# Telas — especificação

Referência visual: `prototipo/<arquivo>.html`. Textos entre colchetes ([Evento A], [R$]) são exemplos.

**Carregando (todas as telas internas):** enquanto os dados chegam, a tela mostra um *skeleton screen* — blocos cinza
pulsando no formato da tela (menu, cabeçalho, indicadores, tabelas/cartões), em vez de “Carregando…”.

## 1. Login
Arquivo do protótipo: `prototipo/index.html`

**Objetivo:** Entrada no Backstage com a conta da EXP e escolha do tema visual.

**Como chegar:** Endereço do sistema (primeira tela).

**Blocos:**
- **Entrar com Google:** único caminho de login (decidido em 26/11/2026), com a conta Google da EXP pelo Supabase Auth.
- **Links:** nenhum na versão real (“Esqueci minha senha” saiu junto com o login por senha; o mapa do banco é só do protótipo).
- **Tema:** Seletor Roxo / Verde. A escolha vale para todas as telas e fica salva no navegador.

**Regras:**
- Só entra quem está cadastrado em usuarios e com ativo = verdadeiro.
- O papel padrão do usuário (gestor, planejamento, …) define o que ele vê a partir daqui.

**Dados:** `auth.users, usuarios`

**Quem pode:** Qualquer pessoa cadastrada.

**Pendências:**
- Nenhuma.

## 2. Painel
Arquivo do protótipo: `prototipo/Main.html`

**Objetivo:** Resumo do dia da pessoa: tarefas, eventos que se aproximam e o que pede atenção.

**Como chegar:** Depois do login, ou menu lateral → Painel.

**Blocos:**
- **Saudação e frase do dia:** “[Usuário] · [dia da semana, data]”, frase sorteada da lista de frases da empresa e botão “+ Novo evento”.
  Gestor e planejamento veem “✎ Frases do dia”, que abre uma janela para incluir, editar, ligar/desligar (sai do sorteio sem apagar) e apagar frases; grava na hora.
- **Indicadores:** Eventos ativos · Eventos esta semana (seg a dom, com os nomes) · Pontos de atenção (total, quantos atrasados/indeferidos; clica e desce até a lista).
- **Minhas tarefas no Asana:** Três cartões: Tarefas para hoje (com quantas já concluídas), Tarefas atrasadas (a mais antiga há N dias) e Na sua fila (em aberto atribuídas à pessoa). Mostra “Sincronizado há N min” e o botão “Abrir no Asana”.
- **Próximos eventos:** Tabela Evento · Data · Faltam (D-x) · Status · Pagamento · “Entrar no evento →”.
- **Pontos de atenção:** Selos coloridos: Atrasado, Vence em 5d, Sem NF, Hoje, cada um com o item e o evento.
- **Pagamentos da semana:** Tabela Vencimento · Evento · Item · Fornecedor · Parcela · Valor · Status.
- **Menu lateral:** Painel, Eventos, Empresa (Estoque, Cadastros), Projeto (Mapa do banco), indicador “Asana conectado”, seletor de tema e Sair.

**Regras:**
- A lista mostra só os eventos que a pessoa pode ver (equipe) ou todos, para gestor/planejamento.
- As tarefas vêm do Asana por uma função no servidor; o token nunca chega ao navegador.
- “+ Novo evento” e “✎ Frases do dia” só aparecem para gestor e planejamento.
- Pontos de atenção de documentos só contam eventos com a tela Documentação ligada.

**Dados:** `eventos, frases_do_dia, usuario_integracoes, documentos, evento_modulos, v_cronograma`

**Quem pode:** Todos os usuários.

**Pendências:**
- “Pagamentos nos próximos 7 dias”, a coluna Pagamento, os selos Atrasado e Sem NF e a tabela “Pagamentos da semana” dependem do módulo de pagamentos, que está pausado: remover ou ligar ao sistema atual.

## 3. Eventos
Arquivo do protótipo: `prototipo/Eventos.html`

**Objetivo:** Encontrar e abrir os eventos.

**Como chegar:** Menu lateral → Eventos.

**Blocos:**
- **Topo:** Título e botão “+ Novo evento”.
- **Filtros:** Busca por texto, status (Todos, Planejamento, Montagem, Operação, Encerrado) e período (Próximos, Este mês, Passados).
- **Cartões de evento:** Nome, selo de status, data · local, cidade · D-x e alertas de documentos (pendentes, atrasados, indeferidos, Docs em dia).
  Gestor e planejamento veem “🗑 Excluir” no cartão (mesma confirmação da Visão geral).

**Regras:**
- Cada pessoa vê só os eventos em que está na equipe; gestor e planejamento veem todos.
- D-x é calculado a partir da data do evento (dia 0); depois do evento vira D+x.

**Dados:** `eventos, documentos`

**Quem pode:** Todos (cada um vê os seus eventos).

**Pendências:**
- Nenhuma (filtro com os 6 status feito; pagamentos fora do MVP).

## 4. Evento · Visão geral
Arquivo do protótipo: `prototipo/EventoGeral.html`

