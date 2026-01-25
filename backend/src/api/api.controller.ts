import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  Headers,
} from '@nestjs/common';
import { OrdersService } from '../orders/orders.service';
import { TablesService } from '../tables/tables.service';
import { MenuItemsService } from '../menu-items/menu-items.service';
import { CategoriesService } from '../categories/categories.service';
import { UsersService } from '../users/users.service';
import { SyncService } from '../sync/sync.service';

@Controller('api')
export class ApiController {
  constructor(
    private readonly ordersService: OrdersService,
    private readonly tablesService: TablesService,
    private readonly menuItemsService: MenuItemsService,
    private readonly categoriesService: CategoriesService,
    private readonly usersService: UsersService,
    private readonly syncService: SyncService,
  ) {}

  private getDeviceId(headers: any): string | undefined {
    return headers['x-device-id'] || headers['device-id'];
  }

  // Orders API
  @Get('orders')
  async getOrders() {
    return await this.ordersService.findAll();
  }

  @Get('orders/active')
  async getActiveOrders() {
    return await this.ordersService.getActiveOrders();
  }

  @Get('orders/sync')
  async getSyncOrders() {
    return await this.ordersService.getSyncOrders();
  }

  @Get('orders/table/:tableNumber')
  async getOrdersByTable(@Param('tableNumber') tableNumber: string) {
    return await this.ordersService.getOrdersByTable(tableNumber);
  }

  @Get('orders/:id')
  async getOrder(@Param('id') id: number) {
    return await this.ordersService.findOne(id);
  }

  @Post('orders')
  async createOrder(@Body() orderData: any, @Headers() headers: any) {
    const deviceId = this.getDeviceId(headers);
    return await this.ordersService.create(orderData, deviceId);
  }

  @Put('orders/:id')
  async updateOrder(
    @Param('id') id: number,
    @Body() orderData: any,
    @Headers() headers: any,
  ) {
    const deviceId = this.getDeviceId(headers);
    return await this.ordersService.update(id, orderData, deviceId);
  }

  @Put('orders/:id/status')
  async updateOrderStatus(
    @Param('id') id: number,
    @Body() body: { status: string },
    @Headers() headers: any,
  ) {
    const deviceId = this.getDeviceId(headers);
    return await this.ordersService.updateStatus(id, body.status, deviceId);
  }

  @Delete('orders/:id')
  async deleteOrder(@Param('id') id: number, @Headers() headers: any) {
    const deviceId = this.getDeviceId(headers);
    return await this.ordersService.remove(id, deviceId);
  }

  @Post('orders/:id/payments')
  async addPayment(
    @Param('id') id: number,
    @Body() paymentData: { amount: number; method: string },
    @Headers() headers: any,
  ) {
    const deviceId = this.getDeviceId(headers);
    return await this.ordersService.addPayment(
      id,
      paymentData.amount,
      paymentData.method,
    );
  }

  // Tables API
  @Get('tables')
  async getTables() {
    return await this.tablesService.findAll();
  }

  @Get('tables/available')
  async getAvailableTables() {
    return await this.tablesService.getAvailableTables();
  }

  @Get('tables/occupied')
  async getOccupiedTables() {
    return await this.tablesService.getOccupiedTables();
  }

  @Get('tables/:id')
  async getTable(@Param('id') id: number) {
    return await this.tablesService.findOne(id);
  }

  @Post('tables')
  async createTable(@Body() tableData: any, @Headers() headers: any) {
    const deviceId = this.getDeviceId(headers);
    return await this.tablesService.create(tableData, deviceId);
  }

  @Put('tables/:id')
  async updateTable(
    @Param('id') id: number,
    @Body() tableData: any,
    @Headers() headers: any,
  ) {
    const deviceId = this.getDeviceId(headers);
    return await this.tablesService.update(id, tableData, deviceId);
  }

  @Put('tables/:id/status')
  async updateTableStatus(
    @Param('id') id: number,
    @Body() body: { status: string },
    @Headers() headers: any,
  ) {
    const deviceId = this.getDeviceId(headers);
    return await this.tablesService.updateStatus(id, body.status, deviceId);
  }

