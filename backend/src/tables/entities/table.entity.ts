import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity('restaurant_tables')
export class RestaurantTable {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ unique: true })
    name: string;

    @Column({ default: 'available' })
    status: string;

    @Column({ default: 0 })
    x: number;

    @Column({ default: 0 })
    y: number;
}

