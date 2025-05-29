-- dest.prereq: config/db/1722614396_create_db

CREATE TABLE IF NOT EXISTS org (
    org_id        INTEGER PRIMARY KEY,
    name          TEXT    NOT NULL UNIQUE CHECK( LENGTH(name)    > 0 ),
    acronym       TEXT    NOT NULL UNIQUE CHECK( LENGTH(acronym) > 0 ),
    address       TEXT    NOT NULL CHECK( LENGTH(address) > 0 ),
    last_modified TEXT    NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' ) ),
    created       TEXT    NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' ) ),
    active        INTEGER NOT NULL CHECK( active = 1 OR active = 0 ) DEFAULT 1
);
CREATE TRIGGER IF NOT EXISTS org_last_modified
    AFTER UPDATE OF
        name,
        acronym,
        address,
        created,
        active
    ON org
    BEGIN
        UPDATE org
            SET last_modified = STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' )
            WHERE org_id = OLD.org_id;
    END;

CREATE TABLE IF NOT EXISTS region (
    region_id     INTEGER PRIMARY KEY,
    name          TEXT    NOT NULL UNIQUE CHECK( LENGTH(name)    > 0 ),
    acronym       TEXT    NOT NULL UNIQUE CHECK( LENGTH(acronym) > 0 ),
    secret        TEXT    NOT NULL UNIQUE CHECK( LENGTH(secret)  > 0 ),
    last_modified TEXT    NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' ) ),
    created       TEXT    NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' ) ),
    active        INTEGER NOT NULL CHECK( active = 1 OR active = 0 ) DEFAULT 1
);
CREATE TRIGGER IF NOT EXISTS region_last_modified
    AFTER UPDATE OF
        name,
        acronym,
        secret,
        created,
        active
    ON region
    BEGIN
        UPDATE region
            SET last_modified = STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' )
            WHERE region_id = OLD.region_id;
    END;

CREATE TABLE IF NOT EXISTS user_org (
    user_org_id INTEGER PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES user(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
    org_id      INTEGER NOT NULL REFERENCES org(org_id)   ON UPDATE CASCADE ON DELETE CASCADE,
    created     TEXT    NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' ) )
);

CREATE TABLE IF NOT EXISTS user_region (
    user_region_id INTEGER PRIMARY KEY,
    user_id        INTEGER NOT NULL REFERENCES user(user_id)     ON UPDATE CASCADE ON DELETE CASCADE,
    region_id      INTEGER NOT NULL REFERENCES region(region_id) ON UPDATE CASCADE ON DELETE CASCADE,
    created        TEXT    NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' ) )
);

CREATE TABLE IF NOT EXISTS org_region (
    org_region_id INTEGER PRIMARY KEY,
    org_id        INTEGER NOT NULL REFERENCES org(org_id)       ON UPDATE CASCADE ON DELETE CASCADE,
    region_id     INTEGER NOT NULL REFERENCES region(region_id) ON UPDATE CASCADE ON DELETE CASCADE,
    created       TEXT    NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' ) )
);

CREATE TABLE IF NOT EXISTS registration (
    registration_id INTEGER PRIMARY KEY,
    user_id         INTEGER NOT NULL REFERENCES user(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
    org_id          INTEGER NOT NULL REFERENCES org(org_id)   ON UPDATE CASCADE ON DELETE CASCADE,
    info            TEXT    NOT NULL,
    created         TEXT    NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' ) )
);
