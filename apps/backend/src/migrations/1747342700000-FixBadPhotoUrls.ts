import { MigrationInterface, QueryRunner } from 'typeorm';

export class FixBadPhotoUrls1747342700000 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE diagnostic_requests ALTER COLUMN "photoUrl" DROP NOT NULL`);
    await queryRunner.query(`
      UPDATE diagnostic_requests
      SET "photoUrl" = NULL
      WHERE "photoUrl" LIKE '%undefined%'
         OR "photoUrl" = 'uploads/'
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`UPDATE diagnostic_requests SET "photoUrl" = '' WHERE "photoUrl" IS NULL`);
    await queryRunner.query(`ALTER TABLE diagnostic_requests ALTER COLUMN "photoUrl" SET NOT NULL`);
  }
}
