# VS Code

Arquivos ligados em `~/.config/Code/User/` (links de arquivo, não da pasta, para o cache
não entrar no repositório):

```bash
ln -s ~/.dotfiles/vscode/settings.json    ~/.config/Code/User/settings.json
ln -s ~/.dotfiles/vscode/keybindings.json ~/.config/Code/User/keybindings.json
```

Reinstalar as extensões numa máquina nova:

```bash
xargs -n1 code --install-extension < ~/.dotfiles/vscode/extensions.txt
```

Atualizar a lista depois de instalar/remover extensões:

```bash
code --list-extensions > ~/.dotfiles/vscode/extensions.txt
```

## Caminhos que mudam por máquina (branch de cada dispositivo)

- `mise.binPath`: `/home/<usuário>/.local/bin/mise`
- `nix.serverSettings.nixd.options`: no notebook, opções do home-manager do flake em
  `~/.dotfiles/nix-dotfiles` (`homeConfigurations."7aauac"`); no desktop, o flake de lá.
- `qt-qml.qmlls.customExePath`: `/usr/lib/qt6/bin/qmlls` (Arch, pacote `qt6-declarative`).
