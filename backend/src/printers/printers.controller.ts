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
import { PrintersService } from './printers.service';

@Controller('printers')
export class PrintersController {
  constructor(private readonly printersService: PrintersService) {}

  private getDeviceId(headers: any): string | undefined {
    return headers['x-device-id'] || headers['device-id'];
  }

  @Get()
  async findAll() {
    return await this.printersService.findAll();
  }

  @Get('role/:role')
  async findByRole(@Param('role') role: string) {
    return await this.printersService.findByRole(role);
  }

  @Get(':id')
  async findOne(@Param('id') id: number) {
    return await this.printersService.findOne(id);
  }

  @Post()
  async create(@Body() printerData: any, @Headers() headers: any) {
    const deviceId = this.getDeviceId(headers);
    return await this.printersService.create(printerData, deviceId);
  }

  @Put(':id')
  async update(
    @Param('id') id: number,
    @Body() printerData: any,
    @Headers() headers: any,
  ) {
    const deviceId = this.getDeviceId(headers);
    return await this.printersService.update(id, printerData, deviceId);
  }

  @Put(':id/status')
  async updateStatus(
    @Param('id') id: number,
    @Body() body: { status: string; errorMessage?: string },
  ) {
    return await this.printersService.updateStatus(
      id,
      body.status,
      body.errorMessage,
    );
  }

  @Post(':id/test')
  async testPrint(@Param('id') id: number) {
    return await this.printersService.testPrint(id);
  }

  @Put(':id/default')
  async setDefault(@Param('id') id: number, @Body() body: { role: string }) {
    return await this.printersService.setDefault(id, body.role);
  }

  @Put(':id/paper-level')
  async updatePaperLevel(
    @Param('id') id: number,
    @Body() body: { level: number },
  ) {
    await this.printersService.updatePaperLevel(id, body.level);
    return { success: true };
  }

  @Put(':id/ink-level')
  async updateInkLevel(
    @Param('id') id: number,
    @Body() body: { level: number },
  ) {
    await this.printersService.updateInkLevel(id, body.level);
    return { success: true };
  }

  @Delete(':id')
  async remove(@Param('id') id: number, @Headers() headers: any) {
    const deviceId = this.getDeviceId(headers);
    return await this.printersService.remove(id, deviceId);
  }
}
