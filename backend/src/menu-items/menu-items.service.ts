import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MenuItem } from './menu-item.entity';

@Injectable()
export class MenuItemsService {
    constructor(
        @InjectRepository(MenuItem)
        private menuItemsRepository: Repository<MenuItem>,
    ) { }

    findAll(): Promise<MenuItem[]> {
        return this.menuItemsRepository.find({ relations: ['category'] });
    }

    create(menuItem: MenuItem): Promise<MenuItem> {
        return this.menuItemsRepository.save(menuItem);
    }

    async update(id: number, menuItemData: Partial<MenuItem>): Promise<void> {
        await this.menuItemsRepository.update(id, menuItemData);
    }
}
