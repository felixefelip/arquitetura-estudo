# Frontend Rails com View Components

Este projeto foi migrado de Angular para Rails utilizando View Components, aproveitando os controllers existentes nas engines.

## Arquitetura Implementada

### Controllers das Engines

Os controllers das engines foram adaptados para responder tanto a requisições JSON (API) quanto HTML, seguindo o padrão RESTful do Rails:

1. **Academico::LoginController** (`engines/academico/app/controllers/academico/login_controller.rb`)
   - `GET /academico/login/new` - Exibe formulário de login (HTML)
   - `POST /academico/login` - Processa login (action `create`)
   - `DELETE /academico/login` - Realiza logout (action `destroy`)

2. **Academico::CursosController** (`engines/academico/app/controllers/academico/cursos_controller.rb`)
   - `GET /academico/cursos` - Lista cursos (action `index`)
   - `PATCH /academico/cursos/:id` - Atualiza curso (action `update`)
   - `PATCH /academico/cursos/:id/assistir` - Marca curso como assistido (action customizada)

3. **Marketing::LeadsController** (`engines/marketing/app/controllers/marketing/leads_controller.rb`)
   - `GET /marketing/leads/new` - Exibe formulário de compra (action `new`)
   - `POST /marketing/leads` - Cria lead/compra (action `create`)
   - `GET /marketing/leads/sucesso` - Página de sucesso (action customizada)

4. **Academico::AlunosController** (`engines/academico/app/controllers/academico/alunos_controller.rb`)
   - API REST completa para alunos (JSON)

5. **Finance::ClientsController** (`engines/finance/app/controllers/finance/clients_controller.rb`)
   - `POST /finance/clients` - Cria cliente (API JSON)

### View Components Criados

Os componentes foram criados usando a gem `view_component` e estão em `app/components/`:

1. **HeaderComponent** - Cabeçalho reutilizável com logo e informações do usuário
2. **LoginFormComponent** - Formulário de login com validações
3. **CompraFormComponent** - Formulário multi-step para compra (dados pessoais + pagamento)
4. **CursoCardComponent** - Card individual de curso com botão de ação

### Views das Engines

As views foram criadas dentro das respectivas engines:

- `engines/academico/app/views/academico/login/new.html.erb`
- `engines/academico/app/views/academico/cursos/index.html.erb`
- `engines/marketing/app/views/marketing/leads/new.html.erb`
- `engines/marketing/app/views/marketing/leads/sucesso.html.erb`

### Rotas

O arquivo `config/routes.rb` segue o padrão RESTful do Rails usando `resources`:

```ruby
Rails.application.routes.draw do
  # Rota raiz
  root "marketing/leads#new"

  # Namespace Marketing
  namespace :marketing do
    resources :leads, only: [:new, :create] do
      collection do
        get :sucesso
      end
    end
  end

  # Namespace Academico
  namespace :academico do
    resources :alunos  # API REST completa

    resources :cursos, only: [:index, :update] do
      member do
        patch :assistir
      end
    end

    resource :login, only: [:new, :create, :destroy]
  end

  # Namespace Finance
  namespace :finance do
    resources :clients, only: [:create]  # API
  end
end
```

**Principais rotas geradas:**
- `GET /marketing/leads/new` → Formulário de compra
- `POST /marketing/leads` → Criar lead
- `GET /marketing/leads/sucesso` → Página de sucesso
- `GET /academico/login/new` → Formulário de login
- `POST /academico/login` → Processar login
- `DELETE /academico/login` → Logout
- `GET /academico/cursos` → Lista de cursos
- `PATCH /academico/cursos/:id` → Atualizar curso
- `PATCH /academico/cursos/:id/assistir` → Marcar como assistido

### Estilos

Os estilos CSS foram criados em `app/assets/stylesheets/components.css` com design responsivo baseado no layout original do Angular.

## Funcionalidades Implementadas

### 1. Página de Login
- Formulário com campos de e-mail e senha
- Validação de campos obrigatórios
- Mensagens de erro para credenciais inválidas
- Armazenamento de sessão do usuário

### 2. Página de Compra
- Formulário multi-step (dados pessoais → pagamento)
- Validação de campos (CPF, cartão, CVV)
- Resumo da compra no lado direito
- Navegação entre steps com validação

### 3. Página de Cursos (Área Logada)
- Header com nome do usuário e botão de logout
- Lista de cursos disponíveis
- Botão para marcar curso como assistido
- Proteção de autenticação

### 4. Página de Sucesso
- Confirmação visual de compra realizada
- Link para acessar os cursos

## Padrão RESTful

A aplicação segue o padrão RESTful do Rails:

- **Recursos (Resources)**: Uso consistente de `resources` e `resource` para definir rotas
- **Actions Padrão**: `new`, `create`, `index`, `show`, `update`, `destroy`
- **Actions Customizadas**: Usando `member` e `collection` quando necessário
- **Namespaces**: Organização lógica por contexto (marketing, academico, finance)
- **Named Routes**: Helpers de rota gerados automaticamente (ex: `new_academico_login_path`)

## Compatibilidade com API

Os controllers de API (`AlunosController`, `ClientsController`) respondem com JSON, enquanto os controllers de UI respondem com HTML. A separação é feita por namespace e propósito do controller.

## Sessão e Autenticação

O sistema de autenticação utiliza sessões Rails:
- Login armazena `user_id`, `user_name` e `user_email` na sessão
- Logout limpa a sessão
- Verificação de autenticação para rotas protegidas

## ApplicationController

Foi modificado de `ActionController::API` para `ActionController::Base` com proteção CSRF inteligente:

```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, if: :json_request?
end
```

Isso mantém a segurança para formulários HTML mas permite requisições JSON sem token CSRF.

## Como Testar

1. Iniciar o servidor Rails:
```bash
bin/rails server
```

2. Acessar as páginas:
- `/` - Página inicial (redireciona para compra)
- `/marketing/leads/new` - Página de compra
- `/academico/login/new` - Página de login
- `/academico/cursos` - Página de cursos (requer login)

3. Verificar rotas disponíveis:
```bash
bin/rails routes
```

## Melhorias Futuras

- [ ] Adicionar testes RSpec para os componentes
- [ ] Implementar autenticação real com senha (bcrypt já está no Gemfile)
- [ ] Adicionar validações server-side mais robustas
- [ ] Implementar paginação na lista de cursos
- [ ] Adicionar filtros e busca de cursos
- [ ] Melhorar acessibilidade (ARIA labels)
- [ ] Adicionar testes de integração com Capybara
