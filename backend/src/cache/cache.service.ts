import { Injectable, Inject, Logger } from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';

@Injectable()
export class CacheService {
  private readonly logger = new Logger(CacheService.name);

  constructor(@Inject(CACHE_MANAGER) private cacheManager: Cache) {}

  async get<T>(key: string): Promise<T | undefined> {
    try {
      const value = await this.cacheManager.get<T>(key);
      if (value) {
        this.logger.debug(`Cache HIT for key: ${key}`);
      } else {
        this.logger.debug(`Cache MISS for key: ${key}`);
      }
      return value;
    } catch (error) {
      this.logger.error(`Cache GET error for key ${key}:`, error);
      return undefined;
    }
  }

  async set<T>(key: string, value: T, ttl?: number): Promise<void> {
    try {
      await this.cacheManager.set(key, value, ttl);
      this.logger.debug(`Cache SET for key: ${key}, TTL: ${ttl || 'default'}`);
    } catch (error) {
      this.logger.error(`Cache SET error for key ${key}:`, error);
    }
  }

  async del(key: string): Promise<void> {
    try {
      await this.cacheManager.del(key);
      this.logger.debug(`Cache DELETE for key: ${key}`);
    } catch (error) {
      this.logger.error(`Cache DELETE error for key ${key}:`, error);
    }
  }

  async delPattern(pattern: string): Promise<void> {
    try {
      // This requires Redis store with pattern support
      const keys = await this.getKeys(pattern);
      if (keys.length > 0) {
        await Promise.all(keys.map((key) => this.cacheManager.del(key)));
        this.logger.debug(
          `Cache DELETE pattern: ${pattern}, deleted ${keys.length} keys`,
        );
      }
    } catch (error) {
      this.logger.error(`Cache DELETE pattern error for ${pattern}:`, error);
    }
  }

  async getOrSet<T>(
    key: string,
    factory: () => Promise<T>,
    ttl?: number,
  ): Promise<T> {
    let value = await this.get<T>(key);

    if (value === undefined) {
      value = await factory();
      if (value !== undefined) {
        await this.set(key, value, ttl);
      }
    }

    return value;
  }

  async mget<T>(keys: string[]): Promise<(T | undefined)[]> {
    try {
      return await Promise.all(keys.map((key) => this.get<T>(key)));
    } catch (error) {
      this.logger.error(`Cache MGET error:`, error);
      return keys.map(() => undefined);
    }
  }

  async mset<T>(
    keyValuePairs: Array<{ key: string; value: T; ttl?: number }>,
  ): Promise<void> {
    try {
      await Promise.all(
        keyValuePairs.map(({ key, value, ttl }) => this.set(key, value, ttl)),
      );
      this.logger.debug(`Cache MSET for ${keyValuePairs.length} keys`);
    } catch (error) {
      this.logger.error(`Cache MSET error:`, error);
    }
  }

  async increment(
    key: string,
    amount: number = 1,
    ttl?: number,
  ): Promise<number> {
    try {
      const current = (await this.get<number>(key)) || 0;
      const newValue = current + amount;
      await this.set(key, newValue, ttl);
      return newValue;
    } catch (error) {
      this.logger.error(`Cache INCREMENT error for key ${key}:`, error);
      return amount;
    }
  }

  async exists(key: string): Promise<boolean> {
    try {
      const value = await this.cacheManager.get(key);
      return value !== undefined;
    } catch (error) {
      this.logger.error(`Cache EXISTS error for key ${key}:`, error);
      return false;
    }
  }

  async ttl(key: string): Promise<number> {
    try {
      // This would need Redis store implementation
      return -1; // Not implemented in basic cache manager
    } catch (error) {
      this.logger.error(`Cache TTL error for key ${key}:`, error);
      return -1;
    }
  }

  async reset(): Promise<void> {
    try {
      await this.cacheManager.reset();
      this.logger.log('Cache cleared');
    } catch (error) {
      this.logger.error('Cache RESET error:', error);
    }
  }

  private async getKeys(pattern: string): Promise<string[]> {
    // This would need Redis store implementation for pattern matching
    // For now, return empty array
    return [];
  }

  // Cache key generators
  generateKey(prefix: string, ...parts: (string | number)[]): string {
    return `${prefix}:${parts.join(':')}`;
  }

  // Common cache keys
  static readonly KEYS = {
    USER: (id: number) => `user:${id}`,
    USER_PERMISSIONS: (id: number) => `user:${id}:permissions`,
    MENU_ITEMS: () => 'menu:items',
    MENU_ITEM: (id: number) => `menu:item:${id}`,
    CATEGORIES: () => 'categories',
    CATEGORY: (id: number) => `category:${id}`,
    TABLES: () => 'tables',
    TABLE: (id: number) => `table:${id}`,
    ORDERS_ACTIVE: () => 'orders:active',
    ORDER: (id: number) => `order:${id}`,
    SYNC_VERSION: () => 'sync:version',
    DEVICE: (id: string) => `device:${id}`,
    STATS_DAILY: (date: string) => `stats:daily:${date}`,
  };

  // Cache TTL constants (in seconds)
  static readonly TTL = {
    SHORT: 60, // 1 minute
    MEDIUM: 300, // 5 minutes
    LONG: 1800, // 30 minutes
    VERY_LONG: 3600, // 1 hour
    DAILY: 86400, // 24 hours
  };
}
