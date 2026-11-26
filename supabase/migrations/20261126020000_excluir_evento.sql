-- =====================================================================
-- Backstage · migration 3 (26/11/2026)
-- Excluir evento apaga TUDO o que pertence a ele. Dois ajustes:
--
-- 1. Memórias × setor: a ligação (setor_id, evento_id) → setores não tinha
--    regra de exclusão e BARRAVA excluir um evento com linhas de memória
--    ligadas a setor. Agora, se um setor some, a linha da memória fica sem
--    setor (ON DELETE SET NULL só em setor_id). Isso libera a exclusão do
--    evento e evita perder linhas quando alguém apaga só um setor.
--    (Precisa de PostgreSQL 15+; o Supabase usa 15/17.)
--
-- 2. Estoque: estoque_movimentos.evento_id não apagava em cascata, então
--    um evento com reserva/saída de estoque não podia ser excluído. Agora os
--    movimentos do evento vão junto (o saldo volta como se o evento não
--    tivesse existido). O item do estoque continua cadastrado.
--
-- O histórico (tabela historico) continua guardado: é o registro de auditoria.
-- =====================================================================

DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'mem_com_visual', 'mem_forracao', 'mem_cenografia', 'mem_piso_fechamento', 'mem_gradil_tenda',
    'mem_banheiro', 'mem_barricada', 'mem_painel_led', 'mem_mesas_cadeiras', 'mem_mobilia'
  ] LOOP
    EXECUTE format('ALTER TABLE %I DROP CONSTRAINT %I', t, t || '_setor_id_evento_id_fkey');
    EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I FOREIGN KEY (setor_id, evento_id)
                    REFERENCES setores(id, evento_id) ON DELETE SET NULL (setor_id)', t, t || '_setor_id_evento_id_fkey');
  END LOOP;
END $$;

ALTER TABLE estoque_movimentos DROP CONSTRAINT estoque_movimentos_evento_id_fkey;
ALTER TABLE estoque_movimentos
  ADD CONSTRAINT estoque_movimentos_evento_id_fkey
  FOREIGN KEY (evento_id) REFERENCES eventos(id) ON DELETE CASCADE;
