--Creating New DataBase---

CREATE DATABASE ORMS_Group19;

USE ORMS_Group19;

----Creating New Tables-----

CREATE TABLE USERTYPES(UserTypeID varchar(50) Primary Key NOT NULL, UserTypeName varchar(50))

CREATE TABLE USERS(UserID varchar(50) Primary Key NOT NULL, UserName varchar(50) NOT NULL, Password varbinary(350) NOT NULL, Emailid varchar(50) NOT NULL, UserTypeID varchar(50) NOT NULL, FOREIGN KEY (UserTypeID) REFERENCES USERTYPES(UserTypeID), CreatedDate DATETIME)
  
CREATE TABLE CUSTOMER(CustomerID varchar(50) Primary Key NOT NULL, FirstName varchar(50) NOT NULL, LastName varchar(50) NOT NULL, UserID varchar(50) NOT NULL, PhoneNumber BIGINT NOT NULL, FOREIGN KEY (UserID) REFERENCES USERS(UserID), ModifiedDate DATETIME)

CREATE TABLE CUSTOMERADDRESS(AddressID varchar(50) Primary Key NOT NULL, CustomerID varchar(50) NOT NULL, CONSTRAINT FK_CUSTOMERADDRESS_CUSTOMER FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID), FlatNo varchar(60) NOT NULL, Street varchar(60) NOT NULL, City varchar(60) NOT NULL, State varchar(60) NOT NULL, Country varchar(60) NOT NULL, Zipcode DECIMAL(10,0) NOT NULL)

CREATE TABLE EMPLOYEE(EmployeeID varchar(50) Primary Key NOT NULL, EmployeeFirstName varchar(50) NOT NULL, EmployeeLastName varchar(50) NOT NULL, EmployeeTypeID varchar(50) NOT NULL, FOREIGN KEY (EmployeeTypeID) REFERENCES EMPLOYEETYPE(EmployeeTypeID))

CREATE TABLE EMPLOYEETYPE(EmployeeTypeID varchar(50) Primary Key NOT NULL, EmployeeTypeName varchar(60) NOT NULL, Description varchar(60) NOT NULL, EmployeeAccessRights varbinary(350) NOT NULL)

CREATE TABLE BRAND(BrandID varchar(50) Primary Key NOT NULL, BrandName varchar(60) NOT NULL, BrandRating FLOAT NOT NULL, BrandSales DECIMAL(15,2) NOT NULL)

CREATE TABLE INVENTORY(InventoryID varchar(50) Primary Key NOT NULL, ProductID varchar(50) NOT NULL, SupplierID varchar(50) NOT NULL, CONSTRAINT FK_INVENTORY_PRODUCT FOREIGN KEY (ProductID) REFERENCES PRODUCT(ProductID), CONSTRAINT FK_INVENTORY_SUPPLIER FOREIGN KEY (SupplierID) REFERENCES SUPPLIER(SupplierID), ProductQuantity varchar(50) NOT NULL, ProductAvailability varchar(60) NOT NULL, ProductBatchCode varchar(60) NOT NULL, ProductArrivalDate DATETIME NOT NULL, ProductDepartureDate DATETIME NOT NULL)

CREATE TABLE PAYMENT(PaymentID varchar(50) Primary Key NOT NULL, CustomerID varchar(50) NOT NULL, CONSTRAINT FK_PAYMENT_CUSTOMER FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID),ModeOfPayment varbinary(350), Amount BIGINT, PaymentDate DATETIME)

CREATE TABLE CARTITEMS(CustomerID varchar(50) NOT NULL, SiteID varchar(50) NOT NULL, ProductValue varchar(50) NOT NULL, ProductName varchar(60) NOT NULL, FOREIGN KEY (SiteID) REFERENCES SHOPPINGSITE(SiteID), CONSTRAINT FK_CARTITEMS_CUSTOMER FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID), BeginDate DATETIME)

CREATE TABLE SUPPLIER(SupplierID varchar(50) Primary Key NOT NULL, SupplierName varchar(60) NOT NULL, SupplierQuantity BIGINT NOT NULL, SupplierDispatchDate DATETIME NOT NULL, SupplierDispatchValue BIGINT NOT NULL, SupplierAddressID varchar(50) NOT NULL, FOREIGN KEY (SupplierAddressID) REFERENCES SUPPLIERADDRESS(SupplierAddressID))

CREATE TABLE SUPPLIERADDRESS(SupplierAddressID varchar(50) Primary Key NOT NULL, SupplierCity varchar(60), SupplierState varchar(60) NOT NULL, SupplierCountry varchar(60) NOT NULL, SupplierZipcode DECIMAL(10,0) NOT NULL)

CREATE TABLE SHOPPINGSITE(SiteID varchar(50) Primary Key NOT NULL, CustomerID varchar(50) NOT NULL, FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID), SiteName varchar(60) NOT NULL, StartTime TIME NOT NULL, EndTime TIME NOT NULL)

