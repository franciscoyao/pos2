import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { SyncService } from '../sync/sync.service';
import { EventsGateway } from '../events/events.gateway';

@Injectable()
export class TasksService {
  private readonly logger = new Logger(TasksService.name);

  constructor(
    private readonly syncService: SyncService,
    private readonly eventsGateway: EventsGateway,
  ) {}

  // Clean up old sync records every day at 2 AM
  @Cron('0 2 * * *')
  async handleSyncCleanup() {
    this.logger.log('Starting sync records cleanup...');
    try {
      await this.syncService.cleanupOldSyncRecords(30); // Keep 30 days
      this.logger.log('Sync records cleanup completed');
    } catch (error) {
      this.logger.error('Sync records cleanup failed:', error);
    }
  }

  // Update device statuses every 5 minutes
  @Cron(CronExpression.EVERY_5_MINUTES)
  async handleDeviceStatusUpdate() {
    try {
      const devices = await this.syncService.getAllDevices();
      const now = new Date();

      for (const device of devices) {
        if (device.lastSeenAt) {
          const timeDiff = now.getTime() - device.lastSeenAt.getTime();
          const minutesDiff = timeDiff / (1000 * 60);

          // Mark as offline if not seen for more than 10 minutes
          if (minutesDiff > 10 && device.status !== 'offline') {
            await this.syncService.updateDeviceStatus(
              device.deviceId,
              'offline',
            );
            this.logger.log(`Device ${device.deviceId} marked as offline`);

            // Notify other devices
            this.eventsGateway.server.emit('device:status_changed', {
              deviceId: device.deviceId,
              status: 'offline',
            });
          }
        }
      }
    } catch (error) {
      this.logger.error('Device status update failed:', error);
    }
  }

  // Send heartbeat to all connected devices every minute
  @Cron(CronExpression.EVERY_MINUTE)
  handleServerHeartbeat() {
    const connectedDevices = this.eventsGateway.getConnectedDevices();

    if (connectedDevices.length > 0) {
      this.eventsGateway.server.emit('server:heartbeat', {
        timestamp: new Date(),
        connectedDevices: connectedDevices.length,
      });
    }
  }

  // Generate daily reports at midnight
  @Cron('0 0 * * *')
  handleDailyReports() {
    this.logger.log('Generating daily reports...');
    try {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      yesterday.setHours(0, 0, 0, 0);

      const today = new Date();
      today.setHours(0, 0, 0, 0);

      // This would integrate with a reports service
      // For now, just log the activity
      this.logger.log(`Daily report generated for ${yesterday.toDateString()}`);
    } catch (error) {
      this.logger.error('Daily report generation failed:', error);
    }
  }
}
