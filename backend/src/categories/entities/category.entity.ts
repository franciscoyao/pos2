import { Entity, Column, PrimaryGeneratedColumn, OneToMany } from 'typeorm';
import { MenuItem } from '../../menu-items/entities/menu-item.entity';


@Entity('categories')
export class Category {
    @PrimaryGeneratedColumn()
    id: number;

    @Column()
    name: string;

    @Column({ default: 'dine-in' })
    menuType: string;

    @Column({ default: 0 })
    sortOrder: number;

    @Column({ nullable: true })
    station: string;

    @Column({ default: 'active' })
    status: string;

    @OneToMany(() => MenuItem, (menuItem) => menuItem.category)
    menuItems: MenuItem[];
}
