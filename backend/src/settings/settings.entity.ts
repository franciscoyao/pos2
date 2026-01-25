import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';

@Entity('settings')
@Index(['category'])
@Index(['key'])
@Index(['isActive'])
export class Setting {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true })
  key: string;

  @Column()
  value: string;

  @Column({ default: 'general' })
  category: string; // 'general', 'payment', 'tax', 'printer', 'notification', 'sync'

  @Column({ nullable: true })
  description: string;

  @Column({ default: 'string' })
  dataType: string; // 'string', 'number', 'boolean', 'json', 'array'

  @Column({ default: true })
  isActive: boolean;

  @Column({ default: false })
  isReadOnly: boolean;

  @Column({ default: false })
  requiresRestart: boolean;

  @Column({ nullable: true })
  validationRule: string; // JSON schema or regex for validation

  @Column({ nullable: true })
  defaultValue: string;

  @Column({ nullable: true })
  lastModifiedBy: string; // Device ID or user ID

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Helper method to get typed value
  getTypedValue(): any {
    switch (this.dataType) {
      case 'number':
        return parseFloat(this.value);
      case 'boolean':
        return this.value === 'true';
      case 'json':
        try {
          return JSON.parse(this.value);
        } catch {
          return null;
        }
      case 'array':
        try {
          return JSON.parse(this.value);
        } catch {
          return [];
        }
      default:
        return this.value;
    }
  }
}

// Predefined settings with their default values
export const DEFAULT_SETTINGS = {
  // General Settings
  'general.restaurant_name': {
    value: 'My Restaurant',
    category: 'general',
    dataType: 'string',
  },
  'general.currency_symbol': {
    value: '$',
    category: 'general',
    dataType: 'string',
  },
  'general.currency_code': {
    value: 'USD',
    category: 'general',
    dataType: 'string',
  },
  'general.timezone': { value: 'UTC', category: 'general', dataType: 'string' },
  'general.language': { value: 'en', category: 'general', dataType: 'string' },
  'general.date_format': {
    value: 'MM/DD/YYYY',
    category: 'general',
    dataType: 'string',
  },
  'general.time_format': {
    value: '12',
    category: 'general',
    dataType: 'string',
  },

  // Tax Settings
  'tax.rate': { value: '0.08', category: 'tax', dataType: 'number' },
  'tax.inclusive': { value: 'false', category: 'tax', dataType: 'boolean' },
  'tax.name': { value: 'Sales Tax', category: 'tax', dataType: 'string' },
  'tax.number': { value: '', category: 'tax', dataType: 'string' },

  // Service Charge Settings
  'service.rate': { value: '0.15', category: 'service', dataType: 'number' },
  'service.auto_apply': {
    value: 'false',
    category: 'service',
    dataType: 'boolean',
  },
  'service.name': {
    value: 'Service Charge',
    category: 'service',
    dataType: 'string',
  },

  // Order Settings
  'order.auto_print': { value: 'true', category: 'order', dataType: 'boolean' },
  'order.delay_threshold': {
    value: '15',
    category: 'order',
    dataType: 'number',
  },
  'order.number_format': {
    value: 'ORD-{YYYY}{MM}{DD}-{###}',
    category: 'order',
    dataType: 'string',
  },
  'order.allow_modifications': {
    value: 'true',
    category: 'order',
    dataType: 'boolean',
  },
  'order.require_confirmation': {
    value: 'false',
    category: 'order',
    dataType: 'boolean',
  },

  // Payment Settings
  'payment.methods': {
    value: JSON.stringify(['cash', 'card', 'digital_wallet']),
    category: 'payment',
    dataType: 'array',
  },
  'payment.cash_rounding': {
    value: 'true',
    category: 'payment',
    dataType: 'boolean',
  },
  'payment.tip_suggestions': {
    value: JSON.stringify([15, 18, 20, 25]),
    category: 'payment',
    dataType: 'array',
  },
  'payment.auto_tip': {
    value: 'false',
    category: 'payment',
    dataType: 'boolean',
  },

  // Printer Settings
  'printer.auto_print_kitchen': {
    value: 'true',
    category: 'printer',
    dataType: 'boolean',
  },
  'printer.auto_print_bar': {
    value: 'true',
    category: 'printer',
    dataType: 'boolean',
  },
  'printer.auto_print_receipt': {
    value: 'true',
    category: 'printer',
    dataType: 'boolean',
  },
  'printer.paper_size': {
    value: '80mm',
    category: 'printer',
    dataType: 'string',
  },

  // Kiosk Settings
  'kiosk.enabled': { value: 'false', category: 'kiosk', dataType: 'boolean' },
  'kiosk.timeout': { value: '300', category: 'kiosk', dataType: 'number' },
  'kiosk.payment_methods': {
    value: JSON.stringify(['card', 'digital_wallet']),
    category: 'kiosk',
    dataType: 'array',
  },
  'kiosk.require_phone': {
    value: 'false',
    category: 'kiosk',
    dataType: 'boolean',
  },

  // Sync Settings
  'sync.interval': { value: '30', category: 'sync', dataType: 'number' },
  'sync.conflict_resolution': {
    value: 'server_wins',
    category: 'sync',
    dataType: 'string',
  },
  'sync.offline_queue_limit': {
    value: '1000',
    category: 'sync',
    dataType: 'number',
  },
  'sync.retry_attempts': { value: '3', category: 'sync', dataType: 'number' },

  // Notification Settings
  'notification.sound_enabled': {
    value: 'true',
    category: 'notification',
    dataType: 'boolean',
  },
  'notification.order_alerts': {
    value: 'true',
    category: 'notification',
    dataType: 'boolean',
  },
  'notification.delay_alerts': {
    value: 'true',
    category: 'notification',
    dataType: 'boolean',
  },
  'notification.payment_alerts': {
    value: 'true',
    category: 'notification',
    dataType: 'boolean',
  },

  // Security Settings
  'security.session_timeout': {
    value: '480',
    category: 'security',
    dataType: 'number',
  },
  'security.max_login_attempts': {
    value: '5',
    category: 'security',
    dataType: 'number',
  },
  'security.lockout_duration': {
    value: '15',
    category: 'security',
    dataType: 'number',
  },
  'security.require_pin': {
    value: 'true',
    category: 'security',
    dataType: 'boolean',
  },

  // Analytics Settings
  'analytics.enabled': {
    value: 'true',
    category: 'analytics',
    dataType: 'boolean',
  },
  'analytics.retention_days': {
    value: '365',
    category: 'analytics',
    dataType: 'number',
  },
  'analytics.track_performance': {
    value: 'true',
    category: 'analytics',
    dataType: 'boolean',
  },
};
