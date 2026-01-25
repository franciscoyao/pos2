import { ConfigService } from '@nestjs/config';
import { TypeOrmModuleOptions } from '@nestjs/typeorm';

export const databaseConfig = (
  configService: ConfigService,
): TypeOrmModuleOptions => {
  const isProduction = configService.get('NODE_ENV') === 'production';

  return {
    type: 'postgres',
    url: configService.get('DATABASE_URL'),
    host: configService.get('DB_HOST', 'localhost'),
    port: parseInt(configService.get('DB_PORT', '5432'), 10),
    username: configService.get('DB_USERNAME', 'postgres'),
    password: configService.get('DB_PASSWORD', 'password'),
    database: configService.get('DB_NAME', 'pos_system'),
    // entities: [__dirname + '/../**/*.entity{.ts,.js}'], // Deprecated in favor of autoLoadEntities
    autoLoadEntities: true,
    migrations: [__dirname + '/../migrations/*{.ts,.js}'],
    subscribers: [__dirname + '/../subscribers/*{.ts,.js}'],

    // Performance & Production Settings
    synchronize: !isProduction, // Never sync in production
    migrationsRun: isProduction,
    logging: configService.get('DB_LOGGING', !isProduction),
    logger: 'advanced-console',

    // Connection Pool Settings
    extra: {
      connectionLimit: parseInt(
        configService.get('DB_CONNECTION_LIMIT', '20'),
        10,
      ),
      acquireTimeout: parseInt(
        configService.get('DB_ACQUIRE_TIMEOUT', '60000'),
        10,
      ),
      timeout: parseInt(configService.get('DB_TIMEOUT', '60000'), 10),
      reconnect: true,
      reconnectTries: Number.MAX_VALUE,
      reconnectInterval: 1000,
    },

    // SSL Configuration
    ssl:
      configService.get('DB_SSL') === 'true'
        ? {
          rejectUnauthorized:
            configService.get('DB_SSL_REJECT_UNAUTHORIZED', 'false') ===
            'true',
          ca: configService.get('DB_SSL_CA'),
          cert: configService.get('DB_SSL_CERT'),
          key: configService.get('DB_SSL_KEY'),
        }
        : false,

    // Performance Optimizations - Disabled Redis cache for Docker compatibility
    // cache: {
    //   type: 'redis',
    //   options: {
    //     host: configService.get('REDIS_HOST', 'localhost'),
    //     port: parseInt(configService.get('REDIS_PORT', '6379'), 10),
    //     password: configService.get('REDIS_PASSWORD'),
    //     db: parseInt(configService.get('REDIS_CACHE_DB', '2'), 10),
    //   },
    //   duration: parseInt(configService.get('DB_CACHE_DURATION', '30000'), 10), // 30 seconds
    // },

    // Query optimization
    maxQueryExecutionTime: parseInt(
      configService.get('DB_MAX_QUERY_TIME', '1000'),
      10,
    ),
  };
};
