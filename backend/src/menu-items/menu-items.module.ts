import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MenuItemsService } from './menu-items.service';
import { MenuItemsController } from './menu-items.controller';
import { MenuItem } from './entities/menu-item.entity';
import { OrdersModule } from '../orders/orders.module';

@Module({
  imports: [TypeOrmModule.forFeature([MenuItem]), OrdersModule],
  controllers: [MenuItemsController],
  providers: [MenuItemsService],
})
export class MenuItemsModule { }

