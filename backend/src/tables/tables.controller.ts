import { Controller, Get, Post, Body, Put, Param } from '@nestjs/common';
import { TablesService } from './tables.service';
import { RestaurantTable } from './table.entity';

@Controller('tables')
export class TablesController {
  constructor(private readonly tablesService: TablesService) {}

  @Get()
  findAll(): Promise<RestaurantTable[]> {
    return this.tablesService.findAll();
  }

  @Post()
  create(@Body() table: RestaurantTable): Promise<RestaurantTable> {
    return this.tablesService.create(table);
  }

  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() table: Partial<RestaurantTable>,
  ): Promise<RestaurantTable> {
    return this.tablesService.update(+id, table);
  }
}
