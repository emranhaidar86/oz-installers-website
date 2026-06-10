// Netlify Function — GET /api/settings
// Public endpoint: no auth required.
// Query params:
//   ?category=pricing   → all settings in that category
//   ?key=pricing.tv.small → single setting by exact key
//   (no params)         → all settings

const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Content-Type': 'application/json'
};

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 204, headers: cors, body: '' };
  }
  if (event.httpMethod !== 'GET') {
    return { statusCode: 405, headers: cors, body: JSON.stringify({ error: 'Method not allowed' }) };
  }

  const { category, key } = event.queryStringParameters || {};

  const baseQuery = supabase
    .from('app_settings')
    .select('key, value, label, description, category, data_type, updated_at');

  // Single-key lookup
  if (key) {
    const { data, error } = await baseQuery.eq('key', key).single();
    if (error) {
      const status = error.code === 'PGRST116' ? 404 : 500;
      return { statusCode: status, headers: cors, body: JSON.stringify({ error: error.message }) };
    }
    return {
      statusCode: 200,
      headers: { ...cors, 'Cache-Control': 'no-store' },
      body: JSON.stringify({ data })
    };
  }

  // Filtered or full list
  let query = category ? baseQuery.eq('category', category) : baseQuery;
  query = query.order('category').order('key');

  const { data, error } = await query;
  if (error) {
    return { statusCode: 500, headers: cors, body: JSON.stringify({ error: error.message }) };
  }

  return {
    statusCode: 200,
    headers: { ...cors, 'Cache-Control': 'no-store' },
    body: JSON.stringify({ data })
  };
};
