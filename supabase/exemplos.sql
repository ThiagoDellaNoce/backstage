-- =====================================================================
-- EVENTOS DE EXEMPLO (só para ver as telas com dados)
-- Rodar no SQL Editor do Supabase DEPOIS do schema, do seed e do
-- cadastro do primeiro usuário. As datas são relativas a hoje.
-- Todos os nomes começam com "[Exemplo]". Para apagar tudo, rode só:
--   DELETE FROM eventos WHERE nome LIKE '[Exemplo]%';
-- =====================================================================

-- Limpa uma rodada anterior, para poder rodar de novo
DELETE FROM eventos WHERE nome LIKE '[Exemplo]%';

-- 1. Eventos (o gatilho cria os documentos padrão e põe o criador na equipe)
INSERT INTO eventos (empresa_id, nome, contratante, local, cidade, data_evento, data_fim, publico_estimado, status, criado_por)
SELECT u.empresa_id, e.nome, e.contratante, e.local, e.cidade,
       current_date + e.ini, current_date + e.fim, e.publico, e.status::status_evento, u.id
FROM (SELECT * FROM usuarios WHERE papel IN ('gestor', 'planejamento') AND ativo ORDER BY criado_em LIMIT 1) u,
(VALUES
  ('[Exemplo] Feira Agro',          'Sindicato Rural',   'Parque de Exposições', 'Araxá',      -1,   1, 12000, 'operacao'),
  ('[Exemplo] Corrida de Rua',      'Prefeitura',        'Praça Central',        'Uberaba',     0,   0,  1500, 'operacao'),
  ('[Exemplo] Festival de Verão',   'Verão Produções',   'Parque do Lago',       'Uberaba',    12,  14,  8000, 'montagem'),
  ('[Exemplo] Show Sertanejo',      'Arena Shows',       'Arena Multiuso',       'Uberlândia', 30,  30,  5000, 'planejamento'),
  ('[Exemplo] Congresso Médico',    'Associação Médica', 'Centro de Convenções', 'Uberaba',    60,  62,   900, 'planejamento')
) AS e(nome, contratante, local, cidade, ini, fim, publico, status);

-- 2. Documentos: prazos e situações para aparecerem nos Pontos de atenção
UPDATE documentos d
SET prazo_dia_relativo = x.prazo, status = x.status::status_documento
FROM eventos ev, tipos_documento t,
(VALUES
  ('[Exemplo] Festival de Verão', 'AVCB',   -15, 'pendente'),     -- venceu há 3 dias
  ('[Exemplo] Festival de Verão', 'Alvará',  -9, 'protocolado'),  -- vence em 3 dias
  ('[Exemplo] Festival de Verão', 'CODAU',   -5, 'em_analise'),   -- ainda longe
  ('[Exemplo] Festival de Verão', 'CEMIG',  -20, 'aprovado'),     -- ok
  ('[Exemplo] Show Sertanejo',    'CODAU',  -20, 'indeferido'),
  ('[Exemplo] Show Sertanejo',    'CEMIG',  -28, 'pendente'),     -- vence em 2 dias
  ('[Exemplo] Feira Agro',        'AVCB',   -10, 'aprovado'),
  ('[Exemplo] Feira Agro',        'Alvará',  -3, 'aprovado'),
  ('[Exemplo] Corrida de Rua',    'Alvará',  -7, 'aprovado')
) AS x(evento, tipo, prazo, status)
WHERE ev.nome = x.evento AND d.evento_id = ev.id
  AND t.nome = x.tipo AND d.tipo_id = t.id;

-- 3. Setores e cronograma de hoje (atividades avulsas)
INSERT INTO setores (evento_id, nome, ordem)
SELECT ev.id, s.nome, s.ordem FROM eventos ev,
(VALUES
  ('[Exemplo] Corrida de Rua', 'Largada', 1),
  ('[Exemplo] Corrida de Rua', 'Chegada', 2),
  ('[Exemplo] Feira Agro',     'Pavilhão', 1)
) AS s(evento, nome, ordem)
WHERE ev.nome = s.evento;

INSERT INTO cronograma_linhas (evento_id, setor_id, titulo, ordem)
SELECT s.evento_id, s.id, l.titulo, l.ordem
FROM setores s JOIN eventos ev ON ev.id = s.evento_id,
(VALUES
  ('[Exemplo] Corrida de Rua', 'Largada',  'Pórtico de largada', 1),
  ('[Exemplo] Corrida de Rua', 'Chegada',  'Tendas de apoio',    1),
  ('[Exemplo] Feira Agro',     'Pavilhão', 'Som e luz',          1)
) AS l(evento, setor, titulo, ordem)
WHERE ev.nome = l.evento AND s.nome = l.setor;

-- dia_relativo: Corrida é hoje (D0); a Feira começou ontem, então hoje é D+1
INSERT INTO cronograma_marcacoes (linha_id, dia_relativo, periodo, fase)
SELECT l.id, m.dia, m.periodo::periodo_dia, m.fase::fase_cronograma
FROM cronograma_linhas l JOIN eventos ev ON ev.id = l.evento_id,
(VALUES
  ('[Exemplo] Corrida de Rua', 'Pórtico de largada', 0, 'manha', 'montagem'),
  ('[Exemplo] Corrida de Rua', 'Tendas de apoio',    0, 'tarde', 'montagem'),
  ('[Exemplo] Corrida de Rua', 'Pórtico de largada', 0, 'noite', 'desmontagem'),
  ('[Exemplo] Feira Agro',     'Som e luz',          1, 'noite', 'operacao')
) AS m(evento, titulo, dia, periodo, fase)
WHERE ev.nome = m.evento AND l.titulo = m.titulo;

-- Conferência rápida
SELECT nome, data_evento, status FROM eventos WHERE nome LIKE '[Exemplo]%' ORDER BY data_evento;