**Objetivo:** Ficha do evento: números principais, dados, dimensionamento e equipe.

**Como chegar:** Eventos → cartão do evento, ou Painel → “Entrar no evento”.

**Blocos:**
- **Cabeçalho:** Caminho, nome, data · local, cidade · D-x, lista de Status (Planejamento, Montagem, Operação, Desmontagem, Encerrado, Cancelado) e “Editar evento”.
- **Abas do evento:** Visão geral, Planilha de trabalho, Cronograma, Artístico, Documentação e Pagamentos (em breve). O submenu lateral repete as abas.
- **Indicadores:** Orçado (planilha), Pago, Itens contratados (18 / 42) e Documentos aprovados (2 / 4).
- **Dados do evento:** Local, Cidade, Data (início a fim), Público estimado e Produtor (cliente / contratante).
- **Dimensionamento pelo público:** Baias de entrada (1 a cada 250 pessoas), Banheiros (1/80), Seguranças (1/100) e Metragem de bar (1 m/100). Exemplo com 3.000 pessoas: 12 baias, 38 banheiros, 30 seguranças, 30 m de bar.
- **Equipe:** “+ Adicionar” e tabela Nome · Função no evento.
- **Orçamento por categoria:** Categoria · Itens · Orçado · Pago · Saldo.
- **Próximos 3 dias:** Linha do tempo curta com o que acontece em D-x (montagens, vistorias).

**Regras:**
- As abas aparecem conforme o checklist de telas do evento.
- Dimensionamento = público ÷ pessoas por unidade, sempre arredondado para cima; as regras são editáveis pela empresa.

**Dados:** `eventos, evento_modulos, parametros_dimensionamento (v_evento_dimensionamento), evento_equipe, v_planilha, documentos`

**Quem pode:** Equipe do evento e gestor/planejamento. Membros podem mudar status e dados.

**Na versão real (26/11/2026):**
- Sem Pago e Saldo (pagamentos fora do MVP). “Documentos aprovados” só aparece com a Documentação ligada.
- “Próximos 3 dias” = hoje até hoje+2: cronograma por fase + marcos (prazos de documento, passagem de som, show).
- “+ Adicionar” e “×” da equipe só para gestor/planejamento, até a pendência 9 (permissões) ser decidida; o banco ainda deixa membros.
- “Editar evento” aparece desabilitado até a tela ser desenhada.
- **Excluir** (só gestor e planejamento): janela que lista o que será apagado (itens da planilha, documentos, cronograma,
  setores, atrações, conferências, anexos, movimentos de estoque, equipe) e pede para digitar o nome do evento.
  Apaga tudo do evento; o histórico de alterações é mantido. Não dá para desfazer.

**Pendências:**
- Tela Editar evento (dados + checklist de telas).

## 5. Evento · Planilha de trabalho
Arquivo do protótipo: `prototipo/Planilha.html`

**Objetivo:** O coração do evento: tudo o que será contratado, com quantidades, valores e status.

**Como chegar:** Evento → aba Planilha de trabalho.

**Blocos:**
- **Ações:** “Conferência”, “Exportar p/ Sheets” e “+ Item do catálogo”.
- **Filtros:** Categorias (Todas, Estrutura geral, Estrutura eventual, Estrutura bar, Técnica, Cenografia, Maquinário/Serviços, Staff, Extras) e status de contrato.
- **Tabela:** Agrupada por categoria com subtotal: Item · Descritivo · Fornecedor · Qtd · Freq. · Und · V. unit. · V. total · Contrato · Produção · Pagamento · Resp. Itens com memória têm ▸ para abrir o detalhe. Termina com o TOTAL DO EVENTO.
- **Detalhe aberto:** Ao abrir um item com memória (ex.: Tendas), mostra as linhas da memória e o total, com “Editar memória”.
- **Submenu lateral:** Lista as 10 memórias de cálculo ligadas ao evento.

**Regras:**
- Item com memória: quantidade e valor vêm da memória e não se editam na planilha.
- Item sem memória: V. total = quantidade × frequência × valor unitário.
- Status de contrato e de produção: pendente, em andamento, concluído, cancelado.

**Dados:** `planilha_itens, catalogo_itens, categorias, fornecedores, usuarios, v_planilha, v_memoria_resultado`

**Quem pode:** Equipe do evento e gestor/planejamento.

**Pendências:**
- Coluna Pagamento e “Ver parcelas” dependem de pagamentos.
- O exemplo de memória de Tendas usa o desenho antigo (Tipo, Estilo Piramidal): atualizar para Gradil e tendas.

## 6. Adicionar itens do catálogo
Arquivo do protótipo: `prototipo/ItemCatalogo.html`

**Objetivo:** Escolher de uma vez os itens que o evento vai contratar.

**Como chegar:** Planilha → “+ Item do catálogo”.

