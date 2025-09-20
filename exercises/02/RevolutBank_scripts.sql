CREATE DATABASE RevoluteBankingDB
GO

USE RevoluteBankingDB
GO

CREATE SCHEMA Banks
GO

CREATE SCHEMA Accounts
GO

CREATE SCHEMA Cards
GO

CREATE SCHEMA Clients
GO

CREATE SCHEMA Resources
GO

------------ Banks.Banks ------------
CREATE TABLE [Banks].[Banks]
(
    BankId INT IDENTITY(1, 1) NOT NULL,
    BankIdentifierCode VARCHAR(11) NOT NULL,
    [Name] NVARCHAR(150) NOT NULL,
    BranchName NVARCHAR(150) NOT NULL,
    Rating VARCHAR(5),
    AssetsAmount MONEY,
    CONSTRAINT PK_Banks_BankId PRIMARY KEY(BankId),
    CONSTRAINT UQ_Banks_BankIdentifierCode UNIQUE(BankIdentifierCode),
);

EXEC sys.sp_addextendedproperty
    @name=N'TableDescription',
    @value=N'Table is used for storing bank information.',
    @level0type=N'SCHEMA',
    @level0name=N'Banks',
    @level1type=N'TABLE',
    @level1name=N'Banks';

INSERT INTO [Banks].[Banks]
    ( BankIdentifierCode, [Name], BranchName, Rating, AssetsAmount )
VALUES
    ('REVOGB2LXXX' , 'REVOLUT LTD', 'EU Revolut', 'AAA', 240000000);
------------ Banks.Banks ------------

------------ Resources.Currencies ------------
CREATE TABLE [Resources].[Currencies]
(
    CurrencyId INT IDENTITY(1, 1) NOT NULL,
    Code VARCHAR(3) NOT NULL,
    [Name] NVARCHAR(15) NOT NULL,
    CBDC BIT NOT NULL CONSTRAINT DF_Currencies_CDBC DEFAULT 0,
    CONSTRAINT PK_Currencies_CurrencyId PRIMARY KEY(CurrencyId),
    CONSTRAINT UQ_Currencies_Code UNIQUE(Code)
);

EXEC sys.sp_addextendedproperty
    @name=N'TableDescription',
    @value=N'Table is used for storing currency information.',
    @level0type=N'SCHEMA',
    @level0name=N'Resources',
    @level1type=N'TABLE',
    @level1name=N'Currencies';

INSERT INTO [Resources].[Currencies]
    (Code, Name)
VALUES
    ('BGN', 'lev');
------------ Resources.Currencies ------------


------------ Accounts.AccountTypes ------------
CREATE TABLE [Accounts].[AccountTypes]
(
    AccountTypeId INT IDENTITY(1, 1) NOT NULL,
    Code VARCHAR(3) NOT NULL,
    [Name] NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_AccoutTypes_AccountTypeId PRIMARY KEY(AccountTypeId),
    CONSTRAINT UQ_AccoutTypes_Code UNIQUE(Code),
);

EXEC sys.sp_addextendedproperty
    @name=N'TableDescription',
    @value=N'Table is used for storing account types information.',
    @level0type=N'SCHEMA',
    @level0name=N'Accounts',
    @level1type=N'TABLE',
    @level1name=N'AccountTypes';

INSERT INTO [Accounts].[AccountTypes]
    (Code, [Name])
VALUES('CHA', 'Checking account');
------------ Accounts.AccountTypes ------------


------------ Clients.Users ------------
CREATE TABLE [Clients].[Users]
(
    UserId INT IDENTITY(1, 1) NOT NULL,
    FirstName NVARCHAR(150) NOT NULL,
    LastName NVARCHAR(150) NOT NULL,
    NationalIdentifierNumber NVARCHAR(15) NOT NULL,
    [State] TINYINT NOT NULL CONSTRAINT DF_Clients_State DEFAULT 1,
    CONSTRAINT PK_Clients_UserId PRIMARY KEY(UserId),
    CONSTRAINT UQ_Clients_NationalIdentifierNumber UNIQUE(NationalIdentifierNumber),
);

