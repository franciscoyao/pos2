import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Order } from '../orders/order.entity';
import { OrderItem } from '../orders/order-item.entity';
import { Payment } from '../orders/payment.entity';
import { MenuItem } from '../menu-items/menu-item.entity';
import { User } from '../users/user.entity';
import { MetricsService } from './metrics.service';
import { MetricsController } from './metrics.controller';
import { CustomCacheModule } from '../cache/cache.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Order, OrderItem, Payment, MenuItem, User]),
    CustomCacheModule,
  ],
  controllers: [MetricsController],
  providers: [MetricsService],
  exports: [MetricsService],
})
export class MetricsModule {}
