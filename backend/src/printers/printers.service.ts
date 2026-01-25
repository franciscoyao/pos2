import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Printer } from './printer.entity';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { QueueService } from '../queue/queue.service';

export interface PrintJob {
  id: string;
  printerId: number;
  type: 'receipt' | 'kitchen' | 'bar' | 'label';
  content: string;
  priority: number;
  metadata?: {
    orderId?: number;
    tableNumber?: string;
    orderType?: string;
    timestamp?: Date;
  };
}

@Injectable()
export class PrintersService {
  private readonly logger = new Logger(PrintersService.name);

  constructor(
    @InjectRepository(Printer)
    private printersRepository: Repository<Printer>,
    private eventEmitter: EventEmitter2,
    private queueService: QueueService,
  ) {}

  async findAll(): Promise<Printer[]> {
    return await this.printersRepository.find({
      where: { isDeleted: false },
      order: { role: 'ASC', name: 'ASC' },
    });
  }

  async findByRole(role: string): Promise<Printer[]> {
    return await this.printersRepository.find({
      where: { role, isActive: true, isDeleted: false },
      order: { isDefault: 'DESC', name: 'ASC' },
    });
  }

  async findOne(id: number): Promise<Printer> {
    const printer = await this.printersRepository.findOne({
      where: { id, isDeleted: false },
    });

    if (!printer) {
      throw new NotFoundException(`Printer with ID ${id} not found`);
    }

    return printer;
  }

  async create(
    printerData: Partial<Printer>,
    deviceId?: string,
  ): Promise<Printer> {
    const printer = this.printersRepository.create({
      ...printerData,
      lastModifiedBy: deviceId,
    });

    const savedPrinter = await this.printersRepository.save(printer);

    // Emit printer created event
    this.eventEmitter.emit('printer.created', {
      printer: savedPrinter,
      deviceId,
    });

    this.logger.log(
      `Printer created: ${savedPrinter.name} (${savedPrinter.role})`,
    );

    return savedPrinter;
  }

  async update(
    id: number,
    printerData: Partial<Printer>,
    deviceId?: string,
  ): Promise<Printer> {
    const printer = await this.findOne(id);

    Object.assign(printer, {
      ...printerData,
      lastModifiedBy: deviceId,
    });

    const updatedPrinter = await this.printersRepository.save(printer);

    // Emit printer updated event
    this.eventEmitter.emit('printer.updated', {
      printer: updatedPrinter,
      deviceId,
    });

    this.logger.log(`Printer updated: ${updatedPrinter.name}`);

    return updatedPrinter;
  }

  async updateStatus(
    id: number,
    status: string,
    errorMessage?: string,
  ): Promise<Printer> {
    const printer = await this.findOne(id);

    printer.status = status;

    if (status === 'error' && errorMessage) {
      printer.lastErrorAt = new Date();
      printer.lastErrorMessage = errorMessage;
    }

    const updatedPrinter = await this.printersRepository.save(printer);

    // Emit status change event
    this.eventEmitter.emit('printer.status_changed', {
      printer: updatedPrinter,
      oldStatus: printer.status,
      newStatus: status,
      errorMessage,
    });

    return updatedPrinter;
  }

  async setDefault(id: number, role: string): Promise<Printer> {
    // Remove default flag from other printers in the same role
    await this.printersRepository.update(
      { role, isDefault: true },
      { isDefault: false },
    );

    // Set this printer as default
    const printer = await this.findOne(id);
    printer.isDefault = true;

    return await this.printersRepository.save(printer);
  }

  async testPrint(id: number): Promise<boolean> {
    const printer = await this.findOne(id);

    if (!printer.isActive || printer.status !== 'online') {
      throw new Error(`Printer ${printer.name} is not available for printing`);
    }

    const testContent = this.generateTestPrint(printer);

    try {
      await this.print({
        id: `test-${Date.now()}`,
        printerId: id,
        type: 'receipt',
        content: testContent,
        priority: 1,
      });

      return true;
    } catch (error) {
      this.logger.error(
        `Test print failed for printer ${printer.name}:`,
        error,
      );
      await this.updateStatus(id, 'error', error.message);
      return false;
    }
  }

