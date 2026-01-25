import { Controller, Get, Query } from '@nestjs/common';
import { MetricsService } from './metrics.service';

@Controller('metrics')
export class MetricsController {
  constructor(private readonly metricsService: MetricsService) {}

  @Get('sales')
  async getSalesMetrics(
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    const start = startDate ? new Date(startDate) : new Date();
    const end = endDate ? new Date(endDate) : new Date();

    return await this.metricsService.getSalesMetrics(start, end);
  }

  @Get('performance')
  async getPerformanceMetrics(
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    const start = startDate ? new Date(startDate) : new Date();
    const end = endDate ? new Date(endDate) : new Date();

    return await this.metricsService.getPerformanceMetrics(start, end);
  }

  @Get('popularity')
  async getPopularityMetrics(
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
    @Query('limit') limit?: number,
  ) {
    const start = startDate ? new Date(startDate) : new Date();
    const end = endDate ? new Date(endDate) : new Date();

    return await this.metricsService.getPopularityMetrics(start, end, limit);
  }

  @Get('staff')
  async getStaffMetrics(
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    const start = startDate ? new Date(startDate) : new Date();
    const end = endDate ? new Date(endDate) : new Date();

    return await this.metricsService.getStaffMetrics(start, end);
  }

  @Get('dashboard')
  async getDashboardMetrics() {
    return await this.metricsService.getDashboardMetrics();
  }

  @Get('prometheus')
  async getPrometheusMetrics() {
    const { register } = await import('prom-client');
    return register.metrics();
  }
}
