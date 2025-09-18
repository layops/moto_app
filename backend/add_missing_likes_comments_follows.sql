-- Sadece eksik olan likes_comments ve follows sütunlarını ekle
ALTER TABLE notifications_notificationpreferences 
ADD COLUMN likes_comments BOOLEAN DEFAULT TRUE;

ALTER TABLE notifications_notificationpreferences 
ADD COLUMN follows BOOLEAN DEFAULT TRUE;
