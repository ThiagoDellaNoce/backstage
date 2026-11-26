// Visão geral do evento: carrega tudo do evento ?id= e liga as ações ao banco.
import { supabase } from './supabase.js';
import { exigirLogin } from './auth.js';
import { montarLayout, abasDoEvento } from './layout.js';
import { hoje, somarDias } from './util.js';
import { desenharEvento } from './evento-view.js';
import { excluirEvento } from './excluir-evento.js';

const usuario = await exigirLogin();
let main = montarLayout(usuario, 'eventos');
const id = Number(new URLSearchParams(location.search).get('id'));

async function carregar() {
  const ev = await supabase.from('eventos').select('*').eq('id', id).maybeSingle();
  if (ev.error) throw ev.error;
  if (!ev.data) return null; // não existe ou a pessoa não está na equipe (RLS)
  const evento = ev.data;
  const h = hoje();

  const [mod, dim, eq, usu, pla, doc, cro, mar] = await Promise.all([
    supabase.from('evento_modulos').select('modulo, ativo').eq('evento_id', id),
    supabase.from('v_evento_dimensionamento').select('nome, unidade, pessoas_por_unidade, necessario, ordem').eq('evento_id', id),
    supabase.from('evento_equipe').select('usuario_id, papel, usuarios(nome)').eq('evento_id', id),
    supabase.from('usuarios').select('id, nome, papel').eq('ativo', true),
    supabase.from('v_planilha').select('categoria_nome, categoria_ordem, valor_total, status_contrato').eq('evento_id', id),
    supabase.from('documentos').select('status').eq('evento_id', id),
    supabase.from('v_cronograma').select('titulo, data, periodo, fase').eq('evento_id', id).gte('data', h).lte('data', somarDias(h, 2)),
    supabase.from('v_cronograma_marcos').select('tipo, titulo, dia_relativo, horario').eq('evento_id', id),
  ]);
  for (const r of [mod, dim, eq, usu, pla, doc, cro, mar]) if (r.error) throw r.error;

  const ativos = mod.data.filter((m) => m.ativo).map((m) => m.modulo);
  const docsLigada = ativos.includes('documentacao');
  return {
    evento,
    abas: abasDoEvento(ativos),
    docsLigada,
    dimensionamento: dim.data,
    equipe: eq.data.map((e) => ({ usuario_id: e.usuario_id, papel: e.papel, nome: e.usuarios?.nome })),
    usuarios: usu.data,
    planilha: pla.data,
    documentos: docsLigada ? doc.data : [],
    cronograma: cro.data,
    marcos: docsLigada ? mar.data : mar.data.filter((m) => m.tipo !== 'documento'),
  };
}

const acoes = {
  async status(novo) {
    const { error } = await supabase.from('eventos').update({ status: novo }).eq('id', id);
    if (error) throw error;
  },
  async adicionar(usuario_id, papel) {
    const { error } = await supabase.from('evento_equipe').insert({ evento_id: id, usuario_id, papel });
    if (error) throw error;
  },
  async remover(usuario_id) {
    const { error } = await supabase.from('evento_equipe').delete().eq('evento_id', id).eq('usuario_id', usuario_id);
    if (error) throw error;
  },
};

try {
  const dados = id ? await carregar() : null;
  if (!dados) {
    main.innerHTML = `<div class="msg msg-info">Evento não encontrado, ou você não está na equipe dele. <a href="eventos.html">Voltar para Eventos</a></div>`;
  } else {
    document.title = `Backstage · ${dados.evento.nome}`;
    main = montarLayout(usuario, 'eventos', { evento: dados.evento, abas: dados.abas, aba: 'visao_geral' });
    acoes.excluir = async () => { if (await excluirEvento(dados.evento)) location.href = 'eventos.html'; };
    desenharEvento(main, usuario, dados, acoes);
  }
} catch (e) {
  console.error(e);
  main.innerHTML = '<div class="msg msg-erro">Não foi possível carregar o evento. Recarregue a página em instantes.</div>';
}
