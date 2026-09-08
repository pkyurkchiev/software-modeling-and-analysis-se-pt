/* =====================================================================================
   RevoluteBankingDB - допълнение
   1) Потребителски типове (alias types + табличен тип за списък)
   2) Помощни таблици и процедури
   3) Два SQL Server Agent job-а
   4) Примери за употреба
   ===================================================================================== */

USE RevoluteBankingDB
GO

/* =====================================================================================
   0. Схема за одит / служебни обекти
   ===================================================================================== */
IF SCHEMA_ID('Audit') IS NULL
    EXEC('CREATE SCHEMA Audit');
GO


/* =====================================================================================
   1. ПОТРЕБИТЕЛСКИ ТИПОВЕ (User-Defined Types)
   ===================================================================================== */

-- 1.1 Alias типове - едно определение, ползвано на много места.
--     Ако утре IBAN стане 40 символа, се сменя само тук.
IF TYPE_ID('Accounts.IBANType') IS NULL
    CREATE TYPE [Accounts].[IBANType] FROM NVARCHAR(34) NOT NULL;
GO

IF TYPE_ID('Currencies.CurrencyCodeType') IS NULL
    CREATE TYPE [Currencies].[CurrencyCodeType] FROM VARCHAR(3) NOT NULL;
GO

IF TYPE_ID('Clients.NationalIdType') IS NULL
    CREATE TYPE [Clients].[NationalIdType] FROM NVARCHAR(15) NOT NULL;
GO


-- 1.2 Табличен тип (User-Defined Table Type) - типът "обект за списък".
--     Подава се като TVP параметър на процедура и позволява да изпратиш
--     наведнъж 100 превода с едно извикване вместо 100 отделни INSERT-а.
IF TYPE_ID('Accounts.TransactionListType') IS NULL
BEGIN
    CREATE TYPE [Accounts].[TransactionListType] AS TABLE
    (
        RowNo INT IDENTITY(1,1) NOT NULL,
        ReciverIban [Accounts].[IBANType],              -- alias типът се ползва тук
        Amount MONEY NOT NULL,
        CurrencyCode [Currencies].[CurrencyCodeType],   -- и тук
        [Description] NVARCHAR(200) NULL,
        PRIMARY KEY CLUSTERED (RowNo),
        CHECK (Amount > 0)
    );
END
GO

-- 1.3 Табличен тип за списък от идентификатори - удобен за "IN (списък)" сценарии
IF TYPE_ID('Clients.IdListType') IS NULL
BEGIN
    CREATE TYPE [Clients].[IdListType] AS TABLE
    (
        Id INT NOT NULL PRIMARY KEY
    );
END
GO


-- 1.4 Прилагане на alias типовете върху вече съществуващите колони.
--     Оттук нататък типът има реални зависимости и SQL Server няма да позволи
--     да го изтриеш, докато не отпаднат всички колони и параметри, които го ползват.

-- Accounts.Accounts.IBAN - няма индекс, минава директно
ALTER TABLE [Accounts].[Accounts]
    ALTER COLUMN IBAN [Accounts].[IBANType];
GO

-- Accounts.Transactions.ReciverIban
ALTER TABLE [Accounts].[Transactions]
    ALTER COLUMN ReciverIban [Accounts].[IBANType];
GO

-- Currencies.Currencies.Code - има UNIQUE, затова се сваля и се връща
ALTER TABLE [Currencies].[Currencies] DROP CONSTRAINT UQ_Currencies_Code;
GO
ALTER TABLE [Currencies].[Currencies]
    ALTER COLUMN Code [Currencies].[CurrencyCodeType];
GO
ALTER TABLE [Currencies].[Currencies]
    ADD CONSTRAINT UQ_Currencies_Code UNIQUE(Code);
GO

-- Clients.Users.NationalIdentifierNumber - същият сценарий
ALTER TABLE [Clients].[Users] DROP CONSTRAINT UQ_Clients_NationalIdentifierNumber;
GO
ALTER TABLE [Clients].[Users]
    ALTER COLUMN NationalIdentifierNumber [Clients].[NationalIdType];
GO
ALTER TABLE [Clients].[Users]
    ADD CONSTRAINT UQ_Clients_NationalIdentifierNumber UNIQUE(NationalIdentifierNumber);
GO


/* =====================================================================================
   2. ПОМОЩНИ ТАБЛИЦИ
   ===================================================================================== */

