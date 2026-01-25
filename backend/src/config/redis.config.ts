import { ConfigService } from '@nestjs/config';

export const redisConfig = (configService: ConfigService) => ({
  host: configService.get('REDIS_HOST', 'localhost'),
  port: parseInt(configService.get('REDIS_PORT', '6379'), 10),
  password: configService.get('REDIS_PASSWORD'),
  db: parseInt(configService.get('REDIS_DB', '0'), 10),

  // Connection settings
  connectTimeout: parseInt(
    configService.get('REDIS_CONNECT_TIMEOUT', '10000'),
    10,
  ),
  commandTimeout: parseInt(
    configService.get('REDIS_COMMAND_TIMEOUT', '5000'),
    10,
  ),
  retryDelayOnFailover: parseInt(
    configService.get('REDIS_RETRY_DELAY', '100'),
    10,
  ),
  maxRetriesPerRequest: parseInt(
    configService.get('REDIS_MAX_RETRIES', '3'),
    10,
  ),

  // Performance settings
  lazyConnect: true,
  keepAlive: parseInt(configService.get('REDIS_KEEP_ALIVE', '30000'), 10),

  // Cluster support (if needed)
  enableReadyCheck: true,

  // Key prefix for namespacing
  keyPrefix: configService.get('REDIS_KEY_PREFIX', 'pos:'),
});
