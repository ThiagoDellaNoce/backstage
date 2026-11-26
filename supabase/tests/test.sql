\set ON_ERROR_STOP 1
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public, auth TO authenticated;
INSERT INTO auth.users VALUES ('00000000-0000-0000-0000-000000000001','della@exp'),('00000000-0000-0000-0000-000000000002','free@exp'),('00000000-0000-0000-0000-000000000003','free2@exp');
INSERT INTO usuarios (id, empresa_id, nome, email, papel) SELECT u.id, 1, u.email, u.email, p::papel_usuario FROM auth.users u
  JOIN (VALUES ('della@exp','planejamento'),('free@exp','freelance'),('free2@exp','freelance')) v(e,p) ON v.e=u.email;
SELECT count(*) AS catalogo FROM catalogo_itens;

-- Della (planejamento) cria evento
SET ROLE authenticated; SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
INSERT INTO eventos (empresa_id, nome, data_evento, publico_estimado, criado_por) VALUES (1,'Evento A','2026-12-12',3000,'00000000-0000-0000-0000-000000000001');
SELECT modulo, ativo FROM evento_modulos ORDER BY 1;
SELECT count(*) AS docs_criados FROM documentos;
INSERT INTO evento_modulos (evento_id, modulo) VALUES (1,'piso_fechamento'),(1,'gradil_tenda'),(1,'cronograma');
INSERT INTO evento_equipe VALUES (1,'00000000-0000-0000-0000-000000000002','freelance');
INSERT INTO setores (evento_id,nome,ordem) VALUES (1,'Portaria',1),(1,'Palco',2);
INSERT INTO planilha_itens (evento_id, catalogo_item_id) SELECT 1, id FROM catalogo_itens WHERE nome='Piso e fechamentos';
INSERT INTO planilha_itens (evento_id, catalogo_item_id) SELECT 1, id FROM catalogo_itens WHERE nome='Gradil e tendas';
INSERT INTO planilha_itens (evento_id, catalogo_item_id) SELECT 1, id FROM catalogo_itens WHERE nome='Gerador';
INSERT INTO planilha_itens (evento_id, catalogo_item_id) SELECT 1, id FROM catalogo_itens WHERE nome='Seguranças';
INSERT INTO planilha_itens (evento_id, catalogo_item_id) SELECT 1, id FROM catalogo_itens WHERE nome='Banheiros químicos';
UPDATE planilha_itens SET quantidade=1, frequencia=2, valor_unitario=1500 WHERE catalogo_item_id=(SELECT id FROM catalogo_itens WHERE nome='Gerador');
SELECT id, tipo_memoria, unidade FROM planilha_itens ORDER BY id;

INSERT INTO mem_piso_fechamento (evento_id, planilha_item_id, setor_id, item, quantidade, largura, comprimento, area_m2, valor_unitario)
  VALUES (1,1,2,'piso',1,20,15,300,45);
INSERT INTO mem_piso_fechamento (evento_id, planilha_item_id, setor_id, item, quantidade, metragem_linear, valor_unitario)
  VALUES (1,1,2,'fechamento',20,40,80);
INSERT INTO mem_gradil_tenda (evento_id, planilha_item_id, setor_id, item, estilo, quantidade, largura, comprimento, valor_unitario) VALUES
  (1,2,1,'tenda','calhada',3,10,10,800),(1,2,1,'fechamento_lona','lona',4,10,NULL,20),(1,2,1,'gradil','gradil',80,NULL,NULL,15);
SELECT item, tendas_m2, lonas_m2, gradil_ml, valor_total FROM mem_gradil_tenda;
INSERT INTO mem_banheiro (evento_id, planilha_item_id, quantidade, quantidade_pne) VALUES (1,5,35,5);
UPDATE planilha_itens SET valor_unitario=300 WHERE id=5;
SELECT item_nome, categoria_nome, quantidade_final, valor_total FROM v_planilha ORDER BY id;
SELECT nome, necessario FROM v_evento_dimensionamento ORDER BY ordem;

-- Cronograma
INSERT INTO cronograma_linhas (evento_id, setor_id, planilha_item_id) VALUES (1,2,1);
INSERT INTO cronograma_marcacoes VALUES (1,-4,'manha','montagem'),(1,0,'noite','operacao');
SELECT setor, titulo, data, periodo, fase FROM v_cronograma;
