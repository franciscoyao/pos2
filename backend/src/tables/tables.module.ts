import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TablesService } from './tables.service';
import { TablesController } from './tables.controller';
import { RestaurantTable } from './entities/table.entity';
import { OrdersModule } from '../orders/orders.module';

@Module({
  imports: [TypeOrmModule.forFeature([RestaurantTable]), OrdersModule],
  controllers: [TablesController],
  providers: [TablesService],
})
export class TablesModule { }


