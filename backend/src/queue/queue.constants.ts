export const QUEUE_NAMES = {
  SYNC: 'sync',
  NOTIFICATIONS: 'notifications',
  REPORTS: 'reports',
  CLEANUP: 'cleanup',
} as const;

export type QueueName = (typeof QUEUE_NAMES)[keyof typeof QUEUE_NAMES];
