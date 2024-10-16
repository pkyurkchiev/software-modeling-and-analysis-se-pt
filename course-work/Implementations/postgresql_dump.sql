create table users
(
    user_id       serial
        primary key,
    username      varchar(100) not null,
    email         varchar(100) not null,
    password      varchar(100) not null,
    bio           text,
    profile_image varchar(255),
    signup_date   date         not null,
    user_type     varchar(50),
    photo_count   integer default 0
);

alter table users
    owner to postgres;

create table photos
(
    photo_id    serial
        primary key,
    title       varchar(255) not null,
    description text,
    upload_date date         not null,
    image_url   varchar(255) not null,
    views_count integer,
    resolution  varchar(50),
    user_id     integer
        references users
);

alter table photos
    owner to postgres;

create table categories
(
    category_id   serial
        primary key,
    category_name varchar(100) not null
);

alter table categories
    owner to postgres;

create table tags
(
    tag_id   serial
        primary key,
    tag_name varchar(100) not null
);

alter table tags
    owner to postgres;

create table downloads
(
    download_id   serial
        primary key,
    photo_id      integer
        references photos,
    user_id       integer
        references users,
    download_date date not null
);

alter table downloads
    owner to postgres;

create table comments
(
    comment_id   serial
        primary key,
    photo_id     integer
        references photos,
    user_id      integer
        references users,
    comment_text text not null,
    comment_date date not null
);

alter table comments
    owner to postgres;

create table likes
(
    like_id   serial
        primary key,
    photo_id  integer
        references photos,
    user_id   integer
        references users,
    like_date date not null
);

alter table likes
    owner to postgres;

create table collections
(
    collection_id   serial
        primary key,
    collection_name varchar(255) not null,
    user_id         integer
        references users
);

alter table collections
    owner to postgres;

create table photo_tags
(
    photo_id integer not null
        references photos,
    tag_id   integer not null
        references tags,
    primary key (photo_id, tag_id)
);

alter table photo_tags
    owner to postgres;

create table photo_collections
(
    photo_id      integer not null
        references photos,
    collection_id integer not null
        references collections,
    primary key (photo_id, collection_id)
);

alter table photo_collections
    owner to postgres;

create table collection_to_photo
(
    entry_id      serial
        primary key,
    collection_id integer
        references collections,
    photo_id      integer
        references photos
);

alter table collection_to_photo
    owner to postgres;

create function getuserphotos(user_id integer)
    returns TABLE(photo_id integer, title character varying, description text, upload_date date, image_url character varying)
    language plpgsql
as
$$
BEGIN
    RETURN QUERY SELECT * FROM Photos WHERE user_id = GetUserPhotos(user_id);
END;
$$;

alter function getuserphotos(integer) owner to postgres;

create function getphotodownloads(photo_id integer)
    returns TABLE(downloadcount integer)
    language plpgsql
as
$$
BEGIN
    RETURN QUERY SELECT COUNT(download_id) AS DownloadCount FROM Downloads WHERE photo_id = GetPhotoDownloads.photo_id;
END;
$$;

alter function getphotodownloads(integer) owner to postgres;

create function getaveragerating(photo_id integer) returns numeric
    language plpgsql
as
$$
DECLARE
    avg_rating DECIMAL(5, 2);
BEGIN
    SELECT AVG(rating) INTO avg_rating FROM Ratings WHERE photo_id = GetAverageRating.photo_id;
    RETURN avg_rating;
END;
$$;

alter function getaveragerating(integer) owner to postgres;

create function getphotocountbycategory(category_id integer) returns integer
    language plpgsql
as
$$
DECLARE
    photo_count INT;
BEGIN
    SELECT COUNT(photo_id) INTO photo_count FROM Photos WHERE category_id = GetPhotoCountByCategory.category_id;
    RETURN photo_count;
END;
$$;

alter function getphotocountbycategory(integer) owner to postgres;

create function updateuserphotocount() returns trigger
    language plpgsql
as
$$
BEGIN
    UPDATE Users
    SET photo_count = photo_count + 1
    WHERE user_id = NEW.user_id;
    RETURN NEW;
END;
$$;

alter function updateuserphotocount() owner to postgres;

create trigger trg_updateuserphotocount
    after insert
    on photos
    for each row
execute procedure updateuserphotocount();

create function deleteuserphotos() returns trigger
    language plpgsql
as
$$
BEGIN
    DELETE FROM Photos WHERE user_id = OLD.user_id;
    RETURN OLD;
END;
$$;

alter function deleteuserphotos() owner to postgres;

create trigger trg_deleteuserphotos
    after delete
    on users
    for each row
execute procedure deleteuserphotos();

create function decrementuserphotocount() returns trigger
    language plpgsql
as
$$
BEGIN
    UPDATE Users
    SET photo_count = photo_count - 1
    WHERE user_id = OLD.user_id;
    RETURN OLD;
END;
$$;

alter function decrementuserphotocount() owner to postgres;

create trigger trg_decrementuserphotocount
    after delete
    on photos
    for each row
execute procedure decrementuserphotocount();

