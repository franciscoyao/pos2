import { Controller, Get, Post, Body, Put, Param } from '@nestjs/common';
import { CategoriesService } from './categories.service';
import { Category } from './category.entity';

@Controller('categories')
export class CategoriesController {
    constructor(private readonly categoriesService: CategoriesService) { }

    @Get()
    findAll(): Promise<Category[]> {
        return this.categoriesService.findAll();
    }

    @Post()
    create(@Body() category: Category): Promise<Category> {
        return this.categoriesService.create(category);
    }

    @Put(':id')
    update(@Param('id') id: string, @Body() category: Partial<Category>): Promise<void> {
        return this.categoriesService.update(+id, category);
    }
}
