CREATE DATABASE RevolutBankingDB;

CREATE TABLE Banks (
 BankID int NOT NULL,
 BankIdentifierCode nvarchar(11) NOT NULL UNIQUE,
 BankName nvarchar(150) NOT NULL,
 BankBranchName nvarchar(150) NOT NULL,
 Rating varchar(5),
 AssetsAmount money,
 CONSTRAINT PK_Bank PRIMARY KEY (BankID)
);

CREATE TABLE Currencies (
 CurrencyID int NOT NULL,
 [Name] nvarchar(30) NOT NULL,
 IsCBDC bit NOT NULL,
 Descriptions nvarchar(150) NOT NULL,
 CONSTRAINT PK_Curency PRIMARY KEY (CurrencyID)
);

CREATE TABLE  Customers (
 CustomerID int NOT NULL,
 NationalIdentityNumber nvarchar(15) NOT NULL,
 FirstName nvarchar(150) NOT NULL,
 LastName nvarchar(150) NOT NULL,
 [Address] nvarchar(300),
 CONSTRAINT PK_Customer PRIMARY KEY (CustomerID)
);

CREATE TABLE BankAccountTypes (
 BankAccountTypeID int NOT NULL,
 [Name] nvarchar(30) NOT NULL,
 Descriptions nvarchar(150) NOT NULL,
 Limit money,
 Rate DECIMAL(5,2),
 CONSTRAINT PK_BankAccountType PRIMARY KEY (BankAccountTypeID)
);

CREATE TABLE Cards (
 CardID int NOT NULL,
 CardNumber nvarchar(30) NOT NULL,
 PINCode nvarchar(4) NOT NULL,
 CVV nvarchar(3) NOT NULL,
 Limit money,
 ValidationDate datetime2 NOT NULL,
 CardType nvarchar(30) NOT NULL,
 CONSTRAINT PK_Card PRIMARY KEY (CardID)
);

-- Constraint
ALTER TABLE Cards ADD CONSTRAINT DF_Cards_ValidationDate_Default
DEFAULT GETUTCDATE() FOR ValidationDate;

CREATE TABLE CardsTwoBankAccounts(
 CardID int NOT NULL,
 BankAccountID int NOT NULL,
 CONSTRAINT PK_CardsTwoBankAccount PRIMARY KEY (CardID, BankAccountID)
);

-- Constraint
ALTER TABLE CardsTwoBankAccounts
ADD CONSTRAINT FK_CardsTwoBankAccounts_Cards_CardID
FOREIGN KEY (CardID) REFERENCES Cards(CardID);
ALTER TABLE CardsTwoBankAccounts
ADD CONSTRAINT FK_CardsTwoBankAccounts_BankAccounts_BankAccountID
FOREIGN KEY (BankAccountID) REFERENCES BankAccounts(BankAccountID);

CREATE TABLE Transactions (
 TransactionID int NOT NULL,
 SenderBankAccountID int NOT NULL,
 ReceiverBankAccountID int NOT NULL,
 Amount money,
 CreatedOn datetime2 NOT NULL,
 CurrencyID int NOT NULL,
 CONSTRAINT PK_Transaction PRIMARY KEY (TransactionID)
);

-- Constraint
ALTER TABLE Transactions
ADD CONSTRAINT FK_Transactions_BankAccounts_SenderBankAccountID
FOREIGN KEY (SenderBankAccountID) REFERENCES BankAccounts(BankAccountID);
ALTER TABLE Transactions
ADD CONSTRAINT FK_Transactions_BankAccounts_ReceiverBankAccountID
FOREIGN KEY (ReceiverBankAccountID) REFERENCES BankAccounts(BankAccountID);
ALTER TABLE Transactions
ADD CONSTRAINT FK_Transactions_Currencies_CurrencyID
FOREIGN KEY (CurrencyID) REFERENCES Currencies(CurrencyID);
ALTER TABLE Transactions ADD CONSTRAINT DF_Transactions_CreatedOn_Default
DEFAULT GETUTCDATE() FOR CreatedOn;

CREATE TABLE BankAccounts (
 BankAccountID int NOT NULL,
 Balance money,
 IsActive bit NOT NULL,
 CardID int NOT NULL,
 BankAccountTypeID int NOT NULL,
 BankID int NOT NULL,
 CustomerID int NOT NULL,
 CONSTRAINT PK_BankAccount PRIMARY KEY (BankAccountID)
);

-- Constraints
ALTER TABLE BankAccounts
ADD CONSTRAINT FK_BankAccounts_Cards_CardID
FOREIGN KEY (CardID) REFERENCES Cards(CardID);
ALTER TABLE BankAccounts
ADD CONSTRAINT FK_BankAccounts_BankAccountTypes_BankAccountTypeID
FOREIGN KEY (BankAccountTypeID) REFERENCES BankAccountTypes(BankAccountTypeID);
ALTER TABLE BankAccounts
ADD CONSTRAINT FK_BankAccounts_Banks_BankID
FOREIGN KEY (BankID) REFERENCES Banks(BankID);
ALTER TABLE BankAccounts
ADD CONSTRAINT FK_BankAccounts_Customers_CustomerID
FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID);

