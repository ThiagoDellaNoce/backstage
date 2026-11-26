# Permissões (regras RLS do schema v0.3)

Dois níveis: **administrador** (gestor, planejamento) e **membro** (demais papéis). A função no evento (`evento_equipe.papel`) é informativa.

Legenda: **Total** = em todos os eventos e cadastros da empresa · **Equipe** = ler e editar, só nos eventos em que está na equipe · **Ver na equipe** = só ler, nos eventos em que está na equipe · **Ler** = só leitura · **Próprio** = só os próprios dados · **Não** = sem acesso

| Ação | Gestor | Planejamento | Arquiteto | Produtor de bar | Produtor de palco | Produtor geral | Freelance | Tabelas |
|---|---|---|---|---|---|---|---|---|
| **Acesso e painel** | | | | | | | | |
| Entrar, ver o painel, escolher tema | Total | Total | Total | Total | Total | Total | Total | `todas` |
| Conectar a própria conta do Asana | Próprio | Próprio | Próprio | Próprio | Próprio | Próprio | Próprio | `usuario_integracoes` |
| Ver colegas da empresa (nome, papel) | Total | Total | Ler | Ler | Ler | Ler | Ler | `usuarios` |
| Cadastrar, editar e desativar usuários ⚠ | Total | Total | Não | Não | Não | Não | Não | `usuarios` |
| Consultar histórico de alterações | Ler | Ler | Não | Não | Não | Não | Não | `historico` |
| **Eventos** | | | | | | | | |
| Ver a lista de eventos | Total | Total | Equipe | Equipe | Equipe | Equipe | Equipe | `eventos` |
| Criar evento | Total | Total | Não | Não | Não | Não | Não | `eventos` |
| Editar dados e status do evento ⚠ | Total | Total | Equipe | Equipe | Equipe | Equipe | Equipe | `eventos` |
| Excluir evento (apaga tudo do evento, inclusive movimentos de estoque; histórico mantido) | Total | Total | Não | Não | Não | Não | Não | `eventos` |
| Ligar e desligar telas do evento (checklist) | Total | Total | Ver na equipe | Ver na equipe | Ver na equipe | Ver na equipe | Ver na equipe | `evento_modulos` |
| Adicionar e remover pessoas da equipe ⚠ | Total | Total | Equipe | Equipe | Equipe | Equipe | Equipe | `evento_equipe` |
| Criar e ordenar setores | Total | Total | Equipe | Equipe | Equipe | Equipe | Equipe | `setores` |
| **Planilha de trabalho** | | | | | | | | |
| Ver e editar itens da planilha | Total | Total | Equipe | Equipe | Equipe | Equipe | Equipe | `planilha_itens` |
| Apagar itens da planilha ⚠ | Total | Total | Equipe | Equipe | Equipe | Equipe | Equipe | `planilha_itens` |
| Preencher as 10 memórias de cálculo | Total | Total | Equipe | Equipe | Equipe | Equipe | Equipe | `mem_*` |
| Conferência em campo | Total | Total | Equipe | Equipe | Equipe | Equipe | Equipe | `conferencias` |
| Anexar arquivos e fotos | Total | Total | Equipe | Equipe | Equipe | Equipe | Equipe | `anexos` |
| **Cronograma, documentação e artístico** | | | | | | | | |
| Montar o cronograma (linhas e marcações) | Total | Total | Equipe | Equipe | Equipe | Equipe | Equipe | `cronograma_linhas · cronograma_marcacoes` |
| Controlar documentos do evento | Total | Total | Equipe | Equipe | Equipe | Equipe | Equipe | `documentos` |
| Atrações, custos, hospedagem, roomlist e transporte | Total | Total | Equipe | Equipe | Equipe | Equipe | Equipe | `atracoes · atracao_custos · hospedagens · roomlist · transportes` |
| **Cadastros da empresa** | | | | | | | | |
| Fornecedores ⚠ | Total | Total | Ler | Ler | Ler | Ler | Ler | `fornecedores` |
| Catálogo de itens e categorias ⚠ | Total | Total | Ler | Ler | Ler | Ler | Ler | `catalogo_itens · categorias` |
| Hotéis | Total | Total | Ler | Ler | Ler | Ler | Ler | `hoteis` |
| Tipos de documento, modelos de evento ⚠ | Total | Total | Ler | Ler | Ler | Ler | Ler | `tipos_documento · modelos_evento · modelo_modulos` |
| Parâmetros de dimensionamento e frases do dia (frases: pelo Painel) | Total | Total | Ler | Ler | Ler | Ler | Ler | `parametros_dimensionamento · frases_do_dia` |
| **Estoque** | | | | | | | | |
| Consultar estoque | Total | Total | Ler | Ler | Ler | Ler | Ler | `estoque_itens` |
| Cadastrar e editar materiais | Total | Total | Não | Não | Não | Não | Não | `estoque_itens` |
| Registrar movimentos ⚠ | Total | Total | Total | Total | Total | Total | Total | `estoque_movimentos` |

## Pontos de atenção

- **Cadastrar, editar e desativar usuários:** Ninguém além de gestor/planejamento edita o próprio nome ou telefone
- **Editar dados e status do evento:** Qualquer membro da equipe muda o status (inclusive para Encerrado ou Cancelado)
- **Adicionar e remover pessoas da equipe:** Hoje um membro, até freelance, pode pôr ou tirar pessoas da equipe
- **Apagar itens da planilha:** Apagar um item apaga também as linhas da memória; considerar só arquivar
- **Fornecedores:** As telas oferecem “+ Cadastrar fornecedor” a todos, mas o banco só deixa gestor/planejamento
- **Catálogo de itens e categorias:** Mesmo caso: “Cadastrar novo item no catálogo” aparece para todos
- **Tipos de documento, modelos de evento:** Telas de modelos: o banco deixa qualquer usuário apagar as telas de um modelo (falta trava no apagar)
- **Registrar movimentos:** Qualquer usuário da empresa registra, edita ou apaga movimentos, mesmo fora da equipe do evento
- **Permissões por função:** arquiteto, produtores e freelance têm as mesmas permissões.
- **Apagar dentro do evento:** membros apagam documentos, atrações, linhas do cronograma e anexos.
