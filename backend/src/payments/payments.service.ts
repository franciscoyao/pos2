import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Payment } from '../orders/payment.entity';
import { EventsGateway } from '../events/events.gateway';
import { SyncService } from '../sync/sync.service';

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);

  constructor(
    @InjectRepository(Payment)
    private paymentsRepository: Repository<Payment>,
    private eventsGateway: EventsGateway,
    private syncService: SyncService,
  ) {}

  async findAll(): Promise<Payment[]> {
    return await this.paymentsRepository.find({
      where: { isDeleted: false },
      relations: ['order'],
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: number): Promise<Payment> {
    const payment = await this.paymentsRepository.findOne({
      where: { id, isDeleted: false },
      relations: ['order'],
    });

    if (!payment) {
      throw new NotFoundException(`Payment with ID ${id} not found`);
    }

    return payment;
  }

  async create(
    paymentData: Partial<Payment>,
    deviceId?: string,
  ): Promise<Payment> {
    const payment = this.paymentsRepository.create({
      ...paymentData,
      lastModifiedBy: deviceId,
    });

    const savedPayment = await this.paymentsRepository.save(payment);

    // Record sync change
    await this.syncService.recordChange(
      'payment',
      savedPayment.id,
      'create',
      savedPayment,
      undefined,
      deviceId,
    );

    // Emit real-time update
    this.eventsGateway.server.emit('payment:created', savedPayment);

    this.logger.log(
      `Payment created: ${savedPayment.id} - ${savedPayment.method}`,
    );

    return savedPayment;
  }

  async update(
    id: number,
    paymentData: Partial<Payment>,
    deviceId?: string,
  ): Promise<Payment> {
    const existingPayment = await this.findOne(id);

    Object.assign(existingPayment, {
      ...paymentData,
      lastModifiedBy: deviceId,
    });

    const updatedPayment = await this.paymentsRepository.save(existingPayment);

    // Record sync change
    await this.syncService.recordChange(
      'payment',
      id,
      'update',
      updatedPayment,
      existingPayment,
      deviceId,
    );

    // Emit real-time update
    this.eventsGateway.server.emit('payment:updated', updatedPayment);

    return updatedPayment;
  }

  async processRefund(
    id: number,
    refundAmount: number,
    reason: string,
    deviceId?: string,
  ): Promise<Payment> {
    const payment = await this.findOne(id);

    if (!payment.isRefundable) {
      throw new Error('Payment is not refundable');
    }

    payment.status = 'refunded';
    payment.refundedAt = new Date();
    payment.refundAmount = refundAmount;
    payment.refundReason = reason;
    payment.lastModifiedBy = deviceId || 'system';

    const updatedPayment = await this.paymentsRepository.save(payment);

    // Record sync change
    await this.syncService.recordChange(
      'payment',
      id,
      'update',
      updatedPayment,
      payment,
      deviceId,
    );

    // Emit real-time update
    this.eventsGateway.server.emit('payment:refunded', updatedPayment);

    this.logger.log(`Payment refunded: ${id} - Amount: ${refundAmount}`);

    return updatedPayment;
  }

  async remove(id: number, deviceId?: string): Promise<void> {
    const payment = await this.findOne(id);

    payment.isDeleted = true;
    payment.lastModifiedBy = deviceId || 'system';

    await this.paymentsRepository.save(payment);

    // Record sync change
    await this.syncService.recordChange(
      'payment',
      id,
      'delete',
      { id, isDeleted: true },
      payment,
      deviceId,
    );

    // Emit real-time update
    this.eventsGateway.server.emit('payment:deleted', { id });

    this.logger.log(`Payment deleted: ${id}`);
  }
}
