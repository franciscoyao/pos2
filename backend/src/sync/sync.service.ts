import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan } from 'typeorm';
import { SyncRecord } from './sync.entity';
import { Device } from './device.entity';
import { EventsGateway } from '../events/events.gateway';

export interface SyncRequest {
  deviceId: string;
  lastSyncVersion: number;
  changes: SyncChange[];
}

export interface SyncChange {
  entityType: string;
  entityId: number;
  action: 'create' | 'update' | 'delete';
  data: any;
  version: number;
  timestamp: Date;
}

export interface SyncResponse {
  success: boolean;
  newSyncVersion: number;
  changes: SyncChange[];
  conflicts: ConflictResolution[];
}

export interface ConflictResolution {
  entityType: string;
  entityId: number;
  resolution: 'server_wins' | 'client_wins' | 'merged';
  serverData: any;
  clientData: any;
  mergedData?: any;
}

@Injectable()
export class SyncService {
  private readonly logger = new Logger(SyncService.name);

  constructor(
    @InjectRepository(SyncRecord)
    private syncRepository: Repository<SyncRecord>,
    @InjectRepository(Device)
    private deviceRepository: Repository<Device>,
    private eventsGateway: EventsGateway,
  ) {}

  async registerDevice(deviceInfo: Partial<Device>): Promise<Device> {
    let device = await this.deviceRepository.findOne({
      where: { deviceId: deviceInfo.deviceId },
    });

    if (device) {
      device.lastSeenAt = new Date();
      device.status = 'online';
      if (deviceInfo.deviceName) device.deviceName = deviceInfo.deviceName;
      if (deviceInfo.deviceType) device.deviceType = deviceInfo.deviceType;
      if (deviceInfo.userId) device.userId = deviceInfo.userId;
      if (deviceInfo.capabilities)
        device.capabilities = deviceInfo.capabilities;
    } else {
      device = this.deviceRepository.create({
        ...deviceInfo,
        lastSeenAt: new Date(),
        status: 'online',
        syncVersion: 0,
      });
    }

    return await this.deviceRepository.save(device);
  }

  async updateDeviceStatus(deviceId: string, status: string): Promise<void> {
    await this.deviceRepository.update(
      { deviceId },
      { status, lastSeenAt: new Date() },
    );
  }

  async recordChange(
    entityType: string,
    entityId: number,
    action: 'create' | 'update' | 'delete',
    data: any,
    previousData?: any,
    deviceId?: string,
    userId?: number,
  ): Promise<SyncRecord> {
    const latestRecord = await this.syncRepository.findOne({
      where: { entityType, entityId },
      order: { version: 'DESC' },
    });

    const version = (latestRecord?.version || 0) + 1;

    const syncRecord = this.syncRepository.create({
      entityType,
      entityId,
      action,
      data,
      previousData,
      version,
      deviceId,
      userId,
      synced: false,
    });

    const saved = await this.syncRepository.save(syncRecord);

    // Emit real-time update to all connected devices except the originating one
    this.eventsGateway.emitSyncUpdate({
      entityType,
      entityId,
      action,
      data,
      version,
      excludeDevice: deviceId,
    });

    return saved;
  }

  async processSync(syncRequest: SyncRequest): Promise<SyncResponse> {
    const { deviceId, lastSyncVersion, changes } = syncRequest;

    try {
      // Update device status
      await this.updateDeviceStatus(deviceId, 'syncing');

      // Process incoming changes and detect conflicts
      const conflicts: ConflictResolution[] = [];
      const processedChanges: SyncChange[] = [];

      for (const change of changes) {
        const conflict = await this.detectConflict(change, deviceId);
        if (conflict) {
          conflicts.push(conflict);
          // Apply conflict resolution
          const resolvedData = await this.resolveConflict(conflict);
          if (resolvedData) {
            await this.recordChange(
              change.entityType,
              change.entityId,
              change.action,
              resolvedData,
              change.data,
              deviceId,
            );
            processedChanges.push({
              ...change,
              data: resolvedData,
            });
          }
        } else {
          // No conflict, record the change
          await this.recordChange(
            change.entityType,
            change.entityId,
            change.action,
            change.data,
            undefined,
            deviceId,
          );
          processedChanges.push(change);
        }
      }

      // Get changes since last sync for this device
      const serverChanges = await this.getChangesSince(
        lastSyncVersion,
        deviceId,
      );

      // Update device sync version
      const newSyncVersion = await this.getLatestSyncVersion();
      await this.deviceRepository.update(
        { deviceId },
        {
          syncVersion: newSyncVersion,
          lastSyncAt: new Date(),
          status: 'online',
        },
      );

      return {
        success: true,
        newSyncVersion,
        changes: serverChanges,
        conflicts,
      };
    } catch (error) {
      this.logger.error(`Sync failed for device ${deviceId}:`, error);
      await this.updateDeviceStatus(deviceId, 'online');
      throw error;
    }
  }

