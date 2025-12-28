import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MenuItem } from './menu-item.entity';
import { MenuItemsController } from './menu-items.controller';
import { MenuItemsService } from './menu-items.service';

@Module({
    imports: [TypeOrmModule.forFeature([MenuItem])],
    controllers: [MenuItemsController],
    providers: [MenuItemsService],
})
export class MenuItemsModule { }