-- 2.1 Лог за изпълненията на job-овете
IF OBJECT_ID('[Audit].[JobRunLog]', 'U') IS NULL
BEGIN
    CREATE TABLE [Audit].[JobRunLog]
    (
        JobRunLogId INT IDENTITY(1,1) NOT NULL,
        JobName NVARCHAR(128) NOT NULL,
        StartedOn DATETIME2 NOT NULL CONSTRAINT DF_JobRunLog_StartedOn DEFAULT SYSDATETIME(),
        FinishedOn DATETIME2 NULL,
        RowsAffected INT NULL,
        IsSuccess BIT NOT NULL CONSTRAINT DF_JobRunLog_IsSuccess DEFAULT 1,
        ErrorMessage NVARCHAR(2000) NULL,
        CONSTRAINT PK_JobRunLog_JobRunLogId PRIMARY KEY (JobRunLogId)
    );
END
GO

-- 2.2 Архив на старите транзакции
IF OBJECT_ID('[Audit].[TransactionsArchive]', 'U') IS NULL
BEGIN
    CREATE TABLE [Audit].[TransactionsArchive]
    (
        TransactionId INT NOT NULL,
        AccountId INT NOT NULL,
        ReciverIban [Accounts].[IBANType],   -- alias типът се ползва и тук
        Amount MONEY NOT NULL,
        CurrencyId INT NOT NULL,
        CreatedOn DATETIME2 NOT NULL,
        [State] TINYINT NOT NULL,
        ArchivedOn DATETIME2 NOT NULL CONSTRAINT DF_TransactionsArchive_ArchivedOn DEFAULT SYSDATETIME(),
        CONSTRAINT PK_TransactionsArchive_TransactionId PRIMARY KEY (TransactionId)
    );
END
GO


/* =====================================================================================
   3. ПРОЦЕДУРИ, КОИТО JOB-ОВЕТЕ ИЗПЪЛНЯВАТ
   ===================================================================================== */

-- 3.1 Ежедневна поддръжка на картите:
--     изтеклите карти минават в State = 0, а сметките към тях се блокират (State = 2).
CREATE OR ALTER PROCEDURE [Cards].[USP_DeactivateExpiredCards]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @JobName NVARCHAR(128) = N'RevolutBank - Daily Card Maintenance';
    DECLARE @LogId INT, @Rows INT = 0;

    INSERT INTO [Audit].[JobRunLog] (JobName) VALUES (@JobName);
    SET @LogId = SCOPE_IDENTITY();

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE c
        SET c.[State] = 0
        FROM [Cards].[Cards] AS c
        WHERE c.ValidationDate < CAST(GETDATE() AS DATE)
          AND c.[State] <> 0;

        SET @Rows = @@ROWCOUNT;

        UPDATE a
        SET a.[State] = 2   -- 2 = временно блокирана сметка
        FROM [Accounts].[Accounts] AS a
        INNER JOIN [Cards].[Cards] AS c ON a.CardId = c.CardId
        WHERE c.[State] = 0
          AND a.[State] = 1;

        SET @Rows = @Rows + @@ROWCOUNT;

        COMMIT TRANSACTION;

        UPDATE [Audit].[JobRunLog]
        SET FinishedOn = SYSDATETIME(), RowsAffected = @Rows, IsSuccess = 1
        WHERE JobRunLogId = @LogId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        UPDATE [Audit].[JobRunLog]
        SET FinishedOn = SYSDATETIME(), IsSuccess = 0, ErrorMessage = ERROR_MESSAGE()
        WHERE JobRunLogId = @LogId;

        THROW;
    END CATCH
END
GO


