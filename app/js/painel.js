// Painel: carrega os dados do Supabase e desenha a tela.
import { supabase } from './supabase.js';
import { exigirLogin } from './auth.js';
import { montarLayout } from './layout.js';
import { hoje } from './util.js';
import { desenharPainel } from './painel-view.js';
import { editarFrases } from './frases.js';

const usuario = await exigirLogin();
const main = montarLayout(usuario, 'painel');

async function carregar() {
  const h = hoje();

  // O RLS já limita aos eventos que a pessoa pode ver
  const [ev, fr] = await Promise.all([
    supabase.from('eventos')
      .select('id, nome, local, cidade, data_evento, data_fim, status')
      .in('status', ['planejamento', 'montagem', 'operacao', 'desmontagem'])
      .order('data_evento'),
    supabase.from('frases_do_dia').select('id, texto').eq('ativa', true),
  ]);
  if (ev.error) throw ev.error;

  const eventos = ev.data;
  const ids = eventos.map((e) => e.id);
  let documentos = [], cronogramaHoje = [];

  if (ids.length) {
    const [doc, cro, mod] = await Promise.all([
      supabase.from('documentos')
        .select('id, evento_id, status, prazo_dia_relativo, descricao, tipos_documento(nome)')
        .in('evento_id', ids)
        .neq('status', 'aprovado'),
      supabase.from('v_cronograma')
        .select('evento_id, titulo, periodo, fase')
        .in('evento_id', ids)
        .eq('data', h),
      supabase.from('evento_modulos').select('evento_id').in('evento_id', ids).eq('modulo', 'documentacao').eq('ativo', true),
    ]);
    if (doc.error) throw doc.error;
    if (cro.error) throw cro.error;
    if (mod.error) throw mod.error;
    const comDocs = new Set(mod.data.map((m) => m.evento_id)); // só eventos com a Documentação ligada
    documentos = doc.data.filter((d) => comDocs.has(d.evento_id));
    cronogramaHoje = cro.data;
  }

  return { eventos, frases: fr.data || [], documentos, cronogramaHoje };
}

try {
  desenharPainel(main, usuario, await carregar(), hoje(), { editarFrases: () => editarFrases(usuario) });
} catch (e) {
  console.error(e);
  main.innerHTML = '<div class="msg msg-erro">Não foi possível carregar o painel. Recarregue a página em instantes.</div>';
}
