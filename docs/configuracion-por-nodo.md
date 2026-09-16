# Configuracion por nodo

Este repositorio contiene una configuracion de Patroni por host. No se debe copiar
la configuracion de un nodo sobre otro.

| Nodo | Archivo versionado | IP actual | Rol |
| --- | --- | --- | --- |
| Nodo 1 | `config/patroni/nodes/node1.yml` | `100.120.213.18` | Lider inicial y candidato a lider |
| Nodo 2 | `config/patroni/nodes/node2.yml` | `100.87.77.76` | Replica sincronica y candidato a lider |
| Nodo 3 | `config/patroni/nodes/node3.yml` | `100.108.44.95` | Replica asincronica de solo lectura |

## Que modifica cada integrante

Cada integrante modifica solo el archivo de su nodo:

- `name` debe coincidir con el nombre del archivo: `node1`, `node2` o `node3`.
- `restapi.connect_address` usa la IP propia y el puerto `8008`.
- `postgresql.connect_address` usa la IP y el puerto propios: Nodo 1 usa `5432`,
  Nodo 2 usa `5433` y Nodo 3 usa `5434`. Nodo 2 y Nodo 3 evitan así el puerto
  `5432`, que ya está ocupado por PostgreSQL local en esos hosts.
- La lista `etcd3.hosts` debe incluir las tres IP de Tailscale con el endpoint
  `:2379` y mantenerse identica en los tres archivos.

Los valores `scope`, `namespace`, `bootstrap.dcs` y la lista completa de etcd son
compartidos: deben mantenerse iguales en los tres archivos. No se deben cambiar
desde un solo host sin avisar al equipo.

## Credenciales

Las contrasenas no se guardan en los YAML. Cada host crea
`config/patroni/.env` a partir de `.env.example` con las mismas dos contrasenas
acordadas por el equipo. Ese archivo esta ignorado por Git.

Los puertos de `postgres_exporter` están versionados sin credenciales en
`config/postgres-exporter/node1.env`, `node2.env` y `node3.env`.

## Iniciar un nodo

Desde la raiz del repositorio, en el host correspondiente:

```bash
NODE_NAME=node2 docker compose \
  --env-file config/patroni/.env \
  -f docker/docker-compose.node.yml up -d
```

Cambie solo `NODE_NAME` por `node1`, `node2` o `node3` segun el host. El volumen
se crea como `pgdata_node1`, `pgdata_node2` o `pgdata_node3`, por lo que los datos
persistentes no se comparten ni se sobrescriben entre nodos.

## Antes de iniciar el cluster

1. Confirmar que etcd se ejecuta en los tres hosts y escucha en el puerto `2379`.
2. Construir o descargar la misma imagen en los tres hosts. El Compose construye
   localmente `proyecto1-patroni:pg16.15-patroni4.1.5`, basada en PostgreSQL
   `16.15` con Patroni `4.1.5`; no se usa la etiqueta mutable `latest`.
