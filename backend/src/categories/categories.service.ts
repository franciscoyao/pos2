import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Category } from './category.entity';

@Injectable()
export class CategoriesService {
    constructor(
        @InjectRepository(Category)
        private categoriesRepository: Repository<Category>,
    ) { }

    findAll(): Promise<Category[]> {
        return this.categoriesRepository.find();
    }

    create(category: Category): Promise<Category> {
        return this.categoriesRepository.save(category);
    }

    async update(id: number, categoryData: Partial<Category>): Promise<void> {
        await this.categoriesRepository.update(id, categoryData);
    }
}
