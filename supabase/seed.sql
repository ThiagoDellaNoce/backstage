-- =====================================================================
-- BACKSTAGE — Carga inicial (EXP Produções) — rodar depois do schema.sql
-- Catálogo vindo do MOLDE - PLANEJAMENTO v3
-- =====================================================================

INSERT INTO empresas (nome) VALUES ('EXP Produções');

-- Categorias (Staff fica fora do cronograma: vai para Mão de obra)
INSERT INTO categorias (empresa_id, nome, ordem, entra_no_cronograma)
 SELECT e.id, c.nome, c.ordem, c.crono FROM empresas e, (VALUES
  ('Estrutura geral', 1, true),
  ('Estrutura eventual', 2, true),
  ('Estrutura bar', 3, true),
  ('Técnica', 4, true),
  ('Cenografia', 5, true),
  ('Maquinário/Serviços', 6, true),
  ('Staff', 7, false),
  ('Extras', 8, true)
 ) AS c(nome, ordem, crono) WHERE e.nome = 'EXP Produções';

-- Catálogo (60 itens). Pisos+Fechamentos viraram 'Piso e fechamentos';
-- Tendas+Lonas+Gradil viraram 'Gradil e tendas'; Barricadas e Guindaste duplicados foram unificados.
INSERT INTO catalogo_itens (empresa_id, categoria_id, nome, unidade, tipo_memoria)
 SELECT cat.empresa_id, cat.id, i.nome, i.und, i.mem::tipo_memoria FROM (VALUES
  ('Estrutura geral', 'Piso e fechamentos', 'M²', 'piso_fechamento'),
  ('Estrutura geral', 'Gradil e tendas', 'M²', 'gradil_tenda'),
  ('Cenografia', 'Cenografia geral', 'UND', 'cenografia'),
  ('Estrutura geral', 'Box diversos', 'ML', 'nenhuma'),
  ('Estrutura geral', 'Box palco', 'ML', 'nenhuma'),
  ('Estrutura eventual', 'Cobertura camarote', 'M²', 'nenhuma'),
  ('Estrutura geral', 'Banheiros químicos', 'UND', 'banheiro'),
  ('Estrutura geral', 'Ambulância', 'UND', 'nenhuma'),
  ('Estrutura geral', 'CCO (Monitoramento)', 'UND', 'nenhuma'),
  ('Estrutura bar', 'Mesas e cadeiras', 'UND', 'mesas_cadeiras'),
  ('Estrutura bar', 'Térmicas', 'UND', 'nenhuma'),
  ('Estrutura eventual', 'Barricadas', 'UND', 'barricada'),
  ('Estrutura geral', 'Frete barricada', 'UND', 'nenhuma'),
  ('Estrutura eventual', 'Passa cabo', 'UND', 'nenhuma'),
  ('Estrutura eventual', 'Octanorm', 'M²', 'nenhuma'),
  ('Estrutura eventual', 'Easyfloor FAST', 'M²', 'nenhuma'),
  ('Estrutura eventual', 'Easyfloor Plus', 'M²', 'nenhuma'),
  ('Estrutura eventual', 'Andaimes', 'UND', 'nenhuma'),
  ('Estrutura eventual', 'Container', 'UND', 'nenhuma'),
  ('Técnica', 'Som e Luz Palco', 'UND', 'nenhuma'),
  ('Técnica', 'Luz', 'UND', 'nenhuma'),
  ('Técnica', 'Painel de LED', 'UND', 'painel_led'),
  ('Técnica', 'Gerador', 'UND', 'nenhuma'),
  ('Técnica', 'Transmissão simultânea', 'UND', 'nenhuma'),
  ('Técnica', 'Iluminação ambiente/serviço', 'UND', 'nenhuma'),
  ('Cenografia', 'Forração', 'M²', 'forracao'),
  ('Cenografia', 'Mobília', 'UND', 'mobilia'),
  ('Cenografia', 'Comunicação visual', 'UND', 'com_visual'),
  ('Extras', 'Sinalização bombeiro', 'PACOTE', 'nenhuma'),
  ('Maquinário/Serviços', 'Elétrica', 'UND', 'nenhuma'),
  ('Maquinário/Serviços', 'Pia', 'UND', 'nenhuma'),
  ('Maquinário/Serviços', 'Hidráulica', 'UND', 'nenhuma'),
  ('Maquinário/Serviços', 'Caminhão pipa', 'UND', 'nenhuma'),
  ('Maquinário/Serviços', 'Guindaste', 'UND', 'nenhuma'),
  ('Maquinário/Serviços', 'PTA', 'UND', 'nenhuma'),
  ('Maquinário/Serviços', 'Internet', 'UND', 'nenhuma'),
  ('Maquinário/Serviços', 'Pedreiro', 'UND', 'nenhuma'),
  ('Maquinário/Serviços', 'Serralheiro', 'UND', 'nenhuma'),
  ('Staff', 'VJ', 'PCT', 'nenhuma'),
  ('Staff', 'Iluminador', 'UND', 'nenhuma'),
  ('Staff', 'Carregadores', 'UND', 'nenhuma'),
  ('Staff', 'trasporte limpeza', 'UND', 'nenhuma'),
  ('Staff', 'Segurança patrimonial', 'UND', 'nenhuma'),
  ('Staff', 'Seguranças', 'UND', 'nenhuma'),
  ('Staff', 'Seguranças GE', 'UND', 'nenhuma'),
  ('Staff', 'Brigadistas', 'UND', 'nenhuma'),
  ('Staff', 'Policial civil (P2)', 'UND', 'nenhuma'),
  ('Staff', 'Barman', 'UND', 'nenhuma'),
  ('Staff', 'Limpeza', 'UND', 'nenhuma'),
  ('Staff', 'Geradorista', 'UND', 'nenhuma'),
  ('Staff', 'Produção camarim', 'UND', 'nenhuma'),
  ('Staff', 'Caixas', 'UND', 'nenhuma'),
  ('Staff', 'Validadores', 'UND', 'nenhuma'),
  ('Staff', 'Controladores de acesso', 'UND', 'nenhuma'),
  ('Staff', 'Estacionamento', 'UND', 'nenhuma'),
  ('Staff', 'Foodtruck', 'UND', 'nenhuma'),
  ('Extras', 'Rádios', 'UND', 'nenhuma'),
  ('Extras', 'Crachás', 'UND', 'nenhuma'),
  ('Estrutura geral', 'Blimps', 'UND', 'nenhuma'),
  ('Estrutura geral', 'Efeitos', 'UND', 'nenhuma')
 ) AS i(cat, nome, und, mem) JOIN categorias cat ON cat.nome = i.cat;

