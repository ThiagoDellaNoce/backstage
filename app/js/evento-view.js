// Visão geral do evento (sem acesso ao banco: recebe dados e ações).
import { esc, hoje, diasEntre, somarDias, dx, faltamHtml, STATUS_EVENTO, FASE, PERIODO, PAPEL } from './util.js';
import { htmlAbas } from './layout.js';

const num = new Intl.NumberFormat('pt-BR');
const brl = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });
const dataBr = (iso) => iso.split('-').reverse().join('/');
const TIPO_MARCO = { documento: 'Prazo', passagem_som: 'Passagem de som', show: 'Show' };

/** Orçado e itens por categoria, a partir das linhas da v_planilha. */
export function orcamentoPorCategoria(planilha) {
  const m = new Map();
  for (const i of planilha) {
    if (!m.has(i.categoria_nome)) m.set(i.categoria_nome, { nome: i.categoria_nome, ordem: i.categoria_ordem, itens: 0, valor: 0 });
    const c = m.get(i.categoria_nome);
    c.itens++;
    c.valor += Number(i.valor_total) || 0;
  }
  return [...m.values()].sort((a, b) => a.ordem - b.ordem);
}

/** Agenda de hoje até hoje+2: cronograma (por fase) + marcos (prazos de documento, passagem de som, show). */
export function proximosDias(evento, cronograma, marcos, h = hoje()) {
  const dias = [0, 1, 2].map((n) => somarDias(h, n));
  return dias.map((data) => {
    const itens = [];
    const porFase = new Map();
    for (const c of cronograma) {
      if (c.data !== data || !c.fase) continue;
      if (!porFase.has(c.fase)) porFase.set(c.fase, { titulos: new Set(), periodos: new Set() });
      porFase.get(c.fase).titulos.add(c.titulo);
      if (c.periodo) porFase.get(c.fase).periodos.add(c.periodo);
    }
    for (const [fase, g] of porFase) {
      const per = ['manha', 'tarde', 'noite'].filter((p) => g.periodos.has(p)).map((p) => PERIODO[p]).join(', ');
      itens.push(`${FASE[fase]}: ${[...g.titulos].join(', ')}${per ? ` · ${per}` : ''}`);
    }
    for (const m of marcos) {
      if (m.dia_relativo == null || somarDias(evento.data_evento, m.dia_relativo) !== data) continue;
      const hora = m.horario ? ` · ${new Date(m.horario).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })}` : '';
      itens.push(`${TIPO_MARCO[m.tipo] || m.tipo}: ${m.titulo}${hora}`);
    }
    return { data, dia: diasEntre(evento.data_evento, data), itens };
  });
}

/**
 * @param dados  { evento, abas, dimensionamento, equipe:[{usuario_id,papel,nome}], usuarios, planilha, documentos, cronograma, marcos, docsLigada }
 * @param acoes  { status(novo), adicionar(usuario_id, papel), remover(usuario_id) } — devolvem Promise
 */
