import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  OneToMany,
  CreateDateColumn,
  UpdateDateColumn,
  VersionColumn,
} from 'typeorm';
import { OrderItem } from './order-item.entity';
import { Payment } from './payment.entity';

@Entity('orders')
export class Order {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true })
  orderNumber: string;

  @Column({ nullable: true })
  tableNumber: string;

  @Column({ default: 'dine-in' })
  type: string;

  @Column({ nullable: true })
  waiterId: number;

  @Column({ default: 'pending' })
  status: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @VersionColumn()
  version: number;

  @Column({ nullable: true })
  lastModifiedBy: string; // device ID

  @Column('float', { default: 0.0 })
  totalAmount: number;

  @Column('float', { default: 0.0 })
  taxAmount: number;

  @Column('float', { default: 0.0 })
  serviceAmount: number;

  @Column({ nullable: true })
  paymentMethod: string;

  @Column('float', { default: 0.0 })
  tipAmount: number;

  @Column({ type: 'varchar', nullable: true })
  taxNumber: string | null;

  @Column({ type: 'timestamp', nullable: true })
  completedAt: Date;

  @Column({ default: false })
  isDeleted: boolean;

  @OneToMany(() => OrderItem, (orderItem) => orderItem.order, { cascade: true })
  items: OrderItem[];

  @OneToMany(() => Payment, (payment) => payment.order, { cascade: true })
  payments: Payment[];

  @Column('float', { default: 0.0 })
  paidAmount: number;
}
