import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Setting, DEFAULT_SETTINGS } from './settings.entity';
import { CacheService } from '../cache/cache.service';
import { EventEmitter2 } from '@nestjs/event-emitter';

@Injectable()
export class SettingsService {
  private readonly logger = new Logger(SettingsService.name);
  private readonly CACHE_PREFIX = 'settings:';
  private readonly CACHE_TTL = CacheService.TTL.LONG;

  constructor(
    @InjectRepository(Setting)
    private settingsRepository: Repository<Setting>,
    private cacheService: CacheService,
    private eventEmitter: EventEmitter2,
  ) {}

  async initializeDefaultSettings(): Promise<void> {
    this.logger.log('Initializing default settings...');

    for (const [key, config] of Object.entries(DEFAULT_SETTINGS)) {
      const existing = await this.settingsRepository.findOne({
        where: { key },
      });

      if (!existing) {
        const setting = this.settingsRepository.create({
          key,
          value: config.value,
          category: config.category,
          dataType: config.dataType,
          description: `Default ${key} setting`,
        });

        await this.settingsRepository.save(setting);
        this.logger.debug(`Created default setting: ${key}`);
      }
    }

    this.logger.log('Default settings initialization completed');
  }

  async get<T = any>(key: string, defaultValue?: T): Promise<T> {
    // Try cache first
    const cacheKey = `${this.CACHE_PREFIX}${key}`;
    let setting = await this.cacheService.get<Setting>(cacheKey);

    if (!setting) {
      // Fetch from database
      setting =
        (await this.settingsRepository.findOne({
          where: { key, isActive: true },
        })) || undefined;

      if (setting) {
        // Cache the setting
        await this.cacheService.set(cacheKey, setting, this.CACHE_TTL);
      }
    }

    if (!setting) {
      if (defaultValue !== undefined) {
        return defaultValue;
      }
      throw new NotFoundException(`Setting '${key}' not found`);
    }

    return setting.getTypedValue() as T;
  }

  async set(key: string, value: any, deviceId?: string): Promise<Setting> {
    let setting = await this.settingsRepository.findOne({ where: { key } });

    const stringValue =
      typeof value === 'object' ? JSON.stringify(value) : String(value);

    if (setting) {
      const oldValue = setting.getTypedValue();
      setting.value = stringValue;
      setting.lastModifiedBy = deviceId || 'system';

      await this.settingsRepository.save(setting);

      // Emit change event
      this.eventEmitter.emit('setting.changed', {
        key,
        oldValue,
        newValue: value,
        deviceId,
      });
    } else {
      // Create new setting
      setting = this.settingsRepository.create({
        key,
        value: stringValue,
        category: 'custom',
        dataType: this.inferDataType(value),
        lastModifiedBy: deviceId,
      });

      await this.settingsRepository.save(setting);

      // Emit creation event
      this.eventEmitter.emit('setting.created', {
        key,
        value,
        deviceId,
      });
    }

    // Update cache
    const cacheKey = `${this.CACHE_PREFIX}${key}`;
    await this.cacheService.set(cacheKey, setting, this.CACHE_TTL);

    this.logger.log(`Setting '${key}' updated to: ${stringValue}`);

    return setting;
  }

  async getByCategory(category: string): Promise<Record<string, any>> {
    const settings = await this.settingsRepository.find({
      where: { category, isActive: true },
      order: { key: 'ASC' },
    });

    const result: Record<string, any> = {};

    for (const setting of settings) {
      result[setting.key] = setting.getTypedValue();
    }

    return result;
  }

  async getAllSettings(): Promise<Record<string, any>> {
    const settings = await this.settingsRepository.find({
      where: { isActive: true },
      order: { category: 'ASC', key: 'ASC' },
    });

    const result: Record<string, any> = {};

    for (const setting of settings) {
      result[setting.key] = setting.getTypedValue();
    }

    return result;
  }

  async bulkUpdate(
    updates: Record<string, any>,
    deviceId?: string,
  ): Promise<void> {
    const promises = Object.entries(updates).map(([key, value]) =>
      this.set(key, value, deviceId),
    );

    await Promise.all(promises);

    this.logger.log(`Bulk updated ${Object.keys(updates).length} settings`);
  }

  async delete(key: string): Promise<void> {
    const setting = await this.settingsRepository.findOne({ where: { key } });

    if (!setting) {
      throw new NotFoundException(`Setting '${key}' not found`);
    }

    await this.settingsRepository.remove(setting);

    // Remove from cache
    const cacheKey = `${this.CACHE_PREFIX}${key}`;
    await this.cacheService.del(cacheKey);

    // Emit deletion event
    this.eventEmitter.emit('setting.deleted', { key });

    this.logger.log(`Setting '${key}' deleted`);
  }

  async resetToDefault(key: string): Promise<Setting> {
    const defaultConfig = DEFAULT_SETTINGS[key];

    if (!defaultConfig) {
      throw new NotFoundException(
        `No default value found for setting '${key}'`,
      );
    }

    return await this.set(key, defaultConfig.value);
  }

  async clearCache(): Promise<void> {
    await this.cacheService.delPattern(`${this.CACHE_PREFIX}*`);
    this.logger.log('Settings cache cleared');
  }

  // Helper methods for common settings
  async getTaxRate(): Promise<number> {
    return await this.get<number>('tax.rate', 0);
  }

  async getServiceRate(): Promise<number> {
    return await this.get<number>('service.rate', 0);
  }

  async getCurrencySymbol(): Promise<string> {
    return await this.get<string>('general.currency_symbol', '$');
  }

  async getOrderDelayThreshold(): Promise<number> {
    return await this.get<number>('order.delay_threshold', 15);
  }

  async isKioskEnabled(): Promise<boolean> {
    return await this.get<boolean>('kiosk.enabled', false);
  }

  private inferDataType(value: any): string {
    if (typeof value === 'boolean') return 'boolean';
    if (typeof value === 'number') return 'number';
    if (Array.isArray(value)) return 'array';
    if (typeof value === 'object') return 'json';
    return 'string';
  }
}
