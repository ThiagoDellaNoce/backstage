// Janela "Frases do dia" (Painel): gestor e planejamento incluem, editam, ligam/desligam e apagam.
// Cada mudança grava na hora. Devolve a lista de frases ativas ao fechar.
import { supabase } from './supabase.js';
import { esc } from './util.js';
import { abrirJanela } from './janela.js';

export async function editarFrases(usuario) {
  const { data, error } = await supabase.from('frases_do_dia').select('id, texto, ativa').order('id');
  if (error) throw error;
  let frases = data;

  await abrirJanela({ titulo: 'Frases do dia', rodape: '<button type="button" class="btn btn-primary" data-ok>Pronto</button>' }, (corpo, fechar, d) => {
    d.querySelector('[data-ok]').addEventListener('click', () => fechar());

    function desenhar(msg = '') {
      corpo.innerHTML = `
        <div class="muted">Uma frase ativa é sorteada por dia no Painel. Desmarque para tirar do sorteio sem apagar.</div>
        <div class="linha-add">
          <input type="text" id="nova" placeholder="Nova frase…" maxlength="200" style="flex:1 1 260px" aria-label="Nova frase">
          <button type="button" class="btn btn-primary btn-sm" id="incluir">+ Incluir</button>
        </div>
        ${msg ? `<div class="msg msg-erro" role="alert">${esc(msg)}</div>` : ''}
        <div class="frases">${frases.length ? frases.map((f) => `
          <div class="frase${f.ativa ? '' : ' inativa'}" data-id="${f.id}">
            <input type="checkbox"${f.ativa ? ' checked' : ''} aria-label="Ativa" title="Ativa no sorteio">
            <input type="text" value="${esc(f.texto)}" maxlength="200" aria-label="Texto da frase">
            <button type="button" class="btn-x" data-apagar aria-label="Apagar frase" title="Apagar">×</button>
          </div>`).join('') : '<div class="vazio">Nenhuma frase cadastrada.</div>'}
        </div>
        <div class="muted" style="font-size:12px">${frases.filter((f) => f.ativa).length} ativa(s) de ${frases.length}.</div>`;

      const nova = corpo.querySelector('#nova');
      const incluir = async () => {
        const texto = nova.value.trim();
        if (!texto) { nova.focus(); return; }
        const r = await supabase.from('frases_do_dia').insert({ empresa_id: usuario.empresa_id, texto }).select('id, texto, ativa').single();
        if (r.error) { console.error(r.error); desenhar('Não foi possível incluir a frase.'); return; }
        frases.push(r.data);
        desenhar();
        corpo.querySelector('#nova').focus();
      };
      corpo.querySelector('#incluir').addEventListener('click', incluir);
      nova.addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.preventDefault(); incluir(); } });

      corpo.querySelectorAll('.frase').forEach((linha) => {
        const id = Number(linha.dataset.id);
        const f = frases.find((x) => x.id === id);
        const [caixa, texto] = linha.querySelectorAll('input');
        caixa.addEventListener('change', async () => {
          const r = await supabase.from('frases_do_dia').update({ ativa: caixa.checked }).eq('id', id);
          if (r.error) { console.error(r.error); desenhar('Não foi possível salvar.'); return; }
          f.ativa = caixa.checked;
          desenhar();
        });
        texto.addEventListener('change', async () => {
          const t = texto.value.trim();
          if (!t) { texto.value = f.texto; return; }
          const r = await supabase.from('frases_do_dia').update({ texto: t }).eq('id', id);
          if (r.error) { console.error(r.error); desenhar('Não foi possível salvar.'); return; }
          f.texto = t;
        });
        linha.querySelector('[data-apagar]').addEventListener('click', async () => {
          if (!confirm(`Apagar a frase "${f.texto}"?`)) return;
          const r = await supabase.from('frases_do_dia').delete().eq('id', id);
          if (r.error) { console.error(r.error); desenhar('Não foi possível apagar.'); return; }
          frases = frases.filter((x) => x.id !== id);
          desenhar();
        });
      });
    }
    desenhar();
  });

  return frases.filter((f) => f.ativa);
}
