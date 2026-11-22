#!/bin/sh
# Publie un pack d'installation par logiciel (Release « pack-installation ») :
#   outils/publier-packs.sh <slug> "<Nom>" [<slug> "<Nom>" ...]
# Chaque zip Pack-d-installation-<Nom>.zip contient le certificat EVINTERTECH, Installer.cmd
# et logiciel.txt (l'identifiant du logiciel à installer). Le nom du zip doit suivre le nom
# du logiciel sur le site : la page Logiciels l'associe ainsi à sa fiche.
set -e
DEPOT=$(cd "$(dirname "$0")/.." && pwd)
TRAVAIL=$(mktemp -d)
FICHIERS=""
while [ $# -ge 2 ]; do
  SLUG="$1"; NOM="$2"; shift 2
  # Même règle que le site (src/lib/logiciels.server.ts, nomPack) : accents retirés, le reste en tirets
  ZIP=$(node -e 'const n = process.argv[1].normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^A-Za-z0-9]+/g, "-").replace(/^-|-$/g, ""); console.log(`Pack-d-installation-${n}.zip`)' "$NOM")
  DOSSIER="$TRAVAIL/Pack d'installation $NOM"
  mkdir -p "$DOSSIER"
  cp "$DEPOT/pack-installation/"* "$DOSSIER/"
  printf '%s\n' "$SLUG" > "$DOSSIER/logiciel.txt"
  (cd "$TRAVAIL" && zip -qr "$ZIP" "Pack d'installation $NOM")
  FICHIERS="$FICHIERS $ZIP"
done
[ -n "$FICHIERS" ] || { echo 'Usage : publier-packs.sh <slug> "<Nom>" [...]'; exit 1; }
NOTES="Un pack par logiciel : il installe le certificat EVINTERTECH puis la dernière version du logiciel.
- Extraire le zip (clic droit, Extraire tout).
- Double-cliquer sur Installer.cmd et répondre Oui pour le certificat." \
ETIQUETTE=pack-installation FICHIERS_EN_PLUS="$FICHIERS" DOSSIER_FICHIERS="$TRAVAIL" \
  "$DEPOT/outils/publier.sh" pack-installation 0.0.0 "$TRAVAIL/$(echo $FICHIERS | cut -d' ' -f1)" /dev/null "Packs d'installation EVINTERTECH"
rm -rf "$TRAVAIL"
