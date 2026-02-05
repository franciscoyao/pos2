import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity('settings')
export class Setting {
    @PrimaryGeneratedColumn()
    id: number;

    @Column('decimal', { default: 0 })
    taxRate: number;

    @Column('decimal', { default: 0 })
    serviceRate: number;

    @Column({ default: '$' })
    currencySymbol: string;

    @Column({ default: false })
    kioskMode: boolean;

    @Column({ default: 15 })
    orderDelayThreshold: number;
}

