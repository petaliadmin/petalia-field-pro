import { MigrationInterface, QueryRunner } from 'typeorm';

export class FixBadPhotoUrls1747342700000 implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      UPDATE diagnostic_requests
      SET "photoUrl" = NULL
      WHERE "photoUrl" IS NULL
         OR "photoUrl" LIKE '%undefined%'
         OR "photoUrl" = 'uploads/'
    `);
  }

  async down(_queryRunner: QueryRunner): Promise<void> {}
}
