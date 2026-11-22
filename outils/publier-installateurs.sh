#!/bin/sh
# Publie un installateur par logiciel (Release « installateurs ») :
#   outils/publier-installateurs.sh <slug> "<Nom>" [<slug> "<Nom>" ...]
# Chaque zip Installateur-<Nom>.zip contient le certificat EVINTERTECH, Installer.cmd
# et logiciel.txt (l'identifiant du logiciel à installer). Le nom du zip doit suivre le nom
# du logiciel sur le site : la page Logiciels l'associe ainsi à sa fiche.
set -e
DEPOT=$(cd "$(dirname "$0")/.." && pwd)
TRAVAIL=$(mktemp -d)
FICHIERS=""
while [ $# -ge 2 ]; do
  SLUG="$1"; NOM="$2"; shift 2
  # Même règle que le site (src/lib/logiciels.server.ts, nomInstallateur) : accents retirés, le reste en tirets
  ZIP=$(node -e 'const n = process.argv[1].normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^A-Za-z0-9]+/g, "-").replace(/^-|-$/g, ""); console.log(`Installateur-${n}.zip`)' "$NOM")
  DOSSIER="$TRAVAIL/Installateur $NOM"
  mkdir -p "$DOSSIER"
  cp "$DEPOT/installateur/"* "$DOSSIER/"
  printf '%s\n' "$SLUG" > "$DOSSIER/logiciel.txt"
  (cd "$TRAVAIL" && zip -qr "$ZIP" "Installateur $NOM")
  FICHIERS="$FICHIERS $ZIP"
done
[ -n "$FICHIERS" ] || { echo 'Usage : publier-installateurs.sh <slug> "<Nom>" [...]'; exit 1; }
NOTES="Un installateur par logiciel : il installe le certificat EVINTERTECH puis la dernière version du logiciel.
- Extraire le zip (clic droit, Extraire tout).
- Double-cliquer sur Installer.cmd et répondre Oui pour le certificat." \
ETIQUETTE=installateurs FICHIERS_EN_PLUS="$FICHIERS" DOSSIER_FICHIERS="$TRAVAIL" \
  "$DEPOT/outils/publier.sh" installateurs 0.0.0 "$TRAVAIL/$(echo $FICHIERS | cut -d' ' -f1)" /dev/null "Installateurs EVINTERTECH"
rm -rf "$TRAVAIL"
