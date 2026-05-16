import { Controller, Post, Body, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('request-otp')
  async requestOtp(@Body() body: { phone: string }) {
    if (!body.phone) throw new BadRequestException('Le numéro de téléphone est requis');
    return this.authService.requestOtp(body.phone);
  }

  @Post('verify-otp')
  async verifyOtp(@Body() body: { phone: string; code: string }) {
    if (!body.phone || !body.code) throw new BadRequestException('Téléphone et code sont requis');
    return this.authService.verifyOtp(body.phone, body.code);
  }

  @Post('register')
  async register(@Body() body: { phone: string; name: string; pin: string }) {
    if (!body.phone || !body.name || !body.pin) {
      throw new BadRequestException('Informations d\'inscription incomplètes');
    }
    return this.authService.register(body);
  }

  @Post('login')
  async login(@Body() body: { phone: string; pin: string }) {
    if (!body.phone || !body.pin) {
      throw new BadRequestException('Numéro de téléphone et PIN requis');
    }
    return this.authService.loginWithPin(body.phone, body.pin);
  }
}
