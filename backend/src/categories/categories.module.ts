import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Category } from './category.entity';
import { CategoriesController } from './categories.controller';
import { CategoriesService } from './categories.service';

import { EventsModule } from '../events/events.module';

@Module({
    imports: [TypeOrmModule.forFeature([Category]), EventsModule],
    controllers: [CategoriesController],
    providers: [CategoriesService],
})
export class CategoriesModule { }
