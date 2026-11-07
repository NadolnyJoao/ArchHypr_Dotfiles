# Auditoria de portabilidade — 7 de novembro de 2026

Base auditada: `efe9fd2`, no clone local `ArchHypr_Dotfiles`. A árvore estava limpa antes do trabalho. Este relatório substitui a revisão antiga do ZIP, preservada no histórico Git.

## Parecer

O repo é um instalador de ambiente gráfico para **Arch Linux x86_64 já instalado**, com Hyprland >= 0.57, internet, sudo e sessão de usuário funcional. É apropriado para reproduzir o rice nesse escopo, com as validações abaixo. **Não há evidência suficiente para garantir uma instalação completa em qualquer máquina.**

Não configura disco, sistema de arquivos, bootloader, kernel, firmware, GPU, contas, rede inicial, locale ou dados pessoais. Não substitui instalação do Arch, backup do sistema ou imagem de disco. Drivers, monitores, dispositivos de brilho, bateria e teclado dependem da máquina de destino.

## Problemas encontrados e tratados

| Constatação | Tratamento | Evidência |
|---|---|---|
| A entrada principal podia ser publicada apesar da falha de Hyprpaper/Hyprlock e comandos usados pelos atalhos | Dependências explícitas antes de copiar módulos e entrada principal; SDDM depende dessa etapa | Instalações simuladas com falhas em `hyprpaper`, `hyprlock` e `grim` preservam a entrada anterior e pulam a habilitação do SDDM |
| Hypridle não tinha comandos de bloqueio/suspensão | `lock_cmd`, solicitação de bloqueio antes de dormir, espera explícita pelo protocolo de bloqueio e DPMS ligado ao voltar | Configuração aceita pelo Hypridle instalado; suspensão e desbloqueio reais continuam pendentes |
| Reinício era oferecido mesmo após uma instalação incompleta | Prompt suprimido quando existem etapas falhas ou puladas | Revisão do fluxo de conclusão; reboot real não executado |
| Drop-in do SDDM podia ser sobreposto, com falso sucesso | Verificação da configuração efetiva na ordem documentada; conflito falha a etapa e impede habilitação dependente | Instalação simulada com `/etc/sddm.conf` conflitante preservado |
| LazyGit usado pela interface Git do editor não estava na lista | Adicionado a `packages/neovim.txt` | Pacote disponível no banco local do Arch; a interface interativa não foi aberta |
| Clones de Neovim e wallpapers não registravam a revisão | `rev-parse HEAD` nos logs, inclusive ao reaproveitar clones | Testes com repositórios Git reais em diretórios temporários |
| Entrada desktop tinha duas categorias principais | Uma categoria principal e `TextEditor` como categoria adicional | `desktop-file-validate` sem o aviso anterior |
| README e revisão anunciavam rotação de 15 minutos | Documentação corrigida para uma hora, conforme implementação e teste existentes | Teste de intervalo e fila de wallpapers |
| Os testes Lua usavam somente uma API simulada | Modo nativo opcional para Hyprland, Kitty, GTK3, Fish, desktop e XKB | Quatro paletas aceitas e mapas US/BR compilados |

## Cobertura por componente

