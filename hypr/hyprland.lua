
------------------
---- MONITORS ----
------------------

hl.monitor({
    output = "DP-1",
    mode = "1920x1080@240",
    position = "0x0",
    scale = 1,
})

hl.monitor({
    output = "DP-2",
    mode = "1920x1080@240",
    position = "-1920x0",
    scale = 1,
    -- disabled = true;
})


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "rofi -show drun -disable-history"


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function () 
    -- System
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Dolphin
    hl.exec_cmd("kbuildsycoca6")

    -- Polkit
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")

    -- Clipvault
    hl.exec_cmd("wl-paste --type text --watch clipvault store")
    hl.exec_cmd("wl-paste --type image --watch clipvault store")

    -- Network Manager Applet
    hl.exec_cmd("nm-applet --indicator")

    -- Waybar
    hl.exec_cmd("waybar")

    -- Noctalia
    -- hl.exec_cmd("noctalia")

    -- Swaync
    hl.exec_cmd("swaync")

    -- Swww
    hl.exec_cmd("swww init")

    -- Waypaper
    hl.exec_cmd("waypaper --restore")

    -- Hypridle
    hl.exec_cmd("hypridle")

    -- GNOME/GTK
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Breeze-Dark'")
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
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")

-- Toolkit Backend Variables
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

-- Dolphin
hl.env("XDG_MENU_PREFIX", "arch-")

-- Mozilla
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Hyprshot
hl.env("HYPRSHOT_DIR", os.getenv("HOME") .. "/Imagens/Prints")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 1,
        gaps_out = 4,

        border_size = 2,

        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        resize_on_border = false,

        allow_tearing = false,

        layout = "scrolling",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
            size      = 3,
            passes    = 1,
            vibrancy  = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

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
        force_default_wallpaper = -1,
        disable_hyprland_logo   = false,
        middle_click_paste      = true,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "br",
        kb_variant = "abnt2",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        -- kb_layout = us
        -- kb_variant = intl
        -- kb_model = 
        -- kb_options = compose:ralt
        -- kb_rules =

        numlock_by_default = true,

        repeat_rate  = 25,
        repeat_delay = 600,

        follow_mouse = 1,

        sensitivity = 0,

        touchpad = {
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
    name            = "lxddz-2.4g-8k-hs-receiver--1",
    sensitivity     = 0,
    accel_profile   = "flat",
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "ALT"

hl.bind(mainMod .. " + T",      hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + M",      hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + J",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + Space",  hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P",      hl.dsp.window.pseudo())
hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen({ mode = "fullscreen" }))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume",     hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",     hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",            hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",      hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",    hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Clipvault
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("clipvault list | rofi -dmenu -display-columns 2 | clipvault get | wl-copy"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd([[bash -c "clipvault clear && notify-send 'Clipvault' 'Histórico limpo!'"]]))

-- Hyprlock
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

-- Waybar
hl.bind(mainMod .. " + SHIFT + Escape", hl.dsp.exec_cmd("/home/cauaarch/.dotfiles/waybar/scripts/launch.sh"))

-- Hyprshot
-- Captura de uma janela
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m window"))

-- Captura de um monitor
hl.bind(mainMod .. " + SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m output"))

-- Captura de uma região
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m region"))

-- wLogout
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("wlogout --buttons-per-row 4"))

-- Yazi
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd("kitty yazi"))

-- Resize columns
hl.bind(mainMod .. " + N", hl.dsp.layout("colresize +conf"))

-- Segure SUPER + [+] ou [-] para redimensionar a janela como uma animação
hl.bind(mainMod .. " + equal", hl.dsp.layout("colresize +0.1"), { repeating = true })
hl.bind(mainMod .. " + minus", hl.dsp.layout("colresize -0.1"), { repeating = true })


-----------------
---- WINDOWS ----
-----------------

local suppressMaximizeRule = hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
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

hl.workspace_rule({ workspace = "1",    monitor = "DP-1" , default = true, persistent = true })
hl.workspace_rule({ workspace = "2",    monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "3",    monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "4",    monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "5",    monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "6",    monitor = "DP-2" , default = true, persistent = true })
hl.workspace_rule({ workspace = "7",    monitor = "DP-2", persistent = true })
hl.workspace_rule({ workspace = "8",    monitor = "DP-2", persistent = true })
hl.workspace_rule({ workspace = "9",    monitor = "DP-2", persistent = true })
hl.workspace_rule({ workspace = "10",   monitor = "DP-2", persistent = true })
