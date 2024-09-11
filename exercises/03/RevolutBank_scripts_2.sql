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

CREATE SCHEMA Currencies
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

----------------- Currencies.Currencies --------
CREATE TABLE [Currencies].[Currencies]
(
	CurrencyId INT IDENTITY(1, 1) NOT NULL,
	Code VARCHAR(3) NOT NULL,
	[Name] NVARCHAR(30) NOT NULL,
	CBDC BIT NOT NULL CONSTRAINT DF_Currencies_CBDC DEFAULT 0,
	CONSTRAINT PK_Currencies_CurrencyId PRIMARY KEY(CurrencyId),
	CONSTRAINT UQ_Currencies_Code UNIQUE(Code),
);
GO

INSERT INTO [Currencies].[Currencies]
	([Code]
	,[Name])
VALUES
	('BGN', 'Bulgrian lev')
	,
	('EUR', 'Euro')
	,
	('USD', 'United States dollar')
	,
	('GBP', 'British pound')
GO
----------------- Currencies.Currencies --------


----------------- Currencies.ExchangeRates -----
CREATE TABLE [Currencies].[ExchangeRates]
(
	CurrencyId INT NOT NULL,
	ExchangeDate DATE NOT NULL,
	Buy FLOAT NOT NULL CONSTRAINT DF_ExchangeRates_Buy DEFAULT 1,
	Sell FLOAT NOT NULL CONSTRAINT DF_ExchangeRates_Sell DEFAULT 1,
	CONSTRAINT FK_Currencies_ExchanteRages_CurrencyId FOREIGN KEY (CurrencyId) REFERENCES Currencies.Currencies(CurrencyId),
	INDEX IX_ExchangeRates_CurrencyId_ExchangeDate NONCLUSTERED (CurrencyId, ExchangeDate)
);
GO

INSERT INTO [Currencies].[ExchangeRates]
	([CurrencyId]
	,[ExchangeDate]
	,[Sell]
	,[Buy])
VALUES
	(4, convert(date,'02.09.2024', 104), 2.32234, 0.4306)
	,
	(4, convert(date,'03.09.2024', 104), 2.32602, 0.429919)
	,
	(4, convert(date,'04.09.2024', 104), 2.32152, 0.430752)
	,
	(4, convert(date,'05.09.2024', 104), 2.31959, 0.431111)
	,
	(4, convert(date,'06.09.2024', 104), 2.31959, 0.431111)
	,
	(4, convert(date,'07.09.2024', 104), 2.31959, 0.431111)
	,
	(4, convert(date,'08.09.2024', 104), 2.31959, 0.431111)
	,
	(4, convert(date,'09.09.2024', 104), 2.3183, 0.431351)
	,
	(4, convert(date,'10.09.2024', 104), 2.32105, 0.430839)
	,
	(3, convert(date,'02.09.2024', 104), 1.76822, 0.56554)
	,
	(3, convert(date,'03.09.2024', 104), 1.77239, 0.56421)
	,
	(3, convert(date,'04.09.2024', 104), 1.76998, 0.564978)
	,
	(3, convert(date,'05.09.2024', 104), 1.76249, 0.567379)
	,
	(3, convert(date,'06.09.2024', 104), 1.76249, 0.567379)
	,
	(3, convert(date,'07.09.2024', 104), 1.76249, 0.567379)
	,
	(3, convert(date,'08.09.2024', 104), 1.76249, 0.567379)
	,
	(3, convert(date,'09.09.2024', 104), 1.7711, 0.564621)
	,
	(3, convert(date,'10.09.2024', 104), 1.77303, 0.564006)
GO
----------------- Currencies.ExchangeRates -----


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
	('CHA', 'Checking account')
  , ('FSE', 'Flex safe')
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
	('Pavel', 'Kyurkchiev', '8901121122')
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

CREATE TRIGGER TR_ForDeleteCard
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
	('122234445558888', '032', '20281210', 1)
   , ('53395566222333', '072', '20261210', 1)
   , ('43395566555555', '082', '20231210', 0)
   , ('33394354566655', '022', '20281210', 1)
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
 	REFERENCES Currencies.Currencies(CurrencyId),
	CONSTRAINT FK_Cards_Accounts_CardId FOREIGN KEY (CardId) REFERENCES
 	Cards.Cards(CardId),
);
GO

