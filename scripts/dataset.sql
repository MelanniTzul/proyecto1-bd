-- Dataset de prueba para ejecutar solo en el lider actual del cluster.
-- ADVERTENCIA: reinicia estas tablas dentro de la base de datos seleccionada.
BEGIN;

DROP TABLE IF EXISTS pagos CASCADE;
DROP TABLE IF EXISTS detalle_pedidos CASCADE;
DROP TABLE IF EXISTS pedidos CASCADE;
DROP TABLE IF EXISTS productos CASCADE;
DROP TABLE IF EXISTS categorias CASCADE;
DROP TABLE IF EXISTS empleados CASCADE;
DROP TABLE IF EXISTS clientes CASCADE;

CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) UNIQUE,
    telefono VARCHAR(20),
    creado TIMESTAMP DEFAULT now()
);

CREATE TABLE empleados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    puesto VARCHAR(50),
    contratado DATE DEFAULT CURRENT_DATE
);

CREATE TABLE categorias (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    precio NUMERIC(10,2) NOT NULL CHECK (precio >= 0),
    stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    categoria_id INT REFERENCES categorias(id)
);

CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,
    cliente_id INT REFERENCES clientes(id),
    empleado_id INT REFERENCES empleados(id),
    estado VARCHAR(20) NOT NULL DEFAULT 'pendiente',
    fecha TIMESTAMP DEFAULT now()
);

CREATE TABLE detalle_pedidos (
    id SERIAL PRIMARY KEY,
    pedido_id INT REFERENCES pedidos(id),
    producto_id INT REFERENCES productos(id),
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(10,2) NOT NULL CHECK (precio_unitario >= 0)
);

CREATE TABLE pagos (
    id SERIAL PRIMARY KEY,
    pedido_id INT REFERENCES pedidos(id),
    metodo VARCHAR(30) NOT NULL,
    monto NUMERIC(10,2) NOT NULL CHECK (monto >= 0),
    fecha_pago TIMESTAMP DEFAULT now()
);

INSERT INTO clientes (nombre, correo, telefono) VALUES
  ('Ana López', 'ana@correo.com', '5555-1234'),
  ('Carlos Pérez', 'carlos@correo.com', '5555-5678'),
  ('María García', 'maria@correo.com', '5555-9012');

INSERT INTO empleados (nombre, puesto) VALUES
  ('Luis Ramírez', 'Vendedor'),
  ('Sofía Méndez', 'Cajera');

INSERT INTO categorias (nombre) VALUES
  ('Periféricos'),
  ('Almacenamiento'),
  ('Audio');

INSERT INTO productos (nombre, precio, stock, categoria_id) VALUES
  ('Teclado mecánico', 250.00, 30, 1),
  ('Mouse inalámbrico', 120.00, 50, 1),
  ('Disco SSD 500GB', 380.00, 20, 2),
  ('Audífonos Bluetooth', 199.00, 25, 3);

INSERT INTO pedidos (cliente_id, empleado_id, estado) VALUES
  (1, 1, 'enviado'),
  (2, 2, 'pendiente'),
  (3, 1, 'entregado');

INSERT INTO detalle_pedidos (pedido_id, producto_id, cantidad, precio_unitario) VALUES
  (1, 1, 2, 250.00),
  (1, 2, 1, 120.00),
  (2, 3, 1, 380.00),
  (3, 4, 2, 199.00);

INSERT INTO pagos (pedido_id, metodo, monto) VALUES
  (1, 'tarjeta', 620.00),
  (2, 'efectivo', 380.00),
  (3, 'transferencia', 398.00);

COMMIT;
