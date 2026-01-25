import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';
import { Order } from './order.entity';
import { MenuItem } from '../menu-items/menu-item.entity';
import { Payment } from './payment.entity';

@Entity('order_items')
@Index(['orderId'])
@Index(['menuItemId'])
@Index(['status'])
export class OrderItem {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  orderId: number;

  @ManyToOne(() => Order, (order) => order.items, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'orderId' })
  order: Order;

  @Column()
  menuItemId: number;

  @ManyToOne(() => MenuItem, { eager: true })
  @JoinColumn({ name: 'menuItemId' })
  menuItem: MenuItem;

  @Column({ default: 1 })
  quantity: number;

  @Column('decimal', { precision: 10, scale: 2 })
  priceAtTime: number;

  @Column({ default: 'pending' })
  status: string; // 'pending', 'accepted', 'cooking', 'ready', 'served', 'paid', 'cancelled'

  @Column({ nullable: true })
  paymentId: number;

  @ManyToOne(() => Payment, { nullable: true })
  @JoinColumn({ name: 'paymentId' })
  payment: Payment;

  // Kitchen/Bar specific fields
  @Column({ nullable: true })
  station: string; // 'kitchen', 'bar'

  @Column({ nullable: true })
  preparationTime: number; // Estimated time in minutes

  @Column({ nullable: true })
  startedAt: Date; // When cooking/preparation started

  @Column({ nullable: true })
  readyAt: Date; // When item was marked ready

  @Column({ nullable: true })
  servedAt: Date; // When item was served

  // Special instructions and modifications
  @Column('text', { nullable: true })
  specialInstructions: string;

  @Column('jsonb', { nullable: true })
  modifications: Array<{
    type: 'add' | 'remove' | 'substitute';
    item: string;
    price?: number;
  }>;

  // Allergen and dietary information
  @Column('simple-array', { nullable: true })
  allergens: string[];

  @Column('jsonb', { nullable: true })
  dietaryInfo: {
    vegetarian?: boolean;
    vegan?: boolean;
    glutenFree?: boolean;
    dairyFree?: boolean;
    nutFree?: boolean;
  };

  // Tracking and audit
  @Column({ nullable: true })
  assignedTo: number; // User ID of staff member handling this item

  @Column({ nullable: true })
  lastModifiedBy: string; // Device ID

  @Column({ default: false })
  isDeleted: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Calculated properties
  get totalPrice(): number {
    const basePrice = this.priceAtTime * this.quantity;
    const modificationPrice =
      this.modifications?.reduce((sum, mod) => sum + (mod.price || 0), 0) || 0;
    return basePrice + modificationPrice;
  }

  get isOverdue(): boolean {
    if (!this.preparationTime || !this.startedAt) return false;
    const expectedReadyTime = new Date(
      this.startedAt.getTime() + this.preparationTime * 60000,
    );
    return (
      new Date() > expectedReadyTime &&
      this.status !== 'ready' &&
      this.status !== 'served'
    );
  }

  get preparationDuration(): number | null {
    if (!this.startedAt || !this.readyAt) return null;
    return Math.round(
      (this.readyAt.getTime() - this.startedAt.getTime()) / 60000,
    ); // in minutes
  }
}
