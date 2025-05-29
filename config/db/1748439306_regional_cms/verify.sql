SELECT CASE WHEN
    ( SELECT 1 FROM sqlite_master WHERE type = 'table'   AND name = 'org'                  ) +
    ( SELECT 1 FROM sqlite_master WHERE type = 'trigger' AND name = 'org_last_modified'    ) +
    ( SELECT 1 FROM sqlite_master WHERE type = 'table'   AND name = 'region'               ) +
    ( SELECT 1 FROM sqlite_master WHERE type = 'trigger' AND name = 'region_last_modified' ) +
    ( SELECT 1 FROM sqlite_master WHERE type = 'table'   AND name = 'user_org'             ) +
    ( SELECT 1 FROM sqlite_master WHERE type = 'table'   AND name = 'user_region'          ) +
    ( SELECT 1 FROM sqlite_master WHERE type = 'table'   AND name = 'org_region'           ) +
    ( SELECT 1 FROM sqlite_master WHERE type = 'table'   AND name = 'registration'         )
    = 8
THEN 1 ELSE 0 END;
