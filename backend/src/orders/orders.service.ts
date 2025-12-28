import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Order } from './order.entity';

import { EventsGateway } from '../events/events.gateway';

@Injectable()
export class OrdersService {
    constructor(
        @InjectRepository(Order)
        private ordersRepository: Repository<Order>,
        private eventsGateway: EventsGateway,
    ) { }

    findAll(): Promise<Order[]> {
        return this.ordersRepository.find({
            relations: ['items', 'items.menuItem'],
            order: { createdAt: 'DESC' }
        });
    }

    async create(order: Order): Promise<Order> {
        const newOrder = await this.ordersRepository.save(order);
        this.eventsGateway.emitNewOrder(newOrder);
        return newOrder;
    }

    async update(id: number, orderData: Partial<Order>): Promise<void> {
        await this.ordersRepository.update(id, orderData);
        const updatedOrder = await this.ordersRepository.findOne({
            where: { id },
            relations: ['items', 'items.menuItem']
        });
        this.eventsGateway.emitOrderUpdate(updatedOrder);
    }
}
