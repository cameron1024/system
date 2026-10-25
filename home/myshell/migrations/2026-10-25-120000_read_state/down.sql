DROP INDEX notifications_order;

ALTER TABLE notifications RENAME COLUMN read_at TO dismissed_at;

CREATE INDEX notifications_unread ON notifications (received_at) WHERE dismissed_at IS NULL;
