import { Controller, Get, Post, Body, Put, Param, Delete } from '@nestjs/common';
import { CategoriesService } from './categories.service';
import { Category } from './category.entity';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';

@Controller('categories')
export class CategoriesController {
    constructor(private readonly categoriesService: CategoriesService) { }

    @Get()
    findAll(): Promise<Category[]> {
        return this.categoriesService.findAll();
    }

    @Post()
    create(@Body() createCategoryDto: CreateCategoryDto): Promise<Category> {
        // Cast to Category entity if service expects entity, or update service to accept DTO
        return this.categoriesService.create(createCategoryDto as Category);
    }

    @Put(':id')
    update(@Param('id') id: string, @Body() updateCategoryDto: UpdateCategoryDto): Promise<void> {
        return this.categoriesService.update(+id, updateCategoryDto);
    }

    @Delete(':id')
    remove(@Param('id') id: string): Promise<void> {
        return this.categoriesService.remove(+id);
    }
}
