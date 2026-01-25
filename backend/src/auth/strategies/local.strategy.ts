import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy } from 'passport-local';
import { AuthService } from '../auth.service';

@Injectable()
export class LocalStrategy extends PassportStrategy(Strategy) {
  constructor(private authService: AuthService) {
    super({
      usernameField: 'username', // Can be username, email, or pin
      passwordField: 'password', // Can be password or pin
      passReqToCallback: true,
    });
  }

  async validate(req: any, username: string, password: string): Promise<any> {
    const { loginType } = req.body;

    let user;

    if (loginType === 'pin') {
      // PIN-based login (4-digit PIN)
      user = await this.authService.validateUserByPin(username, password);
    } else {
      // Username/email + password login
      user = await this.authService.validateUser(username, password);
    }

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (!user.isActive) {
      throw new UnauthorizedException('Account is inactive');
    }

    if (user.isLocked) {
      throw new UnauthorizedException(
        'Account is locked due to too many failed attempts',
      );
    }

    return user;
  }
}
