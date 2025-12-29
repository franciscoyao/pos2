import { Controller, Get, Post, Body, Put, Param } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { Order } from './order.entity';

@Controller('orders')
export class OrdersController {
    constructor(private readonly ordersService: OrdersService) { }

    @Get()
    findAll(): Promise<Order[]> {
        return this.ordersService.findAll();
    }

    @Post()
    create(@Body() order: Order): Promise<Order> {
        return this.ordersService.create(order);
    }

    @Put(':id')
    update(@Param('id') id: string, @Body() order: Partial<Order>): Promise<void> {
        return this.ordersService.update(+id, order);
    }
}
