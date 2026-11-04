#!/usr/bin/env python3
"""Publie une nouvelle version d'un package Cloudron de ce dépôt.

    python3 -I scripts/release.py <dossier> --upstream <ref> --changelog "<texte>" [--version X.Y.Z]

- bumpe le patch de `version` dans <dossier>/CloudronManifest.json (ou prend --version)
- met à jour upstreamVersion et changelog
- ajoute l'entrée correspondante dans <dossier>/CloudronVersions.json avec dockerImage
Affiche la nouvelle version sur stdout.
"""
import argparse, email.utils, json, sys
from pathlib import Path

IMAGE_OWNER = "ghcr.io/vitetj"

def dump(path, obj, indent):
    path.write_text(json.dumps(obj, indent=indent, ensure_ascii=False) + "\n", encoding="utf-8")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dir")
    ap.add_argument("--upstream", required=True)
    ap.add_argument("--changelog", required=True)
    ap.add_argument("--version")
    a = ap.parse_args()

    d = Path(a.dir)
    name = "key-connector" if d.resolve() == Path.cwd().resolve() else d.name
    mpath, vpath = d / "CloudronManifest.json", d / "CloudronVersions.json"
    m = json.loads(mpath.read_text(encoding="utf-8"))
    versions = json.loads(vpath.read_text(encoding="utf-8"))

    if a.version:
        new = a.version
    else:
        major, minor, patch = (int(x) for x in m["version"].split("."))
        new = f"{major}.{minor}.{patch + 1}"
    if new in versions["versions"]:
        sys.exit(f"version {new} existe déjà dans {vpath}")

    m["version"] = new
    m["upstreamVersion"] = a.upstream
    m["changelog"] = f"* {new} : {a.changelog}"
    dump(mpath, m, 2)

    now = email.utils.formatdate(usegmt=True)
    vm = dict(m, dockerImage=f"{IMAGE_OWNER}/{name}:{new}")
    versions["versions"][new] = {"manifest": vm, "creationDate": now, "ts": now, "publishState": "published"}
    dump(vpath, versions, 4)
    print(new)

if __name__ == "__main__":
    main()
