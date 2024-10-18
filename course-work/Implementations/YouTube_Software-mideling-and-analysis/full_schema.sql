CREATE SCHEMA UserManagement;
CREATE SCHEMA ContentManagement;

----------------------------------------------------------------------------------------------
-- UserManagement Schemas
--     Tables:
--     UserAccount,
--     Subscription,
--     Playlist

CREATE TABLE UserManagement.UserAccount
(
    Email          VARCHAR(150) PRIMARY KEY NOT NULL,
    Username       VARCHAR(36)              NOT NULL,
    Password       VARCHAR(127)             NOT NULL,
    FirstName      VARCHAR(150)             NOT NULL,
    LastName       VARCHAR(150)             NOT NULL,
    DateOfCreation TIMESTAMP                NOT NULL,
    PhoneNumber    VARCHAR(15),
    Subscribers    BIGINT
);

CREATE TABLE UserManagement.Subscription
(
    FromUserAccountEmail VARCHAR(150) NOT NULL,
    ToUserAccountEmail   VARCHAR(150) NOT NULL,
    SubscriptionDate     TIMESTAMP    NOT NULL,
    PRIMARY KEY (FromUserAccountEmail, ToUserAccountEmail),
    FOREIGN KEY (FromUserAccountEmail) REFERENCES UserManagement.UserAccount (Email),
    FOREIGN KEY (ToUserAccountEmail) REFERENCES UserManagement.UserAccount (Email)
);

CREATE TABLE UserManagement.Playlist
(
    PlaylistName     VARCHAR(150) NOT NULL,
    UserAccountEmail VARCHAR(150) NOT NULL,
    CreationDate     TIMESTAMP,
    PRIMARY KEY (PlaylistName, UserAccountEmail),
    FOREIGN KEY (UserAccountEmail) REFERENCES UserManagement.UserAccount (Email)
);

----------------------------------------------------------------------------------------------
-- ContentManagement Schemas
--     Tables:
--     Video,
--     Categories,
--     Comments
--     Likes
--     PlaylistVideo

CREATE TABLE ContentManagement.Categories
(
    Genre       VARCHAR(100) PRIMARY KEY NOT NULL,
    Description TEXT
);

CREATE TABLE ContentManagement.Video
(
    URL              TEXT PRIMARY KEY NOT NULL,
    UserAccountEmail VARCHAR(150)     NOT NULL,
    Genre            VARCHAR(100)     NOT NULL,
    Title            VARCHAR(100),
    Published        TIMESTAMP        NOT NULL,
    Duration         TIME             NOT NULL,
    Description      TEXT,
    FOREIGN KEY (UserAccountEmail) REFERENCES UserManagement.UserAccount (Email),
    FOREIGN KEY (Genre) REFERENCES ContentManagement.Categories (Genre)
);

CREATE TABLE ContentManagement.Comments
(
    URL              TEXT         NOT NULL,
    UserAccountEmail VARCHAR(150) NOT NULL,
    CommentText      TEXT,
    CommentDate      TIMESTAMP,
    PRIMARY KEY (URL, UserAccountEmail),
    FOREIGN KEY (URL) REFERENCES ContentManagement.Video (URL),
    FOREIGN KEY (UserAccountEmail) REFERENCES UserManagement.UserAccount (Email)
);

CREATE TABLE ContentManagement.Likes
(
    URL              TEXT         NOT NULL,
    UserAccountEmail VARCHAR(150) NOT NULL,
    isLiked          BOOLEAN,
    LikeDate         TIMESTAMP,
    PRIMARY KEY (URL, UserAccountEmail),
    FOREIGN KEY (URL) REFERENCES ContentManagement.Video (URL),
    FOREIGN KEY (UserAccountEmail) REFERENCES UserManagement.UserAccount (Email)
);

CREATE TABLE ContentManagement.PlaylistVideo
(
    PlaylistName     VARCHAR(150) NOT NULL,
    UserAccountEmail VARCHAR(150) NOT NULL,
    URL              TEXT         NOT NULL,
    PRIMARY KEY (PlaylistName, URL, UserAccountEmail),
    FOREIGN KEY (PlaylistName, UserAccountEmail)
        REFERENCES UserManagement.Playlist (PlaylistName, UserAccountEmail),
    FOREIGN KEY (URL)
        REFERENCES ContentManagement.Video (URL),
    FOREIGN KEY (UserAccountEmail)
        REFERENCES UserManagement.UserAccount (Email)
);


----------------------------------------------------------------------------------------------
-- Procedures
-- AddUser
-- AddVideo
-- AddCategory


