CREATE DATABASE PatreonDB
GO

USE PatreonDB
GO

CREATE SCHEMA Users
CREATE SCHEMA Creators /* Contains external profiles too */
CREATE SCHEMA Subscriptions /* Contains tiers too */
CREATE SCHEMA Content /* Contains content types and individual purchases too */
GO

--------------- Users.Users ---------------
CREATE TABLE [Users].[Users]
(
	UserId INT IDENTITY(1, 1) NOT NULL,
	EMail NVARCHAR(254) NOT NULL,
	Username NVARCHAR(150) NOT NULL,
	Password BINARY(60) NOT NULL, /* BCrypt size */
	RegistrationDate DATETIME NOT NULL DEFAULT GETDATE(),

	CONSTRAINT PK_Users_UserId PRIMARY KEY(UserId),
	CONSTRAINT UQ_Users_EMail UNIQUE(EMail),
);

INSERT INTO [Users].[Users]
	(UserId, EMail, Username, Password)
VALUES 
    (1, 'petar.kostov@example.com', 'PetarKostov', CONVERT(BINARY(60), 'PetarKostov123')),
    (2, 'ivan.kadikyanov@example.com', 'IvanKadikyanov', CONVERT(BINARY(60), 'IvanKadikyanov123')),
    (3, 'nedalin.bogdanov@example.com', 'NedalinBogdanov', CONVERT(BINARY(60), 'NedalinBogdanov123')),
    (4, 'bozhidar.nikolov@example.com', 'BozhidarNikolov', CONVERT(BINARY(60), 'BozhidarNikolov123')),
    (5, 'stefan.dimitrov@example.com', 'StefanDimitrov', CONVERT(BINARY(60), 'StefanDimitrov123'));

GO
--------------- Users.Users ---------------


--------------- Creators.Creators ----------------
CREATE TABLE [Creators].[Creators]
(
	CreatorId INT IDENTITY(1, 1) NOT NULL,
	UserId INT NOT NULL,
	URL NVARCHAR(150) NOT NULL, /* as in https://www.patreon.com/c/{URL} */
	Description NVARCHAR(150) NOT NULL,
	IsPublic BIT NOT NULL DEFAULT 0,
	IsNSFW BIT NOT NULL DEFAULT 0,

	CONSTRAINT PK_Creators_CreatorId PRIMARY KEY(CreatorId),
	CONSTRAINT FK_Users_Creators_UserId FOREIGN KEY(UserId) REFERENCES Users.Users(UserId),
	CONSTRAINT UQ_Creators_UserId UNIQUE(UserId)
);

INSERT INTO [Creators].[Creators]
	(CreatorId, UserId, URL, Description)
VALUES 
    (1, 1, 'https://www.patreon.com/c/petar_kostov_creator', 'Petar Kostov Art Studio'),
    (2, 2, 'https://www.patreon.com/c/ivan_kadikyanov_creator', 'Ivan Kadikyanov Photography'),
    (3, 3, 'https://www.patreon.com/c/nedalin_bogdanov_creator', 'Nedalin Bogdanov Digital Art'),
    (4, 4, 'https://www.patreon.com/c/bozhidar_nikolov_creator', 'Bozhidar Nikolov Craftwork'),
    (5, 5, 'https://www.patreon.com/c/stefan_dimitrov_creator', 'Stefan Dimitrov Music Studio');

	
GO
--------------- Creators.Creators ----------------


--------------- Creators.ExternalPlatforms ----------------
CREATE TABLE [Creators].[ExternalPlatforms]
(
	ExternalPlatformId INT IDENTITY(1, 1) NOT NULL,
	Name NVARCHAR(30) NOT NULL,
	PlatformURL VARCHAR(150) NOT NULL,
	ApiURL VARCHAR(250) NOT NULL,
	Icon VARCHAR(512) NOT NULL,
	
	CONSTRAINT PK_ExternalPlatforms_ExternalPlatformId PRIMARY KEY(ExternalPlatformId),
	CONSTRAINT UQ_ExternalPlatforms_Name UNIQUE(Name)
);

INSERT INTO [Creators].[ExternalPlatforms]
	(ExternalPlatformId, Name, PlatformURL, ApiURL, Icon)