**Blocos:**
- **Topo:** “← Planilha”, evento, busca e explicação: fornecedor e valores se preenchem depois.
- **Filtros e atalho:** Categorias e “+ Usar modelo de outro evento”.
- **Lista por categoria:** Cada categoria mostra quantos itens estão selecionados. Cada item: nome, unidade e memória (ex.: “M² · memória: piso”), com selo “Já na planilha” (travado) ou “Calcula”.
- **Rodapé fixo:** “N itens selecionados”, Cancelar e “Adicionar N”. Link “Não achou? Cadastrar novo item no catálogo”.

**Regras:**
- Itens que já estão na planilha aparecem marcados e travados.
- Ao adicionar, cada item copia do catálogo o tipo de memória e a unidade (gatilho no banco).

**Dados:** `catalogo_itens, categorias, planilha_itens`

**Quem pode:** Equipe do evento e gestor/planejamento.

**Pendências:**
- Os nomes de memória na tela (piso, tenda, box, elétrica) são do desenho antigo: os modelos da v0.3 são os 10 tipos; “box” e “elétrica” não existem.
- “Cadastrar novo item no catálogo” só funciona para gestor/planejamento.

## 7. Novo item no catálogo
Arquivo do protótipo: `prototipo/NovoItem.html`

**Objetivo:** Criar um item que fica disponível para todos os eventos da EXP.

**Como chegar:** Adicionar itens do catálogo → “Cadastrar novo item”, ou Cadastros → Catálogo.

**Blocos:**
- **Campos:** Nome do item, Categoria (8 opções), Unidade padrão (UND, M², ML, PCT, Diária).
- **Como a quantidade é definida?:** “Digitada direto” (ex.: 1 gerador, 40 seguranças) ou “Calculada por memória de cálculo”.
- **Modelo de memória:** Lista que só se habilita quando a quantidade é calculada.
- **Ações:** Cancelar e Salvar item.

**Regras:**
- Nome não pode repetir dentro da mesma categoria.

**Dados:** `catalogo_itens, categorias`

**Quem pode:** Só gestor e planejamento.

**Pendências:**
- A lista de modelos de memória deve mostrar os 10 tipos da v0.3.

## 8. Detalhe do item
Arquivo do protótipo: `prototipo/ItemDetalhe.html`

**Objetivo:** Tudo sobre um item contratado: contratação, valores, memória, cronograma e anexos.

**Como chegar:** Planilha → clicar no item.

**Blocos:**
- **Topo:** “← Planilha”, evento · categoria, nome do item e “Remover item”.
- **Status:** Contrato (Concluído, Pendente, Em andamento, Cancelado), Produção (Pendente, Em andamento, Concluído) e Pagamento (vem das parcelas).
- **Contratação:** Descritivo da contratação, Fornecedor (com “+ Cadastrar fornecedor”), Responsável e Observação.
- **Quantidade e valor:** Quantidade (travada: “calculada pela memória”), Unidade, Frequência (diárias), Valor unitário e a conta “450 × 1 × R$ = total”.
- **Memória de cálculo:** Resumo das linhas (ex.: Entrada principal · 3 × 10×10 = 300 m²) com “Editar”.
- **Parcelas:** “+ Parcela”, lista com condição, D-x e status, “Programado R$ de R$ · 100%”.
- **No cronograma:** Montagem D-9 a D-7, Desmontagem D+1, com “Ver”.
- **Anexos:** “+ Arquivo” e lista de arquivos com data.
- **Rodapé:** Cancelar e Salvar.

**Regras:**
- Com memória, a quantidade fica travada.
- Remover o item apaga também as linhas da memória (cascata).

**Dados:** `planilha_itens, fornecedores, usuarios, mem_*, cronograma_linhas, cronograma_marcacoes, anexos`

**Quem pode:** Equipe do evento e gestor/planejamento.

**Pendências:**
- Parcelas e Pagamento dependem do módulo pausado.
- “+ Cadastrar fornecedor” só funciona para gestor/planejamento.
- Avaliar “Arquivar” no lugar de “Remover item”.

## 9. Memória · Comunicação visual
Arquivo do protótipo: `prototipo/ComVisual.html`

**Objetivo:** Peças de comunicação visual com medidas e valor.

**Como chegar:** Planilha de trabalho → submenu lateral da memória, ou Detalhe do item → “Editar memória”.

**Blocos:**
- **Cabeçalho:** Caminho Eventos / [Evento] / Planilha de trabalho, nome da memória e botão “+ Novo item”, que abre a janela de inclusão.
- **Indicadores:** Item na planilha (Comunicação visual) e Linhas (3 itens · 23,24 m²).
- **Colunas:** Item · Código · Largura (m) · Altura (m) · M² (calculado) · Valor total
- **Cartão “Vai para a planilha de trabalho”:** Mostra em destaque o resultado que sobe para o item da planilha (valor em R$ ou quantidade).
- **Tabela estilo Excel:** Enter cria a próxima linha, Tab avança de célula; dá para colar várias linhas do Excel de uma vez. A última linha vazia é a de inclusão rápida. O “×” remove a linha.
- **Linha de total e legenda:** Totais das colunas numéricas e legenda das células: calculado (não editável) e bloqueado para o item escolhido.

