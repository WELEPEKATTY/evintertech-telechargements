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
# ETIQUETTE et NOTES peuvent être imposées (ex. packs d'installation : ETIQUETTE=pack-installation)
ETIQUETTE=${ETIQUETTE:-$SLUG-v$VERSION}
[ -n "$NOTES" ] || NOTES=$(awk -v v="## [$VERSION]" 'index($0, v) == 1 { dedans = 1; next } /^## \[/ { if (dedans) exit } dedans' "$JOURNAL" | sed '/^$/d')

# FICHIERS_EN_PLUS (noms dans DOSSIER_FICHIERS) : plusieurs fichiers dans la même Release
TRAVAIL=$(mktemp -d)
LISTE=${FICHIERS_EN_PLUS:-$SETUP}
for F in $LISTE; do cp "${DOSSIER_FICHIERS:-$(dirname "$FICHIER")}/$F" "$TRAVAIL/"; done
node -e '
const [etiquette, titre, notes, liste, dossier] = process.argv.slice(1);
require("fs").writeFileSync(dossier + "/publication.json", JSON.stringify({ etiquette, titre, notes, fichiers: liste.trim().split(/\s+/) }, null, 2));
 ' "$ETIQUETTE" "$TITRE" "$NOTES" "$LISTE" "$TRAVAIL"

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
git clean -fdxq -e .github
for F in $LISTE; do cp "$TRAVAIL/$F" .; done
cp "$TRAVAIL/publication.json" .
git add .github publication.json $LISTE
git commit -qm "Publication $ETIQUETTE"
git push -q -f origin televersement
cd "$DEPOT" && git worktree remove --force "$TRAVAIL/arbre"
rm -rf "$TRAVAIL"
echo "Publié : $ETIQUETTE (la Release apparaît sur GitHub dans une minute)"
