-- =====================================================================
-- BACKSTAGE — Sistema de controle de eventos (EXP Produções)
-- Modelo de dados v0.3 — PostgreSQL 15+ / Supabase
-- ---------------------------------------------------------------------
-- O que mudou em relação à v0.2:
--   • Usuários ligados ao login do Supabase (auth.users) + permissões (RLS)
--   • Checklist de telas por evento (modulos / evento_modulos)
--   • Setores do evento, ordenáveis, usados por memórias e cronograma
--   • 10 memórias de cálculo com tabela própria e regras no banco
--     (Piso e fechamentos, Gradil e tendas etc.); só o resultado sobe
--     para a planilha mãe
--   • Cronograma por setor, dia relativo e período (manhã/tarde/noite)
--   • Parâmetros de dimensionamento pelo público (baias, banheiros…)
--   • Conferência em campo, anexos, histórico de alterações
--   • Pagamentos fora do MVP (sistema atual da EXP) — só um campo de
--     referência externa na planilha
--   • Asana: vínculo do usuário; tokens ficam no Supabase Vault
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. EXTENSÕES E FUNÇÕES DE APOIO
-- ---------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Mantém atualizado_em em dia
CREATE OR REPLACE FUNCTION fn_set_atualizado_em() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.atualizado_em := now();
  RETURN NEW;
END $$;

-- ---------------------------------------------------------------------
-- 1. TIPOS FIXOS
-- (listas que só mudam junto com o sistema; o resto é tabela de cadastro)
-- ---------------------------------------------------------------------
CREATE TYPE papel_usuario AS ENUM (
  'gestor', 'planejamento', 'arquiteto',
  'produtor_bar', 'produtor_palco', 'produtor_geral', 'freelance'
);

CREATE TYPE status_evento AS ENUM (
  'planejamento', 'montagem', 'operacao', 'desmontagem', 'encerrado', 'cancelado'
);

CREATE TYPE status_etapa AS ENUM ('pendente', 'em_andamento', 'concluido', 'cancelado');

-- Qual memória de cálculo um item do catálogo usa
CREATE TYPE tipo_memoria AS ENUM (
  'nenhuma',
  'com_visual', 'forracao', 'cenografia', 'piso_fechamento', 'gradil_tenda',
  'banheiro', 'barricada', 'painel_led', 'mesas_cadeiras', 'mobilia'
);

CREATE TYPE periodo_dia     AS ENUM ('manha', 'tarde', 'noite');
CREATE TYPE fase_cronograma AS ENUM ('montagem', 'operacao', 'desmontagem');

CREATE TYPE status_documento AS ENUM (
  'pendente', 'protocolado', 'em_analise', 'aprovado', 'indeferido'
);

CREATE TYPE status_conferencia AS ENUM ('a_conferir', 'conforme', 'divergente');

