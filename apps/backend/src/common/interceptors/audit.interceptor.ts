import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { EventEmitter2 } from '@nestjs/event-emitter';

@Injectable()
export class AuditInterceptor implements NestInterceptor {
  constructor(private eventEmitter: EventEmitter2) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const { method, url, user, body } = request;

    return next.handle().pipe(
      tap(() => {
        if (['POST', 'PATCH', 'DELETE'].includes(method)) {
          this.eventEmitter.emit('audit.action', {
            method,
            url,
            userId: user?.id || 'anonymous',
            data: body,
            timestamp: new Date(),
          });
        }
      }),
    );
  }
}
