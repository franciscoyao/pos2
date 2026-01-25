import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Order } from '../orders/order.entity';
import { OrderItem } from '../orders/order-item.entity';
import { Payment } from '../orders/payment.entity';
import { MenuItem } from '../menu-items/menu-item.entity';
import { User } from '../users/user.entity';
import { CacheService } from '../cache/cache.service';
import { register, Counter, Histogram, Gauge } from 'prom-client';

export interface SalesMetrics {
  totalSales: number;
  totalOrders: number;
  averageOrderValue: number;
  totalTax: number;
  totalTips: number;
  totalServiceCharges: number;
  paymentMethods: Record<string, number>;
  hourlyBreakdown: Array<{ hour: number; sales: number; orders: number }>;
}

export interface PerformanceMetrics {
  averageOrderTime: number;
  averageKitchenTime: number;
  averageServiceTime: number;
  ordersByStatus: Record<string, number>;
  delayedOrders: number;
  cancelledOrders: number;
}

export interface PopularityMetrics {
  topItems: Array<{ item: MenuItem; quantity: number; revenue: number }>;
  topCategories: Array<{
    categoryId: number;
    categoryName: string;
    quantity: number;
    revenue: number;
  }>;
  leastPopular: Array<{ item: MenuItem; quantity: number }>;
}

export interface StaffMetrics {
  waiterPerformance: Array<{
    waiter: User;
    ordersProcessed: number;
    totalSales: number;
    averageOrderValue: number;
    averageServiceTime: number;
  }>;
  kitchenPerformance: {
    averagePreparationTime: number;
    ordersCompleted: number;
    delayedOrders: number;
  };
}

@Injectable()
export class MetricsService {
  private readonly logger = new Logger(MetricsService.name);

  // Prometheus metrics
  private readonly orderCounter = new Counter({
    name: 'pos_orders_total',
    help: 'Total number of orders',
    labelNames: ['status', 'type', 'payment_method'],
  });

  private readonly salesGauge = new Gauge({
    name: 'pos_sales_total',
    help: 'Total sales amount',
    labelNames: ['period'],
  });

  private readonly orderDurationHistogram = new Histogram({
    name: 'pos_order_duration_seconds',
    help: 'Order processing duration',
    labelNames: ['status'],
    buckets: [60, 300, 600, 900, 1800, 3600], // 1min to 1hour
  });

  private readonly kitchenTimeHistogram = new Histogram({
    name: 'pos_kitchen_time_seconds',
    help: 'Kitchen preparation time',
    labelNames: ['station'],
    buckets: [60, 300, 600, 900, 1200, 1800], // 1min to 30min
  });

  constructor(
    @InjectRepository(Order)
    private ordersRepository: Repository<Order>,
    @InjectRepository(OrderItem)
    private orderItemsRepository: Repository<OrderItem>,
    @InjectRepository(Payment)
    private paymentsRepository: Repository<Payment>,
    @InjectRepository(MenuItem)
    private menuItemsRepository: Repository<MenuItem>,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    private cacheService: CacheService,
  ) {
    // Register Prometheus metrics
    register.registerMetric(this.orderCounter);
    register.registerMetric(this.salesGauge);
    register.registerMetric(this.orderDurationHistogram);
    register.registerMetric(this.kitchenTimeHistogram);
  }

  async getSalesMetrics(startDate: Date, endDate: Date): Promise<SalesMetrics> {
    const cacheKey = `metrics:sales:${startDate.toISOString()}:${endDate.toISOString()}`;

    return await this.cacheService.getOrSet(
      cacheKey,
      async () => {
        const orders = await this.ordersRepository.find({
          where: {
            createdAt: Between(startDate, endDate),
            status: 'completed',
            isDeleted: false,
          },
          relations: ['payments'],
        });

        const totalSales = orders.reduce(
          (sum, order) => sum + order.totalAmount,
          0,
        );
        const totalOrders = orders.length;
        const averageOrderValue =
          totalOrders > 0 ? totalSales / totalOrders : 0;
        const totalTax = orders.reduce(
          (sum, order) => sum + order.taxAmount,
          0,
        );
        const totalTips = orders.reduce(
          (sum, order) => sum + order.tipAmount,
          0,
        );
        const totalServiceCharges = orders.reduce(
          (sum, order) => sum + order.serviceAmount,
          0,
        );

        // Payment methods breakdown
        const paymentMethods: Record<string, number> = {};
        orders.forEach((order) => {
          order.payments?.forEach((payment) => {
            paymentMethods[payment.method] =
              (paymentMethods[payment.method] || 0) + payment.amount;
          });
        });

        // Hourly breakdown
        const hourlyBreakdown = Array.from({ length: 24 }, (_, hour) => ({
          hour,
          sales: 0,
          orders: 0,
        }));

        orders.forEach((order) => {
          const hour = order.createdAt.getHours();
          hourlyBreakdown[hour].sales += order.totalAmount;
          hourlyBreakdown[hour].orders += 1;
        });

        return {
          totalSales,
          totalOrders,
          averageOrderValue,
          totalTax,
          totalTips,
          totalServiceCharges,
          paymentMethods,
          hourlyBreakdown,
        };
      },
      CacheService.TTL.MEDIUM,
    );
  }

