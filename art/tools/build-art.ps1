# Draws the game's icon and thumbnails (Scenes.cs) into art\store.
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$out = Join-Path (Split-Path -Parent $here) "store"
New-Item -ItemType Directory -Force $out | Out-Null
if (-not ("Doodles" -as [type])) {
	Add-Type -Path (Join-Path $here "Doodles.cs"), (Join-Path $here "Scenes.cs") -ReferencedAssemblies System.Drawing
}
$n = [Doodles]::BuildArt($out)
Write-Output "drew $n pictures into $out"