CREATE TRIGGER TR_AfterInsertAccount
ON [Accounts].[Accounts]
AFTER INSERT
AS
BEGIN
	IF (EXISTS (SELECT *
	FROM INFORMATION_SCHEMA.TABLES
	WHERE TABLE_SCHEMA = 'Accounts'
    	AND TABLE_NAME = 'Transactions'))
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
	('BG18REVLL122223233' , 12000 , 1 , 1 , 1 , 1 , 1)
  , ('BG18REVLL898566365' , 580 , 1 , 1 , 2 , 1 , 2)
  , ('BG18REVLL852266344' , 80 , 1 , 1 , 1 , 1 , 3)
  , ('BG18REVLL845855554' , 80 , 1 , 1 , 1 , 1 , 4)
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
 	REFERENCES Currencies.Currencies(CurrencyId),
);
GO


INSERT INTO [Accounts].[Transactions]
	([AccountId]
	,[ReceiverIBAN]
	,[Amount]
	,[CurrencyId]
	,[CreatedOn])
VALUES
	(1, 'BG12DSKK1231231233333', 100, 3, '20240905')
	, (1, 'BG12DSKK1231231233333', 20, 4, '20240903')
	, (1, 'BG12DSKK1231231233333', 5.2, 4, '20240902')
GO
----------------- Accounts.Transactions --------

----------------- Function  --------------------
CREATE FUNCTION [Currencies].[F_AmountToCurrency]
(
	@iAmount MONEY,
	@iCurrencyCode VARCHAR(3) = 'EUR',
	@iExchangeDate DATE = GETDATE,
	@iExchangeAction BIT = 0 -- 0 - SELL, 1 - BUY
)
RETURNS MONEY
AS
BEGIN
	DECLARE @oAmount MONEY = 0;

	SELECT @oAmount = CASE @iExchangeAction
    	WHEN 0 THEN er.Sell * @iAmount
    	ELSE er.Buy * @iAmount
	END
	FROM [Currencies].[ExchangeRates] AS er
    	LEFT JOIN [Currencies].[Currencies] AS cc ON cc.CurrencyId = er.CurrencyId
	WHERE cc.Code = @iCurrencyCode AND er.ExchangeDate = @iExchangeDate;

	RETURN @oAmount;
END
GO

SELECT [Currencies].[f_AmountToCurrency] (12, 'GBP', '2024-09-08', 1)
GO
----------------- Function  --------------------


----------------- Stored Procedure  ------------
CREATE PROCEDURE UPS_GeTransactionToBaseCurrency
	(@iAccountId INT)
AS
BEGIN
	SELECT aa.IBAN AS SenderIBAN
    	, t.ReceiverIBAN
    	, CASE WHEN cc.Code = 'BGN' THEN t.Amount
        	ELSE [Currencies].[F_AmountToCurrency](t.Amount, cc.Code, CAST(t.CreatedOn AS DATE), 1)
    	END  Amount
    	, t.CreatedOn
	FROM [Accounts].[Transactions] AS t
    	INNER JOIN [Accounts].[Accounts] AS aa
    	ON t.AccountId = aa.AccountId
    	INNER JOIN [Currencies].[Currencies] AS cc
    	ON cc.CurrencyId = t.CurrencyId
	WHERE  t.AccountId = @iAccountId
    	AND aa.[State] = 1
END
GO

EXEC UPS_GeTransactionToBaseCurrency @iAccountId = 1
GO
----------------- Stored Procedure  ------------


----------------- View  ------------
CREATE VIEW [Cards].[VW_CardsGet] AS
SELECT uu.FirstName
, uu.LastName
, c.PermanentAccountNumber
, c.ValidationDate
, a.Balance
, cc.Code
, t.[Name] AS AccountType
FROM [Cards].[Cards] AS c
INNER JOIN [Accounts].[Accounts] AS a ON c.CardId = a.CardId AND a.State = 1
INNER JOIN [Accounts].[AccountTypes] AS t ON a.AccountTypeId = t.AccountTypeId
INNER JOIN [Users].[Clients] as uc ON uc.ClientId = a.ClientId
INNER JOIN [Users].[Users] as uu ON uc.UserId = uu.UserId
INNER JOIN [Currencies].[Currencies] as cc ON a.CurrencyId = cc.CurrencyId
WHERE c.State = 1;
GO

SELECT * FROM [Cards].[VW_CardsGet]
----------------- View  ------------
