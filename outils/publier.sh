#!/bin/sh
# Publie une version de n'importe quel logiciel EVINTERTECH :
#   outils/publier.sh <slug> <version> <fichier> <CHANGELOG.md> [titre]
# Un commit sur la branche « televersement » déclenche la Release <slug>-v<version>,
# que la page Logiciels du site et les applications lisent.
set -e
DEPOT=$(cd "$(dirname "$0")/.." && pwd)
SLUG="$1"; VERSION="$2"; FICHIER="$3"; JOURNAL="$4"; TITRE="${5:-$SLUG $VERSION}"
# chemins absolus : le script change de dossier avant de vérifier la taille des fichiers en ligne
FICHIER="$(cd "$(dirname "$FICHIER")" && pwd)/$(basename "$FICHIER")"
[ -n "$DOSSIER_FICHIERS" ] && DOSSIER_FICHIERS="$(cd "$DOSSIER_FICHIERS" && pwd)"
[ -f "$FICHIER" ] || { echo "Usage : publier.sh <slug> <version> <fichier> <CHANGELOG.md> [titre]"; exit 1; }
SETUP=$(basename "$FICHIER")
# Installateur incomplet ou abîmé : on refuse de publier (Windows afficherait « integrity check has failed »)
case "$FICHIER" in
  *.exe|*.zip)
    if command -v 7z >/dev/null; then
      7z t "$FICHIER" >/dev/null 2>&1 || { echo "Refusé : $FICHIER est incomplet ou abîmé (7z t)."; exit 1; }
    else
      echo "Attention : 7z absent, intégrité de $FICHIER non vérifiée."
    fi ;;
esac
# Notes : la section de cette version dans le CHANGELOG
# ETIQUETTE et NOTES peuvent être imposées (ex. installateurs : ETIQUETTE=installateurs)
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
# On attend que GitHub ait joint les fichiers (taille comprise) : deux publications lancées
# coup sur coup se marcheraient dessus sur la branche « televersement »
DEPOT_GH=$(git -C "$DEPOT" remote get-url origin | sed -E 's#.*github.com[:/](.*)\.git$#\1#; s#.*github.com[:/]##')
for F in $LISTE; do
  TAILLE=$(wc -c < "${DOSSIER_FICHIERS:-$(dirname "$FICHIER")}/$F" | tr -d ' ')
  for i in $(seq 1 60); do
    gh api "repos/$DEPOT_GH/releases/tags/$ETIQUETTE" --jq ".assets[] | select(.name == \"$F\") | .size" 2>/dev/null | grep -qx "$TAILLE" && break
    [ "$i" = 60 ] && { echo "Délai dépassé : $F n'est pas encore en ligne sur $ETIQUETTE."; exit 1; }
    sleep 10
  done
done
echo "Publié : $ETIQUETTE"
