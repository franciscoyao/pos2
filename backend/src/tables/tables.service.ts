import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RestaurantTable } from './table.entity';

import { EventsGateway } from '../events/events.gateway';

@Injectable()
export class TablesService {
    constructor(
        @InjectRepository(RestaurantTable)
        private tablesRepository: Repository<RestaurantTable>,
        private eventsGateway: EventsGateway,
    ) { }

    findAll(): Promise<RestaurantTable[]> {
        return this.tablesRepository.find();
    }

    create(table: RestaurantTable): Promise<RestaurantTable> {
        return this.tablesRepository.save(table);
    }

    async update(id: number, tableData: Partial<RestaurantTable>): Promise<void> {
        await this.tablesRepository.update(id, tableData);
        const updatedTable = await this.tablesRepository.findOneBy({ id });
        this.eventsGateway.emitTableUpdate(updatedTable);
    }
}
