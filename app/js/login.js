import { supabase, configurado } from './supabase.js';
import { entrarComGoogle, usuarioAtual } from './auth.js';

const btn = document.getElementById('google');
const msg = document.getElementById('msg');

function mostrar(texto, tipo = 'erro') {
  msg.className = 'msg msg-' + tipo;
  msg.textContent = texto;
  msg.hidden = false;
}

function ocupado(sim) {
  btn.disabled = sim;
  btn.querySelector('span').textContent = sim ? 'Entrando…' : 'Entrar com Google';
}

async function conferir() {
  ocupado(true);
  const r = await usuarioAtual();
  if (r.usuario) { location.replace('painel.html'); return; }

  ocupado(false);
  if (r.motivo === 'sem_sessao') return;

  // Tem sessão do Google, mas não pode entrar: encerra a sessão e explica.
  await supabase.auth.signOut();
  if (r.motivo === 'dominio') {
    mostrar(`A conta ${r.email} não é da EXP. Entre com uma conta @exp.rec.br.`);
  } else if (r.motivo === 'nao_cadastrado') {
    mostrar(`A conta ${r.email} ainda não tem acesso ao Backstage. Peça o cadastro ao gestor ou ao planejamento.`);
  } else {
    mostrar('Não foi possível conferir seu cadastro agora. Tente de novo em instantes.');
    console.error(r.erro);
  }
}

btn.addEventListener('click', async () => {
  if (!configurado) { mostrar('Supabase ainda não configurado: preencha app/js/config.js.', 'info'); return; }
  ocupado(true);
  try { await entrarComGoogle(); }
  catch (e) { ocupado(false); mostrar('Não foi possível abrir o login do Google. Tente de novo.'); console.error(e); }
});

// Erro devolvido pelo Google/Supabase na volta do login (ex.: acesso negado)
const p = new URLSearchParams(location.search + '&' + location.hash.slice(1));
if (p.get('error')) {
  mostrar(p.get('error_description') || 'O login foi cancelado.');
  history.replaceState(null, '', location.pathname);
} else if (configurado) {
  conferir();
} else {
  mostrar('Supabase ainda não configurado: preencha app/js/config.js.', 'info');
}
