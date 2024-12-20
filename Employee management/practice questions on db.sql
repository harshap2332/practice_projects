use EMS

-- 1. Question: Retrieve the first and last names of all employees.
SELECT FirstName, LastName 
FROM Employee ;

-- 2. Retrieve the first and last names of employees who work as 'Software Engineer'.
select firstname,lastname from employee	
where jobtitleid = (select jobtitleid from jobtitle
where jobtitlename = 'Software Engineer');

-- 3. Question: Retrieve first names and last names of last 7 hires
select top 7 * from employee
order by hiredate desc;

-- 4. Question: Get the count of employees in each job title.
select jobtitlename, COUNT(employeeid) e_count
from employee e
inner join jobtitle j
on e.jobtitleid = j.jobtitleid
group by jobtitlename;

-- 5. Question: Retrieve the full name & other personal info of employees who work in the 'Engineering' department.
select CONCAT(firstname,' ',lastname) as fullname, dob,gender,phonenumber
from employee e
inner join department d
on e.deptId=d.deptID
where deptname = 'Engineering';

-- 6. Question: List job titles that have more than 3 employees.
select jobtitlename, COUNT(employeeid) e_count
from employee e
inner join jobtitle j
on e.jobtitleid = j.jobtitleid
group by jobtitlename
having COUNT(employeeid) >3;

-- 7. Question: Retrieve all employee names along with their department names.
select employeeid ,concat(firstname,' ',lastname),deptname
from employee e
inner join department d
on e.deptId=d.deptID;

-- 8. Question: Retrieve the first names of employees and the projects they are working on, along with their role in the project.
select firstname,projectname,jobtitlename as 'role'
from employee e
inner join projectallocation pa
on e.employeeid=pa.employeeid 
inner join project p
on pa.projectid=p.projectid
inner join jobtitle j
on e.jobtitleid=j.jobtitleid
order by projectname;

-- 9. Question: Get the count of employees in each department
select COUNT(employeeid) as 'no.of E',deptname
from employee e
inner join department d
on e.deptId=d.deptID
group by deptname

-- 10. Question: List all departments with more than 5 employees.
select COUNT(employeeid) as 'no.of E',deptname
from employee e
inner join department d
on e.deptId=d.deptID
group by deptname
having COUNT(employeeid) > 5

-- 11. Question: Retrieve the full names of employees and their managers.
--selfjoin
select CONCAT(e.firstname,' ',e.lastname) as 'emp name',CONCAT(m.firstname,' ',m.lastname) as 'mang name'
from employee e
inner join employee m
on e.employeeid=m.managerid

-- 12. Question: Which manager is managing more employees and how many
SELECT top 1 CONCAT(M.firstname,' ',M.lastname) as 'emp name',COUNT(E.employeeid) as 'no of emp'
from employee E
inner join EMPLOYEE M
on E.managerid=M.employeeid
group by M.firstname,M.lastname,M.employeeid
order by 2 DESC;

-- 13. Question: Retrieve names of employees working on projects as 'Software Engineer', ordered by project start date
select firstname,lastname,jobtitlename,projectname,startdate
from employee e
inner join projectallocation pa
on pa.employeeid=e.employeeid
inner join project p
on p.projectid=pa.projectid
inner join jobtitle j
on e.jobtitleid=j.jobtitleid
where jobtitlename = 'Software Engineer'
order by 5;

-- 14. Question: Retrieve the names of employees who are working on 'Project Delta'.
select firstname,lastname,projectname
from employee e
inner join projectallocation pa
on pa.employeeid=e.employeeid
inner join project p
on p.projectid=pa.projectid
where projectname='Project Delta';

---OR nested query

select firstname,lastname from employee
where employeeid in (select employeeid from projectallocation
where projectid =(select projectid from project
where projectname='Project Delta'))


-- 15. Question: Retrieve the names of employees, department name, and total salary, ordered by total salary in descending order

select firstname,lastname,deptname,(basesalary+bonus-deduction) as total_salary
from employee e
inner join department d
on d.deptID=e.deptId
inner join salary s
on s.employeeid=e.employeeid
order by total_salary desc;


-- 16. Question: Create a function to find employees with a birthday in the given month and calculate their age

create function fn_getbday(@month int)
returns table
as return(
select firstname,lastname,dob,
YEAR(getdate())- YEAR(dob)age
from employee
where MONTH(dob)=@month
);

---november
select * from dbo.fn_getbday(11);

---march
select * from dbo.fn_getbday(3);

---
go
create function fn_getyos(@dn varchar(100))
returns table
as return(
select e.firstname,e.lastname,YEAR(getdate())-YEAR(e.hiredate) as year_of_service,d.deptname
from employee e
inner join department d
on d.deptID=e.deptId
where deptname like (@dn)
);
go


--engineerig
select *from dbo.fn_getyos('engineering')


-- Question: Create a function to find employees in a specified department and calculate their years of service
    -- Find employees in the IT department and their years of service
    -- Find employees in the HR department and their years of service

go
create function fn_getyoe(@jn varchar(100))
returns table
as return(
select e.firstname,e.lastname,jobtitlename,deptname,YEAR(getdate())-YEAR(e.hiredate) as year_of_service
from employee e
inner join jobtitle j
on j.jobtitleid=e.jobtitleid
inner join department d
on d.deptID=e.deptId
where jobtitlename like (@jn)
);
go

select*from jobtitle
select*from department
drop function fn_getyoe

---HR
 select *from dbo.fn_getyoe('%hr%')