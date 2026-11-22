# Téléchargements EVINTERTECH

Installateurs officiels des logiciels EVINTERTECH, publiés comme « Releases » de ce dépôt.

- Catalogue et historique : https://www.evintertech.com/logiciels
- Étiquettes : `<logiciel>-v<x.y.z>`, ou `<logiciel>-v<x.y.z>-beta.<n>` pendant la bêta (exemple : `fonds-animes-v1.0.0-beta.1`), et `installateurs`.
- Une version finale passe après ses bêtas : 1.0.0-beta.1 < 1.0.0-beta.2 < 1.0.0. Le site ignore les publications antérieures à la colonne `versions_depuis` de la fiche (remise à zéro des numéros pour la bêta).
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

## Installateurs

Un installateur par logiciel, `Installateur-<Nom>.zip`, tous dans la Release `installateurs`.
Modèle : `installateur/` (certificat public `EVINTERTECH-certificat.cer`, `Installer.cmd`, `installer.ps1`).
Publier ou republier tous les installateurs :

```sh
outils/publier-installateurs.sh fonds-animes "Fanimus" wele-tune "Wélé Tune"
```

Le nom passé doit être celui de la fiche sur le site : la page Logiciels relie ainsi chaque installateur à son logiciel.
Fanimus garde l'identifiant `fonds-animes` (les applications déjà installées s'en servent pour leurs mises à jour).
