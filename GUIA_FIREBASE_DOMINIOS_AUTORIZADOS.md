# Guía: Dominios autorizados de Firebase Auth (Vercel)

Esta guía documenta cómo se configuró Authentication para que el login funcione en la web desplegada en Vercel (`https://notaspro.vercel.app`).

## Por qué hace falta

Firebase Auth solo permite iniciar sesión desde dominios que estén en la lista **Authorized domains**.

Si la app carga en Vercel pero el login falla en el navegador, el error típico es:

```text
auth/unauthorized-domain
```

Sin el dominio autorizado, Auth puede fallar aunque el resto de la app funcione.

## Proyecto involucrado

| Dato | Valor |
|------|--------|
| Proyecto Firebase | `diario-notaspro` |
| App web | NotasPro |
| Dominio de producción | `notaspro.vercel.app` |
| Cuenta usada (CLI) | la cuenta con la que haces `firebase login` |

Dominios que ya suelen existir por defecto:

- `localhost`
- `diario-notaspro.firebaseapp.com`
- `diario-notaspro.web.app`

Dominio añadido para producción:

- `notaspro.vercel.app`

## Opción A — Consola de Firebase (recomendada para hacerla a mano)

1. Abre [Firebase Console](https://console.firebase.google.com/).
2. Selecciona el proyecto **Diario NotasPro** (`diario-notaspro`).
3. Ve a **Authentication** → **Settings** (Configuración).
4. Busca la sección **Authorized domains** (Dominios autorizados).
5. Haz clic en **Add domain** (Agregar dominio).
6. Escribe exactamente:

   ```text
   notaspro.vercel.app
   ```

   Sin `https://`, sin barra final.
7. Guarda / confirma.
8. Verifica que el dominio aparezca en la lista junto a `localhost` y los dominios `*.firebaseapp.com` / `*.web.app`.

### Preview de Vercel

Firebase **no admite wildcards** como `*.vercel.app`.

- Producción: basta con `notaspro.vercel.app`.
- Previews (`notaspro-xxxx.vercel.app`): hay que agregar **cada hostname exacto** si vas a probar Auth ahí.

## Opción B — Cómo se hizo por API (método usado en esta sesión)

Se usó la API Admin de Identity Toolkit con el token de la sesión local de Firebase CLI (`firebase login`), sin tocar el almacén de credenciales a mano ni imprimir tokens.

### Requisitos

- Tener [Firebase CLI](https://firebase.google.com/docs/cli) instalado.
- Estar autenticado: `firebase login`.
- Tener permisos de propietario/editor en el proyecto `diario-notaspro`.
- Node.js disponible (para el script).

### Pasos técnicos ejecutados

1. Confirmar proyecto activo:

   ```bash
   firebase projects:list
   ```

   Debe aparecer `diario-notaspro`.

2. Leer la configuración actual de Auth:

   ```http
   GET https://identitytoolkit.googleapis.com/admin/v2/projects/diario-notaspro/config
   Authorization: Bearer <ACCESS_TOKEN>
   ```

3. Revisar `authorizedDomains` (antes del cambio):

   ```json
   [
     "localhost",
     "diario-notaspro.firebaseapp.com",
     "diario-notaspro.web.app"
   ]
   ```

4. Añadir `notaspro.vercel.app` a la lista (sin borrar los existentes).

5. Guardar con PATCH:

   ```http
   PATCH https://identitytoolkit.googleapis.com/admin/v2/projects/diario-notaspro/config?updateMask=authorizedDomains
   Authorization: Bearer <ACCESS_TOKEN>
   Content-Type: application/json

   {
     "authorizedDomains": [
       "localhost",
       "diario-notaspro.firebaseapp.com",
       "diario-notaspro.web.app",
       "notaspro.vercel.app"
     ]
   }
   ```

   Importante: el PATCH con `updateMask=authorizedDomains` **reemplaza toda la lista**. Siempre hay que hacer GET primero y fusionar, nunca enviar solo el dominio nuevo.

6. Resultado verificado (después del cambio):

   ```json
   [
     "localhost",
     "diario-notaspro.firebaseapp.com",
     "diario-notaspro.web.app",
     "notaspro.vercel.app"
   ]
   ```

### Script de referencia (PowerShell / Node)

Puedes repetir el proceso con un script local similar a este (ajusta rutas si `firebase-tools` no está en global):

```javascript
const path = require('path');
const fbRoot = path.join(process.env.APPDATA, 'npm', 'node_modules', 'firebase-tools');

(async () => {
  const auth = require(path.join(fbRoot, 'lib', 'auth'));
  const scopes = require(path.join(fbRoot, 'lib', 'scopes'));

  const account = auth.getGlobalDefaultAccount();
  if (!account?.tokens?.refresh_token) {
    throw new Error('No hay sesión de firebase login');
  }

  const tokens = await auth.getAccessToken(
    account.tokens.refresh_token,
    [scopes.CLOUD_PLATFORM, scopes.FIREBASE_PLATFORM, scopes.EMAIL, scopes.OPENID],
  );

  const projectId = 'diario-notaspro';
  const url = `https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config`;
  const headers = {
    Authorization: `Bearer ${tokens.access_token}`,
    'Content-Type': 'application/json',
  };

  const getRes = await fetch(url, { headers });
  const config = await getRes.json();
  if (!getRes.ok) throw new Error(JSON.stringify(config));

  const domains = [...(config.authorizedDomains || [])];
  const toAdd = ['notaspro.vercel.app'];

  for (const d of toAdd) {
    if (!domains.includes(d)) domains.push(d);
  }

  const patchRes = await fetch(`${url}?updateMask=authorizedDomains`, {
    method: 'PATCH',
    headers,
    body: JSON.stringify({ authorizedDomains: domains }),
  });
  const updated = await patchRes.json();
  if (!patchRes.ok) throw new Error(JSON.stringify(updated));

  console.log(updated.authorizedDomains);
})();
```

> Seguridad: no imprimas ni compartas el access token / refresh token. El script solo debe usarlos en memoria para la llamada HTTP.

## Cómo verificar que quedó bien

### En consola

1. Authentication → Settings → Authorized domains.
2. Debe existir `notaspro.vercel.app`.

### En la app

1. Abre `https://notaspro.vercel.app` en ventana privada.
2. Intenta iniciar sesión.
3. Resultado esperado: login sin `auth/unauthorized-domain`.
4. Si falla:
   - Hard refresh (`Ctrl+F5`).
   - Confirma que la URL es exactamente `notaspro.vercel.app`.
   - Revisa la consola del navegador (F12).

## Errores frecuentes

| Problema | Causa | Solución |
|----------|--------|----------|
| `auth/unauthorized-domain` | Dominio no autorizado | Agregar el hostname exacto |
| Agregaste `https://notaspro.vercel.app` | Formato inválido | Usar solo `notaspro.vercel.app` |
| Preview de Vercel falla | Hostname distinto al de producción | Agregar ese preview concreto |
| PATCH borró `localhost` | Se envió la lista incompleta | Volver a GET + fusionar + PATCH |

## Resumen de lo hecho en NotasPro

1. Se identificó el proyecto Firebase `diario-notaspro`.
2. Se leyeron los dominios autorizados actuales.
3. Se agregó `notaspro.vercel.app`.
4. Se confirmó la lista final con los 4 dominios.
5. Quedó listo para probar login en producción Vercel.

## Enlaces útiles

- [Firebase Console — Auth Settings](https://console.firebase.google.com/project/diario-notaspro/authentication/settings)
- App producción: https://notaspro.vercel.app
- Documentación Firebase Auth (dominios autorizados): https://firebase.google.com/docs/auth/web/redirect-best-practices
