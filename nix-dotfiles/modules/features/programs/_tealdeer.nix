{ ... }:

{
  # tldr: exemplos curtos e práticos de comandos (ex.: "tldr tar", "tldr --language pt_BR ffmpeg").
  programs.tealdeer = {
    enable = true;
    enableAutoUpdates = true; # atualiza as páginas sozinho (serviço do home-manager)
    settings = {
      display.compact = false;
      updates.auto_update = true;
    };
  };
}
