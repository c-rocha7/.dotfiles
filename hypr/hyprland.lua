------------------
---- MONITORS ----
------------------

hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@60",
    position = "0x0",
    scale = 1,
})

-- Qualquer tela externa (HDMI, DisplayPort, USB-C): resolução ideal, à direita do notebook.
-- Trocar o modo (estender/espelhar/só externa/só notebook): SUPER+SHIFT+P (scripts/monitor.sh).
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto-right",
    scale = 1,
})

-- hl.monitor({
-- output = "DP-2",
-- mode = "1920x1080@240",
-- position = "-1920x0",
-- scale = 1,
-- disabled = true;
-- })


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "ghostty"
local fileManager = "dolphin"
-- Launcher da ilha (Quickshell); se o qs não estiver rodando, cai no rofi
local menu        = [[bash -c "qs ipc call launcher toggle || rofi -show drun -disable-history"]]


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    -- System
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GTK_IM_MODULE PATH")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GTK_IM_MODULE PATH")

    -- Dolphin
    hl.exec_cmd("kbuildsycoca6")

    -- Polkit
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")

    -- Clipvault
    hl.exec_cmd("wl-paste --type text --watch clipvault store")
    -- Imagens até 50 MB (o padrão do clipvault é 5 MB; itens somem após 14 dias)
    hl.exec_cmd("wl-paste --type image --watch clipvault store --max-entry-length 50000000")

    -- Network Manager Applet
    hl.exec_cmd("nm-applet --indicator")

    -- Bluetooth (ícone na bandeja da ilha)
    hl.exec_cmd("blueman-applet")

    -- Barra (Quickshell; config em ~/.config/quickshell)
    hl.exec_cmd("qs")

    -- Noctalia
    -- hl.exec_cmd("noctalia")

    -- Notificações: feitas pelo Quickshell (qs), não usa mais o swaync

    -- Swww
    hl.exec_cmd("awww-daemon")

    -- Waypaper
    hl.exec_cmd("waypaper --restore")

    -- Hypridle
    hl.exec_cmd("hypridle")

    -- Luz noturna por horário (perfis em ~/.config/hypr/hyprsunset.conf)
    hl.exec_cmd("hyprsunset")

    -- Snapshots no menu do Limine (limine-snapper-sync):
    -- avisa erros de sincronização e, ao iniciar por um snapshot, oferece "Restaurar agora"
    hl.exec_cmd("limine-snapper-notify")
    hl.exec_cmd("limine-snapper-restore --notify")

    -- GNOME/GTK
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Breeze-Dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface font-name 'FiraCode Nerd Font 12'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface monospace-font-name 'FiraCode Nerd Font 12'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface document-font-name 'FiraCode Nerd Font 12'")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- Cursor
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")

-- XDG Specifications
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Qt Variables
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- Toolkit Backend Variables
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

-- GTK
hl.env("GTK_IM_MODULE", "simple")

-- Dolphin
hl.env("XDG_MENU_PREFIX", "arch-")

-- Mozilla
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Hyprshot
hl.env("HYPRSHOT_DIR", os.getenv("HOME") .. "/Imagens/Prints")

-- PATH: inclui ~/.local/bin (mise, claude...) para os apps abertos pelo launcher/atalhos
do
    local localBin = os.getenv("HOME") .. "/.local/bin"
    local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
    -- só acrescenta uma vez (o Hyprland reaplica a config a cada recarga)
    if not (":" .. path .. ":"):find(":" .. localBin .. ":", 1, true) then
        path = localBin .. ":" .. path
    end
    hl.env("PATH", path)
end


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in          = 1,
        gaps_out         = 4,

        border_size      = 2,

        col              = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        resize_on_border = false,

        allow_tearing    = false,

        layout           = "scrolling",
    },

    decoration = {
        rounding         = 0,
        rounding_power   = 1,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow           = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur             = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, spring = "easy", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

hl.config({
    dwindle = {
        preserve_split = true,
    },
})

hl.config({
    master = {
        new_status = "master",
    },
})

hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
        explicit_column_widths = "0.5, 1.0",
    },
})


----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper    = -1,
        disable_hyprland_logo      = false,
        middle_click_paste         = true,
        -- Se o programa da tela de bloqueio (Quickshell) cair, outro pode assumir o bloqueio
        allow_session_lock_restore = true,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout          = "br",
        kb_variant         = "abnt2",
        kb_model           = "",
        kb_options         = "",
        kb_rules           = "",

        -- kb_layout = us
        -- kb_variant = intl
        -- kb_model =
        -- kb_options = compose:ralt
        -- kb_rules =

        numlock_by_default = true,

        repeat_rate        = 25,
        repeat_delay       = 600,

        follow_mouse       = 1,

        sensitivity        = 0,

        touchpad           = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

