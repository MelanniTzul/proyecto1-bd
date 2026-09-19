import sql from 'k6/x/sql';
import driver from 'k6/x/sql/driver/postgres';
import { check, sleep } from 'k6';
import { Counter, Trend } from 'k6/metrics';

const password = __ENV.PATRONI_SUPERUSER_PASSWORD;

if (!password) {
  throw new Error(
    'No se encontro PATRONI_SUPERUSER_PASSWORD. Use scripts/ejecutar-carga.sh.',
  );
}

const node3Host = __ENV.NODE3_DB_HOST || '100.108.44.95';
const node3Port = __ENV.NODE3_DB_PORT || '5434';
const database = __ENV.DB_NAME || 'postgres';
const user = __ENV.DB_USER || 'postgres';
const pauseSeconds = Number(__ENV.PAUSE_SECONDS || 0.1);

const node3Url = `postgres://${encodeURIComponent(user)}:${encodeURIComponent(password)}@${node3Host}:${node3Port}/${encodeURIComponent(database)}?sslmode=disable`;
const db = sql.open(driver, node3Url);

const lecturasTotales = new Counter('lecturas_totales');
const lecturasExitosas = new Counter('lecturas_exitosas');
const lecturasFallidas = new Counter('lecturas_fallidas');
const latenciaLectura = new Trend('latencia_lectura_ms', true);

export const options = {
  vus: Number(__ENV.VUS || 20),
  duration: __ENV.DURATION || '2m',
  thresholds: {
    lecturas_totales: ['count>=0'],
    lecturas_exitosas: ['count>=0'],
    lecturas_fallidas: ['count>=0'],
    latencia_lectura_ms: ['p(95)>=0'],
  },
};

let erroresMostrados = 0;

export default function () {
  const inicio = Date.now();
  lecturasTotales.add(1);

  try {
    let total = null;
    const rows = db.query('SELECT COUNT(*) AS total FROM clientes');

    for (const row of rows) {
      total = Number(row.total);
    }

    const correcta = Number.isFinite(total) && total >= 0;
    check(correcta, {
      'lectura de Node 3 completada': (value) => value === true,
    });

    if (!correcta) {
      throw new Error('No se obtuvo el conteo de clientes');
    }

    lecturasExitosas.add(1);
  } catch (error) {
    lecturasFallidas.add(1);
    check(false, {
      'lectura de Node 3 completada': (value) => value === true,
    });

    if (erroresMostrados < 3) {
      console.warn(`Lectura de Node 3 fallida: ${String(error)}`);
      erroresMostrados += 1;
    }
  } finally {
    latenciaLectura.add(Date.now() - inicio);
  }

  sleep(pauseSeconds);
}

export function teardown() {
  db.close();
}
