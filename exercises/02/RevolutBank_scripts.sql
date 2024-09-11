CREATE DATABASE RevolutBankingDB
GO

USE RevolutBankingDB
GO

CREATE SCHEMA Banks
GO

CREATE SCHEMA Accounts
GO

CREATE SCHEMA Cards
GO

CREATE SCHEMA Users
GO

CREATE SCHEMA Resources
GO

----------------- BANKS.BANKS ------------------
CREATE TABLE [Banks].[Banks]
(
	BankId INT IDENTITY(1, 1) NOT NULL,
	BankIdentifierCode VARCHAR(11) NOT NULL,
	BankName NVARCHAR(150) NOT NULL,
	BranchName NVARCHAR(150) NOT NULL,
	Rating VARCHAR(5),
	AssetsAmount MONEY,
	CONSTRAINT PK_Banks_BankId PRIMARY KEY(BankId),
	CONSTRAINT UQ_BANKS_BankIdentifierCode UNIQUE(BankIdentifierCode),
);

EXEC sys.sp_addextendedproperty
  @name=N'TableDescription',
  @value=N'Table is used for storing bank informaiton.',
  @level0type=N'SCHEMA',
  @level0name=N'Banks',
  @level1type=N'TABLE',
  @level1name=N'Banks';

INSERT INTO [Banks].[Banks]
	([BankIdentifierCode]
	,[BankName]
	,[BranchName]
	,[Rating]
	,[AssetsAmount])
VALUES
	('REVOGB2LXXX'
       	, 'REVOLUT LTD'
       	, 'EU REVOLUT'
       	, 'AAA'
       	, 24000000)
GO

----------------- BANKS.BANKS ------------------

----------------- Resources.Currencies ---------
CREATE TABLE [Resources].[Currencies]
(
	CurrencyId INT IDENTITY(1, 1) NOT NULL,
	Code VARCHAR(3) NOT NULL,
	[Name] NVARCHAR(15) NOT NULL,
	CBDC BIT NOT NULL CONSTRAINT DF_Currencies_CBDC DEFAULT 0,
	CONSTRAINT PK_Currencies_CurrencyId PRIMARY KEY(CurrencyId),
	CONSTRAINT UQ_Currencies_Code UNIQUE(Code),
);
GO

INSERT INTO [Resources].[Currencies]
	([Code]
	,[Name])
VALUES
	('BGN'
    	, 'Bulgrian lev')
GO
----------------- Resources.Currencies ---------


----------------- Accounts.AccountTypes --------
CREATE TABLE [Accounts].[AccountTypes]
(
	AccountTypeId INT IDENTITY(1, 1) NOT NULL,
	Code VARCHAR(3) NOT NULL,
	[Name] NVARCHAR(100) NOT NULL,
	CONSTRAINT PK_AccountTypes_AccountId PRIMARY KEY(AccountTypeId),
	CONSTRAINT UQ_AccountTypes_Code UNIQUE(Code),
);
GO

INSERT INTO [Accounts].[AccountTypes]
	([Code]
	,[Name])
VALUES
	('CHA'
       	, 'Checking account')
GO
----------------- Accounts.AccountTypes --------


----------------- Users.Users ------------------
CREATE TABLE [Users].[Users]
(
	UserId INT IDENTITY(1, 1) NOT NULL,
	FirstName NVARCHAR(150) NOT NULL,
	LastName NVARCHAR(150) NOT NULL,
	NationalIdentityNumber NVARCHAR(15) NOT NULL,
	[State] TINYINT NOT NULL CONSTRAINT DF_Users_State DEFAULT 1,
	CONSTRAINT PK_Users_UserId PRIMARY KEY(UserId),
	CONSTRAINT UQ_Users_NationalIdentityNumber UNIQUE(NationalIdentityNumber),
);
GO

INSERT INTO [Users].[Users]
	([FirstName]
	,[LastName]
	,[NationalIdentityNumber])
VALUES
	('Pavel'
       	, 'Kyurkchiev'
       	, '8901121122')
GO

----------------- Users.Users ------------------


----------------- Users.Clients ----------------
CREATE TABLE [Users].[Clients]
(
	ClientId INT IDENTITY(1, 1) NOT NULL,
	UserId INT NOT NULL,
	CONSTRAINT PK_Clients_ClientId PRIMARY KEY(ClientId),
	CONSTRAINT FK_Users_Clients_UserId FOREIGN KEY (UserId) REFERENCES
 	Users.Users(UserId),
);
 GO

INSERT INTO [Users].[Clients]
	([UserId])
VALUES
	(1)
GO
----------------- Users.Clients ----------------

----------------- CARDS.CARDS ------------------
CREATE TABLE [Cards].[Cards]
(
	CardId INT IDENTITY(1, 1) NOT NULL,
	PermanentAccountNumber NVARCHAR(19) NOT NULL,
	CVV NVARCHAR(3) NOT NULL,
	ValidationDate DATETIME2 NOT NULL,
	[State] TINYINT NOT NULL CONSTRAINT DF_Accounts_State DEFAULT 0,
	CONSTRAINT PK_Cards_CardId PRIMARY KEY(CardId),
);
GO

