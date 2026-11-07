# ArchHypr Dotfiles

Rice para Arch Linux x86_64 com Hyprland **0.57 ou superior**, iniciado a partir do perfil padrão. O instalador aplica os dotfiles, instala os programas e habilita o SDDM Astronaut com o tema Japanese Aesthetic.

A revisão automatizada cobre instalação limpa e reexecução com comandos simulados. A validação de login pelo SDDM, renderização, teclas físicas e desbloqueio precisa ser feita numa sessão Arch. O relatório de revisão está em [REVISAO.md](REVISAO.md).

## Antes de começar

Entre no Hyprland como seu usuário comum e conecte à internet. No terminal, confira a autorização de administrador.

```bash
sudo -v
```

Se ainda precisar baixar o repositório, instale o Git e clone por HTTPS.

```bash
sudo pacman -Syu --needed git
git clone https://github.com/NadolnyJoao/ArchHypr_Dotfiles.git
cd ArchHypr_Dotfiles
```

Se baixou um ZIP, extraia e abra o terminal na pasta que contém `install.sh`. O nome dessa pasta pode variar conforme o arquivo baixado.

## Instalar

Veja o plano primeiro. O modo de simulação lista os pacotes e destinos.

```bash
bash install.sh --dry-run
```

Execute a instalação.

```bash
bash install.sh
```

O script atualiza o Arch antes de instalar novos pacotes. Se a atualização falhar, ele aproveita os pacotes que já existiam e registra os que ficaram faltando. A falha de uma etapa pula as dependentes e permite continuar com as independentes. Se a autorização do sudo expirar, ele pede a senha novamente no terminal.

