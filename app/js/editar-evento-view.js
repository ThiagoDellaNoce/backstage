// Editar evento: dados (todos da equipe) + telas do evento (só gestor/planejamento). Uma página, um "Salvar".
import { esc } from './util.js';
import { validarDados, limparDados, montarDados, montarChecklist } from './evento-form.js';

/**
 * @param dados  { evento, modulos (cadastro), ativos: [codigo], parametros }
 * @param salvar async ({ evento, modulos: {codigo: bool} | null }) => void
 */
export function desenharEditarEvento(main, usuario, dados, salvar) {
  const original = dados.evento;
  const ev = {
    nome: original.nome, contratante: original.contratante ?? '', local: original.local ?? '', cidade: original.cidade ?? '',
    data_evento: original.data_evento, data_fim: original.data_fim ?? '', publico_estimado: original.publico_estimado ?? '', status: original.status,
  };
  const ligadas = new Set(dados.ativos);
  const ligadasAntes = new Set(dados.ativos);
  let erros = {}, sujo = false, salvando = false;

  main.innerHTML = `
    <div>
      <div class="muted"><a href="eventos.html">Eventos</a> / <a href="evento.html?id=${original.id}">${esc(original.nome)}</a> / Editar</div>
      <h1>Editar evento</h1>
    </div>
    <section class="box">
      <h2>Dados do evento</h2>
      <div id="dados"></div>
      <div id="aviso-data" class="msg msg-info" style="margin-top:12px" hidden></div>
    </section>
    <section class="box">
      <h2>Telas do evento</h2>
      <div id="telas"></div>
    </section>
    <div id="erro-geral" class="msg msg-erro" role="alert" hidden></div>
    <div class="acoes">
      <span></span>
      <div class="dir">
        <a class="btn btn-ghost" href="evento.html?id=${original.id}">Cancelar</a>
        <button type="button" class="btn btn-primary" id="salvar">Salvar alterações</button>
      </div>
    </div>`;

  const boxDados = main.querySelector('#dados'), boxTelas = main.querySelector('#telas');
  const avisoData = main.querySelector('#aviso-data'), erroGeral = main.querySelector('#erro-geral');
  const btn = main.querySelector('#salvar');

  const marcarSujo = () => { sujo = true; };
  function mostrarAvisoData() {
    const mudou = ev.data_evento && ev.data_evento !== original.data_evento;
    avisoData.hidden = !mudou;
    if (mudou) avisoData.textContent = 'A data do evento (dia 0) mudou: prazos de documentos e o cronograma acompanham a nova data, porque são guardados como D-x.';
  }
  function desenharDados() {
    montarDados(boxDados, ev, {
      parametros: dados.parametros, erros, status: true,
      aviso: (campo) => { marcarSujo(); if (campo === 'data_evento') mostrarAvisoData(); },
    });
  }

  desenharDados();
  mostrarAvisoData();
  montarChecklist(boxTelas, dados.modulos, ligadas, usuario.admin
    ? { texto: 'Desligar uma tela só a esconde: nada é apagado e, ao religar, tudo volta. Ligar a Documentação cria os documentos padrão que faltarem.', mudou: marcarSujo }
    : { bloqueado: true, texto: 'Só gestor e planejamento ligam e desligam telas do evento.' });

  // Avisa antes de sair com alterações não salvas
  window.addEventListener('beforeunload', (e) => { if (sujo && !salvando) { e.preventDefault(); e.returnValue = ''; } });

  btn.addEventListener('click', async () => {
    erros = validarDados(ev);
    if (Object.keys(erros).length) { desenharDados(); boxDados.querySelector('.erro input')?.focus(); return; }
    erros = {};

    let mudancasTelas = null;
    if (usuario.admin) {
      mudancasTelas = {};
      for (const m of dados.modulos) {
        if (m.sempre_ativo || !m.disponivel) continue;
        if (ligadas.has(m.codigo) !== ligadasAntes.has(m.codigo)) mudancasTelas[m.codigo] = ligadas.has(m.codigo);
      }
    }
    salvando = true; btn.disabled = true; btn.textContent = 'Salvando…'; erroGeral.hidden = true;
    try {
      await salvar({ evento: { ...limparDados(ev), status: ev.status }, modulos: mudancasTelas });
    } catch (e) {
      console.error(e);
      salvando = false; btn.disabled = false; btn.textContent = 'Salvar alterações';
      erroGeral.textContent = `Não foi possível salvar. ${e?.message || ''}`.trim();
      erroGeral.hidden = false;
    }
  });
}
