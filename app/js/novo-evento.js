// Novo evento: carrega os cadastros e cria pelo fn_criar_evento (uma transação só).
import { supabase } from './supabase.js';
import { exigirLogin } from './auth.js';
import { montarLayout } from './layout.js';
import { avisar } from './util.js';
import { desenharNovoEvento } from './novo-evento-view.js';

const usuario = await exigirLogin();
const main = montarLayout(usuario, 'eventos');

async function carregar() {
  const [mod, usu, par, mdl] = await Promise.all([
    supabase.from('modulos').select('codigo, nome, grupo, pergunta, sempre_ativo, disponivel, ordem'),
    supabase.from('usuarios').select('id, nome, papel').eq('ativo', true),
    supabase.from('parametros_dimensionamento').select('nome, pessoas_por_unidade, unidade, ordem'),
    supabase.from('modelos_evento').select('id, nome, modelo_modulos(modulo)'),
  ]);
  for (const r of [mod, usu, par, mdl]) if (r.error) throw r.error;
  return {
    modulos: mod.data,
    usuarios: usu.data,
    parametros: par.data,
    modelos: mdl.data.map((m) => ({ id: m.id, nome: m.nome, modulos: m.modelo_modulos.map((x) => x.modulo) })),
  };
}

async function criar({ evento, modulos, equipe }) {
  const { error } = await supabase.rpc('fn_criar_evento', { p_evento: evento, p_modulos: modulos, p_equipe: equipe });
  if (error) throw error;
  avisar(`Evento “${evento.nome}” criado.`);
  location.href = 'eventos.html';
}

if (!usuario.admin) {
  main.innerHTML = `<h1>Novo evento</h1>
    <div class="msg msg-info">Só gestor e planejamento podem criar eventos. <a href="eventos.html">Voltar para Eventos</a></div>`;
} else {
  try {
    desenharNovoEvento(main, usuario, await carregar(), criar);
  } catch (e) {
    console.error(e);
    main.innerHTML = '<div class="msg msg-erro">Não foi possível carregar o formulário. Recarregue a página em instantes.</div>';
  }
}
