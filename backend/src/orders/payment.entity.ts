import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, JoinColumn, CreateDateColumn } from 'typeorm';
import { Order } from './order.entity';

@Entity('payments')
export class Payment {
    @PrimaryGeneratedColumn()
    id: number;

    @Column()
    orderId: number;

    @ManyToOne(() => Order, (order) => order.payments)
    @JoinColumn({ name: 'orderId' })
    order: Order;

    @Column('float')
    amount: number;

    @Column()
    method: string; // 'cash', 'card', 'mixed'

    @Column({ default: 'success' })
    status: string;

    @CreateDateColumn()
    createdAt: Date;
}
