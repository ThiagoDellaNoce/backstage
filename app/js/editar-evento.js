// Editar evento: carrega o evento ?id= e grava dados + telas.
import { supabase } from './supabase.js';
import { exigirLogin } from './auth.js';
import { montarLayout, abasDoEvento } from './layout.js';
import { avisar } from './util.js';
import { desenharEditarEvento } from './editar-evento-view.js';

const usuario = await exigirLogin();
let main = montarLayout(usuario, 'eventos');
const id = Number(new URLSearchParams(location.search).get('id'));

async function carregar() {
  const ev = await supabase.from('eventos').select('*').eq('id', id).maybeSingle();
  if (ev.error) throw ev.error;
  if (!ev.data) return null;
  const [mod, cad, par] = await Promise.all([
    supabase.from('evento_modulos').select('modulo, ativo').eq('evento_id', id),
    supabase.from('modulos').select('codigo, nome, grupo, pergunta, sempre_ativo, disponivel, ordem'),
    supabase.from('parametros_dimensionamento').select('nome, pessoas_por_unidade, unidade, ordem'),
  ]);
  for (const r of [mod, cad, par]) if (r.error) throw r.error;
  return { evento: ev.data, ativos: mod.data.filter((m) => m.ativo).map((m) => m.modulo), modulos: cad.data, parametros: par.data };
}

async function salvar({ evento, modulos }) {
  const r = await supabase.from('eventos').update(evento, { count: 'exact' }).eq('id', id);
  if (r.error) throw r.error;
  if (!r.count) throw new Error('Você não tem permissão para editar este evento.');

  const linhas = Object.entries(modulos || {}).map(([modulo, ativo]) => ({ evento_id: id, modulo, ativo, alterado_por: usuario.id, alterado_em: new Date().toISOString() }));
  if (linhas.length) {
    const m = await supabase.from('evento_modulos').upsert(linhas, { onConflict: 'evento_id,modulo' });
    if (m.error) throw new Error(`Os dados foram salvos, mas as telas não: ${m.error.message}`);
  }
  avisar('Alterações salvas.');
  location.href = `evento.html?id=${id}`;
}

try {
  const dados = id ? await carregar() : null;
  if (!dados) {
    main.innerHTML = '<div class="msg msg-info">Evento não encontrado, ou você não está na equipe dele. <a href="eventos.html">Voltar para Eventos</a></div>';
  } else {
    document.title = `Backstage · Editar ${dados.evento.nome}`;
    main = montarLayout(usuario, 'eventos', { evento: dados.evento, abas: abasDoEvento(dados.ativos), aba: null });
    desenharEditarEvento(main, usuario, dados, salvar);
  }
} catch (e) {
  console.error(e);
  main.innerHTML = '<div class="msg msg-erro">Não foi possível carregar o evento. Recarregue a página em instantes.</div>';
}
