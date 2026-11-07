# Rice Arch

Instalador para **Arch Linux x86_64 com uma primeira sessão do Hyprland padrão já funcionando**. Use um usuário comum com acesso a `sudo`, rede funcional e um terminal aberto no Hyprland. O instalador atualiza o Arch, instala os programas, aplica os dotfiles e habilita o SDDM para o próximo boot.

## Instalar

1. Extraia o projeto e abra um terminal dentro da pasta `rice-arch`.
2. Confira o plano sem fazer alterações.

   ```bash
   bash install.sh --dry-run
   ```

3. Rode o instalador. Digite sua senha quando o sudo pedir.

   ```bash
   bash install.sh
   ```

4. Ao final, informe nome e e-mail para o Git. Se gerar uma chave SSH, escolha a frase secreta no prompt do OpenSSH. Copie a chave pública exibida para [GitHub → SSH and GPG keys](https://github.com/settings/keys). Confirme o cadastro com `ssh -T git@github.com`.
5. Abra o relatório no caminho que o instalador mostrar. Revise as falhas antes de aceitar o reinício. O padrão do prompt é **não**.
6. No SDDM, escolha **Hyprland**. Na primeira abertura do Neovim, aguarde a instalação dos plugins e ferramentas pelo lazy.nvim e pelo Mason.

O instalador clona os repositórios por HTTPS. Se quiser usar SSH para enviar alterações de um clone, troque o remote do repositório depois de cadastrar a chave.

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
| Super + Shift + Espaço | Nord, Gruvbox ou Catppuccin Mocha |
| Super + Shift + S | Copiar região da tela |
| Super + L | Bloquear com Hyprlock |
| Super + setas | Mudar foco |
| Super + Shift + setas | Mover janela |
| Super + 1–9 | Trocar workspace |
| Super + Shift + 1–9 | Mover janela para workspace |
| Teclas físicas | Volume, mudo e brilho |

A Waybar tem volume, rede, relógio, workspaces, bateria quando disponível, bandeja, SwayNC e energia. O botão de rede usa NetworkManager quando o serviço já está ativo. O menu de energia pede confirmação para sair, reiniciar e desligar.

## Relatório e recuperação

O caminho padrão é `~/.local/state/rice-arch/instalacao.*/resumo.tsv`. Cada etapa tem seu próprio log. `OK` indica sucesso, `JA_PRONTO` indica que o estado esperado já existia, `FALHOU` aponta para o log e `PULADO` descreve a dependência ou condição ausente. Arquivos substituídos ficam em `backup/` dentro da pasta daquela execução.

| Sintoma | O que verificar |
|---|---|
| Atualização falhou ou banco bloqueado | Leia `atualizacao.log`. Verifique se há outra transação do pacman em execução. Resolva o erro e rode o instalador novamente. |
| Sudo expirou durante a instalação | Procure por erro de autenticação nos logs e execute novamente em um terminal interativo. |
| Clone HTTPS falhou | Confira rede, acesso ao repo e URL no log da etapa. A configuração de wallpaper depende do clone. |
| Hyprland mostra erro de configuração | No terminal, rode `hyprctl configerrors`. Compare o arquivo indicado com o backup da mesma execução. Se a interface estiver inutilizável, acesse um TTY com Ctrl + Alt + F3. |
| SDDM não aparece ou o tema falha | Use o TTY e consulte `journalctl -b -u sddm`. O preview é `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/rice-arch-astronaut`. Para voltar ao tema padrão, remova ou restaure o drop-in `/etc/sddm.conf.d/90-rice-arch.conf`. |
| Sem miniaturas no Thunar | Confira `tumbler` e a opção **Mostrar miniaturas** nas preferências do Thunar. |
| Thunar mantém a cor anterior | Feche as janelas e reabra. Confira o tema GTK ativo com `gsettings get org.gnome.desktop.interface gtk-theme`. |
| Brilho não diminui | Confira `brightnessctl -c backlight info`. Monitores sem controle exposto ao sistema ainda podem apagar após dez minutos. |
| Plugins do Neovim falham | Abra `:checkhealth`, `:Lazy` e `:Mason` para descobrir qual ferramenta ou download falhou. |

## Manutenção e testes

- `packages/` contém a lista de pacotes.
- `lib/` contém as etapas do instalador.
- `dotfiles/hypr/modules/` separa atalhos, aparência e inicialização.
- `dotfiles/hypr/themes/` contém as três paletas.
- `tests/` contém testes locais com ambientes temporários e comandos simulados.

```bash
for test in tests/*.sh; do bash "$test" || break; done
```

Os testes locais cobrem backups, reexecução, relatórios, falhas simuladas, temas, wallpapers, configuração do SDDM e preferências do Git. Em Arch, teste também login pelo SDDM, desbloqueio, troca de tema com apps abertos e o ciclo de inatividade.

## Remapeamento opcional no ThinkPad

Rode dentro da sessão Hyprland quando quiser que Ctrl direito digite `/` e Shift + Ctrl direito digite `?`.

```bash
bash "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/thinkpad-remap.sh" on
```

Troque `on` por `off` para voltar ao mapa anterior. O comando parte do mapa Wayland da sessão e valida a cópia antes de aplicá-la. Rode novamente no próximo login se quiser usar o remapeamento nessa sessão.
