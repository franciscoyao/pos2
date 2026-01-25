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
import { SettingsService } from './settings.service';

@Controller('settings')
export class SettingsController {
  constructor(private readonly settingsService: SettingsService) {}

  private getDeviceId(headers: any): string | undefined {
    return headers['x-device-id'] || headers['device-id'];
  }

  @Get()
  async getAllSettings() {
    return await this.settingsService.getAllSettings();
  }

  @Get('category/:category')
  async getByCategory(@Param('category') category: string) {
    return await this.settingsService.getByCategory(category);
  }

  @Get(':key')
  async getSetting(@Param('key') key: string) {
    return await this.settingsService.get(key);
  }

  @Put(':key')
  async setSetting(
    @Param('key') key: string,
    @Body() body: { value: any },
    @Headers() headers: any,
  ) {
    const deviceId = this.getDeviceId(headers);
    return await this.settingsService.set(key, body.value, deviceId);
  }

  @Post('bulk')
  async bulkUpdate(
    @Body() updates: Record<string, any>,
    @Headers() headers: any,
  ) {
    const deviceId = this.getDeviceId(headers);
    await this.settingsService.bulkUpdate(updates, deviceId);
    return { success: true };
  }

  @Post(':key/reset')
  async resetToDefault(@Param('key') key: string) {
    return await this.settingsService.resetToDefault(key);
  }

  @Delete(':key')
  async deleteSetting(@Param('key') key: string) {
    await this.settingsService.delete(key);
    return { success: true };
  }

  @Post('cache/clear')
  async clearCache() {
    await this.settingsService.clearCache();
    return { success: true };
  }

  // Convenience endpoints for common settings
  @Get('business/tax-rate')
  async getTaxRate() {
    return { taxRate: await this.settingsService.getTaxRate() };
  }

  @Get('business/service-rate')
  async getServiceRate() {
    return { serviceRate: await this.settingsService.getServiceRate() };
  }

  @Get('business/currency')
  async getCurrency() {
    return { currencySymbol: await this.settingsService.getCurrencySymbol() };
  }

  @Get('kiosk/enabled')
  async isKioskEnabled() {
    return { enabled: await this.settingsService.isKioskEnabled() };
  }
}