**Regras:**
- M² = largura × altura (não editável).
- O valor total é digitado por linha.
- Sobe para a planilha: soma dos valores (e a soma dos m² como quantidade).

**Dados:** `mem_com_visual`

**Quem pode:** Equipe do evento e gestor/planejamento.

## 10. Memória · Forração
Arquivo do protótipo: `prototipo/Forracao.html`

**Objetivo:** Forração por local, com estilo, cor e preço por m².

**Como chegar:** Planilha de trabalho → submenu lateral da memória, ou Detalhe do item → “Editar memória”.

**Blocos:**
- **Cabeçalho:** Caminho Eventos / [Evento] / Planilha de trabalho, nome da memória e botão “+ Novo item”, que abre a janela de inclusão.
- **Indicadores:** Item na planilha e Linhas (3 itens · 136 m²).
- **Colunas:** Item · Código · Estilo · Largura · Altura · M² · Preço und. · Qtd · Total · Local de aplicação · Cor
- **Cartão “Vai para a planilha de trabalho”:** Mostra em destaque o resultado que sobe para o item da planilha (valor em R$ ou quantidade).
- **Tabela estilo Excel:** Enter cria a próxima linha, Tab avança de célula; dá para colar várias linhas do Excel de uma vez. A última linha vazia é a de inclusão rápida. O “×” remove a linha.
- **Linha de total e legenda:** Totais das colunas numéricas e legenda das células: calculado (não editável) e bloqueado para o item escolhido.

**Regras:**
- M² = largura × altura.
- Total = M² × preço und. × quantidade.
- Sobe para a planilha: soma dos totais (e dos m²).

**Dados:** `mem_forracao`

**Quem pode:** Equipe do evento e gestor/planejamento.

## 11. Memória · Cenografia geral
Arquivo do protótipo: `prototipo/Cenografia.html`

**Objetivo:** Peças de cenografia com controle de teto orçamentário.

**Como chegar:** Planilha de trabalho → submenu lateral da memória, ou Detalhe do item → “Editar memória”.

**Blocos:**
- **Cabeçalho:** Caminho Eventos / [Evento] / Planilha de trabalho, nome da memória e botão “+ Novo item”, que abre a janela de inclusão.
- **Indicadores:** Item na planilha, Teto orçamentário somado e “Acima do teto: N itens”.
- **Colunas:** Item · Descritivo · Preço und. · Qtd · Total · Teto orçamentário · Dentro/Acima · Local de aplicação · Cor
- **Cartão “Vai para a planilha de trabalho”:** Mostra em destaque o resultado que sobe para o item da planilha (valor em R$ ou quantidade).
- **Tabela estilo Excel:** Enter cria a próxima linha, Tab avança de célula; dá para colar várias linhas do Excel de uma vez. A última linha vazia é a de inclusão rápida. O “×” remove a linha.
- **Linha de total e legenda:** Totais das colunas numéricas e legenda das células: calculado (não editável) e bloqueado para o item escolhido.

**Regras:**
- Total = preço und. × quantidade.
- Selo “Acima” quando o total passa do teto orçamentário da linha.
- Sobe para a planilha: soma dos totais.

**Dados:** `mem_cenografia`

**Quem pode:** Equipe do evento e gestor/planejamento.

**Pendências:**
- Confirmar se o “Preço Duzão” da planilha v3 é o teto orçamentário.

## 12. Memória · Piso e fechamentos
Arquivo do protótipo: `prototipo/PisoFechamentos.html`

**Objetivo:** Pisos, escadas, arquibancadas, rampas e fechamentos com área ou metragem linear.

**Como chegar:** Planilha de trabalho → submenu lateral da memória, ou Detalhe do item → “Editar memória”.

**Blocos:**
- **Cabeçalho:** Caminho Eventos / [Evento] / Planilha de trabalho, nome da memória e botão “+ Novo item”, que abre a janela de inclusão.
- **Indicadores:** Itens na planilha (Pisos · Fechamentos), Área total (336 m²) e Metragem linear (40 m).
- **Colunas:** Item (Piso, Escada, Arquibancada, Fechamento, Rampa) · Posicionamento · Altura · Qtd · Largura · Comprimento · Área M² · Metragem linear · Valor unitário · Valor
- **Cartão “Vai para a planilha de trabalho”:** Mostra em destaque o resultado que sobe para o item da planilha (valor em R$ ou quantidade).
- **Tabela estilo Excel:** Enter cria a próxima linha, Tab avança de célula; dá para colar várias linhas do Excel de uma vez. A última linha vazia é a de inclusão rápida. O “×” remove a linha.
- **Linha de total e legenda:** Totais das colunas numéricas e legenda das células: calculado (não editável) e bloqueado para o item escolhido.

**Regras:**
- Área M² só abre para Piso, Escada, Arquibancada e Rampa: sugere qtd × largura × comprimento e aceita ajuste.
- Metragem linear só abre para Fechamento.
- Valor = valor unitário × área (ou × metragem linear no Fechamento).
- Linha sem item escolhido: erro.
- Sobe para a planilha: soma dos valores; quantidade = área total.

