# SplitMarket

Aplicativo Flutter desenvolvido para gerenciamento e divisão de despesas em grupo, permitindo o controle compartilhado de gastos de forma simples, organizada e acessível.

---

# 📱 Sobre o Projeto

O SplitMarket foi desenvolvido utilizando Flutter e segue uma arquitetura organizada em camadas, promovendo reutilização de componentes, escalabilidade e padronização visual.

O projeto conta com:
- gerenciamento de despesas;
- organização por grupos;
- componentes reutilizáveis;
- suporte a tema claro e escuro;
- arquitetura baseada em features;
- utilização de Design Tokens.

---

# 🎨 Design Tokens

O SplitMarket utiliza Design Tokens para centralizar e padronizar os estilos visuais da aplicação, garantindo consistência entre componentes e facilitando a manutenção da interface.

Os tokens foram organizados na pasta:

```txt
lib/core/themes/
```

---

# 📁 Estrutura dos Tokens

| Arquivo | Responsabilidade |
|---|---|
| `app_colors.dart` | Centraliza as cores da aplicação |
| `app_spacing.dart` | Define espaçamentos reutilizáveis |
| `app_text_styles.dart` | Padroniza estilos tipográficos |
| `app_theme.dart` | Configura os temas globais |
| `theme_notifier.dart` | Gerencia alternância de temas |

---

# 🎨 Paleta de Cores

As cores principais do aplicativo foram definidas em:

```txt
app_colors.dart
```

| Token | Valor |
|---|---|
| `primary` | `#8E76F7` |
| `lightBackground` | `#F5F5F5` |
| `darkBackground` | `#121212` |

Essas cores são reutilizadas em toda a aplicação para manter a identidade visual padronizada.

---

# 🌙 Sistema de Temas

O projeto possui suporte para:
- Tema Claro
- Tema Escuro

Os temas são definidos em:

```txt
app_theme.dart
```

e controlados dinamicamente através de:

```txt
theme_notifier.dart
```

O gerenciamento utiliza `ChangeNotifier`, permitindo atualização automática da interface ao alterar o tema da aplicação.

---

# ✍️ Tipografia

Os estilos tipográficos são centralizados em:

```txt
app_text_styles.dart
```

Garantindo:
- padronização visual;
- reutilização de estilos;
- manutenção simplificada.

---

# 📏 Espaçamentos

Os espaçamentos globais são definidos em:

```txt
app_spacing.dart
```

Isso permite:
- alinhamento consistente;
- melhor organização visual;
- reutilização entre componentes.

---

# 🧩 Estrutura do Projeto

```txt
lib/
 ├── core/
 │    ├── database/
 │    ├── services/
 │    └── themes/
 │
 ├── features/
 ├── models/
 ├── services/
 ├── viewmodels/
 ├── views/
 ├── widgets/
 └── main.dart
```

---

# 🚀 Benefícios da Utilização de Design Tokens

- padronização da interface;
- reutilização de componentes;
- escalabilidade do projeto;
- manutenção simplificada;
- colaboração eficiente entre os membros da equipe.

---

# 🛠️ Tecnologias Utilizadas

- Flutter
- Dart
- Provider
- ChangeNotifier

---

# ▶️ Como Executar o Projeto

Clone o repositório:

```bash
git clone URL_DO_REPOSITORIO
```

Acesse a pasta:

```bash
cd splitmarket
```

Instale as dependências:

```bash
flutter pub get
```

Execute o projeto:

```bash
flutter run -d chrome
```

---

# 👥 Equipe

Projeto desenvolvido em equipe para fins acadêmicos e aprendizado em desenvolvimento mobile utilizando Flutter.