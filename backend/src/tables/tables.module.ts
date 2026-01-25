import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RestaurantTable } from './table.entity';
import { TablesController } from './tables.controller';
import { TablesService } from './tables.service';
import { EventsModule } from '../events/events.module';
import { SyncModule } from '../sync/sync.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([RestaurantTable]),
    EventsModule,
    SyncModule,
  ],
  controllers: [TablesController],
  providers: [TablesService],
  exports: [TablesService],
})
export class TablesModule { }
