# Revisão do instalador

Base recebida em **Arch_Dotfiles.zip**, commit **3807b04**. A página do repositório no GitHub não pôde ser aberta neste ambiente. Esta revisão usa o ZIP enviado como fonte.

## Falhas confirmadas e corrigidas

| Problema na base recebida | Correção |
|---|---|
| Nenhuma etapa associava arquivos de código ao Neovim | Entrada desktop que abre Kitty com Neovim e associações por MIME |
| Nordic só havia sido instalado manualmente | Clone HTTPS para a pasta de temas do usuário, com backup de destino conflitante |
| Fish perdia a preferência de ocultar a saudação | Arquivo versionado em fish/conf.d, copiado pelo instalador |
| Agente Polkit instalado, sem inicialização na sessão | Inicialização pelo serviço de usuário e etapa registrada no relatório |
| Seletor de temas tinha dois atalhos iguais, incluindo o diagnóstico temporário | Um único atalho, sem o log de diagnóstico |
| Arquivo opcional de monitores não era carregado pelo main do repo | Carregamento opcional por último, gitignore e preservação na reexecução |
| Teste GTK esperava o Gruvbox antigo e falhava | Expectativas atualizadas e testes de ícones das três paletas |
| Nord não tinha a segunda linha com cores ANSI | Paleta de 16 cores adicionada e verificada para os três temas |
| Ampliação de transparência estava parcialmente no repo | Valores acordados aplicados a janelas, Kitty e painéis |
| Tema GTK só era aplicado no próximo login | Aplicação registrada ao final da instalação |
| Miniaturas dependiam das preferências locais do Thunar | Etapa explícita de configuração via xfconf |
| Preferência de cor e file chooser dependiam da seleção automática de portal | Configuração para GTK Settings/FileChooser e Hyprland |
| Cache de sudo podia expirar durante downloads | Reautenticação visível no terminal entre etapas |
| Kitty podia ser configurado para Fish antes de garantir Fish instalado | Dependências do desktop verificadas antes da cópia |
| SDDM podia modificar parcialmente um diretório já ativo | Preparação temporária, publicação por troca e backup do tema anterior |
| Não havia controle de versão mínima para Lua/wobble | Validação do Hyprland instalado, mínimo 0.57 |
| Testes não exerciam install.sh inteiro | Instalação limpa, reexecução e falha de pacote simuladas pela entrada normal |
| Etapas puladas podiam parecer sucesso completo | Código 2 para parcial, 1 para falha, estados detalhados no TSV |
| README tinha instruções incompletas | Instalação, recursos, TTY, recuperação, diagnóstico e testes documentados |
| Ferramentas auxiliares não eram todas declaradas | Ninja, ferramentas Python para Mason, less, desktop-file-utils, shared-mime-info e xfconf |

O botão de energia da Waybar foi conferido após decodificar o JSON. Suas aspas já estavam corretas e foram preservadas.

## Recursos preservados e conferidos

- Waybar arredondada com ícones de áudio e Ethernet.
- Rofi com transparência e seleção conforme a paleta.
- Kitty flutuante, sem maximização automática, abas arredondadas e Fish.
- Gruvbox pastel, Catppuccin unificado e pastas Papirus por paleta.
- Fila embaralhada de wallpapers, avanço manual e intervalo de 15 minutos.
- Confirmação da troca mesmo quando o IPC do Hyprpaper responde sem texto.
- Hyprlock usando uma cópia do wallpaper ativo.
- Brilho após 5 minutos, restauração e tela apagada após 10.
- Hyprsunset de 5000 K das 18h às 7h.
- Atalhos de workspaces, foco, movimento, captura, áudio e brilho.
- SDDM Japanese Aesthetic com 613342.jpg e textos brancos.
- Clone HTTPS do Neovim-IDE, plugins na primeira abertura e arquivos de código associados ao editor.
- Firefox padrão, Discord, Obsidian, OpenCode, Flatpak e YTMDesktop.
- Nome/e-mail do Git, chave SSH e reinício opcional.
- Remapeamento do Ctrl direito separado e restrito à sessão.
- Rede existente preservada. O botão da Waybar usa NetworkManager quando ativo.

## Verificações executadas

A suíte **bash tests/run.sh** executa 11 arquivos de teste Bash e a validação Python/Lua/Waybar.

O teste de instalação usa uma cópia temporária do projeto. Pacman, Git remoto, Flatpak, sudo, systemctl, GSettings, MIME e xfconf são simulados. Os diretórios do SDDM apontam para a pasta temporária. Quando o ambiente roda como root, o bloqueio de root é removido somente dessa cópia instrumentada.

Foram verificados instalação limpa, reexecução preservando monitores e edições do Neovim, falha no Rofi com etapas independentes continuando, falha de atualização, backups, paletas e cores ANSI, ausência de atalhos duplicados, mapa de teclado, imagem do SDDM e fila de wallpapers.

O parser GTK3 disponível também aceitou o CSS gerado das três paletas, da Waybar e do SwayNC. Sem servidor gráfico, o GTK emitiu avisos de ausência de tela ao resolver recursos do Adwaita. Essa verificação cobre a aceitação do CSS, sem validar a aparência final.

## Limites da validação

É necessário confirmar em Arch real o boot/login do SDDM, o desbloqueio, a aparência do Rofi/Kitty/Thunar, o teclado físico e o compartilhamento de tela. Os comandos reais de instalação e os serviços reais não foram executados pelo teste simulado.

Se apenas o teclado do console estiver configurado, confira o layout da sessão Hyprland. O módulo de entrada lê o layout X11 disponível via localectl.

O Neovim-IDE e as dependências externas continuam sendo obtidos dos projetos de origem. A primeira abertura precisa de rede e pode falhar se um download ou uma versão externa mudar. As revisões dos temas preparados são registradas nos logs, mas esta revisão não congela todos os pacotes e plugins.

## Aplicar ao repositório existente

O arquivo **revisao.patch** acompanha o pacote. No clone correspondente ao ZIP recebido, use **git apply --check** antes de aplicá-lo para verificar se a base ainda corresponde.

Depois de aplicar, execute **bash tests/run.sh**, revise o diff, faça o commit e envie ao GitHub. Para instalar numa máquina nova, use o projeto revisado e examine o relatório antes do primeiro reinício.

## Referências consultadas

- [Hyprland e configuração Lua](https://wiki.hypr.land/configuring/core/)
- [Hyprpolkitagent e inicialização do serviço de usuário](https://wiki.hypr.land/hypr-ecosystem/user/hyprpolkitagent/)
- [SDDM Astronaut e suas dependências Qt6](https://github.com/Keyitdev/sddm-astronaut-theme)
- [Nordic GTK](https://github.com/EliverLara/Nordic)
- [Preferência de aparência via portal](https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Settings.html)
- [Extra CMake do LazyVim](https://www.lazyvim.org/extras/lang/cmake)
