import { Injectable, Inject, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import { MenuItem } from './menu-item.entity';
import { EventEmitter2 } from '@nestjs/event-emitter';

@Injectable()
export class MenuItemsService {
  constructor(
    @InjectRepository(MenuItem)
    private menuItemsRepository: Repository<MenuItem>,
    @Inject(CACHE_MANAGER) private cacheManager: Cache,
    private eventEmitter: EventEmitter2,
  ) { }

  async findAll(): Promise<MenuItem[]> {
    const cached = await this.cacheManager.get<MenuItem[]>('menu_items:all');
    if (cached) {
      return cached;
    }

    const items = await this.menuItemsRepository.find({
      relations: ['category'],
      order: {
        category: {
          sortOrder: 'ASC',
        },
        name: 'ASC',
      },
    });

    await this.cacheManager.set('menu_items:all', items, 60000); // 1 minute cache
    return items;
  }

  async findOne(id: number): Promise<MenuItem> {
    const item = await this.menuItemsRepository.findOne({
      where: { id },
      relations: ['category'],
    });

    if (!item) {
      throw new NotFoundException(`Menu item with ID ${id} not found`);
    }

    return item;
  }

  async findByCategory(categoryId: number): Promise<MenuItem[]> {
    const allItems = await this.findAll();
    return allItems.filter(item => item.category?.id === +categoryId);
  }

  async create(createDto: Partial<MenuItem>, deviceId?: string): Promise<MenuItem> {
    const item = this.menuItemsRepository.create(createDto);
    const saved = await this.menuItemsRepository.save(item);

    await this.cacheManager.del('menu_items:all');
    this.eventEmitter.emit('menu-item.updated', { ...saved, deviceId });

    return saved;
  }

  async update(id: number, updateDto: Partial<MenuItem>, deviceId?: string): Promise<MenuItem> {
    const item = await this.findOne(id);
    Object.assign(item, updateDto);
    const saved = await this.menuItemsRepository.save(item);

    await this.cacheManager.del('menu_items:all');
    this.eventEmitter.emit('menu-item.updated', { ...saved, deviceId });

    return saved;
  }

  async remove(id: number, deviceId?: string): Promise<void> {
    const item = await this.findOne(id);
    await this.menuItemsRepository.remove(item);

    await this.cacheManager.del('menu_items:all');
    this.eventEmitter.emit('menu-item.deleted', { id, deviceId });
  }
}
