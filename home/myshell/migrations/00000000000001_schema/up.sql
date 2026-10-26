CREATE TABLE notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    app_name TEXT NOT NULL,
    app_icon TEXT NOT NULL,
    summary TEXT NOT NULL,
    body TEXT NOT NULL,
    -- The action invoked by clicking the notification, if the sender offered one.
    default_action TEXT,
    -- Unix milliseconds.
    received_at BIGINT NOT NULL,
    -- NULL while unread.
    read_at BIGINT,
    -- A resolved image file, if any.
    icon TEXT
);

-- The dropdown's order (unread first, then newest first), so pages are index range scans.
CREATE INDEX notifications_order ON notifications ((read_at IS NOT NULL), received_at DESC, id DESC);

-- JSON values cached across restarts, e.g. whether a data source is available.
CREATE TABLE persisted (
    key TEXT PRIMARY KEY NOT NULL,
    value TEXT NOT NULL
);
