CREATE TABLE raw_data(
    InvoiceNo     VARCHAR2(50),
    StockCode     VARCHAR2(50),
    Description   VARCHAR2(200),
    Quantity      NUMBER,
    InvoiceDate   DATE,
    Price         NUMBER(10,2),
    CustomerID    NUMBER,
    Country       VARCHAR2(50)
);


---Czyszczenie

DELETE FROM raw_data
WHERE CustomerID IS NULL
   OR Price IS NULL
   OR Quantity IS NULL
   OR InvoiceDate IS NULL;

DELETE FROM raw_data
WHERE InvoiceNo LIKE 'C%';

DELETE FROM raw_data
WHERE Quantity <= 0;

SELECT COUNT(*) FROM RAW_DATA;


---RESZTA TABEL
CREATE TABLE customers (
    customer_id   NUMBER PRIMARY KEY,
    customer_name VARCHAR2(100),
    country       VARCHAR2(50)
);

-- CATEGORIES
CREATE TABLE categories (
    category_id   NUMBER PRIMARY KEY,
    category_name VARCHAR2(100)
);

-- PRODUCTS
CREATE TABLE products (
    product_id     NUMBER PRIMARY KEY,
    product_name   VARCHAR2(200),
    category_id    NUMBER,
    unit_price     NUMBER(10,2),
    units_in_stock NUMBER,
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
);
CREATE SEQUENCE seq_products START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_products
BEFORE INSERT ON products
FOR EACH ROW
BEGIN
    IF :NEW.product_id IS NULL THEN
        SELECT seq_products.NEXTVAL INTO :NEW.product_id FROM dual;
    END IF;
END;
/

-- ORDERS
CREATE TABLE orders (
    order_id       NUMBER PRIMARY KEY,
    invoice_number VARCHAR2(50),
    order_date     DATE,
    customer_id    NUMBER,
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);

-- ORDER DETAILS
CREATE TABLE order_details (
    order_detail_id NUMBER PRIMARY KEY,
    order_id        NUMBER,
    product_id      NUMBER,
    quantity        NUMBER,
    unit_price      NUMBER(10,2),
    CONSTRAINT fk_od_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_od_product FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE SEQUENCE seq_products START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_orders START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_order_details START WITH 1 INCREMENT BY 1;


-- PRODUCTS
CREATE OR REPLACE TRIGGER trg_products
BEFORE INSERT ON products
FOR EACH ROW
BEGIN
    IF :NEW.product_id IS NULL THEN
        SELECT seq_products.NEXTVAL INTO :NEW.product_id FROM dual;
    END IF;
END;
/

-- ORDERS
CREATE OR REPLACE TRIGGER trg_orders
BEFORE INSERT ON orders
FOR EACH ROW
BEGIN
    IF :NEW.order_id IS NULL THEN
        SELECT seq_orders.NEXTVAL INTO :NEW.order_id FROM dual;
    END IF;
END;
/

-- ORDER DETAILS
CREATE OR REPLACE TRIGGER trg_order_details
BEFORE INSERT ON order_details
FOR EACH ROW
BEGIN
    IF :NEW.order_detail_id IS NULL THEN
        SELECT seq_order_details.NEXTVAL INTO :NEW.order_detail_id FROM dual;
    END IF;
END;
/

INSERT INTO customers (customer_id, customer_name, country)
SELECT
    CustomerID,
    'Customer_' || CustomerID,
    MIN(Country)   -- bierze jeden kraj
FROM raw_data
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID;

INSERT INTO categories (category_id, category_name) VALUES (1, 'Electronics');
INSERT INTO categories (category_id, category_name) VALUES (2, 'Clothing');
INSERT INTO categories (category_id, category_name) VALUES (3, 'Home and Kitchen');
INSERT INTO categories (category_id, category_name) VALUES (4, 'Toys');
INSERT INTO categories (category_id, category_name) VALUES (5, 'Food and Beverages');
INSERT INTO categories (category_id, category_name) VALUES (6, 'Office Supplies');
INSERT INTO categories (category_id, category_name) VALUES (7, 'Health and Beauty');
INSERT INTO categories (category_id, category_name) VALUES (8, 'Sports');

TRUNCATE TABLE products;

INSERT INTO products (product_name, category_id, unit_price, units_in_stock)
SELECT
    Description,
    1,
    AVG(Price),   -- albo MIN / MAX
    0
FROM raw_data
WHERE Description IS NOT NULL
GROUP BY Description;

INSERT INTO orders (invoice_number, order_date, customer_id)
SELECT
    InvoiceNo,
    MIN(InvoiceDate),
    CustomerID
FROM raw_data
WHERE CustomerID IS NOT NULL
GROUP BY InvoiceNo, CustomerID;

INSERT INTO order_details (order_id, product_id, quantity, unit_price)
SELECT
    o.order_id,
    p.product_id,
    SUM(r.Quantity),
    AVG(r.Price)
FROM raw_data r
JOIN orders o ON r.InvoiceNo = o.invoice_number
JOIN products p ON r.Description = p.product_name
GROUP BY
    o.order_id,
    p.product_id;




