import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, ManyToOne, JoinColumn, OneToMany } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { OrderItem } from '../../order-items/entities/order-item.entity';


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

    @Column('decimal', { default: 0 })
    totalAmount: number;

    @Column('decimal', { default: 0 })
    taxAmount: number;

    @Column('decimal', { default: 0 })
    serviceAmount: number;

    @Column({ nullable: true })
    paymentMethod: string;

    @Column('decimal', { default: 0 })
    tipAmount: number;

    @Column({ nullable: true })
    taxNumber: string;

    @Column({ nullable: true })
    completedAt: Date;

    @ManyToOne(() => User, (user) => user.orders, { onDelete: 'SET NULL' })
    @JoinColumn({ name: 'waiterId' })
    waiter: User;

    @OneToMany(() => OrderItem, (item) => item.order)
    items: OrderItem[];
}
