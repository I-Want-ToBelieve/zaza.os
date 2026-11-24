#!/usr/bin/env python3
"""Refresh the portable Krohnkite flake input from a local public checkout."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkout", type=Path, nargs="?", help="local Krohnkite source checkout")
    parser.add_argument("--check", action="store_true", help="verify the existing snapshot against SOURCE.json")
    arguments = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    target = root / "inputs/krohnkite"
    if arguments.check:
        receipt = json.loads((target / "SOURCE.json").read_text(encoding="utf-8"))
        expected = receipt["files"]
        actual = {path.relative_to(target).as_posix() for path in target.rglob("*") if path.is_file() and path.name != "SOURCE.json"}
        if actual != set(expected):
            raise SystemExit("snapshot file inventory differs from SOURCE.json")
        for name, value in expected.items():
            path = target / name
            if not path.resolve().is_relative_to(target.resolve()) or hashlib.sha256(path.read_bytes()).hexdigest() != value:
                raise SystemExit(f"snapshot checksum mismatch: {name}")
        print(f"Verified {len(expected)} public source files against SOURCE.json")
        return
    if arguments.checkout is None:
        parser.error("provide a checkout, or use --check")
    source = arguments.checkout.resolve()
    if not (source / "flake.nix").is_file() or not (source / "upstreams.json").is_file():
        parser.error("checkout must contain the Effect v4 Krohnkite flake and upstreams.json")
    if source == target.resolve() or source.is_relative_to(target.resolve()):
        parser.error("checkout must be independent of the generated input")
    ignored = {".git", ".repo", "node_modules", "dist", ".nx", ".pnpm-store", ".workcache", "coverage", "artifacts", "__pycache__"}
    files = []
    for directory, directories, names in os.walk(source, followlinks=False):
        directories[:] = sorted(name for name in directories if name not in ignored and not Path(directory, name).is_symlink())
        for name in sorted(names):
            path = Path(directory, name)
            if name in ignored or name == "SOURCE.json" or name.startswith("result") or path.is_symlink():
                continue
            relative = path.relative_to(source)
            if path.suffix.lower() in {".pem", ".key"}:
                parser.error(f"private key material cannot be copied: {relative}")
            data = path.read_bytes()
            try:
                text = data.decode("utf-8")
            except UnicodeDecodeError:
                text = None
            if text is not None and "\x00" not in text:
                data = text.replace("\r\n", "\n").encode("utf-8")
            files.append((relative, data))
    try:
        revision = subprocess.check_output(["git", "-c", f"safe.directory={source.as_posix()}", "-C", str(source), "rev-parse", "HEAD"], text=True).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        revision = None
    receipt = {
        "repository": "https://github.com/I-Want-ToBelieve/krohnkite",
        "baseRevision": revision,
        "textLineEndings": "LF",
        "files": {relative.as_posix(): hashlib.sha256(data).hexdigest() for relative, data in files},
    }
    target.parent.mkdir(parents=True, exist_ok=True)
    # Validate the final path before removing an obsolete generated snapshot.
    if target.resolve() != (root.resolve() / "inputs/krohnkite"):
        raise SystemExit("generated input escaped the repository")
    with tempfile.TemporaryDirectory(prefix="krohnkite-source-", dir=target.parent) as temporary:
        prepared = Path(temporary)
        for relative, data in files:
            destination = prepared / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(data)
        (prepared / "SOURCE.json").write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8", newline="\n")
        if target.exists():
            shutil.rmtree(target)
        shutil.copytree(prepared, target)
    print(f"Updated {target} from {len(files)} public source files")
    print("Run nix flake update krohnkite, then the Krohnkite and lvlv VM checks.")


if __name__ == "__main__":
    main()
