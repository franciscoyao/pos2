import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { TasksService } from './tasks.service';
import { SyncModule } from '../sync/sync.module';
import { EventsModule } from '../events/events.module';

@Module({
  imports: [ScheduleModule.forRoot(), SyncModule, EventsModule],
  providers: [TasksService],
})
export class TasksModule {}
