import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderDto } from './dto/update-order.dto';
import { Order } from './entities/order.entity';
import { OrdersGateway } from './orders.gateway';

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order)
    private ordersRepository: Repository<Order>,
    private ordersGateway: OrdersGateway,
  ) { }

  async create(createOrderDto: CreateOrderDto) {
    // In a real app, you'd handle OrderItems creation here or separately.
    // For now, simple save.
    const order = this.ordersRepository.create(createOrderDto);
    const savedOrder = await this.ordersRepository.save(order);
    this.ordersGateway.notifyNewOrder(savedOrder);
    return savedOrder;
  }

  findAll() {
    return this.ordersRepository.find({ relations: ['items', 'waiter'] });
  }

  findOne(id: number) {
    return this.ordersRepository.findOne({ where: { id }, relations: ['items', 'waiter'] });
  }

  async update(id: number, updateOrderDto: UpdateOrderDto) {
    await this.ordersRepository.update(id, updateOrderDto);
    const updatedOrder = await this.findOne(id);
    this.ordersGateway.notifyOrderUpdate(updatedOrder);
    return updatedOrder;
  }

  async remove(id: number) {
    const order = await this.findOne(id);
    await this.ordersRepository.delete(id);
    // Optionally notify deletion
    return order;
  }
}

