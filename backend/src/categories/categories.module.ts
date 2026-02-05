import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CategoriesService } from './categories.service';
import { CategoriesController } from './categories.controller';
import { Category } from './entities/category.entity';
import { OrdersModule } from '../orders/orders.module';

@Module({
  imports: [TypeOrmModule.forFeature([Category]), OrdersModule],
  controllers: [CategoriesController],
  providers: [CategoriesService],
})
export class CategoriesModule { }

