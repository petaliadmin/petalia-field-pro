import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Inject,
} from '@nestjs/common';
import { Observable, of, from } from 'rxjs';
import { switchMap } from 'rxjs/operators';
import { Redis } from 'ioredis';

@Injectable()
export class IdempotencyInterceptor implements NestInterceptor {
  constructor(@Inject('REDIS_CLIENT') private readonly redis: Redis) {}

  private readonly TTL = 86400;

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

    return next.handle().pipe(
      switchMap((res) =>
        from(
          this.redis
            .set(`idempotency:${key}`, JSON.stringify(res), 'EX', this.TTL)
            .then(() => res),
        ),
      ),
    );
  }
}
