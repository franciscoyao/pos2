import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MenuItem } from './menu-item.entity';

import { EventsGateway } from '../events/events.gateway';

@Injectable()
export class MenuItemsService {
    constructor(
        @InjectRepository(MenuItem)
        private menuItemsRepository: Repository<MenuItem>,
        private eventsGateway: EventsGateway,
    ) { }

    findAll(): Promise<MenuItem[]> {
        return this.menuItemsRepository.find({ relations: ['category'] });
    }

    async create(menuItem: MenuItem): Promise<MenuItem> {
        const savedItem = await this.menuItemsRepository.save(menuItem);
        this.eventsGateway.emitMenuItemUpdate(savedItem);
        return savedItem;
    }

    async update(id: number, menuItemData: Partial<MenuItem>): Promise<void> {
        await this.menuItemsRepository.update(id, menuItemData);
        const updatedItem = await this.menuItemsRepository.findOne({
            where: { id },
            relations: ['category']
        });
        if (updatedItem) {
            this.eventsGateway.emitMenuItemUpdate(updatedItem);
        }
    }
}
