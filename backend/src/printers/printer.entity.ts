import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';

@Entity('printers')
@Index(['role'])
@Index(['status'])
@Index(['isActive'])
export class Printer {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  name: string;

  @Column({ nullable: true })
  description: string;

  @Column({ nullable: true })
  macAddress: string;

  @Column({ nullable: true })
  ipAddress: string;

  @Column({ default: 'bluetooth' })
  connectionType: string; // 'bluetooth', 'wifi', 'usb', 'network'

  @Column({ default: 'kitchen' })
  role: string; // 'kitchen', 'bar', 'receipt', 'label'

  @Column({ default: 'offline' })
  status: string; // 'online', 'offline', 'error', 'printing', 'out_of_paper'

  @Column({ default: true })
  isActive: boolean;

  @Column({ default: false })
  isDefault: boolean; // Default printer for this role

  // Printer specifications
  @Column({ default: '80mm' })
  paperSize: string; // '58mm', '80mm', '112mm'

  @Column({ default: 'thermal' })
  printerType: string; // 'thermal', 'impact', 'inkjet', 'laser'

  @Column({ default: 'ESC/POS' })
  commandSet: string; // 'ESC/POS', 'CPCL', 'ZPL'

  @Column({ default: 203 })
  dpi: number; // Dots per inch

  @Column({ default: 32 })
  charactersPerLine: number;

  // Connection settings
  @Column('jsonb', { nullable: true })
  connectionSettings: {
    // Bluetooth settings
    bluetoothName?: string;
    bluetoothPin?: string;

    // Network settings
    port?: number;
    timeout?: number;

    // USB settings
    vendorId?: string;
    productId?: string;

    // WiFi settings
    ssid?: string;
    password?: string;
  };

  // Print settings
  @Column('jsonb', { nullable: true })
  printSettings: {
    // Layout settings
    marginTop?: number;
    marginBottom?: number;
    marginLeft?: number;
    marginRight?: number;

    // Font settings
    fontSize?: 'small' | 'medium' | 'large';
    fontWeight?: 'normal' | 'bold';

    // Print quality
    density?: number;
    speed?: number;

    // Paper settings
    autoCut?: boolean;
    cutType?: 'full' | 'partial';

    // Receipt settings
    printLogo?: boolean;
    logoPath?: string;
    printHeader?: boolean;
    printFooter?: boolean;

    // Kitchen/Bar settings
    printTime?: boolean;
    printTable?: boolean;
    printWaiter?: boolean;
    printSpecialInstructions?: boolean;
  };

  // Filter settings - what to print
  @Column('jsonb', { nullable: true })
  filterSettings: {
    // Station filtering
    stations?: string[]; // ['kitchen', 'bar']

    // Category filtering
    categories?: number[];

    // Menu type filtering
    menuTypes?: string[]; // ['dine-in', 'takeaway']

    // Order type filtering
    orderTypes?: string[]; // ['new', 'modification', 'cancellation']

    // Time-based filtering
    startTime?: string; // HH:MM
    endTime?: string; // HH:MM

    // Day-based filtering
    activeDays?: string[]; // ['monday', 'tuesday', ...]
  };

  // Status tracking
  @Column({ nullable: true })
  lastPrintAt: Date;

  @Column({ nullable: true })
  lastErrorAt: Date;

  @Column({ nullable: true })
  lastErrorMessage: string;

  @Column({ default: 0 })
  totalPrintJobs: number;

  @Column({ default: 0 })
  failedPrintJobs: number;

  @Column({ nullable: true })
  paperLevel: number; // Percentage (0-100)

  @Column({ nullable: true })
  inkLevel: number; // Percentage (0-100)

  // Maintenance
  @Column({ nullable: true })
  lastMaintenanceAt: Date;

  @Column({ nullable: true })
  nextMaintenanceAt: Date;

  @Column('jsonb', { nullable: true })
  maintenanceLog: Array<{
    date: Date;
    type: string;
    description: string;
    performedBy: string;
  }>;

  // Device association
  @Column({ nullable: true })
  assignedDeviceId: string; // Device that manages this printer

  @Column({ nullable: true })
  lastModifiedBy: string; // Device ID

  @Column({ default: false })
  isDeleted: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Calculated properties
  get successRate(): number {
    if (this.totalPrintJobs === 0) return 100;
    return (
      ((this.totalPrintJobs - this.failedPrintJobs) / this.totalPrintJobs) * 100
    );
  }

  get isOnline(): boolean {
    return this.status === 'online';
  }

  get needsMaintenance(): boolean {
    return this.nextMaintenanceAt && this.nextMaintenanceAt < new Date();
  }

  get isLowOnPaper(): boolean {
    return this.paperLevel !== null && this.paperLevel < 20;
  }

  get isLowOnInk(): boolean {
    return this.inkLevel !== null && this.inkLevel < 20;
  }
}
