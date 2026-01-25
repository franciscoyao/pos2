import { Controller, Get, Post, Body, Put, Param } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { Order } from './order.entity';
import { CreateOrderDto } from './dto/create-order.dto';

@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Get('sync')
  getSyncOrders(): Promise<Order[]> {
    return this.ordersService.getSyncOrders();
  }

  @Get()
  findAll(): Promise<Order[]> {
    return this.ordersService.findAll();
  }

  @Post()
  create(@Body() createOrderDto: CreateOrderDto): Promise<Order> {
    return this.ordersService.create(createOrderDto as any);
  }

  @Put(':id')
  update(
    @Param('id') id: string,
    @Body() order: Partial<Order>,
  ): Promise<Order> {
    return this.ordersService.update(+id, order);
  }

  @Post(':orderNumber/split-table')
  splitTable(
    @Param('orderNumber') orderNumber: string,
    @Body()
    body: {
      targetTableNumber: string;
      items: { id: number; quantity: number }[];
      newOrderNumber?: string;
    },
  ): Promise<Order> {
    return this.ordersService.splitTable(
      orderNumber,
      body.targetTableNumber,
      body.items,
      body.newOrderNumber,
    );
  }

  @Post(':id/pay-items')
  payItems(
    @Param('id') id: string,
    @Body()
    body: { items: { id: number; quantity: number }[]; paymentMethod: string },
  ): Promise<Order> {
    return this.ordersService.payItems(+id, body.items, body.paymentMethod);
  }

  @Post(':id/pay')
  addPayment(
    @Param('id') id: string,
    @Body() body: { amount: number; method: string },
  ): Promise<Order> {
    return this.ordersService.addPayment(+id, body.amount, body.method);
  }

  @Post('merge-tables')
  mergeTables(
    @Body() body: { fromTableNumber: string; toTableNumber: string },
  ): Promise<void> {
    return this.ordersService.mergeTables(
      body.fromTableNumber,
      body.toTableNumber,
    );
  }
}
