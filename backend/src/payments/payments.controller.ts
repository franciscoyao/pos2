import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Headers,
} from '@nestjs/common';
import { PaymentsService } from './payments.service';

@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  private getDeviceId(headers: any): string | undefined {
    return headers['x-device-id'] || headers['device-id'];
  }

  @Get()
  async findAll() {
    return await this.paymentsService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: number) {
    return await this.paymentsService.findOne(id);
  }

  @Post()
  async create(@Body() paymentData: any, @Headers() headers: any) {
    const deviceId = this.getDeviceId(headers);
    return await this.paymentsService.create(paymentData, deviceId);
  }

  @Put(':id')
  async update(
    @Param('id') id: number,
    @Body() paymentData: any,
    @Headers() headers: any,
  ) {
    const deviceId = this.getDeviceId(headers);
    return await this.paymentsService.update(id, paymentData, deviceId);
  }

  @Post(':id/refund')
  async refund(
    @Param('id') id: number,
    @Body() body: { amount: number; reason: string },
    @Headers() headers: any,
  ) {
    const deviceId = this.getDeviceId(headers);
    return await this.paymentsService.processRefund(
      id,
      body.amount,
      body.reason,
      deviceId,
    );
  }

  @Delete(':id')
  async remove(@Param('id') id: number, @Headers() headers: any) {
    const deviceId = this.getDeviceId(headers);
    return await this.paymentsService.remove(id, deviceId);
  }
}