-- 3.2 Седмично архивиране на транзакции по-стари от N месеца.
--     Работи на партиди, за да не заключи цялата таблица.
CREATE OR ALTER PROCEDURE [Accounts].[USP_ArchiveOldTransactions]
    @RetentionMonths INT = 24,
    @BatchSize INT = 5000
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @JobName NVARCHAR(128) = N'RevolutBank - Weekly Transaction Archiving';
    DECLARE @LogId INT, @Rows INT = 0, @BatchRows INT = 1;
    DECLARE @Cutoff DATETIME2 = DATEADD(MONTH, -@RetentionMonths, SYSDATETIME());

    INSERT INTO [Audit].[JobRunLog] (JobName) VALUES (@JobName);
    SET @LogId = SCOPE_IDENTITY();

    BEGIN TRY
        WHILE @BatchRows > 0
        BEGIN
            BEGIN TRANSACTION;

            DELETE TOP (@BatchSize)
            FROM [Accounts].[Transactions]
            OUTPUT deleted.TransactionId, deleted.AccountId, deleted.ReciverIban,
                   deleted.Amount, deleted.CurrencyId, deleted.CreatedOn, deleted.[State]
              INTO [Audit].[TransactionsArchive]
                   (TransactionId, AccountId, ReciverIban, Amount, CurrencyId, CreatedOn, [State])
            WHERE CreatedOn < @Cutoff;

            SET @BatchRows = @@ROWCOUNT;
            SET @Rows = @Rows + @BatchRows;

            COMMIT TRANSACTION;
        END

        UPDATE [Audit].[JobRunLog]
        SET FinishedOn = SYSDATETIME(), RowsAffected = @Rows, IsSuccess = 1
        WHERE JobRunLogId = @LogId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        UPDATE [Audit].[JobRunLog]
        SET FinishedOn = SYSDATETIME(), IsSuccess = 0, ErrorMessage = ERROR_MESSAGE()
        WHERE JobRunLogId = @LogId;

        THROW;
    END CATCH
END
GO


/* =====================================================================================
   4. ОБЕКТИ, КОИТО ПОЛЗВАТ ТИПОВЕТЕ
   ===================================================================================== */

-- 4.1 Скаларна функция с alias тип като параметър:
--     проверява дали IBAN-ът е на сметка в нашата банка
CREATE OR ALTER FUNCTION [Accounts].[UFN_IsInternalIban]
    (@Iban [Accounts].[IBANType])
RETURNS BIT
AS
BEGIN
    DECLARE @Result BIT = 0;

    IF EXISTS (SELECT 1 FROM [Accounts].[Accounts] WHERE IBAN = @Iban AND [State] = 1)
        SET @Result = 1;

    RETURN @Result;
END
GO


-- 4.2 Табличната функция приема списък от клиенти чрез Clients.IdListType
CREATE OR ALTER FUNCTION [Clients].[UFN_GetAccountsForClients]
    (@ClientIds [Clients].[IdListType] READONLY)
RETURNS TABLE
AS
RETURN
(
    SELECT
        cl.ClientId,
        u.FirstName + N' ' + u.LastName AS ClientName,
        u.NationalIdentifierNumber,
        a.AccountId,
        a.IBAN,
        a.Balance,
        cur.Code AS CurrencyCode,
        at.[Name] AS AccountType,
        a.[State]
    FROM @ClientIds AS ids
    INNER JOIN [Clients].[Clients] AS cl ON cl.ClientId = ids.Id
    INNER JOIN [Clients].[Users] AS u ON u.UserId = cl.UserId
    INNER JOIN [Accounts].[Accounts] AS a ON a.ClientId = cl.ClientId
    INNER JOIN [Currencies].[Currencies] AS cur ON cur.CurrencyId = a.CurrencyId
    INNER JOIN [Accounts].[AccountTypes] AS at ON at.AccountTypeId = a.AccountTypeId
);
GO


-- 4.3 Търсене по ЕГН - параметърът е Clients.NationalIdType
CREATE OR ALTER PROCEDURE [Clients].[USP_GetClientByNationalId]
    @NationalId [Clients].[NationalIdType]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.UserId,
        u.FirstName,
        u.LastName,
        u.NationalIdentifierNumber,
        cl.ClientId,
        COUNT(a.AccountId) AS AccountsCount,
        SUM(a.Balance) AS TotalBalance
    FROM [Clients].[Users] AS u
    LEFT JOIN [Clients].[Clients] AS cl ON cl.UserId = u.UserId
    LEFT JOIN [Accounts].[Accounts] AS a ON a.ClientId = cl.ClientId AND a.[State] = 1
    WHERE u.NationalIdentifierNumber = @NationalId
    GROUP BY u.UserId, u.FirstName, u.LastName, u.NationalIdentifierNumber, cl.ClientId;
END
GO