hl.device({
    name          = "lxddz-2.4g-8k-hs-receiver--1",
    sensitivity   = 0,
    accel_profile = "flat",
})


---------------------
---- KEYBINDINGS ----
---------------------

-- local mainMod = "ALT"
local mainMod = "SUPER"

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal), { description = "Apps · Terminal" })
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Janelas · Fechar janela" })
hl.bind(mainMod .. " + M",
    hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"),
    { description = "Sessão · Sair do Hyprland" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager), { description = "Apps · Gerenciador de arquivos" })
-- hl.bind(mainMod .. " + J",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(menu),
    { description = "Ilha · Launcher (apps, :emoji, =conta, >comando)" })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { description = "Janelas · Pseudo-tile" })
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd([[bash -c "~/.config/hypr/scripts/monitor.sh"]]),
    { description = "Tela · Tela externa: estender → espelhar → só externa → só notebook" })
hl.bind("XF86Display", hl.dsp.exec_cmd([[bash -c "~/.config/hypr/scripts/monitor.sh"]]))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Janelas · Tela cheia" })

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }), { description = "Janelas · Focar à esquerda" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { description = "Janelas · Focar à direita" })
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }), { description = "Janelas · Focar acima" })
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }), { description = "Janelas · Focar abaixo" })

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }), { description = "Janelas · Focar à esquerda (vim)" })
-- SUPER+L virou "bloquear tela"; focar à direita fica na seta (SUPER+→)
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Sessão · Bloquear a tela" })
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }), { description = "Janelas · Focar acima (vim)" })
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }), { description = "Janelas · Focar abaixo (vim)" })

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }),
        { description = i == 1 and "Workspaces · Ir para o workspace (1…0)" or nil })
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }),
        { description = i == 1 and "Workspaces · Mover janela para o workspace (1…0)" or nil })
end

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"),
    { description = "Workspaces · Mostrar/esconder o especial" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }),
    { description = "Workspaces · Mover janela para o especial" })

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }),
    { description = "Workspaces · Próximo (rolar o mouse)" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }),
    { description = "Workspaces · Anterior (rolar o mouse)" })

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),
    { mouse = true, description = "Janelas · Arrastar (botão esquerdo)" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(),
    { mouse = true, description = "Janelas · Redimensionar (botão direito)" })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true, description = "Mídia · Aumentar volume" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true, description = "Mídia · Diminuir volume" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, repeating = true, description = "Mídia · Mutar som" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true }) -- tecla de teclados externos (fora do guia)
-- Microfone: o notebook não tem tecla própria (a ilha mostra o aviso de mudo/ligado)
hl.bind(mainMod .. " + ALT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, description = "Mídia · Mutar microfone" })

-- Brilho: passos de 5% visíveis em toda a faixa (0% = mínimo útil da tela).
-- O script (hypr/scripts/brightness.sh) também avisa a ilha do Quickshell.
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd([[bash -c "~/.config/hypr/scripts/brightness.sh up"]]),
    { locked = true, repeating = true, description = "Mídia · Aumentar brilho" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd([[bash -c "~/.config/hypr/scripts/brightness.sh down"]]),
    { locked = true, repeating = true, description = "Mídia · Diminuir brilho" })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Mídia · Próxima faixa" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"),
    { locked = true, description = "Mídia · Tocar/pausar" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Mídia · Tocar/pausar" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Mídia · Faixa anterior" })

-- Clipvault
-- Trocar de janela (lista de janelas no launcher da ilha); sem o qs, cai no rofi
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd([[bash -c "qs ipc call launcher windows || rofi -show window"]]),
    { description = "Ilha · Trocar de janela" })

-- Histórico do clipboard no launcher da ilha; se o qs não estiver rodando, cai no rofi
hl.bind(mainMod .. " + V",
    hl.dsp.exec_cmd(
        [[bash -c "qs ipc call launcher clipboard || (clipvault list | rofi -dmenu -display-columns 2 | clipvault get | wl-copy)"]]),
    { description = "Ilha · Histórico do clipboard" })