  @Delete('tables/:id')
  async deleteTable(@Param('id') id: number, @Headers() headers: any) {
    const deviceId = this.getDeviceId(headers);
    return await this.tablesService.remove(id, deviceId);
  }

  // Menu Items API
  @Get('menu-items')
  async getMenuItems() {
    return await this.menuItemsService.findAll();
  }

  @Get('menu-items/category/:categoryId')
  async getMenuItemsByCategory(@Param('categoryId') categoryId: number) {
    return await this.menuItemsService.findByCategory(categoryId);
  }

  @Get('menu-items/:id')
  async getMenuItem(@Param('id') id: number) {
    return await this.menuItemsService.findOne(id);
  }

  @Post('menu-items')
  async createMenuItem(@Body() menuItemData: any, @Headers() headers: any) {
    const deviceId = this.getDeviceId(headers);
    return await this.menuItemsService.create(menuItemData, deviceId);
  }

  @Put('menu-items/:id')
  async updateMenuItem(
    @Param('id') id: number,
    @Body() menuItemData: any,
    @Headers() headers: any,
  ) {
    const deviceId = this.getDeviceId(headers);
    return await this.menuItemsService.update(id, menuItemData, deviceId);
  }

  @Delete('menu-items/:id')
  async deleteMenuItem(@Param('id') id: number, @Headers() headers: any) {
    const deviceId = this.getDeviceId(headers);
    return await this.menuItemsService.remove(id, deviceId);
  }

  // Categories API
  @Get('categories')
  async getCategories() {
    return await this.categoriesService.findAll();
  }

  @Get('categories/:id')
  async getCategory(@Param('id') id: number) {
    return await this.categoriesService.findOne(id);
  }

  @Post('categories')
  async createCategory(@Body() categoryData: any, @Headers() headers: any) {
    const deviceId = this.getDeviceId(headers);
    return await this.categoriesService.create(categoryData, deviceId);
  }

  @Put('categories/:id')
  async updateCategory(
    @Param('id') id: number,
    @Body() categoryData: any,
    @Headers() headers: any,
  ) {
    const deviceId = this.getDeviceId(headers);
    return await this.categoriesService.update(id, categoryData, deviceId);
  }

  @Delete('categories/:id')
  async deleteCategory(@Param('id') id: number, @Headers() headers: any) {
    const deviceId = this.getDeviceId(headers);
    return await this.categoriesService.remove(id, deviceId);
  }

  // Users API
  @Get('users')
  async getUsers() {
    return await this.usersService.findAll();
  }

  @Get('users/:id')
  async getUser(@Param('id') id: number) {
    return await this.usersService.findOne(id);
  }

  @Post('users')
  async createUser(@Body() userData: any, @Headers() headers: any) {
    const deviceId = this.getDeviceId(headers);
    return await this.usersService.create(userData, deviceId);
  }

  @Put('users/:id')
  async updateUser(
    @Param('id') id: number,
    @Body() userData: any,
    @Headers() headers: any,
  ) {
    const deviceId = this.getDeviceId(headers);
    return await this.usersService.update(id, userData, deviceId);
  }

  @Delete('users/:id')
  async deleteUser(@Param('id') id: number, @Headers() headers: any) {
    const deviceId = this.getDeviceId(headers);
    return await this.usersService.remove(id, deviceId);
  }

  // Bulk sync endpoint for initial data load
  @Get('sync/initial')
  async getInitialSyncData() {
    const [orders, tables, menuItems, categories, users] = await Promise.all([
      this.ordersService.getSyncOrders(),
      this.tablesService.findAll(),
      this.menuItemsService.findAll(),
      this.categoriesService.findAll(),
      this.usersService.findAll(),
    ]);

    return {
      orders,
      tables,
      menuItems,
      categories,
      users,
      timestamp: new Date(),
    };
  }

  // Health check
  @Get('health')
  async healthCheck() {
    return {
      status: 'ok',
      timestamp: new Date(),
      version: '2.0.0',
    };
  }
}