export function desenharEvento(main, usuario, dados, acoes, h = hoje()) {
  const { evento } = dados;
  const onde = [evento.local, evento.cidade].filter(Boolean).join(', ');
  const datas = evento.data_fim && evento.data_fim !== evento.data_evento
    ? `${dataBr(evento.data_evento)} a ${dataBr(evento.data_fim)}` : dataBr(evento.data_evento);

  const orcado = dados.planilha.reduce((s, i) => s + (Number(i.valor_total) || 0), 0);
  const contratados = dados.planilha.filter((i) => i.status_contrato === 'concluido').length;
  const aprovados = dados.documentos.filter((d) => d.status === 'aprovado').length;
  const categorias = orcamentoPorCategoria(dados.planilha);
  const agenda = proximosDias(evento, dados.cronograma, dados.marcos, h);

  main.innerHTML = `
    <div class="cabecalho">
      <div>
        <div class="muted"><a href="eventos.html">Eventos</a> / ${esc(evento.nome)}</div>
        <h1>${esc(evento.nome)}</h1>
        <div class="muted">${datas}${onde ? ` · ${esc(onde)}` : ''} · ${faltamHtml(evento, h)}</div>
      </div>
      <div class="lado">
        <label for="status" class="muted">Status</label>
        <select id="status" class="status">
          ${Object.entries(STATUS_EVENTO).map(([k, v]) => `<option value="${k}"${k === evento.status ? ' selected' : ''}>${v.nome}</option>`).join('')}
        </select>
        <a class="btn btn-ghost" aria-disabled="true" title="Tela Editar evento: em breve">Editar evento</a>
      </div>
    </div>
    <div id="aviso" class="msg" role="status" hidden></div>
    ${htmlAbas(evento, dados.abas, 'visao_geral')}

    <div class="kpis">
      <div class="box kpi"><span class="muted">Orçado (planilha)</span><b>${brl.format(orcado)}</b></div>
      <div class="box kpi"><span class="muted">Itens contratados</span><b>${contratados} / ${dados.planilha.length}</b></div>
      ${dados.docsLigada ? `<div class="box kpi"><span class="muted">Documentos aprovados</span><b>${aprovados} / ${dados.documentos.length}</b></div>` : ''}
    </div>

    <div class="linha2">
      <section class="box">
        <h2>Dados do evento</h2>
        <dl class="ficha">
          <dt>Local</dt><dd>${esc(evento.local || '—')}</dd>
          <dt>Cidade</dt><dd>${esc(evento.cidade || '—')}</dd>
          <dt>Data</dt><dd>${datas}</dd>
          <dt>Público estimado</dt><dd>${evento.publico_estimado != null ? num.format(evento.publico_estimado) : '—'}</dd>
          <dt>Contratante</dt><dd>${esc(evento.contratante || '—')}</dd>
        </dl>
        <hr class="div">
        ${dados.dimensionamento.length ? `
          <div class="muted" style="margin-bottom:8px">Dimensionamento pelo público (${num.format(evento.publico_estimado)})</div>
          <dl class="ficha">${[...dados.dimensionamento].sort((a, b) => a.ordem - b.ordem).map((d) => `
            <dt>${esc(d.nome)}</dt><dd><b>${num.format(d.necessario)}${d.unidade === 'm' ? ' m' : ''}</b>
            <span class="muted">· 1${d.unidade === 'm' ? ' m' : ''} para cada ${num.format(d.pessoas_por_unidade)} pessoas</span></dd>`).join('')}
          </dl>`
        : '<div class="vazio">Informe o público estimado para ver o dimensionamento.</div>'}
      </section>

      <section class="box" id="equipe"></section>
    </div>

    <div class="linha2">
      <section class="box" style="flex-grow:2">
        <h2>Orçamento por categoria</h2>
        ${categorias.length ? `<div class="tw"><table>
          <thead><tr><th>Categoria</th><th>Itens</th><th style="text-align:right">Orçado</th></tr></thead>
          <tbody>${categorias.map((c) => `<tr><td>${esc(c.nome)}</td><td>${c.itens}</td><td class="dir">${brl.format(c.valor)}</td></tr>`).join('')}
          <tr><td><b>Total</b></td><td><b>${dados.planilha.length}</b></td><td class="dir"><b>${brl.format(orcado)}</b></td></tr></tbody>
        </table></div>` : '<div class="vazio">A planilha ainda não tem itens.</div>'}
      </section>
      <section class="box">
        <h2>Próximos 3 dias</h2>
        ${(evento.data_fim || evento.data_evento) < h ? '<div class="vazio">O evento já aconteceu.</div>' : `<div class="tempo">${agenda.map((d) => `
          <div class="dia"><span class="tag${d.data === h ? ' info' : ''}">${dx(d.dia)}</span>
            <div><div class="muted">${d.data === h ? 'Hoje' : new Date(d.data + 'T12:00').toLocaleDateString('pt-BR', { weekday: 'short', day: '2-digit', month: '2-digit' })}</div>
            ${d.itens.length ? `<ul>${d.itens.map((t) => `<li>${esc(t)}</li>`).join('')}</ul>` : '<span class="vazio" style="padding:0">Nada marcado.</span>'}</div>
          </div>`).join('')}
        </div>`}
      </section>
    </div>`;

  // ---------- Status ----------
  const aviso = main.querySelector('#aviso');
  const mostrar = (texto, tipo) => { aviso.className = `msg msg-${tipo}`; aviso.textContent = texto; aviso.hidden = false; };
  const sel = main.querySelector('#status');
  sel.addEventListener('change', async () => {
    const antes = evento.status, novo = sel.value;
    sel.disabled = true;
    try {
      await acoes.status(novo);
      evento.status = novo;
      mostrar(`Status alterado para ${STATUS_EVENTO[novo].nome}.`, 'info');
    } catch (e) {
      console.error(e);
      sel.value = antes;
      mostrar('Não foi possível alterar o status.', 'erro');
    }
    sel.disabled = false;
  });

  // ---------- Equipe ----------
  const caixa = main.querySelector('#equipe');
  function desenharEquipe() {
    const naEquipe = new Set(dados.equipe.map((e) => e.usuario_id));
    const livres = dados.usuarios.filter((u) => !naEquipe.has(u.id)).sort((a, b) => a.nome.localeCompare(b.nome));
    const lista = [...dados.equipe].sort((a, b) => (a.nome || '').localeCompare(b.nome || ''));
    caixa.innerHTML = `
      <div style="display:flex;justify-content:space-between;align-items:center;gap:8px"><h2>Equipe</h2>
        ${usuario.admin && livres.length ? '<button type="button" class="btn btn-ghost btn-sm" id="eq-abrir">+ Adicionar</button>' : ''}</div>
      ${usuario.admin && livres.length ? `<div id="eq-form" class="linha-add" hidden style="margin-bottom:12px">
        <select id="eq-pessoa" aria-label="Pessoa"><option value="">Escolha a pessoa…</option>${livres.map((u) => `<option value="${u.id}">${esc(u.nome)}</option>`).join('')}</select>
        <select id="eq-papel" aria-label="Função">${Object.entries(PAPEL).map(([k, v]) => `<option value="${k}">${v}</option>`).join('')}</select>
        <button type="button" class="btn btn-primary btn-sm" id="eq-salvar">Adicionar</button>
      </div>` : ''}
      ${lista.length ? `<div class="tw"><table>
        <thead><tr><th>Nome</th><th>Função no evento</th>${usuario.admin ? '<th></th>' : ''}</tr></thead>
        <tbody>${lista.map((e) => `<tr><td>${esc(e.nome || '—')}${e.usuario_id === usuario.id ? ' <span class="muted">(você)</span>' : ''}</td><td>${PAPEL[e.papel] || e.papel}</td>
          ${usuario.admin ? `<td class="dir"><button type="button" class="btn-x" data-tirar="${e.usuario_id}" aria-label="Tirar ${esc(e.nome)} da equipe" title="Tirar da equipe">×</button></td>` : ''}</tr>`).join('')}</tbody>
      </table></div>` : '<div class="vazio">Ninguém na equipe ainda.</div>'}`;

    const form = caixa.querySelector('#eq-form');
    const pessoa = caixa.querySelector('#eq-pessoa'), papel = caixa.querySelector('#eq-papel');
    caixa.querySelector('#eq-abrir')?.addEventListener('click', () => { form.hidden = !form.hidden; if (!form.hidden) pessoa.focus(); });
    if (form) pessoa.addEventListener('change', () => {
      const u = dados.usuarios.find((x) => x.id === pessoa.value);
      if (u) papel.value = u.papel;
    });
    caixa.querySelector('#eq-salvar')?.addEventListener('click', async () => {
      if (!pessoa.value) { pessoa.focus(); return; }
      try {
        await acoes.adicionar(pessoa.value, papel.value);
        const u = dados.usuarios.find((x) => x.id === pessoa.value);
        dados.equipe.push({ usuario_id: pessoa.value, papel: papel.value, nome: u?.nome });
        desenharEquipe();
      } catch (e) { console.error(e); mostrar('Não foi possível adicionar a pessoa.', 'erro'); }
    });
    caixa.querySelectorAll('[data-tirar]').forEach((b) => b.addEventListener('click', async () => {
      const e = dados.equipe.find((x) => x.usuario_id === b.dataset.tirar);
      if (!confirm(`Tirar ${e?.nome || 'esta pessoa'} da equipe? Ela deixa de ver o evento (se não for gestor ou planejamento).`)) return;
      try {
        await acoes.remover(b.dataset.tirar);
        dados.equipe = dados.equipe.filter((x) => x.usuario_id !== b.dataset.tirar);
        desenharEquipe();
      } catch (err) { console.error(err); mostrar('Não foi possível tirar a pessoa da equipe.', 'erro'); }
    }));
  }
  desenharEquipe();
}