**Dados:** `mem_piso_fechamento`

**Quem pode:** Equipe do evento e gestor/planejamento.

**Pendências:**
- A tela fala em dois itens (Pisos · Fechamentos); no catálogo v0.3 eles viraram um item só, “Piso e fechamentos”.

## 13. Memória · Gradil e tendas
Arquivo do protótipo: `prototipo/GradilTendas.html`

**Objetivo:** Tendas, balcões, gradil e fechamentos em lona, com medidas calculadas.

**Como chegar:** Planilha de trabalho → submenu lateral da memória, ou Detalhe do item → “Editar memória”.

**Blocos:**
- **Cabeçalho:** Caminho Eventos / [Evento] / Planilha de trabalho, nome da memória e botão “+ Novo item”, que abre a janela de inclusão.
- **Indicadores:** Tendas (450 m²), Fechamento em lona (108 m²), Gradil (160 ML) e Itens na planilha.
- **Colunas:** Item (Tenda, Balcão, Gradil, Fechamento em lona) · Posicionamento · Estilo (Tubular, Balcão, Gradil, Lona, Calhada, Arco, Avance) · Qtd · Largura (ML) · Compr. (ML) · Altura · Tendas (M²) · Lonas (M²) · Gradil (ML) · Valor unit. · Valor total
- **Cartão “Vai para a planilha de trabalho”:** Mostra em destaque o resultado que sobe para o item da planilha (valor em R$ ou quantidade).
- **Tabela estilo Excel:** Enter cria a próxima linha, Tab avança de célula; dá para colar várias linhas do Excel de uma vez. A última linha vazia é a de inclusão rápida. O “×” remove a linha.
- **Linha de total e legenda:** Totais das colunas numéricas e legenda das células: calculado (não editável) e bloqueado para o item escolhido.

**Regras:**
- Tendas (M²) só para Tenda: qtd × largura × comprimento.
- Lonas (M²) só para Fechamento em lona: qtd × largura × 2,70.
- Gradil (ML) só para Gradil: qtd × 2.
- As três colunas calculadas nunca são editáveis.
- Valor total: Tenda e Balcão = qtd × unitário; Lona = M² × unitário; Gradil = ML × unitário.

**Dados:** `mem_gradil_tenda`

**Quem pode:** Equipe do evento e gestor/planejamento.

**Pendências:**
- Confirmar a regra do valor total.

## 14. Memória · Banheiros químicos
Arquivo do protótipo: `prototipo/Banheiros.html`

**Objetivo:** Banheiros por local, comuns e PNE, comparados ao necessário pelo público.

**Como chegar:** Planilha de trabalho → submenu lateral da memória, ou Detalhe do item → “Editar memória”.

**Blocos:**
- **Cabeçalho:** Caminho Eventos / [Evento] / Planilha de trabalho, nome da memória e botão “+ Novo item”, que abre a janela de inclusão.
- **Indicadores:** 40 unidades, Comuns + PNE (35 + 5) e Necessário pelo público.
- **Colunas:** Referencial · Setor · Local · Quantidade · Quantidade PNE · Total
- **Cartão “Vai para a planilha de trabalho”:** Mostra em destaque o resultado que sobe para o item da planilha (valor em R$ ou quantidade).
- **Tabela estilo Excel:** Enter cria a próxima linha, Tab avança de célula; dá para colar várias linhas do Excel de uma vez. A última linha vazia é a de inclusão rápida. O “×” remove a linha.
- **Linha de total e legenda:** Totais das colunas numéricas e legenda das células: calculado (não editável) e bloqueado para o item escolhido.

**Regras:**
- Total = quantidade + PNE.
- Compara com o necessário pelo público (3.000 ÷ 80 = 38): “Atende · sobram 2”.
- Sobe para a planilha: total de unidades como quantidade do item “Banheiros químicos”.

**Dados:** `mem_banheiro, parametros_dimensionamento`

**Quem pode:** Equipe do evento e gestor/planejamento.

**Pendências:**
- Setor está como texto: deve virar a lista dos setores do evento.

## 15. Memória · Barricadas
Arquivo do protótipo: `prototipo/Barricadas.html`

**Objetivo:** Peças de barricada por tipo e setor.

**Como chegar:** Planilha de trabalho → submenu lateral da memória, ou Detalhe do item → “Editar memória”.

**Blocos:**
- **Cabeçalho:** Caminho Eventos / [Evento] / Planilha de trabalho, nome da memória e botão “+ Novo item”, que abre a janela de inclusão.
- **Indicadores:** 46 peças, com o total de cada tipo.
- **Colunas:** Tipo de peça (Barricada reta, Curva direita, Curva esquerda) · Setor · Quantidade
- **Cartão “Vai para a planilha de trabalho”:** Mostra em destaque o resultado que sobe para o item da planilha (valor em R$ ou quantidade).
- **Tabela estilo Excel:** Enter cria a próxima linha, Tab avança de célula; dá para colar várias linhas do Excel de uma vez. A última linha vazia é a de inclusão rápida. O “×” remove a linha.
- **Linha de total e legenda:** Totais das colunas numéricas e legenda das células: calculado (não editável) e bloqueado para o item escolhido.