-- 4.4 Процедура с табличния тип (TVP)
CREATE OR ALTER PROCEDURE [Accounts].[USP_InsertTransactions]
    @iAccountId INT,
    @Transactions [Accounts].[TransactionListType] READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM @Transactions)
        THROW 50010, N'Списъкът с преводи е празен.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Balance MONEY, @State TINYINT, @CardId INT;

        SELECT @Balance = a.Balance, @State = a.[State], @CardId = a.CardId
        FROM [Accounts].[Accounts] AS a WITH (UPDLOCK, ROWLOCK)
        WHERE a.AccountId = @iAccountId;

        IF @Balance IS NULL
            THROW 50011, N'Сметката не съществува.', 1;

        IF @State <> 1
            THROW 50012, N'Сметката не е активна.', 1;

        IF EXISTS (SELECT 1 FROM [Cards].[Cards]
                   WHERE CardId = @CardId AND ValidationDate < CAST(GETDATE() AS DATE))
            THROW 50013, N'Картата към сметката е изтекла.', 1;

        -- непозната валута в списъка
        IF EXISTS (SELECT 1
                   FROM @Transactions AS t
                   LEFT JOIN [Currencies].[Currencies] AS c ON c.Code = t.CurrencyCode
                   WHERE c.CurrencyId IS NULL)
            THROW 50014, N'В списъка има непознат валутен код.', 1;

        DECLARE @Total MONEY = (SELECT SUM(Amount) FROM @Transactions);

        IF @Balance < @Total
            THROW 50015, N'Недостатъчна наличност по сметката.', 1;

        INSERT INTO [Accounts].[Transactions]
            (AccountId, ReciverIban, Amount, CurrencyId, CreatedOn)
        SELECT @iAccountId, t.ReciverIban, t.Amount, c.CurrencyId, SYSDATETIME()
        FROM @Transactions AS t
        INNER JOIN [Currencies].[Currencies] AS c ON c.Code = t.CurrencyCode
        ORDER BY t.RowNo;

        UPDATE [Accounts].[Accounts]
        SET Balance = Balance - @Total
        WHERE AccountId = @iAccountId;

        -- вътрешните получатели се заверяват веднага; функцията ползва IBANType
        UPDATE a
        SET a.Balance = a.Balance + t.Amount
        FROM [Accounts].[Accounts] AS a
        INNER JOIN (
            SELECT ReciverIban, SUM(Amount) AS Amount
            FROM @Transactions
            WHERE [Accounts].[UFN_IsInternalIban](ReciverIban) = 1
            GROUP BY ReciverIban
        ) AS t ON t.ReciverIban = a.IBAN;

        COMMIT TRANSACTION;

        SELECT @Total AS TotalTransferred,
               (SELECT COUNT(*) FROM @Transactions) AS TransactionsCount;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO


/* =====================================================================================
   5. SQL SERVER AGENT JOBS
   Изисква стартирана услуга SQL Server Agent (няма я в Express edition).
   ===================================================================================== */

USE [msdb]
GO

/* ---------- JOB 1: RevolutBank - Daily Card Maintenance (всеки ден в 02:00) ---------- */
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'RevolutBank - Daily Card Maintenance')
    EXEC msdb.dbo.sp_delete_job
        @job_name = N'RevolutBank - Daily Card Maintenance',
        @delete_unused_schedule = 1;
GO

EXEC msdb.dbo.sp_add_job
    @job_name = N'RevolutBank - Daily Card Maintenance',
    @enabled = 1,
    @description = N'Деактивира изтеклите карти и блокира сметките, останали без валидна карта.',
    @category_name = N'Database Maintenance',
    @notify_level_eventlog = 2;   -- запис в Event Log само при грешка
GO

EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'RevolutBank - Daily Card Maintenance',
    @step_name = N'Deactivate expired cards',
    @step_id = 1,
    @subsystem = N'TSQL',
    @database_name = N'RevoluteBankingDB',
    @command = N'EXEC [Cards].[USP_DeactivateExpiredCards];',
    @retry_attempts = 2,
    @retry_interval = 5,          -- минути между опитите
    @on_success_action = 1,       -- 1 = край с успех
    @on_fail_action = 2;          -- 2 = край с грешка
GO

EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'RevolutBank - Every day 02:00',
    @enabled = 1,
    @freq_type = 4,               -- 4 = дневно
    @freq_interval = 1,           -- през 1 ден
    @active_start_time = 020000;  -- 02:00:00
GO

EXEC msdb.dbo.sp_attach_schedule
    @job_name = N'RevolutBank - Daily Card Maintenance',
    @schedule_name = N'RevolutBank - Every day 02:00';
GO

