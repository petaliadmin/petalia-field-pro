import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';

@Injectable()
export class AuditListener {
  private readonly logger = new Logger('AuditListener');

  @OnEvent('audit.action')
  handleAuditAction(payload: any) {
    this.logger.log(
      `[AUDIT EVENT] ${payload.method} ${payload.url} by ${payload.userId}`,
    );
    // Ici, on pourrait injecter une Repository pour sauvegarder en DB
  }
}