EXEC sys.sp_addextendedproperty
    @name=N'TableDescription',
    @value=N'Table is used for storing user information.',
    @level0type=N'SCHEMA',
    @level0name=N'Clients',
    @level1type=N'TABLE',
    @level1name=N'Users';

INSERT INTO [Clients].[Users]
    (FirstName, LastName, NationalIdentifierNumber)
VALUES('Pavel', 'Kyurkchiev', '8901101010');
------------ Clients.Users ------------

------------ Clients.Clients ------------
CREATE TABLE [Clients].[Clients]
(
    ClientId INT IDENTITY(1,1) NOT NULL,
    UserId INT NOT NULL,
    CONSTRAINT PK_Clients_ClientId PRIMARY KEY(ClientId),
    CONSTRAINT FK_Clients_Users_UserId FOREIGN KEY(UserId) REFERENCES Clients.Users(UserId),
);

EXEC sys.sp_addextendedproperty
    @name=N'TableDescription',
    @value=N'Table is used for storing client information.',
    @level0type=N'SCHEMA',
    @level0name=N'Clients',
    @level1type=N'TABLE',
    @level1name=N'Clients';

INSERT INTO [Clients].[Clients]
    (UserId)
VALUES
    (1);
------------ Clients.Clients ------------

------------ Cards.Cards ------------
CREATE TABLE [Cards].[Cards]
(
    CardId INT IDENTITY(1,1) NOT NULL,
    PermamentAccountNumber NVARCHAR(19) NOT NULL,
    CVV NVARCHAR(3) NOT NULL,
    ValidationDate DATETIME2 NOT NULL,
    [State] TINYINT NOT NULL CONSTRAINT DF_Accounts_State DEFAULT 0,
    CONSTRAINT PK_Cards_CardId PRIMARY KEY(CardId),
);

EXEC sys.sp_addextendedproperty
    @name=N'TableDescription',
    @value=N'Table is used for storing card information.',
    @level0type=N'SCHEMA',
    @level0name=N'Cards',
    @level1type=N'TABLE',
    @level1name=N'Cards';


INSERT INTO Cards.Cards
    (PermamentAccountNumber, CVV, ValidationDate)
VALUES('4938 3108 1742 9022  ', '111', '2031-12-31');
GO

CREATE TRIGGER tr_ForDeleteCard
ON Cards.Cards
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if any cards being deleted are still valid (not expired)
    IF EXISTS (
        SELECT 1 
        FROM DELETED 
        WHERE ValidationDate >= CAST(GETDATE() AS DATE)
    )
    BEGIN
        -- Throw a proper error instead of using PRINT and ROLLBACK
        THROW 50001, 'Cannot delete card(s): One or more cards are still valid and have not expired.', 1;
        RETURN;
    END
    
    -- If all cards are expired, proceed with deletion
    DELETE c
    FROM Cards.Cards c
    INNER JOIN DELETED d ON c.CardId = d.CardId;
END
GO


DELETE FROM Cards.Cards WHERE CardId = 1;
------------ Cards.Cards ------------

