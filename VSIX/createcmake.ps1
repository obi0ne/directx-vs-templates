<#

.SYNOPSIS
This script creates a instance of one of the Win32 templates using CMake

.DESCRIPTION
This script is intended for creating a template instance outside of Visual Studio using CMake for building instead.

.PARAMETER templatedir
Provides the directory to read for the source template (d3d11game_win32, etc.)

.PARAMETER projectname
This is name of the project (such as "Direct3DGame")

.PARAMETER targetdir
This is the name of the target directory for the project (must not already exist). Defaults to the user's source directory.

.EXAMPLE
This creates a new instance of the Direct3D 11 Game template:

.\createcmake.ps1 d3d11game_win32 Direct3DGame $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D 11 Game with Device Resources template:

.\createcmake.ps1 d3d11game_win32_dr Direct3DGameDR $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D 12 Game template:

.\createcmake.ps1 d3d12game_win32 Direct3D12Game $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D 12 Game with Device Resources template:

.\createcmake.ps1 d3d12game_win32_dr Direct3D12GameDR $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D UWP Game template:

.\createcmake.ps1 d3d11game_uwp_cppwinrt Direct3DUWPGame $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D UWP Game with Device Resources template:

.\createcmake.ps1 d3d11game_uwp_cppwinrt_dr Direct3DUWPGameDR $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D 12 UWP Game template:

.\createcmake.ps1 d3d12game_uwp_cppwinrt Direct3DUWP12Game $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D 12 UWP Game with Device Resources template:

.\createcmake.ps1 d3d12game_uwp_cppwinrt_dr Direct3DUWP12GameDR $Env:USERPROFILE\source

.LINK
https://github.com/walbourn/directx-vs-templates/wiki

#>

param (
    [string]$templatedir = "d3d11game_win32",
    [string]$projectname = "Direct3DGame",
    [string]$targetdir = "$Env:USERPROFILE\source"
)

$templatedir = "..\" + $templatedir

$cmake = $templatedir + "\CMakeLists.txt"

if (-not (Test-Path -Path $cmake)) {
    Write-Error -Message "ERROR: $templatedir does not contain a CMake" -ErrorAction Stop
}

$targetdir = $targetdir + "\" + $projectname

if (Test-Path $targetdir) {
    Write-Error -Message "ERROR: Project directory already exists" -ErrorAction Stop
}

try {
    New-Item -Path $targetdir -ItemType Directory -ErrorAction Stop | Out-Null
}
catch {
    Write-Error -Message "Unable to create project directory '$targetdir'`n $_" -ErrorAction Stop
}

$files = Get-ChildItem $templatedir | Where {$_.extension -eq ".cpp"} | % { $_.FullName }
$files += Get-ChildItem $templatedir | Where {$_.extension -eq ".h"} | % { $_.FullName }

if (Test-Path -Path ($templatedir + "\Package.appxmanifest")) {
    $files += Get-ChildItem $templatedir | Where {$_.extension -eq ".appxmanifest"} | % { $_.FullName }
}

$guid = New-Guid
$locale = Get-WinSystemLocale

foreach ($file in $files) {
    $target = $targetdir + "\" + [System.IO.Path]::GetFileName($file)
    $i = Get-Content $file -Raw
    $o = $i.Replace("`$projectname$", $projectname)
    $o = $o.Replace("`$safeprojectname$", $projectname)
    $o = $o.Replace("`$guid9$", $guid)
    $o = $o.Replace("`$XmlEscapedPublisherDistinguishedName$", "CN=$Env:USERNAME")
    $o = $o.Replace("`$XmlEscapedPublisher$", "$Env:USERNAME")
    $o = $o.Replace("x-generate", $locale)
    $o = $o.Replace("`$targetnametoken$", "@PROJECT_NAME@")

    $o | Set-Content -Path $target -NoNewline
}
    
Copy-Item ($templatedir + "\CMakeLists.txt") -Destination $targetdir
Copy-Item ($templatedir + "\*.json") -Destination $targetdir
if (Test-Path -Path ($templatedir + "\settings.manifest")) {
    Copy-Item ($templatedir + "\*.rc") -Destination $targetdir
    Copy-Item ($templatedir + "\directx.ico") -Destination $targetdir
    Copy-Item ($templatedir + "\settings.manifest") -Destination $targetdir
}
else {
    New-Item -Path ($targetdir + "\Assets") -ItemType Directory | Out-Null
    Copy-Item ($templatedir + "\StoreLogo.png") -Destination ($targetdir + "\Assets\StoreLogo.png")
    Copy-Item ($templatedir + "\Logo.scale-200.png") -Destination ($targetdir + "\Assets\Logo.png")
    Copy-Item ($templatedir + "\SmallLogo.scale-200.png") -Destination ($targetdir + "\Assets\SmallLogo.png")
    Copy-Item ($templatedir + "\SplashScreen.scale-200.png") -Destination ($targetdir + "\Assets\SplashScreen.png")
    Copy-Item ($templatedir + "\WideLogo.scale-200.png") -Destination ($targetdir + "\Assets\WideLogo.png")
}

Write-Host "New project in $targetdir"