CREATE TABLE INVOICE(InvoiceID varchar(50) Primary Key NOT NULL, OrderID varchar(50) NOT NULL,FOREIGN KEY (OrderID) REFERENCES ORDERS(OrderID)) 

CREATE TABLE ORDERS(OrderID varchar(50) Primary Key NOT NULL,OrderRefNo varchar(50) NOT NULL, OrderValue DECIMAL(7,2) NOT NULL, CustomerID varchar(50) NOT NULL, OrderDate DATETIME NOT NULL, FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID))

CREATE TABLE PRODUCT(ProductID varchar(50) Primary Key NOT NULL, BrandID varchar(50) NOT NULL, FOREIGN KEY (BrandID) REFERENCES BRAND(BrandID), ProductName varchar(60) NOT NULL, ProductType varchar(60) NOT NULL, ActualProductPrice DECIMAL(15,2) NOT NULL, DiscountPrice DECIMAL(15,2) NOT NULL, ProductColor varchar(10) NOT NULL, ProductQuantity INT NOT NULL, SerialNumber varchar(50) NOT NULL)

CREATE TABLE ORDERDETAILS(ProductID varchar(50) not null REFERENCES PRODUCT(ProductID), OrderID varchar(50) not null REFERENCES ORDERS(OrderID)constraint PK_Product_Order primary key clustered (ProductID, OrderID))

CREATE TABLE CARDDETAILS(CardID INT,CustomerID varchar(50), CardType varchar(50), DateOfExpiry DATE, CardNumber varbinary(500), FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID))

 ALTER TABLE Orders
ADD CONSTRAINT FK_OrderPaymentID
FOREIGN KEY (PaymentID) REFERENCES PAYMENT(PaymentID);


 /*ALTER TABLE Invoice
ADD CONSTRAINT FK_InvoiceOrderID
FOREIGN KEY (OrderID) REFERENCES ORDERS(OrderID);*/


---TRIGGERS CREATED----

---TRIGGER FOR UPDATING ORDER TABLE---

Create TRIGGER UpdateOrderTable
ON dbo.ORDERDETAILS
After Insert, Update, Delete 
AS
BEGIN 
	SET NOCOUNT ON;
	DECLARE @OrderID VARCHAR(10)
	IF EXISTS(SELECT * FROM inserted)
		IF EXISTS(SELECT * FROM deleted)
			SELECT @OrderID = i.OrderID FROM Inserted i
		ELSE
			SELECT @OrderID = i.OrderID FROM Inserted i	
	ELSE
		IF EXISTS(SELECT * FROM deleted)
			SELECT @OrderID = d.OrderID FROM Deleted d

	UPDATE dbo.Orders 
	SET OrderValue = (select SUM(dbo.Total_Income(ActualProductPrice, DiscountPrice)) From PRODUCT p
					 INNER JOIN ORDERDETAILS o
					 ON p.ProductID = o.ProductID
					 WHERE o.OrderID = @OrderID
					 Group by OrderID)

END

---TRIGGER FOR CHANGING ADDRESS---

CREATE TRIGGER AddressChange
ON dbo.CUSTOMERADDRESS
AFTER UPDATE,INSERT
AS
BEGIN
	SET NOCOUNT ON;
	UPDATE dbo.CUSTOMER
	SET ModifiedDate = GETDATE()
	From 
		dbo.CUSTOMER
		Where CustomerID IN (SELECT CustomerID FROM inserted UNION ALL SELECT CustomerID FROM deleted)
END

---TRIGGER FOR UPDATING DATE IN PAYMENT TABLE---

Create TRIGGER UpdatePaymentDate
ON dbo.PAYMENT
After insert,Update
AS
BEGIN 
	SET NOCOUNT ON;
	DECLARE @PaymentID VARCHAR(10)
	DECLARE @PaymentStatus  VARCHAR(10)
	IF EXISTS(SELECT * FROM inserted)
			SELECT @PaymentID = i.PaymentID FROM Inserted i;
			SELECT @PaymentStatus = i.PaymentStatus FROM Inserted i;
	IF( @PaymentStatus = 'YES')
		UPDATE dbo.PAYMENT 
		set PaymentDate = GETUTCDATE()
		Where PaymentID =  @PaymentID

END

---TRIGGER FOR RAISING ERROR IN PAYMENT TABLE---

Create TRIGGER RollBackPayment
ON dbo.PAYMENT
After Insert
AS
BEGIN 
	SET NOCOUNT ON;
	DECLARE @PaymentID VARCHAR(10)
	DECLARE @PaymentStatus  VARCHAR(10)
	IF EXISTS(SELECT * FROM inserted)
			SELECT @PaymentStatus = i.PaymentStatus FROM Inserted i;
	IF( @PaymentStatus = 'Failed')
	RAISERROR ('Payment Process Failed', 16, 1);	
	ROLLBACK TRANSACTION;

