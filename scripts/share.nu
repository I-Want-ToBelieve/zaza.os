# @see https://www.nushell.sh/zh-CN/book/

export def get_globals [] {
    {
        snapshot_needed:  [
            {
                sources: [
                    "~/.local/share/color-schemes",
                    "~/.local/share/plasma"
                ]
                target: $"./sync/(hostname)"
            }
        ],
        original: "./sync/k99-lite",
    }
}


