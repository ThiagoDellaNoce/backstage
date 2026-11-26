# Casos de uso

Atores: **Usuário** (qualquer pessoa logada) ▷ **Membro da equipe** (arquiteto, produtores, freelance — nos eventos em que está na equipe) ▷ **Administrador** (gestor e planejamento). Externos: Google, Asana, Google Sheets, Sistema de pagamentos EXP.

| ID | Caso de uso | Pacote | Atores | Descrição | Telas |
|---|---|---|---|---|---|
| UC01 | Entrar no sistema | Acesso e painel | Usuário, Google | Login com a conta Google da EXP (ou e-mail e senha). O sistema confere se a pessoa está cadastrada e ativa e carrega empresa e papel. | Login |
| UC02 | Ver painel do dia | Acesso e painel | Usuário | Frase do dia, indicadores (eventos ativos, eventos esta semana, pontos de atenção), tarefas do Asana (para hoje, atrasadas, na fila), próximos eventos e pontos de atenção. «include» UC04. | Painel |
| UC03 | Conectar conta do Asana | Acesso e painel | Usuário, Asana | Autoriza o Backstage a ler as tarefas da pessoa. O token fica guardado no cofre (Vault), nunca no navegador. | Painel (menu lateral) |
| UC04 | Consultar tarefas do Asana | Acesso e painel | Asana | Uma função no servidor (Edge Function) busca as tarefas com o token do cofre e devolve os totais ao painel. | Painel |
| UC05 | Escolher tema (Roxo ou Verde) | Acesso e painel | Usuário | Alterna entre o tema Roxo (#6b3e92) e o Verde (#1DB954 sobre #212121). A escolha fica salva no navegador. | Login, menu lateral |
| UC06 | Consultar mapa do banco | Acesso e painel | Usuário | Mapa interativo das tabelas, ligações, regras e permissões do banco. | Mapa do banco |
| UC07 | Listar e filtrar eventos | Eventos | Membro da equipe | Lista em cartões com status, data, local, D-x e alertas. Filtros por status, período e busca. Cada pessoa vê só os eventos em que está na equipe; gestor e planejamento veem todos. | Eventos |
| UC08 | Ver visão geral do evento | Eventos | Membro da equipe | Indicadores (orçado, pago, itens contratados, documentos aprovados), dados do evento, dimensionamento pelo público, equipe, orçamento por categoria e próximos 3 dias. | Evento · Visão geral |
| UC09 | Alterar status e dados do evento | Eventos | Membro da equipe | Muda o status (planejamento, montagem, operação, desmontagem, encerrado, cancelado) e edita local, datas, público e contratante. | Evento · Visão geral |
| UC10 | Criar evento | Eventos | Administrador | Assistente com os dados do evento e o checklist de telas. Ao salvar, o banco liga as telas fixas, cria os documentos padrão e põe o criador na equipe. «include» UC11. | Novo evento (a desenhar) |
| UC11 | Ligar ou desligar telas do evento | Eventos | Administrador | Checklist das telas do evento (cronograma, artístico, documentação, cada memória de cálculo). Desligar só esconde; nenhum dado é apagado. | Novo evento / Editar evento (a desenhar) |
| UC12 | Gerenciar equipe do evento | Eventos | Membro da equipe | Adiciona e remove pessoas do evento e define a função de cada uma. Quem entra na equipe passa a ver o evento. | Evento · Visão geral (Equipe) |
| UC13 | Excluir evento | Eventos | Administrador | Remove o evento e tudo o que pertence a ele (planilha, memórias, setores, cronograma, documentos, artístico, conferências, anexos, movimentos de estoque, equipe). Pede para digitar o nome do evento. O histórico de alterações é mantido. | Eventos, Visão geral |
| UC14 | Gerenciar fornecedores | Administração da empresa | Administrador | Cadastro com CNPJ, categoria, contato, telefone e dados bancários; mostra histórico de eventos e valores em aberto. | Cadastros · Fornecedores |
| UC15 | Gerenciar catálogo de itens | Administração da empresa | Administrador | Itens reutilizáveis por categoria, com unidade padrão e o modelo de memória de cálculo que cada um usa. | Cadastros · Catálogo, Novo item no catálogo |
| UC16 | Gerenciar hotéis | Administração da empresa | Administrador | Hotéis usados nas hospedagens do artístico. | Cadastros · Hotéis |
| UC17 | Gerenciar usuários e papéis | Administração da empresa | Administrador | Cadastra pessoas, define o papel padrão (gestor, planejamento, arquiteto, produtores, freelance) e desativa acessos. | Cadastros · Usuários |
| UC18 | Configurar parâmetros | Administração da empresa | Administrador | Regras de dimensionamento pelo público, tipos de documento padrão, modelos de evento e frases do dia. | Frases do dia: Painel (✎). Demais: a desenhar |
| UC19 | Consultar histórico de alterações | Administração da empresa | Administrador | Quem criou, mudou ou apagou eventos, itens da planilha, documentos e telas do evento, com o antes e o depois. | A desenhar |
| UC20 | Adicionar itens do catálogo | Planilha de trabalho | Membro da equipe | Marca no catálogo os itens que o evento vai contratar; pode copiar a seleção de outro evento. | Adicionar itens do catálogo |
| UC21 | Editar item da planilha | Planilha de trabalho | Membro da equipe | Fornecedor, descritivo, responsável, observação, quantidade, frequência, valor unitário e status de contrato e produção. | Detalhe do item |
| UC22 | Preencher memória de cálculo | Planilha de trabalho | Membro da equipe | Lança as linhas de detalhe (10 tipos). O banco calcula medidas e valores; só o resultado sobe para o item da planilha. «extend» UC21. | 10 telas de memória |
| UC23 | Exportar planilha para Google Sheets | Planilha de trabalho | Membro da equipe, Google Sheets | Gera uma cópia da planilha do evento numa planilha Google. | Planilha de trabalho |
| UC24 | Anexar arquivos | Planilha de trabalho | Membro da equipe | Orçamentos, contratos, fotos, alvarás e riders guardados no Storage e ligados ao item, documento, conferência ou atração. | Detalhe do item, Documentação, Conferência |
| UC25 | Conferir itens em campo | Planilha de trabalho | Membro da equipe | Na montagem, operação e desmontagem: compara contratado × recebido, marca conforme ou divergente, registra observação e fotos. «include» UC24. | Conferência em campo |
| UC26 | Organizar setores | Cronograma | Membro da equipe | Cria setores (Portaria, Palco, VIP…) e muda a ordem livremente. | Cronograma |
| UC27 | Marcar montagem, operação e desmontagem | Cronograma | Membro da equipe | Para cada estrutura, marca dia relativo (D-x) e período (manhã, tarde, noite) com a fase M, O ou D. Itens de Staff não entram. | Cronograma |
| UC28 | Adicionar atividade avulsa | Cronograma | Membro da equipe | Linhas que não são estruturas: vistoria, passagem de som, entregas. | Cronograma |
| UC29 | Imprimir cronograma | Cronograma | Membro da equipe | Versão para impressão, filtrável por setor. | Cronograma |
| UC30 | Controlar documentos do evento | Documentação | Membro da equipe | Protocolo, status (pendente → protocolado → em análise → aprovado/indeferido), prazo em D-x, vistoria, responsável e dependência entre documentos. «include» UC24. | Documentação |
| UC31 | Cadastrar atrações e horários | Artístico | Membro da equipe | Atrações com tipo, contato da produção, passagem de som, horário e duração do show. | Artístico |
| UC32 | Controlar cachê e custos da atração | Artístico | Membro da equipe | Cachê, alimentação e outros custos com quantidade, valor e referência ao pagamento externo. | Artístico |
| UC33 | Organizar hospedagem e roomlist | Artístico | Membro da equipe | Hotel, check-in/out por grupo; roomlist com hóspede, função, tipo e número do quarto; importar e exportar para o hotel. | Artístico |
| UC34 | Organizar transporte | Artístico | Membro da equipe | Trechos (chegada, passagem de som, show, saída), veículo, horários, origem/destino, passageiros, fornecedor, motorista ou voo. | Artístico |
| UC35 | Consultar estoque | Estoque | Usuário | Saldo de cada material: total, disponível, reservado, em evento, em manutenção, local. | Estoque |
| UC36 | Registrar movimento de estoque | Estoque | Usuário | Reserva, saída, retorno, manutenção, retorno de manutenção ou perda, ligado ao evento. | Estoque |
| UC37 | Cadastrar material do estoque | Estoque | Administrador | Novo material com categoria, unidade, quantidade total e local. | Estoque |
| UC38 | Consultar pagamentos | Pagamentos (futuro) | Membro da equipe, Sistema de pagamentos EXP | Módulo pausado. Os pagamentos seguem no sistema atual da EXP (Apps Script); a planilha guarda só uma referência externa. | Pagamentos (desabilitada) |
