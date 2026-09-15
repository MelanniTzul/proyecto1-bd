-- Carga masiva para la Fase 6 y verificacion de replicacion con volumen.
-- Ejecutar despues de scripts/dataset.sql y solo contra el lider vigente.

-- 500 clientes nuevos
INSERT INTO clientes (nombre, correo, telefono)
SELECT
  'Cliente ' || s || '-' || floor(random() * 100000)::int,
  'cliente' || s || floor(random() * 100000)::int || '@correo.com',
  '5555-' || lpad((floor(random() * 9999))::text, 4, '0')
FROM generate_series(1, 500) AS s;

-- 50 empleados nuevos
INSERT INTO empleados (nombre, puesto)
SELECT
  'Empleado ' || s || '-' || floor(random() * 100000)::int,
  (ARRAY['Vendedor', 'Cajero', 'Supervisor', 'Bodeguero'])[1 + floor(random() * 4)::int]
FROM generate_series(1, 50) AS s;

-- 100 productos nuevos; requiere que existan categorias.
INSERT INTO productos (nombre, precio, stock, categoria_id)
SELECT
  'Producto ' || s || '-' || floor(random() * 100000)::int,
  round((random() * 500 + 20)::numeric, 2),
  floor(random() * 200)::int,
  (SELECT id FROM categorias ORDER BY random() LIMIT 1)
FROM generate_series(1, 100) AS s;

-- 2000 pedidos nuevos distribuidos entre clientes y empleados existentes.
INSERT INTO pedidos (cliente_id, empleado_id, estado, fecha)
SELECT
  (SELECT id FROM clientes ORDER BY random() LIMIT 1),
  (SELECT id FROM empleados ORDER BY random() LIMIT 1),
  (ARRAY['pendiente', 'enviado', 'entregado', 'cancelado'])[1 + floor(random() * 4)::int],
  now() - (random() * interval '180 days')
FROM generate_series(1, 2000) AS s;

-- Aproximadamente 4000 detalles de pedido.
INSERT INTO detalle_pedidos (pedido_id, producto_id, cantidad, precio_unitario)
SELECT
  p.id,
  (SELECT id FROM productos ORDER BY random() LIMIT 1),
  1 + floor(random() * 5)::int,
  round((random() * 400 + 20)::numeric, 2)
FROM pedidos p
CROSS JOIN generate_series(1, 2) AS s
ORDER BY random()
LIMIT 4000;

-- Aproximadamente 2000 pagos.
INSERT INTO pagos (pedido_id, metodo, monto)
SELECT
  p.id,
  (ARRAY['tarjeta', 'efectivo', 'transferencia'])[1 + floor(random() * 3)::int],
  round((random() * 1000 + 20)::numeric, 2)
FROM pedidos p
ORDER BY random()
LIMIT 2000;

SELECT 'clientes' AS tabla, COUNT(*) AS total FROM clientes
UNION ALL SELECT 'empleados', COUNT(*) FROM empleados
UNION ALL SELECT 'categorias', COUNT(*) FROM categorias
UNION ALL SELECT 'productos', COUNT(*) FROM productos
UNION ALL SELECT 'pedidos', COUNT(*) FROM pedidos
UNION ALL SELECT 'detalle_pedidos', COUNT(*) FROM detalle_pedidos
UNION ALL SELECT 'pagos', COUNT(*) FROM pagos;
