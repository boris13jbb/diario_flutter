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
  getDocs,
} from 'firebase/firestore';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const rules = readFileSync(resolve(root, 'firestore.rules'), 'utf8');

const env = await initializeTestEnvironment({
  projectId: 'diario-rules-test',
  firestore: { rules },
});

const noteA = {
  user_id: 'user-a',
  title: 'Nota de A',
  content: 'privada',
  date: '2026-09-10',
};
const noteB = {
  user_id: 'user-b',
  title: 'Nota de B',
  content: 'ajena',
  date: '2026-09-10',
};

function db(uid, email) {
  if (!uid) return env.unauthenticatedContext().firestore();
  return env.authenticatedContext(uid, { email }).firestore();
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

await check('usuario A no lee comentarios de una nota ajena', async () => {
  await assertFails(getDoc(doc(db('user-a', 'a@example.com'), 'note_comments/comment-b')));
});

await check('el propietario sí lee sus comentarios', async () => {
  await assertSucceeds(getDoc(doc(db('user-b', 'b@example.com'), 'note_comments/comment-b')));
});

await check('usuario no autorizado no lee comentarios de la nota', async () => {
  await assertFails(getDoc(doc(db('user-c', 'c@example.com'), 'note_comments/comment-b')));
});

await check('el acceso se concede solo en shared_notes', async () => {
  await assertSucceeds(
    setDoc(doc(db('user-b', 'b@example.com'), 'shared_notes/note-b_c@example.com'), {
      note_id: 'note-b',
      owner_id: 'user-b',
      shared_with_email: 'c@example.com',
      permission: 'read',
    }),
  );
});

await check('usuario autorizado lee comentarios de la nota compartida', async () => {
  await assertSucceeds(getDoc(doc(db('user-c', 'c@example.com'), 'note_comments/comment-b')));
});

await check('al revocar el acceso deja de poder leer comentarios', async () => {
  await assertSucceeds(
    deleteDoc(doc(db('user-b', 'b@example.com'), 'shared_notes/note-b_c@example.com')),
  );
  await assertFails(getDoc(doc(db('user-c', 'c@example.com'), 'note_comments/comment-b')));
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

await check('usuario A no se concede acceso a una nota de B', async () => {
  await assertFails(
    setDoc(doc(db('user-a', 'a@example.com'), 'shared_notes/note-b_a@example.com'), {
      note_id: 'note-b',
      owner_id: 'user-a',
      shared_with_email: 'a@example.com',
      permission: 'read',
    }),
  );
});

await env.cleanup();

if (failed > 0) {
  console.error(`${failed} prueba(s) de reglas fallaron`);
  process.exit(1);
}
console.log('FIRESTORE RULES      PASS');
