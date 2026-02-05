import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Category } from '../../categories/entities/category.entity';

@Entity('menu_items')
export class MenuItem {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ unique: true, nullable: true })
    code: string;

    @Column()
    name: string;

    @Column('decimal', { precision: 10, scale: 2 })
    price: number;

    @Column()
    categoryId: number;

    @Column({ default: 'kitchen' })
    station: string;

    @Column({ default: 'dine-in' })
    type: string;

    @Column({ default: 'active' })
    status: string;

    @Column({ default: false })
    allowPriceEdit: boolean;

    @ManyToOne(() => Category, (category) => category.menuItems, { onDelete: 'SET NULL' })
    @JoinColumn({ name: 'categoryId' })
    category: Category;
}

