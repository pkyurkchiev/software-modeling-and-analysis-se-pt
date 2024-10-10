create table if not exists useraccount
(
    email          varchar(150) not null
        primary key,
    username       varchar(36)  not null,
    password       varchar(127) not null,
    firstname      varchar(150) not null,
    lastname       varchar(150) not null,
    dateofcreation timestamp    not null,
    phonenumber    varchar(15),
    subscribers    bigint
);

alter table useraccount
    owner to lubodimoff;

create table if not exists subscription
(
    fromuseraccountemail varchar(150) not null
        references useraccount,
    touseraccountemail   varchar(150) not null
        references useraccount,
    subscriptiondate     timestamp    not null,
    primary key (fromuseraccountemail, touseraccountemail)
);

alter table subscription
    owner to lubodimoff;

create trigger addsubscriber
    after insert
    on subscription
    for each row
execute procedure public.updatesubscribersoninsert();

create trigger removesubscriber
    after delete
    on subscription
    for each row
execute procedure public.updatesubscribersondelete();

create table if not exists playlist
(
    playlistname     varchar(150) not null,
    useraccountemail varchar(150) not null
        references useraccount,
    creationdate     timestamp,
    primary key (playlistname, useraccountemail)
);

alter table playlist
    owner to lubodimoff;

create or replace procedure adduser(IN p_email character varying, IN p_username character varying, IN p_password character varying, IN p_firstname character varying, IN p_lastname character varying, IN p_dateofcreation timestamp without time zone, IN p_phonenumber character varying, IN p_subscribers bigint)
    language plpgsql
as
$$
BEGIN
    INSERT INTO UserManagement.UserAccount
    (
        Email, Username, Password, FirstName, LastName, DateOfCreation, PhoneNumber, Subscribers
    )
    VALUES
    (
        p_Email, p_Username, p_Password, p_FirstName, p_LastName, p_DateOfCreation, p_PhoneNumber, p_Subscribers
    );
END;
$$;

alter procedure adduser(varchar, varchar, varchar, varchar, varchar, timestamp, varchar, bigint) owner to lubodimoff;

