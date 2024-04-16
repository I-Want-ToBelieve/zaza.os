# @see https://www.nushell.sh/zh-CN/book/

export def get_globals [] {
    {
        snapshot_needed:  [
            {
                sources: [
                    "~/.local/share/color-schemes",
                    "~/.local/share/plasma",
                    "~/.config/Kvantum"
                ]
                target: $"./mutable/synchronous/(hostname)"
            }
        ],
        original: "./mutable/synchronous/k99-lite",
    }
}


