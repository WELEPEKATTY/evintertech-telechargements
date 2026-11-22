$ErrorActionPreference = "Stop"
$ici = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host ""
Write-Host "  EVINTERTECH - pack testeurs" -ForegroundColor Yellow
Write-Host ""

# 1. Certificat EVINTERTECH : Windows reconnaît ensuite nos logiciels signés
$cer = Get-ChildItem -Path $ici -Filter "*.cer" | Select-Object -First 1
if ($cer) {
  Write-Host "Windows va demander de confirmer l'ajout du certificat EVINTERTECH : répondez Oui." -ForegroundColor Cyan
  Import-Certificate -FilePath $cer.FullName -CertStoreLocation Cert:\CurrentUser\Root | Out-Null
  Import-Certificate -FilePath $cer.FullName -CertStoreLocation Cert:\CurrentUser\TrustedPublisher | Out-Null
  Write-Host "Certificat EVINTERTECH installé." -ForegroundColor Green
} else {
  Write-Host "Certificat absent du pack : les installateurs fonctionneront, avec l'avertissement de Windows." -ForegroundColor DarkYellow
}

# 2. Logiciels Windows publiés
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$catalogue = Invoke-RestMethod "https://www.evintertech.com/api/public/logiciels"
$windows = @($catalogue.logiciels | Where-Object { $_.plateforme -eq "windows" -and $_.derniere -and $_.derniere.installateur })
if (-not $windows) { Write-Host "Aucun logiciel Windows publié pour le moment."; exit 0 }

foreach ($l in $windows) {
  $rep = Read-Host "Installer $($l.nom) $($l.derniere.version) ? (O/N)"
  if ($rep -notmatch '^[oO]') { continue }
  $f = $l.derniere.installateur
  $dest = Join-Path $env:TEMP $f.nom
  Write-Host "Téléchargement de $($f.nom)..."
  Invoke-WebRequest -Uri $f.url -OutFile $dest -UseBasicParsing
  if ($f.sha256 -and ((Get-FileHash $dest -Algorithm SHA256).Hash.ToLower() -ne $f.sha256)) {
    Write-Host "Fichier abîmé, installation annulée." -ForegroundColor Red; continue
  }
  Unblock-File $dest
  Start-Process -FilePath $dest -Wait
}
Write-Host ""
Write-Host "Terminé. Les mises à jour arriveront ensuite d'elles-mêmes dans chaque application." -ForegroundColor Yellow
