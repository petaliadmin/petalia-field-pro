import { Injectable, Inject, UnauthorizedException, BadRequestException, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Redis } from 'ioredis';
import { UsersService } from '../users/users.service';
import { SmsService } from '../common/services/sms.service';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private jwtService: JwtService,
    private usersService: UsersService,
    private smsService: SmsService,
    @Inject('REDIS_CLIENT') private redis: Redis,
  ) {}

  async requestOtp(phone: string) {
    // Générer un code à 6 chiffres
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Sauvegarder dans Redis pendant 5 minutes
    await this.redis.set(`otp:${phone}`, code, 'EX', 300);
    
    this.logger.log(`Generated OTP for ${phone}: ${code}`);

    // Envoyer via SMS
    await this.smsService.sendOtp(phone, code);
    
    return { message: 'OTP envoyé avec succès' };
  }

  async verifyOtp(phone: string, code: string) {
    const savedCode = await this.redis.get(`otp:${phone}`);
    
    if (!savedCode || savedCode !== code) {
      throw new UnauthorizedException('Code OTP invalide ou expiré');
    }

    // Marquer le numéro comme vérifié dans Redis pendant 15 minutes pour permettre l'inscription
    await this.redis.set(`verified:${phone}`, 'true', 'EX', 900);
    
    return { message: 'OTP vérifié avec succès' };
  }

  async register(userData: any) {
    const { phone, name, pin } = userData;

    // Vérifier si le téléphone a été validé par OTP (en dev/test, on autorise en fallback pour faciliter les tests de synchronisation)
    const isVerified = await this.redis.get(`verified:${phone}`);
    if (!isVerified && process.env.NODE_ENV !== 'development') {
      throw new BadRequestException('Le numéro de téléphone n\'a pas été vérifié');
    }

    // Hacher le code PIN (password)
    const hashedPassword = await bcrypt.hash(pin, 10);

    let user = await this.usersService.findByPhone(phone);
    if (user) {
      // Si l'utilisateur existe déjà (réinstallation de l'application mobile), on le met à jour
      user = await this.usersService.update(user.id, { name, password: pin });
    } else {
      user = await this.usersService.create({
        phone,
        name,
        password: hashedPassword,
        email: `${phone}@petalia.agro`,
      });
    }

    // Supprimer le token de vérification
    await this.redis.del(`verified:${phone}`);

    // Retourner le token JWT
    return this.login(user);
  }

  async login(user: any) {
    const payload = {
      username: user.phone,
      sub: user.id,
      role: user.role,
    };
    return {
      access_token: this.jwtService.sign(payload),
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        role: user.role,
      },
    };
  }

  async loginWithPin(phone: string, pin: string) {
    const user = await this.usersService.findByPhone(phone);
    if (!user) {
      throw new UnauthorizedException('Identifiants invalides');
    }

    const isMatch = await bcrypt.compare(pin, user.password);
    if (!isMatch) {
      throw new UnauthorizedException('Identifiants invalides');
    }

    return this.login(user);
  }
}