VALUES 
    (1, 'YouTube', 'https://youtube.com', 'https://api.youtube.com', 'https://icon.com/youtube'),
    (2, 'Twitter', 'https://twitter.com', 'https://api.twitter.com', 'https://icon.com/twitter'),
    (3, 'Instagram', 'https://instagram.com', 'https://api.instagram.com', 'https://icon.com/instagram'),
    (4, 'Twitch', 'https://twitch.tv', 'https://api.twitch.tv', 'https://icon.com/twitch'),
    (5, 'Facebook', 'https://facebook.com', 'https://api.facebook.com', 'https://icon.com/facebook');
	
GO
--------------- Creators.ExternalPlatforms ----------------


--------------- Creators.ExternalProfiles ----------------
CREATE TABLE [Creators].[ExternalProfiles]
(
	ExternalPlatformId INT NOT NULL,
	CreatorId INT NOT NULL,
	ProfileURL NVARCHAR(250) NOT NULL,
	Token VARCHAR(250) NOT NULL,
	
	CONSTRAINT PK_ExternalProfiles_ExternalPlatformId_CreatorId PRIMARY KEY(ExternalPlatformId, CreatorId),
	CONSTRAINT FK_ExternalPlatform_ExternalProfiles_ExternalPlatformId FOREIGN KEY(ExternalPlatformId) REFERENCES Creators.ExternalPlatforms(ExternalPlatformId),
	CONSTRAINT FK_Creators_ExternalProfiles_CreatorId FOREIGN KEY(CreatorId) REFERENCES Creators.Creators(CreatorId)
);

INSERT INTO [Creators].[ExternalProfiles]
	(ExternalPlatformId, CreatorId, ProfileURL, Token)
VALUES 
    (1, 1, 'https://youtube.com/petarkostov', 'cf23df2207d99a74fbe169e3eba035e633b65d94'),
    (2, 2, 'https://twitter.com/ivankadikyanov', 'ad58cd1320e61a21467b7b43e5d0c7028ff236a8'),
    (3, 3, 'https://instagram.com/nedalinbogdanov', 'ff62bc71381d57b06ef273bcfd7124dd674f2589'),
    (4, 4, 'https://twitch.tv/bozhidarnikolov', '73c2e0998b9e1cc99a8a7b3514f75b7986b42ed1'),
    (5, 5, 'https://facebook.com/stefandimitrov', '5f25d5b9e19279b18fdf84653f3b54d8bc7cd923');

GO
--------------- Creators.ExternalProfiles ----------------


--------------- Subscriptions.Tiers ---------------
CREATE TABLE [Subscriptions].[SubscriptionTiers]
(
	SubscriptionTierId INT IDENTITY(1, 1) NOT NULL,
	CreatorId INT NOT NULL,
	Name NVARCHAR(50) NOT NULL,
	IsBilledPerUpload BIT NOT NULL DEFAULT 0, /* Billed monthly by default */
	SubscriberCountLimit INT DEFAULT NULL,
	
	CONSTRAINT PK_SubscriptionTiers_SubscriptionTierId PRIMARY KEY(SubscriptionTierId),
	CONSTRAINT FK_Creators_SubscriptionTiers_CreatorId FOREIGN KEY(CreatorId) REFERENCES Creators.Creators(CreatorId),
	CONSTRAINT UQ_SubscriptionTiers_CreatorId_Name UNIQUE(CreatorId, Name)
);

INSERT INTO [Subscriptions].[SubscriptionTiers]
	(SubscriptionTierId, CreatorId, Name, IsBilledPerUpload, SubscriberCountLimit)
VALUES 
    (1, 1, 'Basic Support', 0, NULL),
    (2, 1, 'Gold Membership', 0, 100),
    (3, 1, 'Silver Tier', 1, 200),
    (4, 1, 'VIP Access', 0, 10),
    (5, 1, 'Premium Content', 1, 25);
	
GO
--------------- Subscriptions.Tiers ---------------


