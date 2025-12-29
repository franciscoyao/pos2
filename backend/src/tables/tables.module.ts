import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RestaurantTable } from './table.entity';
import { TablesController } from './tables.controller';
import { TablesService } from './tables.service';
import { EventsModule } from '../events/events.module';

@Module({
    imports: [
        TypeOrmModule.forFeature([RestaurantTable]),
        EventsModule
    ],
    controllers: [TablesController],
    providers: [TablesService],
})
export class TablesModule { }
