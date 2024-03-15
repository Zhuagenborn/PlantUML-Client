<#
.SYNOPSIS
    Send PlantUML scripts to the PlantUML server and download diagrams.
.DESCRIPTION
    This script can enumerate PlantUML scripts in a directory, send them to the PlantUML server and download the built diagrams to a directory.
.PARAMETER ScriptDirectory
    The directory of input PlantUML scripts. The default is the current directory.
.PARAMETER DiagramDirectory
    The directory of output diagrams. The default is the current directory.
.PARAMETER ScriptExtension
    The file extension of PlantUML scripts. The default is `puml`.
.PARAMETER DiagramExtension
    The file extension of built diagrams, supporting `png` and `svg`. The default is `png`.
.EXAMPLE
    PS> .\Build-PlantUML.ps1
    The script sends all `.puml` files in the current directory to the PlantUML server, then downloads `.png` diagrams to the current directory.
.EXAMPLE
    PS> .\Build-PlantUML.ps1 -ScriptDirectory 'docs' -DiagramDirectory 'images'
    The script sends all `.puml` files in the `docs` directory to the PlantUML server, then downloads `.png` diagrams to the `images` directory.
.EXAMPLE
    PS> .\Build-PlantUML.ps1 -ScriptExtension 'txt'
    The script sends all `.txt` files in the current directory to the PlantUML server, then downloads `.png` diagrams to the current directory.
.EXAMPLE
    PS> .\Build-PlantUML.ps1 -DiagramExtension 'svg'
    The script sends all `.puml` files in the current directory to the PlantUML server, then downloads `.svg` diagrams to the current directory.
.LINK
    https://plantuml.com/en/text-encoding
#>
[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [string]$ScriptDirectory = (Get-Location).Path,
    [ValidateNotNullOrEmpty()]
    [string]$DiagramDirectory = (Get-Location).Path,
    [ValidateNotNullOrEmpty()]
    [string]$ScriptExtension = 'puml',
    [ValidateSet('png', 'svg')]
    [string]$DiagramExtension = 'png'
)

<#
.SYNOPSIS
    Format a PlantUML script to a hexadecimal byte string.
#>
function Format-Script {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Script
    )

    $bytes = $Script | Format-Hex
    return [System.BitConverter]::ToString($bytes.Bytes) -replace '-'
}

<#
.SYNOPSIS
    Send a PlantUML script to the PlantUML server and download the diagram.
#>
function Build-Diagram {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Script,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DiagramPath
    )

    New-Variable -Name 'server' -Value 'https://www.plantuml.com/plantuml' -Option Constant
    $encoded = Format-Script -Script $Script
    $url = "$server/$DiagramExtension/~h$encoded"
    Invoke-WebRequest -Uri $url -OutFile $DiagramPath
}

if (!(Test-Path -PathType Container $DiagramDirectory)) {
    New-Item -ItemType Directory -Path $DiagramDirectory
}

foreach ($file in Get-ChildItem -Path (Join-Path $ScriptDirectory '*') -Include "*.$ScriptExtension" ) {
    try {
        $script = Get-Content -Path $file | Out-String
        if (![String]::IsNullOrWhiteSpace($script)) {
            $diagram = Join-Path $DiagramDirectory "$($file.BaseName).$DiagramExtension"
            Build-Diagram -Script $script -DiagramPath $diagram
            Write-Verbose "'$file' has been built to '$diagram'."
        }
    }
    catch {
        Write-Host $_ -ForegroundColor Red
    }
}