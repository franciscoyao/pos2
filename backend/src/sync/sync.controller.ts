import { Controller, Post, Get, Body, Param, Query } from '@nestjs/common';
import { SyncService } from './sync.service';
import type { SyncRequest, SyncResponse } from './sync.service';
import { Device } from './device.entity';

@Controller('sync')
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  @Post('register-device')
  async registerDevice(@Body() deviceInfo: Partial<Device>): Promise<Device> {
    return await this.syncService.registerDevice(deviceInfo);
  }

  @Post('process')
  async processSync(@Body() syncRequest: SyncRequest): Promise<SyncResponse> {
    return await this.syncService.processSync(syncRequest);
  }

  @Get('device/:deviceId/status')
  async getDeviceStatus(
    @Param('deviceId') deviceId: string,
  ): Promise<Device | null> {
    return await this.syncService.getDeviceStatus(deviceId);
  }

  @Get('devices')
  async getAllDevices(): Promise<Device[]> {
    return await this.syncService.getAllDevices();
  }

  @Post('device/:deviceId/heartbeat')
  async deviceHeartbeat(
    @Param('deviceId') deviceId: string,
  ): Promise<{ success: boolean }> {
    await this.syncService.updateDeviceStatus(deviceId, 'online');
    return { success: true };
  }
}
