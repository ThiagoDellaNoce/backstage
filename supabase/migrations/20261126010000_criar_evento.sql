-- =====================================================================
-- Backstage · migration 2 (26/11/2026)
-- 1. Documentos padrão só nascem quando a tela Documentação está ligada
--    (antes nasciam com todo evento, mesmo sem Documentação).
-- 2. fn_criar_evento: cria evento + checklist de telas + equipe numa
--    única transação (usada pela tela Novo evento).
-- =====================================================================

-- 1a. O gatilho de criação do evento deixa de criar documentos
CREATE OR REPLACE FUNCTION fn_evento_criado() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO evento_modulos (evento_id, modulo, ativo)
  SELECT NEW.id, codigo, true FROM modulos WHERE sempre_ativo;

  IF NEW.criado_por IS NOT NULL THEN
    INSERT INTO evento_equipe (evento_id, usuario_id, papel)
    SELECT NEW.id, u.id, u.papel FROM usuarios u WHERE u.id = NEW.criado_por
    ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END $$;

-- 1b. Ligou a Documentação (na criação ou depois): cria os documentos padrão
--     que ainda não existem. Desligar não apaga nada.
CREATE OR REPLACE FUNCTION fn_documentacao_ligada() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO documentos (evento_id, tipo_id)
  SELECT NEW.evento_id, t.id
  FROM eventos e JOIN tipos_documento t ON t.empresa_id = e.empresa_id AND t.padrao
  WHERE e.id = NEW.evento_id
  ON CONFLICT (evento_id, tipo_id) DO NOTHING;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_documentacao_ligada
  AFTER INSERT OR UPDATE OF ativo ON evento_modulos
  FOR EACH ROW WHEN (NEW.modulo = 'documentacao' AND NEW.ativo)
  EXECUTE FUNCTION fn_documentacao_ligada();

-- 2. Criar evento completo. SECURITY DEFINER porque o RLS de leitura não
--    deixa o RETURNING ver o evento recém-criado; as regras são checadas aqui:
--    só administrador, sempre na própria empresa, equipe só da própria empresa.
--    p_evento:  {"nome", "contratante", "local", "cidade", "data_evento",
--                "data_fim", "publico_estimado"}
--    p_modulos: códigos das telas marcadas no checklist
--    p_equipe:  [{"usuario_id": "...", "papel": "arquiteto"}, …]
CREATE OR REPLACE FUNCTION fn_criar_evento(p_evento JSONB, p_modulos TEXT[], p_equipe JSONB DEFAULT '[]')
RETURNS BIGINT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_id BIGINT;
BEGIN
  IF NOT fn_sou_admin() THEN
    RAISE EXCEPTION 'Só gestor e planejamento podem criar eventos.' USING ERRCODE = '42501';
  END IF;

  INSERT INTO eventos (empresa_id, nome, contratante, local, cidade, data_evento, data_fim, publico_estimado, criado_por)
  VALUES (
    fn_minha_empresa(),
    nullif(trim(p_evento->>'nome'), ''),
    nullif(trim(p_evento->>'contratante'), ''),
    nullif(trim(p_evento->>'local'), ''),
    nullif(trim(p_evento->>'cidade'), ''),
    (p_evento->>'data_evento')::DATE,
    nullif(p_evento->>'data_fim', '')::DATE,
    nullif(p_evento->>'publico_estimado', '')::INT,
    auth.uid()
  )
  RETURNING id INTO v_id;

  -- Checklist: grava todas as telas opcionais disponíveis, ligadas ou não
  INSERT INTO evento_modulos (evento_id, modulo, ativo, alterado_por)
  SELECT v_id, m.codigo, m.codigo = ANY (coalesce(p_modulos, '{}')), auth.uid()
  FROM modulos m
  WHERE NOT m.sempre_ativo AND m.disponivel;

  -- Equipe (quem criou já entrou pelo gatilho)
  INSERT INTO evento_equipe (evento_id, usuario_id, papel)
  SELECT v_id, u.id, coalesce((x->>'papel')::papel_usuario, u.papel)
  FROM jsonb_array_elements(coalesce(p_equipe, '[]')) x
  JOIN usuarios u ON u.id = (x->>'usuario_id')::UUID
  WHERE u.empresa_id = fn_minha_empresa() AND u.ativo
  ON CONFLICT DO NOTHING;

  RETURN v_id;
END $$;

REVOKE ALL ON FUNCTION fn_criar_evento(JSONB, TEXT[], JSONB) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION fn_criar_evento(JSONB, TEXT[], JSONB) TO authenticated;
