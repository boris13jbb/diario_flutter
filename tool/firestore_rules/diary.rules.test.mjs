import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  query,
  where,
  orderBy,
  limit,
  getDocs,
  Timestamp,
} from 'firebase/firestore';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const rules = readFileSync(resolve(root, 'firestore.rules'), 'utf8');

const env = await initializeTestEnvironment({
  projectId: 'diario-rules-test',
  firestore: { rules },
});

const noteA = {
  id: 'note-a',
  user_id: 'user-a',
  title: 'Nota de A',
  content: 'privada',
  date: '2026-09-10',
};
const noteB = {
  id: 'note-b',
  user_id: 'user-b',
  title: 'Nota de B',
  content: 'ajena',
  date: '2026-09-10',
};

function db(uid, email) {
  if (!uid) return env.unauthenticatedContext().firestore();
  return env.authenticatedContext(uid, { email }).firestore();
}

/** Misma fórmula que NoteShareService.accessDocId / shareDocId en rules. */
function accessDocId(noteId, email) {
  return `${noteId}_${email.trim().toLowerCase()}`;
}

function commentsQuery(firestore, noteId, ownerId) {
  return getDocs(
    query(
      collection(firestore, 'note_comments'),
      where('note_id', '==', noteId),
      where('owner_id', '==', ownerId),
      orderBy('created_at', 'asc'),
    ),
  );
}

function scopedEntryQuery(firestore, userId, entryId) {
  return getDocs(
    query(
      collection(firestore, 'diary_entries'),
      where('user_id', '==', userId),
      where('id', '==', entryId),
      limit(1),
    ),
  );
}

let failed = 0;

async function check(name, fn) {
  try {
    await fn();
    console.log(`ok  ${name}`);
  } catch (error) {
    failed += 1;
    console.error(`FAIL ${name}`);
    console.error(error);
  }
}

await env.withSecurityRulesDisabled(async (context) => {
  const admin = context.firestore();
  await setDoc(doc(admin, 'diary_entries/note-b'), noteB);
  await setDoc(doc(admin, 'note_categories/cat-b'), {
    user_id: 'user-b',
    name: 'B',
    color: 1,
  });
  await setDoc(doc(admin, 'user_settings/user-b'), { favorite_ids: ['x'] });
  await setDoc(doc(admin, 'note_comments/comment-b'), {
    note_id: 'note-b',
    owner_id: 'user-b',
    user_id: 'user-b',
    text: 'secreto',
    created_at: Timestamp.fromDate(new Date('2026-09-10T12:00:00Z')),
  });
  await setDoc(doc(admin, 'note_comments/comment-b-2'), {
    note_id: 'note-b',
    owner_id: 'user-b',
    user_id: 'user-b',
    text: 'segundo',
    created_at: Timestamp.fromDate(new Date('2026-09-10T13:00:00Z')),
  });
  // Concesión legacy UUID (formato anterior).
  await setDoc(doc(admin, 'shared_notes/legacy-uuid-share-001'), {
    note_id: 'note-b',
    owner_id: 'user-b',
    shared_with_email: 'legacy@example.com',
    permission: 'read',
  });
});

await check('usuario no autenticado no lee notas', async () => {
  await assertFails(getDoc(doc(db(null), 'diary_entries/note-b')));
});

await check('usuario A no lee una nota de usuario B', async () => {
  await assertFails(getDoc(doc(db('user-a', 'a@example.com'), 'diary_entries/note-b')));
});

await check('usuario A no edita una nota de usuario B', async () => {
  await assertFails(
    updateDoc(doc(db('user-a', 'a@example.com'), 'diary_entries/note-b'), {
      title: 'robada',
      user_id: 'user-b',
    }),
  );
});

await check('usuario A crea su propia nota', async () => {
  await assertSucceeds(
    setDoc(doc(db('user-a', 'a@example.com'), 'diary_entries/note-a'), noteA),
  );
});

await check('cambiar user_id en una actualización se rechaza', async () => {
  await assertFails(
    updateDoc(doc(db('user-a', 'a@example.com'), 'diary_entries/note-a'), {
      title: 'sigue siendo mia',
      user_id: 'user-b',
    }),
  );
});

