# Backstage — contexto do projeto

Este arquivo passa para o Claude Code tudo o que foi decidido nas conversas de desenho do Backstage
(nov/2026). Leia inteiro antes de começar. Os detalhes estão em `docs/`.

## Com quem você está trabalhando

- **Della**, coordenador de produção de eventos na **EXP Produções**. Brasileira: responda sempre em **português do Brasil**.
- Já constrói ferramentas internas (Google Apps Script, Sheets, HTML/CSS/JS próprio). Entende código, mas o foco dela é o produto.
- Jeito de trabalhar: começa simples e evolui por etapas; manda listas de alterações numeradas e exatas (ex.: "1.1 …, 2.3 …").
  Siga a numeração dele ao responder. Quando ele diz "vamos pensar juntos antes de alterar", **não mude nada**: proponha e espere.
- Prefere ver o resultado funcionando a ler explicações longas. Respostas curtas, diretas, sem jargão desnecessário.
- Comentários deixados no protótipo (botão "Comentar") são respondidos na conversa, não em threads.

## O que é o Backstage

Sistema web de controle e gestão de eventos que substitui a planilha **"MOLDE - PLANILHA DE PLANEJAMENTO"**
(`referencia/MOLDE_-_PLANEJAMENTO_-_v3.xlsx`). Cada aba da planilha virou uma tela; as contas viraram regras no banco;
cada pessoa vê só os eventos em que trabalha.

Módulos: Painel · Eventos · Visão geral do evento · Planilha de trabalho (+ catálogo, detalhe do item, conferência em campo)
· 10 Memórias de cálculo · Cronograma · Artístico · Documentação · Estoque · Cadastros · Pagamentos (pausado) · Mão de obra (futuro).

## Onde paramos (26/11/2026)

- Protótipo navegável com **26 telas** (pasta `prototipo/`, abrir `prototipo/index.html`), temas Roxo e Verde.
- Banco **v0.3** pronto e testado em PostgreSQL 16 (`supabase/migrations/…_schema_v0_3.sql` + `supabase/seed.sql`).
- Documentação completa em PDF (`docs/Backstage_Documentacao_v0.3.pdf`, 112 páginas): casos de uso, classes, fluxogramas,
  relações do banco, permissões e todas as telas. Estude-o bem.

- **Próximo passo combinado: subir a primeira versão real** (ver "Primeira versão" abaixo).

- Há 14 decisões em aberto (`docs/pendencias.md`). Só as de **permissão** devem ser resolvidas antes de mexer nas regras RLS.

## Decisões tomadas (não reabrir sem o Della pedir)

| Tema | Decisão |
|---|---|
| Front-end | HTML, CSS e JavaScript **puro** (sem framework, sem build obrigatório). `supabase-js` por ESM/CDN. |
| Hospedagem | **Cloudflare** (Workers com arquivos estáticos, pasta `app`), publicando a cada push na `main` do **GitHub**. Endereço: https://backstage.thiago-2dd.workers.dev |
| Banco e login | **Supabase**: PostgreSQL com RLS, gatilhos e visões; login **Google** (conta da EXP, domínio exp.rec.br); Storage para anexos; Edge Functions; Vault para tokens. |
| Apps Script | Só para integrações Google (ex.: exportar planilha para Sheets). |
| Pagamentos | **Fora do MVP.** A EXP já tem um sistema de pagamentos em Apps Script. A aba aparece desabilitada ("em breve") e no fim dos menus. No banco há só `pagamento_ref_externa`. Tentativa de iframe foi descartada (exige `setXFrameOptionsMode(ALLOWALL)` e há problemas de login/cookie). |
| Asana | Integração **por usuário**. Painel com cartões "Tarefas para hoje", "Tarefas atrasadas", "Na sua fila". Token no Vault, lido só por Edge Function. |
| Layout | **Desktop primeiro**. Responsividade/celular fica para depois (o uso principal será celular, mas não agora). |
| Visual | Dark mode. Fonte Inter. Dois temas selecionáveis (ver Design). |
| Datas | Evento tem **dia 0** (`data_evento`). Cronograma e prazos guardam **dia relativo** (D-x / D+x). Mudou a data do evento, tudo acompanha. |
| Cronograma | Por **setor** (Portaria, Palco, VIP…, ordem livre) × dia × **período** (manhã, tarde, noite) × **fase** (M montagem, O operação, D desmontagem). **Só estruturas**; Staff vai para a futura aba Mão de obra. Linha pode abrir as linhas da memória. Linha de marcos no topo (documentos, passagem de som, show). |
| Checklist de telas | Ao criar evento escolhe-se quais telas ele terá (`evento_modulos`). Desligar só esconde, não apaga. Visão geral e Planilha são fixas. |
| Memórias | Cada uma tem tabela própria; o banco calcula; **só o resultado sobe** para o item da planilha. |
| Dimensionamento | Pelo público, sempre arredondando para cima: baias 1/250, banheiros 1/80, seguranças 1/100, bar 1 m/100. Parâmetros editáveis (`parametros_dimensionamento`). |
| Painel | Frase do dia aleatória e divertida; "Pontos de atenção" (não "Atenção"); seção Asana; Próximos eventos com "Entrar no evento". |

