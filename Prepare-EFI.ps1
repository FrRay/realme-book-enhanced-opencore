[CmdletBinding()]
param(
    [string]$OutputDirectory = 'EFI-ready',
    [ValidateSet('Upstream', 'Personal', 'Disabled')]
    [string]$Touchpad = 'Upstream',
    [string]$PersonalEfi
)

$ErrorActionPreference = 'Stop'
$base = Join-Path $PSScriptRoot 'EFI'
if (-not (Test-Path -LiteralPath (Join-Path $base 'BOOT/BOOTx64.efi') -PathType Leaf)) {
    throw 'The EFI release ZIP must be extracted before running this script.'
}
if ($Touchpad -eq 'Personal' -and -not $PersonalEfi) {
    throw 'Personal mode requires -PersonalEfi pointing to an existing EFI folder.'
}

$destination = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDirectory)
if (Test-Path -LiteralPath $destination) {
    throw "Output folder already exists: $destination"
}
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'dependencies.json') -Raw | ConvertFrom-Json

function Read-Plist {
    param([string]$Path)
    $xml = [System.Xml.XmlDocument]::new()
    $xml.PreserveWhitespace = $true
    $xml.XmlResolver = $null
    $xml.Load($Path)
    return ,$xml
}

function Get-PlistValue {
    param([System.Xml.XmlNode]$Dictionary, [string]$Key)
    return $Dictionary.SelectSingleNode("key[.='$Key']/following-sibling::*[1]")
}

function Copy-Dependency {
    param($Dependency, [string]$Staging, [string]$Cache)
    $archive = Join-Path $Cache $Dependency.file
    Write-Host "Downloading $($Dependency.file)"
    Invoke-WebRequest -Uri $Dependency.url -OutFile $archive -UseBasicParsing -TimeoutSec 90
    $actual = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
    if ($actual -ne $Dependency.sha256) {
        throw "Checksum mismatch: $($Dependency.file)"
    }
    if ($Dependency.target) {
        $target = Join-Path $Staging $Dependency.target
        New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        Copy-Item -LiteralPath $archive -Destination $target
        return
    }

    $expanded = Join-Path $Cache ([IO.Path]::GetFileNameWithoutExtension($Dependency.file))
    Expand-Archive -LiteralPath $archive -DestinationPath $expanded
    foreach ($bundle in $Dependency.bundles) {
        $bundlePaths = @(Get-ChildItem -LiteralPath $expanded -Filter $bundle.name -Directory -Recurse |
            Where-Object { $_.Name -eq $bundle.name -and $_.FullName -notmatch '[\\/]__MACOSX[\\/]' })
        if ($bundlePaths.Count -ne 1) {
            throw "Expected one $($bundle.name) in $($Dependency.file)"
        }
        $target = Join-Path (Join-Path $Staging 'EFI/OC/Kexts') $bundle.target
        Copy-Item -LiteralPath $bundlePaths[0].FullName -Destination $target -Recurse
    }
}

function Assert-OpenCoreFiles {
    param([System.Xml.XmlDocument]$Config, [string]$OcFolder)
    $dict = $Config.DocumentElement.SelectSingleNode('dict')
    $kernel = Get-PlistValue $dict 'Kernel'
    foreach ($entry in (Get-PlistValue $kernel 'Add').SelectNodes('dict')) {
        if ((Get-PlistValue $entry 'Enabled').Name -ne 'true') { continue }
        $bundle = (Get-PlistValue $entry 'BundlePath').InnerText
        foreach ($key in @('PlistPath', 'ExecutablePath')) {
            $path = (Get-PlistValue $entry $key).InnerText
            if ($path -and -not (Test-Path -LiteralPath (Join-Path $OcFolder "Kexts/$bundle/$path") -PathType Leaf)) {
                throw "Missing enabled kext file: $bundle/$path"
            }
        }
    }

    foreach ($pair in @(@('ACPI','Add','ACPI'), @('UEFI','Drivers','Drivers'))) {
        $section = Get-PlistValue $dict $pair[0]
        foreach ($entry in (Get-PlistValue $section $pair[1]).SelectNodes('dict')) {
            if ((Get-PlistValue $entry 'Enabled').Name -ne 'true') { continue }
            $path = (Get-PlistValue $entry 'Path').InnerText
            if (-not (Test-Path -LiteralPath (Join-Path $OcFolder "$($pair[2])/$path") -PathType Leaf)) {
                throw "Missing enabled boot file: $path"
            }
        }
    }
}

$tempRoot = (Resolve-Path -LiteralPath ([IO.Path]::GetTempPath())).Path.TrimEnd('\')
$work = Join-Path $tempRoot ('realme-efi-' + [guid]::NewGuid().ToString('N'))
$staging = Join-Path $work 'output'
$cache = Join-Path $work 'downloads'
New-Item -ItemType Directory -Path $staging,$cache | Out-Null
try {
    Copy-Item -LiteralPath $base -Destination $staging -Recurse
    foreach ($dependency in $manifest.dependencies) {
        if ($dependency.group -eq 'touchpad' -and $Touchpad -ne 'Upstream') { continue }
        Copy-Dependency $dependency $staging $cache
    }

    $ocFolder = Join-Path $staging 'EFI/OC'
    $assembledConfig = Join-Path $ocFolder 'config.plist'
    $config = Read-Plist $assembledConfig
    if ($Touchpad -eq 'Personal') {
        $personalRoot = (Resolve-Path -LiteralPath $PersonalEfi).Path
        foreach ($property in $manifest.personalTouchpadFiles.PSObject.Properties) {
            $source = Join-Path $personalRoot "OC/Kexts/$($property.Name)"
            if (-not (Test-Path -LiteralPath $source -PathType Leaf) -or
                (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $property.Value) {
                throw "Personal touchpad file is missing or differs: $($property.Name)"
            }
            $target = Join-Path $ocFolder "Kexts/$($property.Name)"
            New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
            Copy-Item -LiteralPath $source -Destination $target
        }
    }
    if ($Touchpad -eq 'Disabled') {
        $kernel = Get-PlistValue ($config.DocumentElement.SelectSingleNode('dict')) 'Kernel'
        foreach ($entry in (Get-PlistValue $kernel 'Add').SelectNodes('dict')) {
            $bundle = (Get-PlistValue $entry 'BundlePath').InnerText
            if ($bundle -notmatch '^VoodooI2C(?:HID)?\.kext(?:/|$)') { continue }
            [void]$entry.ReplaceChild($config.CreateElement('false'), (Get-PlistValue $entry 'Enabled'))
        }
        [IO.File]::WriteAllText($assembledConfig, $config.OuterXml, [Text.UTF8Encoding]::new($false))
    }
    Assert-OpenCoreFiles $config $ocFolder

    New-Item -ItemType Directory -Path $destination | Out-Null
    Copy-Item -LiteralPath (Join-Path $staging 'EFI') -Destination $destination -Recurse
    Write-Host "Prepared EFI: $(Join-Path $destination 'EFI')"
    Write-Host 'Complete the per-machine SMBIOS fields before booting.'
}
finally {
    if (Test-Path -LiteralPath $work -PathType Container) {
        $resolvedWork = (Resolve-Path -LiteralPath $work).Path
        if ((Split-Path -Parent $resolvedWork) -eq $tempRoot -and
            (Split-Path -Leaf $resolvedWork) -match '^realme-efi-[a-f0-9]{32}$') {
            Remove-Item -LiteralPath $resolvedWork -Recurse -Force
        }
    }
}
