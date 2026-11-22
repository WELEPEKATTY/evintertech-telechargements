#!/bin/sh
# Publie le pack testeurs (dossier pack-testeurs/, avec EVINTERTECH-certificat.cer s'il est présent)
set -e
DEPOT=$(cd "$(dirname "$0")/.." && pwd)
ZIP="$DEPOT/Pack-testeurs-EVINTERTECH.zip"
rm -f "$ZIP"
(cd "$DEPOT/pack-testeurs" && zip -q "$ZIP" ./*)
NOTES="Installe le certificat EVINTERTECH puis propose les logiciels Windows publiés sur www.evintertech.com/logiciels.
- Extraire le zip (clic droit, Extraire tout).
- Double-cliquer sur Installer-EVINTERTECH.cmd et répondre Oui pour le certificat." \
ETIQUETTE=pack-testeurs "$DEPOT/outils/publier.sh" pack-testeurs 0.0.0 "$ZIP" /dev/null "Pack testeurs EVINTERTECH"
rm -f "$ZIP"
