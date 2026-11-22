# Téléchargements EVINTERTECH

Installateurs officiels des logiciels EVINTERTECH, publiés comme « Releases » de ce dépôt.

- Catalogue et historique : https://www.evintertech.com/logiciels
- Étiquettes : `<logiciel>-v<x.y.z>` (exemple : `fonds-animes-v1.6.0`) et `pack-testeurs`.
- Le code source des logiciels n'est pas ici, seulement les fichiers à installer.

Aide : support@evintertech.com

## Un seul système pour tous nos logiciels

1. **Fiche** : Administration › Logiciels sur www.evintertech.com, avec un identifiant (`slug`), par exemple `wele-tune`.
2. **Icône** : tuile noire bordée d'or, triangle EVINTERTECH en haut, filet rouge-jaune-vert en bas, un symbole propre au logiciel au centre.
3. **Mises à jour dans l'application** :
   - Electron : copier `kit/electron/mises-a-jour.js` et l'appeler avec `creerMisesAJour({ slug: "wele-tune", … })`.
   - Autres technologies : lire `https://www.evintertech.com/api/public/logiciels/<slug>` (champ `derniere` : `version`, `installateur.url`, `installateur.sha256`).
4. **Publier une version** : `outils/publier.sh <slug> <version> <installateur> <CHANGELOG.md> "<titre>"`.
   La Release `<slug>-v<version>` apparaît ici, sur la page Logiciels et dans l'application.
5. **Signature** : kit `signature/` du dépôt evintertech-fonds (certificat EVINTERTECH).

## Pack testeurs

`pack-testeurs/` : installe le certificat EVINTERTECH puis propose les logiciels Windows publiés.
Avant publication, ajouter `EVINTERTECH-certificat.cer` (partie publique du certificat) dans ce dossier,
puis le zipper et le publier sous l'étiquette `pack-testeurs`.
