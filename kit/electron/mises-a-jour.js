// Mises à jour depuis la page Logiciels du site EVINTERTECH — module commun à toutes nos
// applications Electron (copie de référence : evintertech-telechargements/kit/electron).
// L'API donne la dernière version publiée et l'adresse de son installateur (hébergé sur GitHub) ;
// l'installateur est téléchargé, vérifié (SHA-256), puis lancé en silencieux : il remplace
// l'application et la relance.
const { app, net } = require("electron");
const fs = require("node:fs");
const path = require("node:path");
const crypto = require("node:crypto");
const { spawn } = require("node:child_process");

const SITE = "https://www.evintertech.com";

// « 1.0.0-beta.2 » → [1, 0, 0, 2] ; une version finale passe après toutes ses bêtas
const decouper = (v) => {
  const m = /^(\d+)\.(\d+)\.(\d+)(?:-beta\.(\d+))?$/.exec(String(v));
  return m ? [+m[1], +m[2], +m[3], m[4] === undefined ? Infinity : +m[4]] : [0, 0, 0, 0];
};
const plusRecente = (a, b) => {
  const pa = decouper(a);
  const pb = decouper(b);
  for (let i = 0; i < 4; i++) if (pa[i] !== pb[i]) return pa[i] > pb[i];
  return false;
};

// slug : l'identifiant du logiciel sur la page Logiciels (et dans les étiquettes GitHub <slug>-vX.Y.Z)
function creerMisesAJour({ slug, surChangement, journal }) {
  const API = `${SITE}/api/public/logiciels/${slug}`;
  let etat = { etat: "inconnu", version: null, notes: "", progression: 0, message: "", page: `${SITE}/logiciels/${slug}` };
  let derniere = null;
  const changer = (modifs) => {
    etat = { ...etat, ...modifs };
    surChangement(etat);
  };

  async function verifier() {
    if (["telechargement", "installation"].includes(etat.etat)) return etat;
    changer({ etat: "verification", message: "" });
    try {
      const reponse = await net.fetch(`${API}?v=${app.getVersion()}`, { cache: "no-store" });
      if (!reponse.ok) throw new Error(`Le site a répondu ${reponse.status}`);
      const fiche = await reponse.json();
      derniere = fiche.derniere;
      if (derniere?.installateur && plusRecente(derniere.version, app.getVersion())) {
        changer({ etat: "disponible", version: derniere.version, notes: derniere.notes || "" });
      } else {
        changer({ etat: "a-jour", version: derniere?.version ?? app.getVersion() });
      }
    } catch (erreur) {
      journal("mise-a-jour", "verification", String(erreur));
      changer({ etat: "erreur", message: "Vérification impossible (hors ligne ?)" });
    }
    return etat;
  }

  function telecharger(url, destination, tailleAttendue) {
    return new Promise((ok, echec) => {
      const requete = net.request({ url, redirect: "follow" });
      requete.on("response", (reponse) => {
        if (reponse.statusCode !== 200) return echec(new Error(`Téléchargement refusé (${reponse.statusCode})`));
        const total = Number(reponse.headers["content-length"]) || tailleAttendue || 0;
        const fichier = fs.createWriteStream(destination);
        const empreinte = crypto.createHash("sha256");
        let recu = 0;
        reponse.on("data", (morceau) => {
          recu += morceau.length;
          empreinte.update(morceau);
          fichier.write(morceau);
          if (total) changer({ progression: Math.round((recu / total) * 100) });
        });
        reponse.on("end", () => fichier.end(() => ok(empreinte.digest("hex"))));
        reponse.on("error", echec);
      });
      requete.on("error", echec);
      requete.end();
    });
  }

  async function installer() {
    if (etat.etat !== "disponible" || !derniere?.installateur) await verifier();
    if (etat.etat !== "disponible") return etat;
    const { url, sha256, taille, nom } = derniere.installateur;
    const destination = path.join(app.getPath("temp"), nom || `${slug}-${derniere.version}-setup.exe`);
    changer({ etat: "telechargement", progression: 0, message: "" });
    try {
      const empreinte = await telecharger(url, destination, taille);
      if (sha256 && empreinte !== sha256) throw new Error("Le fichier téléchargé est abîmé (empreinte différente)");
      changer({ etat: "installation", progression: 100 });
      journal("mise-a-jour", "installation", derniere.version);
      // /S : installation silencieuse ; l'installateur ferme cette application puis la relance
      spawn(destination, ["/S"], { detached: true, stdio: "ignore", windowsHide: true }).unref();
      setTimeout(() => app.quit(), 1500);
    } catch (erreur) {
      journal("mise-a-jour", "echec", String(erreur));
      changer({ etat: "disponible", message: String(erreur.message || erreur) });
    }
    return etat;
  }

  return { verifier, installer, etat: () => etat };
}

module.exports = { creerMisesAJour };