EXEC msdb.dbo.sp_add_jobserver
    @job_name = N'RevolutBank - Daily Card Maintenance',
    @server_name = N'(LOCAL)';
GO


/* ---------- JOB 2: RevolutBank - Weekly Transaction Archiving (неделя 03:00) ---------- */
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'RevolutBank - Weekly Transaction Archiving')
    EXEC msdb.dbo.sp_delete_job
        @job_name = N'RevolutBank - Weekly Transaction Archiving',
        @delete_unused_schedule = 1;
GO

EXEC msdb.dbo.sp_add_job
    @job_name = N'RevolutBank - Weekly Transaction Archiving',
    @enabled = 1,
    @description = N'Премества транзакции по-стари от 24 месеца в Audit.TransactionsArchive и обновява статистиките.',
    @category_name = N'Database Maintenance',
    @notify_level_eventlog = 2;
GO

EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'RevolutBank - Weekly Transaction Archiving',
    @step_name = N'Archive transactions older than 24 months',
    @step_id = 1,
    @subsystem = N'TSQL',
    @database_name = N'RevoluteBankingDB',
    @command = N'EXEC [Accounts].[USP_ArchiveOldTransactions] @RetentionMonths = 24, @BatchSize = 5000;',
    @retry_attempts = 1,
    @retry_interval = 10,
    @on_success_action = 3,       -- 3 = премини към следващата стъпка
    @on_fail_action = 2;
GO

EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'RevolutBank - Weekly Transaction Archiving',
    @step_name = N'Update statistics',
    @step_id = 2,
    @subsystem = N'TSQL',
    @database_name = N'RevoluteBankingDB',
    @command = N'EXEC sp_updatestats;',
    @on_success_action = 1,
    @on_fail_action = 2;
GO

EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'RevolutBank - Every Sunday 03:00',
    @enabled = 1,
    @freq_type = 8,               -- 8 = седмично
    @freq_interval = 1,           -- 1 = неделя (битова маска: 1=Nd,2=Pn,4=Vt,8=Sr,16=Ch,32=Pt,64=Sb)
    @freq_recurrence_factor = 1,  -- през 1 седмица
    @active_start_time = 030000;  -- 03:00:00
GO

EXEC msdb.dbo.sp_attach_schedule
    @job_name = N'RevolutBank - Weekly Transaction Archiving',
    @schedule_name = N'RevolutBank - Every Sunday 03:00';
GO

EXEC msdb.dbo.sp_add_jobserver
    @job_name = N'RevolutBank - Weekly Transaction Archiving',
    @server_name = N'(LOCAL)';
GO


/* =====================================================================================
   6. ПРИМЕРИ ЗА ДЕМОНСТРАЦИЯ
   ===================================================================================== */

USE RevoluteBankingDB
GO

/* ---------- Пример 1: масово вкарване на преводи чрез табличния тип ---------- */
DECLARE @Batch [Accounts].[TransactionListType];

INSERT INTO @Batch (ReciverIban, Amount, CurrencyCode, [Description])
VALUES (N'HN50IKQT54288734823397434301', 250.00, 'BGN', N'Наем'),
       (N'HN50IKQT54288734823397434302',  75.50, 'BGN', N'Ток'),
       (N'HN50IKQT54288734823397434303', 120.00, 'EUR', N'Абонамент');

SELECT * FROM @Batch;   -- как изглежда списъкът преди изпращане

EXEC [Accounts].[USP_InsertTransactions]
     @iAccountId = 1,
     @Transactions = @Batch;
GO

SELECT AccountId, ReciverIban, Amount, CurrencyId, CreatedOn
FROM [Accounts].[Transactions]
WHERE AccountId = 1
ORDER BY TransactionId DESC;
GO


/* ---------- Пример 2: как типът пази целостта (очаквана грешка) ---------- */
BEGIN TRY
    DECLARE @Bad [Accounts].[TransactionListType];

    -- CHECK (Amount > 0) в самия тип отхвърля реда още при пълненето
    INSERT INTO @Bad (ReciverIban, Amount, CurrencyCode)
    VALUES (N'HN50IKQT54288734823397434399', -10.00, 'BGN');
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrNo, ERROR_MESSAGE() AS ErrMsg;
END CATCH
GO