--------------- Subscriptions.Subscriptions ---------------
CREATE TABLE [Subscriptions].[Subscriptions]
(
	SubscriptionId INT IDENTITY(1, 1) NOT NULL,
	UserId INT NOT NULL,
	CreatorId INT NOT NULL,
	SubscriptionTierId INT, /* Tier, if any */
	Active BIT NOT NULL DEFAULT 1,
	CustomPledge MONEY DEFAULT NULL, /* Custom Pledge, if any. Must be higher than Tier price. */
	MaxMonthlyCost MONEY DEFAULT NULL, /* Applicable when Tier is billed per upload. Should be higher than Tier price. */

	CONSTRAINT PK_Subscriptions_SubscriptionId PRIMARY KEY(SubscriptionId),
	CONSTRAINT FK_Users_Subscriptions_UserId FOREIGN KEY(UserId) REFERENCES Users.Users(UserId),
	CONSTRAINT FK_Creators_Subscriptions_CreatorId FOREIGN KEY(CreatorId) REFERENCES Creators.Creators(CreatorId),
	CONSTRAINT FK_SubscriptionTiers_Subscriptions_SubscriptionTierId FOREIGN KEY(SubscriptionTierId) REFERENCES Subscriptions.SubscriptionTiers(SubscriptionTierId)
);

INSERT INTO [Subscriptions].[Subscriptions]
	(SubscriptionId, UserId, CreatorId, SubscriptionTierId, Active, CustomPledge, MaxMonthlyCost)
VALUES 
    (1, 1, 1, 1, 1, 15.00, NULL),
    (2, 2, 2, 2, 1, 35.00, NULL),
    (3, 3, 3, 3, 1, 25.00, 100.00),
    (4, 4, 4, 4, 0, 50.00, NULL),
    (5, 5, 5, 5, 1, 100.00, 200.00);
	
GO
--------------- Subscriptions.Subscriptions ---------------


--------------- Subscriptions.MonthlySubscriptionPayouts ---------------
CREATE TABLE [Subscriptions].[MonthlySubscriptionPayouts]
(
	MonthlySubscriptionPayoutId INT IDENTITY(1, 1) NOT NULL,
	UserId INT NOT NULL,
	CreatorId INT NOT NULL,
	SubscriptionId INT NOT NULL, 
	Amount Money NOT NULL,
	[Date] Date NOT NULL DEFAULT GETDATE(),

	CONSTRAINT PK_MonthlySubscriptionPayouts_MonthlySubscriptionPayoutId PRIMARY KEY(MonthlySubscriptionPayoutId),
	CONSTRAINT FK_Users_MonthlySubscriptionPayouts_UserId FOREIGN KEY(UserId) REFERENCES Users.Users(UserId),
	CONSTRAINT FK_Creators_MonthlySubscriptionPayouts_CreatorId FOREIGN KEY(CreatorId) REFERENCES Creators.Creators(CreatorId),
	CONSTRAINT FK_Subscriptions_MonthlySubscriptionPayouts_SubscriptionsId FOREIGN KEY(SubscriptionId) REFERENCES Subscriptions.Subscriptions(SubscriptionId)
);

INSERT INTO [Subscriptions].[MonthlySubscriptionPayouts]
	(MonthlySubscriptionPayoutId, UserId, CreatorId, SubscriptionId, Amount, [Date])
VALUES 
    (1, 1, 1, 1, 15.00, '2024-10-01'),
    (2, 2, 2, 2, 35.00, '2024-10-01'),
    (3, 3, 3, 3, 25.00, '2024-10-01'),
    (4, 4, 4, 4, 50.00, '2024-10-01'),
    (5, 5, 5, 5, 100.00, '2024-10-01');
	
GO
--------------- Subscriptions.MonthlySubscriptionPayouts ---------------


--------------- Content.ContentTypes ---------------
CREATE TABLE [Content].[ContentTypes]
(
	ContentTypeId INT IDENTITY(1, 1) NOT NULL,
	Name NVARCHAR(50) NOT NULL,
	Description NVARCHAR(250) NOT NULL,
	
	CONSTRAINT PK_ContentTypes_ContentTypeId PRIMARY KEY(ContentTypeId),
	CONSTRAINT UQ_ContentTypes_Name UNIQUE(Name)
);

INSERT INTO [Content].[contentTypes]
	(ContentTypeId, Name, Description)
VALUES 
    (1, 'Video', 'Video content for subscribers.'),
    (2, 'Music', 'Music tracks available for download.'),
    (3, 'Blog', 'Exclusive blog posts.'),
    (4, 'Tutorial', 'How-to tutorials.'),
    (5, 'Artwork', 'Digital artwork for download.');
	
GO
--------------- Content.ContentTypes ---------------