| Arquivos / componente | O que foi conferido | Limite |
|---|---|---|
| `install.sh`, `lib/steps.sh`, `lib/packages.sh` | Ordem, dependências, atualização, códigos 0/1/2, logs, backups, arquivos temporários, bloqueio de execução, ajuda e simulação | Pacman e sudo reais não foram usados para instalar ou modificar o sistema |
| `packages/*.txt` | 64 pacotes distintos após deduplicação, nomes disponíveis por `pacman -Si`; comandos chamados por configurações e scripts | Consulta ao banco local, sem atualizar mirrors nem instalar os pacotes em uma máquina limpa |
| `lib/dotfiles.sh`, `hyprland.lua`, `modules/*.lua` | Caminhos XDG, arquivo de monitores opcional preservado, entrada publicada após dependências; API real do Hyprland | Parser não exercita interação com janelas, renderização ou GPU |
| Temas Nord, Gruvbox, Catppuccin e Solitude | Cores hexadecimais, 16 cores ANSI, arquivos gerados, CSS e configurações do Kitty | Aparência final precisa de sessão gráfica |
| Waybar e SwayNC | JSON, comandos, CSS e importação da paleta | Módulos de bateria/rede/áudio dependem dos serviços e hardware |
| Rofi | Estrutura e comandos revisados, geração das cores e seleção simulada | Parser/renderização do Rofi não puderam ser testados sem conexão com o compositor |
| Kitty, Fish, entrada desktop e portal | Parser real do Kitty/Fish/desktop, shell Fish declarado, MIME e preferências de portal | File chooser, compartilhamento de tela e ativação D-Bus não exercitados ao vivo |
| `theme.sh`, `gtk-theme.sh` | Troca offline das quatro paletas, scripts simulados, ícones Papirus e geração GTK3 | GSettings real não foi alterado; Nordic upstream não foi baixado novamente |
| `wallpaper.sh`, `lib/wallpapers.sh` | Filas por tema, fallback para raiz, arquivos removidos, espaços/vírgulas, erro sem avanço, intervalo de uma hora e concorrência por locks revisada | Imagens simuladas e IPC simulado; pack remoto não baixado |
| `lock.sh`, `hypridle.conf`, `idle-brightness.sh` | Imagem ativa copiada, fallback sem imagem, brilho/restauração, ausência de backlight e integração de suspensão | Sem autenticação PAM, suspensão ou tecla física real |
| `hyprsunset.conf`, `power-menu.sh` | Horários 07h/18h, temperatura, confirmação e comandos de energia revisados | Sem mudar temperatura de tela, desligar ou reiniciar |
| `thinkpad-remap.sh`, `remap-keymap.py` | Alteração exclusiva de RCTL, preservação de LCTL; compilação de mapas completos US/BR com libxkbcommon | Mapa da sessão e teclado físico não foram alterados |
| `lib/sddm.sh`, `lib/check-sddm.py` | Preparação, cores brancas, wallpaper, dependências Qt6, publicação, backup, falha de publicação com restauração, precedência de configuração | Sem novo download do Astronaut, teste do greeter ou boot/login real |
| `lib/neovim.sh`, `packages/neovim.txt` | Clone, destino inválido, backup e preservação de edição local; revisão do clone local do Neovim-IDE | Plugins/Mason não foram instalados do zero |
| `lib/integration.sh`, `lib/finish.sh` | Nordic, associações MIME, miniaturas, Firefox, Git e proteção de chaves existentes | Preferências e serviços simulados; Git global e SSH dos testes isolados |
| `tests/`, README e `.gitignore` | Suíte, isolamento, sintaxe Bash, Lua, referências, instruções de instalação e recuperação | Testes simulados não equivalem a uma instalação física |

## Resultados executados

- `bash tests/run.sh`: **12 arquivos Bash e validação Python/Lua, código final 0**. Suíte de regressão, incluindo instalação limpa, reexecução, falhas de pacote, falha de atualização e falha na publicação de SDDM. As linhas `FALHOU` de cenários negativos são esperadas; o código final da suíte é o critério de aprovação.
- `RICE_NATIVE_TESTS=1 bash tests/native.sh`: parsers reais de Hyprland, Kitty e GTK3 aceitaram as quatro paletas; Fish e entrada desktop também passaram. Mapas XKB US e BR foram remapeados e recompilados.
- `pacman -Si` para a união das duas listas: todos os nomes encontrados no banco local.
- `hypridle --verbose --config ...` com socket Wayland inexistente: arquivo e listeners reconhecidos, seguido da falha esperada de conexão. Isso verifica leitura da configuração, não suspensão.
- `git diff --check`: sem erros de whitespace.

Versões usadas: Hyprland `0.57.1-1`, Kitty `0.49.2-1`, GTK3 `1:3.24.52-2`, Fish `4.9.3`, libxkbcommon `1.13.2-1`, Hypridle `0.1.8-2`, Python `3.14.9-1`, Lua `5.5.1-1`, Neovim `0.12.6-1` e Git `2.56.0-1`.