END

---INSERTION OF THE DATA INTO TABLES----

INSERT INTO dbo.USERTYPES(UserTypeID, UserTypeName)
VALUES('USRT9001','USER'),('CUSTT9002','CUSTOMER'),('EMPT9003','EMPLOYEE'),('VENDT9004','VENDOR'),('SUPPT9005','SUPPLIER')

INSERT INTO USERS(UserID, UserName, Password,Emailid,UserTypeID, CreatedDate)
VALUES('UR7001','John.Hopkins',ENCRYPTBYKEY(KEY_GUID(N'ORMSSymmetricKey'), CONVERT(varbinary,'PassT51')),'john.hopkins63@gmail.com','CUST9002','2020/10/10'),
	('UR7002','Tim.Scott',ENCRYPTBYKEY(KEY_GUID(N'ORMSSymmetricKey'), CONVERT(varbinary,'PassT52')),'tim.scott84@gmail.com','CUST9002','2020/03/30'),
	('UR7003','Kevin.Stuart',ENCRYPTBYKEY(KEY_GUID(N'ORMSSymmetricKey'), CONVERT(varbinary,'PassT53')),'kevin.stuart91@gmail.com','CUST9002','2020/12/05'),
	('UR7004','Rahul.Mehrotra',ENCRYPTBYKEY(KEY_GUID(N'ORMSSymmetricKey'), CONVERT(varbinary,'PassT54')),'rahul2.meh1@gmail.com','CUST9002','2020/07/24'),
	('UR7005','Nikhil.Joshi',ENCRYPTBYKEY(KEY_GUID(N'ORMSSymmetricKey'), CONVERT(varbinary,'PassT55')),'nik.josh@gmail.com','CUST9002','2020/01/24'),
	('UR7006','Ren.Xiu',ENCRYPTBYKEY(KEY_GUID(N'ORMSSymmetricKey'), CONVERT(varbinary,'PassT56')),'ren.xiu66@gmail.com','CUST9002','2020/01/16'),
	('UR7007','John.Scott',ENCRYPTBYKEY(KEY_GUID(N'ORMSSymmetricKey'), CONVERT(varbinary,'PassT57')),'j.scott7@gmail.com','CUST9002','2020/03/31'),
	('UR7008','Shawn.Luis',ENCRYPTBYKEY(KEY_GUID(N'ORMSSymmetricKey'), CONVERT(varbinary,'PassT58')),'shawn.liu56@gmail.com','CUST9002','2020/02/14'),
	('UR7009','Swati.Pandey',ENCRYPTBYKEY(KEY_GUID(N'ORMSSymmetricKey'), CONVERT(varbinary,'PassT59')),'pandey.s94@gmail.com','CUST9002','2020/04/20'),
	('UR7010','Dan.Patel',ENCRYPTBYKEY(KEY_GUID(N'ORMSSymmetricKey'), CONVERT(varbinary,'PassT60')),'dan.p@gmail.com','CUST9002','2020/04/20'),
	('UR7011','Utkarsh.Kakkar',ENCRYPTBYKEY(KEY_GUID(N'ORMSSymmetricKey'), CONVERT(varbinary,'PassT61')),'kakkar.u@gmail.com','VENDT9004','2020/04/01'),
	('UR7012','Rusell.King',ENCRYPTBYKEY(KEY_GUID(N'ORMSSymmetricKey'), CONVERT(varbinary,'PassT62')),'king.rus@gmail.com','VENDT9004','2020/04/01'),
	('UR7013','Krishna.Singh',ENCRYPTBYKEY(KEY_GUID(N'ORMSSymmetricKey'), CONVERT(varbinary,'PassT63')),'k.singh@gmail.com','VENDT9004','2020/04/01'),
	('UR7014','Tej.Francis',ENCRYPTBYKEY(KEY_GUID(N'ORMSSymmetricKey'), CONVERT(varbinary,'PassT64')),'francis.t@gmail.com','SUPPT9005','2020/04/01'),
	('UR7015','Jesse.Parker',ENCRYPTBYKEY(KEY_GUID(N'ORMSSymmetricKey'), CONVERT(varbinary,'PassT65')),'jes.park90@gmail.com','EMPT9003','2020/04/01'),
	('UR7016','Je.Par',ENCRYPTBYKEY(KEY_GUID(N'ORMSSymmetricKey'), CONVERT(varbinary,'PassT66')),'jes.pa@gmail.com','EMPT9003','2020/04/01')
     
	 
Select UserID, DECRYPTBYKEY(Password) from dbo.USERS

  INSERT INTO CUSTOMER(CustomerID, FirstName, LastName, UserID, PhoneNumber, ModifiedDate)
