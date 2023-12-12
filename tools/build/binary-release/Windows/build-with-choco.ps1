param ([string]$RAKUDO_VER, [switch]$sign, [switch]$keep)

# inspired by https://github.com/hankache/rakudo-star-win/blob/master/build.ps1
# expected $RAKUDO_VER is something like "2021.03"
# if none is given, we will try to get the "latest" from GitHub

# $ErrorActionPreference = "stop"

# Make sure Powershell 7 doesn't just silently swallows errors.
# https://david.gardiner.net.au/2020/04/azure-pipelines-powershell-7-errors.html
# https://github.com/microsoft/azure-pipelines-tasks/issues/12799
$ErrorView = 'NormalView'

function CheckLastExitCode {
  if ($LastExitCode -ne 0) {
    $msg = @"
!!!
!!! Program failed with exit code: $LastExitCode
!!!
!!! Callstack: $(Get-PSCallStack | Out-String)
!!!
"@
    throw $msg
  }
}

IF ( $PSScriptRoot ) { $ScriptRoot = $PSScriptRoot} ELSE { $ScriptRoot = Get-Location }
Write-Host "   INFO - `"`$ScriptRoot`" set to `"$ScriptRoot`""

IF ( -NOT ((Get-Command "cl.exe" -ErrorAction SilentlyContinue).Path) ) {
  Write-Host "WARNING - MSVC with `"cl.exe`", version 19 or newer, is a hard requirement to build NQP, Moar and Rakudo now, see"
  Write-Host "          https://github.com/rakudo/rakudo/commit/d01d4b26641bec2a62b43007b476f668982b9ab6#diff-a3c0a8904b9af2275c7ef3d4616ad9c3481898d3cc0e4698133948520b2df2ed"
  Write-Host "          https://github.com/Raku/nqp-configure/blob/e068508a94d643c1174bcd29e333dd659df502c5/lib/NQP/Config.pm#L252"
  
  IF ( -NOT ((Get-Command "Launch-VsDevShell.ps1" -ErrorAction SilentlyContinue).Path) ) {
    Write-Host "  ERROR - Couldn't neither find `"cl.exe`" nor `"Launch-VsDevShell.ps1`""
    Write-Host "  ERROR - Make sure `"Microsoft Visual C++ 2019`" or newer is installed and try again"
    EXIT
  } ELSE {
    Write-Host "   INFO - Executing `"Launch-VsDevShell.ps1`""
    & Launch-VsDevShell.ps1 2>&1 | Out-Null
  }
}

# "Launch-VsDevShell.ps1" seems to change the directory. Let's get back...
IF ( $ScriptRoot -ne (pwd).Path ) { cd $ScriptRoot }