  async print(job: PrintJob): Promise<void> {
    const printer = await this.findOne(job.printerId);

    if (!printer.isActive) {
      throw new Error(`Printer ${printer.name} is not active`);
    }

    if (printer.status !== 'online') {
      throw new Error(
        `Printer ${printer.name} is not online (status: ${printer.status})`,
      );
    }

    try {
      // Update printer status to printing
      await this.updateStatus(job.printerId, 'printing');

      // Add to print queue
      await this.queueService.addNotificationJob({
        type: 'system_alert',
        recipients: [printer.assignedDeviceId || 'all'],
        data: {
          job,
          printer,
        },
        priority: job.priority,
      });

      // Update print statistics
      printer.totalPrintJobs += 1;
      printer.lastPrintAt = new Date();
      await this.printersRepository.save(printer);

      // Update status back to online
      await this.updateStatus(job.printerId, 'online');

      this.logger.debug(`Print job queued for printer ${printer.name}`);
    } catch (error) {
      // Update failed job count
      printer.failedPrintJobs += 1;
      await this.printersRepository.save(printer);

      // Update status to error
      await this.updateStatus(job.printerId, 'error', error.message);

      throw error;
    }
  }

  async printReceipt(orderId: number, content: string): Promise<void> {
    const receiptPrinters = await this.findByRole('receipt');

    if (receiptPrinters.length === 0) {
      this.logger.warn('No receipt printers available');
      return;
    }

    const defaultPrinter =
      receiptPrinters.find((p) => p.isDefault) || receiptPrinters[0];

    await this.print({
      id: `receipt-${orderId}-${Date.now()}`,
      printerId: defaultPrinter.id,
      type: 'receipt',
      content,
      priority: 5,
      metadata: {
        orderId,
        timestamp: new Date(),
      },
    });
  }

  async printKitchenOrder(
    orderId: number,
    content: string,
    tableNumber?: string,
  ): Promise<void> {
    const kitchenPrinters = await this.findByRole('kitchen');

    for (const printer of kitchenPrinters) {
      if (this.shouldPrintToStation(printer, 'kitchen')) {
        await this.print({
          id: `kitchen-${orderId}-${printer.id}-${Date.now()}`,
          printerId: printer.id,
          type: 'kitchen',
          content,
          priority: 10,
          metadata: {
            orderId,
            tableNumber,
            timestamp: new Date(),
          },
        });
      }
    }
  }

  async printBarOrder(
    orderId: number,
    content: string,
    tableNumber?: string,
  ): Promise<void> {
    const barPrinters = await this.findByRole('bar');

    for (const printer of barPrinters) {
      if (this.shouldPrintToStation(printer, 'bar')) {
        await this.print({
          id: `bar-${orderId}-${printer.id}-${Date.now()}`,
          printerId: printer.id,
          type: 'bar',
          content,
          priority: 10,
          metadata: {
            orderId,
            tableNumber,
            timestamp: new Date(),
          },
        });
      }
    }
  }

  async updatePaperLevel(id: number, level: number): Promise<void> {
    const printer = await this.findOne(id);
    printer.paperLevel = level;
    await this.printersRepository.save(printer);

    if (level < 20) {
      this.eventEmitter.emit('printer.low_paper', { printer });
    }
  }

  async updateInkLevel(id: number, level: number): Promise<void> {
    const printer = await this.findOne(id);
    printer.inkLevel = level;
    await this.printersRepository.save(printer);

    if (level < 20) {
      this.eventEmitter.emit('printer.low_ink', { printer });
    }
  }

  async scheduleMaintenance(
    id: number,
    date: Date,
    performedBy: string,
  ): Promise<void> {
    const printer = await this.findOne(id);

    printer.lastMaintenanceAt = new Date();
    printer.nextMaintenanceAt = date;

    if (!printer.maintenanceLog) {
      printer.maintenanceLog = [];
    }

    printer.maintenanceLog.push({
      date: new Date(),
      type: 'scheduled',
      description: 'Scheduled maintenance',
      performedBy,
    });

    await this.printersRepository.save(printer);
  }

  async remove(id: number, deviceId?: string): Promise<void> {
    const printer = await this.findOne(id);

    printer.isDeleted = true;
    printer.lastModifiedBy = deviceId || 'system';

    await this.printersRepository.save(printer);

    this.eventEmitter.emit('printer.deleted', {
      printer,
      deviceId,
    });

    this.logger.log(`Printer deleted: ${printer.name}`);
  }

  private shouldPrintToStation(printer: Printer, station: string): boolean {
    if (!printer.filterSettings?.stations) {
      return true; // No filter means print all
    }

    return printer.filterSettings.stations.includes(station);
  }

  private generateTestPrint(printer: Printer): string {
    const now = new Date();

    return `
================================
        TEST PRINT
================================

Printer: ${printer.name}
Role: ${printer.role}
Date: ${now.toLocaleDateString()}
Time: ${now.toLocaleTimeString()}

Paper Size: ${printer.paperSize}
DPI: ${printer.dpi}
Characters/Line: ${printer.charactersPerLine}

Status: ${printer.status}
Total Jobs: ${printer.totalPrintJobs}
Success Rate: ${printer.successRate.toFixed(1)}%

This is a test print to verify
printer connectivity and settings.

================================
        END TEST
================================
        `;
  }
}
