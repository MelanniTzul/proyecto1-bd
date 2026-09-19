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

const writeHost = __ENV.WRITE_DB_HOST || '127.0.0.1';
const writePort = __ENV.WRITE_DB_PORT || '5000';
const readHost = __ENV.READ_DB_HOST || '127.0.0.1';
const readPort = __ENV.READ_DB_PORT || '5001';
const database = __ENV.DB_NAME || 'postgres';
const user = __ENV.DB_USER || 'postgres';
const failureAtSeconds = Number(__ENV.FAILURE_AT_SECONDS || 60);
const pauseSeconds = Number(__ENV.PAUSE_SECONDS || 0.1);
const runId = __ENV.RUN_ID || `${Date.now()}`;
const startedAt = Date.now();

function connectionUrl(host, port) {
  return `postgres://${encodeURIComponent(user)}:${encodeURIComponent(password)}@${host}:${port}/${encodeURIComponent(database)}?sslmode=disable`;
}

const writeDb = sql.open(driver, connectionUrl(writeHost, writePort));
const readDb = sql.open(driver, connectionUrl(readHost, readPort));

const operacionesTotales = new Counter('operaciones_totales');
const operacionesExitosas = new Counter('operaciones_exitosas');
const operacionesFallidas = new Counter('operaciones_fallidas');
const lecturasExitosas = new Counter('lecturas_exitosas');
const escriturasExitosas = new Counter('escrituras_exitosas');
const latenciaLectura = new Trend('latencia_lectura_ms', true);
const latenciaEscritura = new Trend('latencia_escritura_ms', true);

export const options = {
  vus: Number(__ENV.VUS || 20),
  duration: __ENV.DURATION || '2m',
  thresholds: {
    'operaciones_totales{periodo:antes_falla}': ['count>=0'],
    'operaciones_totales{periodo:despues_falla}': ['count>=0'],
    'operaciones_exitosas{periodo:antes_falla}': ['count>=0'],
    'operaciones_exitosas{periodo:despues_falla}': ['count>=0'],
    'operaciones_fallidas{periodo:antes_falla}': ['count>=0'],
    'operaciones_fallidas{periodo:despues_falla}': ['count>=0'],
    'latencia_lectura_ms{periodo:antes_falla}': ['p(95)>=0'],
    'latencia_lectura_ms{periodo:despues_falla}': ['p(95)>=0'],
    'latencia_escritura_ms{periodo:antes_falla}': ['p(95)>=0'],
    'latencia_escritura_ms{periodo:despues_falla}': ['p(95)>=0'],
  },
};

let erroresMostrados = 0;

function periodoActual() {
  const elapsedSeconds = (Date.now() - startedAt) / 1000;
  return elapsedSeconds < failureAtSeconds ? 'antes_falla' : 'despues_falla';
}

function registrarError(tipo, error) {
  if (erroresMostrados < 3) {
    console.warn(`${tipo} fallida: ${String(error)}`);
    erroresMostrados += 1;
  }
}

function ejecutarLectura() {
  const tags = { operacion: 'lectura', periodo: periodoActual() };
  const inicio = Date.now();
  operacionesTotales.add(1, tags);

  try {
    let filas = 0;
    const rows = readDb.query(
      'SELECT id, nombre, correo FROM clientes ORDER BY id DESC LIMIT 10',
    );

    for (const row of rows) {
      if (row.id !== null) {
        filas += 1;
      }
    }

    const correcta = filas > 0;
    check(correcta, { 'lectura completada': (value) => value === true }, tags);

    if (!correcta) {
      throw new Error('La consulta no devolvio filas');
    }

    operacionesExitosas.add(1, tags);
    lecturasExitosas.add(1, tags);
  } catch (error) {
    operacionesFallidas.add(1, tags);
    check(false, { 'lectura completada': (value) => value === true }, tags);
    registrarError('Lectura', error);
  } finally {
    latenciaLectura.add(Date.now() - inicio, tags);
  }
}

function ejecutarEscritura() {
  const tags = { operacion: 'escritura', periodo: periodoActual() };
  const inicio = Date.now();
  operacionesTotales.add(1, tags);

  try {
    const result = writeDb.exec(
      'INSERT INTO clientes (nombre, correo, telefono) VALUES ($1, $2, $3)',
      `Carga ${runId}-${__VU}-${__ITER}`,
      `carga-${runId}-${__VU}-${__ITER}@prueba.local`,
      '5555-6000',
    );
    const correcta = result.rowsAffected() === 1;

    check(correcta, { 'escritura completada': (value) => value === true }, tags);

    if (!correcta) {
      throw new Error(`Filas insertadas: ${result.rowsAffected()}`);
    }

    operacionesExitosas.add(1, tags);
    escriturasExitosas.add(1, tags);
  } catch (error) {
    operacionesFallidas.add(1, tags);
    check(false, { 'escritura completada': (value) => value === true }, tags);
    registrarError('Escritura', error);
  } finally {
    latenciaEscritura.add(Date.now() - inicio, tags);
  }
}

export default function () {
  ejecutarLectura();
  ejecutarEscritura();
  sleep(pauseSeconds);
}

export function teardown() {
  readDb.close();
  writeDb.close();
}
