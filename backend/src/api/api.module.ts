import { Module } from '@nestjs/common';
import { ApiController } from './api.controller';
import { OrdersModule } from '../orders/orders.module';
import { TablesModule } from '../tables/tables.module';
import { MenuItemsModule } from '../menu-items/menu-items.module';
import { CategoriesModule } from '../categories/categories.module';
import { UsersModule } from '../users/users.module';
import { SyncModule } from '../sync/sync.module';

@Module({
  imports: [
    OrdersModule,
    TablesModule,
    MenuItemsModule,
    CategoriesModule,
    UsersModule,
    SyncModule,
  ],
  controllers: [ApiController],
})
export class ApiModule {}
