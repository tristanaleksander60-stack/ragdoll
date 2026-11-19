param([string]$Only = "")
# Compiles Doodles.cs and draws the hand-drawn icons into art\icons (see Doodles.cs).
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$out = Join-Path (Split-Path -Parent $here) "icons"
New-Item -ItemType Directory -Force $out | Out-Null
if (-not ("Doodles" -as [type])) {
	Add-Type -Path (Join-Path $here "Doodles.cs"), (Join-Path $here "Scenes.cs") -ReferencedAssemblies System.Drawing
}
$n = [Doodles]::Build($out, $Only)
Write-Output "drew $n icons into $out"
