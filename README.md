# Backstage

Sistema de controle e gestão de eventos da EXP Produções.
Contexto completo para o Claude Code: **CLAUDE.md**. Especificações: **docs/**.

## Como continuar no Claude Code

1. Abra esta pasta no Claude Code (app desktop → Code → escolher a pasta, ou no terminal: `cd` até aqui e rode `claude`).
2. Primeira mensagem sugerida:

   > Leia o CLAUDE.md e os arquivos de docs/. Depois me guie na configuração das contas (GitHub, Supabase, Google, Cloudflare)
   > e comece a primeira versão pela tela de login.

## Configuração das contas (uma vez só)

### 1. GitHub
- Crie um repositório **privado** chamado `backstage` (ou peça ao Claude Code: ele faz `git init` e o primeiro push).

### 2. Supabase
- Em supabase.com, crie um projeto (região **South America (São Paulo)**). Guarde a senha do banco.
- Em **SQL Editor**, rode nesta ordem:
  1. `supabase/migrations/20261126000000_schema_v0_3.sql`
  2. `supabase/seed.sql`
- Em **Project Settings → API**, copie a **Project URL** e a **anon public key** para `app/js/config.js`.
  A `service_role` key **nunca** vai para o código nem para o GitHub.
- Alternativa pelo terminal: instalar a Supabase CLI, `supabase link` e `supabase db push`.

### 3. Login Google (conta da EXP)
- No Google Cloud Console (com a conta da EXP): crie um projeto → **Google Auth Platform / Tela de consentimento OAuth**
  como **Interno** (só contas exp.rec.br) → **Credenciais → ID do cliente OAuth → Aplicativo da Web**.
- URI de redirecionamento autorizado: `https://<seu-projeto>.supabase.co/auth/v1/callback`
- No Supabase: **Authentication → Sign In / Providers → Google**: cole o Client ID e o Client Secret e ative.
- Em **Authentication → URL Configuration**: Site URL = endereço do Cloudflare Pages; em **Redirect URLs** adicione
  `https://<seu-site>.pages.dev/**` e `http://localhost:5500/**` (servidor local de testes).

### Testar no computador
Servidor local: `npx http-server app -p 5500 -c-1` e abrir `http://localhost:5500`.

### 4. Primeiro usuário
Depois de entrar uma vez com o Google (o login cria a conta em `auth.users`), rode no SQL Editor trocando o e-mail:

```sql
INSERT INTO usuarios (id, empresa_id, nome, email, papel)
SELECT u.id, e.id, 'Della', u.email, 'gestor'
FROM auth.users u, empresas e
WHERE u.email = 'seu-email@exp.rec.br' AND e.nome = 'EXP Produções';
```

Os próximos usuários serão cadastrados pela tela de Cadastros → Usuários (a construir).

### 5. Cloudflare Pages
- **Workers & Pages → Create → Pages → Connect to Git** → escolha o repositório.
- Framework: **None**. Comando de build: **vazio**. Pasta de saída: **`app`**.
- Cada push na branch principal publica sozinho.

## Testes do banco
`supabase/tests/`: `stub.sql` simula o `auth` do Supabase num PostgreSQL local; `test.sql` cria um evento de exemplo e confere
cálculos e permissões; `fail.sql` confere que as regras barram o que devem barrar.
Ordem: stub → migration → seed → test → fail.