-- ---------------------------------------------------------------------
-- 2. EMPRESA E USUÁRIOS
-- ---------------------------------------------------------------------
CREATE TABLE empresas (
  id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome          TEXT NOT NULL,
  cnpj          TEXT UNIQUE,
  matriz_id     BIGINT REFERENCES empresas(id),     -- filiais apontam para a matriz
  criado_em     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Um usuário do sistema = uma conta de login do Supabase (Google da EXP)
CREATE TABLE usuarios (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  empresa_id    BIGINT NOT NULL REFERENCES empresas(id),
  nome          TEXT NOT NULL,
  email         TEXT NOT NULL UNIQUE,
  telefone      TEXT,
  papel         papel_usuario NOT NULL,            -- papel padrão
  ativo         BOOLEAN NOT NULL DEFAULT true,
  criado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Integrações por usuário (Asana). O token NÃO fica aqui:
-- vai para o Supabase Vault e só uma Edge Function o lê.
CREATE TABLE usuario_integracoes (
  usuario_id        UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  provedor          TEXT NOT NULL CHECK (provedor IN ('asana')),
  usuario_externo   TEXT,                         -- gid do usuário no Asana
  workspace_externo TEXT,                         -- gid do workspace
  vault_secret_id   UUID,                         -- referência ao token no Vault
  conectado_em      TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (usuario_id, provedor)
);

-- Frases do dia do Painel (uma sorteada por dia)
CREATE TABLE frases_do_dia (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  empresa_id  BIGINT NOT NULL REFERENCES empresas(id),
  texto       TEXT NOT NULL,
  ativa       BOOLEAN NOT NULL DEFAULT true
);

-- Regras de dimensionamento pelo público (editáveis pela empresa)
CREATE TABLE parametros_dimensionamento (
  empresa_id  BIGINT NOT NULL REFERENCES empresas(id),
  codigo      TEXT NOT NULL,                      -- baias_entrada, banheiros, segurancas, metragem_bar
  nome        TEXT NOT NULL,
  pessoas_por_unidade NUMERIC NOT NULL CHECK (pessoas_por_unidade > 0),
  unidade     TEXT NOT NULL DEFAULT 'un',
  ordem       INT NOT NULL DEFAULT 0,
  PRIMARY KEY (empresa_id, codigo)
);

-- ---------------------------------------------------------------------
-- 3. CADASTROS DA EMPRESA
-- ---------------------------------------------------------------------
CREATE TABLE fornecedores (
  id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  empresa_id      BIGINT NOT NULL REFERENCES empresas(id),
  nome            TEXT NOT NULL,
  cnpj            TEXT,
  categoria       TEXT,
  contato         TEXT,
  telefone        TEXT,
  email           TEXT,
  dados_bancarios TEXT,                           -- chave PIX / conta
  ativo           BOOLEAN NOT NULL DEFAULT true,
  criado_em       TIMESTAMPTZ NOT NULL DEFAULT now(),
  atualizado_em   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (empresa_id, cnpj)
);

CREATE TABLE hoteis (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  empresa_id  BIGINT NOT NULL REFERENCES empresas(id),
  nome        TEXT NOT NULL,
  cidade      TEXT,
  endereco    TEXT,
  contato     TEXT
);

-- Categorias da planilha: Estrutura geral, Estrutura eventual, Estrutura bar,
-- Técnica, Cenografia, Maquinário/Serviços, Staff, Extras
CREATE TABLE categorias (
  id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  empresa_id          BIGINT NOT NULL REFERENCES empresas(id),
  nome                TEXT NOT NULL,
  ordem               INT NOT NULL DEFAULT 0,
  entra_no_cronograma BOOLEAN NOT NULL DEFAULT true,  -- Staff = false (vai para Mão de obra)
  UNIQUE (empresa_id, nome)
);

-- Catálogo reutilizável (os ~60 itens do molde v3)
CREATE TABLE catalogo_itens (
  id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  empresa_id    BIGINT NOT NULL REFERENCES empresas(id),
  categoria_id  BIGINT NOT NULL REFERENCES categorias(id),
  nome          TEXT NOT NULL,
  unidade       TEXT NOT NULL DEFAULT 'UND',       -- M², ML, UND, PCT, Diária
  tipo_memoria  tipo_memoria NOT NULL DEFAULT 'nenhuma',
  ativo         BOOLEAN NOT NULL DEFAULT true,
  UNIQUE (categoria_id, nome)
);

-- ---------------------------------------------------------------------
-- 4. TELAS (MÓDULOS) — o checklist do "Novo evento"
-- ---------------------------------------------------------------------
-- Lista fixa das telas do sistema. sempre_ativo = não aparece no checklist.
CREATE TABLE modulos (
  codigo        TEXT PRIMARY KEY,
  nome          TEXT NOT NULL,
  grupo         TEXT NOT NULL,                    -- nucleo, modulo, estrutura, tecnica_visual, mobiliario
  pergunta      TEXT,                             -- texto do checklist
  tipo_memoria  tipo_memoria,                     -- preenchido nas 10 memórias
  sempre_ativo  BOOLEAN NOT NULL DEFAULT false,
  disponivel    BOOLEAN NOT NULL DEFAULT true,    -- false = "em breve" (ex.: Pagamentos)
  ordem         INT NOT NULL DEFAULT 0
);

INSERT INTO modulos (codigo, nome, grupo, pergunta, tipo_memoria, sempre_ativo, disponivel, ordem) VALUES
 ('visao_geral',     'Visão geral',          'nucleo',         NULL, NULL, true,  true,  1),
 ('planilha',        'Planilha de trabalho', 'nucleo',         NULL, NULL, true,  true,  2),
 ('cronograma',      'Cronograma',           'modulo',         'Vai usar cronograma?', NULL, false, true, 3),
 ('artistico',       'Artístico',            'modulo',         'Vai ter atrações / artístico?', NULL, false, true, 4),
 ('documentacao',    'Documentação',         'modulo',         'Precisa de documentação (alvará, AVCB…)?', NULL, false, true, 5),
 ('mao_de_obra',     'Mão de obra',          'modulo',         'Vai controlar mão de obra?', NULL, false, false, 6),
 ('pagamentos',      'Pagamentos',           'modulo',         NULL, NULL, false, false, 99),
 ('piso_fechamento', 'Piso e fechamentos',   'estrutura',      'Vai ter piso, rampa ou fechamento?', 'piso_fechamento', false, true, 10),
 ('gradil_tenda',    'Gradil e tendas',      'estrutura',      'Vai ter tenda, gradil ou lona?',     'gradil_tenda',    false, true, 11),
 ('barricada',       'Barricadas',           'estrutura',      'Vai ter barricada?',                 'barricada',       false, true, 12),
 ('banheiro',        'Banheiros químicos',   'estrutura',      'Vai ter banheiro químico?',          'banheiro',        false, true, 13),
 ('painel_led',      'Painel de LED',        'tecnica_visual', 'Vai ter painel de LED?',             'painel_led',      false, true, 20),
 ('com_visual',      'Comunicação visual',   'tecnica_visual', 'Vai ter comunicação visual?',        'com_visual',      false, true, 21),
 ('forracao',        'Forração',             'tecnica_visual', 'Vai ter forração?',                  'forracao',        false, true, 22),
 ('cenografia',      'Cenografia geral',     'tecnica_visual', 'Vai ter cenografia?',                'cenografia',      false, true, 23),
 ('mesas_cadeiras',  'Mesas e cadeiras',     'mobiliario',     'Vai ter mesas e cadeiras?',          'mesas_cadeiras',  false, true, 30),
 ('mobilia',         'Mobília',              'mobiliario',     'Vai ter mobília (lounge, camarim)?', 'mobilia',         false, true, 31);

-- Modelos prontos ("Show em espaço aberto", "Corporativo"…)
CREATE TABLE modelos_evento (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  empresa_id  BIGINT NOT NULL REFERENCES empresas(id),
  nome        TEXT NOT NULL,
  UNIQUE (empresa_id, nome)
);
CREATE TABLE modelo_modulos (
  modelo_id   BIGINT NOT NULL REFERENCES modelos_evento(id) ON DELETE CASCADE,
  modulo      TEXT   NOT NULL REFERENCES modulos(codigo),
  PRIMARY KEY (modelo_id, modulo)
);

-- ---------------------------------------------------------------------
-- 5. EVENTO
-- ---------------------------------------------------------------------
CREATE TABLE eventos (
  id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  empresa_id       BIGINT NOT NULL REFERENCES empresas(id),
  nome             TEXT NOT NULL,
  contratante      TEXT,                          -- produtor / cliente
  local            TEXT,
  cidade           TEXT,
  data_evento      DATE NOT NULL,                 -- "dia 0" (D0) de cronograma e prazos
  data_fim         DATE,
  publico_estimado INT CHECK (publico_estimado >= 0),
  status           status_evento NOT NULL DEFAULT 'planejamento',
  modelo_id        BIGINT REFERENCES modelos_evento(id),   -- modelo usado na criação
  criado_por       UUID REFERENCES usuarios(id),
  criado_em        TIMESTAMPTZ NOT NULL DEFAULT now(),
  atualizado_em    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (data_fim IS NULL OR data_fim >= data_evento)
);

-- Quem trabalha em cada evento e com qual função
CREATE TABLE evento_equipe (
  evento_id   BIGINT NOT NULL REFERENCES eventos(id) ON DELETE CASCADE,
  usuario_id  UUID   NOT NULL REFERENCES usuarios(id),
  papel       papel_usuario NOT NULL,
  PRIMARY KEY (evento_id, usuario_id)
);

-- Checklist: quais telas estão ligadas neste evento.
-- Desligar = ativo false (os dados ficam guardados, nada é apagado).
CREATE TABLE evento_modulos (
  evento_id      BIGINT NOT NULL REFERENCES eventos(id) ON DELETE CASCADE,
  modulo         TEXT   NOT NULL REFERENCES modulos(codigo),
  ativo          BOOLEAN NOT NULL DEFAULT true,
  alterado_por   UUID REFERENCES usuarios(id),
  alterado_em    TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (evento_id, modulo)
);

-- Setores do evento (Portaria, Palco, VIP…), em ordem livre.
-- Usados pelas memórias de cálculo e pelo cronograma.
CREATE TABLE setores (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  evento_id  BIGINT NOT NULL REFERENCES eventos(id) ON DELETE CASCADE,
  nome       TEXT NOT NULL,
  ordem      INT  NOT NULL DEFAULT 0,
  UNIQUE (evento_id, nome),
  UNIQUE (id, evento_id)                          -- para FKs compostas
);

-- ---------------------------------------------------------------------
-- 6. PLANILHA DE TRABALHO
-- ---------------------------------------------------------------------
CREATE TABLE planilha_itens (
  id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  evento_id         BIGINT NOT NULL REFERENCES eventos(id) ON DELETE CASCADE,
  catalogo_item_id  BIGINT NOT NULL REFERENCES catalogo_itens(id),
  tipo_memoria      tipo_memoria NOT NULL DEFAULT 'nenhuma',  -- copiado do catálogo (trigger)
  descritivo        TEXT,
  observacao        TEXT,
  fornecedor_id     BIGINT REFERENCES fornecedores(id),
  responsavel_id    UUID   REFERENCES usuarios(id),
  unidade           TEXT,
  -- Usados só quando o item NÃO tem memória de cálculo:
  quantidade        NUMERIC NOT NULL DEFAULT 0 CHECK (quantidade >= 0),
  valor_unitario    NUMERIC(12,2) NOT NULL DEFAULT 0,
  frequencia        NUMERIC NOT NULL DEFAULT 1 CHECK (frequencia > 0),   -- diárias
  status_contrato   status_etapa NOT NULL DEFAULT 'pendente',
  status_producao   status_etapa NOT NULL DEFAULT 'pendente',
  pagamento_ref_externa TEXT,                     -- id/link no sistema de pagamentos atual
  ordem             INT NOT NULL DEFAULT 0,
  arquivado         BOOLEAN NOT NULL DEFAULT false,
  criado_em         TIMESTAMPTZ NOT NULL DEFAULT now(),
  atualizado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (id, evento_id, tipo_memoria)            -- alvo das FKs das memórias
);

CREATE OR REPLACE FUNCTION fn_planilha_tipo_memoria() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  SELECT c.tipo_memoria, coalesce(NEW.unidade, c.unidade)
    INTO NEW.tipo_memoria, NEW.unidade
  FROM catalogo_itens c WHERE c.id = NEW.catalogo_item_id;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_planilha_tipo_memoria
  BEFORE INSERT OR UPDATE OF catalogo_item_id ON planilha_itens
  FOR EACH ROW EXECUTE FUNCTION fn_planilha_tipo_memoria();

-- ---------------------------------------------------------------------
-- 7. MEMÓRIAS DE CÁLCULO
-- Cada linha pertence a um item da planilha do mesmo tipo de memória
-- (garantido pela FK composta). Só o total sobe para a planilha mãe.
-- Colunas comuns: evento_id, planilha_item_id, setor_id, ordem.
-- ---------------------------------------------------------------------

-- 7.1 Comunicação visual — M² = largura × altura; valor total digitado
CREATE TABLE mem_com_visual (
  id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  evento_id         BIGINT NOT NULL,
  planilha_item_id  BIGINT NOT NULL,
  tipo_memoria      tipo_memoria NOT NULL DEFAULT 'com_visual' CHECK (tipo_memoria = 'com_visual'),
  setor_id          BIGINT,
  item              TEXT NOT NULL,
  codigo            TEXT,
  largura           NUMERIC(10,2) CHECK (largura >= 0),
  altura            NUMERIC(10,2) CHECK (altura >= 0),
  m2                NUMERIC(12,2) GENERATED ALWAYS AS (coalesce(largura,0) * coalesce(altura,0)) STORED,
  valor_total       NUMERIC(12,2) NOT NULL DEFAULT 0,
  ordem             INT NOT NULL DEFAULT 0,
  FOREIGN KEY (planilha_item_id, evento_id, tipo_memoria) REFERENCES planilha_itens(id, evento_id, tipo_memoria) ON DELETE CASCADE,
  FOREIGN KEY (setor_id, evento_id) REFERENCES setores(id, evento_id)
);

-- 7.2 Forração — M² = L × A; total = M² × preço und × quantidade
CREATE TABLE mem_forracao (
  id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  evento_id         BIGINT NOT NULL,
  planilha_item_id  BIGINT NOT NULL,
  tipo_memoria      tipo_memoria NOT NULL DEFAULT 'forracao' CHECK (tipo_memoria = 'forracao'),
  setor_id          BIGINT,
  item              TEXT NOT NULL,
  codigo            TEXT,
  estilo            TEXT,
  largura           NUMERIC(10,2) CHECK (largura >= 0),
  altura            NUMERIC(10,2) CHECK (altura >= 0),
  m2                NUMERIC(12,2) GENERATED ALWAYS AS (coalesce(largura,0) * coalesce(altura,0)) STORED,
  preco_unitario    NUMERIC(12,2) NOT NULL DEFAULT 0,
  quantidade        NUMERIC NOT NULL DEFAULT 1 CHECK (quantidade >= 0),
  total             NUMERIC(14,2) GENERATED ALWAYS AS
                      (coalesce(largura,0) * coalesce(altura,0) * preco_unitario * quantidade) STORED,
  local_aplicacao   TEXT,
  cor               TEXT,
  ordem             INT NOT NULL DEFAULT 0,
  FOREIGN KEY (planilha_item_id, evento_id, tipo_memoria) REFERENCES planilha_itens(id, evento_id, tipo_memoria) ON DELETE CASCADE,
  FOREIGN KEY (setor_id, evento_id) REFERENCES setores(id, evento_id)
);

-- 7.3 Cenografia geral — total = preço × quantidade; comparado ao teto
-- ("Preço Duzão" da planilha v3 — nome a confirmar)
CREATE TABLE mem_cenografia (
  id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  evento_id         BIGINT NOT NULL,
  planilha_item_id  BIGINT NOT NULL,
  tipo_memoria      tipo_memoria NOT NULL DEFAULT 'cenografia' CHECK (tipo_memoria = 'cenografia'),
  setor_id          BIGINT,
  item              TEXT NOT NULL,
  descritivo        TEXT,
  preco_unitario    NUMERIC(12,2) NOT NULL DEFAULT 0,
  quantidade        NUMERIC NOT NULL DEFAULT 1 CHECK (quantidade >= 0),
  total             NUMERIC(14,2) GENERATED ALWAYS AS (preco_unitario * quantidade) STORED,
  teto_orcamentario NUMERIC(14,2),
  acima_do_teto     BOOLEAN GENERATED ALWAYS AS
                      (teto_orcamentario IS NOT NULL AND preco_unitario * quantidade > teto_orcamentario) STORED,
  local_aplicacao   TEXT,
  cor               TEXT,
  ordem             INT NOT NULL DEFAULT 0,
  FOREIGN KEY (planilha_item_id, evento_id, tipo_memoria) REFERENCES planilha_itens(id, evento_id, tipo_memoria) ON DELETE CASCADE,
  FOREIGN KEY (setor_id, evento_id) REFERENCES setores(id, evento_id)
);

-- 7.4 Piso e fechamentos
--   Área M² só para Piso/Escada/Arquibancada/Rampa; Metragem linear só para Fechamento.
--   Valor = valor unitário × área (ou × metragem linear no Fechamento).
CREATE TYPE item_piso AS ENUM ('piso', 'escada', 'arquibancada', 'fechamento', 'rampa');

CREATE TABLE mem_piso_fechamento (
  id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  evento_id         BIGINT NOT NULL,
  planilha_item_id  BIGINT NOT NULL,
  tipo_memoria      tipo_memoria NOT NULL DEFAULT 'piso_fechamento' CHECK (tipo_memoria = 'piso_fechamento'),
  setor_id          BIGINT,
  item              item_piso NOT NULL,
  posicionamento    TEXT,
  altura            NUMERIC(10,2) CHECK (altura >= 0),
  quantidade        NUMERIC NOT NULL DEFAULT 1 CHECK (quantidade >= 0),
  largura           NUMERIC(10,2) CHECK (largura >= 0),
  comprimento       NUMERIC(10,2) CHECK (comprimento >= 0),
  area_m2           NUMERIC(12,2) CHECK (area_m2 >= 0),       -- tela sugere qtd × larg × compr
  metragem_linear   NUMERIC(12,2) CHECK (metragem_linear >= 0),
  valor_unitario    NUMERIC(12,2) NOT NULL DEFAULT 0,
  valor             NUMERIC(14,2) GENERATED ALWAYS AS (
                      CASE WHEN item = 'fechamento' THEN valor_unitario * coalesce(metragem_linear,0)
                           ELSE valor_unitario * coalesce(area_m2,0) END) STORED,
  ordem             INT NOT NULL DEFAULT 0,
  CHECK (item <> 'fechamento' OR area_m2 IS NULL),
  CHECK (item =  'fechamento' OR metragem_linear IS NULL),
  FOREIGN KEY (planilha_item_id, evento_id, tipo_memoria) REFERENCES planilha_itens(id, evento_id, tipo_memoria) ON DELETE CASCADE,
  FOREIGN KEY (setor_id, evento_id) REFERENCES setores(id, evento_id)
);

-- 7.5 Gradil e tendas — medidas calculadas, nunca editáveis
--   Tendas M² = qtd × largura × comprimento (só Tenda)
--   Lonas M²  = qtd × largura × 2,70        (só Fechamento em lona)
--   Gradil ML = qtd × 2                     (só Gradil)
--   Valor total = medida calculada × unitário; Tenda e Balcão = qtd × unitário
--   (regra do valor total ainda a confirmar)
CREATE TYPE item_gradil_tenda   AS ENUM ('tenda', 'balcao', 'gradil', 'fechamento_lona');
CREATE TYPE estilo_gradil_tenda AS ENUM ('tubular', 'balcao', 'gradil', 'lona', 'calhada', 'arco', 'avance');

CREATE TABLE mem_gradil_tenda (
  id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  evento_id         BIGINT NOT NULL,
  planilha_item_id  BIGINT NOT NULL,
  tipo_memoria      tipo_memoria NOT NULL DEFAULT 'gradil_tenda' CHECK (tipo_memoria = 'gradil_tenda'),
  setor_id          BIGINT,
  item              item_gradil_tenda NOT NULL,
  posicionamento    TEXT,
  estilo            estilo_gradil_tenda,
  quantidade        NUMERIC NOT NULL DEFAULT 1 CHECK (quantidade >= 0),
  largura           NUMERIC(10,2) CHECK (largura >= 0),       -- metro linear
  comprimento       NUMERIC(10,2) CHECK (comprimento >= 0),   -- metro linear
  altura            NUMERIC(10,2) CHECK (altura >= 0),
  tendas_m2         NUMERIC(12,2) GENERATED ALWAYS AS (
                      CASE WHEN item = 'tenda' THEN quantidade * coalesce(largura,0) * coalesce(comprimento,0) END) STORED,
  lonas_m2          NUMERIC(12,2) GENERATED ALWAYS AS (
                      CASE WHEN item = 'fechamento_lona' THEN quantidade * coalesce(largura,0) * 2.70 END) STORED,
  gradil_ml         NUMERIC(12,2) GENERATED ALWAYS AS (
                      CASE WHEN item = 'gradil' THEN quantidade * 2 END) STORED,
  valor_unitario    NUMERIC(12,2) NOT NULL DEFAULT 0,
  valor_total       NUMERIC(14,2) GENERATED ALWAYS AS (
                      CASE item
                        WHEN 'fechamento_lona' THEN quantidade * coalesce(largura,0) * 2.70 * valor_unitario
                        WHEN 'gradil'          THEN quantidade * 2 * valor_unitario
                        ELSE quantidade * valor_unitario END) STORED,
  ordem             INT NOT NULL DEFAULT 0,
  FOREIGN KEY (planilha_item_id, evento_id, tipo_memoria) REFERENCES planilha_itens(id, evento_id, tipo_memoria) ON DELETE CASCADE,
  FOREIGN KEY (setor_id, evento_id) REFERENCES setores(id, evento_id)
);

-- 7.6 Banheiros químicos — total = quantidade + PNE
CREATE TABLE mem_banheiro (
  id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  evento_id         BIGINT NOT NULL,
  planilha_item_id  BIGINT NOT NULL,
  tipo_memoria      tipo_memoria NOT NULL DEFAULT 'banheiro' CHECK (tipo_memoria = 'banheiro'),
  setor_id          BIGINT,
  referencial       TEXT,
  local             TEXT,
  quantidade        INT NOT NULL DEFAULT 0 CHECK (quantidade >= 0),
  quantidade_pne    INT NOT NULL DEFAULT 0 CHECK (quantidade_pne >= 0),
  total             INT GENERATED ALWAYS AS (quantidade + quantidade_pne) STORED,
  ordem             INT NOT NULL DEFAULT 0,
  FOREIGN KEY (planilha_item_id, evento_id, tipo_memoria) REFERENCES planilha_itens(id, evento_id, tipo_memoria) ON DELETE CASCADE,
  FOREIGN KEY (setor_id, evento_id) REFERENCES setores(id, evento_id)
);

-- 7.7 Barricadas
CREATE TYPE peca_barricada AS ENUM ('reta', 'curva_direita', 'curva_esquerda');

CREATE TABLE mem_barricada (
  id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  evento_id         BIGINT NOT NULL,
  planilha_item_id  BIGINT NOT NULL,
  tipo_memoria      tipo_memoria NOT NULL DEFAULT 'barricada' CHECK (tipo_memoria = 'barricada'),
  setor_id          BIGINT,
  tipo_peca         peca_barricada NOT NULL,
  quantidade        INT NOT NULL DEFAULT 0 CHECK (quantidade >= 0),
  ordem             INT NOT NULL DEFAULT 0,
  FOREIGN KEY (planilha_item_id, evento_id, tipo_memoria) REFERENCES planilha_itens(id, evento_id, tipo_memoria) ON DELETE CASCADE,
  FOREIGN KEY (setor_id, evento_id) REFERENCES setores(id, evento_id)
);

-- 7.8 Painel de LED — metros totais = largura × altura
CREATE TABLE mem_painel_led (
  id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  evento_id         BIGINT NOT NULL,
  planilha_item_id  BIGINT NOT NULL,
  tipo_memoria      tipo_memoria NOT NULL DEFAULT 'painel_led' CHECK (tipo_memoria = 'painel_led'),
  setor_id          BIGINT,
  local             TEXT,
  descricao         TEXT,
  largura           NUMERIC(10,2) CHECK (largura >= 0),
  altura            NUMERIC(10,2) CHECK (altura >= 0),
  metros_totais     NUMERIC(12,2) GENERATED ALWAYS AS (coalesce(largura,0) * coalesce(altura,0)) STORED,
  ordem             INT NOT NULL DEFAULT 0,
  FOREIGN KEY (planilha_item_id, evento_id, tipo_memoria) REFERENCES planilha_itens(id, evento_id, tipo_memoria) ON DELETE CASCADE,
  FOREIGN KEY (setor_id, evento_id) REFERENCES setores(id, evento_id)
);

-- 7.9 Mesas e cadeiras
CREATE TYPE material_mesa AS ENUM ('madeira', 'plastico');

CREATE TABLE mem_mesas_cadeiras (
  id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  evento_id         BIGINT NOT NULL,
  planilha_item_id  BIGINT NOT NULL,
  tipo_memoria      tipo_memoria NOT NULL DEFAULT 'mesas_cadeiras' CHECK (tipo_memoria = 'mesas_cadeiras'),
  setor_id          BIGINT,
  local             TEXT,
  descricao         TEXT,
  mesas             INT NOT NULL DEFAULT 0 CHECK (mesas >= 0),
  cadeiras          INT NOT NULL DEFAULT 0 CHECK (cadeiras >= 0),
  tipo              material_mesa,
  ordem             INT NOT NULL DEFAULT 0,
  FOREIGN KEY (planilha_item_id, evento_id, tipo_memoria) REFERENCES planilha_itens(id, evento_id, tipo_memoria) ON DELETE CASCADE,
  FOREIGN KEY (setor_id, evento_id) REFERENCES setores(id, evento_id)
);

-- 7.10 Mobília
CREATE TABLE mem_mobilia (
  id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  evento_id         BIGINT NOT NULL,
  planilha_item_id  BIGINT NOT NULL,
  tipo_memoria      tipo_memoria NOT NULL DEFAULT 'mobilia' CHECK (tipo_memoria = 'mobilia'),
  setor_id          BIGINT,
  local             TEXT,
  item              TEXT NOT NULL,
  quantidade        INT NOT NULL DEFAULT 0 CHECK (quantidade >= 0),
  fornecedor_id     BIGINT REFERENCES fornecedores(id),
  ordem             INT NOT NULL DEFAULT 0,
  FOREIGN KEY (planilha_item_id, evento_id, tipo_memoria) REFERENCES planilha_itens(id, evento_id, tipo_memoria) ON DELETE CASCADE,
  FOREIGN KEY (setor_id, evento_id) REFERENCES setores(id, evento_id)
);

-- Resultado de cada memória por item da planilha (quantidade e valor).
-- Nas memórias com R$, o que manda é o valor; a quantidade é só referência.
CREATE VIEW v_memoria_resultado WITH (security_invoker = true) AS
SELECT planilha_item_id, sum(m2) AS quantidade, sum(valor_total) AS valor FROM mem_com_visual GROUP BY 1
UNION ALL SELECT planilha_item_id, sum(m2), sum(total) FROM mem_forracao GROUP BY 1
UNION ALL SELECT planilha_item_id, sum(quantidade), sum(total) FROM mem_cenografia GROUP BY 1
UNION ALL SELECT planilha_item_id, sum(area_m2), sum(valor) FROM mem_piso_fechamento GROUP BY 1          -- qtd = área (fechamento em ML fica na tela)
UNION ALL SELECT planilha_item_id, sum(tendas_m2), sum(valor_total) FROM mem_gradil_tenda GROUP BY 1       -- qtd = m² de tenda
UNION ALL SELECT planilha_item_id, sum(total), NULL FROM mem_banheiro GROUP BY 1
UNION ALL SELECT planilha_item_id, sum(quantidade), NULL FROM mem_barricada GROUP BY 1
UNION ALL SELECT planilha_item_id, sum(metros_totais), NULL FROM mem_painel_led GROUP BY 1
UNION ALL SELECT planilha_item_id, sum(mesas + cadeiras), NULL FROM mem_mesas_cadeiras GROUP BY 1
UNION ALL SELECT planilha_item_id, sum(quantidade), NULL FROM mem_mobilia GROUP BY 1;

-- A planilha como a tela mostra: quantidade e valor finais
--  • memória com R$  → valor vem da memória
--  • memória sem R$  → quantidade vem da memória, valor = qtd × freq × unitário
--  • sem memória     → tudo digitado
CREATE VIEW v_planilha WITH (security_invoker = true) AS
SELECT
  pi.*,
  c.nome  AS item_nome,
  cat.id  AS categoria_id,
  cat.nome AS categoria_nome,
  cat.ordem AS categoria_ordem,
  coalesce(mr.quantidade, pi.quantidade) AS quantidade_final,
  coalesce(mr.valor,
           coalesce(mr.quantidade, pi.quantidade) * pi.frequencia * pi.valor_unitario)::NUMERIC(14,2) AS valor_total
FROM planilha_itens pi
JOIN catalogo_itens c ON c.id = pi.catalogo_item_id
JOIN categorias cat   ON cat.id = c.categoria_id
LEFT JOIN v_memoria_resultado mr ON mr.planilha_item_id = pi.id
WHERE NOT pi.arquivado;

-- ---------------------------------------------------------------------
-- 8. CRONOGRAMA — por setor, dia relativo e período
-- ---------------------------------------------------------------------
-- Uma linha da grade: uma estrutura (item da planilha) num setor,
-- opcionalmente aberta numa linha da memória, ou uma atividade avulsa.
CREATE TABLE cronograma_linhas (
  id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  evento_id         BIGINT NOT NULL REFERENCES eventos(id) ON DELETE CASCADE,
  setor_id          BIGINT NOT NULL,
  planilha_item_id  BIGINT REFERENCES planilha_itens(id) ON DELETE CASCADE,
  memoria_tipo      tipo_memoria,                 -- quando a linha é o detalhe de uma memória
  memoria_id        BIGINT,
  linha_pai_id      BIGINT REFERENCES cronograma_linhas(id) ON DELETE CASCADE,
  titulo            TEXT,                         -- obrigatório em atividade avulsa
  ordem             INT NOT NULL DEFAULT 0,
  FOREIGN KEY (setor_id, evento_id) REFERENCES setores(id, evento_id) ON DELETE CASCADE,
  CHECK (planilha_item_id IS NOT NULL OR titulo IS NOT NULL),
  CHECK ((memoria_tipo IS NULL) = (memoria_id IS NULL))
);

CREATE TABLE cronograma_marcacoes (
  linha_id      BIGINT NOT NULL REFERENCES cronograma_linhas(id) ON DELETE CASCADE,
  dia_relativo  INT NOT NULL CHECK (dia_relativo BETWEEN -120 AND 60),   -- 0 = dia do evento
  periodo       periodo_dia NOT NULL,
  fase          fase_cronograma NOT NULL,
  PRIMARY KEY (linha_id, dia_relativo, periodo)
);

-- Só estruturas: bloqueia itens de categorias fora do cronograma (Staff…)
CREATE OR REPLACE FUNCTION fn_cronograma_so_estruturas() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.planilha_item_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM planilha_itens pi
    JOIN catalogo_itens c ON c.id = pi.catalogo_item_id
    JOIN categorias cat   ON cat.id = c.categoria_id
    WHERE pi.id = NEW.planilha_item_id AND NOT cat.entra_no_cronograma
  ) THEN
    RAISE EXCEPTION 'Este item não entra no cronograma (categoria de mão de obra)';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_cronograma_so_estruturas
  BEFORE INSERT OR UPDATE OF planilha_item_id ON cronograma_linhas
  FOR EACH ROW EXECUTE FUNCTION fn_cronograma_so_estruturas();

-- ---------------------------------------------------------------------
-- 9. CONFERÊNCIA EM CAMPO
-- ---------------------------------------------------------------------
CREATE TABLE conferencias (
  id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  evento_id         BIGINT NOT NULL REFERENCES eventos(id) ON DELETE CASCADE,
  planilha_item_id  BIGINT NOT NULL REFERENCES planilha_itens(id) ON DELETE CASCADE,
  fase              fase_cronograma NOT NULL,
  qtd_contratada    NUMERIC,                      -- foto do valor no momento
  qtd_recebida      NUMERIC,
  status            status_conferencia NOT NULL DEFAULT 'a_conferir',
  observacao        TEXT,
  conferido_por     UUID REFERENCES usuarios(id),
  conferido_em      TIMESTAMPTZ,
  UNIQUE (planilha_item_id, fase)
);

-- ---------------------------------------------------------------------
-- 10. DOCUMENTAÇÃO
-- ---------------------------------------------------------------------
CREATE TABLE tipos_documento (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  empresa_id  BIGINT NOT NULL REFERENCES empresas(id),
  nome        TEXT NOT NULL,                      -- CEMIG, AVCB, CODAU, Alvará…
  padrao      BOOLEAN NOT NULL DEFAULT true,      -- criado junto com o evento
  UNIQUE (empresa_id, nome)
);

CREATE TABLE documentos (
  id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  evento_id         BIGINT NOT NULL REFERENCES eventos(id) ON DELETE CASCADE,
  tipo_id           BIGINT NOT NULL REFERENCES tipos_documento(id),
  descricao         TEXT,
  protocolo         TEXT,
  status            status_documento NOT NULL DEFAULT 'pendente',
  data_solicitacao  DATE,
  prazo_dia_relativo INT,                         -- D-x (acompanha a data do evento)
  data_emissao      DATE,
  validade          DATE,
  vistoria_em       TIMESTAMPTZ,
  depende_de_id     BIGINT REFERENCES documentos(id),   -- ex.: Alvará depende do AVCB
  responsavel_id    UUID REFERENCES usuarios(id),
  atualizado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (evento_id, tipo_id)
);

-- ---------------------------------------------------------------------
-- 11. ARTÍSTICO
-- ---------------------------------------------------------------------
-- Tipos sugeridos no comentário da tela (a confirmar)
CREATE TYPE tipo_atracao AS ENUM ('artistico', 'staff', 'fornecedor', 'esportivo');

CREATE TABLE atracoes (
  id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  evento_id         BIGINT NOT NULL REFERENCES eventos(id) ON DELETE CASCADE,
  tipo              tipo_atracao NOT NULL DEFAULT 'artistico',
  nome              TEXT NOT NULL,
  contato_producao  TEXT,
  telefone_producao TEXT,
  passagem_som_em   TIMESTAMPTZ,
  show_em           TIMESTAMPTZ,
  duracao_min       INT CHECK (duracao_min > 0),
  ordem             INT NOT NULL DEFAULT 0
);

-- Cachê, alimentação etc. (valores; pagamento fica no sistema atual)
CREATE TABLE atracao_custos (
  id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  atracao_id    BIGINT NOT NULL REFERENCES atracoes(id) ON DELETE CASCADE,
  tipo          TEXT NOT NULL CHECK (tipo IN ('cache', 'alimentacao', 'outro')),
  descricao     TEXT,
  quantidade    NUMERIC NOT NULL DEFAULT 1,
  valor_unit    NUMERIC(12,2) NOT NULL DEFAULT 0,
  valor_total   NUMERIC(14,2) GENERATED ALWAYS AS (quantidade * valor_unit) STORED,
  pagamento_ref_externa TEXT
);

CREATE TABLE hospedagens (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  atracao_id  BIGINT NOT NULL REFERENCES atracoes(id) ON DELETE CASCADE,
  hotel_id    BIGINT NOT NULL REFERENCES hoteis(id),
  quem        TEXT,                               -- artista, equipe…
  checkin     DATE,
  checkout    DATE,
  observacao  TEXT,
  CHECK (checkout IS NULL OR checkin IS NULL OR checkout >= checkin)
);

CREATE TABLE roomlist (
  id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  hospedagem_id  BIGINT NOT NULL REFERENCES hospedagens(id) ON DELETE CASCADE,
  hospede        TEXT NOT NULL,
  funcao         TEXT,
  tipo_quarto    TEXT CHECK (tipo_quarto IN ('single', 'duplo', 'triplo', 'quadruplo')),
  numero_quarto  TEXT
);

CREATE TYPE tipo_veiculo AS ENUM ('carro', 'van', 'onibus', 'aviao');
CREATE TYPE trecho_transporte AS ENUM (
  'chegada_cidade', 'ida_passagem_som', 'volta_passagem_som',
  'ida_show', 'volta_show', 'saida_cidade'
);

CREATE TABLE transportes (
  id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  atracao_id       BIGINT NOT NULL REFERENCES atracoes(id) ON DELETE CASCADE,
  veiculo          tipo_veiculo NOT NULL,
  trecho           trecho_transporte NOT NULL,
  origem           TEXT,
  destino          TEXT,
  saida_em         TIMESTAMPTZ,
  chegada_em       TIMESTAMPTZ,
  passageiros      INT CHECK (passageiros >= 0),
  fornecedor_id    BIGINT REFERENCES fornecedores(id),
  motorista        TEXT,
  voo_localizador  TEXT
);

-- ---------------------------------------------------------------------
-- 12. ESTOQUE (da empresa, movimentado por evento)
-- ---------------------------------------------------------------------
CREATE TABLE estoque_itens (
  id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  empresa_id   BIGINT NOT NULL REFERENCES empresas(id),
  nome         TEXT NOT NULL,
  categoria    TEXT,
  unidade      TEXT NOT NULL DEFAULT 'UND',
  qtd_total    NUMERIC NOT NULL DEFAULT 0 CHECK (qtd_total >= 0),
  localizacao  TEXT
);

CREATE TABLE estoque_movimentos (
  id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  estoque_item_id  BIGINT NOT NULL REFERENCES estoque_itens(id),
  evento_id        BIGINT REFERENCES eventos(id),
  tipo             TEXT NOT NULL CHECK (tipo IN ('reserva', 'saida', 'retorno', 'manutencao', 'retorno_manutencao', 'perda')),
  quantidade       NUMERIC NOT NULL CHECK (quantidade > 0),
  data             DATE NOT NULL DEFAULT CURRENT_DATE,
  usuario_id       UUID REFERENCES usuarios(id),
  observacao       TEXT
);

-- ---------------------------------------------------------------------
-- 13. ANEXOS (arquivos no Supabase Storage)
-- Contratos, orçamentos, alvarás, fotos da conferência, riders…
-- ---------------------------------------------------------------------
CREATE TABLE anexos (
  id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  evento_id     BIGINT REFERENCES eventos(id) ON DELETE CASCADE,
  entidade      TEXT NOT NULL CHECK (entidade IN ('planilha_item', 'documento', 'conferencia', 'atracao', 'evento')),
  entidade_id   BIGINT NOT NULL,
  storage_path  TEXT NOT NULL,                    -- caminho no bucket
  nome_arquivo  TEXT NOT NULL,
  mime_type     TEXT,
  enviado_por   UUID REFERENCES usuarios(id),
  enviado_em    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- 14. HISTÓRICO (quem mudou o quê)
-- ---------------------------------------------------------------------
CREATE TABLE historico (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tabela      TEXT NOT NULL,
  registro_id TEXT NOT NULL,
  acao        TEXT NOT NULL CHECK (acao IN ('INSERT', 'UPDATE', 'DELETE')),
  antes       JSONB,
  depois      JSONB,
  usuario_id  UUID,
  em          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION fn_historico() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO historico (tabela, registro_id, acao, antes, depois, usuario_id)
  VALUES (TG_TABLE_NAME,
          coalesce((to_jsonb(NEW)->>'id'), (to_jsonb(OLD)->>'id'), ''),
          TG_OP,
          CASE WHEN TG_OP <> 'INSERT' THEN to_jsonb(OLD) END,
          CASE WHEN TG_OP <> 'DELETE' THEN to_jsonb(NEW) END,
          auth.uid());
  RETURN coalesce(NEW, OLD);
END $$;

CREATE TRIGGER trg_hist_eventos        AFTER INSERT OR UPDATE OR DELETE ON eventos        FOR EACH ROW EXECUTE FUNCTION fn_historico();
CREATE TRIGGER trg_hist_planilha_itens AFTER INSERT OR UPDATE OR DELETE ON planilha_itens FOR EACH ROW EXECUTE FUNCTION fn_historico();
CREATE TRIGGER trg_hist_documentos     AFTER INSERT OR UPDATE OR DELETE ON documentos     FOR EACH ROW EXECUTE FUNCTION fn_historico();
CREATE TRIGGER trg_hist_evento_modulos AFTER INSERT OR UPDATE OR DELETE ON evento_modulos FOR EACH ROW EXECUTE FUNCTION fn_historico();

-- Triggers de atualizado_em
CREATE TRIGGER trg_upd_usuarios       BEFORE UPDATE ON usuarios       FOR EACH ROW EXECUTE FUNCTION fn_set_atualizado_em();
CREATE TRIGGER trg_upd_fornecedores   BEFORE UPDATE ON fornecedores   FOR EACH ROW EXECUTE FUNCTION fn_set_atualizado_em();
CREATE TRIGGER trg_upd_eventos        BEFORE UPDATE ON eventos        FOR EACH ROW EXECUTE FUNCTION fn_set_atualizado_em();
CREATE TRIGGER trg_upd_planilha_itens BEFORE UPDATE ON planilha_itens FOR EACH ROW EXECUTE FUNCTION fn_set_atualizado_em();
CREATE TRIGGER trg_upd_documentos     BEFORE UPDATE ON documentos     FOR EACH ROW EXECUTE FUNCTION fn_set_atualizado_em();

-- ---------------------------------------------------------------------
-- 15. CRIAÇÃO DE EVENTO
-- Ao criar um evento: liga as telas fixas, cria os documentos padrão
-- e põe o criador na equipe. As telas do checklist são gravadas pelo app.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_evento_criado() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO evento_modulos (evento_id, modulo, ativo)
  SELECT NEW.id, codigo, true FROM modulos WHERE sempre_ativo;

  INSERT INTO documentos (evento_id, tipo_id)
  SELECT NEW.id, t.id FROM tipos_documento t
  WHERE t.empresa_id = NEW.empresa_id AND t.padrao;

  IF NEW.criado_por IS NOT NULL THEN
    INSERT INTO evento_equipe (evento_id, usuario_id, papel)
    SELECT NEW.id, u.id, u.papel FROM usuarios u WHERE u.id = NEW.criado_por
    ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_evento_criado AFTER INSERT ON eventos
  FOR EACH ROW EXECUTE FUNCTION fn_evento_criado();

-- ---------------------------------------------------------------------
-- 16. VISÕES PARA AS TELAS
-- ---------------------------------------------------------------------
-- Dimensionamento pelo público (Visão geral): sempre arredonda para cima
CREATE VIEW v_evento_dimensionamento WITH (security_invoker = true) AS
SELECT e.id AS evento_id, p.codigo, p.nome, p.unidade, p.pessoas_por_unidade, p.ordem,
       ceil(e.publico_estimado / p.pessoas_por_unidade)::INT AS necessario
FROM eventos e
JOIN parametros_dimensionamento p ON p.empresa_id = e.empresa_id
WHERE e.publico_estimado IS NOT NULL;

-- Grade do cronograma com a data real de cada marcação
CREATE VIEW v_cronograma WITH (security_invoker = true) AS
SELECT l.evento_id, s.id AS setor_id, s.nome AS setor, s.ordem AS setor_ordem,
       l.id AS linha_id, l.linha_pai_id, l.ordem AS linha_ordem,
       coalesce(l.titulo, c.nome) AS titulo, l.planilha_item_id,
       m.dia_relativo, (e.data_evento + m.dia_relativo) AS data, m.periodo, m.fase
FROM cronograma_linhas l
JOIN setores s ON s.id = l.setor_id
JOIN eventos e ON e.id = l.evento_id
LEFT JOIN planilha_itens pi ON pi.id = l.planilha_item_id
LEFT JOIN catalogo_itens c  ON c.id = pi.catalogo_item_id
LEFT JOIN cronograma_marcacoes m ON m.linha_id = l.id;

-- Marcos que aparecem no topo do cronograma (só leitura)
CREATE VIEW v_cronograma_marcos WITH (security_invoker = true) AS
SELECT d.evento_id, 'documento' AS tipo, t.nome AS titulo, d.prazo_dia_relativo AS dia_relativo, NULL::TIMESTAMPTZ AS horario
FROM documentos d JOIN tipos_documento t ON t.id = d.tipo_id
WHERE d.prazo_dia_relativo IS NOT NULL
UNION ALL
SELECT a.evento_id, 'passagem_som', a.nome, (a.passagem_som_em::DATE - e.data_evento), a.passagem_som_em
FROM atracoes a JOIN eventos e ON e.id = a.evento_id WHERE a.passagem_som_em IS NOT NULL
UNION ALL
SELECT a.evento_id, 'show', a.nome, (a.show_em::DATE - e.data_evento), a.show_em
FROM atracoes a JOIN eventos e ON e.id = a.evento_id WHERE a.show_em IS NOT NULL;

-- Saldo de estoque por situação
CREATE VIEW v_estoque_saldo WITH (security_invoker = true) AS
SELECT i.id, i.empresa_id, i.nome, i.unidade, i.qtd_total,
       coalesce(sum(m.quantidade) FILTER (WHERE m.tipo = 'reserva'), 0)  AS reservado,
       coalesce(sum(m.quantidade) FILTER (WHERE m.tipo = 'saida'), 0)
     - coalesce(sum(m.quantidade) FILTER (WHERE m.tipo = 'retorno'), 0) AS em_evento,
       coalesce(sum(m.quantidade) FILTER (WHERE m.tipo = 'manutencao'), 0)
     - coalesce(sum(m.quantidade) FILTER (WHERE m.tipo = 'retorno_manutencao'), 0) AS em_manutencao,
       coalesce(sum(m.quantidade) FILTER (WHERE m.tipo = 'perda'), 0)    AS perdido
FROM estoque_itens i LEFT JOIN estoque_movimentos m ON m.estoque_item_id = i.id
GROUP BY i.id;

-- ---------------------------------------------------------------------
-- 17. PERMISSÕES (Row Level Security)
-- Regra geral:
--   • gestor e planejamento veem e editam todos os eventos da empresa
--   • os demais veem e editam só os eventos em que estão na equipe
--   • ligar/desligar telas do checklist: só gestor e planejamento
--   • cadastros da empresa: todos leem; gestor e planejamento editam
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_minha_empresa() RETURNS BIGINT
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT empresa_id FROM usuarios WHERE id = auth.uid() AND ativo
$$;

CREATE OR REPLACE FUNCTION fn_sou_admin() RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND ativo AND papel IN ('gestor', 'planejamento'))
$$;

CREATE OR REPLACE FUNCTION fn_acesso_evento(p_evento BIGINT) RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM eventos e
    WHERE e.id = p_evento AND e.empresa_id = fn_minha_empresa()
      AND (fn_sou_admin() OR EXISTS (
            SELECT 1 FROM evento_equipe q WHERE q.evento_id = e.id AND q.usuario_id = auth.uid())))
$$;

-- Tabelas com evento_id direto: mesma política para todas
DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'evento_equipe', 'setores', 'planilha_itens',
    'mem_com_visual', 'mem_forracao', 'mem_cenografia', 'mem_piso_fechamento', 'mem_gradil_tenda',
    'mem_banheiro', 'mem_barricada', 'mem_painel_led', 'mem_mesas_cadeiras', 'mem_mobilia',
    'cronograma_linhas', 'conferencias', 'documentos', 'atracoes', 'anexos'
  ] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('CREATE POLICY acesso_evento ON %I FOR ALL USING (fn_acesso_evento(evento_id)) WITH CHECK (fn_acesso_evento(evento_id))', t);
  END LOOP;
