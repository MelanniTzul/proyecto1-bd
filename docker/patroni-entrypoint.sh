#!/bin/sh
set -eu

# Docker crea los volumenes nombrados como root. Patroni debe iniciar PostgreSQL
# como el usuario postgres, por lo que corrige el propietario antes de reducir
# privilegios.
data_dir="${PATRONI_POSTGRESQL_DATA_DIR:-/data/patroni}"
mkdir -p "$data_dir"
chown postgres:postgres "$data_dir"
chmod 700 "$data_dir"

exec gosu postgres "$@"
