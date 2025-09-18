import { createClient } from 'npm:@supabase/supabase-js@2'

interface Notification {
  id: string
  recipient_id: string
  message: string
  notification_type: string
  sender_id?: string
  timestamp: string
}

interface WebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE'
  table: string
  record: Notification
  schema: 'public'
  old_record: null | Notification
}

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

// FCM Server Key
const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')

Deno.serve(async (req) => {
  try {
    const payload: WebhookPayload = await req.json()

    console.log('Push notification webhook triggered:', payload.type, payload.table)

    // Sadece INSERT event'lerini işle
    if (payload.type !== 'INSERT' || payload.table !== 'notifications_notification') {
      return new Response('Event not handled', { status: 200 })
    }

    const notification = payload.record

    // Kullanıcının push notification tercihlerini kontrol et
    const { data: preferences, error } = await supabase
      .from('notifications_notificationpreferences')
      .select('push_enabled, fcm_token')
      .eq('user_id', notification.recipient_id)
      .single()

    if (error) {
      console.error('Error fetching user preferences:', error)
      return new Response('User preferences not found', { status: 404 })
    }

    // Push notification kapalıysa işleme devam etme
    if (!preferences.push_enabled) {
      console.log('Push notification disabled for user:', notification.recipient_id)
      return new Response('Push notification disabled', { status: 200 })
    }

    // FCM token varsa gerçek push notification gönder
    if (preferences.fcm_token && FCM_SERVER_KEY) {
      try {
        const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
          method: 'POST',
          headers: {
            'Authorization': `key=${FCM_SERVER_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            to: preferences.fcm_token,
            notification: {
              title: 'MotoApp',
              body: notification.message,
              icon: 'ic_launcher',
              sound: 'default',
            },
            data: {
              notification_id: notification.id,
              notification_type: notification.notification_type,
              sender_id: notification.sender_id || '',
            },
          }),
        })

        if (fcmResponse.ok) {
          console.log('FCM push notification sent successfully')
          return new Response(JSON.stringify({
            success: true,
            notification_id: notification.id,
            method: 'fcm_push'
          }), {
            headers: { 'Content-Type': 'application/json' },
          })
        } else {
          console.error('FCM push notification failed:', await fcmResponse.text())
        }
      } catch (fcmError) {
        console.error('FCM push notification error:', fcmError)
      }
    }

    // FCM başarısız olursa Supabase real-time notification gönder
    const realtimeResponse = await supabase
      .channel('notifications')
      .send({
        type: 'broadcast',
        event: 'notification',
        payload: {
          user_id: notification.recipient_id,
          notification: {
            id: notification.id,
            message: notification.message,
            notification_type: notification.notification_type,
            sender_id: notification.sender_id,
            timestamp: notification.timestamp,
          }
        }
      })

    if (realtimeResponse.error) {
      console.error('Supabase real-time notification failed:', realtimeResponse.error)
      return new Response(JSON.stringify({
        success: false,
        error: realtimeResponse.error.message
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    console.log('Supabase real-time notification sent successfully')
    return new Response(JSON.stringify({
      success: true,
      notification_id: notification.id,
      method: 'supabase_realtime'
    }), {
      headers: { 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('Push notification webhook error:', error)
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
