// Menu lateral comum às telas internas.
import { sair } from './auth.js';
import { esc } from './util.js';

// href nulo = tela ainda não construída (aparece como "em breve")
const MENU = [
  { id: 'painel', nome: 'Painel', href: 'painel.html' },
  { id: 'eventos', nome: 'Eventos', href: null },
  { sec: 'Empresa' },
  { id: 'estoque', nome: 'Estoque', href: null },
  { id: 'cadastros', nome: 'Cadastros', href: null },
];

/**
 * Monta o menu dentro de <div class="app"> e devolve o <main> para a tela preencher.
 * @param {object} usuario  vindo de exigirLogin()
 * @param {string} ativo    id do item do menu da tela atual
 */
export function montarLayout(usuario, ativo) {
  const app = document.querySelector('.app');
  const nav = document.createElement('nav');
  nav.className = 'side';
  nav.setAttribute('aria-label', 'Menu principal');

  nav.innerHTML = '<div class="marca">backstage</div>' + MENU.map((m) => {
    if (m.sec) return `<div class="sec">${esc(m.sec)}</div>`;
    if (!m.href) return `<span class="item-off" aria-disabled="true">${esc(m.nome)}<span class="breve">em breve</span></span>`;
    const on = m.id === ativo;
    return `<a href="${m.href}"${on ? ' class="on" aria-current="page"' : ''}>${esc(m.nome)}</a>`;
  }).join('') +
    '<div class="espaco"></div>' +
    '<span class="item-off"><span class="ponto"></span>Asana<span class="breve">em breve</span></span>';

  if (window.BackstageTema) nav.appendChild(window.BackstageTema.box());

  const s = document.createElement('a');
  s.href = '#';
  s.dataset.sair = '';
  s.textContent = `Sair · ${usuario.nome}`;
  s.addEventListener('click', (e) => { e.preventDefault(); sair(); });
  nav.appendChild(s);

  app.prepend(nav);
  return app.querySelector('main');
}
