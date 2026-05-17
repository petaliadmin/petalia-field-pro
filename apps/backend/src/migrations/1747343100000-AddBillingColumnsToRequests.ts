import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddBillingColumnsToRequests1747343100000
  implements MigrationInterface
{
  name = 'AddBillingColumnsToRequests1747343100000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Diagnostics IA : on conserve l'auteur (technicien) et le montant
    // effectivement débité pour pouvoir rembourser en cas de rejet.
    await queryRunner.query(
      `ALTER TABLE "diagnostic_requests" ADD COLUMN IF NOT EXISTS "userId" uuid`,
    );
    await queryRunner.query(
      `ALTER TABLE "diagnostic_requests" ADD COLUMN IF NOT EXISTS "feeAmount" integer`,
    );
    await queryRunner.query(
      `ALTER TABLE "diagnostic_requests" ADD COLUMN IF NOT EXISTS "feeReference" varchar`,
    );

    // Demandes d'avis expert : idem (auteur + snapshot du tarif débité).
    await queryRunner.query(
      `ALTER TABLE "expert_requests" ADD COLUMN IF NOT EXISTS "userId" uuid`,
    );
    await queryRunner.query(
      `ALTER TABLE "expert_requests" ADD COLUMN IF NOT EXISTS "feeAmount" integer`,
    );
    await queryRunner.query(
      `ALTER TABLE "expert_requests" ADD COLUMN IF NOT EXISTS "feeReference" varchar`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "expert_requests" DROP COLUMN IF EXISTS "feeReference"`,
    );
    await queryRunner.query(
      `ALTER TABLE "expert_requests" DROP COLUMN IF EXISTS "feeAmount"`,
    );
    await queryRunner.query(
      `ALTER TABLE "expert_requests" DROP COLUMN IF EXISTS "userId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "diagnostic_requests" DROP COLUMN IF EXISTS "feeReference"`,
    );
    await queryRunner.query(
      `ALTER TABLE "diagnostic_requests" DROP COLUMN IF EXISTS "feeAmount"`,
    );
    await queryRunner.query(
      `ALTER TABLE "diagnostic_requests" DROP COLUMN IF EXISTS "userId"`,
    );
  }
}