  async getPerformanceMetrics(
    startDate: Date,
    endDate: Date,
  ): Promise<PerformanceMetrics> {
    const cacheKey = `metrics:performance:${startDate.toISOString()}:${endDate.toISOString()}`;

    return await this.cacheService.getOrSet(
      cacheKey,
      async () => {
        const orders = await this.ordersRepository.find({
          where: {
            createdAt: Between(startDate, endDate),
            isDeleted: false,
          },
          relations: ['items'],
        });

        // Calculate average order time (from creation to completion)
        const completedOrders = orders.filter((o) => o.completedAt);
        const averageOrderTime =
          completedOrders.length > 0
            ? completedOrders.reduce((sum, order) => {
                return (
                  sum +
                  (order.completedAt.getTime() - order.createdAt.getTime())
                );
              }, 0) /
              completedOrders.length /
              1000 /
              60 // Convert to minutes
            : 0;

        // Calculate kitchen performance
        const kitchenItems = await this.orderItemsRepository.find({
          where: {
            createdAt: Between(startDate, endDate),
            station: 'kitchen',
            startedAt: Between(startDate, endDate),
            readyAt: Between(startDate, endDate),
          },
        });

        const averageKitchenTime =
          kitchenItems.length > 0
            ? kitchenItems.reduce((sum, item) => {
                if (item.startedAt && item.readyAt) {
                  return (
                    sum + (item.readyAt.getTime() - item.startedAt.getTime())
                  );
                }
                return sum;
              }, 0) /
              kitchenItems.length /
              1000 /
              60 // Convert to minutes
            : 0;

        // Calculate service time (from ready to served)
        const servedItems = await this.orderItemsRepository.find({
          where: {
            createdAt: Between(startDate, endDate),
            readyAt: Between(startDate, endDate),
            servedAt: Between(startDate, endDate),
          },
        });

        const averageServiceTime =
          servedItems.length > 0
            ? servedItems.reduce((sum, item) => {
                if (item.readyAt && item.servedAt) {
                  return (
                    sum + (item.servedAt.getTime() - item.readyAt.getTime())
                  );
                }
                return sum;
              }, 0) /
              servedItems.length /
              1000 /
              60 // Convert to minutes
            : 0;

        // Orders by status
        const ordersByStatus: Record<string, number> = {};
        orders.forEach((order) => {
          ordersByStatus[order.status] =
            (ordersByStatus[order.status] || 0) + 1;
        });

        // Delayed orders (taking longer than expected)
        const delayedOrders = kitchenItems.filter(
          (item) => item.isOverdue,
        ).length;

        // Cancelled orders
        const cancelledOrders = orders.filter(
          (o) => o.status === 'cancelled',
        ).length;

        return {
          averageOrderTime,
          averageKitchenTime,
          averageServiceTime,
          ordersByStatus,
          delayedOrders,
          cancelledOrders,
        };
      },
      CacheService.TTL.MEDIUM,
    );
  }

