// Excluir evento (só gestor e planejamento; o banco também barra os demais).
// Mostra o que será apagado e pede para digitar o nome do evento.
import { supabase } from './supabase.js';
import { esc, avisar } from './util.js';
import { abrirJanela } from './janela.js';

// [tabela, singular, plural]
const CONTAR = [
  ['planilha_itens', 'item da planilha', 'itens da planilha (com as memórias de cálculo)'],
  ['documentos', 'documento', 'documentos'],
  ['cronograma_linhas', 'linha do cronograma', 'linhas do cronograma'],
  ['setores', 'setor', 'setores'],
  ['atracoes', 'atração', 'atrações (com custos, hospedagem e transporte)'],
  ['conferencias', 'conferência em campo', 'conferências em campo'],
  ['anexos', 'anexo', 'anexos'],
  ['estoque_movimentos', 'movimento de estoque', 'movimentos de estoque (reservas e saídas)'],
  ['evento_equipe', 'pessoa na equipe', 'pessoas na equipe'],
];

async function resumo(id) {
  const r = await Promise.all(CONTAR.map(([t]) => supabase.from(t).select('*', { count: 'exact', head: true }).eq('evento_id', id)));
  return CONTAR.map(([, um, varios], i) => {
    const n = r[i].error ? null : r[i].count;
    return { n, nome: n === 1 ? um : varios };
  }).filter((x) => x.n);
}

/** Abre a confirmação e exclui. Devolve true se excluiu. */
export async function excluirEvento(evento) {
  const itens = await resumo(evento.id).catch(() => []);
  const ok = await abrirJanela({
    titulo: 'Excluir evento',
    rodape: '<button type="button" class="btn btn-ghost" data-nao>Cancelar</button><button type="button" class="btn btn-perigo" data-sim disabled>Excluir definitivamente</button>',
  }, (corpo, fechar, d) => {
    corpo.innerHTML = `
      <p style="margin:0">Isto apaga <b>${esc(evento.nome)}</b> e <b>tudo</b> o que pertence a ele. <b>Não dá para desfazer.</b></p>
      ${itens.length ? `<ul class="lista-apagar">${itens.map((x) => `<li>${x.n} ${esc(x.nome)}</li>`).join('')}</ul>`
        : '<div class="muted">O evento ainda não tem planilha, documentos nem cronograma.</div>'}
      <div class="muted" style="font-size:12px">O registro no histórico de alterações é mantido.</div>
      <div class="campo"><label for="conf">Para confirmar, digite o nome do evento:</label>
        <input id="conf" type="text" autocomplete="off" placeholder="${esc(evento.nome)}"></div>
      <div id="erro-exc" class="msg msg-erro" role="alert" hidden></div>`;
    const conf = corpo.querySelector('#conf'), sim = d.querySelector('[data-sim]'), erro = corpo.querySelector('#erro-exc');
    const igual = () => conf.value.trim().toLowerCase() === evento.nome.trim().toLowerCase();
    conf.addEventListener('input', () => { sim.disabled = !igual(); });
    d.querySelector('[data-nao]').addEventListener('click', () => fechar(false));
    sim.addEventListener('click', async () => {
      if (!igual()) return;
      sim.disabled = true; sim.textContent = 'Excluindo…';
      const { error, count } = await supabase.from('eventos').delete({ count: 'exact' }).eq('id', evento.id);
      if (error || !count) {
        console.error(error);
        erro.textContent = error ? `Não foi possível excluir: ${error.message}` : 'Você não tem permissão para excluir este evento.';
        erro.hidden = false;
        sim.textContent = 'Excluir definitivamente'; sim.disabled = false;
        return;
      }
      fechar(true);
    });
    setTimeout(() => conf.focus());
  });
  if (ok) avisar(`Evento “${evento.nome}” excluído.`);
  return !!ok;
}
