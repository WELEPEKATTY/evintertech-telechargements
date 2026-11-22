#!/bin/sh
# Supprime des publications (Release + étiquette) : outils/supprimer.sh <étiquette> [...]
set -e
DEPOT=$(cd "$(dirname "$0")/.." && pwd)
[ $# -ge 1 ] || { echo "Usage : supprimer.sh <étiquette> [...]"; exit 1; }
TRAVAIL=$(mktemp -d)
cd "$DEPOT"
git fetch -q origin main
git worktree prune
git branch -D nettoyage >/dev/null 2>&1 || true
git worktree add -q --detach "$TRAVAIL/arbre" origin/main
cd "$TRAVAIL/arbre"
git checkout -q --orphan nettoyage
git rm -rq --cached . >/dev/null 2>&1 || true
git clean -fdxq -e .github
printf '%s\n' "$@" > suppression.txt
git add .github suppression.txt
git commit -qm "Suppression : $*"
git push -q -f origin nettoyage
cd "$DEPOT" && git worktree remove --force "$TRAVAIL/arbre"
rm -rf "$TRAVAIL"
echo "Demandé : $* (supprimées sur GitHub dans une minute)"
