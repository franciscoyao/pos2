import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import { SyncService } from '../sync/sync.service';
import { EventsGateway } from '../events/events.gateway';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    private eventsGateway: EventsGateway,
    private syncService: SyncService,
  ) { }

  async findAll(): Promise<User[]> {
    return this.usersRepository.find({
      where: { status: 'active' },
    });
  }

  async findOne(id: number): Promise<User> {
    const user = await this.usersRepository.findOneBy({ id });
    if (!user) {
      throw new NotFoundException(`User #${id} not found`);
    }
    return user;
  }

  async create(userData: Partial<User>, deviceId?: string): Promise<User> {
    const newUser = this.usersRepository.create(userData);
    const savedUser = await this.usersRepository.save(newUser);

    // Record sync change
    await this.syncService.recordChange(
      'user',
      savedUser.id,
      'create',
      savedUser,
      undefined,
      deviceId,
    );

    this.eventsGateway.emitUserUpdate(savedUser);
    return savedUser;
  }

  async update(
    id: number,
    userData: Partial<User>,
    deviceId?: string,
  ): Promise<User> {
    const existingUser = await this.findOne(id);

    await this.usersRepository.update(id, userData);
    const updatedUser = await this.findOne(id);

    // Record sync change
    await this.syncService.recordChange(
      'user',
      id,
      'update',
      updatedUser,
      existingUser,
      deviceId,
    );

    this.eventsGateway.emitUserUpdate(updatedUser);
    return updatedUser;
  }

  async remove(id: number, deviceId?: string): Promise<void> {
    const user = await this.findOne(id);

    // Soft delete by marking as inactive
    user.status = 'inactive';
    await this.usersRepository.save(user);

    // Record sync change
    await this.syncService.recordChange(
      'user',
      id,
      'delete',
      user,
      undefined,
      deviceId,
    );

    this.eventsGateway.emitUserUpdate(user);
  }
}
