# DomPet Frontend

Uma loja virtual de petshop feita em Flutter (Web/Mobile) com foco em performance, responsividade real e UX sólida.

## ✨ Principais recursos
- Design System leve com tokens (espaçamentos, raios, durações) e tema Material 3 claro/escuro
- Layout responsivo de verdade (breakpoints, largura máxima, grid adaptativo)
- Catálogo com busca, filtro por categorias e paginação
- Card do produto sem overflow (imagens proporcionais, textos com ellipsis)
- Detalhe do produto com ação de adicionar ao carrinho
- Carrinho com badge, incremento otimista e "Limpar carrinho" com confirmação
- Carrossel de destaques (aparece em telas médias+)
- Fluxos de login/registro, checkout e pedidos
- Página de perfil do usuário (rota protegida)

## 🗺️ Rotas principais
- `/` Home (lista e busca de produtos)
- `/produto/:id` Detalhe do produto
- `/cart` Carrinho
- `/checkout` Checkout (protegida)
- `/pedidos` e `/pedidos/:id` (protegidas)
- `/perfil` Página de perfil (protegida)
- `/login`, `/register`, `/splash`

## 🏗️ Arquitetura e pastas
```
lib/
  src/
    app.dart                -> Raiz do app (MaterialApp.router)
    router.dart             -> GoRouter com rotas e redirects

    core/
      http/                 -> Dio + interceptors (auth/refresh, headers, etc.)

    features/
      products/             -> Lista, detalhe, serviço (Dio) e providers
      cart/                 -> Serviço/controlador do carrinho e providers
      orders/               -> Checkout, pedidos e detalhe de pedido
      auth/                 -> Login/registro/session provider
      profile/              -> Página de perfil (consome /usuarios/me)
      home/widgets/         -> Featured carousel

  ui/
    design_system.dart      -> Tokens, breakpoints, temas (claro/escuro)
    widgets/
      responsive_scaffold.dart -> Scaffold responsivo com AppBar + Drawer

  shared/
    models/                 -> Tipos comuns (Produto, PageResult, etc.)
```

## 🎨 Design System
- Breakpoints (`AppBreakpoints`): xs, sm, md, lg, xl
- Largura máxima de conteúdo (`maxContentWidth`): mantém o conteúdo centralizado em telas grandes
- `ResponsiveScaffold`: aplica paddings por breakpoint, AppBar com badge do carrinho e Drawer em telas estreitas
- Botões com tamanhos confortáveis (evita “botão esticado”)

Dicas:
- Use `gridCrossAxisCountFor(width)` para definir colunas por breakpoint.
- Prefira `appPaddingFor(width)` para paddings coerentes com o DS.

## 🔌 Backend e API
Este frontend consome o backend Spring Boot (DomPet). Endpoints usados (principais):
- `GET /produtos/search` (q, categoria, page, size)
- `GET /produtos/{id}`
- `GET /produtos/categorias`
- `POST /cart` e correlatos (dependendo da sua API de carrinho)
- `GET /usuarios/me` (rota protegida por JWT)

### Base URL da API
O cliente Dio (em `lib/src/core/http/api_client.dart`) centraliza a `baseUrl` e os interceptors. Se precisar apontar para outro host/porta, altere lá a constante/configuração da `baseUrl`.

Para Android emulador, a convenção é `http://10.0.2.2:8080`. Para Web/desktop, normalmente `http://localhost:8080`.

## ▶️ Como rodar
Pré-requisitos: Flutter 3.22+ e Dart 3.4+.

- Instale dependências:
```powershell
flutter pub get
```

- Rodar no Chrome (Web):
```powershell
flutter run -d chrome
```

- Rodar no Android Emulator:
```powershell
flutter run -d emulator-5554
```
Obs.: Ajuste o device conforme o nome do seu emulador. Garanta que a `baseUrl` aponte para `10.0.2.2` no Android.

- Build Web (produção):
```powershell
flutter build web --release
```
Saída em `build/web/`.

## 🧪 Testes e qualidade
- Análise estática:
```powershell
flutter analyze
```

- Rodar todos os testes:
```powershell
flutter test -r compact
```

- Rodar um teste específico:
```powershell
flutter test test/features/products/products_list_widget_test.dart -r compact
```

Notas:
- Os testes de widget não devem depender da rede; o catálogo e categorias são providos por camadas isoladas. Se você adicionar novos widgets com chamadas HTTP no build, isole-os por features/flags ou injete mocks.

## 🛒 UX do carrinho
- Botão “Adicionar” faz incremento otimista (badge atualiza instantaneamente)
- Mensagens de feedback via SnackBar
- Ação “Limpar carrinho” com confirmação
- Conflitos de estoque (409) são tratados com mensagem clara ao usuário

## 🧭 Navegação
- `GoRouter` com redirects simples para rotas protegidas
- Acesso rápido ao Perfil pelo ícone no AppBar e pelo Drawer

## 🐛 Troubleshooting
- Imagem estourando/overflow no card:
  - Os cards usam imagem dentro de `Expanded` e textos com `maxLines + ellipsis`. Se adicionar campos, mantenha essa regra para evitar `RenderFlex overflow`.
- API não responde no Android emulador:
  - Verifique se a `baseUrl` aponta para `http://10.0.2.2:8080` (não `localhost`).
- CORS no Web:
  - Garanta que o backend exponha os headers necessários e permita o origin do seu host local.

## 📦 Dependências-chave
- dio, hooks_riverpod, flutter_hooks, go_router
- freezed/json_serializable (modelagem), shared_preferences/flutter_secure_storage
- carousel_slider (carrossel de destaques)

## 📝 Scripts úteis
Você pode criar tasks no VS Code para:
- `flutter analyze`
- `flutter test -r compact`
- `flutter run -d chrome`

