import { Controller, Get, Post, Body, Put, Param } from '@nestjs/common';
import { MenuItemsService } from './menu-items.service';
import { MenuItem } from './menu-item.entity';

@Controller('menu-items')
export class MenuItemsController {
    constructor(private readonly menuItemsService: MenuItemsService) { }

    @Get()
    findAll(): Promise<MenuItem[]> {
        return this.menuItemsService.findAll();
    }

    @Post()
    create(@Body() menuItem: MenuItem): Promise<MenuItem> {
        return this.menuItemsService.create(menuItem);
    }

    @Put(':id')
    update(@Param('id') id: string, @Body() menuItem: Partial<MenuItem>): Promise<void> {
        return this.menuItemsService.update(+id, menuItem);
    }
}
