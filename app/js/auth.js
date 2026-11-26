// Login, sessão e usuário logado.
import { supabase } from './supabase.js';
import { DOMINIO_PERMITIDO } from './config.js';

const pasta = () => location.href.replace(/[?#].*$/, '').replace(/[^/]*$/, '');

export async function entrarComGoogle() {
  const { error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: pasta() + 'index.html',
      queryParams: { hd: DOMINIO_PERMITIDO, prompt: 'select_account' },
    },
  });
  if (error) throw error;
}

export async function sair() {
  await supabase.auth.signOut();
  location.href = pasta() + 'index.html';
}

/**
 * Confere a sessão e o cadastro em `usuarios`.
 * Devolve { sessao, usuario } ou { motivo } quando não pode entrar.
 * O RLS só devolve a linha se o usuário existe e está ativo.
 */
export async function usuarioAtual() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return { motivo: 'sem_sessao' };

  const email = (session.user.email || '').toLowerCase();
  if (!email.endsWith('@' + DOMINIO_PERMITIDO)) return { motivo: 'dominio', email };

  const { data, error } = await supabase
    .from('usuarios')
    .select('id, empresa_id, nome, email, papel, ativo')
    .eq('id', session.user.id)
    .maybeSingle();

  if (error) return { motivo: 'erro', erro: error, email };
  if (!data || !data.ativo) return { motivo: 'nao_cadastrado', email };

  const usuario = { ...data, admin: ['gestor', 'planejamento'].includes(data.papel) };
  return { sessao: session, usuario };
}

/** Para as telas internas: sem login válido, volta para o login. */
export async function exigirLogin() {
  const r = await usuarioAtual();
  if (!r.usuario) {
    location.replace(pasta() + 'index.html');
    return new Promise(() => {}); // para a tela aqui
  }
  return r.usuario;
}
