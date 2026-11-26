// Cliente único do Supabase, importado por todas as telas.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { SUPABASE_URL, SUPABASE_ANON_KEY } from './config.js';

// Trava: chave secreta (sb_secret_… ou service_role) ignora o RLS e nunca pode ir para o navegador.
function chaveSecreta(k) {
  if (k.startsWith('sb_secret_')) return true;
  try { return JSON.parse(atob(k.split('.')[1])).role === 'service_role'; } catch { return false; }
}
if (chaveSecreta(SUPABASE_ANON_KEY)) {
  throw new Error('config.js tem uma chave SECRETA. Use a chave publicável (sb_publishable_…) ou a anon key.');
}

export const configurado = !SUPABASE_URL.includes('SEU-PROJETO') && !SUPABASE_ANON_KEY.startsWith('COLE-AQUI');

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true, flowType: 'pkce' },
});
