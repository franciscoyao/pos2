import { Injectable, Inject, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import { Category } from './category.entity';
import { EventEmitter2 } from '@nestjs/event-emitter';

@Injectable()
export class CategoriesService {
  constructor(
    @InjectRepository(Category)
    private categoriesRepository: Repository<Category>,
    @Inject(CACHE_MANAGER) private cacheManager: Cache,
    private eventEmitter: EventEmitter2,
  ) { }

  async findAll(): Promise<Category[]> {
    const cached = await this.cacheManager.get<Category[]>('categories:all');
    if (cached) {
      return cached;
    }

    const categories = await this.categoriesRepository.find({
      order: {
        sortOrder: 'ASC',
        name: 'ASC',
      },
    });

    await this.cacheManager.set('categories:all', categories, 60000); // 1 minute cache
    return categories;
  }

  async findOne(id: number): Promise<Category> {
    const category = await this.categoriesRepository.findOne({ where: { id } });

    if (!category) {
      throw new NotFoundException(`Category with ID ${id} not found`);
    }

    return category;
  }

  async create(createDto: Partial<Category>, deviceId?: string): Promise<Category> {
    const category = this.categoriesRepository.create(createDto);
    const saved = await this.categoriesRepository.save(category);

    await this.cacheManager.del('categories:all');
    this.eventEmitter.emit('category.updated', { ...saved, deviceId });

    return saved;
  }

  async update(id: number, updateDto: Partial<Category>, deviceId?: string): Promise<Category> {
    const category = await this.findOne(id);
    Object.assign(category, updateDto);
    const saved = await this.categoriesRepository.save(category);

    await this.cacheManager.del('categories:all');
    this.eventEmitter.emit('category.updated', { ...saved, deviceId });

    return saved;
  }

  async remove(id: number, deviceId?: string): Promise<void> {
    const category = await this.findOne(id);
    await this.categoriesRepository.remove(category);

    await this.cacheManager.del('categories:all');
    this.eventEmitter.emit('category.deleted', { id, deviceId });
  }
}
