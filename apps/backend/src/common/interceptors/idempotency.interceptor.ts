import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Inject,
} from '@nestjs/common';
import { Observable, of } from 'rxjs';
import { Redis } from 'ioredis';

@Injectable()
export class IdempotencyInterceptor implements NestInterceptor {
  constructor(@Inject('REDIS_CLIENT') private readonly redis: Redis) {}

  private readonly TTL = 86400; // 24 heures en secondes

  async intercept(context: ExecutionContext, next: CallHandler): Promise<Observable<any>> {
    const request = context.switchToHttp().getRequest();
    const key = request.headers['x-idempotency-key'];

    if (!key || (request.method !== 'POST' && request.method !== 'PATCH')) {
      return next.handle();
    }

    const cachedValue = await this.redis.get(`idempotency:${key}`);
    if (cachedValue) {
      return of(JSON.parse(cachedValue));
    }

    return new Observable((observer) => {
      next.handle().subscribe({
        next: async (res) => {
          await this.redis.set(
            `idempotency:${key}`,
            JSON.stringify(res),
            'EX',
            this.TTL,
          );
          observer.next(res);
        },
        error: (err) => observer.error(err),
        complete: () => observer.complete(),
      });
    });
  }
}
