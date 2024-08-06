SELECT CASE WHEN
    ( SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'user'         ) +
    ( SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'meeting'      ) +
    ( SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'user_meeting' )
    = 3
THEN 1 ELSE 0 END;
