import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Order } from './order.entity';
import { OrderItem } from './order-item.entity';
import { Payment } from './payment.entity';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { EventsModule } from '../events/events.module';

@Module({
    imports: [
        TypeOrmModule.forFeature([Order, OrderItem, Payment]),
        EventsModule
    ],
    controllers: [OrdersController],
    providers: [OrdersService],
})
export class OrdersModule { }
