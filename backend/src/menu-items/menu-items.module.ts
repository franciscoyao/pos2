import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MenuItem } from './menu-item.entity';
import { MenuItemsController } from './menu-items.controller';
import { MenuItemsService } from './menu-items.service';

import { EventsModule } from '../events/events.module';

@Module({
    imports: [TypeOrmModule.forFeature([MenuItem]), EventsModule],
    controllers: [MenuItemsController],
    providers: [MenuItemsService],
})
export class MenuItemsModule { }