IF ((( &cl.exe /v 2>&1 | Select-String "^Microsoft .+ Compiler Version .+ for") -match "^Microsoft .+ Compiler Version (?<VERSION>\d{2}).+" ) -AND ( $Matches.VERSION -ge 19 )) {
  Write-Host "   INFO - `"cl.exe`" version", $Matches.VERSION, "or newer found, continue..."
} ELSE {
  Write-Host "  ERROR - `"cl.exe`" version 19 or newer expected, but only version", $Matches.VERSION, "found"
  Write-Host "  ERROR - Make sure `"Microsoft Visual C++ 2019`" or newer is installed and try again"
  EXIT
}

IF ( -NOT ((Get-Command  "nmake.exe" -ErrorAction SilentlyContinue).Path) )  {
  Write-Host "  ERROR - `"nmake.exe`" not found"
  Write-Host "  ERROR - Make sure `"Microsoft Visual 2019`" or newer is installed and try again"
  EXIT
}

# Let's use choco to make sure all prerequisites are installed
# Check if choco is installed. If not, install it.
Write-Host "   INFO - Checking all prerequisites (choco, git, perl5, WiX toolset, gpg) and installing them, if required"
IF ( -NOT ((Get-Command "choco" -ErrorAction SilentlyContinue).Path) ) { iex (New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1') }

# Now install all prerequisites to build NQP, Moar and finally Rakudo
IF (  -NOT ((Get-Command  "git.exe" -ErrorAction SilentlyContinue).Path) ) { & choco install --yes --force --no-progress --limit-output --timeout 0 git }
IF (  -NOT ((Get-Command  "curl.exe" -ErrorAction SilentlyContinue).Path) ) { & choco install --yes --force --no-progress --limit-output --timeout 0 curl }
IF (  -NOT ((Get-Command "perl.exe" -ErrorAction SilentlyContinue).Path) ) { & choco install --yes --force --no-progress --limit-output --timeout 0 perl }
IF ( (-NOT ((Get-Command "heat.exe" -ErrorAction SilentlyContinue).Path)) -OR (-NOT ((Get-Command "candle.exe" -ErrorAction SilentlyContinue).Path)) ) { & choco install --yes --force --no-progress --limit-output --timeout 0 wixtoolset }
IF ( ($sign) -AND ( -NOT ((Get-Command "gpg.exe" -ErrorAction SilentlyContinue).Path) ) ) { & choco install --yes --force --no-progress --limit-output --timeout 0 gpg4win-vanilla }

# If no Rakudo release is given, build the latest from github
IF ( -NOT ($RAKUDO_VER) ) {
  Write-Host "   INFO - `"`$RAKUDO_VER`" not found, try to guess it from `"https://github.com/rakudo/rakudo/releases/latest`""
  ( Invoke-WebRequest https://github.com/rakudo/rakudo/releases/latest ) -match 'https://github.com/rakudo/rakudo/releases/tag/(?<RAKUDO_VERSION>[\d]{4}\.[\d]{2})(?<RAKUDO_PATCH>\.[\d]+)?' | Out-Null
  IF ( $Matches.RAKUDO_PATCH ) {
    $RAKUDO_VER = $Matches.RAKUDO_VERSION + $Matches.RAKUDO_PATCH
  } ELSE {
    $RAKUDO_VER = $Matches.RAKUDO_VERSION
  }
  Write-Host "   INFO - Will continue and try to build `"`$RAKUDO_VER`" $RAKUDO_VER"
}


Write-Host "   INFO - Cloning `"https://github.com/rakudo/rakudo.git`"..."
& git.exe -c advice.detachedHead=false clone --quiet --single-branch -b $RAKUDO_VER "https://github.com/rakudo/rakudo.git" rakudo-$RAKUDO_VER | Out-Null
cd rakudo-$RAKUDO_VER


$PrefixPath = $env:Temp + "\rakudo-star-$RAKUDO_VER"
Write-Host "   INFO - `"`$PrefixPath`" set to $PrefixPath"
Write-Host "   INFO - Building NQP, Moar and Rakudo $RAKUDO_VER"
# "Configure.pl" help -> https://github.com/rakudo/rakudo/blob/master/Configure.pl#L140-L210
perl Configure.pl --backends=moar --gen-moar --gen-nqp --moar-option='--toolchain=msvc' --no-silent-build --relocatable --prefix=$PrefixPath --out=RAKUDO-${RAKUDO_VER}_build.log
CheckLastExitCode

# see https://docs.microsoft.com/en-us/cpp/build/reference/running-nmake
## /C => Suppresses default output, including nonfatal NMAKE errors or warnings, timestamps, and NMAKE copyright message. Suppresses warnings issued by /K
nmake /C
CheckLastExitCode

# nmake /C test
nmake /C install
CheckLastExitCode

# Download Zef and install
Write-Host "   INFO - Cloning `"https://github.com/ugexe/zef.git`"..."
& git.exe -c advice.detachedHead=false clone --quiet https://github.com/ugexe/zef.git
CheckLastExitCode

cd zef
Write-Host "   INFO - Installing ZEF"
& $PrefixPath\bin\raku.exe -I. bin\zef install . --install-to=$PrefixPath\share\perl6\site\ --error
CheckLastExitCode

# Add the required rakudo folders to PATH in order for some modules to test correctly (File::Which)
Write-Host "   INFO - Changing the %PATH% variable"
$orgEnvPath = $Env:Path
$Env:Path += ";$PrefixPath\bin;$PrefixPath\share\perl6\site\bin"


Write-Host "   INFO - ZEF: installing `"https://raw.githubusercontent.com/rakudo/star/master/etc/modules.txt`" modules into `"$PrefixPath\share\perl6\site\`""
& curl.exe -s https://raw.githubusercontent.com/rakudo/star/master/etc/modules.txt --output rakudo-star-modules.txt
CheckLastExitCode

Select-String -Path rakudo-star-modules.txt -Pattern " http "," git " -SimpleMatch | ForEach-Object {
  $moduleName, $moduleUrl = ($_.Line -split '\s+')[0,2]
  $moduleName = $moduleName.replace("-","::")
  Write-Host "   INFO - zef: installing $moduleName, $moduleUrl"
  IF ( $moduleName -ne "zef" ) {
    IF ( [string]( & zef install $moduleName --install-to=$PrefixPath\share\perl6\site\ --error --force-test) -match 'No candidates found matching identity' ) { & zef install $moduleUrl --install-to=$PrefixPath\share\perl6\site\ --error --force-test}
  }
}

$LibWinPThread = (Join-Path (Split-Path (Get-Command perl).Path) libwinpthread-1.dll)
 $LibGcc_S_Seh = (Join-Path (Split-Path (Get-Command perl).Path) libgcc_s_seh-1.dll)
IF (Test-Path -Path $LibGcc_S_Seh) {
  Write-Host "   INFO - Copy required dll from Strawberry Perl libraries"
  Copy-Item $LibWinPThread $PrefixPath\bin
  Copy-Item  $LibGcc_S_Seh $PrefixPath\bin
} ELSE { Write-Host "  ERROR - Couldn't find the Strawberry Perl libraries!" }


Write-Host "   INFO - Creating the .msi Package"
cd $ScriptRoot
IF ( !(Test-Path -Path Windows )) { New-Item -ItemType directory -Path Windows | Out-Null }
$Wixtoolpath = [Environment]::GetEnvironmentVariable('WIX', 'Machine') + "bin"
$msiBinFile = "Windows\rakudo-star-$RAKUDO_VER-win-x86_64-msvc.msi"
$msiChecksumFile = "$msiBinFile" + ".checksums.txt"
& $Wixtoolpath\heat.exe dir $PrefixPath\bin -dr DIR_BIN -cg FilesBin -gg -g1 -sfrag -srd -suid -ke -sw5150 -var "var.BinDir" -out files-bin.wxs
& $Wixtoolpath\heat.exe dir $PrefixPath\include -dr DIR_INCLUDE -cg FilesInclude -gg -g1 -sfrag -srd -ke -sw5150 -var "var.IncludeDir" -out files-include.wxs
& $Wixtoolpath\heat.exe dir $PrefixPath\share -dr DIR_SHARE -cg FilesShare -gg -g1 -sfrag -srd -ke -sw5150 -var "var.ShareDir" -out files-share.wxs
& $Wixtoolpath\candle.exe files-bin.wxs files-include.wxs files-share.wxs -dBinDir="$PrefixPath\bin" -dIncludeDir="$PrefixPath\include" -dShareDir="$PrefixPath\share"
& $Wixtoolpath\candle.exe star.wxs -dSTARVERSION="$RAKUDO_VER"
& $Wixtoolpath\light.exe -b $PrefixPath -ext WixUIExtension files-bin.wixobj files-include.wixobj files-share.wixobj star.wixobj -sw1076 -o $msiBinFile
Write-Host "   INFO - .msi Package `"$msiBinFile`" created"


Write-Host "   INFO - Creating the checksum file `"$msiChecksumFile`""
#& CertUtil -hashfile "Windows\rakudo-star-$RAKUDO_VER-win-x86_64-msvc.msi" SHA256 | findstr /V ":" > "Windows\rakudo-star-$RAKUDO_VER-win-x86_64-msvc.msi.sha256.txt"
#Write-Host -NoNewline (Get-FileHash -Path $msiBinFile -Algorithm SHA256).Hash ($msiBinFile).Split("\")[-1] *> $msiChecksumFile
# Get-FileHash doesn't support SHA224, so we skip that for now.
FOREACH ($HashAlg in "MD5", "SHA1", "SHA256", "SHA384", "SHA512") {
  Write-Host "$HashAlg ($(Split-Path $msiBinFile -Leaf)) = $((Get-FileHash -Path $msiBinFile -Algorithm $HashAlg).Hash)" *>> $msiChecksumFile
}

IF ( $sign ) {
  $unsigned = "$msiChecksumFile" + ".unsigned"
  $asc = "$msiBinFile" + ".asc"
  Write-Host "   INFO - gpg signing the .msi package"
  echo gpg --detach-sign --armor -u $env:GPG_FINGERPRINT --output "$asc" -- "$msiBinFile"
  & gpg --detach-sign --armor -u $env:GPG_FINGERPRINT --output "$asc" -- "$msiBinFile"
  Move-Item "$msiChecksumFile" "$unsigned"
  & gpg --clearsign -u $env:GPG_FINGERPRINT --output "$msiChecksumFile" -- "$unsigned"
  Remove-Item "$unsigned"
}


IF ( ! $keep ) {
  Write-Host "   INFO - Cleaning up..."
  Remove-Item files-*.wxs, *.wixobj, "Windows\rakudo-star-${RAKUDO_VER}-win-x86_64-msvc.wixpdb"
  Remove-Item -Recurse -Force "rakudo-${RAKUDO_VER}"
  #Remove-Item rakudo-$RAKUDO_VER\RAKUDO-${RAKUDO_VER}_build.log
  Remove-Item -Recurse -Force $PrefixPath
  Write-Host "   INFO - ALL done in dir `"", (pwd).Path, "`""
}

$Env:Path = $orgEnvPath
