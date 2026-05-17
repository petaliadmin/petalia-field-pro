import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddFcmTokenToUser1747343000000 implements MigrationInterface {
  name = 'AddFcmTokenToUser1747343000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Colonne ajoutée à l'entité User pour les notifications push FCM
    // (technicien notifié lors de la validation d'un diagnostic IA et
    // lors de la réponse d'un expert). Sans cette migration, tout SELECT
    // sur la table users plante avec `column User.fcmToken does not exist`.
    await queryRunner.query(
      `ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "fcmToken" character varying`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "users" DROP COLUMN IF EXISTS "fcmToken"`,
    );
  }
}
