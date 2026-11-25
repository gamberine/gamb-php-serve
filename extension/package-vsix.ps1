param(
    [string]$Version = "0.7.2",
    [string]$OutputDirectory = ""
)

$ErrorActionPreference = "Stop"
$extensionRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $extensionRoot
if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $repoRoot "dist"
}

$staging = Join-Path ([System.IO.Path]::GetTempPath()) ("gamb-php-serve-vsix-" + [guid]::NewGuid().ToString("N"))
$stagedExtension = Join-Path $staging "extension"
$manifestPath = Join-Path $staging "extension.vsixmanifest"
$typesPath = Join-Path $staging "[Content_Types].xml"
$outputPath = Join-Path $OutputDirectory ("gamb-php-serve-vscode-$Version.vsix")

try {
    New-Item -ItemType Directory -Force -Path $stagedExtension, $OutputDirectory | Out-Null
    Copy-Item (Join-Path $extensionRoot "package.json") $stagedExtension
    Copy-Item (Join-Path $extensionRoot "extension.js") $stagedExtension
    Copy-Item (Join-Path $extensionRoot "README.md") $stagedExtension
    Copy-Item (Join-Path $extensionRoot "resources") (Join-Path $stagedExtension "resources") -Recurse

    @"
<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="gamb-php-serve-vscode" Version="$Version" Publisher="gamberine" />
    <DisplayName>Gamb PHP Serve</DisplayName>
    <Description>Dashboard local para projetos PHP, WordPress e bancos MySQL/MariaDB.</Description>
    <Tags>php,wordpress,mysql,mariadb</Tags>
    <Categories>Other</Categories>
    <GalleryFlags>Public</GalleryFlags>
    <Properties>
      <Property Id="Microsoft.VisualStudio.Code.Engine" Value="^1.85.0" />
    </Properties>
  </Metadata>
  <Installation>
    <InstallationTarget Id="Microsoft.VisualStudio.Code" Version="[1.85.0,)" />
  </Installation>
  <Dependencies />
  <Assets>
    <Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" />
  </Assets>
</PackageManifest>
"@ | Set-Content -LiteralPath $manifestPath -Encoding utf8

    @"
<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="json" ContentType="application/json" />
  <Default Extension="js" ContentType="application/javascript" />
  <Default Extension="md" ContentType="text/markdown" />
  <Default Extension="svg" ContentType="image/svg+xml" />
  <Default Extension="xml" ContentType="application/xml" />
</Types>
"@ | Set-Content -LiteralPath $typesPath -Encoding utf8

    if (Test-Path -LiteralPath $outputPath) {
        Remove-Item -LiteralPath $outputPath -Force
    }
    Compress-Archive -Path (Join-Path $staging "*") -DestinationPath $outputPath -CompressionLevel Optimal
    Write-Output $outputPath
}
finally {
    if (Test-Path -LiteralPath $staging) {
        Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
    }
}
