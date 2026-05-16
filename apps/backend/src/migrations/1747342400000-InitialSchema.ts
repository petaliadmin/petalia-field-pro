import { MigrationInterface, QueryRunner } from 'typeorm';

export class InitialSchema1747342400000 implements MigrationInterface {
  name = 'InitialSchema1747342400000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "uuid-ossp"`);

    await queryRunner.query(
      `CREATE TYPE "public"."users_role_enum" AS ENUM('ADMIN', 'EXPERT', 'TECHNICIAN')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."users_status_enum" AS ENUM('ACTIVE', 'INACTIVE')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."diagnostic_requests_status_enum" AS ENUM('pending', 'analyzed', 'validated', 'rejected')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."wallet_transactions_type_enum" AS ENUM('CREDIT', 'DEBIT')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."payments_method_enum" AS ENUM('WAVE', 'ORANGE_MONEY', 'FREE_MONEY')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."payments_status_enum" AS ENUM('PENDING', 'SUCCESS', 'FAILED', 'CANCELLED')`,
    );

    await queryRunner.query(`
      CREATE TABLE "users" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "name" character varying NOT NULL,
        "email" character varying NOT NULL,
        "password" character varying NOT NULL,
        "role" "public"."users_role_enum" NOT NULL DEFAULT 'TECHNICIAN',
        "status" "public"."users_status_enum" NOT NULL DEFAULT 'ACTIVE',
        "phone" character varying,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "UQ_users_email" UNIQUE ("email"),
        CONSTRAINT "PK_users" PRIMARY KEY ("id")
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "parcels" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "name" character varying NOT NULL,
        "owner" character varying NOT NULL,
        "village" character varying,
        "phone" character varying,
        "crop" character varying NOT NULL,
        "healthScore" double precision NOT NULL DEFAULT '0',
        "boundary" geometry(Polygon,4326) NOT NULL,
        "estimatedYield" double precision,
        "lastVisit" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_parcels" PRIMARY KEY ("id")
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "experts" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "name" character varying NOT NULL,
        "specialization" character varying NOT NULL,
        "consultationFee" double precision NOT NULL,
        CONSTRAINT "PK_experts" PRIMARY KEY ("id")
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "expert_requests" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "status" character varying NOT NULL DEFAULT 'pending',
        "paymentReference" character varying,
        "expertAdvice" text,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "parcelId" uuid,
        "expertId" uuid,
        CONSTRAINT "PK_expert_requests" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      ALTER TABLE "expert_requests"
        ADD CONSTRAINT "FK_expert_requests_parcel"
        FOREIGN KEY ("parcelId") REFERENCES "parcels"("id")
        ON DELETE NO ACTION ON UPDATE NO ACTION
    `);
    await queryRunner.query(`
      ALTER TABLE "expert_requests"
        ADD CONSTRAINT "FK_expert_requests_expert"
        FOREIGN KEY ("expertId") REFERENCES "experts"("id")
        ON DELETE NO ACTION ON UPDATE NO ACTION
    `);

    await queryRunner.query(`
      CREATE TABLE "ledger_entries" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "amount" numeric(12,2) NOT NULL,
        "type" character varying NOT NULL,
        "currency" character varying NOT NULL,
        "description" character varying NOT NULL,
        "reference" character varying,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_ledger_entries" PRIMARY KEY ("id")
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "diagnostic_requests" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "parcelId" character varying NOT NULL,
        "ownerName" character varying NOT NULL,
        "ownerPhone" character varying NOT NULL,
        "photoUrl" character varying NOT NULL,
        "status" "public"."diagnostic_requests_status_enum" NOT NULL DEFAULT 'pending',
        "aiResult" jsonb,
        "adminComment" character varying,
        "validatedAt" TIMESTAMP,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_diagnostic_requests" PRIMARY KEY ("id")
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "wallet_transactions" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "userId" character varying NOT NULL,
        "type" "public"."wallet_transactions_type_enum" NOT NULL,
        "amount" integer NOT NULL,
        "description" character varying NOT NULL,
        "reference" character varying,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_wallet_transactions" PRIMARY KEY ("id")
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "payments" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "userId" character varying NOT NULL,
        "amount" integer NOT NULL,
        "credits" integer NOT NULL,
        "method" "public"."payments_method_enum" NOT NULL,
        "status" "public"."payments_status_enum" NOT NULL DEFAULT 'PENDING',
        "externalId" character varying,
        "paymentUrl" character varying,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_payments" PRIMARY KEY ("id")
      )
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "payments"`);
    await queryRunner.query(`DROP TABLE "wallet_transactions"`);
    await queryRunner.query(`DROP TABLE "diagnostic_requests"`);
    await queryRunner.query(`DROP TABLE "ledger_entries"`);
    await queryRunner.query(
      `ALTER TABLE "expert_requests" DROP CONSTRAINT "FK_expert_requests_expert"`,
    );
    await queryRunner.query(
      `ALTER TABLE "expert_requests" DROP CONSTRAINT "FK_expert_requests_parcel"`,
    );
    await queryRunner.query(`DROP TABLE "expert_requests"`);
    await queryRunner.query(`DROP TABLE "experts"`);
    await queryRunner.query(`DROP TABLE "parcels"`);
    await queryRunner.query(`DROP TABLE "users"`);
    await queryRunner.query(`DROP TYPE "public"."payments_status_enum"`);
    await queryRunner.query(`DROP TYPE "public"."payments_method_enum"`);
    await queryRunner.query(`DROP TYPE "public"."wallet_transactions_type_enum"`);
    await queryRunner.query(
      `DROP TYPE "public"."diagnostic_requests_status_enum"`,
    );
    await queryRunner.query(`DROP TYPE "public"."users_status_enum"`);
    await queryRunner.query(`DROP TYPE "public"."users_role_enum"`);
  }
}