await check('el propietario sí puede actualizar sin cambiar user_id', async () => {
  await assertSucceeds(
    updateDoc(doc(db('user-a', 'a@example.com'), 'diary_entries/note-a'), {
      title: 'editada',
      user_id: 'user-a',
    }),
  );
});

await check('GET ENTRY OWNED', async () => {
  const snap = await assertSucceeds(
    scopedEntryQuery(db('user-a', 'a@example.com'), 'user-a', 'note-a'),
  );
  if (snap.size !== 1 || snap.docs[0].id !== 'note-a') {
    throw new Error('Debía devolver exactamente la nota propia');
  }
  console.log('GET ENTRY OWNED        PASS');
});

await check('GET ENTRY MISSING', async () => {
  const snap = await assertSucceeds(
    scopedEntryQuery(db('user-a', 'a@example.com'), 'user-a', 'aun-no-existe'),
  );
  if (snap.size !== 0) {
    throw new Error('Una nota inexistente debe devolver snapshot vacío');
  }
  console.log('GET ENTRY MISSING      PASS');
});

await check('GET ENTRY OTHER USER', async () => {
  const snap = await assertSucceeds(
    scopedEntryQuery(db('user-a', 'a@example.com'), 'user-a', 'note-b'),
  );
  if (snap.size !== 0) {
    throw new Error('La consulta de A por id de B debía quedar vacía');
  }
  console.log('GET ENTRY OTHER USER   PASS');
});

await check('GET ENTRY DIRECT OTHER USER DENIED', async () => {
  await assertFails(getDoc(doc(db('user-a', 'a@example.com'), 'diary_entries/note-b')));
});

await check('una nota inexistente consultada por user_id no es permission-denied', async () => {
  const snap = await assertSucceeds(
    getDocs(
      query(
        collection(db('user-a', 'a@example.com'), 'diary_entries'),
        where('user_id', '==', 'user-a'),
      ),
    ),
  );
  const found = snap.docs.some((item) => item.id === 'aun-no-existe');
  if (found) {
    throw new Error('Una nota inexistente no debe aparecer en la consulta del usuario');
  }
});

await check('usuario A no lista las categorías de usuario B', async () => {
  await assertFails(
    getDocs(
      query(
        collection(db('user-a', 'a@example.com'), 'note_categories'),
        where('user_id', '==', 'user-b'),
      ),
    ),
  );
});

await check('usuario A no lee los ajustes de usuario B', async () => {
  await assertFails(getDoc(doc(db('user-a', 'a@example.com'), 'user_settings/user-b')));
});

await check('COMMENTS OWNER QUERY', async () => {
  const snap = await assertSucceeds(
    commentsQuery(db('user-b', 'b@example.com'), 'note-b', 'user-b'),
  );
  if (snap.size < 2) {
    throw new Error(`El propietario debía listar sus comentarios, obtuvo ${snap.size}`);
  }
  console.log('COMMENTS OWNER QUERY          PASS');
});

await check('COMMENTS UNAUTHORIZED QUERY', async () => {
  await assertFails(
    commentsQuery(db('user-c', 'c@example.com'), 'note-b', 'user-b'),
  );
  console.log('COMMENTS UNAUTHORIZED QUERY   DENIED');
});

await check('COMMENTS SHARED QUERY', async () => {
  const shareId = accessDocId('note-b', 'c@example.com');
  await assertSucceeds(
    setDoc(doc(db('user-b', 'b@example.com'), `shared_notes/${shareId}`), {
      note_id: 'note-b',
      owner_id: 'user-b',
      shared_with_email: 'c@example.com',
      permission: 'read',
    }),
  );
  const snap = await assertSucceeds(
    commentsQuery(db('user-c', 'c@example.com'), 'note-b', 'user-b'),
  );
  if (snap.size < 1) {
    throw new Error('El usuario compartido debía listar comentarios');
  }
  console.log('COMMENTS SHARED QUERY         PASS');
});

await check('COMMENTS REVOKED QUERY', async () => {
  const shareId = accessDocId('note-b', 'c@example.com');
  await assertSucceeds(
    deleteDoc(doc(db('user-b', 'b@example.com'), `shared_notes/${shareId}`)),
  );
  await assertFails(
    commentsQuery(db('user-c', 'c@example.com'), 'note-b', 'user-b'),
  );
  console.log('COMMENTS REVOKED QUERY        DENIED');
});

