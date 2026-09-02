# Punchi Dock Remastered

<p align="center">
  <img src="contents/images/punchi-dock-remastered.svg" width="160" alt="Logo do Punchi Dock Remastered">
</p>

<p align="center">
  <a href="https://github.com/PunchiSoft/punchi-dock-remastered/releases/tag/v0.9.7.55">
    <img src="https://img.shields.io/badge/release-v0.9.7.55-4caf50" alt="Versão v0.9.7.55">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/licen%C3%A7a-GPL--3.0--or--later-blue" alt="Licença GPL-3.0-or-later">
  </a>
  <a href="https://www.paypal.com/donate/?hosted_button_id=HXFSZU4K8C38W">
    <img src="https://img.shields.io/badge/Doar-PayPal-0070ba" alt="Doar com PayPal">
  </a>
</p>

[English](README.md) | [Español](README.es.md) | [Deutsch](README.de.md) | [Português (Brasil)](README.pt_BR.md)

Punchi Dock Remastered é um dock inicializador nativo e interface de tarefas para o KDE Plasma 6, projetado primariamente para Wayland. Pode operar como dock flutuante ou integrado a um painel do Plasma, seguindo as cores do tema ativo.

Este repositório é uma reescrita modular do [Plasmoide Punchi Dock original](https://github.com/PunchiSoft/punchi-dock-plasmoid). O projeto prepara atualmente seu caminho rumo à versão estável 1.0.

A versão atual é
[v0.9.7.55](https://github.com/PunchiSoft/punchi-dock-remastered/releases/tag/v0.9.7.55).

## Novidades na versão 0.9.7.55

- **Submenu de áudio no Centro de Controle e iconografia dinâmica**: Página dedicada para seleção de dispositivos de saída/entrada e controle de volume por aplicativo, ondas sonoras dinâmicas acompanhando o controle deslizante de volume, detecção automática de fones de ouvido e botão com ícone universal de equalizador (`view-media-equalizer`).
- **Alternador de OSD de volume do Plasma**: Integração nativa com KConfig (`plasmaparc`) para ligar ou desligar a notificação visual de volume na tela.
- **Interações unificadas e geometria simétrica**: Cursor de mão interativo e dicas de contexto em todos os cartões, além de margens simétricas nos controles de Luz Noturna.

Consulte o [registro de alterações da 0.9.7.55](CHANGELOG.md#09755---2026-09-02) para ver as notas detalhadas de lançamento e a validação executada.

## Capturas de Tela

| PunchiMenu Normal — pré-visualização recomendada |
|:--:|
| <img src="Images/PunchiMenuNormal.png?v=0.9.7" alt="PunchiMenu Normal com categorias de aplicativos, grade e favoritos" width="760"> |

| PunchiMenu Tela Cheia |
|:--:|
| <img src="Images/PunchiMenuFullScreen.png?v=0.9.7" alt="Lançador de aplicativos PunchiMenu em Tela Cheia" width="760"> |

| Controles de Mídia MPRIS |
|:--:|
| <img src="Images/MPRIS-Controls.png" alt="Formatos de popup MPRIS com capa e controles de reprodução" width="760"> |

| Disposições do Dock |
|:--:|
| <img src="Images/desktop-layouts.png" alt="Punchi Dock em disposições horizontal, vertical e integrado a painel do Plasma" width="760"> |

| Grade de Pastas | Calendário e Relógio |
|:--:|:--:|
| <img src="Images/MenuGrid.png" alt="Popup de pasta em exibição em grade" width="300"> | <img src="Images/Calendar_clock.png" alt="Popup de calendário e relógio" width="300"> |

## Idiomas

- Inglês é o idioma fonte de execução e padrão de fallback.
- Espanhol (`es`) é a tradução de interface mantida ativamente.
- Alemão (`de`) e Português do Brasil (`pt_BR`) estão incluídos com catálogos de tradução completos.

Consulte o [guia de tradução](po/README.md) para diretrizes sobre os catálogos e como contribuir.

## Recursos

- Modos dock flutuante e painel do Plasma.
- Inicializadores fixados e barra dinâmica opcional de tarefas.
- Inicializadores personalizados com preservação segura de comandos e argumentos.
- Cartões de janelas, miniaturas em tempo real e controles de janelas agrupadas (escolha entre cartões, miniaturas ao vivo ou sem popup de prévia).
- Pastas configuráveis com visualizações em grade, lista e detalhes, alternância direta pelo menu de contexto e arrastar e soltar de inicializadores do PunchiMenu ou da área de trabalho, notas rápidas, lixeira, separadores e calendário.
- Lançador de aplicativos PunchiMenu com apresentações Normal e Tela Cheia, pesquisa, categorias, favoritos, pastas nomeadas, ocultação seletiva, navegação por teclado e atalho global.
- Centro de Controle em tela cheia com conexões rápidas para Wi-Fi e Bluetooth, controles de brilho e volume, Não Perturbe, alternância de tema claro/escuro, ajuste ao vivo de Luz Noturna e histórico de notificações.
- Visualizador de áudio PipeWire opcional com seis estilos, cores dinâmicas ou do tema Plasma e até 48 elementos visuais.
- Popups com tema Plasma, animações configuráveis, distância adaptativa ao dock e transições suaves.
- Ações nativas de aplicativos e janelas nos menus de contexto de inicializadores fixados e tarefas dinâmicas.
- Emblemas opcionais com contagem de janelas em aplicativos agrupados.
- Cartões de mídia MPRIS contextuais com capa, informações da faixa, controles de reprodução e ação acessível para silenciar/restaurar volume.
- Item MPRIS compacto no dock com seleção de reprodutor e execução direta.
- Reordenação persistente de itens no dock por clique longo ou teclado e arrastar e soltar seguro de arquivos sobre inicializadores e a Lixeira.
- Operações assíncronas na lixeira com indicador de progresso, som de conclusão e notificações temáticas do KDE.
- Temas JSON externos em biblioteca gerenciada pelo usuário com fallback seguro para o tema Plasma.
- Conformidade com padrões XDG: Temas JSON importados (`~/.local/share/punchi-dock-remastered/`) e configurações por instância (`~/.config/punchi-dock/`) utilizam armazenamento atômico isolado para proteger contra corrupção em atualizações.
- Módulo nativo C++ QML para descoberta de aplicativos, serviços em runtime, espectro de áudio e operações de lixeira.

## Requisitos do Sistema

- KDE Plasma 6 ou superior.
- Sessão Wayland recomendada (suporte secundário a X11).
- PipeWire necessário para o visualizador de áudio opcional.
- **Distribuição de Referência Oficial**: Fedora 44 `x86_64` com KDE Plasma 6+.
- **Pacote Universal Oficial**: Compilado no Debian 13 (Trixie) com shims binários C (`compat/`), permitindo instalação e execução direta em múltiplas distribuições modernas com Plasma 6 (Fedora, Arch Linux, Debian, Kubuntu e derivados).
- **Compilação Local a partir do Código Fonte**:
  - Requer CMake 3.22+, compilador C++20, Qt 6.6+, ECM/KF6 6.0+, Plasma 6.0+ e arquivos de desenvolvimento do PipeWire (fornecidos pelos repositórios da sua distribuição).
  - Assistentes automatizados com e sem testes facilitam a compilação e instalação em uma única etapa.

## Instalar um Pacote Publicado

Usuários finais podem instalar diretamente um pacote `.plasmoid` pré-compilado oficial (específico da distribuição ou a versão universal) sem a necessidade de compiladores ou ferramentas de desenvolvimento.

Para instalar ou atualizar com o assistente universal:

```bash
./scripts-user/setup-universal.sh caminho/para/o/pacote.plasmoid
```

Ou manualmente através do `kpackagetool6`:

```bash
# Instalação inicial
kpackagetool6 --type Plasma/Applet --install ./punchi-dock-remastered-<versão>-<distro>-x86_64.plasmoid

# Atualização
kpackagetool6 --type Plasma/Applet --upgrade ./punchi-dock-remastered-<versão>-<distro>-x86_64.plasmoid
```

Encerre a sessão e entre novamente, ou reinicie o Plasma Shell, caso o plasmoide atualizado não seja carregado imediatamente.

## Compilar a partir do Código Fonte

O plasmoide contém um módulo nativo em C++ para integração com o Plasma 6, PipeWire e o gerenciador de tarefas. Pode ser compilado facilmente em qualquer distribuição Linux moderna com Plasma 6.

### Dependências de Compilação por Distribuição

O assistente `setup.sh` detecta e informa automaticamente os pacotes ausentes, mas você também pode instalá-los manualmente:

#### Fedora / RHEL / Nobara
```bash
sudo dnf install \
    gcc-c++ cmake extra-cmake-modules \
    qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtshadertools \
    plasma-workspace-devel pipewire-devel \
    kf6-kconfig-devel kf6-ki18n-devel kf6-kio-devel \
    gettext zip unzip
```

#### Arch Linux / Manjaro / EndeavourOS
```bash
sudo pacman -S --needed \
    base-devel cmake extra-cmake-modules \
    qt6-base qt6-declarative qt6-shadertools \
    plasma-workspace pipewire \
    kconfig ki18n kio kservice
```

#### Debian 13 (Trixie) / Kubuntu / Ubuntu
```bash
sudo apt update && sudo apt install \
    build-essential cmake extra-cmake-modules \
    qt6-base-dev qt6-declarative-dev qt6-shader-baker \
    libplasma-dev libpipewire-0.3-dev \
    libkf6config-dev libkf6i18n-dev libkf6kio-dev \
    gettext zip unzip
```

### Assistentes de Compilação Incluídos

O repositório fornece assistentes automatizados adaptados para diferentes necessidades:

#### 1. Assistente para Usuários (Rápido e Seguro, sem testes)

Projetado para compilar e instalar localmente em segundos, sem executar verificações de desenvolvimento:

```bash
./scripts-user/setup.sh
```

- Configura o CMake com `BUILD_TESTING=OFF` (ignora `qmllint` e CTest).
- Detecta automaticamente sua distribuição (Fedora, Arch Linux, Debian, Kubuntu e derivados) e verifica as dependências necessárias.
- Possui **configuração interativa de concorrência e memória** (Modo Seguro com 1 núcleo para máquinas virtuais ou <= 4 GB de RAM, Modo Equilibrado, Rápido ou Personalizado).
- Suporta comandos diretos via CLI:

```bash
# Compilar e instalar localmente em modo seguro (1 thread)
./scripts-user/setup.sh --install -j 1

# Criar apenas o pacote .plasmoid local usando 4 threads paralelas
./scripts-user/setup.sh --build-only --jobs 4

# Desinstalar o plasmoide da área de trabalho atual
./scripts-user/setup.sh --uninstall
```

O pacote gerado fica em `dist/punchi-dock-remastered-<versão>-<distro>-<arch>-local-build.plasmoid`. Consulte [scripts-user/README.md](scripts-user/README.md) para mais detalhes.

#### 2. Assistente Mestre para Desenvolvedores (Validação rigorosa com testes)

Projetado para desenvolvedores e colaboradores que desejam validação completa da base de código:

```bash
./scripts-dev/setup.sh
```

- Executa `qmllint` para análise estática de QML conforme o baseline da distribuição.
- Configura o CMake com `BUILD_TESTING=ON` e executa a suite completa de 67 testes do CTest (contratos de arquitetura, shaders, ciclo de vida, integração Plasma e backend nativo).
- Suporta opções CLI como:

```bash
./scripts-dev/setup.sh --local-test           # Compilar, validar todos os 67 testes e instalar no Plasma local
./scripts-dev/setup.sh --local-test -j 1      # Modo seguro (1 núcleo) para máquinas virtuais / pouca RAM
./scripts-dev/setup.sh --local-test --jobs 8 # Modo rápido com 8 threads paralelas
./scripts-dev/setup.sh --clean-install         # Reinstalação limpa do zero
./scripts-dev/setup.sh --dependencies-only    # Instalar dependências oficiais de build da distribuição
./scripts-dev/setup.sh --lang pt_BR --help    # Ajuda em português do Brasil (também suporta en, es, de)
```

Consulte [scripts-dev/README.md](scripts-dev/README.md) para ferramentas adicionais de desenvolvimento (`check-build-environment.sh`, `update-translations.sh`, `validar-empaquetado-limpio.sh`).

## Estrutura do Projeto

- `contents/`: Pacote do plasmoide em tempo de execução.
- `contents/ui/components/`: Componentes visuais reutilizáveis em QML.
- `contents/code/`: Lógica JavaScript compartilhada e padrões.
- `src/`: Módulo de integração nativo C++ QML.
- `scripts-user/`: Assistente de instalação e compilação para usuários.
- `scripts-dev/`: Ferramentas estritas de teste, empacotamento e manutenção.
- `metadata.json`: Metadados do KPackage e declaração de compatibilidade com o Plasma.

## Apoie o Projeto

Punchi Dock Remastered é um software livre. Relatórios de erros, testes reproduzíveis, melhorias na documentação, traduções e contribuições de código são formas valiosas de apoiar.

Doações financeiras voluntárias podem ser feitas pela [página oficial de doações do PayPal](https://www.paypal.com/donate/?hosted_button_id=HXFSZU4K8C38W).

## Licença

Punchi Dock Remastered é licenciado sob a [GNU General Public License v3.0 ou posterior](LICENSE).