------------ Accounts.Accounts ------------
CREATE TABLE [Accounts].[Accounts]
(
    AccountId INT IDENTITY(1,1) NOT NULL,
    IBAN NVARCHAR(34) NOT NULL,
    Balance MONEY NOT NULL,
    BankId INT NOT NULL,
    ClientId INT NOT NULL,
    AccountTypeId INT NOT NULL,
    CurrencyId INT NOT NULL,
    CardId INT NOT NULL,
    [State] TINYINT NOT NULL CONSTRAINT DF_Accounts_State DEFAULT 1,
    CONSTRAINT PK_Accounts_AccountId PRIMARY KEY(AccountId),
    CONSTRAINT FK_Accouts_Banks_BankId FOREIGN KEY(BankId) REFERENCES Banks.Banks(BankId),
    CONSTRAINT FK_Accouts_Clients_ClientId FOREIGN KEY(ClientId) REFERENCES Clients.Clients(ClientId),
    CONSTRAINT FK_Accouts_AccountTypes_AccountTypeId FOREIGN KEY(AccountTypeId) REFERENCES Accounts.AccountTypes(AccountTypeId),
    CONSTRAINT FK_Accouts_Resources_CurrencyId FOREIGN KEY(CurrencyId) REFERENCES Resources.Currencies(CurrencyId),
    CONSTRAINT FK_Accouts_Cards_CardId FOREIGN KEY(CardId) REFERENCES Cards.Cards(CardId),
);

INSERT INTO [Accounts].[Accounts]
    (IBAN, Balance, BankId, ClientId, AccountTypeId, CurrencyId, CardId)
VALUES('IT72W0300203280817392947896', 12000, 1, 1, 1, 1, 1);
GO

CREATE TRIGGER TR_AfterInsertAccount
ON [Accounts].[Accounts]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Only proceed if there are inserted records
    IF NOT EXISTS (SELECT 1 FROM INSERTED)
        RETURN;
    
    -- Check if Transactions table exists using sys.objects (more efficient than INFORMATION_SCHEMA)
    IF OBJECT_ID('[Accounts].[Transactions]', 'U') IS NOT NULL
    BEGIN
        -- Insert welcome transaction for each new account
        INSERT INTO [Accounts].[Transactions]
            ([AccountId]
            ,[ReciverIban]  -- Fixed column name to match table definition
            ,[Amount]
            ,[CurrencyId]   -- Added missing CurrencyId (required field)
            ,[CreatedOn])
        SELECT 
            i.AccountId,
            'BG18REVLL122223233' AS ReciverIban,
            5.00 AS Amount,
            i.CurrencyId,  -- Use the currency from the account
            GETDATE() AS CreatedOn
        FROM INSERTED i;
    END
END
GO
------------ Accounts.Accounts ------------

------------ Accounts.Transactions ------------
CREATE TABLE [Accounts].[Transactions]
(
    TransactionId INT IDENTITY(1,1) NOT NULL,
    AccountId INT NOT NULL,
    ReciverIban NVARCHAR(34) NOT NULL,
    Amount MONEY NOT NULL,
    CurrencyId INT NOT NULL,
    CreatedOn DATETIME2 NOT NULL CONSTRAINT DF_Transactions_CreatedOn Default GETDATE(),
    [State] TINYINT NOT NULL CONSTRAINT DF_Transactions_State DEFAULT 1,
    CONSTRAINT PK_Transactions_TransactionId PRIMARY KEY(TransactionId),
    CONSTRAINT FK_Transactions_Accounts_AccountId FOREIGN KEY(AccountId) REFERENCES Accounts.Accounts(AccountId),
    CONSTRAINT FK_Accouts_Resources_CurrencyId FOREIGN KEY(CurrencyId) REFERENCES Resources.Currencies(CurrencyId),
);


INSERT INTO [Accounts].[Transactions]
    (AccountId, ReciverIban, Amount, CurrencyId, CreatedOn)
VALUES(1, 'HN50IKQT54288734823397434219', 100, 1, '1232133');
GO
------------ Accounts.Transactions ------------


------------ SP ------------
CREATE PROCEDURE ups_GetTransactionsToBGN(@iAccountId INT)
AS
BEGIN
    SELECT
        aa.IBAN AS SenderIban,
        t.ReciverIban,
        t.Amount,
        t.CreatedOn
    FROM [Accounts].[Transactions] AS t
        INNER JOIN [Accounts].[Accounts] AS aa ON t.AccountId = aa.AccountId
    WHERE aa.AccountId = @iAccountId AND aa.[State] = 1;
END
------------ SP ------------