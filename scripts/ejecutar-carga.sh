#!/usr/bin/env bash

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(dirname "$SCRIPT_DIR")
ENV_FILE="$PROJECT_DIR/config/patroni/.env"
K6_BIN="$PROJECT_DIR/k6-tools/k6-sql"
MODE=${1:-}

show_usage() {
  printf '%s\n' \
    'Uso:' \
    '  ./scripts/ejecutar-carga.sh mixta' \
    '  ./scripts/ejecutar-carga.sh lectura-node3' \
    '' \
    'Variables opcionales:' \
    '  VUS=20 DURATION=2m FAILURE_AT_SECONDS=60 PAUSE_SECONDS=0.1' \
    '  PROMETHEUS_OUTPUT=1 envia metricas a Prometheus local (Node 2)'
}

if [ "$MODE" != 'mixta' ] && [ "$MODE" != 'lectura-node3' ]; then
  show_usage
  exit 2
fi

if [ ! -f "$ENV_FILE" ]; then
  printf 'No existe %s. Creelo desde config/patroni/.env.example.\n' "$ENV_FILE" >&2
  exit 1
fi

if [ ! -x "$K6_BIN" ]; then
  printf 'No existe el binario ejecutable %s. Construyalo siguiendo la guia de Fase 6.\n' "$K6_BIN" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

if [ -z "${PATRONI_SUPERUSER_PASSWORD:-}" ]; then
  printf 'PATRONI_SUPERUSER_PASSWORD no esta definido en %s.\n' "$ENV_FILE" >&2
  exit 1
fi

RUN_ID=${RUN_ID:-$(date '+%Y%m%d-%H%M%S')}
RESULT_DIR=${RESULT_DIR:-/tmp/proyecto1-fase6}
mkdir -p "$RESULT_DIR"
export RUN_ID

case "$MODE" in
  mixta)
    SCRIPT="$PROJECT_DIR/scripts/carga.js"
    ;;
  lectura-node3)
    SCRIPT="$PROJECT_DIR/scripts/carga-lectura.js"
    ;;
esac

SUMMARY_FILE="$RESULT_DIR/${MODE}-${RUN_ID}.json"

printf 'Modo: %s\n' "$MODE"
printf 'Inicio: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
printf 'Resumen JSON: %s\n' "$SUMMARY_FILE"

cd "$PROJECT_DIR"
if [ "${PROMETHEUS_OUTPUT:-0}" = '1' ]; then
  export K6_PROMETHEUS_RW_SERVER_URL=${K6_PROMETHEUS_RW_SERVER_URL:-http://127.0.0.1:9090/api/v1/write}
  export K6_PROMETHEUS_RW_TREND_STATS='avg,p(95)'
  "$K6_BIN" run --out experimental-prometheus-rw --summary-export "$SUMMARY_FILE" "$SCRIPT"
else
  "$K6_BIN" run --summary-export "$SUMMARY_FILE" "$SCRIPT"
fi

printf 'Fin: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