## Design

Tokens (o protótipo usa um mapeamento automático `--xHEX`; no app real use tokens semânticos como abaixo):

| Token | Roxo (padrão) | Verde |
|---|---|---|
| `--bg` | `#121016` | `#212121` |
| `--surface` | `#1c1922` | `#2a2a2a` |
| `--surface-2` | `#26222e` | `#333333` |
| `--border` | `#352f40` | `#404040` |
| `--border-strong` | `#4a4256` | `#525252` |
| `--text` | `#f3f3f3` | `#f3f3f3` |
| `--muted` | `#8d8698` | `#8f8f8f` |
| `--muted-2` | `#b3adbd` | `#b5b5b5` |
| `--primary` | `#6b3e92` | `#1db954` |
| `--on-primary` | `#ffffff` | `#0d0d0d` (texto escuro sobre o verde) |
| `--secondary` | `#f1613a` | `#ffffff` |
| `--link` | `#d2b4f5` | `#baefcd` |
| `--active-bg` | `#2e2340` | `#2a4c36` |
| `--ok` / `--warn` / `--danger` | `#7fe0a6` / `#f5c26b` / `#ff9a85` | iguais |

- Tema salvo por usuário no navegador (`localStorage` chave `backstage-tema`, atributo `data-tema` no `<html>`); seletor no fim do menu lateral e no login.
- Menu lateral: Painel, Eventos · seção Empresa (Estoque, Cadastros) · Asana conectado · Tema · Sair. Dentro do evento, submenu com as abas; a Planilha tem submenu com as 10 memórias.
- Abas do evento: Visão geral, Planilha de trabalho, Cronograma, Artístico, Documentação, Pagamentos (desabilitada, última).
- Tabelas de memória funcionam como Excel: Enter cria a próxima linha, Tab avança, colar várias linhas do Excel; última linha vazia = inclusão rápida; "+ Novo item" abre janela.

## Banco v0.3 (resumo)

Arquivo: `supabase/migrations/20261126000000_schema_v0_3.sql` (fonte da verdade) e `supabase/seed.sql` (EXP Produções, 8 categorias,
60 itens do catálogo, parâmetros de dimensionamento, tipos de documento CEMIG/AVCB/CODAU/Alvará, frases do dia).
41 tabelas, 6 visões, 16 listas fixas (enums), 12 gatilhos.

- `usuarios.id` = `auth.users.id` (uuid). Demais tabelas: `bigint identity`. Tudo com `empresa_id` (multiempresa/filiais).
- `catalogo_itens.tipo_memoria` define qual memória o item usa; gatilho copia para `planilha_itens`.
- Memórias `mem_*` ligadas ao item por FK composta `(planilha_item_id, evento_id, tipo_memoria)` → impossível lançar linha de piso num item de gradil. Setor por FK composta `(setor_id, evento_id)`.
- Fórmulas (colunas geradas):
  - Piso e fechamentos: área só para piso/escada/arquibancada/rampa; metragem linear só para fechamento (CHECKs); valor = unitário × área (ou × ML).
  - Gradil e tendas: tendas m² = qtd × larg × compr (só tenda); lonas m² = qtd × larg × 2,70 (só fechamento em lona); gradil ML = qtd × 2 (só gradil); valor = medida × unitário (tenda e balcão = qtd × unitário).
  - Com. visual m² = L × A (valor digitado); Forração total = m² × preço × qtd; Cenografia total = preço × qtd, `acima_do_teto`; Banheiro total = qtd + PNE; LED m² = L × A.
- `v_memoria_resultado` → `v_planilha`: memória com R$ dá o valor; memória sem R$ dá a quantidade (valor = qtd × freq × unitário); sem memória, tudo digitado.
- Cronograma: `cronograma_linhas` + `cronograma_marcacoes (dia_relativo, periodo, fase)`; gatilho recusa categoria com `entra_no_cronograma = false`. Visões `v_cronograma` (data real) e `v_cronograma_marcos`.
- Gatilho `fn_evento_criado`: liga telas fixas e põe o criador na equipe. Documentos padrão só nascem quando a tela
  Documentação é ligada (gatilho `fn_documentacao_ligada`, migration 2).
- `fn_criar_evento(p_evento, p_modulos, p_equipe)`: cria evento + checklist + equipe numa transação (tela Novo evento).
- `historico` registra alterações de eventos, planilha, documentos e telas.
- **RLS**: `fn_minha_empresa()`, `fn_sou_admin()` (papel gestor ou planejamento), `fn_acesso_evento(evento)` (admin ou na equipe).
  Admin vê/edita tudo; demais só eventos em que estão na equipe; checklist, criar/excluir evento e cadastros só admin.
- Testes: `supabase/tests/` (rodar num Postgres local com o stub de `auth`). Todos passaram na v0.3.
- Ainda não existe: bucket do Storage para anexos (criar `anexos`, privado, com políticas por evento) e Edge Function do Asana.

