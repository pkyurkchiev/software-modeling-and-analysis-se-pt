create or replace function updatesubscribersoninsert() returns trigger
    language plpgsql
as
$$
BEGIN
    UPDATE UserManagement.UserAccount
    SET Subscribers = COALESCE(Subscribers, 0) + 1
    WHERE Email = NEW.ToUserAccountEmail;

    RETURN NEW;
END;
$$;

alter function updatesubscribersoninsert() owner to lubodimoff;

create or replace function updatesubscribersondelete() returns trigger
    language plpgsql
as
$$
BEGIN
    UPDATE UserManagement.UserAccount
    SET Subscribers = COALESCE(Subscribers, 0) - 1
    WHERE Email = OLD.ToUserAccountEmail;

    RETURN OLD;
END;
$$;

alter function updatesubscribersondelete() owner to lubodimoff;

