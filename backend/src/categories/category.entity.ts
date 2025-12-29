import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

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
}