VALUES('CUST5002', 'Tim', 'Scott', 'UR7002', '5175408623', '2020-05-16'),
		('CUST5003', 'Kevin', 'Stuart', 'UR7003', '5175408624', '2020-05-20'),
		('CUST5004', 'Rahul', 'Mehrotra', 'UR7004', '5175408626', '2020-05-24'),
		('CUST5005', 'Nikhil', 'Joshi', 'UR7005', '5175408636', '2020-05-30'),
		('CUST5006', 'Ren', 'Xiu', 'UR7006', '8575408623', '2020-05-16'),
		('CUST5007', 'John', 'Scott', 'UR7007', '5175408632', '2020-05-04'),
		('CUST5008', 'Shawn', 'Luis', 'UR7008', '5175406823', '2020-02-27'),
		('CUST5009', 'Swati', 'Pandey', 'UR7009', '8575508632', '2020-01-02'),
		('CUST5010', 'Dan', 'Patel', 'UR7010', '5175408638', '2020-03-20')

 INSERT INTO CUSTOMERADDRESS(AddressID, CustomerID, FlatNo, Street, City, State, Country,ZipCode)
VALUES('ADDR2003','CUST5001','63','Horodan Street','Boston','MA','USA','02120'),
	  ('ADDR2004','CUST5002','69','Bay Street','San Jose','CA','USA','95008'),
	  ('ADDR2005','CUST5003','501','Grant Road','Mumbai','MH','India','400069'),
	  ('ADDR2006','CUST5003','303','Richardson Road','Bangalore','India','KA','560066'),
	  ('ADDR2007','CUST5004','14C','Smith Street','Boston','MA','USA','02120'),
	  ('ADDR2008','CUST5005','238','Elvis Street','Hoboken','NY','USA','07086'),
	  ('ADDR2009','CUST5006','56','Deli Street','Richardson','TX','USA','75082'),
	  ('ADDR2010','CUST5006','87','China Town','Richardson','TX','USA','75080'),
	  ('ADDR2011','CUST5007','1C','Smith Street','Boston','MA','USA','02120'),
	  ('ADDR2012','CUST5008','12M','Dragon Street','Beijing','BG','China','100015'),
	  ('ADDR2013','CUST5009','102','Sai Street','Bangalore','KA','India','560067'),
	  ('ADDR2014','CUST5009','89C','Markson Street','Delhi','Delhi','India','110029'),
	  ('ADDR2015','CUST5010','1108','9thA Avenue','NY','NY','USA','10012')

INSERT INTO dbo.EMPLOYEE(EmployeeID, EmployeeFirstName, EmployeeLastName, EmployeeTypeID)
VALUES('EMP9001','Jesse','Parker', 'ADMIN3001'),('EMP9002','Je','Par','TECH3002'),
('EMP9003','Zheng','Wang','ACCT3003'),('EMP9004','Handen','Liu','MANAG3004'),('EMP9005','Simran','Kaur','TEAMLEAD3005'),('EMP9006','Pravin','Reddy','DEVOPS3006'),('EMP9007','Seema','Sukand','JAVADEV3007'),('EMP9008','Gagan','Pasar','SYSENGI3008')


OPEN SYMMETRIC KEY ORMSSymmetricKey
DECRYPTION BY CERTIFICATE ORMSCertificate
	INSERT INTO EMPLOYEETYPE(EmployeeTypeID, EmployeeTypeName, Description, EmployeeAccessRights)
VALUES
('TECH3002','TECHNICAL SUPPORT','Responsible for Maintaining Servers',ENCRYPTBYKEY(KEY_GUID('ORMSSymmetricKey'),'WRITE ACCESS')),
('ACCT3003','ACCOUNTANT','Controls Finance of Company',ENCRYPTBYKEY(KEY_GUID('ORMSSymmetricKey'),'READ ACCESS')),
('MANAG3004','PROJECT MANAGER','Look After Technical Projects',ENCRYPTBYKEY(KEY_GUID('ORMSSymmetricKey'),'NO ACCESS')),
('TEAMLEAD3005','TEAM LEADER','Manages Different Project Teams',ENCRYPTBYKEY(KEY_GUID('ORMSSymmetricKey'),'READ ACCESS')),
('DEVOPS3006','DEVOPS GROUP','Deploys and Develops Code',ENCRYPTBYKEY(KEY_GUID('ORMSSymmetricKey'),'WRITE ACCESS')),
('JAVADEV3007','JAVA DEVELOPER','Implements New Functionalities',ENCRYPTBYKEY(KEY_GUID('ORMSSymmetricKey'),'WRITE ACCESS')),
('SYSENGI3008','SYSTEM ENGINEER','Updates and Maintians system requirements',ENCRYPTBYKEY(KEY_GUID('ORMSSymmetricKey'),'NO ACCESS'))

