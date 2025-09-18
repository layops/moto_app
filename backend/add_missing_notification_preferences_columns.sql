-- NotificationPreferences tablosuna eksik sütunları ekle
-- Önce mevcut sütunları kontrol et:
-- SELECT column_name FROM information_schema.columns WHERE table_name = 'notifications_notificationpreferences';

-- Eksik sütunları ekle (sadece mevcut olmayanları):
DO $$ 
BEGIN
    -- likes_comments sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'notifications_notificationpreferences' 
                   AND column_name = 'likes_comments') THEN
        ALTER TABLE notifications_notificationpreferences 
        ADD COLUMN likes_comments BOOLEAN DEFAULT TRUE;
    END IF;

    -- follows sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'notifications_notificationpreferences' 
                   AND column_name = 'follows') THEN
        ALTER TABLE notifications_notificationpreferences 
        ADD COLUMN follows BOOLEAN DEFAULT TRUE;
    END IF;

    -- ride_reminders sütunu (zaten mevcut olabilir)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'notifications_notificationpreferences' 
                   AND column_name = 'ride_reminders') THEN
        ALTER TABLE notifications_notificationpreferences 
        ADD COLUMN ride_reminders BOOLEAN DEFAULT TRUE;
    END IF;

    -- event_updates sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'notifications_notificationpreferences' 
                   AND column_name = 'event_updates') THEN
        ALTER TABLE notifications_notificationpreferences 
        ADD COLUMN event_updates BOOLEAN DEFAULT TRUE;
    END IF;

    -- group_activity sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'notifications_notificationpreferences' 
                   AND column_name = 'group_activity') THEN
        ALTER TABLE notifications_notificationpreferences 
        ADD COLUMN group_activity BOOLEAN DEFAULT TRUE;
    END IF;

    -- new_members sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'notifications_notificationpreferences' 
                   AND column_name = 'new_members') THEN
        ALTER TABLE notifications_notificationpreferences 
        ADD COLUMN new_members BOOLEAN DEFAULT TRUE;
    END IF;

    -- challenges_rewards sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'notifications_notificationpreferences' 
                   AND column_name = 'challenges_rewards') THEN
        ALTER TABLE notifications_notificationpreferences 
        ADD COLUMN challenges_rewards BOOLEAN DEFAULT TRUE;
    END IF;

    -- leaderboard_updates sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'notifications_notificationpreferences' 
                   AND column_name = 'leaderboard_updates') THEN
        ALTER TABLE notifications_notificationpreferences 
        ADD COLUMN leaderboard_updates BOOLEAN DEFAULT TRUE;
    END IF;

    -- sound_enabled sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'notifications_notificationpreferences' 
                   AND column_name = 'sound_enabled') THEN
        ALTER TABLE notifications_notificationpreferences 
        ADD COLUMN sound_enabled BOOLEAN DEFAULT TRUE;
    END IF;

    -- vibration_enabled sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'notifications_notificationpreferences' 
                   AND column_name = 'vibration_enabled') THEN
        ALTER TABLE notifications_notificationpreferences 
        ADD COLUMN vibration_enabled BOOLEAN DEFAULT TRUE;
    END IF;

    -- push_enabled sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'notifications_notificationpreferences' 
                   AND column_name = 'push_enabled') THEN
        ALTER TABLE notifications_notificationpreferences 
        ADD COLUMN push_enabled BOOLEAN DEFAULT TRUE;
    END IF;

    -- fcm_token sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'notifications_notificationpreferences' 
                   AND column_name = 'fcm_token') THEN
        ALTER TABLE notifications_notificationpreferences 
        ADD COLUMN fcm_token TEXT NULL;
    END IF;

    -- created_at sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'notifications_notificationpreferences' 
                   AND column_name = 'created_at') THEN
        ALTER TABLE notifications_notificationpreferences 
        ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;

    -- updated_at sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'notifications_notificationpreferences' 
                   AND column_name = 'updated_at') THEN
        ALTER TABLE notifications_notificationpreferences 
        ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;
