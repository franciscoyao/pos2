import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Order } from './order.entity';
import { MenuItem } from '../menu-items/menu-item.entity';
import { Payment } from './payment.entity';

@Entity('order_items')
export class OrderItem {
    @PrimaryGeneratedColumn()
    id: number;

    @Column()
    orderId: number;

    @ManyToOne(() => Order, (order) => order.items)
    @JoinColumn({ name: 'orderId' })
    order: Order;

    @Column()
    menuItemId: number;

    @ManyToOne(() => MenuItem)
    @JoinColumn({ name: 'menuItemId' })
    menuItem: MenuItem;

    @Column({ default: 1 })
    quantity: number;

    @Column('float')
    priceAtTime: number;

    @Column({ default: 'pending' })
    status: string; // 'pending', 'cooking', 'served', 'paid'

    @Column({ nullable: true })
    paymentId: number;

    @ManyToOne(() => Payment)
    @JoinColumn({ name: 'paymentId' })
    payment: Payment;
}
