-- Notifications are read or unread; dismissal is gone.
ALTER TABLE notifications RENAME COLUMN dismissed_at TO read_at;

DROP INDEX notifications_unread;

-- The dropdown's order (unread first, then newest first), so pages are index range scans.
CREATE INDEX notifications_order ON notifications ((read_at IS NOT NULL), received_at DESC, id DESC);
