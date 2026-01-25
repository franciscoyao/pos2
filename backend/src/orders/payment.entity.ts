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

@Entity('payments')
@Index(['orderId'])
@Index(['method'])
@Index(['status'])
@Index(['createdAt'])
export class Payment {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  orderId: number;

  @ManyToOne(() => Order, (order) => order.payments, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'orderId' })
  order: Order;

  @Column('decimal', { precision: 10, scale: 2 })
  amount: number;

  @Column()
  method: string; // 'cash', 'card', 'digital_wallet', 'gift_card', 'store_credit'

  @Column({ default: 'pending' })
  status: string; // 'pending', 'processing', 'success', 'failed', 'refunded', 'cancelled'

  // Payment method specific details
  @Column('jsonb', { nullable: true })
  paymentDetails: {
    // Card payments
    cardType?: 'visa' | 'mastercard' | 'amex' | 'discover';
    last4?: string;
    authCode?: string;
    transactionId?: string;

    // Digital wallet
    walletType?: 'apple_pay' | 'google_pay' | 'samsung_pay';
    walletTransactionId?: string;

    // Cash payments
    amountTendered?: number;
    changeGiven?: number;

    // Gift card / Store credit
    cardNumber?: string;
    remainingBalance?: number;
  };

  // Split payment information
  @Column({ nullable: true })
  splitType: string; // 'item', 'equal', 'amount', 'percentage'

  @Column('jsonb', { nullable: true })
  splitDetails: {
    // For item-based splits
    itemIds?: number[];

    // For equal splits
    splitCount?: number;
    splitIndex?: number;

    // For amount/percentage splits
    splitAmount?: number;
    splitPercentage?: number;

    // Customer information for split
    customerName?: string;
    customerPhone?: string;
  };

  // Tip and service charges
  @Column('decimal', { precision: 10, scale: 2, default: 0 })
  tipAmount: number;

  @Column('decimal', { precision: 10, scale: 2, default: 0 })
  serviceCharge: number;

  @Column('decimal', { precision: 10, scale: 2, default: 0 })
  taxAmount: number;

  // Processing information
  @Column({ nullable: true })
  processedBy: number; // User ID who processed the payment

  @Column({ nullable: true })
  processedAt: Date;

  @Column({ nullable: true })
  deviceId: string; // Device that processed the payment

  // Receipt and tracking
  @Column({ nullable: true })
  receiptNumber: string;

  @Column({ nullable: true })
  externalTransactionId: string; // From payment processor

  @Column('jsonb', { nullable: true })
  processorResponse: any; // Raw response from payment processor

  // Refund information
  @Column({ nullable: true })
  refundedAt: Date;

  @Column({ nullable: true })
  refundReason: string;

  @Column('decimal', { precision: 10, scale: 2, nullable: true })
  refundAmount: number;

  @Column({ nullable: true })
  refundedBy: number; // User ID who processed the refund

  // Audit trail
  @Column({ nullable: true })
  lastModifiedBy: string; // Device ID

  @Column({ default: false })
  isDeleted: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Calculated properties
  get totalAmount(): number {
    return this.amount + this.tipAmount + this.serviceCharge + this.taxAmount;
  }

  get isRefundable(): boolean {
    return this.status === 'success' && !this.refundedAt;
  }

  get processingTime(): number | null {
    if (!this.processedAt) return null;
    return Math.round(
      (this.processedAt.getTime() - this.createdAt.getTime()) / 1000,
    ); // in seconds
  }
}
