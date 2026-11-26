/* Tema: lê a escolha salva e monta o seletor em #tema-slot (login) ou no menu lateral (nav.side).
   Carregar no <head> sem defer, para não piscar o tema errado. */
(function () {
  var K = 'backstage-tema', d = document.documentElement, t = 'roxo';
  try { t = localStorage.getItem(K) || 'roxo'; } catch (e) {}
  d.setAttribute('data-tema', t);

  function set(v) {
    t = v;
    d.setAttribute('data-tema', v);
    try { localStorage.setItem(K, v); } catch (e) {}
    document.querySelectorAll('.tema button').forEach(function (b) {
      b.setAttribute('aria-pressed', String(b.dataset.t === v));
    });
  }

  function box() {
    var w = document.createElement('div');
    w.className = 'tema';
    w.setAttribute('role', 'group');
    w.setAttribute('aria-label', 'Tema');
    w.innerHTML = '<span>Tema</span><div>' +
      '<button type="button" data-t="roxo"><i style="background:#6b3e92"></i>Roxo</button>' +
      '<button type="button" data-t="verde"><i style="background:#1db954"></i>Verde</button></div>';
    w.addEventListener('click', function (e) {
      var b = e.target.closest('button');
      if (b) { e.preventDefault(); set(b.dataset.t); }
    });
    return w;
  }

  // Para telas que montam o menu depois do login (layout.js)
  window.BackstageTema = { box: function () { var b = box(); setTimeout(function () { set(t); }); return b; } };

  document.addEventListener('DOMContentLoaded', function () {
    var side = document.querySelector('nav.side'), slot = document.getElementById('tema-slot');
    if (side) { if (!side.querySelector('.tema') && !side.hasAttribute('aria-busy')) side.insertBefore(box(), side.querySelector('[data-sair]') || null); }
    else if (slot) slot.appendChild(box());
    set(t);
  });
})();
