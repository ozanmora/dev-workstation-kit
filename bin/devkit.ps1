Param(
  [Parameter(Position=0)]
  [string]$Cmd = "help",
  [Parameter(ValueFromRemainingArguments=$true)]
  [string[]]$Args
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

function Ensure-Env {
  if (!(Test-Path ".env")) { Copy-Item ".env.example" ".env" }
}

function Gen {
  Ensure-Env
  if (Get-Command node -ErrorAction SilentlyContinue) {
    node scripts/gen-nginx.mjs
  } else {
    docker compose run --rm -T node node scripts/gen-nginx.mjs
  }
}

switch ($Cmd) {
  "bootstrap" {
    Ensure-Env
    New-Item -ItemType Directory -Force -Path "docker\certs" | Out-Null
    New-Item -ItemType Directory -Force -Path "data\mariadb" | Out-Null
    New-Item -ItemType Directory -Force -Path "projects\app\public" | Out-Null

@"
<?php
echo "<h1>Dev Workstation Kit</h1>";
echo "<p>Routing is controlled via <code>config/routes.txt</code>.</p>";
phpinfo();
"@ | Set-Content -Encoding UTF8 "projects\app\public\index.php"

    $crt = "docker\certs\devkit.crt"
    $key = "docker\certs\devkit.key"
    if (!(Test-Path $crt) -or !(Test-Path $key)) {
      if (Get-Command openssl -ErrorAction SilentlyContinue) {
        & openssl req -x509 -nodes -newkey rsa:2048 -days 3650 `
          -keyout $key -out $crt `
          -subj "/C=TR/ST=Izmir/L=Izmir/O=DevKit/OU=Local/CN=local.test" `
          -addext "subjectAltName=DNS:*.local.test,DNS:local.test"
      } else {
        Write-Host "[devkit] OpenSSL not found in PATH. Install OpenSSL or use mkcert. See docs/tls.md"
      }
    }

    Gen
    docker compose up -d --remove-orphans
  }

  "gen" { Gen }
  "up" { Ensure-Env; docker compose up -d --remove-orphans }
  "build" { Ensure-Env; docker compose build --no-cache }
  "down" { Ensure-Env; docker compose down }
  "logs" { Ensure-Env; docker compose logs -f --tail=200 }
  "ps" { Ensure-Env; docker compose ps }
  "reset" {
    Ensure-Env
    docker compose down
    if (Test-Path "data") { Remove-Item -Recurse -Force "data" }
    New-Item -ItemType Directory -Force -Path "data\mariadb" | Out-Null
    Write-Host "[devkit] data/ wiped."
  }

  "npm" { Ensure-Env; docker compose run --rm node npm @Args }
  "yarn" {
    Ensure-Env
    $joined = ($Args -join " ")
    docker compose run --rm node bash -lc "corepack enable >/dev/null 2>&1 || true; yarn $joined"
  }

"init" {
  # Run inside the project folder
  $domain = ""
  $type = "php"
  $phpver = "84"
  $docroot = ""
  $urlPath = "/"
  $public = $false
  $wordpress = $false
  $react = $false
  $devPort = ""

  for ($i=0; $i -lt $Args.Count; $i++) {
    switch ($Args[$i]) {
      "--domain" { $domain = $Args[$i+1]; $i++ }
      "--type" { $type = $Args[$i+1]; $i++ }
      "--php" { $phpver = $Args[$i+1]; $i++ }
      "--docroot" { $docroot = $Args[$i+1]; $i++ }
      "--url-path" { $urlPath = $Args[$i+1]; $i++ }
      "--public" { $public = $true }
      "--wordpress" { $wordpress = $true }
      "--react" { $react = $true }
      "--dev-port" { $devPort = $Args[$i+1]; $i++ }
    }
  }

  if ([string]::IsNullOrWhiteSpace($domain)) {
    Write-Host "[devkit] init requires --domain"
    break
  }

  if ($urlPath -eq "") { $urlPath = "/" }
  if (-not $urlPath.StartsWith("/")) { $urlPath = "/" + $urlPath }
  if ($urlPath.Length -gt 1 -and $urlPath.EndsWith("/")) { $urlPath = $urlPath.TrimEnd("/") }

  if ($docroot -eq "") {
    if ($wordpress) { $docroot = "." }
    elseif ($public) { $docroot = "public" }
    elseif ($react) { $type = "static"; $docroot = "dist" }
    else { $docroot = "public" }
  }
  if ($react) { $type = "static" }

  New-Item -ItemType Directory -Force -Path ".devkit" | Out-Null
  $out = ".devkit\devkit.yml"

  $lines = @()
  $lines += "version: 1"
  $lines += "domain: $domain"
  if ($urlPath -ne "/") { $lines += "url_path: $urlPath" }
  $lines += "type: $type"
  if ($type -eq "php") { $lines += "php: `"$phpver`"" }
  $lines += "docroot: $docroot"
  if ($devPort -ne "") {
    $lines += ""
    $lines += "dev:"
    $lines += "  port: $devPort"
  }

  $lines | Set-Content -Encoding UTF8 $out
  Write-Host "[devkit] Wrote $out"
  Write-Host "[devkit] Next: run from DevKit root:"
  Write-Host "  .\bin\devkit.ps1 gen"
  Write-Host "  .\bin\devkit.ps1 up"
}

  Default {
@"
DevKit commands:
  .\bin\devkit.ps1 bootstrap
  .\bin\devkit.ps1 gen
  .\bin\devkit.ps1 up|down|build|logs|ps|reset

Node helpers:
  .\bin\devkit.ps1 npm  -- <npm args>
  .\bin\devkit.ps1 yarn <yarn args>

Examples:
  .\bin\devkit.ps1 yarn -C projects\react-app install
  .\bin\devkit.ps1 npm -- --prefix projects\react-app run build
"@ | Write-Host
  }
}
