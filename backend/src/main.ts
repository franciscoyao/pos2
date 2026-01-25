import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger, VersioningType } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import helmet from 'helmet';
import compression from 'compression';
import { WinstonModule } from 'nest-winston';
import * as winston from 'winston';

async function bootstrap() {
  // Create Winston logger
  const logger = WinstonModule.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(
      winston.format.timestamp(),
      winston.format.errors({ stack: true }),
      winston.format.json(),
    ),
    transports: [
      new winston.transports.Console({
        format: winston.format.combine(
          winston.format.colorize(),
          winston.format.simple(),
        ),
      }),
    ],
  });

  const app = await NestFactory.create(AppModule, {
    logger,
    cors: true,
  });

  const configService = app.get(ConfigService);
  const isProduction = configService.get('NODE_ENV') === 'production';
  const port = configService.get('PORT', 3000);

  // Security middleware
  app.use(
    helmet({
      contentSecurityPolicy: isProduction ? undefined : false,
      crossOriginEmbedderPolicy: false,
    }),
  );

  // Compression middleware
  app.use(compression());

  // CORS configuration
  app.enableCors({
    origin: configService.get('CORS_ORIGINS', '*').split(','),
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'x-device-id',
      'device-id',
      'x-user-id',
      'x-sync-version',
      'x-request-id',
    ],
    exposedHeaders: [
      'x-sync-version',
      'x-request-id',
      'x-rate-limit-remaining',
    ],
  });

  // API versioning
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
    prefix: 'v',
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
      validationError: {
        target: false,
        value: false,
      },
    }),
  );

  // Global prefix
  app.setGlobalPrefix('api', {
    exclude: ['/health', '/metrics', '/docs', '/docs-json', '/'],
  });

  // Swagger documentation
  if (!isProduction || configService.get('ENABLE_DOCS') === 'true') {
    const config = new DocumentBuilder()
      .setTitle('POS System API')
      .setDescription('Advanced Point of Sale System with Real-time Sync')
      .setVersion('2.0.0')
      .addBearerAuth()
      .addApiKey(
        { type: 'apiKey', name: 'x-device-id', in: 'header' },
        'device-id',
      )
      .addTag('Authentication', 'User authentication and authorization')
      .addTag('Orders', 'Order management and processing')
      .addTag('Tables', 'Table management and status')
      .addTag('Menu', 'Menu items and categories')
      .addTag('Payments', 'Payment processing and methods')
      .addTag('Sync', 'Real-time synchronization')
      .addTag('Analytics', 'Reports and analytics')
      .addTag('Settings', 'System configuration')
      .addTag('Printers', 'Printer management')
      .addTag('Users', 'User management')
      .addServer(`http://localhost:${port}`, 'Development')
      .addServer(
        configService.get('API_URL', `http://localhost:${port}`),
        'Production',
      )
      .build();

    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('docs', app, document, {
      swaggerOptions: {
        persistAuthorization: true,
        displayRequestDuration: true,
        docExpansion: 'none',
        filter: true,
        showRequestHeaders: true,
        tryItOutEnabled: true,
      },
      customSiteTitle: 'POS System API Documentation',
      customfavIcon: '/favicon.ico',
      customCss: `
        .swagger-ui .topbar { display: none }
        .swagger-ui .info { margin: 20px 0 }
        .swagger-ui .scheme-container { background: #fafafa; padding: 20px; border-radius: 4px; }
      `,
    });
  }

  // Graceful shutdown
  process.on('SIGTERM', async () => {
    logger.log('SIGTERM received, shutting down gracefully');
    await app.close();
    process.exit(0);
  });

  process.on('SIGINT', async () => {
    logger.log('SIGINT received, shutting down gracefully');
    await app.close();
    process.exit(0);
  });

  // Start the application
  await app.listen(port, '0.0.0.0');

  const appLogger = new Logger('Bootstrap');

  appLogger.log(`🚀 POS System Backend started successfully!`);
  appLogger.log(`📡 Server running on: http://0.0.0.0:${port}`);
  appLogger.log(`🔄 WebSocket server: ws://0.0.0.0:${port}/sync`);
  appLogger.log(`📊 Health check: http://0.0.0.0:${port}/health`);
  appLogger.log(`📈 Metrics: http://0.0.0.0:${port}/metrics`);

  if (!isProduction || configService.get('ENABLE_DOCS') === 'true') {
    appLogger.log(`📚 API Documentation: http://0.0.0.0:${port}/docs`);
  }

  appLogger.log(
    `🌍 Environment: ${configService.get('NODE_ENV', 'development')}`,
  );
  appLogger.log(`🔧 API Version: v1`);
  appLogger.log(`💾 Database: PostgreSQL`);
  appLogger.log(`🔄 Cache: Redis`);
  appLogger.log(`📦 Queue: Bull (Redis)`);

  if (isProduction) {
    appLogger.log(`🔒 Security: Helmet enabled`);
    appLogger.log(`📦 Compression: Enabled`);
  }

  appLogger.log(`✨ Ready to serve requests!`);
}

bootstrap().catch((error) => {
  const logger = new Logger('Bootstrap');
  logger.error('Failed to start the application:', error);
  process.exit(1);
});
