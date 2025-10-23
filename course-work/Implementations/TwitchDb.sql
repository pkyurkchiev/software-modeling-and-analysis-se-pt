CREATE TABLE [User] (
    UserID INT IDENTITY PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    JoinDate DATETIME DEFAULT GETDATE(),
    IsStreamer BIT DEFAULT 0
);

CREATE TABLE Channel (
    ChannelID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(255),
    FollowersCount INT DEFAULT 0,
    UserID INT NOT NULL UNIQUE,
    FOREIGN KEY (UserID) REFERENCES [User](UserID)
);

CREATE TABLE Subscription (
    SubscriptionID INT IDENTITY PRIMARY KEY,
    Tier INT CHECK (Tier BETWEEN 1 AND 3),
    Price DECIMAL(6,2),
    StartDate DATE DEFAULT GETDATE(),
    EndDate DATE NULL,
    IsActive BIT DEFAULT 1,
    UserID INT NOT NULL,
    ChannelID INT NOT NULL,
    FOREIGN KEY (UserID) REFERENCES [User](UserID),
    FOREIGN KEY (ChannelID) REFERENCES Channel(ChannelID)
);

CREATE TABLE Donation (
    DonationID INT IDENTITY PRIMARY KEY,
    UserID INT NOT NULL,
    ChannelID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    Currency NVARCHAR(10),
    Message NVARCHAR(255),
    DonatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (UserID) REFERENCES [User](UserID),
    FOREIGN KEY (ChannelID) REFERENCES Channel(ChannelID)
);

CREATE TABLE Category (
    CategoryID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    GameType NVARCHAR(100)
);

CREATE TABLE Stream (
    StreamID INT IDENTITY PRIMARY KEY,
    ChannelID INT NOT NULL,
    CategoryID INT,
    Title NVARCHAR(150),
    StartTime DATETIME DEFAULT GETDATE(),
    EndTime DATETIME NULL,
    ViewerCount INT DEFAULT 0,
    FOREIGN KEY (ChannelID) REFERENCES Channel(ChannelID),
    FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID)
);

CREATE TABLE Clip (
    ClipID INT IDENTITY PRIMARY KEY,
    StreamID INT NOT NULL,
    Title NVARCHAR(150),
    Duration INT,
    Views INT DEFAULT 0,
    URL NVARCHAR(255),
    FOREIGN KEY (StreamID) REFERENCES Stream(StreamID)
);

CREATE TABLE ChatMessage (
    MessageID INT IDENTITY PRIMARY KEY,
    UserID INT NOT NULL,
    StreamID INT NOT NULL,
    Content NVARCHAR(255),
    SentAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (UserID) REFERENCES [User](UserID),
    FOREIGN KEY (StreamID) REFERENCES Stream(StreamID)
);

CREATE TABLE Follow (
    FollowerID INT NOT NULL,
    FollowedID INT NOT NULL,
    FollowDate DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (FollowerID, FollowedID),
    FOREIGN KEY (FollowerID) REFERENCES [User](UserID),
    FOREIGN KEY (FollowedID) REFERENCES [User](UserID)
);



--примерни данни
INSERT INTO [User] (Username, Email, IsStreamer) VALUES
('Streamer1', 'streamer1@mail.com', 1),
('ViewerA', 'viewerA@mail.com', 0),
('ViewerB', 'viewerB@mail.com', 0);

INSERT INTO Channel (Name, Description, UserID)
VALUES ('Streamer1 Channel', 'Gameplay and fun', 1);

INSERT INTO Category (Name, GameType)
VALUES ('Action Games', 'FPS');

INSERT INTO Stream (ChannelID, CategoryID, Title, ViewerCount)
VALUES (1, 1, 'Live Stream #1', 250);

INSERT INTO Subscription (Tier, Price, UserID, ChannelID)
VALUES (1, 4.99, 2, 1),
       (2, 9.99, 3, 1);

INSERT INTO Donation (UserID, ChannelID, Amount, Currency, Message)
VALUES (2, 1, 5.00, 'USD', 'W STREAM!'),
       (3, 1, 10.00, 'USD', 'L STREAM');


--ФУНКЦИИ:
-- Изчисляване на общите донейти за даден канал
CREATE FUNCTION GetTotalDonations(@ChannelID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Total DECIMAL(10,2);
    SELECT @Total = SUM(Amount)
    FROM Donation
    WHERE ChannelID = @ChannelID;
    RETURN ISNULL(@Total, 0);
END;
GO

-- Изчисляване на общ брой абонаменти за даден потребител
CREATE FUNCTION GetUserSubscriptions(@UserID INT)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT;
    SELECT @Count = COUNT(*)
    FROM Subscription
    WHERE UserID = @UserID AND IsActive = 1;
    RETURN ISNULL(@Count, 0);
END;
GO


SELECT dbo.GetTotalDonations(1) AS TotalDonations;


--Тригери:
-- деактивиране на Subscription след изтичане
CREATE TRIGGER TR_DeactivateSubscription
ON Subscription
AFTER UPDATE
AS
BEGIN
    UPDATE Subscription
    SET IsActive = 0
    WHERE EndDate < GETDATE();
END;
GO

-- При донейт да се вдига фолоуър каунт
CREATE TRIGGER TR_AddFollowerCount
ON Donation
AFTER INSERT
AS
BEGIN
    UPDATE Channel
    SET FollowersCount = FollowersCount + 1
    WHERE ChannelID IN (SELECT ChannelID FROM inserted);
END;
GO



--СЪХРАНЕНИ ПРОЦЕДУРИ:
--  Добавяне на Donation
CREATE PROCEDURE AddDonation
    @UserID INT,
    @ChannelID INT,
    @Amount DECIMAL(10,2),
    @Currency NVARCHAR(10),
    @Message NVARCHAR(255)
AS
BEGIN
    INSERT INTO Donation (UserID, ChannelID, Amount, Currency, Message)
    VALUES (@UserID, @ChannelID, @Amount, @Currency, @Message);
END;
GO

-- Актуализиране на броя последователи в Channel
CREATE PROCEDURE UpdateFollowers
    @ChannelID INT,
    @NewCount INT
AS
BEGIN
    UPDATE Channel
    SET FollowersCount = @NewCount
    WHERE ChannelID = @ChannelID;
END;
GO


EXECUTE AddDonation 
    @UserID = 3, 
    @ChannelID = 1, 
    @Amount = 25.00, 
    @Currency = 'USD', 
    @Message = 'Keep up the good work!';

	select * From dbo.Donation
