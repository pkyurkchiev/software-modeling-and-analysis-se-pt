CREATE DATABASE spotify_db;
USE spotify_db;

-- Таблица за потребители
CREATE TABLE User (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    password VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    country_id INT
);

-- Таблица за артисти
CREATE TABLE Artist (
    artist_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    genre_id INT
);

-- Таблица за албуми
CREATE TABLE Album (
    album_id INT AUTO_INCREMENT PRIMARY KEY,
    artist_id INT,
    title VARCHAR(100) NOT NULL,
    release_date DATE,
    FOREIGN KEY (artist_id) REFERENCES Artist(artist_id)
);

-- Таблица за песни
CREATE TABLE Track (
    track_id INT AUTO_INCREMENT PRIMARY KEY,
    album_id INT,
    artist_id INT,
    genre_id INT,
    title VARCHAR(100) NOT NULL,
    length TIME,
    popularity INT DEFAULT 0,
    FOREIGN KEY (album_id) REFERENCES Album(album_id),
    FOREIGN KEY (artist_id) REFERENCES Artist(artist_id),
    FOREIGN KEY (genre_id) REFERENCES Genre(genre_id)
);

-- Таблица за плейлисти
CREATE TABLE Playlist (
    playlist_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    title VARCHAR(100) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);

CREATE TABLE TrackLog (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    track_id INT,
    action VARCHAR(50),
    action_time DATETIME,
    FOREIGN KEY (user_id) REFERENCES User(user_id),
    FOREIGN KEY (track_id) REFERENCES Track(track_id)
);


-- Таблица за връзка между потребители и песни (много към много)
CREATE TABLE User_Track (
    user_id INT,
    track_id INT,
    play_count INT DEFAULT 0,
    added_to_favorites BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (user_id, track_id),
    FOREIGN KEY (user_id) REFERENCES User(user_id),
    FOREIGN KEY (track_id) REFERENCES Track(track_id)
);

-- Таблица за жанрове
CREATE TABLE Genre (
    genre_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

-- Таблица за абонаменти
CREATE TABLE Subscription (
    subscription_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    type VARCHAR(50) NOT NULL,
    start_date DATE,
    end_date DATE,
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);

-- Таблица за държави
CREATE TABLE Country (
    country_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Добавяне на връзка за държавите
ALTER TABLE User
ADD FOREIGN KEY (country_id) REFERENCES Country(country_id);

-- Функция за изчисляване на броя прослушвания на песен от потребител
DELIMITER //
CREATE FUNCTION GetPlayCount(userId INT, trackId INT) RETURNS INT
BEGIN
    DECLARE playCount INT;
    SELECT play_count INTO playCount FROM User_Track WHERE user_id = userId AND track_id = trackId;
    RETURN playCount;
END //
DELIMITER ;

-- Функция за проверка дали песен е добавена към плейлист на потребител
DELIMITER //
CREATE FUNCTION IsTrackFavorite(userId INT, trackId INT) RETURNS BOOLEAN
BEGIN
    DECLARE isFavorite BOOLEAN;
    SELECT added_to_favorites INTO isFavorite FROM User_Track WHERE user_id = userId AND track_id = trackId;
    RETURN isFavorite;
END //
DELIMITER ;

-- Тригер за логиране при добавяне на песен към плейлист
DELIMITER //
CREATE TRIGGER LogTrackAddition
AFTER INSERT ON User_Track
FOR EACH ROW
BEGIN
    INSERT INTO TrackLog(user_id, track_id, action, action_time)
    VALUES (NEW.user_id, NEW.track_id, 'ADDED_TO_PLAYLIST', NOW());
END //
DELIMITER ;

-- Тригер за обновяване на броя прослушвания на песен
DELIMITER //
CREATE TRIGGER UpdatePlayCount
AFTER UPDATE ON User_Track
FOR EACH ROW
BEGIN
    IF OLD.play_count < NEW.play_count THEN
        UPDATE Track SET popularity = popularity + 1 WHERE track_id = NEW.track_id;
    END IF;
END //
DELIMITER ;

-- Примерни жанрове
INSERT INTO Genre (name) VALUES ('Pop'), ('Rock'), ('Jazz');

-- Примерни държави
INSERT INTO Country (name) VALUES ('USA'), ('Canada'), ('UK');

-- Примерни артисти
INSERT INTO Artist (name, genre_id) VALUES ('Taylor Swift A', 1), ('100 Kila', 2), ('Toni Storaro', 3);

-- Примерни албуми
INSERT INTO Album (artist_id, title, release_date) VALUES (1, 'Album 1', '2020-01-01'), (2, 'Album 2', '2021-05-12');

-- Примерни песни
INSERT INTO Track (album_id, artist_id, genre_id, title, length) VALUES (1, 1, 1, 'Song 1', '00:03:45'), (2, 2, 2, 'Song 2', '00:04:20');

-- Примерни потребители
INSERT INTO User (username, email, password, date_of_birth, country_id) VALUES ('user1', 'user1@example.com', 'password123', '1990-05-12', 1);

-- Примерен абонамент
INSERT INTO Subscription (user_id, type, start_date, end_date) VALUES (1, 'Premium', '2023-01-01', '2024-01-01');

-- Примерен плейлист
INSERT INTO Playlist (user_id, title) VALUES (1, 'My Playlist');

-- Примерни връзки потребител/песен
INSERT INTO User_Track (user_id, track_id, play_count, added_to_favorites) VALUES (1, 1, 10, TRUE);


