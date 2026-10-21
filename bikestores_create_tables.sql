-- Table creation for Bike Store analysis
-- Data is from -> https://www.kaggle.com/datasets/dillonmyrick/bike-store-sample-database
-- qemharitsk.id

-- 1. Create tables (primary keys only)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS order_items, orders, stocks, staffs, stores,
                     customers, products, categories, brands CASCADE;

CREATE TABLE brands (
  brand_id    INT PRIMARY KEY,
  brand_name  VARCHAR(255) NOT NULL
);

CREATE TABLE categories (
  category_id    INT PRIMARY KEY,
  category_name  VARCHAR(255) NOT NULL
);

CREATE TABLE products (
  product_id    INT PRIMARY KEY,
  product_name  VARCHAR(255) NOT NULL,
  brand_id      INT NOT NULL,
  category_id   INT NOT NULL,
  model_year    SMALLINT NOT NULL,
  list_price    NUMERIC(10, 2) NOT NULL
);

CREATE TABLE customers (
  customer_id  INT PRIMARY KEY,
  first_name   VARCHAR(255) NOT NULL,
  last_name    VARCHAR(255) NOT NULL,
  phone        VARCHAR(25),
  email        VARCHAR(255) NOT NULL,
  street       VARCHAR(255),
  city         VARCHAR(50),
  state        VARCHAR(25),
  zip_code     VARCHAR(5)
);

CREATE TABLE stores (
  store_id    INT PRIMARY KEY,
  store_name  VARCHAR(255) NOT NULL,
  phone       VARCHAR(25),
  email       VARCHAR(255),
  street      VARCHAR(255),
  city        VARCHAR(255),
  state       VARCHAR(10),
  zip_code    VARCHAR(5)
);

CREATE TABLE staffs (
  staff_id    INT PRIMARY KEY,
  first_name  VARCHAR(50) NOT NULL,
  last_name   VARCHAR(50) NOT NULL,
  email       VARCHAR(255) NOT NULL,
  phone       VARCHAR(25),
  active      SMALLINT NOT NULL,
  store_id    INT NOT NULL,
  manager_id  INT
);

CREATE TABLE orders (
  order_id       INT PRIMARY KEY,
  customer_id    INT,
  order_status   SMALLINT NOT NULL,  -- 1 Pending, 2 Processing, 3 Rejected, 4 Completed
  order_date     DATE NOT NULL,
  required_date  DATE NOT NULL,
  shipped_date   DATE,
  store_id       INT NOT NULL,
  staff_id       INT NOT NULL
);

CREATE TABLE order_items (
  order_id    INT,
  item_id     INT,
  product_id  INT NOT NULL,
  quantity    INT NOT NULL,
  list_price  NUMERIC(10, 2) NOT NULL,
  discount    NUMERIC(4, 2) NOT NULL DEFAULT 0,
  PRIMARY KEY (order_id, item_id)
);

CREATE TABLE stocks (
  store_id    INT,
  product_id  INT,
  quantity    INT,
  PRIMARY KEY (store_id, product_id)
);


-- 2. Check the row counts after import
-- ---------------------------------------------------------------------
SELECT 'brands' AS table_name, COUNT(*) AS row_count FROM brands
UNION ALL SELECT 'categories',  COUNT(*) FROM categories
UNION ALL SELECT 'products',    COUNT(*) FROM products
UNION ALL SELECT 'customers',   COUNT(*) FROM customers
UNION ALL SELECT 'stores',      COUNT(*) FROM stores
UNION ALL SELECT 'staffs',      COUNT(*) FROM staffs
UNION ALL SELECT 'orders',      COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'stocks',      COUNT(*) FROM stocks;



-- 3. Add foreign keys after the import succeeds
-- ---------------------------------------------------------------------
ALTER TABLE products    ADD FOREIGN KEY (brand_id)    REFERENCES brands (brand_id);
ALTER TABLE products    ADD FOREIGN KEY (category_id) REFERENCES categories (category_id);
ALTER TABLE staffs      ADD FOREIGN KEY (store_id)    REFERENCES stores (store_id);
ALTER TABLE staffs      ADD FOREIGN KEY (manager_id)  REFERENCES staffs (staff_id);
ALTER TABLE orders      ADD FOREIGN KEY (customer_id) REFERENCES customers (customer_id);
ALTER TABLE orders      ADD FOREIGN KEY (store_id)    REFERENCES stores (store_id);
ALTER TABLE orders      ADD FOREIGN KEY (staff_id)    REFERENCES staffs (staff_id);
ALTER TABLE order_items ADD FOREIGN KEY (order_id)    REFERENCES orders (order_id);
ALTER TABLE order_items ADD FOREIGN KEY (product_id)  REFERENCES products (product_id);
ALTER TABLE stocks      ADD FOREIGN KEY (store_id)    REFERENCES stores (store_id);
ALTER TABLE stocks      ADD FOREIGN KEY (product_id)  REFERENCES products (product_id);
