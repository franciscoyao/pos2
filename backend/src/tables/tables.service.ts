import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CreateTableDto } from './dto/create-table.dto';
import { UpdateTableDto } from './dto/update-table.dto';
import { RestaurantTable } from './entities/table.entity';
import { OrdersGateway } from '../orders/orders.gateway';

@Injectable()
export class TablesService {
  constructor(
    @InjectRepository(RestaurantTable)
    private tablesRepository: Repository<RestaurantTable>,
    private ordersGateway: OrdersGateway,
  ) { }

  async create(createTableDto: CreateTableDto) {
    const table = this.tablesRepository.create(createTableDto);
    const savedTable = await this.tablesRepository.save(table);
    this.ordersGateway.notifyTableUpdate(savedTable);
    return savedTable;
  }

  findAll() {
    return this.tablesRepository.find();
  }

  findOne(id: number) {
    return this.tablesRepository.findOneBy({ id });
  }

  async update(id: number, updateTableDto: UpdateTableDto) {
    await this.tablesRepository.update(id, updateTableDto);
    const updatedTable = await this.findOne(id);
    this.ordersGateway.notifyTableUpdate(updatedTable);
    return updatedTable;
  }

  async remove(id: number) {
    const table = await this.findOne(id);
    await this.tablesRepository.delete(id);
    // notify deletion if needed
    return table;
  }
}