CREATE TRIGGER tr_ForDeleteCard
ON Cards.Cards
FOR DELETE
AS
  BEGIN
	IF EXISTS(SELECT 1
	FROM DELETED
	WHERE ValidationDate >= GETDATE())
    	BEGIN
		PRINT 'YOU CANNOT PERFORM DELETE OPRATION';

		ROLLBACK TRANSACTION;
	END
END

GO

INSERT INTO [Cards].[Cards]
	( [PermanentAccountNumber]
	,[CVV]
	,[ValidationDate]
	,[State])
VALUES
	('122234445558888'
       	, '032'
       	, '20281210'
   		, 1)
       	,
	('53395566222333'
       	, '072'
       	, '20261210'
   		, 1)
		,
	('43395566555555'
       	, '082'
       	, '20231210'
   		, 0)
GO
----------------- CARDS.CARDS ------------------


----------------- Accounts.Accounts ------------
CREATE TABLE [Accounts].[Accounts]
(
	AccountId INT IDENTITY(1, 1) NOT NULL,
	IBAN NVARCHAR(34) NOT NULL,
	Balance MONEY NULL,
	BankId INT NOT NULL,
	ClientId INT NOT NULL,
	AccountTypeId INT NOT NULL,
	CurrencyId INT NOT NULL,
	CardId INT NOT NULL,
	[State] TINYINT NOT NULL CONSTRAINT DF_Accounts_State DEFAULT 1,
	CONSTRAINT PK_Accounts_AccountId PRIMARY KEY(AccountId),
	CONSTRAINT FK_Banks_Accounts_BankId FOREIGN KEY (BankId) REFERENCES
 	Banks.Banks(BankId),
	CONSTRAINT FK_Clients_Accounts_ClientId FOREIGN KEY (ClientId) REFERENCES
 	Users.Clients(ClientId),
	CONSTRAINT FK_AccountTypes_Accounts_AccountTypeId FOREIGN KEY (
 	AccountTypeId) REFERENCES Accounts.AccountTypes(AccountTypeId),
	CONSTRAINT FK_Currencies_Accounts_CurrencyId FOREIGN KEY (CurrencyId)
 	REFERENCES Resources.Currencies(CurrencyId),
	CONSTRAINT FK_Cards_Accounts_CardId FOREIGN KEY (CardId) REFERENCES
 	Cards.Cards(CardId),
);
GO

CREATE TRIGGER TR_AfterInsertAccount
ON [Accounts].[Accounts]
AFTER INSERT
AS
BEGIN
	INSERT INTO [Accounts].[Transactions]
		([AccountId]
		,[ReceiverIBAN]
		,[Amount]
		,[CreatedOn])
	SELECT AccountId
   	 , 'BG18REVLL122223233'
   	 , 5
   	 , GETDATE()
	FROM INSERTED;
END
GO

INSERT INTO [Accounts].[Accounts]
	([IBAN]
	,[Balance]
	,[BankId]
	,[ClientId]
	,[AccountTypeId]
	,[CurrencyId]
	,[CardId])
VALUES
	('BG18REVLL122223233'
       	, 12000
       	, 1
       	, 1
       	, 1
       	, 1
       	, 1)
GO
----------------- Accounts.Accounts ------------


----------------- Accounts.Transactions --------
CREATE TABLE [Accounts].[Transactions]
(
	TransactionId INT IDENTITY(1, 1) NOT NULL,
	AccountId INT NOT NULL,
	ReceiverIBAN NVARCHAR(34) NOT NULL,
	Amount MONEY NOT NULL,
	CurrencyId INT NOT NULL,
	CreatedOn DATETIME2 NOT NULL CONSTRAINT DF_Transctions_CreatedOn DEFAULT Getdate (),
	[State] TINYINT NOT NULL CONSTRAINT DF_Transctions_State DEFAULT 0,
	CONSTRAINT PK_Accounts_TransactionId PRIMARY KEY(TransactionId),
	CONSTRAINT FK_Accounts_Transactions_AccountId FOREIGN KEY (AccountId)
 	REFERENCES Accounts.Accounts(AccountId),
	CONSTRAINT FK_Currencies_Transactions_CurrencyId FOREIGN KEY (CurrencyId)
 	REFERENCES Resources.Currencies(CurrencyId),
);
GO


INSERT INTO [Accounts].[Transactions]
	([AccountId]
	,[ReceiverIBAN]
	,[Amount]
	,[CurrencyId]
	,[CreatedOn])
VALUES
	(1
       	, 'BG12DSKK1231231233333'
       	, 100
   		, 1
       	, '20240905')
GO
----------------- Accounts.Transactions --------



----------------- Stored Procedure  ------------
CREATE PROCEDURE UPS_GeTransactionConvertedToBGN
	(@AccountId INT)
AS
BEGIN
	SELECT aa.IBAN AS SenderIBAN,
		t.ReceiverIBAN,
		t.Amount,
		t.CreatedOn
	FROM [Accounts].[Transactions] AS t
		INNER JOIN [Accounts].[Accounts] AS aa
		ON t.AccountId = aa.AccountId
	WHERE  t.AccountId = @AccountId
		AND aa.[State] = 1
END
GO

EXEC ups_GeTransactionConvertedToBGN @AccountId = 1
----------------- Stored Procedure  ------------
