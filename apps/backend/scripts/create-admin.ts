/**
 * Script de création du compte administrateur initial.
 *
 * Usage :
 *   npx ts-node -r tsconfig-paths/register scripts/create-admin.ts
 *   ou
 *   npm run seed:admin
 *
 * Surcharge des valeurs par défaut via variables d'environnement :
 *   ADMIN_PHONE=+221769055852 ADMIN_PIN=1234 ADMIN_NAME="Papa Babacar" npx ts-node ...
 */

import { config } from 'dotenv';
import { DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';

config();

const PHONE  = process.env.ADMIN_PHONE ?? '+221769055852';
const PIN    = process.env.ADMIN_PIN   ?? '1234';
const NAME   = process.env.ADMIN_NAME  ?? 'Admin Petalia';
const EMAIL  = `${PHONE}@petalia.agro`;

async function main() {
  if (!process.env.DATABASE_URL) {
    console.error('❌  DATABASE_URL manquant — vérifiez votre fichier .env');
    process.exit(1);
  }

  const ds = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    entities: [__dirname + '/../src/**/*.entity{.ts,.js}'],
    synchronize: false,
  });

  await ds.initialize();
  console.log('✓  Connexion PostgreSQL établie');

  const hashedPin = await bcrypt.hash(PIN, 10);

  await ds.query(
    `INSERT INTO users (id, name, email, phone, password, role, status, "createdAt", "updatedAt")
     VALUES (gen_random_uuid(), $1, $2, $3, $4, 'ADMIN', 'ACTIVE', NOW(), NOW())
     ON CONFLICT (phone) DO UPDATE
       SET role     = 'ADMIN',
           password = $4,
           status   = 'ACTIVE',
           name     = $1`,
    [NAME, EMAIL, PHONE, hashedPin],
  );

  await ds.destroy();
  console.log(`✓  Compte admin créé / mis à jour`);
  console.log(`   Téléphone : ${PHONE}`);
  console.log(`   PIN       : ${PIN}`);
  console.log(`   Rôle      : ADMIN`);
}

main().catch((err) => {
  console.error('❌  Erreur :', err.message);
  process.exit(1);
});
