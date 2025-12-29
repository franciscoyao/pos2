import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Category } from '../categories/category.entity';

@Entity('menu_items')
export class MenuItem {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ unique: true, nullable: true })
    code: string;

    @Column()
    name: string;

    @Column('float')
    price: number;

    @Column()
    categoryId: number;

    @ManyToOne(() => Category)
    @JoinColumn({ name: 'categoryId' })
    category: Category;

    @Column({ default: 'kitchen' })
    station: string;

    @Column({ default: 'dine-in' })
    type: string;

    @Column({ default: 'active' })
    status: string;

    @Column({ default: false })
    allowPriceEdit: boolean;
}
