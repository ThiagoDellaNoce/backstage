// Assistente "Novo evento": 1 Dados · 2 Telas · 3 Equipe · Resumo.
// Não acessa o banco: recebe os cadastros em `dados` e chama `criar(payload)` no fim.
import { esc, PAPEL } from './util.js';
import { validarDados, montarDados, montarChecklist } from './evento-form.js';

export { dimensionar, validarDados } from './evento-form.js';

const PASSOS = ['Dados do evento', 'Telas do evento', 'Equipe', 'Resumo'];
const num = new Intl.NumberFormat('pt-BR');

/**
 * @param main     elemento <main>
 * @param usuario  usuário logado
 * @param dados    { modulos, usuarios, parametros, modelos: [{id, nome, modulos: []}] }
 * @param criar    async (payload) => void  — chamado no "Criar evento"
 */
export function desenharNovoEvento(main, usuario, dados, criar) {
  const opcionais = dados.modulos.filter((m) => !m.sempre_ativo && m.codigo !== 'pagamentos').sort((a, b) => a.ordem - b.ordem);
  const fixas = dados.modulos.filter((m) => m.sempre_ativo).sort((a, b) => a.ordem - b.ordem);

  const st = {
    passo: 0,
    evento: { nome: '', contratante: '', local: '', cidade: '', data_evento: '', data_fim: '', publico_estimado: '' },
    modulos: new Set(),
    equipe: [], // [{ usuario_id, papel }]
    erros: {},
    salvando: false,
    erroGeral: '',
  };

  main.innerHTML = `
    <div style="display:flex;flex-wrap:wrap;gap:12px;justify-content:space-between;align-items:center">
      <div><a href="eventos.html" class="muted">← Eventos</a><h1>Novo evento</h1></div>
    </div>
    <ol class="passos"></ol>
    <section class="box" id="corpo"></section>
    <div id="erro-geral" class="msg msg-erro" role="alert" hidden></div>
    <div class="acoes">
      <button type="button" class="btn btn-ghost" id="voltar">← Voltar</button>
      <div class="dir">
        <a class="btn btn-ghost" href="eventos.html">Cancelar</a>
        <button type="button" class="btn btn-primary" id="avancar">Avançar →</button>
      </div>
    </div>`;

  const corpo = main.querySelector('#corpo');
  const btnVoltar = main.querySelector('#voltar'), btnAvancar = main.querySelector('#avancar');
  const erroGeral = main.querySelector('#erro-geral');

  // ---------- Passo 1: dados ----------
  function passoDados() {
    montarDados(corpo, st.evento, { parametros: dados.parametros, erros: st.erros });
    corpo.querySelector('#c-nome').focus();
  }

  // ---------- Passo 2: telas ----------
  function passoTelas() {
    montarChecklist(corpo, dados.modulos, st.modulos, { modelos: dados.modelos });
  }

  // ---------- Passo 3: equipe ----------
  const pessoa = (id) => dados.usuarios.find((u) => u.id === id);

  function passoEquipe() {
    const naEquipe = new Set([usuario.id, ...st.equipe.map((e) => e.usuario_id)]);
    const livres = dados.usuarios.filter((u) => !naEquipe.has(u.id)).sort((a, b) => a.nome.localeCompare(b.nome));
    const opcoesPapel = (sel) => Object.entries(PAPEL).map(([k, v]) => `<option value="${k}"${k === sel ? ' selected' : ''}>${v}</option>`).join('');
    corpo.innerHTML = `
      <div class="muted" style="margin-bottom:12px">Quem está na equipe vê e edita o evento. Gestor e planejamento já veem todos os eventos.</div>
      <div class="tw"><table>
        <thead><tr><th>Pessoa</th><th>Função no evento</th><th></th></tr></thead>
        <tbody>
          <tr><td><b>${esc(usuario.nome)}</b> <span class="muted">(você)</span></td><td>${PAPEL[usuario.papel]}</td><td></td></tr>
          ${st.equipe.map((e, i) => `<tr>
            <td>${esc(pessoa(e.usuario_id)?.nome || '')}</td>
            <td><select data-i="${i}" aria-label="Função">${opcoesPapel(e.papel)}</select></td>
            <td class="dir"><button type="button" class="btn-x" data-tirar="${i}" aria-label="Tirar da equipe">×</button></td>
          </tr>`).join('')}
        </tbody>
      </table></div>
      ${livres.length ? `<div class="linha-add" style="margin-top:12px">
        <select id="add-pessoa" aria-label="Pessoa"><option value="">Adicionar pessoa…</option>${livres.map((u) => `<option value="${u.id}">${esc(u.nome)} · ${PAPEL[u.papel]}</option>`).join('')}</select>
        <button type="button" class="btn btn-ghost" id="add">+ Adicionar</button>
      </div>` : `<div class="vazio" style="margin-top:8px">${dados.usuarios.length > 1
        ? 'Todas as pessoas cadastradas já estão na equipe.'
        : 'Ainda não há outras pessoas cadastradas no Backstage.'}</div>`}`;
    corpo.querySelectorAll('select[data-i]').forEach((s) => s.addEventListener('change', () => { st.equipe[+s.dataset.i].papel = s.value; }));
    corpo.querySelectorAll('[data-tirar]').forEach((b) => b.addEventListener('click', () => { st.equipe.splice(+b.dataset.tirar, 1); passoEquipe(); }));
    const add = () => {
      const id = corpo.querySelector('#add-pessoa')?.value;
      if (!id) return;
      st.equipe.push({ usuario_id: id, papel: pessoa(id).papel });
      passoEquipe();
    };
    corpo.querySelector('#add')?.addEventListener('click', add);
    corpo.querySelector('#add-pessoa')?.addEventListener('change', add);
  }

  // ---------- Resumo ----------
  function passoResumo() {
    const e = st.evento;
    const f = (iso) => iso.split('-').reverse().join('/');
    const datas = e.data_fim && e.data_fim !== e.data_evento ? `${f(e.data_evento)} a ${f(e.data_fim)}` : f(e.data_evento);
    const telas = [...fixas.map((m) => m.nome), ...opcionais.filter((m) => st.modulos.has(m.codigo)).map((m) => m.nome)];
    corpo.innerHTML = `
      <dl class="resumo form-grid">
        <div><dt>Evento</dt><dd><b>${esc(e.nome.trim())}</b></dd></div>
        <div><dt>Data</dt><dd>${datas}</dd></div>
        <div><dt>Local</dt><dd>${esc([e.local, e.cidade].map((x) => x.trim()).filter(Boolean).join(', ') || '—')}</dd></div>
        <div><dt>Contratante · Público</dt><dd>${esc(e.contratante.trim() || '—')} · ${e.publico_estimado ? `${num.format(Number(String(e.publico_estimado).replace(/\./g, '')))} pessoas` : '—'}</dd></div>
        <div class="largo" style="grid-column:1/-1"><dt>Telas (${telas.length})</dt><dd>${telas.map((t) => `<span class="tag" style="margin:0 4px 4px 0">${esc(t)}</span>`).join('')}</dd></div>
        <div class="largo" style="grid-column:1/-1"><dt>Equipe</dt><dd>${[`${esc(usuario.nome)} (${PAPEL[usuario.papel]})`, ...st.equipe.map((x) => `${esc(pessoa(x.usuario_id)?.nome)} (${PAPEL[x.papel]})`)].join(' · ')}</dd></div>
      </dl>
      <div class="muted">Status inicial: Planejamento.${st.modulos.has('documentacao') ? ' Os documentos padrão (CEMIG, AVCB, CODAU, Alvará) serão criados.' : ''}</div>`;
  }

  // ---------- Navegação ----------
  const PASSO_FN = [passoDados, passoTelas, passoEquipe, passoResumo];

  function desenhar() {
    main.querySelector('.passos').innerHTML = PASSOS.map((p, i) =>
      `<li class="${i === st.passo ? 'on' : i < st.passo ? 'feito' : ''}"${i === st.passo ? ' aria-current="step"' : ''}>${p}</li>`).join('');
    btnVoltar.style.visibility = st.passo === 0 ? 'hidden' : 'visible';
    btnAvancar.textContent = st.passo === PASSOS.length - 1 ? (st.salvando ? 'Criando…' : 'Criar evento') : 'Avançar →';
    btnAvancar.disabled = st.salvando;
    erroGeral.hidden = !st.erroGeral;
    erroGeral.textContent = st.erroGeral;
    PASSO_FN[st.passo]();
  }

  btnVoltar.addEventListener('click', () => { st.passo = Math.max(0, st.passo - 1); st.erroGeral = ''; desenhar(); });

  btnAvancar.addEventListener('click', async () => {
    if (st.passo === 0) {
      st.erros = validarDados(st.evento);
      if (Object.keys(st.erros).length) { desenhar(); return; }
    }
    if (st.passo < PASSOS.length - 1) { st.passo++; desenhar(); window.scrollTo(0, 0); return; }

    st.salvando = true; st.erroGeral = ''; desenhar();
    const e = st.evento;
    try {
      await criar({
        evento: {
          nome: e.nome.trim(), contratante: e.contratante, local: e.local, cidade: e.cidade,
          data_evento: e.data_evento, data_fim: e.data_fim || '',
          publico_estimado: String(e.publico_estimado).replace(/\./g, ''),
        },
        modulos: [...st.modulos],
        equipe: st.equipe,
      });
    } catch (err) {
      console.error(err);
      st.salvando = false;
      st.erroGeral = `Não foi possível criar o evento. ${err?.message || ''}`.trim();
      desenhar();
    }
  });

  desenhar();
}
