# myFeed — Modo Carreira Mobile 📱🏆

**myFeed** é um aplicativo mobile premium projetado para entusiastas de jogos de simulação (Modo Carreira) e criadores de conteúdo esportivo. Ele permite que os usuários gerenciem notícias, criem competições, acompanhem resultados de partidas detalhadas, gerenciem elencos de clubes personalizados e exportem/importem seus dados com facilidade.

A aplicação conta com uma interface moderna no estilo AMOLED Dark, com efeitos de desfoque translúcido (Glassmorphism), transições fluidas e um design de ponta.



## 🚀 Principais Funcionalidades

![](https://github.com/xkjhon/myFeed/blob/master/web/my.png)

### 📰 1. Feed Personalizado Dinâmico (myFeed)
* **Visualização Unificada**: Um feed responsivo contendo os 3 últimos jogos e as 3 últimas notícias em destaque.
* **Filtros Flutuantes**: Toque em "myFeed" para abrir um menu suspenso animado com efeito blur que filtra instantaneamente por "Jogos" ou "Notícias".
* **Navegação Inteligente**: Botão "Ver Mais" que direciona para as respectivas páginas dedicadas com listagens completas.

### ⚽ 2. Detalhes de Partidas & Ficha do Jogo
* **Status Dinâmico**: O cabeçalho exibe automaticamente **"ÚLTIMO JOGO"** (para a partida mais recente) ou **"JOGO"** (para partidas mais antigas).
* **Pílula de Placar no Scroll**: Ao rolar a tela de detalhes para baixo, o título do cabeçalho dá lugar a uma pílula central flutuante compacta contendo os escudos dos dois times e o placar, garantindo legibilidade permanente.
* **Seção de MVP (Melhor em Campo)**: Exibição imersiva com degradê de contraste escuro, trazendo o jogador destacado à esquerda com nome estilizado em fonte grande ao fundo, e informações estatísticas à direita.
* **Cronologia**: Histórico de gols, cartões e substituições exibidos de forma linear.

### 📝 3. Publicações de Notícias
* **Visual Premium**: Layout no formato de capa revista onde a imagem principal flutua até o topo da tela, passando por trás da barra de status do celular com degradê de transição para contraste ideal.
* **Leitura Confortável**: Tipografia refinada (via Google Fonts) com espaçamento de linha otimizado para legibilidade mobile.

### 🛠️ 4. Painel de Criação e Configurações (Centralizado na Engrenagem)
* **Criação de Times**:
  * **Organização por País**: Clubes são agrupados em ordem alfabética por país (ex: `BRASIL | Flamengo`), facilitando a seleção nos formulários.
  * **Seletor de Espectro de Cores (HSV)**: Criação cromática sem limites. Substituído o bloco de cores fixas por um seletor completo de espectro de matizes.
* **Corte Interativo de Imagens (`CropDialog`)**:
  * Desenvolvido um componente de recorte visual nativo. O usuário pode ajustar e redimensionar a área de recorte diretamente na tela antes de salvar as imagens do MVP, notícias ou brasões de times.
* **Prevenção de Overflows**:
  * Telas de formulários ajustadas com elementos flexíveis (`Expanded`/`Flexible`), evitando barras verticais de erros de layout mesmo em celulares pequenos.

### 💾 5. Importação e Exportação de Backup
* Sistema completo que gera um arquivo `.json` criptografado contendo todos os dados do banco de dados local.
* Permite exportar e compartilhar o arquivo (por WhatsApp, Email, etc.) e restaurá-lo em qualquer outro aparelho que rode o **myFeed**.

---

## 🛠️ Arquitetura & Tecnologias Utilizadas

* **Framework**: Flutter (Dart) com suporte a Material Design 3.
* **Armazenamento Local**: Hive (banco de dados NoSQL ultra-rápido, baseado em chave-valor, ideal para persistência de dados local offline).
* **Processamento de Imagens**:
  * **Flicker-Free Base64 Image Cache**: Sistema de cache estático de memória (`_base64Cache`) no widget `AppImage` para otimizar o processamento de imagens convertidas em texto, eliminando 100% dos travamentos e piscadas de tela durante o scroll.
* **Layouts Animados & Carregamento**:
  * **Skeleton Shimmers (`SkeletonPulse`)**: Telas de transição fluidas que simulam o contorno dos elementos em pulsação suave em vez de travamentos e telas em branco ao iniciar o aplicativo.
  * **Splash Screen Animada**: Tela inicial AMOLED de 3 segundos com animação escalonável de opacidade.

---

## ⚙️ Como Executar e Compilar o Projeto

### Pré-requisitos
* Flutter SDK (versão `>= 3.0.0`) configurado na máquina.
* Dispositivo Android (ou emulador) conectado com permissão de depuração ativada.

### Instruções

1. **Clonar e instalar dependências**:
   ```bash
   flutter pub get
   ```

2. **Limpar arquivos compilados (Recomendado para atualizações de assets/ícones)**:
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Gerar ícones do launcher caso altere as imagens**:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

4. **Executar o aplicativo em Modo Debug**:
   ```bash
   flutter run
   ```

5. **Gerar o arquivo APK pronto para Instalação (Release)**:
   ```bash
   flutter build apk --split-per-abi
   ```
   *(O APK gerado estará disponível no caminho `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` ou semelhante)*.

6. **Gerar pacote de distribuição para iOS (App Store)**:
   ```bash
   flutter build ipa --release
   ```

