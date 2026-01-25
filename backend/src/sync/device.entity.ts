import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('devices')
export class Device {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true })
  deviceId: string;

  @Column()
  deviceName: string;

  @Column()
  deviceType: string; // 'tablet', 'phone', 'desktop', 'kiosk'

  @Column({ nullable: true })
  userId: number;

  @Column({ default: 'online' })
  status: string; // 'online', 'offline', 'syncing'

  @Column('timestamp', { nullable: true })
  lastSeenAt: Date;

  @Column('timestamp', { nullable: true })
  lastSyncAt: Date;

  @Column({ default: 0 })
  syncVersion: number;

  @Column('jsonb', { nullable: true })
  capabilities: any; // { canTakeOrders: true, canManageMenu: false, etc. }

  @Column('jsonb', { nullable: true })
  settings: any;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