GTK3 emite avisos `gtk_icon_theme_get_for_screen` sem servidor gráfico, mas aceita os estilos. O teste nativo remove DISPLAY/WAYLAND_DISPLAY e usa HOME/XDG temporários. Não inicia outra sessão, não dispara autostart nem escreve as preferências reais do usuário.

## Dependências externas e reprodutibilidade

A tentativa real de `git ls-remote https://github.com/NadolnyJoao/Neovim-IDE.git HEAD` falhou com `Could not resolve host: github.com`. Por isso não foram comprovados downloads novos de Neovim-IDE, Wallpapers_Pack, Nordic, Astronaut, Flathub ou plugins/Mason neste ambiente.

Foi possível inspecionar um clone local limpo de Neovim-IDE, com origin correspondente, no commit `691e5b0b5d826ffd26eea62d09f98af616c79139` (28/10/2026). Seus extras são clangd, CMake e DAP; a lista local cobre o compilador e ferramentas de instalação. O runner também declara JavaScript, TypeScript, Java, Ruby e Rust, que exigem runtimes opcionais separados. A configuração tem fallback fora do Omarchy, portanto não exige o Omarchy para iniciar.

Esse projeto externo ignora `lazy-lock.json` e usa plugins atualizáveis. O instalador também usa as branches atuais dos clones externos, os repositórios rolling do Arch e o Flatpak atual. Registrar hashes nos logs ajuda a diagnosticar uma instalação, mas **não congela o conjunto inteiro**. Não se pode afirmar reprodução binária ou visual idêntica no futuro. Congelar isso exigiria snapshot de pacotes, revisões explícitas de cada projeto e lock de plugins mantido e testado junto do Neovim-IDE.

A instalação não é uma transação global: etapas independentes podem concluir mesmo quando outra falha. Os backups permitem recuperação por arquivo; não há rollback automático de pacotes, serviços e preferências em conjunto.

Clones existentes de Neovim e wallpapers são preservados quando origin/estrutura correspondem; reexecutar o instalador não atualiza seu conteúdo. O layout de teclado depende do X11 configurado por localectl, ou do padrão do Hyprland quando esse dado não existe. Rede existente é preservada; instalar NetworkManager não equivale a configurar a conectividade da máquina.

## Validação ainda necessária na máquina de destino

1. Instalar em Arch x86_64 atualizado, com internet e usuário/sudo funcionais, e conferir todos os logs sem falhas ou etapas puladas.
2. Confirmar SDDM, escolha de sessão Hyprland e `hyprctl configerrors` após o login.
3. Testar desbloqueio manual e suspensão/retorno, incluindo tampa de notebook, sem perder uma sessão de recuperação em TTY.
4. Testar os quatro temas, Rofi, wallpapers, fontes/ícones, áudio, rede, brilho, monitores e teclado físico.
5. Abrir Neovim pela primeira vez com rede; conferir `:Lazy`, `:Mason` e `:checkhealth`, compilar e depurar um projeto CMake.
6. Conferir portal/file chooser e compartilhamento de tela.

## Documentação consultada

- [Configuração Lua do Hyprland](https://wiki.hypr.land/configuring/core/)
- [Autostart do Hyprland](https://wiki.hypr.land/configuring/core/autostart/)
- [Hypridle: bloqueio, suspensão e inibidores](https://wiki.hypr.land/hypr-ecosystem/user/hypridle/)
- [SDDM: ordem de precedência e ThemeDir](https://man.archlinux.org/man/sddm.conf.5.en)
- [Astronaut: dependências Qt6 e configuração](https://github.com/Keyitdev/sddm-astronaut-theme)
- [LazyVim: requisitos e ferramentas opcionais](https://www.lazyvim.org/)
- [LazyVim: configuração do gerenciador de plugins](https://www.lazyvim.org/configuration/lazy.nvim)
- [libxkbcommon: ferramentas](https://xkbcommon.org/doc/current/index.html)