END $$;

-- Eventos
ALTER TABLE eventos ENABLE ROW LEVEL SECURITY;
CREATE POLICY ler_evento    ON eventos FOR SELECT USING (fn_acesso_evento(id));
CREATE POLICY criar_evento  ON eventos FOR INSERT WITH CHECK (empresa_id = fn_minha_empresa() AND fn_sou_admin());
CREATE POLICY editar_evento ON eventos FOR UPDATE USING (fn_acesso_evento(id));
CREATE POLICY apagar_evento ON eventos FOR DELETE USING (empresa_id = fn_minha_empresa() AND fn_sou_admin());

-- Checklist de telas: todos da equipe leem, só gestor/planejamento mudam
ALTER TABLE evento_modulos ENABLE ROW LEVEL SECURITY;
CREATE POLICY ler_modulos   ON evento_modulos FOR SELECT USING (fn_acesso_evento(evento_id));
CREATE POLICY mudar_modulos ON evento_modulos FOR ALL USING (fn_acesso_evento(evento_id) AND fn_sou_admin())
                                                  WITH CHECK (fn_acesso_evento(evento_id) AND fn_sou_admin());

-- Tabelas filhas sem evento_id: via o pai
ALTER TABLE cronograma_marcacoes ENABLE ROW LEVEL SECURITY;
CREATE POLICY acesso ON cronograma_marcacoes FOR ALL
  USING (EXISTS (SELECT 1 FROM cronograma_linhas l WHERE l.id = linha_id AND fn_acesso_evento(l.evento_id)))
  WITH CHECK (EXISTS (SELECT 1 FROM cronograma_linhas l WHERE l.id = linha_id AND fn_acesso_evento(l.evento_id)));

DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['atracao_custos', 'hospedagens', 'transportes'] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('CREATE POLICY acesso ON %I FOR ALL
      USING (EXISTS (SELECT 1 FROM atracoes a WHERE a.id = atracao_id AND fn_acesso_evento(a.evento_id)))
      WITH CHECK (EXISTS (SELECT 1 FROM atracoes a WHERE a.id = atracao_id AND fn_acesso_evento(a.evento_id)))', t);
  END LOOP;
END $$;

ALTER TABLE roomlist ENABLE ROW LEVEL SECURITY;
CREATE POLICY acesso ON roomlist FOR ALL
  USING (EXISTS (SELECT 1 FROM hospedagens h JOIN atracoes a ON a.id = h.atracao_id
                 WHERE h.id = hospedagem_id AND fn_acesso_evento(a.evento_id)))
  WITH CHECK (EXISTS (SELECT 1 FROM hospedagens h JOIN atracoes a ON a.id = h.atracao_id
                 WHERE h.id = hospedagem_id AND fn_acesso_evento(a.evento_id)));

-- Cadastros da empresa: todos leem, gestor/planejamento editam
DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'fornecedores', 'hoteis', 'categorias', 'catalogo_itens', 'tipos_documento',
    'modelos_evento', 'parametros_dimensionamento', 'frases_do_dia', 'estoque_itens'
  ] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('CREATE POLICY ler ON %I FOR SELECT USING (empresa_id = fn_minha_empresa())', t);
    EXECUTE format('CREATE POLICY editar ON %I FOR ALL USING (empresa_id = fn_minha_empresa() AND fn_sou_admin())
                                                    WITH CHECK (empresa_id = fn_minha_empresa() AND fn_sou_admin())', t);
  END LOOP;
END $$;

-- Estoque: movimentar é para qualquer usuário da empresa
ALTER TABLE estoque_movimentos ENABLE ROW LEVEL SECURITY;
CREATE POLICY acesso ON estoque_movimentos FOR ALL
  USING (EXISTS (SELECT 1 FROM estoque_itens i WHERE i.id = estoque_item_id AND i.empresa_id = fn_minha_empresa()))
  WITH CHECK (EXISTS (SELECT 1 FROM estoque_itens i WHERE i.id = estoque_item_id AND i.empresa_id = fn_minha_empresa()));

ALTER TABLE modelo_modulos ENABLE ROW LEVEL SECURITY;
CREATE POLICY acesso ON modelo_modulos FOR ALL
  USING (EXISTS (SELECT 1 FROM modelos_evento m WHERE m.id = modelo_id AND m.empresa_id = fn_minha_empresa()))
  WITH CHECK (fn_sou_admin());

-- Usuários: cada um vê os colegas da empresa; só admin cadastra
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
CREATE POLICY ler    ON usuarios FOR SELECT USING (empresa_id = fn_minha_empresa());
CREATE POLICY editar ON usuarios FOR ALL USING (empresa_id = fn_minha_empresa() AND fn_sou_admin())
                                       WITH CHECK (empresa_id = fn_minha_empresa() AND fn_sou_admin());

-- Integrações: só o próprio usuário
ALTER TABLE usuario_integracoes ENABLE ROW LEVEL SECURITY;
CREATE POLICY proprio ON usuario_integracoes FOR ALL USING (usuario_id = auth.uid()) WITH CHECK (usuario_id = auth.uid());

-- Histórico: só leitura, só admin
ALTER TABLE historico ENABLE ROW LEVEL SECURITY;
CREATE POLICY ler ON historico FOR SELECT USING (fn_sou_admin());

-- Tabelas de referência fixas: leitura para qualquer logado
ALTER TABLE modulos ENABLE ROW LEVEL SECURITY;
CREATE POLICY ler ON modulos FOR SELECT USING (auth.uid() IS NOT NULL);
ALTER TABLE empresas ENABLE ROW LEVEL SECURITY;
CREATE POLICY ler ON empresas FOR SELECT USING (id = fn_minha_empresa());

-- ---------------------------------------------------------------------
-- 18. ÍNDICES
-- ---------------------------------------------------------------------
CREATE INDEX ON eventos (empresa_id, data_evento);
CREATE INDEX ON evento_equipe (usuario_id);
CREATE INDEX ON planilha_itens (evento_id);
CREATE INDEX ON setores (evento_id, ordem);
CREATE INDEX ON mem_com_visual (planilha_item_id);
CREATE INDEX ON mem_forracao (planilha_item_id);
CREATE INDEX ON mem_cenografia (planilha_item_id);
CREATE INDEX ON mem_piso_fechamento (planilha_item_id);
CREATE INDEX ON mem_gradil_tenda (planilha_item_id);
CREATE INDEX ON mem_banheiro (planilha_item_id);
CREATE INDEX ON mem_barricada (planilha_item_id);
CREATE INDEX ON mem_painel_led (planilha_item_id);
CREATE INDEX ON mem_mesas_cadeiras (planilha_item_id);
CREATE INDEX ON mem_mobilia (planilha_item_id);
CREATE INDEX ON cronograma_linhas (evento_id, setor_id, ordem);
CREATE INDEX ON documentos (evento_id);
CREATE INDEX ON atracoes (evento_id);
CREATE INDEX ON anexos (entidade, entidade_id);
CREATE INDEX ON estoque_movimentos (estoque_item_id);
CREATE INDEX ON historico (tabela, registro_id);
