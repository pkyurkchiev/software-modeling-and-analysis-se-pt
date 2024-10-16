CREATE TABLE Users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    password VARCHAR(100) NOT NULL,
    bio TEXT,
    profile_image VARCHAR(255),
    signup_date DATE NOT NULL,
    user_type VARCHAR(50)
);

CREATE TABLE Photos (
    photo_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    upload_date DATE NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    views_count INT,
    resolution VARCHAR(50),
    user_id INT REFERENCES Users(user_id)
);

CREATE TABLE Categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL
);

CREATE TABLE Tags (
    tag_id SERIAL PRIMARY KEY,
    tag_name VARCHAR(100) NOT NULL
);

CREATE TABLE Downloads (
    download_id SERIAL PRIMARY KEY,
    photo_id INT REFERENCES Photos(photo_id),
    user_id INT REFERENCES Users(user_id),
    download_date DATE NOT NULL
);

CREATE TABLE Comments (
    comment_id SERIAL PRIMARY KEY,
    photo_id INT REFERENCES Photos(photo_id),
    user_id INT REFERENCES Users(user_id),
    comment_text TEXT NOT NULL,
    comment_date DATE NOT NULL
);

CREATE TABLE Likes (
    like_id SERIAL PRIMARY KEY,
    photo_id INT REFERENCES Photos(photo_id),
    user_id INT REFERENCES Users(user_id),
    like_date DATE NOT NULL
);

CREATE TABLE Collections (
    collection_id SERIAL PRIMARY KEY,
    collection_name VARCHAR(255) NOT NULL,
    user_id INT REFERENCES Users(user_id)
);

CREATE TABLE Photo_Tags (
    photo_id INT,
    tag_id INT,
    PRIMARY KEY (photo_id, tag_id),
    FOREIGN KEY (photo_id) REFERENCES Photos(photo_id),
    FOREIGN KEY (tag_id) REFERENCES Tags(tag_id)
);

CREATE TABLE Photo_Collections (
    photo_id INT,
    collection_id INT,
    PRIMARY KEY (photo_id, collection_id),
    FOREIGN KEY (photo_id) REFERENCES Photos(photo_id),
    FOREIGN KEY (collection_id) REFERENCES Collections(collection_id)
);

CREATE TABLE Collection_to_photo (
    entry_id SERIAL PRIMARY KEY,
    collection_id INT REFERENCES Collections(collection_id),
    photo_id INT REFERENCES Photos(photo_id)
);

-- Stored Procedures are converted to Functions in PostgreSQL
CREATE OR REPLACE FUNCTION GetUserPhotos(user_id INT)
RETURNS TABLE (
    photo_id INT,
    title VARCHAR,
    description TEXT,
    upload_date DATE,
    image_url VARCHAR
) AS $$
BEGIN
    RETURN QUERY SELECT * FROM Photos WHERE user_id = GetUserPhotos(user_id);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION GetPhotoDownloads(photo_id INT)
RETURNS TABLE (
    DownloadCount INT
) AS $$
BEGIN
    RETURN QUERY SELECT COUNT(download_id) AS DownloadCount FROM Downloads WHERE photo_id = GetPhotoDownloads.photo_id;
END;
$$ LANGUAGE plpgsql;

-- Functions for photo ratings and counts
CREATE OR REPLACE FUNCTION GetAverageRating(photo_id INT)
RETURNS DECIMAL(5, 2) AS $$
DECLARE
    avg_rating DECIMAL(5, 2);
BEGIN
    SELECT AVG(rating) INTO avg_rating FROM Ratings WHERE photo_id = GetAverageRating.photo_id;
    RETURN avg_rating;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION GetPhotoCountByCategory(category_id INT)
RETURNS INT AS $$
DECLARE
    photo_count INT;
BEGIN
    SELECT COUNT(photo_id) INTO photo_count FROM Photos WHERE category_id = GetPhotoCountByCategory.category_id;
    RETURN photo_count;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE OR REPLACE FUNCTION UpdateUserPhotoCount()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Users
    SET photo_count = photo_count + 1
    WHERE user_id = NEW.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_UpdateUserPhotoCount
AFTER INSERT ON Photos
FOR EACH ROW EXECUTE FUNCTION UpdateUserPhotoCount();

CREATE OR REPLACE FUNCTION DeleteUserPhotos()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM Photos WHERE user_id = OLD.user_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_DeleteUserPhotos
AFTER DELETE ON Users
FOR EACH ROW EXECUTE FUNCTION DeleteUserPhotos();


CREATE OR REPLACE FUNCTION DecrementUserPhotoCount()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Users
    SET photo_count = photo_count - 1
    WHERE user_id = OLD.user_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_DecrementUserPhotoCount
AFTER DELETE ON Photos
FOR EACH ROW
EXECUTE FUNCTION DecrementUserPhotoCount();

-- Insert sample data
INSERT INTO Users (username, email, password, bio, profile_image, signup_date, user_type)
VALUES
('john_doe', 'john@example.com', 'password123', 'Bio for John', 'image1.jpg', '2024-01-01', 'photographer'),
('jane_doe', 'jane@example.com', 'password123', 'Bio for Jane', 'image2.jpg', '2024-02-01', 'photographer'),
('alice', 'alice@example.com', 'password123', 'Bio for Alice', 'image3.jpg', '2024-03-01', 'viewer'),
('bob', 'bob@example.com', 'password123', 'Bio for Bob', 'image4.jpg', '2024-04-01', 'viewer'),
('charlie', 'charlie@example.com', 'password123', 'Bio for Charlie', 'image5.jpg', '2024-05-01', 'admin');

INSERT INTO Photos (title, description, upload_date, image_url, views_count, resolution, user_id)
VALUES
('Sunset', 'A beautiful sunset', '2024-06-01', 'sunset.jpg', 100, '1920x1080', 1),
('Mountain', 'A stunning mountain view', '2024-06-02', 'mountain.jpg', 150, '1920x1080', 2),
('Beach', 'A serene beach', '2024-06-03', 'beach.jpg', 200, '1920x1080', 1),
('Cityscape', 'A bustling city', '2024-06-04', 'cityscape.jpg', 250, '1920x1080', 2),
('Forest', 'A calm forest', '2024-06-05', 'forest.jpg', 300, '1920x1080', 3);

INSERT INTO Categories (category_name)
VALUES
('Nature'),
('Urban'),
('People'),
('Abstract'),
('Animals');

INSERT INTO Tags (tag_name)
VALUES
('Sunset'),
('Mountain'),
('Beach'),
('City'),
('Forest');

INSERT INTO Downloads (photo_id, user_id, download_date)
VALUES
(1, 3, '2024-07-01'),
(2, 4, '2024-07-02'),
(3, 3, '2024-07-03'),
(4, 5, '2024-07-04'),
(5, 4, '2024-07-05');

INSERT INTO Photo_Tags (photo_id, tag_id)
VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5);

ALTER TABLE Users ADD COLUMN photo_count INT DEFAULT 0;

CREATE OR REPLACE FUNCTION UpdateUserPhotoCount()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Users
    SET photo_count = photo_count + 1
    WHERE user_id = NEW.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_UpdateUserPhotoCount
AFTER INSERT ON Photos
FOR EACH ROW
EXECUTE FUNCTION UpdateUserPhotoCount();


-- DROP TRIGGER IF EXISTS trg_UpdateUserPhotoCount ON Photos;