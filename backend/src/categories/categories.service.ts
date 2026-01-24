import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Category } from './category.entity';

import { EventsGateway } from '../events/events.gateway';

@Injectable()
export class CategoriesService {
    constructor(
        @InjectRepository(Category)
        private categoriesRepository: Repository<Category>,
        private eventsGateway: EventsGateway,
    ) { }

    findAll(): Promise<Category[]> {
        return this.categoriesRepository.find();
    }

    async create(category: Category): Promise<Category> {
        const savedCategory = await this.categoriesRepository.save(category);
        this.eventsGateway.emitCategoryUpdate(savedCategory);
        return savedCategory;
    }

    async update(id: number, categoryData: Partial<Category>): Promise<void> {
        await this.categoriesRepository.update(id, categoryData);
        const updatedCategory = await this.categoriesRepository.findOneBy({ id });
        if (updatedCategory) {
            this.eventsGateway.emitCategoryUpdate(updatedCategory);
        }
    }

    async remove(id: number): Promise<void> {
        await this.categoriesRepository.delete(id);
        // Optionally emit a delete event if needed
    }
}