hl.bind(mainMod .. " + SHIFT + W",
    hl.dsp.exec_cmd([[bash -c "clipvault clear && notify-send 'Clipvault' 'Histórico limpo!'"]]),
    { description = "Ilha · Limpar histórico do clipboard" })

-- Hyprlock
-- hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

-- Barra (Quickshell): reinicia caso trave
hl.bind(mainMod .. " + SHIFT + Escape", hl.dsp.exec_cmd([[bash -c "pkill -x qs; qs"]]),
    { description = "Ilha · Reiniciar a barra (qs)" })

-- Hyprshot
-- Captura de uma janela
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd([[bash -c "~/.config/hypr/scripts/screenshot.sh window"]]),
    { description = "Capturas · Janela" })

-- Captura de um monitor
hl.bind(mainMod .. " + SHIFT + PRINT", hl.dsp.exec_cmd([[bash -c "~/.config/hypr/scripts/screenshot.sh output"]]),
    { description = "Capturas · Tela inteira" })

-- Captura de uma região
hl.bind("PRINT", hl.dsp.exec_cmd([[bash -c "~/.config/hypr/scripts/screenshot.sh region"]]),
    { description = "Capturas · Região (clique na notificação para editar)" })
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd([[bash -c "~/.config/hypr/scripts/screenshot.sh edit"]]),
    { description = "Capturas · Região e já editar (satty)" })

-- Gravação de tela: a ilha pergunta o áudio antes; o mesmo atalho para a gravação.
-- Sem o qs, grava direto com o som do PC (hypr/scripts/record.sh).
hl.bind(mainMod .. " + R",
    hl.dsp.exec_cmd([[bash -c "qs ipc call recording toggle region || ~/.config/hypr/scripts/record.sh toggle region"]]),
    { description = "Capturas · Gravar região (de novo para parar)" })
hl.bind(mainMod .. " + SHIFT + R",
    hl.dsp.exec_cmd([[bash -c "qs ipc call recording toggle screen || ~/.config/hypr/scripts/record.sh toggle screen"]]),
    { description = "Capturas · Gravar tela inteira (de novo para parar)" })

-- wLogout
-- Menu de energia da ilha (Quickshell); se o qs não estiver rodando, cai no wlogout
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd([[bash -c "qs ipc call power toggle || wlogout --buttons-per-row 4"]]),
    { description = "Sessão · Menu de energia" })

-- Guia de atalhos na ilha (lê as descrições destes atalhos)
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs ipc call wallpaper toggle"), { description = "Ilha · Trocar wallpaper" })
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("qs ipc call keys toggle"), { description = "Ilha · Guia de atalhos" })

-- Yazi
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd("kitty yazi"), { description = "Apps · Yazi (arquivos no terminal)" })

-- Resize columns
hl.bind(mainMod .. " + N", hl.dsp.layout("colresize +conf"), { description = "Janelas · Alternar largura da coluna" })

-- Segure SUPER + [+] ou [-] para redimensionar a janela como uma animação
hl.bind(mainMod .. " + equal", hl.dsp.layout("colresize +0.1"),
    { repeating = true, description = "Janelas · Coluna mais larga" })
hl.bind(mainMod .. " + minus", hl.dsp.layout("colresize -0.1"),
    { repeating = true, description = "Janelas · Coluna mais estreita" })


-----------------
---- WINDOWS ----
-----------------

local suppressMaximizeRule = hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    name     = "fix-xwayland-drags",
    match    = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

hl.window_rule({
    match = { class = "org.pulseaudio.pavucontrol" },
    float = true,
    center = true,
    size = "800 600"
})

hl.window_rule({
    match = { class = "waypaper" },
    float = true,
    center = true,
    size = "1280 720"
})

hl.window_rule({
    match = { class = "io.missioncenter.MissionCenter" },
    float = true,
    center = true,
    size = "1280 720"
})


--------------------
---- WORKSPACES ----
--------------------

hl.workspace_rule({ workspace = "1", monitor = "eDP-1", default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "eDP-1", persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "eDP-1", persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "eDP-1", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "eDP-1", persistent = true })
-- hl.workspace_rule({ workspace = "6",    monitor = "DP-2" , default = true, persistent = true })
-- hl.workspace_rule({ workspace = "7",    monitor = "DP-2", persistent = true })
-- hl.workspace_rule({ workspace = "8",    monitor = "DP-2", persistent = true })
-- hl.workspace_rule({ workspace = "9",    monitor = "DP-2", persistent = true })
-- hl.workspace_rule({ workspace = "10",   monitor = "DP-2", persistent = true })
