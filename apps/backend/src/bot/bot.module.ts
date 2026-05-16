import { Module } from '@nestjs/common';
import { BotController } from './bot.controller';
import { BotService } from './bot.service';
import { KnowledgeService } from './knowledge.service';

@Module({
  controllers: [BotController],
  providers: [BotService, KnowledgeService],
})
export class BotModule {}
