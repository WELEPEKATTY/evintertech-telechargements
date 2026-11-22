#!/bin/sh
# Publie une version de n'importe quel logiciel EVINTERTECH :
#   outils/publier.sh <slug> <version> <fichier> <CHANGELOG.md> [titre]
# Un commit sur la branche « televersement » déclenche la Release <slug>-v<version>,
# que la page Logiciels du site et les applications lisent.
set -e
DEPOT=$(cd "$(dirname "$0")/.." && pwd)
SLUG="$1"; VERSION="$2"; FICHIER="$3"; JOURNAL="$4"; TITRE="${5:-$SLUG $VERSION}"
[ -f "$FICHIER" ] || { echo "Usage : publier.sh <slug> <version> <fichier> <CHANGELOG.md> [titre]"; exit 1; }
SETUP=$(basename "$FICHIER")
# Notes : la section de cette version dans le CHANGELOG
NOTES=$(awk -v v="## [$VERSION]" 'index($0, v) == 1 { dedans = 1; next } /^## \[/ { if (dedans) exit } dedans' "$JOURNAL" | sed '/^$/d')

TRAVAIL=$(mktemp -d)
cp "$FICHIER" "$TRAVAIL/"
node -e '
const [etiquette, titre, notes, fichier] = process.argv.slice(1);
require("fs").writeFileSync(process.argv[5] + "/publication.json", JSON.stringify({ etiquette, titre, notes, fichiers: [fichier] }, null, 2));
 ' "$SLUG-v$VERSION" "$TITRE" "$NOTES" "$SETUP" "$TRAVAIL"

cd "$DEPOT"
git fetch -q origin main
git worktree prune
git branch -D televersement >/dev/null 2>&1 || true
# Branche sans historique : les anciens installateurs ne s'accumulent pas dans le dépôt
git worktree add -q --detach "$TRAVAIL/arbre" origin/main
cd "$TRAVAIL/arbre"
git checkout -q --orphan televersement
git rm -rq --cached . >/dev/null 2>&1 || true
# On garde .github : GitHub ne lance le flux que s'il est dans le commit poussé
rm -rf ./* 2>/dev/null || true
cp "$TRAVAIL/$SETUP" "$TRAVAIL/publication.json" .
git add .github "$SETUP" publication.json
git commit -qm "Publication $SLUG-v$VERSION"
git push -q -f origin televersement
cd "$DEPOT" && git worktree remove --force "$TRAVAIL/arbre"
rm -rf "$TRAVAIL"
echo "Publié : $SLUG-v$VERSION (la Release apparaît sur GitHub dans une minute)"