**Regras:**
- Resumo por tipo vai para o fornecedor.
- Sobe para a planilha: total de peças.

**Dados:** `mem_barricada`

**Quem pode:** Equipe do evento e gestor/planejamento.

**Pendências:**
- Setor deve ser a lista dos setores do evento.

## 16. Memória · Painel de LED
Arquivo do protótipo: `prototipo/PainelLed.html`

**Objetivo:** Painéis de LED por local com metragem.

**Como chegar:** Planilha de trabalho → submenu lateral da memória, ou Detalhe do item → “Editar memória”.

**Blocos:**
- **Cabeçalho:** Caminho Eventos / [Evento] / Planilha de trabalho, nome da memória e botão “+ Novo item”, que abre a janela de inclusão.
- **Indicadores:** 48 m², Item na planilha e Painéis (3).
- **Colunas:** Local · Descrição · Dimensão (L × A) · Metros totais (m²)
- **Cartão “Vai para a planilha de trabalho”:** Mostra em destaque o resultado que sobe para o item da planilha (valor em R$ ou quantidade).
- **Tabela estilo Excel:** Enter cria a próxima linha, Tab avança de célula; dá para colar várias linhas do Excel de uma vez. A última linha vazia é a de inclusão rápida. O “×” remove a linha.
- **Linha de total e legenda:** Totais das colunas numéricas e legenda das células: calculado (não editável) e bloqueado para o item escolhido.

**Regras:**
- Metros totais = largura × altura (calculado).
- Sobe para a planilha: total de m².

**Dados:** `mem_painel_led`

**Quem pode:** Equipe do evento e gestor/planejamento.

## 17. Memória · Mesas e cadeiras
Arquivo do protótipo: `prototipo/MesasCadeiras.html`

**Objetivo:** Mesas e cadeiras por local e tipo.

**Como chegar:** Planilha de trabalho → submenu lateral da memória, ou Detalhe do item → “Editar memória”.

**Blocos:**
- **Cabeçalho:** Caminho Eventos / [Evento] / Planilha de trabalho, nome da memória e botão “+ Novo item”, que abre a janela de inclusão.
- **Indicadores:** 42 mesas · 168 cadeiras e o resumo por tipo.
- **Colunas:** Local · Descrição · Mesas · Cadeiras · Tipo (Madeira, Plástico)
- **Cartão “Vai para a planilha de trabalho”:** Mostra em destaque o resultado que sobe para o item da planilha (valor em R$ ou quantidade).
- **Tabela estilo Excel:** Enter cria a próxima linha, Tab avança de célula; dá para colar várias linhas do Excel de uma vez. A última linha vazia é a de inclusão rápida. O “×” remove a linha.
- **Linha de total e legenda:** Totais das colunas numéricas e legenda das células: calculado (não editável) e bloqueado para o item escolhido.

**Regras:**
- Resumo por tipo: Madeira (12 mesas · 48 cadeiras), Plástico (30 · 120).
- Sobe para a planilha: totais de mesas e cadeiras.

**Dados:** `mem_mesas_cadeiras`

**Quem pode:** Equipe do evento e gestor/planejamento.

**Pendências:**
- Decidir se a quantidade do item é mesas + cadeiras somadas (como está no banco) ou se vira dois itens.

## 18. Memória · Mobília
Arquivo do protótipo: `prototipo/Mobilia.html`

**Objetivo:** Mobília por local, com fornecedor do cadastro.

**Como chegar:** Planilha de trabalho → submenu lateral da memória, ou Detalhe do item → “Editar memória”.

**Blocos:**
- **Cabeçalho:** Caminho Eventos / [Evento] / Planilha de trabalho, nome da memória e botão “+ Novo item”, que abre a janela de inclusão.
- **Indicadores:** 26 peças, Item na planilha e número de fornecedores.
- **Colunas:** Local · Item · Quantidade · Fornecedor (do cadastro, com “+ Cadastrar”)
- **Cartão “Vai para a planilha de trabalho”:** Mostra em destaque o resultado que sobe para o item da planilha (valor em R$ ou quantidade).
- **Tabela estilo Excel:** Enter cria a próxima linha, Tab avança de célula; dá para colar várias linhas do Excel de uma vez. A última linha vazia é a de inclusão rápida. O “×” remove a linha.
- **Linha de total e legenda:** Totais das colunas numéricas e legenda das células: calculado (não editável) e bloqueado para o item escolhido.

**Regras:**
- O fornecedor vem do cadastro da empresa.
- Sobe para a planilha: total de peças.

**Dados:** `mem_mobilia, fornecedores`

**Quem pode:** Equipe do evento e gestor/planejamento.

## 19. Conferência em campo
Arquivo do protótipo: `prototipo/Conferencia.html`

