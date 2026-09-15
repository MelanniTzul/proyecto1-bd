-- Ejecutar INSERT, UPDATE y DELETE solamente contra el lider vigente.
-- Verificar despues los SELECT en las replicas mediante el puerto de lectura de HAProxy.

INSERT INTO clientes (nombre, correo, telefono)
VALUES ('Cliente de replicacion', 'replicacion@correo.com', '5555-0000')
RETURNING id, creado;

UPDATE productos
SET stock = stock - 1
WHERE nombre = 'Mouse inalámbrico'
RETURNING id, nombre, stock;

DELETE FROM clientes
WHERE correo = 'replicacion@correo.com'
RETURNING id, nombre;

SELECT id, nombre, correo, creado
FROM clientes
ORDER BY id;

SELECT id, nombre, stock
FROM productos
ORDER BY id;
