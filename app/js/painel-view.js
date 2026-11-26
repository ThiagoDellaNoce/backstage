// Desenho do Painel a partir dos dados já carregados (sem acesso ao banco).
import { esc, hoje, diasEntre, somarDias, dx, dataCurta, dataPorExtenso, faltamHtml, STATUS_EVENTO, FASE, PERIODO } from './util.js';

const ATIVOS = ['planejamento', 'montagem', 'operacao', 'desmontagem'];

/** Frase do dia: a mesma o dia todo, muda no dia seguinte. */
export function fraseDoDia(frases, data = hoje()) {
  if (!frases.length) return null;
  const n = Math.floor(Date.UTC(+data.slice(0, 4), +data.slice(5, 7) - 1, +data.slice(8, 10)) / 86400000);
  const lista = [...frases].sort((a, b) => a.id - b.id);
  return lista[n % lista.length].texto;
}

/** Monta a lista de pontos de atenção (documentos e cronograma de hoje). */
export function pontosDeAtencao({ eventos, documentos, cronogramaHoje }, h = hoje()) {
  const ev = Object.fromEntries(eventos.map((e) => [e.id, e]));
  const pontos = [];

  for (const d of documentos) {
    const e = ev[d.evento_id];
    if (!e) continue;
    const nome = d.tipos_documento?.nome || d.descricao || 'Documento';
    if (d.status === 'indeferido') {
      pontos.push({ ordem: -1000, tag: 'bad', selo: 'Indeferido', texto: `${nome} · ${e.nome}` });
      continue;
    }
    if (d.prazo_dia_relativo == null) continue;
    const prazo = somarDias(e.data_evento, d.prazo_dia_relativo);
    const n = diasEntre(h, prazo);
    if (n < 0) pontos.push({ ordem: n, tag: 'bad', selo: 'Atrasado', texto: `${nome} · ${e.nome} · prazo ${dx(d.prazo_dia_relativo)} (${dataCurta(prazo)})` });
    else if (n === 0) pontos.push({ ordem: 0, tag: 'warn', selo: 'Vence hoje', texto: `${nome} · ${e.nome}` });
    else if (n <= 5) pontos.push({ ordem: n, tag: 'warn', selo: `Vence em ${n}d`, texto: `${nome} · ${e.nome} · ${dataCurta(prazo)}` });
  }

  // Cronograma de hoje: uma linha por evento + fase, juntando os setores
  const grupos = new Map();
  for (const c of cronogramaHoje) {
    if (!ev[c.evento_id] || !c.fase) continue;
    const k = `${c.evento_id}|${c.fase}`;
    if (!grupos.has(k)) grupos.set(k, { e: ev[c.evento_id], fase: c.fase, itens: new Set(), periodos: new Set() });
    const g = grupos.get(k);
    g.itens.add(c.titulo);
    if (c.periodo) g.periodos.add(c.periodo);
  }
  for (const g of grupos.values()) {
    const itens = [...g.itens];
    const resumo = itens.length > 3 ? `${itens.slice(0, 3).join(', ')} +${itens.length - 3}` : itens.join(', ');
    const per = ['manha', 'tarde', 'noite'].filter((p) => g.periodos.has(p)).map((p) => PERIODO[p]).join(', ');
    pontos.push({ ordem: 1, tag: 'info', selo: 'Hoje', texto: `${FASE[g.fase]}: ${resumo} · ${g.e.nome}${per ? ` · ${per}` : ''}` });
  }

  return pontos.sort((a, b) => a.ordem - b.ordem);
}

export function desenharPainel(main, usuario, dados, h = hoje()) {
  const { eventos, frases } = dados;
  const ativos = eventos.filter((e) => ATIVOS.includes(e.status));
  const proximos = ativos
    .filter((e) => (e.data_fim || e.data_evento) >= h)
    .sort((a, b) => a.data_evento.localeCompare(b.data_evento));
  const pontos = pontosDeAtencao(dados, h);
  const frase = fraseDoDia(frases, h);
  const primeiroNome = usuario.nome.split(' ')[0];

  const novoEvento = usuario.admin
    ? '<a class="btn btn-primary" aria-disabled="true" title="Tela Novo evento: em breve">+ Novo evento</a>'
    : '';

  const linhas = proximos.map((e) => {
    const s = STATUS_EVENTO[e.status];
    const onde = [e.local, e.cidade].filter(Boolean).join(', ');
    return `<tr>
      <td><b>${esc(e.nome)}</b>${onde ? `<div class="muted">${esc(onde)}</div>` : ''}</td>
      <td>${dataCurta(e.data_evento)}${e.data_fim && e.data_fim !== e.data_evento ? ` a ${dataCurta(e.data_fim)}` : ''}</td>
      <td>${faltamHtml(e, h)}</td>
      <td><span class="tag ${s.tag}">${s.nome}</span></td>
      <td class="dir"><a class="btn btn-primary btn-sm" aria-disabled="true" title="Visão geral do evento: em breve">Entrar no evento →</a></td>
    </tr>`;
  }).join('');

  const vazioEventos = usuario.admin
    ? 'Nenhum evento por vir. Assim que a tela Novo evento ficar pronta, eles aparecem aqui.'
    : 'Você ainda não está na equipe de nenhum evento por vir.';

  main.innerHTML = `
    <div style="display:flex;flex-wrap:wrap;gap:12px;justify-content:space-between;align-items:center">
      <div>
        <div class="muted">${esc(primeiroNome)} · ${esc(dataPorExtenso())}</div>
        <h1>${esc(frase || `Olá, ${primeiroNome}!`)}</h1>
      </div>
      ${novoEvento}
    </div>

    <div class="kpis">
      <div class="box kpi"><span class="muted">Eventos ativos</span><b>${ativos.length}</b></div>
    </div>

    <section class="box">
      <h2>Próximos eventos</h2>
      ${proximos.length
        ? `<div class="tw"><table>
            <thead><tr><th>Evento</th><th>Data</th><th>Faltam</th><th>Status</th><th></th></tr></thead>
            <tbody>${linhas}</tbody></table></div>`
        : `<div class="vazio">${vazioEventos}</div>`}
    </section>

    <section class="box">
      <h2>Pontos de atenção</h2>
      ${pontos.length
        ? `<div class="atencao">${pontos.map((p) => `<div><span class="tag ${p.tag}">${esc(p.selo)}</span><span>${esc(p.texto)}</span></div>`).join('')}</div>`
        : '<div class="vazio">Nada pedindo atenção agora.</div>'}
    </section>`;
}