insert dbo.CARTITEMS values
	('CUST5001','ST101','Appliances','07-23-2020'),
	('CUST5001','ST102','Appliances','07-23-2020'),
	('CUST5002','ST103','Appliances','07-23-2020'),
	('CUST5003','ST104','Appliances','07-23-2020'),
	('CUST5004','ST105','Appliances','07-23-2020'),
	('CUST5005','ST106','Appliances','07-23-2020'),
	('CUST5006','ST107','Appliances','07-23-2020'),
	('CUST5002','ST108','Appliances','07-23-2020'),
	('CUST5008','ST109','Appliances','07-23-2020'),
	('CUST5003','ST110','Appliances','07-23-2020'),
	('CUST5009','ST111','Appliances','07-23-2020');

INSERT INTO SUPPLIERADDRESS(SupplierAddressID, SupplierCity, SupplierState, SupplierCountry, SupplierZipcode)
VALUES('SUPPADDR12001','Boston','MA','USA',02120),('SUPPADDR12002','Huntsville','AL','USA',35801),('SUPPADDR12003','Denver','CO','USA',80239),('SUPPADDR12004','Hartford','CT','USA',06101),('SUPPADDR12005','Dover','DE','USA',19905),('SUPPADDR12006','Atlanta','GA','USA',30381),('SUPPADDR12007','Chicago','IL','USA',60601),('SUPPADDR12008','Indianapolis','IN','USA',46201),('SUPPADDR12009','Davenport','IA','USA',52809),('SUPPADDR12010','Wichita','KS','USA',67201),('SUPPADDR12011','Miami','FL','USA',33124),('SUPPADDR12012','Laurel','MT','USA',59044)

INSERT INTO SUPPLIER(SupplierID, SupplierName, SupplierQuantity, SupplierDispatchDate, SupplierDispatchValue, SupplierAddressID)
VALUES('SUPP11001','Ranganathan Plywood',6781,'2005-07-12',90000000,'SUPPADDR12001'),('SUPP11002','PeriPeri Macrons',5674,'2005-10-10',80000000,'SUPPADDR12002'),('SUPP11003','Iyenger Bakery',7865,'2005-03-09',70000000,'SUPPADDR12003'),('SUPP11004','LAKME Beauty Products',4563,'2006-04-09',60000000,'SUPPADDR12004'),('SUPP11005','APPLE Appliances',1234,'2006-07-12',50000000,'SUPPADDR12005'),('SUPP11006','Corona Liquors',7345,'2008-08-08',500000000,'SUPPADDR12006'),('SUPP11007','Dolshe Gabana Shirts',3098,'2007-05-04',400000000,'SUPPADDR12007'),
('SUPP11008','Silk Saries',3490,'2004-09-08',2000000000,'SUPPADDR12008'),('SUPP11009','Vadilal Icecream',8954,'2009-02-10',3000000000,'SUPPADDR12009'),('SUPP11010','AMUL Butter Products',4325,'2010-07-04',1000000000,'SUPPADDR12010')


OPEN SYMMETRIC KEY ORMSSymmetricKey
DECRYPTION BY CERTIFICATE ORMSCertificate
 SELECT * ,CONVERT(varchar, DECRYPTBYKEY(EmployeeAccessRights)) AS DecryptedAccessRights From dbo.EMPLOYEETYPE
CLOSE SYMMETRIC KEY ORMSSymmetricKey


INSERT INTO dbo.PRODUCT(ProductID, BrandID, ProductName, ProductType, ActualProductPrice, DiscountPrice, ProductColor, ProductQuantity, SerialNumber)
VALUES('PR115','BR112','Wooden Table','Plywood',999.99, 79.99, 'Green', 35, 'CT10015'),
('PR116','BR113','Spoons','Kitchen',8800, 100, 'Yellow', 55, 'CT10016'),
('PR117','BR114','Juicer','Appliances',2598, 198, 'Blue', 87, 'CT10017'),
('PR118','BR115','Wooden Chair','Plywood',2450, 25, 'Black', 98, 'CT10018'),
('PR119','BR116','Closet','Furniture',3678, 45, 'Orange', 100, 'CT10019'),
('PR120','BR117','Nike Jeans','Clothing',4532, 178, 'Violet', 43, 'CT10020'),
('PR121','BR118','Roti Maker','Kitchen',98760, 890, 'Yellow', 15, 'CT10021'),
('PR122','BR119','Wooden Drawers','Household',50000, 102, 'Blue', 56, 'CT10022'),
('PR123','BR120','Meat Grinder','Appliances',23446, 908, 'Black', 102, 'CT10023')


