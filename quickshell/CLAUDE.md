# Quickshell (moldura) — notas técnicas

- Singletons: `pragma Singleton` tem que ser a **primeira linha**; `shell.qml` precisa de
  `//@ pragma UseQApplication` (menus da bandeja).
- Reiniciar a barra: `SUPER+SHIFT+Esc`. Logs: `qs log $(ls -t /run/user/$UID/quickshell/by-id/*/log.qslog | head -1)`.
