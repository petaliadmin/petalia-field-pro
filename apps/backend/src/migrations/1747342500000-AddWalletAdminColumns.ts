import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddWalletAdminColumns1747342500000 implements MigrationInterface {
  name = 'AddWalletAdminColumns1747342500000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "wallet_transactions" ADD COLUMN IF NOT EXISTS "operationType" character varying DEFAULT 'TOPUP'`,
    );
    await queryRunner.query(
      `ALTER TABLE "wallet_transactions" ADD COLUMN IF NOT EXISTS "adminId" character varying`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "wallet_transactions" DROP COLUMN IF EXISTS "adminId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "wallet_transactions" DROP COLUMN IF EXISTS "operationType"`,
    );
  }
}