CREATE OR REPLACE PROCEDURE UserManagement.AddUser(
    IN p_Email VARCHAR(150),
    IN p_Username VARCHAR(36),
    IN p_Password VARCHAR(127),
    IN p_FirstName VARCHAR(150),
    IN p_LastName VARCHAR(150),
    IN p_DateOfCreation TIMESTAMP,
    IN p_PhoneNumber VARCHAR(15)
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO UserManagement.UserAccount
    (
        Email, Username, Password, FirstName, LastName, DateOfCreation, PhoneNumber
    )
    VALUES
    (
        p_Email, p_Username, p_Password, p_FirstName, p_LastName, p_DateOfCreation, p_PhoneNumber
    );
END;
$$;

CREATE OR REPLACE PROCEDURE ContentManagement.AddVideo (
    IN p_URL TEXT,
    IN p_UserAccountEmail VARCHAR(150),
    IN p_Genre VARCHAR(100),
    IN p_Title VARCHAR(100),
    IN p_Published TIMESTAMP,
    IN p_Duration TIME,
    IN p_Description TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO ContentManagement.Video
    (
        URL, UserAccountEmail, Genre, Title, Published, Duration, Description
    )
    VALUES
    (
        p_URL, p_UserAccountEmail, p_Genre, p_Title, p_Published, p_Duration, p_Description
    );
END;
$$;

CREATE OR REPLACE PROCEDURE ContentManagement.AddCategory (
    IN p_Genre VARCHAR,
    IN p_Description TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO ContentManagement.Categories
    (
        Genre, Description
    )
    VALUES
    (
        p_Genre, p_Description
    );
END;
$$;

----------------------------------------------------------------------------------------------
-- Call
-- AddUser
-- AddVideo
-- AddCategory


CALL UserManagement.AddUser(
    'john.doe@email.com',    -- p_Email
    'johnDoe',               -- p_Username
    'securePassword123',     -- p_Password
    'John',                  -- p_FirstName
    'Doe',                   -- p_LastName
    CURRENT_TIMESTAMP::TIMESTAMP,       -- p_DateOfCreation
    '1234567890'         -- p_PhoneNumber

);

CALL ContentManagement.AddCategory (
    'Placeholder',
    'This genre is used as an example'
    );

CALL ContentManagement.AddVideo(
    'https://www.youtube.com/watch?v=u31qwQUeGuM',
    'john.doe@email.com',
    'Placeholder',
    'Placeholder Video Example',
    CURRENT_TIMESTAMP::TIMESTAMP,
    '00:00:15',
    'Placeholder video that is used as an example in this SQL'
    );

----------------------------------------------------------------------------------------------
-- Functions
-- GetTotalVideosByUser
-- UpdateSubscribersOnInsert
-- UpdateSubscribersOnDelete

CREATE OR REPLACE FUNCTION ContentManagement.GetTotalVideosByUser(
    p_UserAccountEmail VARCHAR(150)
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    total_videos INT;
BEGIN
    SELECT COUNT(*)
    INTO total_videos
    FROM ContentManagement.Video
    WHERE UserAccountEmail = p_UserAccountEmail;

    RETURN total_videos;
END;
$$;

CREATE OR REPLACE FUNCTION UpdateSubscribersOnInsert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE UserManagement.UserAccount
    SET Subscribers = COALESCE(Subscribers, 0) + 1
    WHERE Email = NEW.ToUserAccountEmail;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION UpdateSubscribersOnDelete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE UserManagement.UserAccount
    SET Subscribers = COALESCE(Subscribers, 0) - 1
    WHERE Email = OLD.ToUserAccountEmail;

    RETURN OLD;
END;
$$;
----------------------------------------------------------------------------------------------
-- Triggers
-- UpdateSubscribersOnInsert
-- UpdateSubscribersOnDelete

CREATE TRIGGER AddSubscriber
AFTER INSERT ON UserManagement.Subscription
FOR EACH ROW
EXECUTE FUNCTION UpdateSubscribersOnInsert();

CREATE TRIGGER RemoveSubscriber
AFTER DELETE ON UserManagement.Subscription
FOR EACH ROW
EXECUTE FUNCTION UpdateSubscribersOnDelete();

----------------------------------------------------------------------------------------------
-- Insert information to tables
-- Insert new user
-- The first user John subscribes to new user Jane
-- After that Jane subscribes to John
-- In the end Jane unsubscribes from John

INSERT INTO UserManagement.UserAccount (Email, Username, Password, FirstName, LastName, DateOfCreation, PhoneNumber, Subscribers)
VALUES (
        'jane.smith@email.com',
        'janeSmith',
        'password456',
        'Jane',
        'Smith',
        CURRENT_TIMESTAMP,
        '0987654321',
        0
);

INSERT INTO UserManagement.Subscription (FromUserAccountEmail, ToUserAccountEmail, SubscriptionDate)
VALUES
    ('john.doe@email.com', 'jane.smith@email.com', CURRENT_TIMESTAMP);

INSERT INTO  UserManagement.Subscription (FromUserAccountEmail, ToUserAccountEmail, SubscriptionDate)
VALUES
    ('jane.smith@email.com', 'john.doe@email.com', CURRENT_TIMESTAMP);

DELETE FROM UserManagement.Subscription
WHERE FromUserAccountEmail = 'john.doe@email.com'
AND ToUserAccountEmail = 'jane.smith@email.com';

----------------------------------------------------------------------------------------------
-- Insert data to all the available tables
-- Insert new user
-- User (Alice) subscribes to John
-- Each user (John, Jane, Alice) creates a playlist
-- Creating new video categories
-- John and Jane create a video
-- John and Alice leave comments to Jane's video
-- John likes Jane video, Alice did not liked the video
-- John and Jane insert their own videos to playlist, while Alice adds their (John and Jane) videos to her playlist


-- Insert new user
INSERT INTO UserManagement.UserAccount (Email, Username, Password, FirstName, LastName, DateOfCreation, PhoneNumber, Subscribers)
VALUES
    ('alice.wonderland@email.com', 'aliceWonder', 'wonderPass789', 'Alice', 'Wonderland', CURRENT_TIMESTAMP, '5678901234', 0);


-- User (Alice) subscribes to John
INSERT INTO UserManagement.Subscription (FromUserAccountEmail, ToUserAccountEmail, SubscriptionDate)
VALUES
    ('john.doe@email.com', 'jane.smith@email.com', CURRENT_TIMESTAMP),
    ('alice.wonderland@email.com', 'john.doe@email.com', CURRENT_TIMESTAMP);


-- Each user (John, Jane, Alice) creates a playlist
INSERT INTO UserManagement.Playlist (PlaylistName, UserAccountEmail, CreationDate)
VALUES
    ('John Playlist', 'john.doe@email.com', CURRENT_TIMESTAMP),
    ('Jane Favorites', 'jane.smith@email.com', CURRENT_TIMESTAMP),
    ('Alice Top Videos', 'alice.wonderland@email.com', CURRENT_TIMESTAMP);


-- Creating new video categories
INSERT INTO ContentManagement.Categories (Genre, Description)
VALUES
    ('Education', 'Educational content and tutorials'),
    ('Entertainment', 'Movies, TV shows, and fun videos'),
    ('Gaming', 'Videos about games and gaming'),
    ('Technology', 'Tech reviews, news, and tutorials');


-- John and Jane create a video
INSERT INTO ContentManagement.Video (URL, UserAccountEmail, Genre, Title, Published, Duration, Description)
VALUES
    ('https://youtu.be/johns_video_1', 'john.doe@email.com', 'Education', 'How to Learn SQL', CURRENT_TIMESTAMP, '00:15:00', 'A tutorial on learning SQL.'),
    ('https://youtu.be/jane_video_1', 'jane.smith@email.com', 'Entertainment', 'Best TV Shows in 2024', CURRENT_TIMESTAMP, '00:10:30', 'A review of top TV shows in 2024.');


-- John and Alice leave comments to Jane's video
INSERT INTO ContentManagement.Comments (URL, UserAccountEmail, CommentText, CommentDate)
VALUES
    ('https://youtu.be/jane_video_1', 'john.doe@email.com', 'Great review! I enjoyed the recommendations.', CURRENT_TIMESTAMP),
    ('https://youtu.be/jane_video_1', 'alice.wonderland@email.com', 'This list is awesome! I have to watch these shows.', CURRENT_TIMESTAMP);


-- John likes Jane video, Alice does not liked the video
INSERT INTO ContentManagement.Likes (URL, UserAccountEmail, isLiked, LikeDate)
VALUES
    ('https://youtu.be/jane_video_1', 'john.doe@email.com', TRUE, CURRENT_TIMESTAMP),
    ('https://youtu.be/jane_video_1', 'alice.wonderland@email.com', FALSE, CURRENT_TIMESTAMP);


-- John and Jane insert their own videos to playlist, while Alice adds their (John and Jane) videos to her playlist
INSERT INTO ContentManagement.PlaylistVideo (PlaylistName, UserAccountEmail, URL)
VALUES
    ('John Playlist', 'john.doe@email.com', 'https://youtu.be/johns_video_1'),
    ('Jane Favorites', 'jane.smith@email.com', 'https://youtu.be/jane_video_1'),
    ('Alice Top Videos', 'alice.wonderland@email.com', 'https://youtu.be/johns_video_1'),
    ('Alice Top Videos', 'alice.wonderland@email.com', 'https://youtu.be/jane_video_1');


----------------------------------------------------------------------------------------------

