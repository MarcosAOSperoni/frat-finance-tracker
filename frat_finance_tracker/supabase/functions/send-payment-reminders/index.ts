// Edge Function to send personalized FCM payment reminder notifications
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Reuse the same OAuth 2.0 token helper as send-dues-notification
async function getAccessToken(): Promise<string> {
  const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') || '{}')

  const now = Math.floor(Date.now() / 1000)
  const claim = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  }

  const header = { alg: 'RS256', typ: 'JWT' }
  const encodedHeader = btoa(JSON.stringify(header))
  const encodedClaim = btoa(JSON.stringify(claim))
  const unsignedToken = `${encodedHeader}.${encodedClaim}`

  const encoder = new TextEncoder()
  const data = encoder.encode(unsignedToken)

  const pemKey = serviceAccount.private_key
  const pemContents = pemKey
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '')

  const binaryKey = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  )

  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', cryptoKey, data)

  const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')

  const jwt = `${unsignedToken}.${encodedSignature}`

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })

  const tokenData = await tokenResponse.json()
  return tokenData.access_token
}

async function sendFCMNotification(
  token: string,
  title: string,
  body: string,
  accessToken: string
) {
  const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') || '{}')
  const projectId = serviceAccount.project_id

  const message = {
    message: {
      token,
      notification: { title, body },
      data: {
        type: 'payment_reminder',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      apns: {
        payload: {
          aps: { sound: 'default', badge: 1 },
        },
      },
    },
  }

  return fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(message),
    }
  )
}

function formatDate(dateStr: string): string {
  const date = new Date(dateStr)
  return date.toLocaleDateString('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  })
}

function formatAmount(amount: number): string {
  return amount.toFixed(2)
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // 1. Get all unpaid brother_dues with their payment plan info
    //    Select nested: payment_plans -> scheduled_payments (pending only)
    const { data: unpaidDues, error: duesError } = await supabase
      .from('brother_dues')
      .select(`
        id,
        brother_id,
        total_amount,
        amount_paid,
        due_date,
        status,
        payment_plans (
          id,
          scheduled_payments (
            scheduled_amount,
            scheduled_date,
            status
          )
        )
      `)
      .neq('status', 'paid')

    if (duesError) {
      throw new Error(`Failed to fetch unpaid dues: ${duesError.message}`)
    }

    if (!unpaidDues || unpaidDues.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No brothers with unpaid dues', successCount: 0, failureCount: 0 }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    // 2. Build a map of brother_id → next payment info
    //    If multiple dues periods, use the earliest pending scheduled payment across all
    interface NextPayment {
      amount: number
      date: string
    }

    const brotherNextPayment = new Map<string, NextPayment>()

    for (const due of unpaidDues) {
      const brotherId = due.brother_id as string
      const paymentPlan = due.payment_plans as { scheduled_payments: { scheduled_amount: number; scheduled_date: string; status: string }[] } | null

      let nextPayment: NextPayment | null = null

      if (paymentPlan && paymentPlan.scheduled_payments?.length > 0) {
        // Find the earliest pending scheduled payment
        const pending = paymentPlan.scheduled_payments
          .filter((sp) => sp.status === 'pending')
          .sort((a, b) => new Date(a.scheduled_date).getTime() - new Date(b.scheduled_date).getTime())

        if (pending.length > 0) {
          nextPayment = {
            amount: pending[0].scheduled_amount,
            date: pending[0].scheduled_date,
          }
        }
      }

      // Fall back to the dues due_date with remaining balance
      if (!nextPayment) {
        const remaining = (due.total_amount as number) - (due.amount_paid as number)
        if (remaining > 0) {
          nextPayment = {
            amount: remaining,
            date: due.due_date as string,
          }
        }
      }

      if (!nextPayment) continue

      // Keep the earlier of two entries for the same brother
      const existing = brotherNextPayment.get(brotherId)
      if (!existing || new Date(nextPayment.date) < new Date(existing.date)) {
        brotherNextPayment.set(brotherId, nextPayment)
      }
    }

    if (brotherNextPayment.size === 0) {
      return new Response(
        JSON.stringify({ message: 'No actionable dues found', successCount: 0, failureCount: 0 }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    // 3. Fetch FCM tokens for the brothers with unpaid dues
    const brotherIds = Array.from(brotherNextPayment.keys())

    const { data: tokens, error: tokensError } = await supabase
      .from('fcm_tokens')
      .select('user_id, token')
      .in('user_id', brotherIds)

    if (tokensError) {
      throw new Error(`Failed to fetch FCM tokens: ${tokensError.message}`)
    }

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No FCM tokens found for brothers with unpaid dues', successCount: 0, failureCount: 0 }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    console.log(`Sending payment reminders to ${tokens.length} devices for ${brotherNextPayment.size} brothers`)

    // 4. Get OAuth access token
    const accessToken = await getAccessToken()

    // 5. Send personalized notifications
    const notificationTitle = 'Payment Reminder'

    const results = await Promise.allSettled(
      tokens.map(({ user_id, token }) => {
        const next = brotherNextPayment.get(user_id as string)
        const body = next
          ? `You owe $${formatAmount(next.amount)} due on ${formatDate(next.date)}`
          : 'You have unpaid dues'

        return sendFCMNotification(token as string, notificationTitle, body, accessToken)
      })
    )

    const successCount = results.filter((r) => r.status === 'fulfilled').length
    const failureCount = results.filter((r) => r.status === 'rejected').length

    console.log(`Payment reminders sent: ${successCount} success, ${failureCount} failed`)

    return new Response(
      JSON.stringify({
        message: 'Payment reminders sent',
        successCount,
        failureCount,
        brothersTargeted: brotherNextPayment.size,
        devicesTargeted: tokens.length,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('Error sending payment reminders:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})