INSERT dbo.BRAND(BrandID, BrandName, BrandRating, BrandSales)
 VALUES('BR101','Clothing','5','2000'),
	('BR102','Furniture','3','244'),
	('BR103','Appliances','4.5','4566'),
	('BR104','Kitchen','5','200'),
	('BR105','Household','3.5','2209'),
	('BR106','Clothing','4.5','3600'),
	('BR107','Appliances','4','4800'),
	('BR108','Clothing','5','200'),
	('BR109','Kitchen','3','3400'),
	('BR110','Household','5','900'),
	('BR111','Furniture','4','700');


OPEN SYMMETRIC KEY ORMSSymmetricKey
DECRYPTION BY CERTIFICATE ORMSCertificate
INSERT INTO CARDDETAILS(CardID ,CustomerID, CardType, DateOfExpiry, CardNumber)
VALUES(1,'CUST5001','Credit Card','2020-09-07',ENCRYPTBYKEY(KEY_GUID('ORMSSymmetricKey'),'45678790123445678')),
(2,'CUST5002','Credit Card','2019-09-07',ENCRYPTBYKEY(KEY_GUID('ORMSSymmetricKey'),'5678123489081234')),
(3,'CUST5003','Debit Card','2020-09-10',ENCRYPTBYKEY(KEY_GUID('ORMSSymmetricKey'),'5789123409876547')),
(4,'CUST5004','Debit Card','2020-12-10',ENCRYPTBYKEY(KEY_GUID('ORMSSymmetricKey'),'4523109876543123')),
(5,'CUST5005','Debit Card','2012-07-17',ENCRYPTBYKEY(KEY_GUID('ORMSSymmetricKey'),'597653210986754')),
(6,'CUST5006','Credit Card','2017-12-17',ENCRYPTBYKEY(KEY_GUID('ORMSSymmetricKey'),'5098123456778990')),
(7,'CUST5007','Credit Card','2018-09-10',ENCRYPTBYKEY(KEY_GUID('ORMSSymmetricKey'),'4098128909093456')),
(8,'CUST5008','Debit Card','2022-09-10',ENCRYPTBYKEY(KEY_GUID('ORMSSymmetricKey'),'4231456789071234')),
(9,'CUST5009','Debit Card','2021-10-25',ENCRYPTBYKEY(KEY_GUID('ORMSSymmetricKey'),'4334556677889922')),
(10,'CUST5010','Credit Card','2025-09-10',ENCRYPTBYKEY(KEY_GUID('ORMSSymmetricKey'),'5544678923451234'))

insert dbo.orders values
	('ORD101','REF101','0','CUST5001','07-29-2020','PR101','PT101'),
	('ORD102','REF102','0','CUST5002','07-30-2020','PR101','PT102'),
	('ORD103','REF103','0','CUST5003','07-29-2020','PR102','PT103'),
	('ORD104','REF104','0','CUST5004','07-21-2019','PR103','PT104'),
	('ORD105','REF105','0','CUST5005','07-29-2020','PR105','PT105'),
	('ORD106','REF106','0','CUST5006','07-22-2020','PR107','PT106'),
	('ORD107','REF107','0','CUST5007','07-22-2020','PR108','PT107'),
	('ORD108','REF108','0','CUST5008','07-23-2020','PR106','PT108'),
	('ORD109','REF109','0','CUST5009','07-29-2020','PR102','PT109'),
	('ORD110','REF110','0','CUST5010','07-29-2020','PR105','PT110');

INSERT dbo.CARTITEMS VALUES
	('CUST5001','ST101','Appliances','07-23-2020'),
	('CUST5001','ST102','Appliances','07-23-2020'),
	('CUST5002','ST103','Appliances','07-23-2020'),
	('CUST5003','ST104','Appliances','07-23-2020'),
	('CUST5004','ST105','Appliances','07-23-2020'),
	('CUST5005','ST106','Appliances','07-23-2020'),
	('CUST5006','ST107','Appliances','07-23-2020'),
	('CUST5002','ST108','Appliances','07-23-2020'),
	('CUST5008','ST109','Appliances','07-23-2020'),
	('CUST5003','ST110','Appliances','07-23-2020'),
	('CUST5009','ST111','Appliances','07-23-2020');


select * from SHOPPINGSITE;
insert into dbo.SHOPPINGSITE values
	('ST102','CUST5001','Ebay','2020-07-21 09:10:40.20','2020-07-31 09:40:40.20'),
	('ST103','CUST5002','Myntra','2020-06-21 09:10:40.20','2020-07-31 09:40:40.20'),
	('ST104','CUST5003','Walmart','2020-05-11 09:10:12.20','2020-06-31 09:40:40.34'),
	('ST105','CUST5004','Amazon','2020-02-21 09:10:40.20','2020-03-31 09:40:40.20'),
	('ST106','CUST5005','Flipkart','2020-06-21 09:10:40.20','2020-07-31 10:12:40.20'),
	('ST107','CUST5006','Shein','2020-01-21 09:10:40.20','2020-07-31 11:40:40.20'),
	('ST108','CUST5002','Romway','2020-06-21 09:10:40.20','2020-07-31 09:40:40.20'),
	('ST109','CUST5008','Snap Deal','2020-06-21 09:10:40.20','2020-07-31 09:40:40.20'),
	('ST110','CUST5003','Jabong','2020-06-21 09:10:40.20','2020-07-31 09:40:40.20'),
	('ST111','CUST5009','Wish','2020-04-08 09:10:40.20','2020-07-09 09:40:40.20');

