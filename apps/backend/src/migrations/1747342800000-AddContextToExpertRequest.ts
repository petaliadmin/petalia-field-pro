import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddContextToExpertRequest1747342800000 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE expert_requests ADD COLUMN IF NOT EXISTS context text`);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE expert_requests DROP COLUMN IF EXISTS context`);
  }
}
