import { Controller, Get, Redirect, Version, VERSION_NEUTRAL } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  @Version(VERSION_NEUTRAL)
  @Redirect('/docs')
  getHello() {
    return { url: '/docs' };
  }
}
