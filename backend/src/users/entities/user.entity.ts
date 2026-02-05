import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, OneToMany } from 'typeorm';
import { Order } from '../../orders/entities/order.entity';


@Entity('users')
export class User {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ nullable: true })
    fullName: string;

    @Column({ unique: true, nullable: true })
    username: string;

    @Column({ nullable: true })
    pin: string;

    @Column()
    role: string; // "admin", "waiter", "kitchen", "bar", "kiosk"

    @Column({ default: 'active' })
    status: string;

    @CreateDateColumn()
    createdAt: Date;

    @OneToMany(() => Order, (order) => order.waiter)
    orders: Order[];
}
