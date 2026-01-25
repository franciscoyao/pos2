import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import * as bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import { User } from '../users/user.entity';
import { RefreshToken } from './entities/refresh-token.entity';
import { Role } from './entities/role.entity';
import { Permission } from './entities/permission.entity';
import { UsersService } from '../users/users.service';

export interface JwtPayload {
  sub: number;
  username: string;
  email: string;
  roles: string[];
  permissions: string[];
  deviceId?: string;
}

export interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  user: Partial<User>;
  expiresIn: number;
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(RefreshToken)
    private refreshTokenRepository: Repository<RefreshToken>,
    @InjectRepository(Role)
    private rolesRepository: Repository<Role>,
    @InjectRepository(Permission)
    private permissionsRepository: Repository<Permission>,
    private jwtService: JwtService,
    private usersService: UsersService,
  ) {}

  async validateUser(username: string, password: string): Promise<User | null> {
    const user = await this.usersRepository.findOne({
      where: [{ username }, { email: username }],
      relations: ['roles', 'roles.permissions'],
    });

    if (user && (await bcrypt.compare(password, user.password))) {
      return user;
    }
    return null;
  }

  async login(
    user: User,
    deviceId?: string,
    deviceInfo?: string,
  ): Promise<LoginResponse> {
    const payload: JwtPayload = {
      sub: user.id,
      username: user.username,
      email: user.email,
      roles: user.roles?.map((role) => role.name) || [],
      permissions: this.extractPermissions(user.roles || []),
      deviceId,
    };

    const accessToken = this.jwtService.sign(payload);
    const refreshToken = await this.generateRefreshToken(
      user.id,
      deviceId,
      deviceInfo,
    );

    this.logger.log(`User ${user.username} logged in from device ${deviceId}`);

    return {
      accessToken,
      refreshToken: refreshToken.token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        roles: user.roles,
        isActive: user.isActive,
      },
      expiresIn: 15 * 60, // 15 minutes
    };
  }

  async refreshAccessToken(
    refreshTokenString: string,
  ): Promise<{ accessToken: string; expiresIn: number }> {
    const refreshToken = await this.refreshTokenRepository.findOne({
      where: { token: refreshTokenString, isRevoked: false },
      relations: ['user', 'user.roles', 'user.roles.permissions'],
    });

    if (!refreshToken || refreshToken.expiresAt < new Date()) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    const payload: JwtPayload = {
      sub: refreshToken.user.id,
      username: refreshToken.user.username,
      email: refreshToken.user.email,
      roles: refreshToken.user.roles?.map((role) => role.name) || [],
      permissions: this.extractPermissions(refreshToken.user.roles || []),
      deviceId: refreshToken.deviceId,
    };

    const accessToken = this.jwtService.sign(payload);

    return {
      accessToken,
      expiresIn: 15 * 60,
    };
  }

  async logout(refreshTokenString: string, userId: number): Promise<void> {
    await this.refreshTokenRepository.update(
      { token: refreshTokenString, userId },
      { isRevoked: true, revokedAt: new Date(), revokedBy: 'user' },
    );

    this.logger.log(`User ${userId} logged out`);
  }

  async logoutAllDevices(userId: number): Promise<void> {
    await this.refreshTokenRepository.update(
      { userId, isRevoked: false },
      { isRevoked: true, revokedAt: new Date(), revokedBy: 'user_all_devices' },
    );

    this.logger.log(`User ${userId} logged out from all devices`);
  }

  async validateUserByPin(username: string, pin: string): Promise<User | null> {
    const user = await this.usersRepository.findOne({
      where: [{ username }, { email: username }],
      relations: ['roles', 'roles.permissions'],
    });

    if (user && user.pin && (await bcrypt.compare(pin, user.pin))) {
      return user;
    }
    return null;
  }

  async validateUserById(userId: number): Promise<User | null> {
    return await this.usersRepository.findOne({
      where: { id: userId, isActive: true },
      relations: ['roles', 'roles.permissions'],
    });
  }

  async register(userData: {
    username: string;
    email: string;
    password: string;
    firstName?: string;
    lastName?: string;
    roleIds?: number[];
  }): Promise<User> {
    const existingUser = await this.usersRepository.findOne({
      where: [{ username: userData.username }, { email: userData.email }],
    });

    if (existingUser) {
      throw new BadRequestException('Username or email already exists');
    }

    const hashedPassword = await bcrypt.hash(userData.password, 12);

    let roles: Role[] = [];
    if (userData.roleIds && userData.roleIds.length > 0) {
      roles = await this.rolesRepository.findBy({ id: In(userData.roleIds) });
    } else {
      // Assign default role
      const defaultRole = await this.rolesRepository.findOne({
        where: { name: 'waiter' },
      });
      if (defaultRole) {
        roles = [defaultRole];
      }
    }

    const user = this.usersRepository.create({
      ...userData,
      password: hashedPassword,
      roles,
    });

    const savedUser = await this.usersRepository.save(user);
    this.logger.log(`New user registered: ${savedUser.username}`);

    return savedUser;
  }

  async changePassword(
    userId: number,
    oldPassword: string,
    newPassword: string,
  ): Promise<void> {
    const user = await this.usersRepository.findOne({ where: { id: userId } });

    if (!user || !(await bcrypt.compare(oldPassword, user.password))) {
      throw new UnauthorizedException('Invalid current password');
    }

    const hashedPassword = await bcrypt.hash(newPassword, 12);
    await this.usersRepository.update(userId, { password: hashedPassword });

    // Revoke all refresh tokens to force re-login
    await this.logoutAllDevices(userId);

    this.logger.log(`Password changed for user ${userId}`);
  }

  async hasPermission(
    userId: number,
    resource: string,
    action: string,
  ): Promise<boolean> {
    const user = await this.usersRepository.findOne({
      where: { id: userId },
      relations: ['roles', 'roles.permissions'],
    });

    if (!user || !user.isActive) {
      return false;
    }

    const permissions = this.extractPermissions(user.roles || []);
    return (
      permissions.includes(`${resource}:${action}`) ||
      permissions.includes(`${resource}:manage`)
    );
  }

  async getUserPermissions(userId: number): Promise<string[]> {
    const user = await this.usersRepository.findOne({
      where: { id: userId },
      relations: ['roles', 'roles.permissions'],
    });

    if (!user) {
      return [];
    }

    return this.extractPermissions(user.roles || []);
  }

  private async generateRefreshToken(
    userId: number,
    deviceId?: string,
    deviceInfo?: string,
  ): Promise<RefreshToken> {
    // Revoke existing tokens for this device
    if (deviceId) {
      await this.refreshTokenRepository.update(
        { userId, deviceId, isRevoked: false },
        { isRevoked: true, revokedAt: new Date(), revokedBy: 'new_login' },
      );
    }

    const token = uuidv4();
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30); // 30 days

    const refreshToken = this.refreshTokenRepository.create({
      token,
      userId,
      deviceId,
      deviceInfo,
      expiresAt,
    });

    return await this.refreshTokenRepository.save(refreshToken);
  }

  private extractPermissions(roles: Role[]): string[] {
    const permissions = new Set<string>();

    roles.forEach((role) => {
      role.permissions?.forEach((permission) => {
        permissions.add(`${permission.resource}:${permission.action}`);
      });
    });

    return Array.from(permissions);
  }

  async cleanupExpiredTokens(): Promise<void> {
    const result = await this.refreshTokenRepository.delete({
      expiresAt: new Date(),
    });

    this.logger.log(`Cleaned up ${result.affected} expired refresh tokens`);
  }

  async getActiveDevices(userId: number): Promise<RefreshToken[]> {
    return await this.refreshTokenRepository.find({
      where: { userId, isRevoked: false },
      order: { createdAt: 'DESC' },
    });
  }

  async revokeDevice(userId: number, deviceId: string): Promise<void> {
    await this.refreshTokenRepository.update(
      { userId, deviceId, isRevoked: false },
      { isRevoked: true, revokedAt: new Date(), revokedBy: 'admin' },
    );

    this.logger.log(`Device ${deviceId} revoked for user ${userId}`);
  }
}