  async getPopularityMetrics(
    startDate: Date,
    endDate: Date,
    limit: number = 10,
  ): Promise<PopularityMetrics> {
    const cacheKey = `metrics:popularity:${startDate.toISOString()}:${endDate.toISOString()}:${limit}`;

    return await this.cacheService.getOrSet(
      cacheKey,
      async () => {
        // Top items by quantity and revenue
        const itemStats = await this.orderItemsRepository
          .createQueryBuilder('item')
          .leftJoinAndSelect('item.menuItem', 'menuItem')
          .leftJoinAndSelect('menuItem.category', 'category')
          .select([
            'menuItem.id as menuItemId',
            'menuItem.name as name',
            'menuItem.price as price',
            'category.name as categoryName',
            'SUM(item.quantity) as totalQuantity',
            'SUM(item.quantity * item.priceAtTime) as totalRevenue',
          ])
          .where('item.createdAt BETWEEN :startDate AND :endDate', {
            startDate,
            endDate,
          })
          .groupBy('menuItem.id, menuItem.name, menuItem.price, category.name')
          .orderBy('totalQuantity', 'DESC')
          .limit(limit)
          .getRawMany();

        const topItems = (
          await Promise.all(
            itemStats.map(async (stat) => {
              const item = await this.menuItemsRepository.findOne({
                where: { id: stat.menuItemId },
                relations: ['category'],
              });
              return {
                item,
                quantity: parseInt(stat.totalQuantity),
                revenue: parseFloat(stat.totalRevenue),
              };
            }),
          )
        ).filter(
          (
            result,
          ): result is { item: MenuItem; quantity: number; revenue: number } =>
            result.item !== null,
        );

        // Top categories
        const categoryStats = await this.orderItemsRepository
          .createQueryBuilder('item')
          .leftJoinAndSelect('item.menuItem', 'menuItem')
          .leftJoinAndSelect('menuItem.category', 'category')
          .select([
            'category.id as categoryId',
            'category.name as categoryName',
            'SUM(item.quantity) as totalQuantity',
            'SUM(item.quantity * item.priceAtTime) as totalRevenue',
          ])
          .where('item.createdAt BETWEEN :startDate AND :endDate', {
            startDate,
            endDate,
          })
          .groupBy('category.id, category.name')
          .orderBy('totalQuantity', 'DESC')
          .getRawMany();

        const topCategories = categoryStats.map((stat) => ({
          categoryId: stat.categoryId,
          categoryName: stat.categoryName,
          quantity: parseInt(stat.totalQuantity),
          revenue: parseFloat(stat.totalRevenue),
        }));

        // Least popular items
        const leastPopularStats = await this.orderItemsRepository
          .createQueryBuilder('item')
          .leftJoinAndSelect('item.menuItem', 'menuItem')
          .select([
            'menuItem.id as menuItemId',
            'SUM(item.quantity) as totalQuantity',
          ])
          .where('item.createdAt BETWEEN :startDate AND :endDate', {
            startDate,
            endDate,
          })
          .groupBy('menuItem.id')
          .orderBy('totalQuantity', 'ASC')
          .limit(limit)
          .getRawMany();

        const leastPopular = (
          await Promise.all(
            leastPopularStats.map(async (stat) => {
              const item = await this.menuItemsRepository.findOne({
                where: { id: stat.menuItemId },
                relations: ['category'],
              });
              return {
                item,
                quantity: parseInt(stat.totalQuantity),
              };
            }),
          )
        ).filter(
          (result): result is { item: MenuItem; quantity: number } =>
            result.item !== null,
        );

        return {
          topItems,
          topCategories,
          leastPopular,
        };
      },
      CacheService.TTL.MEDIUM,
    );
  }

