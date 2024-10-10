-- Create the database
CREATE DATABASE LinkedInDB;
GO
USE LinkedInDB;
GO

-- 1. Table Definitions

-- User Table
CREATE TABLE Users (
    userId INT PRIMARY KEY IDENTITY(1,1),
    email NVARCHAR(100) NOT NULL UNIQUE,
    name NVARCHAR(100) NOT NULL,
    headline NVARCHAR(255),
    location NVARCHAR(100),
    industry NVARCHAR(100)
);

-- Profile Table
CREATE TABLE Profiles (
    profileId INT PRIMARY KEY IDENTITY(1,1),
    userId INT,
    summary NVARCHAR(MAX),
    experience NVARCHAR(MAX),
    skills NVARCHAR(MAX),
    FOREIGN KEY (userId) REFERENCES Users(userId)
);

-- Company Table
CREATE TABLE Companies (
    companyId INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(100) NOT NULL,
    industry NVARCHAR(100),
    location NVARCHAR(100)
);

-- Job Table
CREATE TABLE Jobs (
    jobId INT PRIMARY KEY IDENTITY(1,1),
    companyId INT,
    title NVARCHAR(255) NOT NULL,
    description NVARCHAR(MAX),
    location NVARCHAR(100),
	FOREIGN KEY (companyId) REFERENCES Companies(companyId)
);

-- Connections Table (Many-to-Many between Users)
CREATE TABLE Connections (
    connectionId INT PRIMARY KEY IDENTITY(1,1),
    userId1 INT,
    userId2 INT,
    status NVARCHAR(50),
    FOREIGN KEY (userId1) REFERENCES Users(userId),
    FOREIGN KEY (userId2) REFERENCES Users(userId)
);

-- Post Table
CREATE TABLE Posts (
    postId INT PRIMARY KEY IDENTITY(1,1),
    userId INT,
    content NVARCHAR(MAX),
    datePosted DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (userId) REFERENCES Users(userId)
);

-- Message Table (Many-to-Many between Users)
CREATE TABLE Messages (
    messageId INT PRIMARY KEY IDENTITY(1,1),
    senderId INT,
    receiverId INT,
    content NVARCHAR(MAX),
    dateSent DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (senderId) REFERENCES Users(userId),
    FOREIGN KEY (receiverId) REFERENCES Users(userId)
);

-- Job Applications Table (Many-to-Many between Users and Jobs)
CREATE TABLE JobApplications (
    applicationId INT PRIMARY KEY IDENTITY(1,1),
    userId INT,
    jobId INT,
    applicationDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (userId) REFERENCES Users(userId),
    FOREIGN KEY (jobId) REFERENCES Jobs(jobId)
);

-- 2. Stored Procedures
GO

-- Stored Procedure: Get all Jobs applied by a specific user
CREATE PROCEDURE GetUserJobs
    @userId INT
AS
BEGIN
    SELECT Jobs.jobId, Jobs.title, Jobs.description, Jobs.location
    FROM JobApplications
    JOIN Jobs ON JobApplications.jobId = Jobs.jobId
    WHERE JobApplications.userId = @userId;
END;
GO

-- Stored Procedure: Get all posts by a user
CREATE PROCEDURE GetUserPosts
    @userId INT
AS
BEGIN
    SELECT * FROM Posts WHERE userId = @userId;
END;
GO

-- 3. Functions

-- Function: Get Total Number of Connections for a User
CREATE FUNCTION GetTotalConnections (@userId INT)
RETURNS INT
AS
BEGIN
    RETURN (
        SELECT COUNT(*) FROM Connections 
        WHERE userId1 = @userId OR userId2 = @userId
    );
END;
GO

-- Function: Get Total Messages Sent by a User
CREATE FUNCTION GetTotalMessagesSent (@userId INT)
RETURNS INT
AS
BEGIN
    RETURN (
        SELECT COUNT(*) FROM Messages WHERE senderId = @userId
    );
END;
GO

-- 4. Triggers

-- Trigger: Log when a new connection is created
CREATE TRIGGER LogConnectionCreation
ON Connections
AFTER INSERT
AS
BEGIN
    INSERT INTO ConnectionLogs (connectionId, logDate)
    SELECT connectionId, GETDATE() FROM inserted;
END;
GO

-- Trigger: Log when a new job application is made
CREATE TRIGGER LogJobApplication
ON JobApplications
AFTER INSERT
AS
BEGIN
    INSERT INTO JobApplicationLogs (applicationId, logDate)
    SELECT applicationId, GETDATE() FROM inserted;
END;
GO

-- 5. Example Logs Tables for Triggers
CREATE TABLE ConnectionLogs (
    logId INT PRIMARY KEY IDENTITY(1,1),
    connectionId INT,
    logDate DATETIME,
    FOREIGN KEY (connectionId) REFERENCES Connections(connectionId)
);

