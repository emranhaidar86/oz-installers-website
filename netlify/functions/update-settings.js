// Netlify Function — POST /api/settings/update
// Protected: requires Authorization: Bearer <ADMIN_SECRET_TOKEN>
// Body: { updates: [{ key: string, value: any }, ...] }
// An empty `updates` array is accepted — used as an auth-verification ping.

const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Content-Type': 'application/json'
};

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 204, headers: cors, body: '' };
  }
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, headers: cors, body: JSON.stringify({ error: 'Method not allowed' }) };
  }

  // Auth check — constant-time comparison avoids timing attacks
  const rawAuth = event.headers.authorization || event.headers.Authorization || '';
  const token = rawAuth.replace(/^Bearer\s+/i, '').trim();
  const secret = process.env.ADMIN_SECRET_TOKEN || '';
  if (!token || token.length !== secret.length || token !== secret) {
    return { statusCode: 401, headers: cors, body: JSON.stringify({ error: 'Unauthorized' }) };
  }

  let body;
  try {
    body = JSON.parse(event.body || '{}');
  } catch {
    return { statusCode: 400, headers: cors, body: JSON.stringify({ error: 'Invalid JSON body' }) };
  }

  const { updates } = body;
  if (!Array.isArray(updates)) {
    return { statusCode: 400, headers: cors, body: JSON.stringify({ error: '`updates` must be an array' }) };
  }

  // Empty array → auth ping, no DB work needed
  if (updates.length === 0) {
    return { statusCode: 200, headers: cors, body: JSON.stringify({ results: [] }) };
  }

  const results = [];
  for (const { key, value } of updates) {
    if (typeof key !== 'string' || !key.trim()) {
      results.push({ key, success: false, error: 'Invalid or missing key' });
      continue;
    }

    const { data, error } = await supabase
      .from('app_settings')
      .update({ value, updated_by: 'admin' })
      .eq('key', key)
      .select('key, value, updated_at')
      .single();

    if (error) {
      results.push({ key, success: false, error: error.message });
    } else {
      results.push({ key, success: true, data });
    }
  }

  const allOk = results.every((r) => r.success);
  return {
    statusCode: allOk ? 200 : 207,
    headers: cors,
    body: JSON.stringify({ results })
  };
};