## 📣 Contribuindo
- Siga os padrões do Design System e dos breakpoints
- Inclua testes para novas features públicas
- Evite dependências de rede em testes de widget; injete providers/mocks

---
Feito com Flutter ❤️ para a DomPet. Se precisar, abra um issue ou peça por novas seções neste README.
# DomPet App (Flutter)

App mobile Flutter (3.22+/Dart 3.4+) para consumir a API DomPet.

Stack principal
- HTTP: dio (+ interceptors de Authorization, Refresh, X-API-Version e ETag)
- Estado/DI: hooks_riverpod
- Roteamento: go_router
- Modelagem/JSON: freezed + json_serializable
- Storage: flutter_secure_storage (token) e shared_preferences (carrinho local e cache simples ETag)
- UI: Material 3 (tema claro/escuro), responsiva
- Testes: flutter_test + mocktail
- Lint: flutter_lints

Arquitetura (feature-first)
- lib/src/core/config: AppConfig (baseUrl, flavors dev/prod), apiVersionProvider (header X-API-Version)
- lib/src/core/http: Dio client + interceptors (auth/refresh, ETag/If-None-Match, ProblemDetail)
- lib/src/core/auth: Session (token + expiresAt) + SessionNotifier
- lib/src/features/auth: páginas (Login/Register) + AuthService
- lib/src/features/products: service (list/search/suggestions/detalhe) + pages (Home, Detalhe)
- lib/src/features/cart: carrinho local (shared_preferences), serviço remoto, merge pós-login, página
- lib/src/features/orders: checkout, listagem e detalhe
- lib/src/shared/models: Freezed models (Produtos, Carrinho, Pedido, EnderecoDto, AuthResponse, PageResult)

Como configurar baseUrl (dev/prod)
- Ponto único: lib/src/core/config/app_config.dart
- Por padrão: BASE_URL = http://localhost:8080, FLAVOR = dev
- Use --dart-define para sobrescrever por ambiente
  - Android emulador: http://10.0.2.2:8080
  - iOS simulator: http://127.0.0.1:8080

Exemplos de execução
```bash
# 1) Instale dependências
flutter pub get

# 2) Gere os modelos (freezed/json)
flutter pub run build_runner build -d

# 3) Rodar no emulador Android apontando para API local
flutter run --dart-define=BASE_URL=http://10.0.2.2:8080 --dart-define=FLAVOR=dev

# iOS (simulador)
flutter run -d ios --dart-define=BASE_URL=http://127.0.0.1:8080 --dart-define=FLAVOR=dev
```

Rotas principais (go_router)
- /splash: verifica sessão e roteia
- /login, /register
- /: Home com catálogo (search + categorias)
- /produto/:id: detalhe (usa ETag If-None-Match)
- /cart: carrinho (local pré-login, remoto pós-login)
- /checkout: protegido por auth
- /pedidos, /pedidos/:id: protegido por auth

Fluxos e regras de negócio
- Autenticação
  - Login/Register: POST /auth/login|register → salva sessão (token + expiresAt) no secure storage
  - Refresh automático: se faltar menos de 2 minutos para expirar, /auth/refresh e reenvia request
  - Em 401: limpa sessão e redireciona ao login
- Carrinho
  - Antes do login: mantido em shared_preferences
  - Após login/cadastro: merge com remoto
    1) GET /cart
    2) POST /cart/items para cada item local; se 409 (estoque), ajusta qty pelo estoque atual do produto e informa
    3) Limpa carrinho local
- Produtos
  - Home usa /produtos/search (Page do Spring) e /produtos/categorias
  - Detalhe usa ETag: If-None-Match; em 304, usa cache local (SharedPreferences)
- Pedidos
  - Checkout: POST /pedidos/checkout com EnderecoDto
  - Listagem e detalhe de pedidos contendo itens e total

Tratamento de erros (ProblemDetail RFC 7807)
- Interceptor converte respostas de erro da API em ProblemDetail (title, detail, status, errors[])
- Mensagens amigáveis podem ser exibidas via toString() do ProblemDetail

Testes
```bash
# Geração de código necessária antes dos testes
flutter pub run build_runner build -d

# Rodar todos os testes
flutter test
```
Cobertura de testes incluída
- Unit: interceptor de refresh (expiração próxima → chama refresh e reenvia request)
- Unit: merge de carrinho local com remoto (inclui caso 409 ajustando qty)
- Widget: lista de produtos via /produtos/search (Dio mockado por HttpClientAdapter fake)

Notas sobre ETag
- O interceptor adiciona If-None-Match para GET /produtos/{id} quando há etag em cache (SharedPreferences)
- Em 304, serve a resposta do cache e retorna 200 para a UI

Dicas de troubleshooting
- 401 após login/refresh
  - Verifique se BASE_URL aponta para a API correta
  - Se o backend trocou secret/tokenVersion, os tokens existentes ficam inválidos → limpe sessão e logue novamente
- 409 em /cart/items
  - Estoque insuficiente: o app ajusta a quantidade durante o merge e informa o usuário
  - Tente novamente com menor quantidade

Estrutura de diretórios
```
lib/
  main.dart
  src/
    app.dart
    router.dart
    core/
      config/
      http/
      auth/
    features/
      auth/
      products/
      cart/
      orders/
    shared/
      models/
      splash_page.dart
```

Onde alterar baseUrl/flavor
- lib/src/core/config/app_config.dart (comentários apontam como usar --dart-define)

Observações
- Pagamentos: não implementados
- UI: Material 3 com tema claro/escuro
- Código com null-safety, forte tipagem, pequenos widgets reutilizáveis
- Sem chamadas reais de rede nos testes (Dio mockado)