Regras: nunca edite uma migration já aplicada; crie outra. Nomes em português, snake_case, sem acento no banco.

## Primeira versão (proposta aceita para começar)

1. Configuração (com o Della, ver README): repositório GitHub, projeto Supabase (região São Paulo), login Google restrito a exp.rec.br, Cloudflare Pages ligado ao repo.
2. Aplicar schema + seed; cadastrar o Della como primeiro usuário (SQL no README).
3. Telas, nesta ordem: Login (Google) → Painel (sem Asana ainda) → Eventos → Criar evento (assistente + checklist, **tela ainda não desenhada: proponha antes**) → Visão geral com dimensionamento → Planilha de trabalho com Adicionar itens do catálogo e Detalhe do item → memórias **Piso e fechamentos** e **Gradil e tendas**.
4. Depois: demais memórias, Cronograma, Documentação, Artístico, Conferência, Estoque, Cadastros, Asana.

Use `prototipo/*.html` como referência visual exata e `docs/telas.md` como especificação de cada tela.
Não copie restos de pagamentos do protótipo (ver pendências).

## Estrutura sugerida

```
/app/             o sistema publicado (Cloudflare Pages usa só esta pasta)
  index.html      login; demais páginas .html ao lado
  css/            tokens.css (temas), base.css, componentes
  js/             supabase.js (cliente), auth.js, tema.js, um arquivo por tela
/supabase/        migrations/, seed.sql, tests/, functions/ (Edge Functions)
/docs/            especificações (telas, casos de uso, permissões, pendências) e o PDF
/prototipo/       protótipo de referência (não publicar; o botão "Comentar" só funciona na versão online)
/referencia/      planilha original da EXP
```

Chaves: a `anon key` e a URL do Supabase podem ir no front (a segurança está no RLS). **Nunca** commitar `service_role`, tokens do Asana ou `.env`.

## Pendências principais (detalhes em docs/pendencias.md)

1. Tipos de atração (artístico, staff, fornecedor, esportivo) — a confirmar.
2. "Preço Duzão" da Cenografia = teto orçamentário? 3. Regra do valor total em Gradil e tendas.
4. Quantidade que sobe: Piso (só área), Gradil (só m² de tenda), Mesas e cadeiras (soma) — confirmar.
5. Só gestor/planejamento ligam telas do evento — confirmar.
6. Restos de pagamento nas telas do protótipo (Painel, Eventos, Visão geral, Planilha, Detalhe do item, Artístico, Cadastros).
7. Catálogo: trocar modelos antigos (piso, tenda, box, elétrica) pelos 10 tipos; Pisos + Fechamentos = 1 item.
8. Setor nas memórias deve ser lista dos setores do evento.
9. **Permissões**: hoje membros gerenciam a equipe e apagam itens; `modelo_modulos` pode ser apagado por qualquer usuário (falta trava no DELETE); estoque aberto a todos; usuário não edita o próprio perfil; perfis iguais para todos os papéis não-admin.
10. Botões "+ Cadastrar fornecedor" e "Cadastrar novo item" aparecem para quem o banco bloqueia.
11. Estoque: saída deve baixar a reserva? 12. ~~Filtro de status em Eventos~~ feito.
13. ~~Login por e-mail e senha~~ decidido: só Google. 14. Telas a desenhar: Editar evento, Conectar Asana, Cadastros (catálogo, hotéis, usuários), Configurações, Histórico, Mão de obra, celular.

## Histórico das versões do banco

- v0.1: modelo inicial a partir do desenho de indexação do Della (eventos, planilha, item_detalhes genérico com JSONB, cronograma).
- v0.2: controle de pagamentos (tabela de parcelas no eixo do evento, visões de fluxo) — **pausado** depois.
- v0.3 (atual): login Supabase + RLS, checklist de telas, setores, 10 memórias tipadas, cronograma por período, dimensionamento,
  conferência, anexos, histórico, pagamentos como referência externa, Asana via Vault.

## Links (claude.ai)

- Protótipo navegável (com "Comentar" e mapa do banco): https://claude.ai/artifact/C4QrBgZ2pkFH6iL799svZx
- Mapa interativo do banco (avulso): https://claude.ai/artifact/4iquUTwFKxiP4N7CAUfmdk
- Wireframes (canvas de design): https://claude.ai/artifact/9oywfGA3ccdMiKqTzZbiaB
- Apresentação v1 para a diretoria: https://claude.ai/artifact/53YPWkzZ7tQ5iwaoysiT7p
- Modelo de dados v0.2 (desatualizado): https://claude.ai/artifact/8Ltf2F6jZxNrKhUprbDR9u
- Sistema de pagamentos atual da EXP (Apps Script): https://script.google.com/a/macros/exp.rec.br/s/AKfycbyA5R6H9rPgSjq2WiKiHLlW2pMHid-fFM11Eq_SaurpP196nnfWoj7r2O4ZLe-i_O92/exec
