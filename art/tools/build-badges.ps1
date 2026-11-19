# Draws the badge icons (Scenes.cs, badge_*) into art\badges (512 x 512, for the Creator Dashboard).
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$out = Join-Path (Split-Path -Parent $here) "badges"
New-Item -ItemType Directory -Force $out | Out-Null
if (-not ("Doodles" -as [type])) {
	Add-Type -Path (Join-Path $here "Doodles.cs"), (Join-Path $here "Scenes.cs") -ReferencedAssemblies System.Drawing
}
$n = [Doodles]::BuildBadges($out)
Write-Output "drew $n badges into $out"
