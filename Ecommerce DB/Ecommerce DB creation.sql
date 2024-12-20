---orders table

create table orders(
orderid int primary key,
userid int foreign key (userid) references users(userid) ,
orderdate date,
totalamount decimal(10,2)
);


---oder details table
create table ordersdetails(
orderdetailid int primary key,
orderid int foreign key (orderid) references orders(orderid),
productid int foreign key (productid) references products(productid),
quantity int,
subtotal decimal(10,2)
);

---product recommendation table

create table productrecommendation(
recommendationid int primary key,
userid int foreign key (userid) references users(userid),
productid int foreign key (productid) references products(productid),
recommendeddate date
);

---recommendation aduit table
create table recommendationaudit(
auditid int primary key,
userid int foreign key (userid) references users(userid),
productid int foreign key (productid) references products(productid),
recommendeddate date,
auditdate date
);


---inserting data

INSERT INTO Users (UserID, Name, Email, joindate) VALUES
(1, 'Alice', 'alice@example.com', '2024-01-15'),
(2, 'Bob', 'bob@example.com', '2024-03-22'),
(3, 'Charlie', 'charlie@example.com', '2024-05-10'),
(4, 'Diana', 'diana@example.com', '2024-06-01'),
(5, 'Eve', 'eve@example.com', '2024-07-12'),
(6, 'Frank', 'frank@example.com', '2024-08-15'),
(7, 'Grace', 'grace@example.com', '2024-09-10'),
(8, 'Hank', 'hank@example.com', '2024-10-01'),
(9, 'Ivy', 'ivy@example.com', '2024-11-05'),
(10, 'Jack', 'jack@example.com', '2024-12-01');


-- PRODUCTS DATA
INSERT INTO Products (ProductID, ProductName, Category, Price, Stock) VALUES
(101, 'Laptop', 'Electronics', 700.00, 50),
(102, 'Headphones', 'Electronics', 50.00, 200),
(103, 'Coffee Maker', 'Appliances', 80.00, 75),
(104, 'Smartphone', 'Electronics', 500.00, 120),
(105, 'Blender', 'Appliances', 60.00, 90),
(106, 'Tablet', 'Electronics', 300.00, 100),
(107, 'Microwave', 'Appliances', 150.00, 40),
(108, 'Gaming Console', 'Electronics', 400.00, 30),
(109, 'Vacuum Cleaner', 'Appliances', 120.00, 60),
(110, 'Smartwatch', 'Electronics', 200.00, 150);

-- ORDERS DATA
INSERT INTO orders(OrderID, UserID, Orderdate, TotalAmount) VALUES
(1, 1, '2024-06-10', 750.00),
(2, 2, '2024-07-05', 80.00),
(3, 3, '2024-07-15', 900.00),
(4, 4, '2024-08-01', 120.00),
(5, 5, '2024-08-20', 650.00),
(6, 6, '2024-09-05', 400.00),
(7, 7, '2024-09-25', 150.00),
(8, 8, '2024-10-10', 1000.00),
(9, 9, '2024-10-25', 200.00),
(10, 10, '2024-11-10', 750.00);

-- ORDER DETAILS DATA
INSERT INTO ordersdetails(OrderDetailID, OrderID, ProductID, Quantity, Subtotal) VALUES
(1, 1, 101, 1, 700.00),
(2, 1, 102, 1, 50.00),
(3, 2, 103, 1, 80.00),
(4, 3, 104, 1, 500.00),
(5, 3, 106, 2, 400.00),
(6, 4, 105, 2, 120.00),
(7, 5, 108, 1, 400.00),
(8, 5, 109, 2, 240.00),
(9, 6, 102, 8, 400.00),
(10, 7, 110, 1, 150.00);

-- PRODUCT RECOMMENDATION DATA
INSERT INTO productrecommendation(RecommendationID, UserID, ProductID, RecommendedDate) VALUES
(1, 1, 103, '2024-06-12'),
(2, 1, 104, '2024-06-15'),
(3, 2, 105, '2024-07-07'),
(4, 2, 106, '2024-07-09'),
(5, 3, 107, '2024-07-17'),
(6, 4, 108, '2024-08-05'),
(7, 5, 109, '2024-08-22'),
(8, 6, 110, '2024-09-07'),
(9, 7, 101, '2024-09-27'),
(10, 8, 102, '2024-10-12');

select * from orders
select * from ordersdetails
select * from productrecommendation
select * from products
select * from recommendationaudit
select * from users