-- Dimensionamento pelo público
INSERT INTO parametros_dimensionamento (empresa_id, codigo, nome, pessoas_por_unidade, unidade, ordem)
 SELECT id, p.* FROM empresas, (VALUES
  ('baias_entrada', 'Baias de entrada', 250, 'un', 1),
  ('banheiros',     'Banheiros',        80,  'un', 2),
  ('segurancas',    'Seguranças',       100, 'un', 3),
  ('metragem_bar',  'Metragem de bar',  100, 'm',  4)
 ) AS p(codigo, nome, pessoas, unidade, ordem) WHERE empresas.nome = 'EXP Produções';

-- Documentos criados junto com cada evento
INSERT INTO tipos_documento (empresa_id, nome)
 SELECT id, t.nome FROM empresas, (VALUES ('CEMIG'), ('AVCB'), ('CODAU'), ('Alvará')) AS t(nome)
 WHERE empresas.nome = 'EXP Produções';

-- Frases do dia (exemplos — trocar pelas da equipe)
INSERT INTO frases_do_dia (empresa_id, texto)
 SELECT id, f.t FROM empresas, (VALUES
  ('Bom dia! Hoje o palco sobe e o café não pode faltar.'),
  ('Gradil alinhado, coração tranquilo.'),
  ('Checklist em dia é show sem susto.')
 ) AS f(t) WHERE empresas.nome = 'EXP Produções';
