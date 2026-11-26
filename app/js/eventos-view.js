// Desenho da tela Eventos (filtros + cartões), sem acesso ao banco.
import { esc, hoje, diasEntre, somarDias, faltamHtml, STATUS_EVENTO } from './util.js';

export const PERIODOS = { proximos: 'Próximos', mes: 'Este mês', passados: 'Passados', todos: 'Todos os períodos' };

/** Lê os filtros da URL (?q=&status=&periodo=), para sobreviver ao voltar da página. */
export function filtrosDaUrl() {
  const p = new URLSearchParams(location.search);
  return {
    q: p.get('q') || '',
    status: STATUS_EVENTO[p.get('status')] ? p.get('status') : '',
    periodo: PERIODOS[p.get('periodo')] ? p.get('periodo') : 'proximos',
  };
}

function salvarNaUrl(f) {
  const p = new URLSearchParams();
  if (f.q) p.set('q', f.q);
  if (f.status) p.set('status', f.status);
  if (f.periodo !== 'proximos') p.set('periodo', f.periodo);
  history.replaceState(null, '', location.pathname + (p.toString() ? `?${p}` : ''));
}

const semAcento = (s) => String(s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();

/** Aplica busca, status e período; devolve a lista já ordenada. */
export function filtrar(eventos, f, h = hoje()) {
  const mes = h.slice(0, 7);
  const termo = semAcento(f.q.trim());
  const lista = eventos.filter((e) => {
    const fim = e.data_fim || e.data_evento;
    if (f.status && e.status !== f.status) return false;
    if (f.periodo === 'proximos' && fim < h) return false;
    if (f.periodo === 'passados' && fim >= h) return false;
    if (f.periodo === 'mes' && !(e.data_evento.slice(0, 7) <= mes && fim.slice(0, 7) >= mes)) return false;
    if (termo && !semAcento([e.nome, e.local, e.cidade, e.contratante].join(' ')).includes(termo)) return false;
    return true;
  });
  const desc = f.periodo === 'passados';
  return lista.sort((a, b) => (desc ? -1 : 1) * a.data_evento.localeCompare(b.data_evento));
}

/** Selos de documentos de um evento. */
export function selosDocumentos(ev, docs, h = hoje()) {
  if (['encerrado', 'cancelado'].includes(ev.status) || !docs.length) return [];
  let atrasados = 0, indeferidos = 0, pendentes = 0;
  for (const d of docs) {
    if (d.status === 'aprovado') continue;
    if (d.status === 'indeferido') indeferidos++;
    else if (d.prazo_dia_relativo != null && diasEntre(h, somarDias(ev.data_evento, d.prazo_dia_relativo)) < 0) atrasados++;
    else pendentes++;
  }
  const s = [];
  if (indeferidos) s.push({ tag: 'bad', texto: `${indeferidos} doc${indeferidos > 1 ? 's' : ''} indeferido${indeferidos > 1 ? 's' : ''}` });
  if (atrasados) s.push({ tag: 'bad', texto: `${atrasados} doc${atrasados > 1 ? 's' : ''} atrasado${atrasados > 1 ? 's' : ''}` });
  if (pendentes) s.push({ tag: 'warn', texto: `${pendentes} doc${pendentes > 1 ? 's' : ''} pendente${pendentes > 1 ? 's' : ''}` });
  if (!s.length) s.push({ tag: 'ok', texto: 'Docs em dia' });
  return s;
}

function dataEvento(e) {
  const f = (iso) => iso.split('-').reverse().join('/');
  return e.data_fim && e.data_fim !== e.data_evento ? `${f(e.data_evento)} a ${f(e.data_fim)}` : f(e.data_evento);
}

function cartao(e, docs, h) {
  const s = STATUS_EVENTO[e.status];
  const onde = [e.local, e.cidade].filter(Boolean).join(', ');
  const selos = selosDocumentos(e, docs, h);
  return `<a class="box card${['encerrado', 'cancelado'].includes(e.status) ? ' apagado' : ''}" href="evento.html?id=${e.id}">
    <div class="topo"><b>${esc(e.nome)}</b><span class="tag ${s.tag}">${s.nome}</span></div>
    <div class="muted">${dataEvento(e)}${onde ? ` · ${esc(onde)}` : ''} · ${faltamHtml(e, h)}</div>
    ${e.contratante ? `<div class="muted">Contratante: ${esc(e.contratante)}</div>` : ''}
    ${selos.length ? `<div class="selos">${selos.map((x) => `<span class="tag ${x.tag}">${x.texto}</span>`).join('')}</div>` : ''}
  </a>`;
}

/** Monta a tela. `dados` = { eventos, documentos }. */
export function desenharEventos(main, usuario, dados, h = hoje()) {
  const f = filtrosDaUrl();
  const docsPor = {};
  for (const d of dados.documentos) (docsPor[d.evento_id] ||= []).push(d);

  main.innerHTML = `
    <div style="display:flex;flex-wrap:wrap;gap:12px;justify-content:space-between;align-items:center">
      <h1>Eventos</h1>
      ${usuario.admin ? '<a class="btn btn-primary" href="novo-evento.html">+ Novo evento</a>' : ''}
    </div>
    <div class="filtros">
      <input id="f-q" type="search" aria-label="Buscar evento" placeholder="Buscar por nome, local, cidade ou contratante" value="${esc(f.q)}">
      <select id="f-status" aria-label="Status">
        <option value="">Todos os status</option>
        ${Object.entries(STATUS_EVENTO).map(([k, v]) => `<option value="${k}"${k === f.status ? ' selected' : ''}>${v.nome}</option>`).join('')}
      </select>
      <select id="f-periodo" aria-label="Período">
        ${Object.entries(PERIODOS).map(([k, v]) => `<option value="${k}"${k === f.periodo ? ' selected' : ''}>${v}</option>`).join('')}
      </select>
    </div>
    <div id="contagem" class="muted"></div>
    <div id="cards" class="cards"></div>`;

  const q = main.querySelector('#f-q'), st = main.querySelector('#f-status'), pe = main.querySelector('#f-periodo');
  const cards = main.querySelector('#cards'), cont = main.querySelector('#contagem');

  function atualizar() {
    const filtros = { q: q.value, status: st.value, periodo: pe.value };
    salvarNaUrl(filtros);
    const lista = filtrar(dados.eventos, filtros, h);
    cont.textContent = `${lista.length} evento${lista.length === 1 ? '' : 's'}`;
    if (lista.length) {
      cards.innerHTML = lista.map((e) => cartao(e, docsPor[e.id] || [], h)).join('');
    } else if (!dados.eventos.length) {
      cards.innerHTML = `<div class="vazio">${usuario.admin
        ? 'Nenhum evento cadastrado ainda.'
        : 'Você ainda não está na equipe de nenhum evento. Peça ao gestor ou ao planejamento para te incluir.'}</div>`;
    } else {
      cards.innerHTML = '<div class="vazio">Nenhum evento com esses filtros.</div>';
    }
  }

  q.addEventListener('input', atualizar);
  st.addEventListener('change', atualizar);
  pe.addEventListener('change', atualizar);
  atualizar();
}
