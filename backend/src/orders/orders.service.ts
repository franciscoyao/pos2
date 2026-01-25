import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, MoreThan } from 'typeorm';
import { Order } from './order.entity';
import { Payment } from './payment.entity';
import { OrderItem } from './order-item.entity';
import { EventsGateway } from '../events/events.gateway';
import { SyncService } from '../sync/sync.service';
import { In } from 'typeorm';

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order)
    private ordersRepository: Repository<Order>,
    @InjectRepository(Payment)
    private paymentsRepository: Repository<Payment>,
    @InjectRepository(OrderItem)
    private orderItemsRepository: Repository<OrderItem>,
    private eventsGateway: EventsGateway,
    private syncService: SyncService,
  ) {}

  // Get all orders
  findAll(): Promise<Order[]> {
    return this.ordersRepository.find({
      where: { isDeleted: false },
      relations: ['items', 'items.menuItem'],
      order: { createdAt: 'DESC' },
    });
  }

  // Get active orders (pending, preparing, ready)
  async getActiveOrders(): Promise<Order[]> {
    return this.ordersRepository.find({
      where: [
        { status: 'pending' },
        { status: 'preparing' },
        { status: 'ready' },
      ],
      relations: ['items', 'items.menuItem'],
      order: { createdAt: 'DESC' },
    });
  }

  // Get orders by date range
  async getOrdersByDateRange(startDate: Date, endDate: Date): Promise<Order[]> {
    return this.ordersRepository.find({
      where: {
        createdAt: Between(startDate, endDate),
      },
      relations: ['items', 'items.menuItem'],
      order: { createdAt: 'DESC' },
    });
  }

  // Get orders for sync (Active + Recent History)
  async getSyncOrders(): Promise<Order[]> {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    return this.ordersRepository.find({
      where: [
        // Active orders (not completed or cancelled)
        { status: 'pending' },
        { status: 'sent' },
        { status: 'accepted' },
        { status: 'cooking' },
        { status: 'ready' },
        { status: 'served' },
        { status: 'paid' }, // 'paid' is still open until table is cleared/completed
        // Recent history
        { status: 'completed', createdAt: MoreThan(sevenDaysAgo) },
        { status: 'cancelled', createdAt: MoreThan(sevenDaysAgo) },
      ],
      relations: ['items', 'items.menuItem'],
      order: { createdAt: 'DESC' },
    });
  }

  // Get order by ID
  async findOne(id: number): Promise<Order> {
    const order = await this.ordersRepository.findOne({
      where: { id },
      relations: ['items', 'items.menuItem', 'payments'],
    });

    if (!order) {
      throw new NotFoundException(`Order with ID ${id} not found`);
    }

    return order;
  }

  // Get orders by table
  async getOrdersByTable(tableNumber: string): Promise<Order[]> {
    return this.ordersRepository.find({
      where: { tableNumber },
      relations: ['items', 'items.menuItem'],
      order: { createdAt: 'DESC' },
    });
  }

  // Create new order
  async create(orderData: Partial<Order>, deviceId?: string): Promise<Order> {
    const newOrder = this.ordersRepository.create({
      ...orderData,
      lastModifiedBy: deviceId,
    });
    const savedOrder = await this.ordersRepository.save(newOrder);

    // Record sync change
    await this.syncService.recordChange(
      'order',
      savedOrder.id,
      'create',
      savedOrder,
      undefined,
      deviceId,
    );

    // Fetch with relations
    const orderWithRelations = await this.findOne(savedOrder.id);

    // Emit WebSocket event
    this.eventsGateway.emitNewOrder(orderWithRelations, deviceId);

    return orderWithRelations;
  }

  // Update order
  async update(
    id: number,
    orderData: Partial<Order>,
    deviceId?: string,
  ): Promise<Order> {
    const existingOrder = await this.findOne(id);

    await this.ordersRepository.update(id, {
      ...orderData,
      lastModifiedBy: deviceId,
    });

    const updatedOrder = await this.findOne(id);

    // Record sync change
    await this.syncService.recordChange(
      'order',
      id,
      'update',
      updatedOrder,
      existingOrder,
      deviceId,
    );

    // Emit WebSocket event
    this.eventsGateway.emitOrderUpdate(updatedOrder, deviceId);

    return updatedOrder;
  }

  // Update order status
  async updateStatus(
    id: number,
    status: string,
    deviceId?: string,
  ): Promise<Order> {
    const order = await this.findOne(id);

    if (status === 'completed') {
      order.completedAt = new Date();
    }

    order.status = status;
    order.lastModifiedBy = deviceId || 'system';
    const updatedOrder = await this.ordersRepository.save(order);

    // Record sync change
    await this.syncService.recordChange(
      'order',
      id,
      'update',
      updatedOrder,
      order,
      deviceId,
    );

    // Emit WebSocket event
    this.eventsGateway.emitOrderUpdate(updatedOrder, deviceId);

    return updatedOrder;
  }

  // Complete order with payment
  async completeOrder(
    id: number,
    paymentData: {
      paymentMethod: string;
      tipAmount?: number;
      taxNumber?: string;
    },
  ): Promise<Order> {
    const order = await this.findOne(id);

    order.status = 'completed';
    order.completedAt = new Date();
    order.paymentMethod = paymentData.paymentMethod;
    order.tipAmount = paymentData.tipAmount || 0;
    order.taxNumber = paymentData.taxNumber || null;

    const completedOrder = await this.ordersRepository.save(order);

    // Emit WebSocket event
    this.eventsGateway.emitOrderUpdate(completedOrder);

    return completedOrder;
  }

  // Delete order
  async remove(id: number, deviceId?: string): Promise<void> {
    const order = await this.findOne(id);

    // Soft delete
    order.isDeleted = true;
    order.lastModifiedBy = deviceId || 'system';
    await this.ordersRepository.save(order);

    // Record sync change
    await this.syncService.recordChange(
      'order',
      id,
      'delete',
      { id, isDeleted: true },
      order,
      deviceId,
    );

    // Emit WebSocket event
    this.eventsGateway.emitOrderDelete(id, deviceId);
  }

  // Get sales statistics
  async getSalesStats(startDate: Date, endDate: Date) {
    const orders = await this.getOrdersByDateRange(startDate, endDate);

    const completed = orders.filter((o) => o.status === 'completed');

    const totalSales = completed.reduce((sum, o) => sum + o.totalAmount, 0);
    const totalTax = completed.reduce((sum, o) => sum + o.taxAmount, 0);
    const totalService = completed.reduce((sum, o) => sum + o.serviceAmount, 0);
    const totalTips = completed.reduce((sum, o) => sum + o.tipAmount, 0);

    return {
      totalOrders: completed.length,
      totalSales,
      totalTax,
      totalService,
      totalTips,
      averageOrderValue:
        completed.length > 0 ? totalSales / completed.length : 0,
    };
  }

  // Pay specific items (Split Bill by Item)
  async payItems(
    orderId: number,
    items: { id: number; quantity: number }[],
    paymentMethod: string,
  ): Promise<Order> {
    const order = await this.findOne(orderId);

    // Filter items that belong to order and are not paid
    // Ensure we process each item request
    const itemRequests = items.filter((req) => {
      const exists = order.items.find(
        (i) => i.id === req.id && i.status !== 'paid',
      );
      return !!exists;
    });

    if (itemRequests.length === 0) {
      throw new Error('No valid items found to pay');
    }

    let totalPayAmount = 0;
    const paidItems: OrderItem[] = [];

    // Create Payment first or after calculating amount?
    // We need amount first.
    // Loop to calculate amount and validate quantities
    for (const req of itemRequests) {
      const originalItem = order.items.find((i) => i.id === req.id)!;

      if (req.quantity > originalItem.quantity) {
        throw new Error(
          `Cannot pay more than quantity for item ${originalItem.menuItem.name}`,
        );
      }
      totalPayAmount += originalItem.priceAtTime * req.quantity;
    }

    // Create Payment
    const payment = this.paymentsRepository.create({
      order,
      amount: totalPayAmount,
      method: paymentMethod,
      status: 'success',
    });
    const savedPayment = await this.paymentsRepository.save(payment);

    // Update/Split Items
    for (const req of itemRequests) {
      const originalItem = order.items.find((i) => i.id === req.id)!;

      if (req.quantity === originalItem.quantity) {
        // Pay full item
        originalItem.status = 'paid';
        originalItem.payment = savedPayment;
        await this.orderItemsRepository.save(originalItem);
        paidItems.push(originalItem);
      } else {
        // Partial pay: Split item
        // 1. Decrease original item quantity
        originalItem.quantity -= req.quantity;
        await this.orderItemsRepository.save(originalItem);

        // 2. Create new paid item
        const newItem = this.orderItemsRepository.create({
          ...originalItem,
          id: undefined, // New ID
          quantity: req.quantity,
          status: 'paid',
          payment: savedPayment,
          order: order, // Same order
        });
        await this.orderItemsRepository.save(newItem);
        paidItems.push(newItem);
      }
    }

    // Update Order Paid Amount
    order.paidAmount = (order.paidAmount || 0) + totalPayAmount;

    // Check if fully paid
    // Logic: If all items in order are paid.
    // We need to re-fetch items or check local state.
    // Since we modifying items (adding new ones, updating old ones), let's just check if any item is not paid.
    // But wait, we added new items.
    // The original items might still exist with reduced quantity.
    // We should check if ALL items belonging to this order have status 'paid'.

    // Refresh order items to be sure
    const refreshedItems = await this.orderItemsRepository.find({
      where: { order: { id: orderId } },
    });
    const allItemsPaid = refreshedItems.every((i) => i.status === 'paid');

    if (allItemsPaid) {
      order.status = 'paid';
      order.completedAt = new Date();
    }

    await this.ordersRepository.save(order);

    const updatedOrder = await this.findOne(orderId);
    this.eventsGateway.emitOrderUpdate(updatedOrder);
    return updatedOrder;
  }

  // Add generic payment (Split Bill Equal/Amount)
  async addPayment(
    orderId: number,
    amount: number,
    method: string,
  ): Promise<Order> {
    const order = await this.findOne(orderId);

    const payment = this.paymentsRepository.create({
      order,
      amount,
      method,
      status: 'success',
    });
    await this.paymentsRepository.save(payment);

    order.paidAmount = (order.paidAmount || 0) + amount;

    // Check if fully paid (fuzzy check for float)
    if (order.paidAmount >= order.totalAmount - 0.01) {
      order.status = 'paid';
      order.completedAt = new Date();
      // Mark all items as paid if not already
      for (const item of order.items) {
        if (item.status !== 'paid') {
          item.status = 'paid';
          await this.orderItemsRepository.save(item);
        }
      }
    }

    await this.ordersRepository.save(order);
    const updatedOrder = await this.findOne(orderId);
    this.eventsGateway.emitOrderUpdate(updatedOrder);
    return updatedOrder;
  }

  // Split Table (Move items to another table)
  // Split Table (Move items to another table)
  async splitTable(
    currentOrderNumber: string,
    targetTableNumber: string,
    items: { id: number; quantity: number }[],
    newOrderNumber?: string,
  ): Promise<Order> {
    // 1. Get current order
    const currentOrder = await this.ordersRepository.findOne({
      where: { orderNumber: currentOrderNumber },
      relations: ['items', 'items.menuItem'],
    });

    if (!currentOrder) {
      throw new NotFoundException(
        `Order with number ${currentOrderNumber} not found`,
      );
    }

    // 2. Find or Create target order
    let targetOrder = await this.ordersRepository.findOne({
      where: {
        tableNumber: targetTableNumber,
        status: In(['pending', 'active', 'cooking', 'served']),
      },
      relations: ['items', 'items.menuItem'],
    });

    if (!targetOrder) {
      // Create derived order number: Original-Split-Timestamp
      // OR use provided newOrderNumber
      let newOrderNum = newOrderNumber;
      if (!newOrderNum) {
        const suffix = Math.floor(Math.random() * 1000);
        newOrderNum = `${currentOrder.orderNumber}-S${suffix}`;
      }

      targetOrder = this.ordersRepository.create({
        tableNumber: targetTableNumber,
        status: 'pending',
        orderNumber: newOrderNum,
        type: currentOrder.type,
        waiterId: currentOrder.waiterId,
      });
      targetOrder = await this.ordersRepository.save(targetOrder);
    }

    // 3. Move items
    const itemRequests = items.filter((req) => {
      const item = currentOrder.items.find((i) => i.id === req.id);
      return item != null;
    });

    let movedAmount = 0;
    for (const req of itemRequests) {
      const originalItem = currentOrder.items.find((i) => i.id === req.id)!;

      if (req.quantity > originalItem.quantity) {
        throw new Error(
          `Cannot move more than quantity for item ${originalItem.menuItem.name}`,
        );
      }

      if (req.quantity === originalItem.quantity) {
        // Move entire item
        originalItem.order = targetOrder;
        movedAmount += originalItem.priceAtTime * originalItem.quantity;
        await this.orderItemsRepository.save(originalItem);
      } else {
        // Split item
        // Decrease original
        originalItem.quantity -= req.quantity;
        await this.orderItemsRepository.save(originalItem);

        // Create new item in target order
        const newItem = this.orderItemsRepository.create({
          ...originalItem,
          id: undefined,
          quantity: req.quantity,
          order: targetOrder,
        });
        movedAmount += newItem.priceAtTime * newItem.quantity;
        await this.orderItemsRepository.save(newItem);
      }
    }

    // 4. Update totals
    currentOrder.totalAmount = Math.max(
      0,
      currentOrder.totalAmount - movedAmount,
    );
    targetOrder.totalAmount = (targetOrder.totalAmount || 0) + movedAmount;

    await this.ordersRepository.save(targetOrder);

    // Check if current order is empty
    const remainingItemsCount = await this.orderItemsRepository.count({
      where: { order: { id: currentOrder.id } },
    });

    if (remainingItemsCount === 0) {
      await this.ordersRepository.remove(currentOrder);
      this.eventsGateway.emitOrderDelete(currentOrder.id);
    } else {
      await this.ordersRepository.save(currentOrder);
      const updatedCurrent = await this.findOne(currentOrder.id);
      this.eventsGateway.emitOrderUpdate(updatedCurrent);
    }

    // 5. Emit updates for target
    const updatedTarget = await this.findOne(targetOrder.id);
    this.eventsGateway.emitNewOrder(updatedTarget);

    if (remainingItemsCount > 0) {
      return await this.findOne(currentOrder.id);
    } else {
      // Source order deleted, return target order
      return updatedTarget;
    }
  }

  // Merge Tables (Move all orders from one table to another)
  async mergeTables(
    fromTableNumber: string,
    toTableNumber: string,
  ): Promise<void> {
    const fromOrders = await this.ordersRepository.find({
      where: {
        tableNumber: fromTableNumber,
        status: In(['pending', 'active', 'cooking', 'served', 'ready']),
      },
      relations: ['items'],
    });

    if (fromOrders.length === 0) {
      throw new Error(`No active orders on table ${fromTableNumber}`);
    }

    // Check if target has an order
    const targetOrder = await this.ordersRepository.findOne({
      where: {
        tableNumber: toTableNumber,
        status: In(['pending', 'active', 'cooking', 'served', 'ready']),
      },
      relations: ['items'],
    });

    if (targetOrder) {
      // Merge into targetOrder
      for (const order of fromOrders) {
        for (const item of order.items) {
          item.order = targetOrder;
          await this.orderItemsRepository.save(item);
        }
        // Update target totals
        targetOrder.totalAmount =
          (targetOrder.totalAmount || 0) + order.totalAmount;
        // Delete old order
        await this.ordersRepository.remove(order);
      }
      await this.ordersRepository.save(targetOrder);
      this.eventsGateway.emitOrderUpdate(targetOrder);
    } else {
      // Just reassign tables
      for (const order of fromOrders) {
        order.tableNumber = toTableNumber;
        await this.ordersRepository.save(order);
        this.eventsGateway.emitNewOrder(order); // It appears as new on that table
      }
    }

    // Emit table updates (via some mechanism, or allow frontend to refresh based on order updates)
    // Ideally we should emit 'refresh-tables' or similar if we scraped tables status.
    // But Since table status is derived from orders usually, or manual.
    // If table entity has status 'occupied', we should update it.
    // But OrdersService doesn't inject TablesService (circular dependency risk).
    // We'll rely on frontend to refresh or events.
  }
}
