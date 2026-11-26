// Eventos: carrega do Supabase (o RLS já filtra pela equipe) e desenha a tela.
import { supabase } from './supabase.js';
import { hoje } from './util.js';
import { exigirLogin } from './auth.js';
import { montarLayout } from './layout.js';
import { desenharEventos } from './eventos-view.js';
import { lerAviso } from './util.js';
import { excluirEvento } from './excluir-evento.js';

const usuario = await exigirLogin();
const main = montarLayout(usuario, 'eventos');

async function carregar() {
  const ev = await supabase.from('eventos')
    .select('id, nome, contratante, local, cidade, data_evento, data_fim, status')
    .order('data_evento');
  if (ev.error) throw ev.error;

  const ids = ev.data.map((e) => e.id);
  let documentos = [];
  if (ids.length) {
    const [doc, mod] = await Promise.all([
      supabase.from('documentos').select('evento_id, status, prazo_dia_relativo').in('evento_id', ids),
      supabase.from('evento_modulos').select('evento_id').in('evento_id', ids).eq('modulo', 'documentacao').eq('ativo', true),
    ]);
    if (doc.error) throw doc.error;
    if (mod.error) throw mod.error;
    const comDocs = new Set(mod.data.map((m) => m.evento_id)); // só eventos com a Documentação ligada
    documentos = doc.data.filter((d) => comDocs.has(d.evento_id));
  }
  return { eventos: ev.data, documentos };
}

try {
  const mostrarAviso = () => {
    const aviso = lerAviso();
    if (!aviso) return;
    main.querySelector('.msg-aviso')?.remove();
    const m = document.createElement('div');
    m.className = 'msg msg-info msg-aviso';
    m.setAttribute('role', 'status');
    m.textContent = aviso;
    main.querySelector('.filtros').before(m);
  };
  desenharEventos(main, usuario, await carregar(), hoje(), {
    excluir: async (e) => { const ok = await excluirEvento(e); mostrarAviso(); return ok; },
  });
  mostrarAviso();
} catch (e) {
  console.error(e);
  main.innerHTML = '<div class="msg msg-erro">Não foi possível carregar os eventos. Recarregue a página em instantes.</div>';
}