--------------- Content.Content ---------------
CREATE TABLE [Content].[Content]
(
	ContentId INT IDENTITY(1, 1) NOT NULL,
	CreatorId INT NOT NULL,
	Title NVARCHAR(250) NOT NULL,
	Description NVARCHAR(2000) NOT NULL,
	ContentTypeId INT NOT NULL,
	Price MONEY DEFAULT NULL, /* NULL when not purchasable */

	CONSTRAINT PK_Content_ContentId PRIMARY KEY(ContentId),
	CONSTRAINT FK_Creators_Content_CreatorId FOREIGN KEY(CreatorId) REFERENCES Creators.Creators(CreatorId),
	CONSTRAINT FK_ContentType_Content_ContentTypeId FOREIGN KEY(ContentTypeId) REFERENCES Content.ContentTypes(ContentTypeId)
);

INSERT INTO [Content].[Content]
	(ContentId, CreatorId, Title, Description, Price)
VALUES 
    (1, 1, 'Art Video', 'A deep dive into modern art.', 10.00),  -- ContentTypeId 1
    (2, 2, 'Music Album', 'Exclusive music album release.', 20.00);  -- ContentTypeId 5
    (3, 3, 'Crafting Blog', 'Tips and tricks for handmade crafts.', NULL),  -- ContentTypeId 3
    (4, 4, 'Photography Tutorial', 'Learn advanced photography techniques.', 20.00),  -- ContentTypeId 4
    (5, 5, 'Digital Art Piece', 'High-resolution digital artwork.', 35.00),  -- ContentTypeId 2
   
    
    
	
GO
--------------- Content.Content ---------------


--------------- Content.SubscriptionTierContent ---------------
CREATE TABLE [Content].[SubscriptionTierContent]
(
	ContentId INT NOT NULL,
	SubscriptionTierId INT NOT NULL,

	CONSTRAINT PK_SubscriptionTierContents_ContentId_SubscriptionTierId PRIMARY KEY(ContentId, SubscriptionTierId),
	CONSTRAINT FK_Content_SubscriptionTierContent_ContentId FOREIGN KEY(ContentId) REFERENCES Content.Content(ContentId),
	CONSTRAINT FK_SubscriptionTiers_SubscriptionTierContent_SubscriptionTierId FOREIGN KEY(SubscriptionTierId) REFERENCES Subscriptions.SubscriptionTiers(SubscriptionTierId)
);

INSERT INTO [Content].[Content]
	(ContentId, SubscriptionTierId)
VALUES 
    (1, 1),
    (2, 2),
    (3, 3),
    (4, 4),
    (5, 5);
	
GO
--------------- Content.SubscriptionTierContent ---------------


--------------- Content.Purchases ---------------
/* Purchases may be due to active subscription or due to manual purchase of certain content. */
CREATE TABLE [Content].[Purchases]
(
	PurchaseId INT IDENTITY(1, 1) NOT NULL,
	UserId INT NOT NULL,
	CreatorId INT NOT NULL, /* An example of a derivable attribute */
	ContentId INT NOT NULL,
	SubscriptionId INT, /* Subscription that auto-purchased this. */
	Price MONEY NOT NULL DEFAULT 0, /* 0 when the content is accured trough monthly subscription. */
	[DateTime] DateTime DEFAULT GETDATE(),

	CONSTRAINT PK_Purchases_PurchaseId PRIMARY KEY(PurchaseId),
	CONSTRAINT FK_Users_Purchases_UserId FOREIGN KEY(UserId) REFERENCES Users.Users(UserId),
	CONSTRAINT FK_Creators_Purchases_CreatorId FOREIGN KEY(CreatorId) REFERENCES Creators.Creators(CreatorId),
	CONSTRAINT FK_Content_Purchases_ContentId FOREIGN KEY(CreatorId) REFERENCES Content.Content(ContentId),
	CONSTRAINT FK_Subscriptions_Purchases_SubscriptionId FOREIGN KEY(SubscriptionId) REFERENCES Subscriptions.Subscriptions(SubscriptionId)
);

INSERT INTO [Content].[Purchases]
	(UserId, CreatorId, ContentId, SubscriptionId, Price, [DateTime])
VALUES 
    (1, 1, 1, 1, 10.00, '2024-10-01'),
    (2, 2, 2, 2, 20.00, '2024-10-02'),
    (3, 3, 3, 3, 0.00, '2024-10-03'),
    (4, 4, 4, NULL, 20.00, '2024-10-04'),
    (5, 5, 5, 5, 35.00, '2024-10-05');
	
GO
--------------- Content.Purchases ---------------




