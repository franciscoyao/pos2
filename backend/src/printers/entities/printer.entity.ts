import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity('printers')
export class Printer {
    @PrimaryGeneratedColumn()
    id: number;

    @Column()
    name: string;

    @Column()
    macAddress: string;

    @Column()
    role: string; // "kitchen", "bar", "receipt"

    @Column({ default: 'active' })
    status: string;
}

