import { Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import type { Queue, JobOptions } from 'bull';
import { QUEUE_NAMES } from './queue.constants';

export interface SyncJobData {
  entityType: string;
  entityId: number;
  action: 'create' | 'update' | 'delete';
  data: any;
  deviceId?: string;
  userId?: number;
}

export interface NotificationJobData {
  type: 'order_update' | 'table_update' | 'system_alert';
  recipients: string[];
  data: any;
  priority?: number;
}

export interface ReportJobData {
  type: 'daily' | 'weekly' | 'monthly' | 'custom';
  startDate: Date;
  endDate: Date;
  userId: number;
  format: 'pdf' | 'excel' | 'json';
}

@Injectable()
export class QueueService {
  private readonly logger = new Logger(QueueService.name);

  constructor(
    @InjectQueue(QUEUE_NAMES.SYNC) private syncQueue: Queue,
    @InjectQueue(QUEUE_NAMES.NOTIFICATIONS) private notificationQueue: Queue,
    @InjectQueue(QUEUE_NAMES.REPORTS) private reportQueue: Queue,
    @InjectQueue(QUEUE_NAMES.CLEANUP) private cleanupQueue: Queue,
  ) {}

  // Sync Queue Methods
  async addSyncJob(data: SyncJobData, options?: JobOptions): Promise<void> {
    try {
      await this.syncQueue.add('process-sync', data, {
        priority: 10,
        delay: 0,
        ...options,
      });
      this.logger.debug(`Sync job added: ${data.entityType}:${data.entityId}`);
    } catch (error) {
      this.logger.error('Failed to add sync job:', error);
    }
  }

  async addBulkSyncJob(
    items: SyncJobData[],
    options?: JobOptions,
  ): Promise<void> {
    try {
      const jobs = items.map((data) => ({
        name: 'process-sync',
        data,
        opts: { priority: 5, ...options },
      }));

      await this.syncQueue.addBulk(jobs);
      this.logger.debug(`Bulk sync job added: ${items.length} items`);
    } catch (error) {
      this.logger.error('Failed to add bulk sync job:', error);
    }
  }

  // Notification Queue Methods
  async addNotificationJob(
    data: NotificationJobData,
    options?: JobOptions,
  ): Promise<void> {
    try {
      await this.notificationQueue.add('send-notification', data, {
        priority: data.priority || 5,
        ...options,
      });
      this.logger.debug(`Notification job added: ${data.type}`);
    } catch (error) {
      this.logger.error('Failed to add notification job:', error);
    }
  }

  async addUrgentNotification(data: NotificationJobData): Promise<void> {
    await this.addNotificationJob(data, { priority: 1, delay: 0 });
  }

  // Report Queue Methods
  async addReportJob(data: ReportJobData, options?: JobOptions): Promise<void> {
    try {
      await this.reportQueue.add('generate-report', data, {
        priority: 3,
        timeout: 300000, // 5 minutes
        ...options,
      });
      this.logger.debug(`Report job added: ${data.type}`);
    } catch (error) {
      this.logger.error('Failed to add report job:', error);
    }
  }

  // Cleanup Queue Methods
  async addCleanupJob(
    type: string,
    data: any,
    options?: JobOptions,
  ): Promise<void> {
    try {
      await this.cleanupQueue.add(type, data, {
        priority: 1,
        ...options,
      });
      this.logger.debug(`Cleanup job added: ${type}`);
    } catch (error) {
      this.logger.error('Failed to add cleanup job:', error);
    }
  }

  // Queue Management
  async getQueueStats() {
    const [syncStats, notificationStats, reportStats, cleanupStats] =
      await Promise.all([
        this.getQueueInfo(this.syncQueue),
        this.getQueueInfo(this.notificationQueue),
        this.getQueueInfo(this.reportQueue),
        this.getQueueInfo(this.cleanupQueue),
      ]);

    return {
      sync: syncStats,
      notifications: notificationStats,
      reports: reportStats,
      cleanup: cleanupStats,
    };
  }

  private async getQueueInfo(queue: Queue) {
    const [waiting, active, completed, failed, delayed] = await Promise.all([
      queue.getWaiting(),
      queue.getActive(),
      queue.getCompleted(),
      queue.getFailed(),
      queue.getDelayed(),
    ]);

    return {
      waiting: waiting.length,
      active: active.length,
      completed: completed.length,
      failed: failed.length,
      delayed: delayed.length,
    };
  }

  async pauseQueue(queueName: keyof typeof QUEUE_NAMES): Promise<void> {
    const queue = this.getQueue(queueName);
    await queue.pause();
    this.logger.log(`Queue ${queueName} paused`);
  }

  async resumeQueue(queueName: keyof typeof QUEUE_NAMES): Promise<void> {
    const queue = this.getQueue(queueName);
    await queue.resume();
    this.logger.log(`Queue ${queueName} resumed`);
  }

  async cleanQueue(
    queueName: keyof typeof QUEUE_NAMES,
    grace: number = 0,
  ): Promise<void> {
    const queue = this.getQueue(queueName);
    await queue.clean(grace, 'completed');
    await queue.clean(grace, 'failed');
    this.logger.log(`Queue ${queueName} cleaned`);
  }

  private getQueue(queueName: keyof typeof QUEUE_NAMES): Queue {
    switch (queueName) {
      case 'SYNC':
        return this.syncQueue;
      case 'NOTIFICATIONS':
        return this.notificationQueue;
      case 'REPORTS':
        return this.reportQueue;
      case 'CLEANUP':
        return this.cleanupQueue;
      default:
        throw new Error(`Unknown queue: ${queueName}`);
    }
  }

  // Scheduled Jobs
  async scheduleRecurringJobs(): Promise<void> {
    // Daily cleanup at 2 AM
    await this.cleanupQueue.add(
      'daily-cleanup',
      { type: 'daily' },
      {
        repeat: { cron: '0 2 * * *' },
        removeOnComplete: 1,
        removeOnFail: 1,
      },
    );

    // Hourly sync optimization
    await this.syncQueue.add(
      'optimize-sync',
      { type: 'optimize' },
      {
        repeat: { cron: '0 * * * *' },
        removeOnComplete: 1,
        removeOnFail: 1,
      },
    );

    // Weekly reports on Sunday at midnight
    await this.reportQueue.add(
      'weekly-report',
      { type: 'weekly' },
      {
        repeat: { cron: '0 0 * * 0' },
        removeOnComplete: 5,
        removeOnFail: 1,
      },
    );

    this.logger.log('Recurring jobs scheduled');
  }
}