**Objetivo:** Conferir o que chegou contra o que foi contratado, por fase.

**Como chegar:** Planilha → “Conferência”.

**Blocos:**
- **Topo:** “← Planilha”, evento · data · D-x e explicação.
- **Fases:** Abas Montagem, Operação e Desmontagem.
- **Progresso:** “12 de 18 itens conferidos” com barra e contador de divergências.
- **Cartão por item:** Nome, fornecedor, selo (A conferir, Conforme, Divergente), Contratado, campo “Chegou”, observação da divergência, botões Conforme, Divergente e foto. Mostra “Conferido por [Nome] · [hora] · 2 fotos”.

**Regras:**
- Um registro por item e por fase.
- O contratado é guardado no momento da conferência (fica a foto do valor).

**Dados:** `conferencias, planilha_itens, anexos`

**Quem pode:** Equipe do evento e gestor/planejamento.

## 20. Evento · Cronograma
Arquivo do protótipo: `prototipo/Cronograma.html`

**Objetivo:** Quando cada estrutura monta, opera e desmonta, por setor, dia e período.

**Como chegar:** Evento → aba Cronograma.

**Blocos:**
- **Ações:** Imprimir, “+ Setor” e “+ Atividade”.
- **Legenda e filtros:** M · Montagem, O · Operação, D · Desmontagem; “Cada dia em 3 períodos: manhã · tarde · noite”; Mostrar (todos os setores ou um) e “Expandir tudo”.
- **Grade:** Colunas D-8 … EVENTO … D+2 com o dia da semana, cada uma com manhã, tarde e noite.
- **Marcos do evento:** Primeira linha, vinda de Artístico e Documentação: ◆ prazos e vistorias, ♪ passagem de som, ★ show.
- **Setores:** Grupos (Portaria, Palco, Área VIP, Praça de alimentação) com contagem de estruturas, alça para arrastar e setas ↑ ↓ para ordenar.
- **Linhas:** Estrutura com resumo (ex.: “Entrada principal · 3 × 10×10 · [Fornecedor A]”); ▸ abre as linhas da memória (ex.: Escada do palco, Fechamento frente do palco). Atividades avulsas em itálico (Vistoria AVCB, Passagem de som).

**Regras:**
- Só estruturas: itens de Staff são recusados (vão para Mão de obra).
- As marcações guardam o dia relativo; mudou a data do evento, a grade acompanha.

**Dados:** `setores, cronograma_linhas, cronograma_marcacoes, v_cronograma, v_cronograma_marcos`

**Quem pode:** Equipe do evento e gestor/planejamento.

## 21. Evento · Artístico
Arquivo do protótipo: `prototipo/Atracoes.html`

**Objetivo:** Atrações, horários, custos, hospedagem e transporte.

**Como chegar:** Evento → aba Artístico.

**Blocos:**
- **Lista de atrações:** “+ Atração” e cartões com nome, show e passagem de som.
- **Atração selecionada:** Contato da produção, Passagem de som (data e hora), Show (data, hora e duração).
- **Cachê e alimentação:** Tipo · Qtd · Total · Status, com “Ver parcelas”.
- **Hospedagem:** “+ Hotel” e tabela Hotel · Quem · Check-in / out.
- **Roomlist:** Por hotel: “Importar lista”, “Exportar p/ hotel” e tabela Hóspede · Função · Tipo de quarto · Nº quarto.
- **Transporte:** “+ Trecho” e tabela Trecho · Veículo · Saída · Chegada · Origem → destino · Pax · Fornecedor / motorista (ou voo).

**Regras:**
- Passagem de som e show viram marcos no cronograma.
- Trechos: chegada na cidade, ida e volta da passagem de som, ida e volta do show, saída da cidade.

**Dados:** `atracoes, atracao_custos, hospedagens, roomlist, transportes, hoteis, fornecedores`

**Quem pode:** Equipe do evento e gestor/planejamento.

**Pendências:**
- Confirmar os tipos de atração (artístico, staff, fornecedor, esportivo).
- Status e parcelas do cachê dependem de pagamentos.

## 22. Evento · Documentação
Arquivo do protótipo: `prototipo/Documentacao.html`

**Objetivo:** Acompanhar licenças e documentos até a aprovação.

**Como chegar:** Evento → aba Documentação.

**Blocos:**
- **Topo:** “+ Documento” e as etapas: Pendente → Protocolado → Em análise → Aprovado.
- **Cartão por documento:** Nome (CEMIG, AVCB, CODAU, Alvará), selo de status, Protocolo, Prazo (data · D-x ou “vence em N dias”), Emitido, Vistoria, Depende de (ex.: AVCB aprovado), Responsável.
- **Ações:** Ver arquivo, Anexar, Atualizar status, Protocolar.

**Regras:**
- Os documentos padrão nascem com o evento.
- Um documento pode depender de outro (Alvará depende do AVCB).
- O prazo em D-x vira marco no cronograma.

**Dados:** `documentos, tipos_documento, anexos`

