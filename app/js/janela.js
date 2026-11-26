// Janela modal simples, sobre o <dialog> nativo do navegador.
import { esc } from './util.js';

/**
 * Abre uma janela. `montar(corpo, fechar)` preenche o conteúdo.
 * Devolve uma Promise que resolve com o valor passado a fechar(valor).
 */

export function abrirJanela({ titulo, rodape = '' }, montar) {
  return new Promise((resolve) => {
    const d = document.createElement('dialog');
    d.className = 'janela';
    d.innerHTML = `<div class="cab"><h2>${esc(titulo)}</h2><button type="button" class="btn-x" data-fechar aria-label="Fechar">×</button></div>
      <div class="corpo"></div>${rodape ? `<div class="rodape">${rodape}</div>` : ''}`;
    let valor;
    const fechar = (v) => { valor = v; d.close(); };
    d.addEventListener('close', () => { d.remove(); resolve(valor); });
    d.querySelector('[data-fechar]').addEventListener('click', () => fechar());
    document.body.appendChild(d);
    montar(d.querySelector('.corpo'), fechar, d);
    d.showModal();
  });
}
