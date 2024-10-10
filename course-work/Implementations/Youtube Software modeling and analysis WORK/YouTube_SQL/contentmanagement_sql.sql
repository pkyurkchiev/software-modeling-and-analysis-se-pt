create table if not exists categories
(
    genre       varchar(100) not null
        primary key,
    description text
);

alter table categories
    owner to lubodimoff;

create table if not exists video
(
    url              text         not null
        primary key,
    useraccountemail varchar(150) not null,
    genre            varchar(100) not null
        references categories,
    title            varchar(100),
    published        timestamp    not null,
    duration         time         not null,
    description      text
);

alter table video
    owner to lubodimoff;

create table if not exists comments
(
    url              text         not null
        references video,
    useraccountemail varchar(150) not null
        references usermanagement.useraccount,
    commenttext      text,
    commentdate      timestamp,
    primary key (url, useraccountemail)
);

alter table comments
    owner to lubodimoff;

create table if not exists likes
(
    url              text         not null
        references video,
    useraccountemail varchar(150) not null
        references usermanagement.useraccount,
    isliked          boolean,
    likedate         timestamp
);

alter table likes
    owner to lubodimoff;

create table if not exists playlistvideo
(
    playlistname     varchar(150) not null,
    useraccountemail varchar(150) not null
        references usermanagement.useraccount,
    url              text         not null
        references video,
    primary key (playlistname, url, useraccountemail),
    foreign key (playlistname, useraccountemail) references usermanagement.playlist
);

alter table playlistvideo
    owner to lubodimoff;

create or replace procedure addvideo(IN p_url text, IN p_useraccountemail character varying,
                                     IN p_genre character varying, IN p_title character varying,
                                     IN p_published timestamp without time zone, IN p_duration time without time zone,
                                     IN p_description text)
    language plpgsql
as
$$
BEGIN
    INSERT INTO ContentManagement.Video
    (URL, UserAccountEmail, Genre, Title, Published, Duration, Description)
    VALUES (p_URL, p_UserAccountEmail, p_Genre, p_Title, p_Published, p_Duration, p_Description);
END;
$$;

alter procedure addvideo(text, varchar, varchar, varchar, timestamp, time, text) owner to lubodimoff;

create or replace procedure addcategory(IN p_genre character varying, IN p_description text)
    language plpgsql
as
$$
BEGIN
    INSERT INTO ContentManagement.Categories
    (Genre, Description)
    VALUES (p_Genre, p_Description);
END;
$$;

alter procedure addcategory(varchar, text) owner to lubodimoff;

create or replace function getvideodurationinminutes(p_url text) returns integer
    language plpgsql
as
$$
DECLARE
    v_Duration    TIME;
    total_minutes INT;
BEGIN

    SELECT Duration
    INTO v_Duration
    FROM ContentManagement.Video
    WHERE URL = p_URL;

    total_minutes := EXTRACT(EPOCH FROM (v_Duration - '00:00:00'::TIME)) / 60;

    IF total_minutes >= 60 THEN
        RETURN total_minutes % 60;
    ELSE
        RETURN total_minutes;
    END IF;
END;
$$;

alter function getvideodurationinminutes(text) owner to lubodimoff;

create or replace function gettotalvideosbyuser(p_useraccountemail character varying) returns integer
    language plpgsql
as
$$
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

alter function gettotalvideosbyuser(varchar) owner to lubodimoff;

