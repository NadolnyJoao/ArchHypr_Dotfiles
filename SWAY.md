# Sway no ArchHypr_Dotfiles

## Instalar ou atualizar

Execute como usuário comum em um Arch com acesso à internet e sudo:

```fish
cd ~/ArchHypr_Dotfiles
bash instalar-sway.sh
```

Esse comando usa os arquivos do clone atual, instala os pacotes ausentes com
uma atualização completa do Arch e valida a configuração com `sway --validate`.
Após concluir, encerre a sessão e escolha **Sway** no SDDM.
O Hyprland continua disponível.

Para buscar a configuração publicada no GitHub:

```fish
bash atualizar-dotfiles.sh --desktop sway --apply
```

## Personalizar

Os arquivos ficam em `~/.config/sway/`:

| Arquivo | Conteúdo |
|---|---|
| `config` | Carrega os subarquivos |
| `config.d/appearance.conf` | Margens, bordas e janelas flutuantes |
| `config.d/preferences.conf` | Preferências visuais compartilhadas |
| `config.d/bindings.conf` | Atalhos |
| `config.d/input.conf` | Teclado e touchpad, preservados em atualizações |
| `config.d/session.conf` | Início dos componentes |
| `local.conf` | Ajustes exclusivos da máquina, aplicados por último |
| `scripts/` | Temas, wallpaper, energia e inatividade |
| `waybar/`, `rofi/`, `kitty/` | Aparência específica da sessão |

Para zerar as margens, use em `local.conf`:

```sway
gaps inner 0
gaps outer 0
```

Recarregue pelo terminal com `swaymsg reload`. O atalho configurado é
Super + Shift + R. O publicador reconhece margens, bordas e fontes em
`local.conf` e exporta essas preferências para `config.d/preferences.conf`.
Regras de monitor e teclado continuam locais. Novas máquinas usam as
preferências compartilhadas; ajustes existentes em `local.conf` prevalecem.

## Recursos

Os atalhos equivalentes ao Hyprland ficam comentados em `bindings.conf`.
Super + Shift + 1–9 envia a janela e mantém o workspace atual.
Super + Shift + Espaço escolhe Nord, Gruvbox, Catppuccin ou Solitude.
Ark acompanha a paleta escolhida e abre flutuante. As cores Qt/KDE
podem afetar outros aplicativos do usuário; reabra-os após trocar o tema.

O fundo começa preto. Super + Shift + W abre o seletor do tema;
Super + ponto/vírgula avança ou retrocede. Os wallpapers vêm de
`~/.local/share/rice-arch/Wallpapers_Pack/wallpapers/TEMA`.
A atualização não baixa esse repositório: ele deve existir, por exemplo,
a partir da instalação original do rice.

O bloqueio usa swaylock. Blur, wobble e o relógio do Hyprlock
não fazem parte dessa configuração do Sway. Gammastep gerencia
as temperaturas de dia e noite. Veja `gammastep.ini`.

## Falhas e recuperação

- Erro no pacman: resolva a mensagem indicada e execute novamente.
- Erro em `sway --validate`: corrija o arquivo indicado, inclusive `local.conf`;
  a aplicação dos arquivos para antes de substituir a configuração.
- Os backups ficam em `~/.local/state/rice-arch/atualizacao-*/`, com a mesma
  organização dos caminhos de configuração. A subpasta `data/` corresponde
  a `~/.local/share`. Faça a restauração fora da sessão afetada.
- Bluetooth desligado: `sudo systemctl enable --now bluetooth.service`.
- Verifique a sessão real depois de instalar: gestos, áudio, brilho,
  autenticação e compartilhamento de tela dependem do hardware e serviços.

Execute `bash tests/run.sh` antes de publicar alterações. Os testes de
sincronização usam HOME/XDG isolados e simulam o parser do Sway;
a validação com o Sway real ocorre ao aplicar na máquina.
