import sql from 'k6/x/sql';
import { check } from 'k6';

if (!__ENV.DATABASE_URL) {
  throw new Error('Defina DATABASE_URL apuntando al puerto 5000 de HAProxy.');
}

const db = sql.open('postgres', __ENV.DATABASE_URL);

export const options = {
  vus: Number(__ENV.VUS || 20),
  duration: __ENV.DURATION || '2m',
};

export default function () {
  const result = sql.query(
    db,
    'INSERT INTO clientes (nombre, correo) VALUES ($1, $2) RETURNING id',
    `Carga ${__VU}-${__ITER}`,
    `carga-${__VU}-${__ITER}@correo.com`,
  );

  check(result, {
    'insert completado': (value) => value !== null,
  });
}
