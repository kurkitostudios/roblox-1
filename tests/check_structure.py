#!/usr/bin/env python3
"""Controlli statici sul layout Script Sync, sui require e sui remote."""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errors = []

def rel(path: Path) -> str:
    return str(path.relative_to(ROOT))

sync_roots = [
    ROOT / "server" / "GameServer",
    ROOT / "client" / "GameClient",
    ROOT / "shared" / "Shared",
]

for root in sync_roots:
    if not root.exists():
        errors.append(f"Cartella mancante: {rel(root)}")
        continue
    for path in root.rglob("*"):
        if path.is_dir():
            continue
        name = path.name
        if name == "init.luau" or name.startswith("init."):
            errors.append(f"init non consentito nella root di sync: {rel(path)}")
        if path.suffix not in {".luau", ".md"} and not name.endswith(".luau"):
            errors.append(f"File non Luau dentro una cartella sincronizzata: {rel(path)}")

legacy = ROOT / "server" / "GameServer" / "TestSync.legacy.luau"
if not legacy.exists() or "Cursor Cloud" not in legacy.read_text():
    errors.append("TestSync.legacy.luau è stato alterato o rimosso.")

main = ROOT / "server" / "GameServer" / "Main.server.luau"
client = ROOT / "client" / "GameClient" / "ClientBootstrap.local.luau"
if not main.exists():
    errors.append("Manca Main.server.luau")
if not client.exists():
    errors.append("Manca ClientBootstrap.local.luau")

module_names = {}
for root in sync_roots:
    for path in root.rglob("*.luau"):
        stem = path.name
        for suffix in (".server.luau", ".client.luau", ".local.luau", ".legacy.luau", ".plugin.luau", ".luau"):
            if stem.endswith(suffix):
                stem = stem[: -len(suffix)]
                break
        module_names.setdefault(path.parent, set()).add(stem)

require_parent = re.compile(r'require\(\s*script\.Parent(?:\.Parent)?\.([A-Za-z0-9_]+)\s*\)')
require_shared = re.compile(r'''(?:shared|Shared)\s*(?:\(\s*|\:WaitForChild\(\s*)["']([A-Za-z0-9_]+)["']''')
wait_shared = re.compile(r'WaitForChild\(\s*"([A-Za-z0-9_]+)"\s*\)')

shared_dir = ROOT / "shared" / "Shared"
shared_modules = {p.name[:-5] for p in shared_dir.glob("*.luau")}

for path in list((ROOT / "server").rglob("*.luau")) + list((ROOT / "client").rglob("*.luau")) + list((ROOT / "shared").rglob("*.luau")):
    text = path.read_text()
    for match in require_parent.finditer(text):
        target = match.group(1)
        # script.Parent.Parent è usato solo se presente: il target è il nome finale.
        if target not in module_names.get(path.parent, set()) and target not in module_names.get(path.parent.parent, set()):
            errors.append(f"{rel(path)} richiede '{target}', che non è un modulo fratello o zio.")
    for match in require_shared.finditer(text):
        target = match.group(1)
        if target not in shared_modules:
            errors.append(f"{rel(path)} richiede Shared.{target}, che non esiste.")

remote_text = (shared_dir / "RemoteNames.luau").read_text()
remote_names = set(re.findall(r'"([A-Za-z0-9_]+)"', remote_text))
for path in (ROOT / "server").rglob("*.luau"):
    for match in re.finditer(r'\.Bind\(\s*ctx\s*,\s*"([A-Za-z0-9_]+)"', path.read_text()):
        if match.group(1) not in remote_names:
            errors.append(f"Remote non dichiarato: {match.group(1)} in {rel(path)}")

if errors:
    print("ERRORI STRUTTURA")
    for error in errors:
        print(" -", error)
    sys.exit(1)

print("STRUCTURE_OK")
print(f"Moduli Shared: {len(shared_modules)}")
