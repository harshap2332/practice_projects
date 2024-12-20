--- practice questions

-- 1. Fetch all orders placed by users who joined before March 2024.

select * 
from orders o
inner join users u
on u.userid=o.userid
where joindate < '2024-03-01'

-- 2. List all products under the "Electronics" category with price greater than $100.

select productname,price from products
where category Like 'electronics' and price >100;

-- ## FUNCTIONS ## -- 

-- 1. Scalar function to calculate total revenue from all orders.
/*
create function get_revenue()
returns decimal(10,2)
as
begin
declare @totalrevenue decimal(10,2)
select @totalrevenue =SUM(totalamount) from orders;
return @totalrevenue
end;

select dbo.get_revenue() as totalrevenue */

-- 2. Function to return total products purchased by a specific user.
/*
create function get_orderq(@ord int)
returns int
as
begin
declare @totalproducts int
select @totalproducts = SUM(quantity) 
from ordersdetails od
inner join orders o
on o.orderid=od.orderid
where userid = @ord
return @totalproducts
end;

select dbo.get_orderq(3) as no_of_orders
*/

-- ## TRANSACTION ## --
-- 1. Transaction to place an order ensuring consistency.

begin transaction;

begin try
insert into orders
values(12,3,'2024-12-01',750);

insert into ordersdetails
values(12,14,101,1,700);

update products
set stock = stock-1
where productid = 101;

commit transaction
end try

begin catch
rollback transaction;
throw;
end catch

select * from orders

-- ## STORED PROCEDURE ## --
-- 1. Stored procedure to add a new user and recommend a random product.

go
create procedure addURP
@userid int,
@name nvarchar(100),
@email nvarchar(100),
@joindate date
as
begin

if exists(select 1 from users where userid = @userid)
begin
print('ERROR : user already exists')
return
end;

declare @productid int;
declare @recommendationid int;

select @recommendationid = ISNULL(max(recommendationid),0)+1 from productrecommendation;

insert into users
values(@userid,@name,@email,@joindate);

select top 1 @productid = productid from products order by newid();

insert into productrecommendation
values(@recommendationid,@userid,@productid,GETDATE());

print('user and recommendation added successfully')

end;

-- Adding user with ID 401
EXEC addURP
    @UserID = 401,
    @Name = 'David Clark',
    @Email = 'david.clark@example.com',
    @JoinDate = '2024-12-06';

-- Adding user with ID 1
EXEC addURP
    @UserID = 1,
    @Name = 'Charles Clark',
    @Email = 'charles.clark@example.com',
    @JoinDate = '2024-12-06';

-- Verifying the results
select * from users
select * from productrecommendation

-- ## Analytical Questions ## --

-- 1. Fetch the total revenue grouped by product categories with max to min

select category,SUM(subtotal) as total_revenue
from ordersdetails o
inner join products p
on p.productid=o.productid
group by category
order by 2 desc;

-- 2. Identify the top 2 user Name, ID, total with the highest spending.

select top 2 u.userid,u.name,sum(o.totalamount) as total_amount
from users u
inner join orders o
on o.userid=u.userid
group by u.userid,u.name
order by 3 desc;

-- 3. Suggest products not yet purchased by a specific user.

create function fn_suggest(@userid int)
returns table
as
return(
select productname,productid,category 
from products
where productid not in(
select productid
from orders o
inner join ordersdetails od
on od.orderid=o.orderid
where o.orderid= @userid)
);

select * from dbo.fn_suggest(2)