  private async detectConflict(
    change: SyncChange,
    deviceId: string,
  ): Promise<ConflictResolution | null> {
    // Get the latest server version of this entity
    const latestRecord = await this.syncRepository.findOne({
      where: {
        entityType: change.entityType,
        entityId: change.entityId,
      },
      order: { version: 'DESC' },
    });

    if (!latestRecord) {
      return null; // No conflict for new entities
    }

    // Check if there's a newer version on server
    if (
      latestRecord.version > change.version &&
      latestRecord.deviceId !== deviceId
    ) {
      return {
        entityType: change.entityType,
        entityId: change.entityId,
        resolution: 'server_wins', // Default resolution strategy
        serverData: latestRecord.data,
        clientData: change.data,
      };
    }

    return null;
  }

  private async resolveConflict(conflict: ConflictResolution): Promise<any> {
    switch (conflict.resolution) {
      case 'server_wins':
        return conflict.serverData;

      case 'client_wins':
        return conflict.clientData;

      case 'merged':
        // Implement smart merging logic based on entity type
        return this.mergeData(
          conflict.entityType,
          conflict.serverData,
          conflict.clientData,
        );

      default:
        return conflict.serverData;
    }
  }

  private mergeData(entityType: string, serverData: any, clientData: any): any {
    // Implement entity-specific merge logic
    switch (entityType) {
      case 'order':
        return this.mergeOrderData(serverData, clientData);
      case 'table':
        return this.mergeTableData(serverData, clientData);
      default:
        // Default merge: client data takes precedence for most fields
        return { ...serverData, ...clientData, updatedAt: new Date() };
    }
  }

  private mergeOrderData(serverData: any, clientData: any): any {
    // For orders, merge items and keep the latest status
    return {
      ...serverData,
      ...clientData,
      items: [...(serverData.items || []), ...(clientData.items || [])],
      totalAmount: clientData.totalAmount || serverData.totalAmount,
      status: clientData.status || serverData.status,
      updatedAt: new Date(),
    };
  }

  private mergeTableData(serverData: any, clientData: any): any {
    // For tables, client status usually takes precedence
    return {
      ...serverData,
      ...clientData,
      updatedAt: new Date(),
    };
  }

  private async getChangesSince(
    version: number,
    excludeDeviceId?: string,
  ): Promise<SyncChange[]> {
    const query = this.syncRepository
      .createQueryBuilder('sync')
      .where('sync.version > :version', { version })
      .orderBy('sync.version', 'ASC');

    if (excludeDeviceId) {
      query.andWhere('sync.deviceId != :deviceId', {
        deviceId: excludeDeviceId,
      });
    }

    const records = await query.getMany();

    return records.map((record) => ({
      entityType: record.entityType,
      entityId: record.entityId,
      action: record.action as 'create' | 'update' | 'delete',
      data: record.data,
      version: record.version,
      timestamp: record.createdAt,
    }));
  }

  private async getLatestSyncVersion(): Promise<number> {
    const latest = await this.syncRepository.findOne({
      order: { version: 'DESC' },
    });
    return latest?.version || 0;
  }

  async getDeviceStatus(deviceId: string): Promise<Device | null> {
    return await this.deviceRepository.findOne({
      where: { deviceId },
    });
  }

  async getAllDevices(): Promise<Device[]> {
    return await this.deviceRepository.find({
      order: { lastSeenAt: 'DESC' },
    });
  }

  async cleanupOldSyncRecords(daysToKeep: number = 30): Promise<void> {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);

    await this.syncRepository.delete({
      createdAt: LessThan(cutoffDate),
      synced: true,
    });

    this.logger.log(`Cleaned up sync records older than ${daysToKeep} days`);
  }
}