  async getStaffMetrics(startDate: Date, endDate: Date): Promise<StaffMetrics> {
    const cacheKey = `metrics:staff:${startDate.toISOString()}:${endDate.toISOString()}`;

    return await this.cacheService.getOrSet(
      cacheKey,
      async () => {
        // Waiter performance
        const waiterStats = await this.ordersRepository
          .createQueryBuilder('order')
          .leftJoin(User, 'waiter', 'waiter.id = order.waiterId')
          .select([
            'order.waiterId as waiterId',
            'COUNT(order.id) as ordersProcessed',
            'SUM(order.totalAmount) as totalSales',
            'AVG(order.totalAmount) as averageOrderValue',
          ])
          .where('order.createdAt BETWEEN :startDate AND :endDate', {
            startDate,
            endDate,
          })
          .andWhere('order.waiterId IS NOT NULL')
          .andWhere('order.isDeleted = false')
          .groupBy('order.waiterId')
          .getRawMany();

        const waiterPerformance = await Promise.all(
          waiterStats.map(async (stat) => {
            const waiter = await this.usersRepository.findOne({
              where: { id: stat.waiterId },
            });

            if (!waiter) return null;

            // Calculate average service time for this waiter
            const waiterOrders = await this.ordersRepository.find({
              where: {
                waiterId: stat.waiterId,
                createdAt: Between(startDate, endDate),
                completedAt: Between(startDate, endDate),
              },
            });

            const averageServiceTime =
              waiterOrders.length > 0
                ? waiterOrders.reduce((sum, order) => {
                    return (
                      sum +
                      (order.completedAt.getTime() - order.createdAt.getTime())
                    );
                  }, 0) /
                  waiterOrders.length /
                  1000 /
                  60 // Convert to minutes
                : 0;

            return {
              waiter,
              ordersProcessed: parseInt(stat.ordersProcessed),
              totalSales: parseFloat(stat.totalSales),
              averageOrderValue: parseFloat(stat.averageOrderValue),
              averageServiceTime,
            };
          }),
        ).then((results) => results.filter((result) => result !== null));

        // Kitchen performance
        const kitchenItems = await this.orderItemsRepository.find({
          where: {
            createdAt: Between(startDate, endDate),
            station: 'kitchen',
          },
        });

        const completedKitchenItems = kitchenItems.filter(
          (item) => item.readyAt,
        );
        const averagePreparationTime =
          completedKitchenItems.length > 0
            ? completedKitchenItems.reduce((sum, item) => {
                if (item.startedAt && item.readyAt) {
                  return (
                    sum + (item.readyAt.getTime() - item.startedAt.getTime())
                  );
                }
                return sum;
              }, 0) /
              completedKitchenItems.length /
              1000 /
              60 // Convert to minutes
            : 0;

        const delayedKitchenOrders = kitchenItems.filter(
          (item) => item.isOverdue,
        ).length;

        const kitchenPerformance = {
          averagePreparationTime,
          ordersCompleted: completedKitchenItems.length,
          delayedOrders: delayedKitchenOrders,
        };

        return {
          waiterPerformance,
          kitchenPerformance,
        };
      },
      CacheService.TTL.MEDIUM,
    );
  }

  async recordOrderMetric(order: Order): Promise<void> {
    // Record Prometheus metrics
    this.orderCounter.inc({
      status: order.status,
      type: order.type,
      payment_method: order.paymentMethod || 'unknown',
    });

    if (order.status === 'completed' && order.completedAt) {
      const duration =
        (order.completedAt.getTime() - order.createdAt.getTime()) / 1000;
      this.orderDurationHistogram.observe({ status: order.status }, duration);
    }

    // Update daily sales gauge
    const today = new Date().toISOString().split('T')[0];
    const todaySales = await this.getTodaySales();
    this.salesGauge.set({ period: 'daily' }, todaySales);
  }

  async recordKitchenMetric(item: OrderItem): Promise<void> {
    if (item.startedAt && item.readyAt) {
      const duration =
        (item.readyAt.getTime() - item.startedAt.getTime()) / 1000;
      this.kitchenTimeHistogram.observe(
        { station: item.station || 'kitchen' },
        duration,
      );
    }
  }

  async getDashboardMetrics(): Promise<any> {
    const today = new Date();
    const startOfDay = new Date(
      today.getFullYear(),
      today.getMonth(),
      today.getDate(),
    );
    const endOfDay = new Date(
      today.getFullYear(),
      today.getMonth(),
      today.getDate() + 1,
    );

    const [salesMetrics, performanceMetrics] = await Promise.all([
      this.getSalesMetrics(startOfDay, endOfDay),
      this.getPerformanceMetrics(startOfDay, endOfDay),
    ]);

    return {
      today: {
        sales: salesMetrics,
        performance: performanceMetrics,
      },
      timestamp: new Date(),
    };
  }

  private async getTodaySales(): Promise<number> {
    const today = new Date();
    const startOfDay = new Date(
      today.getFullYear(),
      today.getMonth(),
      today.getDate(),
    );
    const endOfDay = new Date(
      today.getFullYear(),
      today.getMonth(),
      today.getDate() + 1,
    );

    const result = await this.ordersRepository
      .createQueryBuilder('order')
      .select('SUM(order.totalAmount)', 'total')
      .where('order.createdAt BETWEEN :start AND :end', {
        start: startOfDay,
        end: endOfDay,
      })
      .andWhere('order.status = :status', { status: 'completed' })
      .andWhere('order.isDeleted = false')
      .getRawOne();

    return parseFloat(result?.total || '0');
  }
}
