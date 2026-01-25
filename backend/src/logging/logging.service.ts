import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface LogEntry {
  level: 'error' | 'warn' | 'info' | 'debug';
  message: string;
  context?: string;
  timestamp: Date;
  metadata?: any;
  deviceId?: string;
  userId?: number;
}

@Injectable()
export class LoggingService {
  private readonly logger = new Logger(LoggingService.name);

  constructor(private configService: ConfigService) {}

  log(entry: LogEntry): void {
    const { level, message, context, metadata, deviceId, userId } = entry;

    const logMessage = this.formatMessage(message, {
      deviceId,
      userId,
      ...metadata,
    });

    switch (level) {
      case 'error':
        this.logger.error(logMessage, context);
        break;
      case 'warn':
        this.logger.warn(logMessage, context);
        break;
      case 'info':
        this.logger.log(logMessage, context);
        break;
      case 'debug':
        this.logger.debug(logMessage, context);
        break;
    }
  }

  error(message: string, context?: string, metadata?: any): void {
    this.log({
      level: 'error',
      message,
      context,
      metadata,
      timestamp: new Date(),
    });
  }

  warn(message: string, context?: string, metadata?: any): void {
    this.log({
      level: 'warn',
      message,
      context,
      metadata,
      timestamp: new Date(),
    });
  }

  info(message: string, context?: string, metadata?: any): void {
    this.log({
      level: 'info',
      message,
      context,
      metadata,
      timestamp: new Date(),
    });
  }

  debug(message: string, context?: string, metadata?: any): void {
    this.log({
      level: 'debug',
      message,
      context,
      metadata,
      timestamp: new Date(),
    });
  }

  private formatMessage(message: string, metadata?: any): string {
    if (!metadata || Object.keys(metadata).length === 0) {
      return message;
    }

    const metadataString = Object.entries(metadata)
      .filter(([_, value]) => value !== undefined && value !== null)
      .map(([key, value]) => `${key}=${value}`)
      .join(' ');

    return `${message} [${metadataString}]`;
  }
}
