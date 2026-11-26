// Partes do formulário de evento usadas por Novo evento e Editar evento.
import { esc, STATUS_EVENTO } from './util.js';

const GRUPOS = [
  { id: 'modulo', nome: 'Módulos' },
  { id: 'estrutura', nome: 'Estruturas' },
  { id: 'tecnica_visual', nome: 'Técnica e visual' },
  { id: 'mobiliario', nome: 'Mobiliário' },
];
const num = new Intl.NumberFormat('pt-BR');

/** Dimensionamento pelo público: sempre arredonda para cima. */
export function dimensionar(publico, parametros) {
  if (!(publico > 0)) return [];
  return [...parametros].sort((a, b) => a.ordem - b.ordem)
    .map((p) => ({ nome: p.nome, unidade: p.unidade, valor: Math.ceil(publico / Number(p.pessoas_por_unidade)) }));
}

/** Valida os dados do evento. Devolve { campo: mensagem }. */
export function validarDados(d) {
  const e = {};
  if (!d.nome.trim()) e.nome = 'Dê um nome ao evento.';
  if (!d.data_evento) e.data_evento = 'Informe a data do evento (dia 0).';
  else {
    const ano = +d.data_evento.slice(0, 4), agora = new Date().getFullYear();
    if (ano < agora - 1 || ano > agora + 5) e.data_evento = `Confira o ano (${ano}).`;
  }
  if (d.data_fim && d.data_evento && d.data_fim < d.data_evento) e.data_fim = 'O término não pode ser antes do início.';
  if (d.publico_estimado !== '' && d.publico_estimado != null && !/^\d+$/.test(String(d.publico_estimado).replace(/\./g, ''))) e.publico_estimado = 'Use só números.';
  return e;
}

/** Dados prontos para o banco (texto aparado, público sem pontos, vazios como null). */
export function limparDados(d) {
  const t = (v) => (String(v ?? '').trim() || null);
  return {
    nome: d.nome.trim(), contratante: t(d.contratante), local: t(d.local), cidade: t(d.cidade),
    data_evento: d.data_evento, data_fim: d.data_fim || null,
    publico_estimado: d.publico_estimado === '' || d.publico_estimado == null ? null : Number(String(d.publico_estimado).replace(/\./g, '')),
  };
}

/**
 * Campos de dados + dimensionamento ao lado. Edita `evento` no lugar.
 * @param opc { parametros, erros, status: bool (mostra o campo Status), aviso: (campo) => void }
 */
export function montarDados(container, evento, opc) {
  const erros = opc.erros || {};
  const campo = (id, rotulo, tipo, extra = {}) => {
    const v = evento[id] ?? '', err = erros[id];
    return `<div class="campo${extra.largo ? ' largo' : ''}${err ? ' erro' : ''}">
      <label for="c-${id}">${rotulo}${extra.obrig ? ' *' : ''}</label>
      <input id="c-${id}" name="${id}" type="${tipo}" value="${esc(v)}"${extra.ph ? ` placeholder="${esc(extra.ph)}"` : ''}${extra.attrs || ''}>
      ${err ? `<span class="msg-campo">${esc(err)}</span>` : extra.dica ? `<span class="dica" id="dica-${id}">${extra.dica}</span>` : ''}
    </div>`;
  };
  const htmlDimens = () => {
    const pub = Number(String(evento.publico_estimado ?? '').replace(/\./g, ''));
    const linhas = dimensionar(pub, opc.parametros);
    if (!linhas.length) return '<div class="vazio">Informe o público estimado para ver o dimensionamento.</div>';
    return `<div class="muted">${num.format(pub)} pessoas</div>` +
      linhas.map((l) => `<div><span>${esc(l.nome)}</span><b>${num.format(l.valor)}${l.unidade === 'm' ? ' m' : ''}</b></div>`).join('');
  };

  container.innerHTML = `
    <div class="dados-lado">
      <div class="form-grid">
        ${campo('nome', 'Nome do evento', 'text', { obrig: true, largo: !opc.status, ph: 'Ex.: Festival de Verão 2027' })}
        ${opc.status ? `<div class="campo"><label for="c-status">Status</label>
          <select id="c-status" name="status">${Object.entries(STATUS_EVENTO).map(([k, v]) => `<option value="${k}"${k === evento.status ? ' selected' : ''}>${v.nome}</option>`).join('')}</select></div>` : ''}
        ${campo('contratante', 'Contratante', 'text', { ph: 'Cliente ou produtor' })}
        ${campo('publico_estimado', 'Público estimado', 'text', { ph: 'Ex.: 8000', attrs: ' inputmode="numeric"' })}
        ${campo('local', 'Local', 'text', { ph: 'Ex.: Parque do Lago' })}
        ${campo('cidade', 'Cidade', 'text', { ph: 'Ex.: Uberaba' })}
        ${campo('data_evento', 'Data do evento', 'date', { obrig: true, dica: 'É o dia 0 (D0): prazos e cronograma contam a partir dele.' })}
        ${campo('data_fim', 'Data de término', 'date', { dica: 'Só se durar mais de um dia.' })}
      </div>
      <aside class="box" style="background:var(--bg)">
        <h2>Dimensionamento</h2>
        <div class="dimens" id="dimens">${htmlDimens()}</div>
      </aside>
    </div>`;
  container.querySelectorAll('input, select').forEach((i) => i.addEventListener(i.tagName === 'SELECT' ? 'change' : 'input', () => {
    evento[i.name] = i.value;
    if (i.name === 'publico_estimado') container.querySelector('#dimens').innerHTML = htmlDimens();
    opc.aviso?.(i.name);
  }));
}

