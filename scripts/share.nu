# @see https://www.nushell.sh/zh-CN/book/

export def get_globals [] {
    {
        snapshot_needed:  [
            {
                sources: [
                    "~/.local/share/color-schemes",
                    "~/.local/share/plasma",
                    "~/.local/share/icons",
                    "~/.local/share/kwin",
                    "~/.local/share/wallpapers",
                    "~/.local/share/kxmlgui5",
                    "~/.config/Kvantum",
                    "~/.config/dolphinrc"
                    "~/.themes"
                ]
                target: $"./mutable/synchronous/(hostname)"
            }
        ],
        original: "./mutable/synchronous/k99-lite",
    }
}


