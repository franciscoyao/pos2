import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToMany,
  JoinTable,
  Index,
} from 'typeorm';
import { Role } from '../auth/entities/role.entity';

@Entity('users')
@Index(['username'])
@Index(['email'])
@Index(['pin'])
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ nullable: true })
  fullName: string;

  @Column({ unique: true, nullable: true })
  username: string;

  @Column({ unique: true, nullable: true })
  email: string;

  @Column({ nullable: true })
  firstName: string;

  @Column({ nullable: true })
  lastName: string;

  @Column({ nullable: true, select: false })
  password: string; // Hashed password for admin users

  @Column({ nullable: true, select: false })
  pin: string; // Hashed 4-digit PIN

  @Column({ default: 'waiter' })
  role: string; // Legacy field for backward compatibility

  @Column({ default: 'active' })
  status: string; // 'active', 'inactive', 'suspended'

  @Column({ nullable: true })
  phoneNumber: string;

  @Column({ nullable: true })
  profileImage: string;

  @Column({ default: false })
  isActive: boolean;

  @Column({ default: false })
  emailVerified: boolean;

  @Column({ nullable: true })
  lastLoginAt: Date;

  @Column({ nullable: true })
  lastLoginDevice: string;

  @Column({ default: 0 })
  loginAttempts: number;

  @Column({ nullable: true })
  lockedUntil: Date;

  // Preferences and settings
  @Column('jsonb', { nullable: true })
  preferences: {
    language?: string;
    timezone?: string;
    theme?: string;
    notifications?: boolean;
    soundEnabled?: boolean;
  };

  // Work schedule and shifts
  @Column('jsonb', { nullable: true })
  workSchedule: {
    shifts?: Array<{
      day: string;
      startTime: string;
      endTime: string;
    }>;
    hourlyRate?: number;
    department?: string;
  };

  // Performance metrics
  @Column('jsonb', { nullable: true })
  metrics: {
    ordersProcessed?: number;
    averageOrderTime?: number;
    customerRating?: number;
    totalSales?: number;
  };

  @ManyToMany(() => Role, (role) => role.users, { cascade: true })
  @JoinTable({
    name: 'user_roles',
    joinColumn: { name: 'userId', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'roleId', referencedColumnName: 'id' },
  })
  roles: Role[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Virtual properties
  get displayName(): string {
    return (
      this.fullName ||
      `${this.firstName} ${this.lastName}`.trim() ||
      this.username
    );
  }

  get isLocked(): boolean {
    return this.lockedUntil && this.lockedUntil > new Date();
  }
}
