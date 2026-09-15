# Ejecución y pruebas

## Antes de iniciar

1. Confirmar que las tres direcciones de Tailscale configuradas sean las de Nodo 1,
   Nodo 2 y Nodo 3 antes de iniciar etcd por primera vez.
2. Crear `config/patroni/.env` desde `.env.example` en cada host, usando las
   mismas credenciales de prueba. No subirlo a Git.
3. Verificar Tailscale entre los tres hosts y abrir los puertos 2379, 2380, 5432,
   8008, 9100 y 9187 dentro de la red privada.
4. Los tres integrantes deben iniciar etcd y Patroni en una misma sesión para la
   primera creación del clúster.
5. La primera vez, Compose construirá la imagen local con PostgreSQL `16.15` y
   Patroni `4.1.5`. Los tres nodos deben usar esa misma versión.

## Nodo de base de datos

En cada host, usando su nombre de nodo:

```bash
NODE_NAME=node2 docker compose \
  --env-file config/patroni/.env \
  -f docker/docker-compose.node.yml up -d
```

Comprobar el estado desde cualquiera de los contenedores Patroni:

```bash
docker exec -it pg_node2 patronictl -c /etc/patroni.yml list
```

Debe existir un `Leader` y dos `Replica`.

## Proxy y monitoreo

En el host designado para HAProxy:

```bash
docker compose -f docker/docker-compose.haproxy.yml up -d
```

En el host de monitoreo, crear `config/monitoring/.env` desde su ejemplo y luego:

```bash
docker compose --env-file config/monitoring/.env \
  -f docker/docker-compose.monitoring.yml up -d
```

Prometheus queda en `http://HOST_MONITOREO:9090`, Grafana en
`http://HOST_MONITOREO:3000` y las estadísticas de HAProxy en
`http://HOST_HAPROXY:8404/stats`.

## Replicación y carga

Ejecutar primero `scripts/dataset.sql` en el líder. Después ejecutar
`scripts/pruebas-replicacion.sql` a través del puerto de escritura de HAProxy
y verificar las consultas desde el puerto de lectura. Para generar volumen antes
de la Fase 6, ejecutar `scripts/carga_masiva.sql` únicamente contra el líder.

El script `scripts/carga.js` requiere una distribución de k6 con la extensión
`xk6-sql` y un driver PostgreSQL. Ejemplo de variable de conexión:

```bash
DATABASE_URL='postgres://postgres:CLAVE@IP_HAPROXY:5000/postgres?sslmode=disable' \
k6 run scripts/carga.js
```

Durante la prueba, detener un nodo principal aproximadamente a la mitad de la
ejecución y registrar operaciones, errores, latencia, RTO y RPO.
