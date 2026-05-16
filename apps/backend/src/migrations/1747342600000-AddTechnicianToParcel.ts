import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddTechnicianToParcel1747342600000 implements MigrationInterface {
  name = 'AddTechnicianToParcel1747342600000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "parcels" ADD COLUMN IF NOT EXISTS "technician" character varying`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "parcels" DROP COLUMN "technician"`,
    );
  }
}
