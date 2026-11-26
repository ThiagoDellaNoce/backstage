SET ROLE authenticated; SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
\echo '--- deve falhar: fechamento com área'
INSERT INTO mem_piso_fechamento (evento_id, planilha_item_id, item, area_m2) VALUES (1,1,'fechamento',10);
\echo '--- deve falhar: linha de piso num item de gradil'
INSERT INTO mem_piso_fechamento (evento_id, planilha_item_id, item, area_m2) VALUES (1,2,'piso',10);
\echo '--- deve falhar: staff no cronograma'
INSERT INTO cronograma_linhas (evento_id, setor_id, planilha_item_id) SELECT 1,1,id FROM planilha_itens WHERE catalogo_item_id=(SELECT id FROM catalogo_itens WHERE nome='Seguranças');
\echo '--- deve falhar: editar tendas_m2'
UPDATE mem_gradil_tenda SET tendas_m2=1;
\echo '--- freelance da equipe vê o evento; tentar mudar checklist (deve dar 0 linhas)'
SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000002';
SELECT count(*) AS eventos_visiveis FROM eventos;
UPDATE evento_modulos SET ativo=false WHERE modulo='cronograma';
\echo '--- freelance fora da equipe não vê nada'
SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000003';
SELECT count(*) AS eventos_visiveis, (SELECT count(*) FROM planilha_itens) AS itens FROM eventos;
RESET ROLE;
SELECT tabela, acao, count(*) FROM historico GROUP BY 1,2 ORDER BY 1,2;
