import { Injectable, ConflictException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserStatus } from './entities/user.entity';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly repository: Repository<User>,
  ) {}

  async create(userData: Partial<User>): Promise<User> {
    const existingEmail = await this.repository.findOneBy({ email: userData.email });
    if (existingEmail) throw new ConflictException('Email déjà utilisé');

    const existingPhone = await this.repository.findOneBy({ phone: userData.phone });
    if (existingPhone) throw new ConflictException('Téléphone déjà utilisé');

    const user = this.repository.create(userData);
    return this.repository.save(user);
  }

  async findByPhone(phone: string): Promise<User | null> {
    return this.repository.findOne({
      where: { phone },
      select: ['id', 'name', 'phone', 'password', 'role', 'status'],
    });
  }

  async findAll(): Promise<User[]> {
    return this.repository.find({ order: { createdAt: 'DESC' } });
  }

  async findOne(id: string): Promise<User> {
    const user = await this.repository.findOneBy({ id });
    if (!user) throw new NotFoundException('Utilisateur introuvable');
    return user;
  }

  async update(id: string, updateData: Partial<User>): Promise<User> {
    const user = await this.findOne(id);
    if (updateData.password) {
      updateData.password = await bcrypt.hash(updateData.password, 10);
    }
    Object.assign(user, updateData);
    return this.repository.save(user);
  }

  async remove(id: string): Promise<void> {
    const user = await this.findOne(id);
    user.status = UserStatus.INACTIVE;
    await this.repository.save(user);
  }
}
