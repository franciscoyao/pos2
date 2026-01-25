import { Controller, Get, Version, VERSION_NEUTRAL } from '@nestjs/common';
import { HealthService } from './health.service';

@Controller('health')
export class HealthController {
  constructor(private readonly healthService: HealthService) { }

  @Get()
  @Version(VERSION_NEUTRAL)
  async check() {
    return await this.healthService.check();
  }

  @Get('info')
  @Version(VERSION_NEUTRAL)
  async getSystemInfo() {
    return await this.healthService.getSystemInfo();
  }
}