/**
 * Checklist de telas. Edita o Set `selecionados` no lugar.
 * @param opc { modelos: [{id, nome, modulos}], bloqueado: bool, texto, mudou: () => void }
 */
export function montarChecklist(container, modulos, selecionados, opc = {}) {
  const opcionais = modulos.filter((m) => !m.sempre_ativo && m.codigo !== 'pagamentos').sort((a, b) => a.ordem - b.ordem);
  const fixas = modulos.filter((m) => m.sempre_ativo).sort((a, b) => a.ordem - b.ordem);
  const modelos = (opc.modelos || []).filter((m) => m.modulos.length);
  const bloq = !!opc.bloqueado;

  container.innerHTML = `
    <div style="display:flex;justify-content:space-between;gap:12px;flex-wrap:wrap;align-items:center;margin-bottom:8px">
      <div class="muted">${opc.texto || 'Marque o que este evento vai ter. Dá para mudar depois: desligar uma tela só a esconde, nada é apagado.'}</div>
      ${bloq ? '' : `<div style="display:flex;gap:8px;flex-wrap:wrap">
        ${modelos.length ? `<select id="modelo" aria-label="Começar de um modelo"><option value="">Começar de um modelo…</option>${modelos.map((m) => `<option value="${m.id}">${esc(m.nome)}</option>`).join('')}</select>` : ''}
        <button type="button" class="btn btn-ghost btn-sm" id="todas">Marcar todas</button>
        <button type="button" class="btn btn-ghost btn-sm" id="limpar">Limpar</button>
      </div>`}
    </div>
    <div class="grupo-telas">
      <h3>Sempre ligadas</h3>
      <div class="telas">${fixas.map((m) => `<label class="tela travada"><input type="checkbox" checked disabled><span><b>${esc(m.nome)}</b></span></label>`).join('')}</div>
      ${GRUPOS.map((g) => {
        const itens = opcionais.filter((m) => m.grupo === g.id);
        if (!itens.length) return '';
        return `<h3>${g.nome}</h3><div class="telas">${itens.map((m) => m.disponivel
          ? `<label class="tela${bloq ? ' travada' : ''}"><input type="checkbox" value="${m.codigo}"${selecionados.has(m.codigo) ? ' checked' : ''}${bloq ? ' disabled' : ''}><span><b>${esc(m.nome)}</b>${m.pergunta ? `<small>${esc(m.pergunta)}</small>` : ''}</span></label>`
          : `<label class="tela travada"><input type="checkbox" disabled><span><b>${esc(m.nome)} <span class="breve" style="margin-left:6px">em breve</span></b>${m.pergunta ? `<small>${esc(m.pergunta)}</small>` : ''}</span></label>`).join('')}</div>`;
      }).join('')}
    </div>`;
  if (bloq) return;

  const caixas = () => container.querySelectorAll('input[type=checkbox][value]');
  const sync = () => {
    selecionados.clear();
    caixas().forEach((c) => { if (c.checked) selecionados.add(c.value); });
    opc.mudou?.();
  };
  caixas().forEach((c) => c.addEventListener('change', sync));
  container.querySelector('#todas').addEventListener('click', () => { caixas().forEach((c) => { c.checked = true; }); sync(); });
  container.querySelector('#limpar').addEventListener('click', () => { caixas().forEach((c) => { c.checked = false; }); sync(); });
  container.querySelector('#modelo')?.addEventListener('change', (e) => {
    const m = modelos.find((x) => String(x.id) === e.target.value);
    if (!m) return;
    caixas().forEach((c) => { c.checked = m.modulos.includes(c.value); });
    sync();
  });
}