-- Insert dumy data
INSERT INTO Customers
select 1,'8906162030','Pavel','Kyurkchiev','Plovdiv,Dunav' union
select 2,'9010241330','Ivan','Ivanov','Sofia,Ivan Vazov' union
select 3,'9111141015','Todor','Todorov','Sofia,Boris 3'

INSERT INTO Currencies
select 1,'USD',0,'USA default currency' union
select 2,'EUR',0,'EU default currency' union
select 3,'DEUR',1,'Digital EU currency' union
select 4,'BGN',0,'Bulgaria default currency'

INSERT INTO Banks
select 1,'BOFIIE2D','Bulgarian National Bank','Bulgaria','BBB+', 100000000 union
select 2,'DSKIFC3D','DSK bank','Bulgaria','BBB', 10000000 union
select 3,'UNIIIF4D','Unicredit bank','Bulgaria','BBB-', 9000000

INSERT INTO BankAccountTypes
select 1,'passive','Passive account, only can deposit money',100000,0.3 union
select 2,'active','Active account',150000,0.1 union
select 3,'deposit','Deposit with a specific rate of return',300000,5.3

INSERT INTO Cards(CardID,CardNumber,PINCode,CVV,Limit,CardType)
select 1,'345523541756008','0596','210',4000,'American Express' union
select 2,'5107239251730706','3496','110',6000,'MasterCard' union
select 3,'4532916485405399','0897','330',7000,'Visa'

INSERT INTO BankAccounts
select 1,40000,1,1,2,1,1 union
select 2,5000,2,3,2,2,2 union
select 3,1000,3,1,2,3,3

INSERT INTO CardsTwoBankAccounts
select 1,2 union
select 1,1 union
select 2,3 union
select 3,1 union
select 2,3

INSERT INTO Transactions(TransactionID,SenderBankAccountID,ReceiverBankAccountID,Amount,CurrencyID)
select 1,1,2,500,1 union
select 2,1,2,200,3 union
select 3,3,2,1500,2 union
select 4,3,2,1500,4

-- SP
CREATE PROCEDURE usp_GetTransactionConvertedToBGN
(@SenderID int)
AS
BEGIN
SET NOCOUNT ON

SELECT
   t.SenderBankAccountID,
   ba11.FirstName + ' ' + ba11.LastName as SenderFullName,
   t.ReceiverBankAccountID,
   ba22.FirstName + ' ' + ba22.LastName as ReceiverFullName,
   t.Amount AS AmountOriginal,
   c.Name AS Currency,
   CASE
      WHEN
         c.Name = 'EUR' 
      THEN
         t.Amount * 1.95583 
      WHEN
         c.Name = 'DEUR' 
      THEN
         t.Amount * 1.95583 
      WHEN
         c.Name = 'USD' 
      THEN
         t.Amount * 1.66624 
      ELSE
         t.Amount 
   END
   AmountBGN , t.CreatedOn 
FROM
   Transactions t 
   LEFT JOIN
      (
         SELECT
            ba1.BankAccountID,
            c1.FirstName,
            c1.LastName 
         FROM
            BankAccounts ba1 
            LEFT JOIN
               Customers c1 
               ON ba1.CustomerID = c1.CustomerID
      )
      ba11 
      ON t.SenderBankAccountID = ba11.BankAccountID 
   LEFT JOIN
      (
         SELECT
            ba2.BankAccountID,
            c2.FirstName,
            c2.LastName 
         FROM
            BankAccounts ba2 
            LEFT JOIN
               Customers c2 
               ON ba2.CustomerID = c2.CustomerID
      )
      ba22 
      ON t.ReceiverBankAccountID = ba22.BankAccountID 
   LEFT JOIN
      Currencies c 
      ON t.CurrencyID = c.CurrencyID
	WHERE t.SenderBankAccountID = @SenderID
END

EXEC usp_GetTransactionConvertedToBGN 3

-- Trigger: INSERT, UPDATE, DELETE -> BEFORE, AFTER, FOR
CREATE TRIGGER tr_ForDeleteCard
ON Cards
FOR DELETE
AS
BEGIN
 PRINT 'YOU CANNOT PERFORM DELETE OPERATION';
 ROLLBACK TRANSACTION;
END

delete from Cards where CardID = 2

CREATE TRIGGER tr_AfterInsertBankAccount
ON BankAccounts
AFTER INSERT
AS
BEGIN
	UPDATE BankAccounts SET IsActive = 1 FROM inserted 
	WHERE BankAccounts.BankAccountID = inserted.BankAccountID;
END
