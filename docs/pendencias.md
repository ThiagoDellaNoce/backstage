# Pendências e decisões em aberto

| # | Tema | Decisão necessária | Onde |
|---|---|---|---|
| 1 | Artístico | Confirmar os tipos de atração: artístico, staff, fornecedor, esportivo. | Artístico · banco (tipo_atracao) |
| 2 | Cenografia | Confirmar se o “Preço Duzão” da planilha v3 é o teto orçamentário. | Memória Cenografia |
| 3 | Gradil e tendas | Confirmar a regra do valor total (Tenda e Balcão = qtd × unitário; Lona = M² × unitário; Gradil = ML × unitário). | Memória Gradil e tendas |
| 4 | Quantidade que sobe | Piso: só a área; Gradil e tendas: só m² de tenda; Mesas e cadeiras: mesas + cadeiras somadas. Confirmar. | Planilha · v_memoria_resultado |
| 5 | Checklist de telas | Confirmar que só gestor e planejamento ligam e desligam telas do evento. | Novo evento · Editar evento |
| 6 | Pagamentos nas telas | Remover ou ligar ao sistema atual: Painel (indicador, coluna, selos, tabela), Eventos (Pago, alertas), Visão geral (Pago, Saldo), Planilha (coluna, parcelas), Detalhe do item (parcelas), Artístico (status), Cadastros (Em aberto). | Várias telas |
| 7 | Catálogo | Trocar os modelos de memória antigos (piso, tenda, box, elétrica) pelos 10 tipos da v0.3; Pisos e Fechamentos viraram um item. | Adicionar itens · Novo item · Piso |
| 8 | Setor nas memórias | Banheiros e Barricadas usam setor em texto; deve virar a lista dos setores do evento em todas as memórias. | Memórias |
| 9 | Permissões | Decidir: equipe gerenciada só por administradores; apagar só por administradores; trava no apagar dos modelos; estoque só para a equipe; usuário editar o próprio perfil; perfis por função. | Banco (RLS) |
| 10 | Botões de cadastro | Esconder “+ Cadastrar fornecedor” e “Cadastrar novo item” de quem não é administrador, ou liberar no banco. | Detalhe do item · Mobília · Catálogo |
| 11 | Estoque | Definir se a saída baixa a reserva. | Estoque · v_estoque_saldo |
| 12 | Eventos | ✅ Feito (26/11/2026): filtro de status com todos os 6 status. | Eventos |
| 13 | Login | ✅ Decidido (26/11/2026): só Google (conta exp.rec.br). E-mail e senha removidos. | Login |
| 14 | Telas a desenhar | Editar evento, Conectar Asana, Cadastros (catálogo, hotéis, usuários), Configurações, Histórico, Mão de obra, versão celular. | Protótipo |