INSERT INTO INVENTORY(InventoryID, ProductID, SupplierID, ProductQuantity, ProductAvailability, ProductBatchCode, ProductArrivalDate, ProductDepartureDate)
VALUES  ('INV25011', 'PR107', 'SUPP11010', '231', 'Available' , 'BA45011', '2011-08-25', '2011-09-01'),
	   ('INV25012', 'PR115', 'SUPP11009', '290', 'Available' , 'BA45012', '2010-09-25', '2010-09-29'),
	   ('INV25013', 'PR116', 'SUPP11008', '160', 'Available' , 'BA45013', '2012-08-15', '2012-08-22'),
	   ('INV25014', 'PR117', 'SUPP11007', '560', 'Available' , 'BA45014', '2012-10-25', '2012-10-30'),
	   ('INV25015', 'PR118', 'SUPP11006', '450', 'Available' , 'BA45015', '2014-08-25', '2014-09-01'),
	   ('INV25016', 'PR119', 'SUPP11005', '505', 'Available' , 'BA45016', '2015-03-25', '2015-04-01'),
	   ('INV25017', 'PR120', 'SUPP11004', '321', 'Available' , 'BA45017', '2013-01-02', '2013-01-08'),
	   ('INV25018', 'PR121', 'SUPP11003', '125', 'Available' , 'BA45018', '2016-12-25', '2017-01-01'),
	   ('INV25019', 'PR122', 'SUPP11002', '540', 'Available' , 'BA45019', '2017-05-06', '2017-05-12'),
	   ('INV25020', 'PR123', 'SUPP11001', '786', 'Available' , 'BA45020', '2019-06-25', '2019-06-26'),
	   ('INV25001', 'PR101', 'SUPP11001', '0', 'NA' , 'BA45001', '2019-08-27', '2019-08-27'),
	   ('INV25002', 'PR111', 'SUPP11002', '125', 'Available' , 'BA45003', '2007-04-12', '2017-05-05'),
	   ('INV25003', 'PR108', 'SUPP11003', '76', 'Available' , 'BA45002', '2009-04-25', '2009-07-09'), 
	   ('INV25004', 'PR105', 'SUPP11004', '0', 'NA' , 'BA45004', '2005-07-26', '2005-07-26'),
	   ('INV25005', 'PR106', 'SUPP11006', '500', 'Available' , 'BA45005', '2006-12-12', '2006-12-25'),
	   ('INV25006', 'PR110', 'SUPP11005', '412', 'Available' , 'BA45006', '2008-04-12', '2008-04-18'),
	   ('INV25007', 'PR109', 'SUPP11008', '0', 'NA' , 'BA45007', '2007-04-12', '2007-04-12'),
	   ('INV25008', 'PR113', 'SUPP11007', '353', 'Available' , 'BA45008', '2009-06-08', '2009-06-14'),
	   ('INV25009', 'PR114', 'SUPP11009', '328', 'Available' , 'BA45009', '2015-10-12', '2015-10-30'),
	   ('INV25010', 'PR112', 'SUPP11010', '987', 'Available' , 'BA45010', '2013-11-25', '2013-12-05')

INSERT INTO dbo.INVOICE VALUES
	('INV901','ORD101'),
	('INV902','ORD102'),
	('INV903','ORD103'),
	('INV904','ORD104'),
	('INV905','ORD105'),
	('INV906','ORD106'),
	('INV907','ORD107'),
	('INV908','ORD108'),
	('INV909','ORD109'),
	('INV910','ORD110')

insert orderdetails values('PR115','ORD101'),
							('PR101','ORD102'),					
	   ('PR114','ORD103'),('PR112','ORD108'),('PR110','ORD109'),('PR108','ORD104'),('PR106','ORD105'),('PR105','ORD109'),
	   ('PR113','ORD104'),('PR111','ORD107'),('PR109','ORD110'),('PR107','ORD103'),('PR116','ORD106'),('PR117','ORD108'),
	   ('PR118','ORD105'),('PR119','ORD106'),('PR120','ORD101'),('PR121','ORD102'),('PR122','ORD107'),('PR123','ORD110')

