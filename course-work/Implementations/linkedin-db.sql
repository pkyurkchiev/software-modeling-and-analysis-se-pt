DROP DATABASE IF EXISTS linkedin;

CREATE DATABASE IF NOT EXISTS linkedin;

USE linkedin;

CREATE TABLE USER (
    UserID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(150) NOT NULL UNIQUE,
    Headline VARCHAR(255),
    Location VARCHAR(100),
    Summary TEXT,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE COMPANY (
    CompanyID INT AUTO_INCREMENT PRIMARY KEY,
    CompanyName VARCHAR(200) NOT NULL,
    Website VARCHAR(255),
    Industry VARCHAR(100),
    Size VARCHAR(50),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE POST (
    PostID INT AUTO_INCREMENT PRIMARY KEY,
    UserID INT NOT NULL,
    Content TEXT NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, 
    FOREIGN KEY (UserID) REFERENCES USER(UserID)
);

CREATE TABLE JOB_POSTING (
    JobID INT AUTO_INCREMENT PRIMARY KEY,
    CompanyID INT NOT NULL,
    Title VARCHAR(200) NOT NULL,
    Description TEXT,
    Location VARCHAR(100),
    Requirements TEXT,
    PostedDate DATE,
    ExpiryDate DATE,
    FOREIGN KEY (CompanyID) REFERENCES COMPANY(CompanyID)
);

CREATE TABLE MESSAGE (
    MessageID INT AUTO_INCREMENT PRIMARY KEY,
    SenderID INT NOT NULL,
    ReceiverID INT NOT NULL,
    Content TEXT,
    Timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (SenderID) REFERENCES USER(UserID),
    FOREIGN KEY (ReceiverID) REFERENCES USER(UserID)
);

CREATE TABLE SKILL (
    SkillID INT AUTO_INCREMENT PRIMARY KEY,
    SkillName VARCHAR(100) NOT NULL
);

CREATE TABLE EDUCATION (
    EducationID INT AUTO_INCREMENT PRIMARY KEY,
    Degree VARCHAR(100),
    InstitutionName VARCHAR(200),
    StartDate DATE,
    EndDate DATE,
    Grade VARCHAR(50)
);


CREATE TABLE USER_COMMENT (
    UserCommentID INT AUTO_INCREMENT PRIMARY KEY,
    UserID INT NOT NULL,
    PostID INT NOT NULL,
    Content TEXT,
    Likes INT,
    FOREIGN KEY (PostID) REFERENCES POST(PostID)
);


CREATE TABLE WORK_EXPERIENCE (
    ExperienceID INT AUTO_INCREMENT PRIMARY KEY,
    UserID INT NOT NULL,
    CompanyID INT NOT NULL,
    JobTitle VARCHAR(150),
    StartDate DATE,
    EndDate DATE,
    Description TEXT,
    IsCurrent BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (UserID) REFERENCES USER(UserID),
    FOREIGN KEY (CompanyID) REFERENCES COMPANY(CompanyID)
);

CREATE TABLE USER_SKILL (
    UserSkillID INT AUTO_INCREMENT PRIMARY KEY,
    UserID INT NOT NULL,
    SkillID INT NOT NULL,
    EndorsementCount INT DEFAULT 0,
    FOREIGN KEY (UserID) REFERENCES USER(UserID),
    FOREIGN KEY (SkillID) REFERENCES SKILL(SkillID)
);

CREATE TABLE USER_EDUCATION (
    UserEducationID INT AUTO_INCREMENT PRIMARY KEY,
    UserID INT NOT NULL,
    EducationID INT NOT NULL,
    StartDate DATE,
    EndDate DATE,
    Grade VARCHAR(20),
    FOREIGN KEY (UserID) REFERENCES USER(UserID),
    FOREIGN KEY (EducationID) REFERENCES EDUCATION(EducationID)
);


CREATE TABLE POST_REACTION (
    ReactionID INT AUTO_INCREMENT PRIMARY KEY,
    UserID INT NOT NULL,
    PostID INT NOT NULL,
    ReactionType ENUM('like', 'celebrate', 'love', 'insightful', 'curious'),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserID) REFERENCES USER(UserID),
    FOREIGN KEY (PostID) REFERENCES POST(PostID)
);


INSERT INTO USER (Name, Email, Headline, Location, Summary) VALUES
('Ivan Petrov', 'ivan.petrov@example.com', 'Senior Software Engineer', 'Sofia, Bulgaria', 'Experienced full-stack developer specializing in cloud solutions.'),
('Maria Dimitrova', 'maria.dimitrova@example.com', 'Product Manager', 'Plovdiv, Bulgaria', 'Leading cross-functional teams to deliver SaaS products.');

INSERT INTO COMPANY (CompanyName, Website, Industry, Size) VALUES
('Cognify Labs Ltd', 'https://cognifylabs.com', 'Information Technology', '50-200'),
('TechBridge Solutions', 'https://techbridgesolutions.com', 'Financial Services', '100-500');

INSERT INTO SKILL (SkillName) VALUES
('AWS Certified Developer'),
('Project Management'),
('TypeScript'),
('React');

INSERT INTO EDUCATION (Degree, InstitutionName, StartDate, EndDate, Grade) VALUES
('MSc Computer Science', 'Plovdiv University', '2016-09-01', '2018-06-30', 'Excellent'),
('BA Business Administration', 'Sofia University', '2012-09-01', '2016-06-30', 'Good');

INSERT INTO USER_SKILL (UserID, SkillID, EndorsementCount) VALUES
(1, 1, 6),
(1, 3, 12),
(2, 2, 4),
(2, 4, 8);

INSERT INTO USER_EDUCATION (UserID, EducationID, StartDate, EndDate, Grade) VALUES
(1, 1, '2016-09-01', '2018-06-30', 'Excellent'),
(2, 2, '2012-09-01', '2016-06-30', 'Good');

INSERT INTO POST (UserID, Content) VALUES
(1, 'Excited to join Cognify Labs and work on cloud-native projects!'),
(2, 'Thrilled to announce our new B2B platform release!');


INSERT INTO MESSAGE (SenderID, ReceiverID, Content) VALUES
(1, 2, 'Welcome to the team, Maria!'),
(2, 1, 'Thanks, Ivan! Looking forward to working together.');

INSERT INTO WORK_EXPERIENCE (UserID, CompanyID, JobTitle, StartDate, EndDate, IsCurrent) VALUES
(1, 1, 'Senior Software Engineer', '2019-01-01', NULL, TRUE),
(2, 2, 'Product Manager', '2022-04-01', NULL, TRUE);

INSERT INTO JOB_POSTING (CompanyID, Title, Description, Location, Requirements, PostedDate, ExpiryDate) VALUES
(1, 'Full-Stack Developer', 'Join us to build scalable web applications.', 'Remote', 'React, Node.js, AWS', '2025-10-01', '2025-12-31'),
(2, 'Data Analyst', 'Work with our fintech platform data sets.', 'Plovdiv', 'SQL, Python, Excel', '2025-09-15', '2025-11-30');

INSERT INTO POST_REACTION (UserID, PostID, ReactionType) VALUES
(2, 1, 'celebrate'),
(1, 2, 'insightful');

INSERT INTO USER_COMMENT (UserID, PostID, Content, Likes) VALUES
(1, 2,  "Great product!Will try it myself.", 3),
(2, 1,  "Congrats on your new role!!!", 1);