CREATE TABLE JobApplicationLogs (
    logId INT PRIMARY KEY IDENTITY(1,1),
    applicationId INT,
    logDate DATETIME,
    FOREIGN KEY (applicationId) REFERENCES JobApplications(applicationId)
);

-- 6. Insertions
-- Insert Users
INSERT INTO Users (email, name, headline, location, industry)
VALUES 
    ('john.doe@example.com', 'John Doe', 'Software Developer', 'New York', 'Technology'),
    ('jane.smith@example.com', 'Jane Smith', 'Project Manager', 'San Francisco', 'Marketing'),
    ('alice.jones@example.com', 'Alice Jones', 'UX Designer', 'Chicago', 'Design'),
    ('bob.miller@example.com', 'Bob Miller', 'Data Scientist', 'Seattle', 'Analytics'),
    ('charles.brown@example.com', 'Charles Brown', 'DevOps Engineer', 'Austin', 'Technology');

-- Insert Profiles (matching userId from Users table)
INSERT INTO Profiles (userId, summary, experience, skills)
VALUES
    (1, 'Experienced software developer specializing in full-stack development.', '5 years at TechCorp', 'JavaScript, React, Node.js, SQL'),
    (2, 'Project manager with a focus on digital transformation and agile methodologies.', '8 years at SoftSolutions', 'Agile, Scrum, Communication, Risk Management'),
    (3, 'UX designer passionate about creating intuitive user experiences.', '4 years at CreativeMedia', 'Figma, Sketch, HTML, CSS'),
    (4, 'Data scientist with expertise in machine learning and big data.', '3 years at DataX', 'Python, R, SQL, Hadoop'),
    (5, 'DevOps engineer with experience in cloud infrastructure and automation.', '6 years at CloudNet', 'AWS, Docker, Kubernetes, Jenkins');

-- Insert Companies
INSERT INTO Companies (name, industry, location)
VALUES 
    ('TechCorp', 'Technology', 'San Francisco'),
    ('SoftSolutions', 'Marketing', 'New York'),
    ('CreativeMedia', 'Design', 'Los Angeles'),
    ('DataX', 'Analytics', 'Boston'),
    ('CloudNet', 'Technology', 'Austin');

-- Insert Jobs (with companyId from Companies table)
INSERT INTO Jobs (companyId, title, description, location)
VALUES
    (1, 'Software Engineer', 'Develop and maintain web applications.', 'Remote'),
    (2, 'Marketing Manager', 'Lead the marketing team and manage campaigns.', 'New York'),
    (3, 'UX Designer', 'Design user interfaces for mobile apps.', 'Remote'),
    (4, 'Data Analyst', 'Analyze large datasets to extract meaningful insights.', 'Boston'),
    (5, 'Cloud Engineer', 'Build and maintain cloud infrastructure.', 'Austin');

-- Insert Connections (userId1, userId2 refer to Users table)
INSERT INTO Connections (userId1, userId2, status)
VALUES
    (1, 2, 'Accepted'),
    (1, 3, 'Accepted'),
    (2, 4, 'Pending'),
    (3, 5, 'Accepted'),
    (4, 5, 'Accepted');

-- Insert Posts
INSERT INTO Posts (userId, content)
VALUES
    (1, 'Just launched a new feature in our product. Excited to see how it performs!'),
    (2, 'Looking forward to leading our next big project. #projectmanagement'),
    (3, 'User-centered design is key to creating great products. #ux #design'),
    (4, 'Data-driven decisions are the future of business. #datascience'),
    (5, 'Cloud automation is revolutionizing the tech industry. #devops');

-- Insert Messages (senderId and receiverId refer to Users table)
INSERT INTO Messages (senderId, receiverId, content)
VALUES
    (1, 2, 'Hey Jane, I saw your post about project management. Would love to discuss more.'),
    (2, 1, 'Sure John, let’s set up a call to talk about it!'),
    (3, 4, 'Hi Bob, I noticed you work in data science. I have a project that could use your expertise.'),
    (4, 5, 'Hello Charles, let’s collaborate on the cloud infrastructure project.'),
    (5, 3, 'Hey Alice, love your work on the new mobile app design. Let’s connect.');

-- Insert Job Applications (with userId from Users and jobId from Jobs)
INSERT INTO JobApplications (userId, jobId)
VALUES
    (1, 1),  -- John applied for Software Engineer
    (2, 2),  -- Jane applied for Marketing Manager
    (3, 3),  -- Alice applied for UX Designer
    (4, 4),  -- Bob applied for Data Analyst
    (5, 5);  -- Charles applied for Cloud Engineer

-- Insert Log Entries for the Triggers (optional, just for reference)
INSERT INTO ConnectionLogs (connectionId, logDate)
VALUES
    (1, GETDATE()),
    (2, GETDATE());

INSERT INTO JobApplicationLogs (applicationId, logDate)
VALUES
    (1, GETDATE()),
    (2, GETDATE());

