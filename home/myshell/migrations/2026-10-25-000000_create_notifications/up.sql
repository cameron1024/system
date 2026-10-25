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
    -- Set when dismissed, acted on, or closed by the sender; NULL while unread.
    dismissed_at BIGINT
);

CREATE INDEX notifications_unread ON notifications (received_at) WHERE dismissed_at IS NULL;
