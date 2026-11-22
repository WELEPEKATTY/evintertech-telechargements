$ErrorActionPreference = "Stop"
$ici = Split-Path -Parent $MyInvocation.MyCommand.Path
# Le logiciel de cet installateur (identifiant de la page Logiciels), écrit à la publication
$slug = (Get-Content (Join-Path $ici "logiciel.txt") -Raw).Trim()

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$fiche = Invoke-RestMethod "https://www.evintertech.com/api/public/logiciels/$slug"
Write-Host ""
Write-Host "  EVINTERTECH - installateur $($fiche.nom)" -ForegroundColor Yellow
Write-Host ""

# 1. Certificat EVINTERTECH : Windows reconnaît ensuite nos logiciels signés
$cer = Get-ChildItem -Path $ici -Filter "*.cer" | Select-Object -First 1
if ($cer) {
  Write-Host "Windows va demander de confirmer l'ajout du certificat EVINTERTECH : répondez Oui." -ForegroundColor Cyan
  Import-Certificate -FilePath $cer.FullName -CertStoreLocation Cert:\CurrentUser\Root | Out-Null
  Import-Certificate -FilePath $cer.FullName -CertStoreLocation Cert:\CurrentUser\TrustedPublisher | Out-Null
  Write-Host "Certificat EVINTERTECH installé." -ForegroundColor Green
} else {
  Write-Host "Certificat absent : l'installation fonctionnera, avec l'avertissement de Windows." -ForegroundColor DarkYellow
}

# 2. Dernière version du logiciel
$f = $fiche.derniere.installateur
if (-not $f) { Write-Host "$($fiche.nom) n'est pas encore publié."; exit 0 }
$dest = Join-Path $env:TEMP $f.nom
$version = $fiche.derniere.version -replace '-beta\.(\d+)$', ' bêta $1'
Write-Host "Téléchargement de $($fiche.nom) $version..."
Invoke-WebRequest -Uri $f.url -OutFile $dest -UseBasicParsing
if ($f.sha256 -and ((Get-FileHash $dest -Algorithm SHA256).Hash.ToLower() -ne $f.sha256)) {
  Write-Host "Fichier abîmé, installation annulée." -ForegroundColor Red; exit 1
}
Unblock-File $dest
Start-Process -FilePath $dest -Wait
Write-Host ""
Write-Host "Terminé. Les mises à jour arriveront ensuite d'elles-mêmes dans $($fiche.nom)." -ForegroundColor Yellow
