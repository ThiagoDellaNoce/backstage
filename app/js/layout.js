// Menu lateral comum às telas internas (+ submenu e abas quando se está dentro de um evento).
import { sair } from './auth.js';
import { esc } from './util.js';

// href nulo = tela ainda não construída (aparece como "em breve")
const MENU = [
  { id: 'painel', nome: 'Painel', href: 'painel.html' },
  { id: 'eventos', nome: 'Eventos', href: 'eventos.html' },
  { sec: 'Empresa' },
  { id: 'estoque', nome: 'Estoque', href: null },
  { id: 'cadastros', nome: 'Cadastros', href: null },
];

// Abas do evento, na ordem combinada. Pagamentos fica sempre por último e desabilitada.
export const ABAS_EVENTO = [
  { codigo: 'visao_geral', nome: 'Visão geral', href: 'evento.html' },
  { codigo: 'planilha', nome: 'Planilha de trabalho', href: null },
  { codigo: 'cronograma', nome: 'Cronograma', href: null },
  { codigo: 'artistico', nome: 'Artístico', href: null },
  { codigo: 'documentacao', nome: 'Documentação', href: null },
];

/** Abas visíveis de um evento, conforme o checklist (evento_modulos ativos). */
export function abasDoEvento(ativos) {
  const on = new Set(ativos);
  return ABAS_EVENTO.filter((a) => on.has(a.codigo));
}

function itemAba(a, eventoId, ativa) {
  if (!a.href) return `<span class="item-off" aria-disabled="true" title="Em breve">${esc(a.nome)}<span class="breve">em breve</span></span>`;
  const on = a.codigo === ativa;
  return `<a href="${a.href}?id=${eventoId}"${on ? ' class="on" aria-current="page"' : ''}>${esc(a.nome)}</a>`;
}
const PAGAMENTOS = '<span class="item-off" aria-disabled="true" title="Os pagamentos seguem no sistema atual da EXP">Pagamentos<span class="breve">em breve</span></span>';

/** Barra de abas do evento (topo do conteúdo). */
export function htmlAbas(evento, abas, ativa) {
  return `<nav class="abas" aria-label="Seções do evento">${abas.map((a) => itemAba(a, evento.id, ativa)).join('')}${PAGAMENTOS}</nav>`;
}

/**
 * Monta o menu dentro de <div class="app"> e devolve o <main> para a tela preencher.
 * @param {object} usuario  vindo de exigirLogin()
 * @param {string} ativo    id do item do menu da tela atual
 * @param {object} [noEvento]  { evento: {id, nome}, abas, aba } para mostrar o submenu do evento
 */
export function montarLayout(usuario, ativo, noEvento) {
  const app = document.querySelector('.app');
  let nav = app.querySelector('nav.side');
  const novo = !nav;
  if (novo) {
    nav = document.createElement('nav');
    nav.className = 'side';
    nav.setAttribute('aria-label', 'Menu principal');
  }
  nav.removeAttribute('aria-busy');
  app.querySelector('main')?.removeAttribute('aria-busy');

  const sub = noEvento
    ? `<div class="sub"><div class="ev" title="${esc(noEvento.evento.nome)}">${esc(noEvento.evento.nome)}</div>${noEvento.abas.map((a) => itemAba(a, noEvento.evento.id, noEvento.aba)).join('')}${PAGAMENTOS}</div>`
    : '';

  nav.innerHTML = '<div class="marca">backstage</div>' + MENU.map((m) => {
    if (m.sec) return `<div class="sec">${esc(m.sec)}</div>`;
    if (!m.href) return `<span class="item-off" aria-disabled="true">${esc(m.nome)}<span class="breve">em breve</span></span>`;
    const on = m.id === ativo && !noEvento;
    const link = `<a href="${m.href}"${on ? ' class="on" aria-current="page"' : m.id === ativo ? ' class="par"' : ''}>${esc(m.nome)}</a>`;
    return m.id === ativo ? link + sub : link;
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

  if (novo) app.prepend(nav);
  return app.querySelector('main');
}
