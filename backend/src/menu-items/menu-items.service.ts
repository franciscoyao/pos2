import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CreateMenuItemDto } from './dto/create-menu-item.dto';
import { UpdateMenuItemDto } from './dto/update-menu-item.dto';
import { MenuItem } from './entities/menu-item.entity';
import { OrdersGateway } from '../orders/orders.gateway';

@Injectable()
export class MenuItemsService {
  constructor(
    @InjectRepository(MenuItem)
    private menuItemsRepository: Repository<MenuItem>,
    private ordersGateway: OrdersGateway,
  ) { }

  async create(createMenuItemDto: CreateMenuItemDto) {
    const menuItem = this.menuItemsRepository.create(createMenuItemDto);
    const savedMenuItem = await this.menuItemsRepository.save(menuItem);
    this.ordersGateway.notifyMenuItemUpdate(savedMenuItem);
    return savedMenuItem;
  }

  findAll() {
    return this.menuItemsRepository.find();
  }

  findOne(id: number) {
    return this.menuItemsRepository.findOneBy({ id });
  }

  async update(id: number, updateMenuItemDto: UpdateMenuItemDto) {
    await this.menuItemsRepository.update(id, updateMenuItemDto);
    const updatedMenuItem = await this.findOne(id);
    this.ordersGateway.notifyMenuItemUpdate(updatedMenuItem);
    return updatedMenuItem;
  }

  async remove(id: number) {
    const menuItem = await this.findOne(id);
    await this.menuItemsRepository.delete(id);
    // Notify deletion if supported by frontend
    return menuItem;
  }
}