await check('LEGACY SHARE TEST', async () => {
  // El UUID legacy no autoriza: Rules solo mira el documento canónico.
  await assertFails(
    commentsQuery(db('user-legacy', 'legacy@example.com'), 'note-b', 'user-b'),
  );
  const canonical = accessDocId('note-b', 'legacy@example.com');
  await assertSucceeds(
    setDoc(doc(db('user-b', 'b@example.com'), `shared_notes/${canonical}`), {
      note_id: 'note-b',
      owner_id: 'user-b',
      shared_with_email: 'legacy@example.com',
      permission: 'read',
    }),
  );
  const snap = await assertSucceeds(
    commentsQuery(db('user-legacy', 'legacy@example.com'), 'note-b', 'user-b'),
  );
  if (snap.size < 1) {
    throw new Error('Tras crear el canónico, el acceso legacy migrado debe funcionar');
  }
  console.log('LEGACY SHARE TEST             PASS');
});

await check('CANONICAL SHARE ID', async () => {
  const email = '  Ana@Example.com  ';
  const expected = accessDocId('note-a', email);
  if (expected !== 'note-a_ana@example.com') {
    throw new Error(`Fórmula canónica incorrecta: ${expected}`);
  }
  await assertSucceeds(
    setDoc(doc(db('user-a', 'a@example.com'), `shared_notes/${expected}`), {
      note_id: 'note-a',
      owner_id: 'user-a',
      shared_with_email: 'ana@example.com',
      permission: 'read',
    }),
  );
  // Mayúsculas en shared_with_email: rechazado por isValidShareEmail.
  await assertFails(
    setDoc(doc(db('user-a', 'a@example.com'), 'shared_notes/note-a_Ana@Example.com'), {
      note_id: 'note-a',
      owner_id: 'user-a',
      shared_with_email: 'Ana@Example.com',
      permission: 'read',
    }),
  );
  // `/` no es un document id válido; el cliente o Rules deben rechazarlo.
  let slashRejected = false;
  try {
    await setDoc(
      doc(db('user-a', 'a@example.com'), 'shared_notes/note-a_bad_slash@example.com'),
      {
        note_id: 'note-a',
        owner_id: 'user-a',
        shared_with_email: 'bad/slash@example.com',
        permission: 'read',
      },
    );
  } catch (_) {
    slashRejected = true;
  }
  if (!slashRejected) {
    throw new Error('Un correo con / debía rechazarse');
  }
  console.log('CANONICAL SHARE ID            PASS');
});

await check('solo propietario crea share y no auto-concede nota ajena', async () => {
  await assertFails(
    setDoc(doc(db('user-a', 'a@example.com'), 'shared_notes/note-b_a@example.com'), {
      note_id: 'note-b',
      owner_id: 'user-a',
      shared_with_email: 'a@example.com',
      permission: 'read',
    }),
  );
});

await check('no se modifican note_id owner_id ni email del share', async () => {
  const shareId = accessDocId('note-a', 'ana@example.com');
  await assertFails(
    updateDoc(doc(db('user-a', 'a@example.com'), `shared_notes/${shareId}`), {
      note_id: 'otra',
    }),
  );
  await assertFails(
    updateDoc(doc(db('user-a', 'a@example.com'), `shared_notes/${shareId}`), {
      owner_id: 'user-b',
    }),
  );
  await assertFails(
    updateDoc(doc(db('user-a', 'a@example.com'), `shared_notes/${shareId}`), {
      shared_with_email: 'otra@example.com',
    }),
  );
  await assertSucceeds(
    updateDoc(doc(db('user-a', 'a@example.com'), `shared_notes/${shareId}`), {
      permission: 'edit',
    }),
  );
  await assertFails(
    updateDoc(doc(db('user-a', 'a@example.com'), `shared_notes/${shareId}`), {
      permission: 'admin',
    }),
  );
});

await check('usuario A no crea un comentario haciéndose pasar por B', async () => {
  await assertFails(
    setDoc(doc(db('user-a', 'a@example.com'), 'note_comments/falso'), {
      note_id: 'note-a',
      owner_id: 'user-a',
      user_id: 'user-b',
      text: 'no soy B',
    }),
  );
});

await env.cleanup();

if (failed > 0) {
  console.error(`${failed} prueba(s) de reglas fallaron`);
  process.exit(1);
}
console.log('FIRESTORE RULES      PASS');
