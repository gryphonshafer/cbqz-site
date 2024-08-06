CREATE TABLE IF NOT EXISTS user (
    user_id       INTEGER PRIMARY KEY,
    email         TEXT    NOT NULL CHECK( email LIKE '%_@__%.__%' ) UNIQUE,
    passwd        TEXT    NOT NULL CHECK( LENGTH(passwd)     >= 8 ),
    first_name    TEXT    NOT NULL CHECK( LENGTH(first_name) >  0 ),
    last_name     TEXT    NOT NULL CHECK( LENGTH(last_name)  >  0 ),
    phone         TEXT    NOT NULL CHECK( LENGTH(phone)      >  0 ),
    info          TEXT,
    last_login    TEXT,
    last_modified TEXT    NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' ) ),
    created       TEXT    NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' ) ),
    active        INTEGER NOT NULL CHECK( active = 1 OR active = 0 ) DEFAULT 0
);
CREATE TRIGGER IF NOT EXISTS user_last_modified
    AFTER UPDATE OF
        email,
        passwd,
        first_name,
        last_name,
        phone,
        info,
        last_login,
        active
    ON user
    BEGIN
        UPDATE user
            SET last_modified = STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' )
            WHERE user_id = OLD.user_id;
    END;

CREATE TABLE IF NOT EXISTS meeting (
    meeting_id INTEGER PRIMARY KEY,
    start      TEXT NOT NULL,
    location   TEXT NOT NULL,
    info       TEXT,
    created    TEXT NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' ) )
);

CREATE TABLE IF NOT EXISTS user_meeting (
    user_meeting_id INTEGER PRIMARY KEY,
    user_id         INTEGER NOT NULL REFERENCES user(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
    meeting_id      INTEGER NOT NULL REFERENCES meeting(meeting_id) ON UPDATE CASCADE ON DELETE CASCADE,
    info            TEXT,
    last_modified   TEXT    NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' ) ),
    created         TEXT    NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' ) )
);
CREATE UNIQUE INDEX IF NOT EXISTS user_meetings ON user_meeting ( user_id, meeting_id );
CREATE TRIGGER IF NOT EXISTS user_meeting_last_modified
    AFTER UPDATE OF
        user_id,
        meeting_id,
        info
    ON user_meeting
    BEGIN
        UPDATE user_meeting
            SET last_modified = STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' )
            WHERE user_meeting_id = OLD.user_meeting_id;
    END;
