import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';

@Entity('sync_records')
@Index(['entityType', 'entityId'])
@Index(['deviceId', 'createdAt'])
export class SyncRecord {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  entityType: string; // 'order', 'table', 'menu_item', 'category', 'user'

  @Column()
  entityId: number;

  @Column()
  action: string; // 'create', 'update', 'delete'

  @Column('jsonb', { nullable: true })
  data: any;

  @Column('jsonb', { nullable: true })
  previousData: any;

  @Column()
  version: number;

  @Column({ nullable: true })
  deviceId: string;

  @Column({ nullable: true })
  userId: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @Column({ default: false })
  synced: boolean;

  @Column('timestamp', { nullable: true })
  syncedAt: Date;

  @Column({ nullable: true })
  conflictResolution: string; // 'server_wins', 'client_wins', 'merged'
}
