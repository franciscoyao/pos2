import { WebSocketGateway, WebSocketServer, SubscribeMessage, MessageBody, OnGatewayConnection, OnGatewayDisconnect } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({ namespace: 'sync', cors: true })
export class OrdersGateway implements OnGatewayConnection, OnGatewayDisconnect {
    @WebSocketServer()
    server: Server;

    handleConnection(client: Socket) {
        console.log(`Client connected: ${client.id}`);
    }

    handleDisconnect(client: Socket) {
        console.log(`Client disconnected: ${client.id}`);
    }

    notifyNewOrder(order: any) {
        this.server.emit('order:new', order);
    }

    notifyOrderUpdate(order: any) {
        this.server.emit('order:update', order);
    }

    notifyTableUpdate(table: any) {
        this.server.emit('table:update', table);
    }

    notifyCategoryUpdate(category: any) {
        this.server.emit('category:update', category);
    }

    notifyMenuItemUpdate(item: any) {
        this.server.emit('menu-item:update', item);
    }
}

