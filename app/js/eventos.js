// Eventos: carrega do Supabase (o RLS já filtra pela equipe) e desenha a tela.
import { supabase } from './supabase.js';
import { exigirLogin } from './auth.js';
import { montarLayout } from './layout.js';
import { desenharEventos } from './eventos-view.js';

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
    const doc = await supabase.from('documentos')
      .select('evento_id, status, prazo_dia_relativo')
      .in('evento_id', ids);
    if (doc.error) throw doc.error;
    documentos = doc.data;
  }
  return { eventos: ev.data, documentos };
}

try {
  desenharEventos(main, usuario, await carregar());
} catch (e) {
  console.error(e);
  main.innerHTML = '<div class="msg msg-erro">Não foi possível carregar os eventos. Recarregue a página em instantes.</div>';
}
