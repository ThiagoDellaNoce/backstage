// Utilidades comuns: datas (D-x), textos e status.

/** Escapa texto para colocar em HTML. */
export function esc(v) {
  return String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

/** Data de hoje no fuso do navegador, como 'AAAA-MM-DD'. */
export function hoje() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

const dia = (iso) => Date.UTC(+iso.slice(0, 4), +iso.slice(5, 7) - 1, +iso.slice(8, 10));

/** Dias de `a` até `b` (datas 'AAAA-MM-DD'). */
export function diasEntre(a, b) {
  return Math.round((dia(b) - dia(a)) / 86400000);
}

/** Soma dias a uma data 'AAAA-MM-DD'. */
export function somarDias(iso, n) {
  return new Date(dia(iso) + n * 86400000).toISOString().slice(0, 10);
}

/** Dia relativo ao evento: D-12, D0, D+3. */
export function dx(n) {
  return n === 0 ? 'D0' : n < 0 ? `D${n}` : `D+${n}`;
}

/** 'AAAA-MM-DD' → '26/11' (ou '26/11/2027' se for de outro ano). */
export function dataCurta(iso) {
  if (!iso) return '';
  const [a, m, d] = iso.split('-');
  return a === hoje().slice(0, 4) ? `${d}/${m}` : `${d}/${m}/${a}`;
}

/** Ex.: 'quarta-feira, 26 de novembro'. */
export function dataPorExtenso(d = new Date()) {
  return d.toLocaleDateString('pt-BR', { weekday: 'long', day: 'numeric', month: 'long' });
}

export const STATUS_EVENTO = {
  planejamento: { nome: 'Planejamento', tag: '' },
  montagem: { nome: 'Montagem', tag: 'info' },
  operacao: { nome: 'Operação', tag: 'ok' },
  desmontagem: { nome: 'Desmontagem', tag: 'warn' },
  encerrado: { nome: 'Encerrado', tag: '' },
  cancelado: { nome: 'Cancelado', tag: 'bad' },
};

export const FASE = { montagem: 'Montagem', operacao: 'Operação', desmontagem: 'Desmontagem' };
export const PERIODO = { manha: 'manhã', tarde: 'tarde', noite: 'noite' };
