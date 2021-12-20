CREATE TABLE employees(
employeeNumber INT NOT NULL,
lastName NVARCHAR(50) NOT NULL,
firstName NVARCHAR(50) NOT NULL,
extension NCHAR(10) NOT NULL,
email NVARCHAR(100) NOT NULL,
birthdate DATE NOT NULL,
officeCode SMALLINT NOT NULL,
reportsTo INT NULL,
jobTitle NVARCHAR(50) NOT NULL); 

INSERT INTO employees 
(employeeNumber,lastName,firstName,extension,email,birthdate,officeCode,reportsTo,jobTitle)
VALUES 
(1002,'Murphy','Diane','x5800','dmurphy@acp.com','1973-12-20',1,NULL,'President'),
(1003,'Patel','Bharatt','x5812','bpatel@acp.com','1966-07-30',1,1002,'Vice President')
; 

SELECT * FROM employees;  