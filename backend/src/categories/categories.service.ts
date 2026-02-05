import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';
import { Category } from './entities/category.entity';
import { OrdersGateway } from '../orders/orders.gateway';

@Injectable()
export class CategoriesService {
  constructor(
    @InjectRepository(Category)
    private categoriesRepository: Repository<Category>,
    private ordersGateway: OrdersGateway,
  ) { }

  async create(createCategoryDto: CreateCategoryDto) {
    const category = this.categoriesRepository.create(createCategoryDto);
    const savedCategory = await this.categoriesRepository.save(category);
    this.ordersGateway.notifyCategoryUpdate(savedCategory);
    return savedCategory;
  }

  findAll() {
    return this.categoriesRepository.find({ order: { sortOrder: 'ASC' } });
  }

  findOne(id: number) {
    return this.categoriesRepository.findOneBy({ id });
  }

  async update(id: number, updateCategoryDto: UpdateCategoryDto) {
    await this.categoriesRepository.update(id, updateCategoryDto);
    const updatedCategory = await this.findOne(id);
    this.ordersGateway.notifyCategoryUpdate(updatedCategory);
    return updatedCategory;
  }

  async remove(id: number) {
    const category = await this.findOne(id);
    await this.categoriesRepository.delete(id);
    // You might want to notify deletion as well, or handle it via update with status 'deleted'
    return category;
  }
}