Ao final, informe nome e e-mail do Git. Na criação da chave SSH, o OpenSSH pede uma frase secreta. O instalador mostra a chave pública para cadastro em [GitHub → SSH and GPG keys](https://github.com/settings/keys). Depois do cadastro, você pode testar com `ssh -T git@github.com`. Repositórios são clonados via HTTPS durante a instalação.

Leia o relatório antes de aceitar o reinício. O padrão do prompt é **não**. No SDDM, escolha a sessão **Hyprland**.

## O que fica configurado

| Componente | Resultado |
|---|---|
| Hyprland | Lua em módulos, margens de 6/12, wobble, transparência e desfoque |
| Waybar | Três blocos arredondados, workspaces, relógio, áudio, rede, bateria, bandeja, notificações e energia |
| Rofi | Launcher e seletor dos temas Nord, Gruvbox pastel e Catppuccin Mocha |
| Kitty | Janela flutuante centralizada, abas arredondadas, Fish e fundo translúcido |
| Thunar | Miniaturas, temas GTK e pastas Papirus que acompanham a paleta |
| Neovim | Clone do Neovim-IDE e associação dos arquivos de código ao Neovim dentro do Kitty |
| Fish | Sugestões e autocomplete, com a saudação oculta |
| SwayNC | Notificações e histórico acessíveis pela Waybar |
| Wallpaper | Pack clonado, fila embaralhada e avanço automático a cada 15 minutos |
| Hyprlock | Super + L com o wallpaper ativo no momento do bloqueio |
| Inatividade | Brilho a 20% após 5 minutos e tela apagada após 10 minutos |
| Hyprsunset | 5000 K das 18h às 7h, conforme o horário local |
| SDDM | Japanese Aesthetic com `613342.jpg` e textos brancos |
| Integração | Agente Polkit iniciado com a sessão, portais GTK/Hyprland e áudio PipeWire |
| Programas | Firefox padrão, Discord, Obsidian, OpenCode, CMake, Flatpak e YTMDesktop |

A instalação inclui o Nordic via HTTPS. Gruvbox e Catppuccin usam temas GTK gerados pelas mesmas paletas do rice. A preferência `prefer-dark` é aplicada no login e na troca de tema. Temas escolhidos dentro dos próprios aplicativos podem sobrepor a preferência do sistema.

Os plugins e ferramentas do Neovim são baixados na primeira abertura. Para C/C++, o projeto prepara GCC, Make, CMake, Ninja e as dependências de instalação de ferramentas do Mason. Outras linguagens podem exigir runtimes adicionais.

## Atalhos

| Atalho | Ação |
|---|---|
| Super + Q | Fechar janela |
| Super + W | Alternar janela flutuante |
| Super + F | Alternar tela cheia |
| Super + E | Thunar |
| Super + Enter | Kitty |
| Super + Shift + Enter | Navegador padrão |
| Super + Espaço | Aplicativos no Rofi |
| Super + Shift + Espaço | Escolher tema |
| Super + Shift + W | Próximo wallpaper |
| Super + Shift + S | Captura de região para a área de transferência |
| Super + L | Bloquear a sessão |
| Super + setas | Mudar foco |
| Super + Shift + setas | Mover janela |
| Super + 1–9 | Trocar workspace |
| Super + Shift + 1–9 | Mover a janela para o workspace |
| Super + botão esquerdo | Arrastar janela |
| Super + botão direito | Redimensionar janela |
| Teclas físicas | Volume, mudo e brilho |

Na máquina usada para desenvolver este rice, Super + Shift + Espaço funciona com o **Shift direito**. O atalho aceita ambos os Shifts, mas certas combinações podem depender do teclado.

A fila de wallpapers recomeça em cada login. Novos arquivos entram no próximo embaralhamento. O menu de energia pede confirmação para sair, reiniciar e desligar. O botão de rede abre o gerenciador quando o NetworkManager já está ativo. O instalador preserva o serviço de rede existente.

## Pastas e personalização

Os caminhos abaixo assumem as variáveis XDG padrão.

| Local | Conteúdo |
|---|---|
| `~/.config/hypr/` | Configuração e scripts da sessão |
| `~/.config/waybar/`, `~/.config/rofi/` | Barra e menus |
| `~/.config/kitty/` | Terminal |
| `~/.config/fish/conf.d/rice-arch.fish` | Preferências portáteis do Fish |
| `~/.local/share/rice-arch/Wallpapers_Pack/wallpapers` | Wallpapers |
| `~/.local/share/themes/Nordic` | Tema GTK Nord |
| `~/.local/share/icons/Rice-Arch-Icons-*` | Pastas coloridas com herança Papirus |
| `~/.local/state/rice-arch/instalacao.*` | Relatórios e backups |

Edite o arquivo correspondente em `dotfiles/` para levar uma mudança às próximas instalações. O instalador faz backup dos dotfiles que substituir. Ele preserva um clone existente do Neovim-IDE com a mesma URL, incluindo as suas edições. Para atualizar clones existentes de wallpapers ou Neovim, revise as mudanças locais e use Git dentro de cada clone.

### Monitores opcionais

A sessão usa detecção automática. Para um arranjo específico, crie `~/.config/hypr/modules/monitors.local.lua`. O arquivo principal o carrega por último, se existir. O instalador o preserva, e a cópia equivalente no repositório está no `.gitignore`.

O layout do teclado é lido do X11 configurado pelo `localectl`, quando disponível. Se apenas o mapa do console estiver configurado, confira o layout dentro do Hyprland. O módulo `input.lua` mantém o remapeamento do ThinkPad separado.

### Remapeamento opcional do ThinkPad

Execute no Hyprland para transformar Ctrl direito em `/` e Shift + Ctrl direito em `?`.

```bash
bash "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/thinkpad-remap.sh" on
```

Para desfazer, use o mesmo comando com `off`. O script transforma e valida uma cópia do mapa da sessão. A ativação vale para a instância atual do Hyprland. Confira caracteres, Shift e Ctrl esquerdo após ativar no teclado físico.

## Relatórios

O caminho da execução aparece no terminal. Abra o arquivo `resumo.tsv` com o editor ou com `cat`.

| Status | Significado |
|---|---|
| `OK` | Etapa concluída |
| `JA_PRONTO` | Estado esperado já estava presente |
| `FALHOU` | O detalhe aponta para o log daquela etapa |
| `PULADO` | Faltou uma dependência ou interação no terminal |

O código de saída é `0` para execução completa, `1` quando há falhas e `2` quando houve etapas puladas. Uma execução sem terminal pula nome/e-mail e chave SSH.

Antes de reiniciar, confira especialmente `hyprland-versao`, `desktop-config`, `hyprland-config`, `wallpaper-config`, `lock-config`, `sddm-tema` e `sddm-servico`. Verifique as outras etapas para ter todos os recursos da tabela de componentes.

## Recuperação e problemas comuns

### A interface não abriu

Acesse um TTY com **Ctrl + Alt + F3** e entre com seu usuário. Consulte o serviço do login.

```bash
systemctl status sddm --no-pager
journalctl -b -u sddm --no-pager
```

Para desabilitar o tema personalizado, renomeie o drop-in do rice.

```bash
sudo mv /etc/sddm.conf.d/90-rice-arch.conf /etc/sddm.conf.d/90-rice-arch.conf.disabled
```

Após salvar seu trabalho, um reinício permite testar o login com o tema padrão. O instalador também registra no log de SDDM o caminho da cópia do tema anterior, quando houver uma reexecução.

### Restaurar o arquivo principal do Hyprland

Escolha a pasta da instalação que você pretende desfazer.

```bash
ls -dt ~/.local/state/rice-arch/instalacao.*
```

No comando abaixo, substitua `EXECUCAO` pelo nome real da pasta escolhida.

```bash
cp ~/.local/state/rice-arch/EXECUCAO/backup/hypr/hyprland.lua ~/.config/hypr/hyprland.lua
```

Confira se o backup existe antes de copiar. Backups de outros dotfiles seguem a mesma estrutura relativa. Depois de entrar na sessão, consulte `hyprctl configerrors`.

### Diagnóstico por recurso

| Sintoma | Como investigar |
|---|---|
| Pacman falhou | Leia `atualizacao.log` e o log do pacote. Resolva rede, mirrors ou a transação pendente antes de executar novamente. |
| Download falhou | Confira o log de clone e a conexão. As dependentes aparecem como puladas. |
| SDDM com cores ou fundo incorretos | Rode `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/rice-arch-astronaut/`. |
| Falta de wallpaper | Rode `bash ~/.config/hypr/scripts/wallpaper.sh next` e `hyprctl hyprpaper listactive`. |
| Tema GTK anterior em uma janela aberta | Feche e reabra o aplicativo. Confira `gsettings get org.gnome.desktop.interface gtk-theme`. |
| Sem miniaturas | Confira `thunar-miniaturas` no relatório e as preferências do Thunar. |
| Arquivo de código não abre | Consulte `xdg-mime query default text/x-lua` e tente `kitty nvim -- caminho/do/arquivo.lua`. |
| Firefox claro | Confira `gsettings get org.gnome.desktop.interface color-scheme` e selecione o tema automático do sistema no Firefox. |
| Sem controle de brilho | Confira `brightnessctl -c backlight info`. Em monitores sem backlight controlável, a etapa de redução é ignorada e o desligamento aos dez minutos continua disponível. |
| Ferramenta do Neovim falhou | Abra `:checkhealth`, `:Lazy` e `:Mason` e examine o download que falhou. |
| Janela gráfica não pede senha | Confira `systemctl --user status hyprpolkitagent.service`. |
| Compartilhamento de tela ou preferência de cor falha | Confira `journalctl --user -b -u xdg-desktop-portal` e o ambiente Wayland da sessão. |

## Testes e manutenção

Execute a suíte com Bash, inclusive quando estiver usando Fish.

```bash
bash tests/run.sh
```

Os testes precisam de Bash, Git, Python, Lua e utilitários básicos. Se faltar Lua, instale com sudo pacman -S --needed lua. O teste completo usa comandos simulados e uma cópia temporária dos destinos de sistema.

| Caminho | Responsabilidade |
|---|---|
| `install.sh` | Ordem e dependências das etapas |
| `packages/*.txt` | Programas instalados pelo pacman |
| `lib/steps.sh` | Status, logs e backup dos dotfiles |
| `lib/integration.sh` | Nordic, associações de arquivos, miniaturas e GTK |
| `dotfiles/hypr/modules/` | Aparência, atalhos, entrada e início da sessão |
| `dotfiles/hypr/themes/` | Paleta base e cores ANSI |
| `tests/` | Regressões e instalação simulada |

Após alterar os arquivos, rode os testes, revise `git diff` e faça o commit. Confirme na sessão real o recurso alterado antes de reproduzir a instalação em outra máquina.
