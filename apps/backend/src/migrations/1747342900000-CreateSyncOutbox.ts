import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateSyncOutbox1747342900000 implements MigrationInterface {
  name = 'CreateSyncOutbox1747342900000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Table de l'outbox de synchronisation hors-ligne / en ligne.
    // Chaque mutation côté serveur (parcels, observations, expert_requests, wallet…)
    // y dépose une entrée que les clients mobiles peuvent rejouer via /parcels/sync.
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "sync_outbox" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "entityId" varchar NOT NULL,
        "entityType" varchar NOT NULL,
        "operation" varchar NOT NULL,
        "payload" jsonb,
        "processed" boolean NOT NULL DEFAULT false,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_sync_outbox_id" PRIMARY KEY ("id")
      )
    `);

    // Index sur createdAt pour findSyncDeltas (WHERE createdAt > :lastSync).
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_sync_outbox_createdAt" ON "sync_outbox" ("createdAt")`,
    );
    // Index sur (entityType, entityId) pour la déduplication côté client.
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_sync_outbox_entity" ON "sync_outbox" ("entityType", "entityId")`,
    );
    // Index partiel sur les entrées non traitées (file d'attente serveur->client).
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_sync_outbox_pending" ON "sync_outbox" ("processed", "createdAt") WHERE "processed" = false`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_sync_outbox_pending"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_sync_outbox_entity"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_sync_outbox_createdAt"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "sync_outbox"`);
  }
}