**Quem pode:** Equipe do evento e gestor/planejamento.

## 23. Evento · Pagamentos (desabilitada)
Arquivo do protótipo: `prototipo/Pagamentos.html`

**Objetivo:** Fica como referência. Os pagamentos seguem no sistema atual da EXP.

**Como chegar:** Evento → aba Pagamentos (marcada “em breve”).

**Blocos:**
- **Aviso:** “Desabilitado · Módulo de pagamentos pausado por enquanto.”
- **Indicadores:** Contratado, Programado em parcelas, Pago, Em atraso, Sem NF.
- **Fluxo no eixo do evento:** Barras por D-x (pago, a pagar, atrasado) no mesmo eixo do cronograma.
- **Parcelas:** Filtros Todas, Atrasadas, Aguardando NF, Próx. 7 dias; colunas Venc. · D-x · Item / atração · Fornecedor · Parcela · Condição · Valor · NF · Status e ações Dar baixa, Anexar NF, Comprovante.

**Regras:**
- Na v0.3 não há tabela de pagamentos: a planilha e os custos da atração guardam só uma referência externa.

**Dados:** `planilha_itens.pagamento_ref_externa, atracao_custos.pagamento_ref_externa`

**Quem pode:** —

## 24. Estoque
Arquivo do protótipo: `prototipo/Estoque.html`

**Objetivo:** Material próprio da EXP e por onde ele anda.

**Como chegar:** Menu lateral → Estoque.

**Blocos:**
- **Ações e filtros:** “Registrar movimento”, “+ Material”, busca, categoria e situação (Disponível, Em evento, Manutenção).
- **Tabela de materiais:** Material · Categoria · Und · Total · Disponível · Reservado · Em evento · Manutenção · Local.
- **Movimentos recentes:** Data · Material · Tipo · Qtd · Evento · Por · Obs.

**Regras:**
- Tipos de movimento: reserva, saída, retorno, manutenção, retorno de manutenção e perda.
- Saldo calculado pela visão v_estoque_saldo.

**Dados:** `estoque_itens, estoque_movimentos, v_estoque_saldo`

**Quem pode:** Todos consultam e movimentam; materiais só gestor/planejamento.

**Pendências:**
- Definir se a saída baixa a reserva (hoje as duas somam).

## 25. Cadastros
Arquivo do protótipo: `prototipo/Cadastros.html`

**Objetivo:** Dados da empresa reutilizados em todos os eventos.

**Como chegar:** Menu lateral → Cadastros.

**Blocos:**
- **Abas:** Fornecedores, Catálogo de itens, Hotéis, Usuários.
- **Fornecedores:** Busca, “+ Fornecedor” e tabela Fornecedor · Categoria · Contato · Eventos · Em aberto.
- **Painel de edição:** Razão social / nome, CNPJ, Categoria, Contato, Telefone, Chave PIX / dados bancários, histórico (N eventos · última contratação) e Salvar / Cancelar.

**Regras:**
- CNPJ não repete dentro da empresa.

**Dados:** `fornecedores, catalogo_itens, categorias, hoteis, usuarios`

**Quem pode:** Todos leem; só gestor/planejamento editam.

**Pendências:**
- Abas Catálogo, Hotéis e Usuários ainda não desenhadas.
- “Em aberto” depende de pagamentos.

## 26. Mapa do banco
Arquivo do protótipo: `prototipo/Banco.html`

**Objetivo:** Explorar o banco de dados v0.3 de forma interativa.

**Como chegar:** Menu lateral → Projeto → Mapa do banco (ou link no login).

**Blocos:**
- **Topo:** “← Protótipo”, totais (41 tabelas · 6 visões · 16 listas fixas · 73 ligações), busca, Chaves / Todas as colunas, Visões, Ligações de apoio e Percursos.
- **Prancha:** Cartões por grupo, arrastáveis, com ligações; zoom e Reorganizar.
- **Painel da tabela:** Colunas, fórmulas, regras, gatilhos e quem pode ler ou editar.
- **Percursos:** Passeios guiados: do catálogo ao valor da planilha, criar um evento, montar o cronograma, quem vê o quê, artístico.

**Regras:**
- Gerado a partir do próprio banco testado.

**Dados:** `todas`

**Quem pode:** Ferramenta do projeto.

## Telas ainda não desenhadas

- **Novo evento:** Assistente com dados do evento, modelo pronto e checklist de telas.
- **Editar evento / telas do evento:** Edição dos dados e do checklist depois de criado (só gestor e planejamento ligam ou desligam telas).
- **Conectar Asana:** Autorização da conta e confirmação.
- **Cadastros · Catálogo, Hotéis e Usuários:** Abas citadas na tela de Cadastros.
- **Configurações:** Parâmetros de dimensionamento, tipos de documento, modelos de evento, frases do dia.
- **Histórico:** Consulta de alterações (só gestor e planejamento).
- **Mão de obra:** Aba futura para Staff, fora do cronograma de estruturas.
- **Versão celular:** Responsividade reorganizada depois do desktop.
