import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { UsersModule } from './users/users.module';
import { CategoriesModule } from './categories/categories.module';
import { MenuItemsModule } from './menu-items/menu-items.module';
import { OrdersModule } from './orders/orders.module';
import { OrderItemsModule } from './order-items/order-items.module';
import { TablesModule } from './tables/tables.module';
import { PrintersModule } from './printers/printers.module';
import { SettingsModule } from './settings/settings.module';

@Module({
  imports: [
    ConfigModule.forRoot(),
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DATABASE_HOST || 'postgres',
      port: parseInt(process.env.DATABASE_PORT || '5432', 10),
      username: process.env.DATABASE_USER || 'postgres',
      password: process.env.DATABASE_PASSWORD || 'password',
      database: process.env.DATABASE_NAME || 'pos_db',
      autoLoadEntities: true,
      synchronize: true, // Connects to the DB and creates tables automatically (Dev only)
    }),
    UsersModule,
    CategoriesModule,
    MenuItemsModule,
    OrdersModule,
    OrderItemsModule,
    TablesModule,
    PrintersModule,
    SettingsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule { }
