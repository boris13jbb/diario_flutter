/**
 * Migra diary_entries de Supabase → Cloud Firestore (diario-notaspro).
 *
 * Requisitos:
 * - SUPABASE_SERVICE_ROLE_KEY (lectura total, ignora RLS)
 * - serviceAccountKey.json de Firebase Admin
 * - Usuarios en Firebase Auth con el MISMO email que en Supabase (modo AUTO_MAP_BY_EMAIL)
 */
import { config as loadEnv } from 'dotenv';
import { createClient } from '@supabase/supabase-js';
import admin from 'firebase-admin';
import { readFileSync, existsSync } from 'node:fs';

// Windows/Cursor a veces ocultan ".env" → usar también "migracion.env"
if (existsSync('.env')) {
  loadEnv();
} else if (existsSync('migracion.env')) {
  loadEnv({ path: 'migracion.env' });
} else {
  loadEnv();
}
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const COLLECTION = 'diary_entries';
const BATCH_SIZE = 400;

const dryRun = process.env.DRY_RUN === 'true';
const autoMapByEmail = process.env.AUTO_MAP_BY_EMAIL !== 'false';

function requireEnv(name) {
  const value = process.env[name];
  if (!value?.trim()) {
    throw new Error(`Falta variable de entorno: ${name}`);
  }
  return value.trim();
}

function initFirebase() {
  const credPath = resolve(
    __dirname,
    process.env.GOOGLE_APPLICATION_CREDENTIALS ?? './serviceAccountKey.json',
  );
  if (!existsSync(credPath)) {
    throw new Error(
      `No se encontró cuenta de servicio en: ${credPath}\n` +
        'Descárgala en Firebase Console → Configuración → Cuentas de servicio.',
    );
  }
  const serviceAccount = JSON.parse(readFileSync(credPath, 'utf8'));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  return admin.firestore();
}

function initSupabase() {
  const url = requireEnv('SUPABASE_URL');
  const key = requireEnv('SUPABASE_SERVICE_ROLE_KEY');
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/** @param {string | null | undefined} iso */
function toFirestoreTimestamp(iso) {
  if (!iso) return undefined;
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return undefined;
  return admin.firestore.Timestamp.fromDate(date);
}

/** @param {Record<string, unknown>} row @param {string} firebaseUserId */
function toFirestoreDoc(row, firebaseUserId) {
  const doc = {
    user_id: firebaseUserId,
    date: row.date ?? '',
    title: row.title ?? '',
    content: row.content ?? '',
    last_updated: Number(row.last_updated ?? 0),
    synced: true,
    audio_markers: row.audio_markers ?? [],
    draw_strokes: row.draw_strokes ?? [],
  };
  const created = toFirestoreTimestamp(row.created_at);
  const updated = toFirestoreTimestamp(row.updated_at);
  if (created) doc.created_at = created;
  if (updated) doc.updated_at = updated;
  return doc;
}

/** @param {import('@supabase/supabase-js').SupabaseClient} supabase */
async function fetchAllDiaryEntries(supabase) {
  const pageSize = 1000;
  let from = 0;
  const all = [];

  while (true) {
    const { data, error } = await supabase
      .from('diary_entries')
      .select('*')
      .range(from, from + pageSize - 1);

    if (error) throw new Error(`Supabase diary_entries: ${error.message}`);
    if (!data?.length) break;
    all.push(...data);
    if (data.length < pageSize) break;
    from += pageSize;
  }

  return all;
}

/** @param {import('@supabase/supabase-js').SupabaseClient} supabase */
async function fetchSupabaseUsersById(supabase) {
  const map = new Map();
  let page = 1;
  const perPage = 1000;

  while (true) {
    const { data, error } = await supabase.auth.admin.listUsers({ page, perPage });
    if (error) throw new Error(`Supabase auth.admin.listUsers: ${error.message}`);
    for (const user of data.users) {
      if (user.email) map.set(user.id, user.email.toLowerCase());
    }
    if (data.users.length < perPage) break;
    page += 1;
  }

  return map;
}

/** @returns {Promise<Map<string, string>>} email → firebase uid */
async function fetchFirebaseUsersByEmail() {
  const map = new Map();
  let nextPageToken;

  do {
    const result = await admin.auth().listUsers(1000, nextPageToken);
    for (const user of result.users) {
      if (user.email) map.set(user.email.toLowerCase(), user.uid);
    }
    nextPageToken = result.pageToken;
  } while (nextPageToken);

  return map;
}

/** @returns {Map<string, string>} supabaseUid → firebaseUid */
async function buildUidMap(supabase) {
  if (process.env.UID_MAP_JSON) {
    const parsed = JSON.parse(process.env.UID_MAP_JSON);
    return new Map(Object.entries(parsed));
  }

  const supabaseUserId = process.env.SUPABASE_USER_ID?.trim();
  const firebaseUserId = process.env.FIREBASE_USER_ID?.trim();
  if (supabaseUserId && firebaseUserId) {
    return new Map([[supabaseUserId, firebaseUserId]]);
  }

  if (!autoMapByEmail) {
    throw new Error(
      'Define AUTO_MAP_BY_EMAIL=true, UID_MAP_JSON o SUPABASE_USER_ID + FIREBASE_USER_ID',
    );
  }

  console.log('Construyendo mapa de usuarios por email...');
  const supabaseIdToEmail = await fetchSupabaseUsersById(supabase);
  const emailToFirebaseUid = await fetchFirebaseUsersByEmail();

  const uidMap = new Map();
  const missingEmails = [];

  for (const [supabaseUid, email] of supabaseIdToEmail) {
    const firebaseUid = emailToFirebaseUid.get(email);
    if (firebaseUid) {
      uidMap.set(supabaseUid, firebaseUid);
    } else {
      missingEmails.push(email);
    }
  }

  if (missingEmails.length) {
    console.warn(
      '\n⚠ Emails en Supabase sin cuenta en Firebase Auth (regístralos antes de migrar):',
    );
    [...new Set(missingEmails)].forEach((e) => console.warn(`  - ${e}`));
  }

  return uidMap;
}

/** @param {FirebaseFirestore.Firestore} firestore */
async function writeBatches(firestore, writes) {
  for (let i = 0; i < writes.length; i += BATCH_SIZE) {
    const chunk = writes.slice(i, i + BATCH_SIZE);
    const batch = firestore.batch();
    for (const { id, data } of chunk) {
      batch.set(firestore.collection(COLLECTION).doc(id), data, { merge: true });
    }
    await batch.commit();
    console.log(`  Escritos ${Math.min(i + BATCH_SIZE, writes.length)} / ${writes.length}`);
  }
}

async function main() {
  console.log('=== Migración Supabase → Firestore ===\n');
  if (dryRun) console.log('Modo DRY_RUN: no se escribirá en Firestore.\n');

  const supabase = initSupabase();
  const firestore = initFirebase();

  const entries = await fetchAllDiaryEntries(supabase);
  console.log(`Entradas en Supabase: ${entries.length}`);

  if (!entries.length) {
    console.log('Nada que migrar.');
    return;
  }

  const uidMap = await buildUidMap(supabase);
  console.log(`Usuarios mapeados: ${uidMap.size}\n`);

  const writes = [];
  const skipped = [];

  for (const row of entries) {
    const supabaseUid = row.user_id;
    const firebaseUid = uidMap.get(supabaseUid);
    if (!firebaseUid) {
      skipped.push({ id: row.id, supabaseUid, reason: 'sin mapeo de usuario' });
      continue;
    }
    writes.push({
      id: String(row.id),
      data: toFirestoreDoc(row, firebaseUid),
    });
  }

  console.log(`Listas para migrar: ${writes.length}`);
  console.log(`Omitidas: ${skipped.length}`);

  if (skipped.length) {
    console.log('\nPrimeras omitidas:');
    skipped.slice(0, 10).forEach((s) =>
      console.log(`  - ${s.id} (${s.reason})`),
    );
  }

  if (!writes.length) {
    console.log('\nNo hay documentos para escribir. Revisa usuarios en Firebase Auth.');
    process.exit(1);
  }

  if (dryRun) {
    console.log('\nEjemplo de documento:');
    console.log(JSON.stringify(writes[0], null, 2));
    console.log('\nDRY_RUN finalizado. Ejecuta sin DRY_RUN para migrar.');
    return;
  }

  console.log('\nEscribiendo en Firestore...');
  await writeBatches(firestore, writes);

  console.log('\n✓ Migración completada.');
  console.log(
    'Abre la app con Firebase, inicia sesión con el mismo email y pulsa sincronizar o reinicia.',
  );
}

main().catch((err) => {
  console.error('\n✗ Error:', err.message ?? err);
  process.exit(1);
});