-- Недостатъчна наличност -> процедурата хвърля 50015 и нищо не се записва
BEGIN TRY
    DECLARE @TooBig [Accounts].[TransactionListType];
    INSERT INTO @TooBig (ReciverIban, Amount, CurrencyCode)
    VALUES (N'HN50IKQT54288734823397434400', 9999999.00, 'BGN');

    EXEC [Accounts].[USP_InsertTransactions] @iAccountId = 1, @Transactions = @TooBig;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrNo, ERROR_MESSAGE() AS ErrMsg;
END CATCH
GO


/* ---------- Пример 3: ръчно стартиране на job-овете и проверка на резултата ---------- */

-- преди изпълнението
SELECT CardId, PermamentAccountNumber, ValidationDate, [State] FROM [Cards].[Cards];

EXEC msdb.dbo.sp_start_job @job_name = N'RevolutBank - Daily Card Maintenance';
WAITFOR DELAY '00:00:05';

-- след изпълнението: изтеклите карти вече са State = 0
SELECT CardId, PermamentAccountNumber, ValidationDate, [State] FROM [Cards].[Cards];

-- собственият лог на процедурата
SELECT TOP (10) JobName, StartedOn, FinishedOn, RowsAffected, IsSuccess, ErrorMessage
FROM [Audit].[JobRunLog]
ORDER BY JobRunLogId DESC;

-- историята, която пази самият Agent
SELECT j.name AS JobName,
       h.step_name,
       h.run_date,
       h.run_time,
       h.run_duration,
       CASE h.run_status WHEN 0 THEN N'Failed'
                         WHEN 1 THEN N'Succeeded'
                         WHEN 2 THEN N'Retry'
                         WHEN 3 THEN N'Canceled'
                         ELSE N'In progress' END AS RunStatus,
       h.message
FROM msdb.dbo.sysjobhistory AS h
INNER JOIN msdb.dbo.sysjobs AS j ON j.job_id = h.job_id
WHERE j.name LIKE N'RevolutBank%'
ORDER BY h.run_date DESC, h.run_time DESC;
GO


/* ---------- Пример 4: списък от клиенти чрез Clients.IdListType ---------- */
DECLARE @Clients [Clients].[IdListType];
INSERT INTO @Clients (Id) VALUES (1), (2);

SELECT * FROM [Clients].[UFN_GetAccountsForClients](@Clients)
ORDER BY ClientId, AccountId;
GO

-- търсене по ЕГН; параметърът е Clients.NationalIdType
EXEC [Clients].[USP_GetClientByNationalId] @NationalId = N'8901101010';
GO

-- функцията с IBANType: вътрешен срещу външен IBAN
SELECT [Accounts].[UFN_IsInternalIban](N'IT72W0300203280817392947896') AS IsInternal_Own,
       [Accounts].[UFN_IsInternalIban](N'HN50IKQT54288734823397434219') AS IsInternal_Foreign;
GO


/* ---------- Справка 1: какви типове съм създал ---------- */
SELECT t.name AS TypeName,
       SCHEMA_NAME(t.schema_id) AS SchemaName,
       t.is_table_type,
       TYPE_NAME(t.system_type_id) AS BaseType,
       t.max_length,
       t.is_nullable
FROM sys.types AS t
WHERE t.is_user_defined = 1
ORDER BY t.is_table_type, t.name;
GO


/* ---------- Справка 2: къде точно се ползва всеки тип ---------- */
-- колони
SELECT SCHEMA_NAME(t.schema_id) + '.' + t.name AS UserType,
       'COLUMN' AS UsedIn,
       SCHEMA_NAME(o.schema_id) + '.' + o.name + '.' + c.name AS ObjectName
FROM sys.columns AS c
INNER JOIN sys.types AS t ON t.user_type_id = c.user_type_id AND t.is_user_defined = 1
INNER JOIN sys.objects AS o ON o.object_id = c.object_id
WHERE o.is_ms_shipped = 0

UNION ALL

-- параметри на процедури и функции
SELECT SCHEMA_NAME(t.schema_id) + '.' + t.name,
       'PARAMETER',
       SCHEMA_NAME(o.schema_id) + '.' + o.name + ' ' + p.name
FROM sys.parameters AS p
INNER JOIN sys.types AS t ON t.user_type_id = p.user_type_id AND t.is_user_defined = 1
INNER JOIN sys.objects AS o ON o.object_id = p.object_id
WHERE o.is_ms_shipped = 0
ORDER BY UserType, UsedIn, ObjectName;
GO
