import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Order } from '../../orders/entities/order.entity';
import { MenuItem } from '../../menu-items/entities/menu-item.entity';

@Entity('order_items')
export class OrderItem {
    @PrimaryGeneratedColumn()
    id: number;

    @Column()
    orderId: number;

    @Column()
    menuItemId: number;

    @Column({ default: 1 })
    quantity: number;

    @Column('decimal', { precision: 10, scale: 2 })
    priceAtTime: number;

    @Column({ default: 'pending' })
    status: string;

    @ManyToOne(() => Order, (order) => order.items, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'orderId' })
    order: Order;

    @ManyToOne(() => MenuItem)
    @JoinColumn({ name: 'menuItemId' })
    menuItem: MenuItem;
}

