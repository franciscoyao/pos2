import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Logger, UseGuards } from '@nestjs/common';
import { Server, Socket } from 'socket.io';

interface ConnectedDevice {
  deviceId: string;
  deviceType: string;
  userId?: number;
  capabilities?: any;
  joinedRooms: string[];
}

@WebSocketGateway({
  cors: {
    origin: '*',
  },
  namespace: '/sync',
})
export class EventsGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer() server: Server;
  private logger: Logger = new Logger('EventsGateway');
  private connectedDevices: Map<string, ConnectedDevice> = new Map();

  afterInit(server: Server) {
    this.logger.log('WebSocket Gateway Initialized');
  }

  handleDisconnect(client: Socket) {
    const deviceId = client.data?.deviceId;
    if (deviceId) {
      this.connectedDevices.delete(client.id);
      this.logger.log(`Device disconnected: ${deviceId} (${client.id})`);

      // Notify other devices about disconnection
      client.broadcast.emit('device:disconnected', { deviceId });
    }
  }

  handleConnection(client: Socket, ...args: any[]) {
    this.logger.log(`Client connected: ${client.id}`);
  }

  @SubscribeMessage('device:register')
  async handleDeviceRegister(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: {
      deviceId: string;
      deviceType: string;
      userId?: number;
      capabilities?: any;
    },
  ) {
    const { deviceId, deviceType, userId, capabilities } = data;

    client.data = { deviceId, deviceType, userId, capabilities };

    const deviceInfo: ConnectedDevice = {
      deviceId,
      deviceType,
      userId,
      capabilities,
      joinedRooms: [],
    };

    this.connectedDevices.set(client.id, deviceInfo);

    // Join device-specific room
    await client.join(`device:${deviceId}`);
    deviceInfo.joinedRooms.push(`device:${deviceId}`);

    // Join role-based rooms
    if (capabilities?.canTakeOrders) {
      await client.join('waiters');
      deviceInfo.joinedRooms.push('waiters');
    }
    if (capabilities?.canManageKitchen) {
      await client.join('kitchen');
      deviceInfo.joinedRooms.push('kitchen');
    }
    if (capabilities?.canManageBar) {
      await client.join('bar');
      deviceInfo.joinedRooms.push('bar');
    }
    if (capabilities?.isKiosk) {
      await client.join('kiosks');
      deviceInfo.joinedRooms.push('kiosks');
    }

    this.logger.log(`Device registered: ${deviceId} (${deviceType})`);

    // Notify other devices about new connection
    client.broadcast.emit('device:connected', {
      deviceId,
      deviceType,
      capabilities,
    });

    // Send current connected devices list
    const connectedDevicesList = Array.from(this.connectedDevices.values());
    client.emit('devices:list', connectedDevicesList);
  }

  @SubscribeMessage('sync:request')
  async handleSyncRequest(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: any,
  ) {
    const deviceId = client.data?.deviceId;
    if (!deviceId) {
      client.emit('error', { message: 'Device not registered' });
      return;
    }

    // Forward to sync service (would be injected in real implementation)
    client.emit('sync:response', { success: true, data });
  }

  @SubscribeMessage('join:table')
  async handleJoinTable(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { tableId: number },
  ) {
    const room = `table:${data.tableId}`;
    await client.join(room);

    const deviceInfo = this.connectedDevices.get(client.id);
    if (deviceInfo) {
      deviceInfo.joinedRooms.push(room);
    }

    this.logger.log(
      `Device ${client.data?.deviceId} joined table ${data.tableId}`,
    );
  }

  @SubscribeMessage('leave:table')
  async handleLeaveTable(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { tableId: number },
  ) {
    const room = `table:${data.tableId}`;
    await client.leave(room);

    const deviceInfo = this.connectedDevices.get(client.id);
    if (deviceInfo) {
      deviceInfo.joinedRooms = deviceInfo.joinedRooms.filter((r) => r !== room);
    }

    this.logger.log(
      `Device ${client.data?.deviceId} left table ${data.tableId}`,
    );
  }

  // Enhanced emit methods for better targeting
  emitSyncUpdate(data: {
    entityType: string;
    entityId: number;
    action: string;
    data: any;
    version: number;
    excludeDevice?: string;
  }) {
    const event = `${data.entityType}:${data.action}`;

    if (data.excludeDevice) {
      this.server.except(`device:${data.excludeDevice}`).emit(event, {
        entityType: data.entityType,
        entityId: data.entityId,
        data: data.data,
        version: data.version,
        timestamp: new Date(),
      });
    } else {
      this.server.emit(event, {
        entityType: data.entityType,
        entityId: data.entityId,
        data: data.data,
        version: data.version,
        timestamp: new Date(),
      });
    }
  }

  emitTableUpdate(table: any, excludeDevice?: string) {
    const room = `table:${table.id}`;
    if (excludeDevice) {
      this.server
        .to(room)
        .except(`device:${excludeDevice}`)
        .emit('table:update', table);
    } else {
      this.server.to(room).emit('table:update', table);
    }

    // Also emit to waiters
    this.server.to('waiters').emit('table:update', table);
  }

  emitOrderUpdate(order: any, excludeDevice?: string) {
    const rooms = [`table:${order.tableId}`, 'kitchen', 'waiters'];

    rooms.forEach((room) => {
      if (excludeDevice) {
        this.server
          .to(room)
          .except(`device:${excludeDevice}`)
          .emit('order:update', order);
      } else {
        this.server.to(room).emit('order:update', order);
      }
    });
  }

  emitNewOrder(order: any, excludeDevice?: string) {
    const rooms = ['kitchen', 'waiters'];

    // Determine which station should receive this order
    if (order.items?.some((item: any) => item.station === 'bar')) {
      rooms.push('bar');
    }

    rooms.forEach((room) => {
      if (excludeDevice) {
        this.server
          .to(room)
          .except(`device:${excludeDevice}`)
          .emit('order:new', order);
      } else {
        this.server.to(room).emit('order:new', order);
      }
    });
  }

  emitCategoryUpdate(category: any, excludeDevice?: string) {
    if (excludeDevice) {
      this.server
        .except(`device:${excludeDevice}`)
        .emit('category:update', category);
    } else {
      this.server.emit('category:update', category);
    }
  }

  emitMenuItemUpdate(menuItem: any, excludeDevice?: string) {
    const rooms = ['kiosks', 'waiters'];

    rooms.forEach((room) => {
      if (excludeDevice) {
        this.server
          .to(room)
          .except(`device:${excludeDevice}`)
          .emit('menu-item:update', menuItem);
      } else {
        this.server.to(room).emit('menu-item:update', menuItem);
      }
    });
  }

  emitUserUpdate(user: any, excludeDevice?: string) {
    if (excludeDevice) {
      this.server.except(`device:${excludeDevice}`).emit('user:update', user);
    } else {
      this.server.emit('user:update', user);
    }
  }

  emitOrderDelete(orderId: number, excludeDevice?: string) {
    if (excludeDevice) {
      this.server
        .except(`device:${excludeDevice}`)
        .emit('order:delete', { id: orderId });
    } else {
      this.server.emit('order:delete', { id: orderId });
    }
  }

  // Utility methods
  getConnectedDevices(): ConnectedDevice[] {
    return Array.from(this.connectedDevices.values());
  }

  getDevicesByCapability(capability: string): ConnectedDevice[] {
    return Array.from(this.connectedDevices.values()).filter(
      (device) => device.capabilities?.[capability],
    );
  }

  emitToDeviceType(deviceType: string, event: string, data: any) {
    Array.from(this.connectedDevices.entries())
      .filter(([_, device]) => device.deviceType === deviceType)
      .forEach(([socketId, _]) => {
        this.server.to(socketId).emit(event, data);
      });
  }
}
