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
	(SubscriptionTierId, CreatorId, Name, IsBilledPerUpload, SubscriverCountLimit)
VALUES
	
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
	
GO
--------------- Content.Purchases ---------------