insert into dbo.payment values
('PT102','CUST5002','18','07-30-2020','Complete','ORD102'),
('PT103','CUST5003','70','07-29-2020','Complete','ORD101'),
('PT104','CUST5004','77','07-21-2020','Complete','ORD103'),
('PT105','CUST5005','11','07-29-2020','Incomplete','ORD104'),
('PT106','CUST5006','12','07-22-2020','Complete','ORD105'),
('PT107','CUST5007','4','07-22-2020','Complete','ORD106'),
('PT108','CUST5008','22','07-23-2020','Complete','ORD107'),
('PT109','CUST5009','10','07-29-2020','Complete','ORD108'),
('PT110','CUST5010','16','07-29-2020','Complete','ORD109');

------CREATED VIEWS-------

CREATE VIEW vwBrandVSProduct
	AS		
	SELECT PRODUCT.BrandID, ProductName, BrandRating, BrandSales
	FROM PRODUCT
	INNER JOIN BRAND ON PRODUCT.BrandID = BRAND.BrandID;

CREATE VIEW vwPaymentvsShoppingSite
	AS		
	SELECT PAYMENT.CustomerID, SiteName, SUM(OrderValue) as Total_OrderValue, PaymentStatus FROM PAYMENT
	INNER JOIN SHOPPINGSITE ON PAYMENT.CustomerID = SHOPPINGSITE.CustomerID
	INNER JOIN ORDERS ON SHOPPINGSITE.CustomerID = ORDERS.CustomerID
	GROUP BY PAYMENT.CustomerID, SiteName, PaymentStatus


----TABLELEVEL CHECK CONSTRAINT USING FUNCTION--

---Function for checking Phone Number---
GO
CREATE FUNCTION dbo.CheckPHONE
(@PhoneNumber Bigint, @CustomerID varchar(50))
RETURNS BIT
AS
BEGIN
	Declare @phn BIT;
	IF(LEN(@PhoneNumber) = 10 AND @PhoneNumber LIKE '[6-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
		SET @phn = 1;
	ELSE SET @phn =  0;
RETURN @phn
END;

ALTER TABLE Customer
ADD CONSTRAINT CHK_PhoneValiadation
CHECK (dbo.CheckPHONE(PhoneNumber,CustomerID)=1)

--- Function for checking User Type---

Create function FNC_CheckCustomer(@UserID Varchar(50))
RETURNS BIT
AS
BEGIN
	Declare @bit BIT;
	Declare @userType varchar(50);
	SET @userType = (select ut.UserTypeName  From USERTYPES ut
					inner join USERS u on u.UserTypeID =ut.UserTypeID
					where u.UserID = @UserID)
	IF(LOWER(@userType) = 'customer')
		SET @bit =1;
	Else 
		SET @bit =0;
		
RETURN @bit
END;

Alter Table Customer
ADD CONSTRAINT CHK_Customer
CHECK (dbo.FNC_CheckCustomer(UserID)=1)


OPEN SYMMETRIC KEY ORMSSymmetricKey
DECRYPTION BY CERTIFICATE ORMSCertificate
 SELECT * From dbo.EMPLOYEETYPE
CLOSE SYMMETRIC KEY ORMSSymmetricKey

---CHECKING THE CERTIFICATE----
USE ORMS_Group19
SELECT * FROM sys.certificates WHERE pvt_key_encryption_type <> 'NA'

--ENCRYPTION KEY--
CREATE MASTER KEY 
ENCRYPTION BY Password = 'ORMS_P@SSWORD';

--CREATE CERTIFICATE FOR THE SYMMETRIC KEY---
CREATE CERTIFICATE ORMSCertificate
WITH SUBJECT = 'ORMS Test Certificate'


---CREATE ENCRYPT KEY---
CREATE SYMMETRIC KEY ORMSSymmetricKey
WITH ALGORITHM = AES_192
ENCRYPTION BY CERTIFICATE ORMSCertificate;

---OPEN SYMMETRIC KEY----
OPEN SYMMETRIC KEY ORMSSymmetricKey
DECRYPTION BY CERTIFICATE ORMSCertificate
 SELECT * ,CONVERT(varchar, DECRYPTBYKEY(Password)) AS DecryptedPassword From dbo.USERS
CLOSE SYMMETRIC KEY ORMSSymmetricKey


-----COMPUTED COLUMN BASED ON A FUNCTION-----

 CREATE FUNCTION Total_Value(@ActualProductPrice DECIMAL(15,2), @DiscountPrice DECIMAL(15,2))
RETURNS DECIMAL(15,2)
AS
   BEGIN
	  Return @ActualProductPrice-@DiscountPrice;
END
GO

ALTER TABLE dbo.Product
ADD ProductValue AS (dbo.Total_Value(ActualProductPrice, DiscountPrice));

select ProductID, (dbo.Total_Value(ActualProductPrice, DiscountPrice)) as Total From PRODUCT

-- dropping Database

drop database ORMS_Group19;