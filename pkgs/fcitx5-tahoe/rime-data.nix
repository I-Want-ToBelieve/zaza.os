{
  rime-ice,
  python3,
}:
rime-ice.overrideAttrs (old: {
  # 新版 OpenCC 要求 group dict 指定 match_policy；保留原先的优先匹配行为。
  postInstall =
    (old.postInstall or "")
    + ''
      chmod u+w "$out/share/rime-data/opencc/emoji.json"
      ${python3}/bin/python3 - <<'PY'
      import json
      import os
      from pathlib import Path
      path = Path(os.environ["out"]) / "share/rime-data/opencc/emoji.json"
      data = json.loads(path.read_text())
      for step in data["conversion_chain"]:
          dictionary = step["dict"]
          if dictionary["type"] == "group":
              dictionary.setdefault("match_policy", "short_circuit")
      path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
      PY
    '';
})
