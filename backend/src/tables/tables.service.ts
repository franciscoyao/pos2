import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RestaurantTable } from './table.entity';
import { EventsGateway } from '../events/events.gateway';
import { SyncService } from '../sync/sync.service';

@Injectable()
export class TablesService {
  constructor(
    @InjectRepository(RestaurantTable)
    private tablesRepository: Repository<RestaurantTable>,
    private eventsGateway: EventsGateway,
    private syncService: SyncService,
  ) { }

  findAll(): Promise<RestaurantTable[]> {
    return this.tablesRepository.find({
      where: { isDeleted: false },
      order: { name: 'ASC' },
    });
  }

  async findOne(id: number): Promise<RestaurantTable> {
    const table = await this.tablesRepository.findOne({
      where: { id, isDeleted: false },
    });

    if (!table) {
      throw new NotFoundException(`Table with ID ${id} not found`);
    }

    return table;
  }

  async create(
    tableData: Partial<RestaurantTable>,
    deviceId?: string,
  ): Promise<RestaurantTable> {
    const table = this.tablesRepository.create({
      ...tableData,
      lastModifiedBy: deviceId,
    });

    const savedTable = await this.tablesRepository.save(table);

    // Record sync change
    await this.syncService.recordChange(
      'table',
      savedTable.id,
      'create',
      savedTable,
      undefined,
      deviceId,
    );

    // Emit real-time update
    this.eventsGateway.emitTableUpdate(savedTable, deviceId);

    return savedTable;
  }

  async update(
    id: number,
    tableData: Partial<RestaurantTable>,
    deviceId?: string,
  ): Promise<RestaurantTable> {
    const existingTable = await this.findOne(id);

    await this.tablesRepository.update(id, {
      ...tableData,
      lastModifiedBy: deviceId,
    });

    const updatedTable = await this.findOne(id);

    // Record sync change
    await this.syncService.recordChange(
      'table',
      id,
      'update',
      updatedTable,
      existingTable,
      deviceId,
    );

    // Emit real-time update
    this.eventsGateway.emitTableUpdate(updatedTable, deviceId);

    return updatedTable;
  }

  async remove(id: number, deviceId?: string): Promise<void> {
    const table = await this.findOne(id);

    // Soft delete
    table.isDeleted = true;
    table.lastModifiedBy = deviceId || 'system';
    await this.tablesRepository.save(table);

    // Record sync change
    await this.syncService.recordChange(
      'table',
      id,
      'delete',
      { id, isDeleted: true },
      table,
      deviceId,
    );

    // Emit real-time update
    this.eventsGateway.emitTableUpdate({ ...table, isDeleted: true }, deviceId);
  }

  async updateStatus(
    id: number,
    status: string,
    deviceId?: string,
  ): Promise<RestaurantTable> {
    return this.update(id, { status }, deviceId);
  }

  async getAvailableTables(): Promise<RestaurantTable[]> {
    return this.tablesRepository.find({
      where: {
        status: 'available',
        isDeleted: false,
      },
      order: { name: 'ASC' },
    });
  }

  async getOccupiedTables(): Promise<RestaurantTable[]> {
    return this.tablesRepository.find({
      where: {
        status: 'occupied',
        isDeleted: false,
      },
      order: { name: 'ASC' },
    });
  }
}
