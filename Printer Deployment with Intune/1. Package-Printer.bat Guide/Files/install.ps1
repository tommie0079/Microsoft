# Intune runs the install command in a 32-bit PowerShell host by default. On a
# 64-bit OS that makes $env:PROCESSOR_ARCHITECTURE report 'x86' and redirects
# system tools (pnputil) to SysWOW64. Relaunch in native PowerShell so driver
# detection and staging use the real OS architecture.
if ($env:PROCESSOR_ARCHITEW6432) {
	$nativePowerShell = Join-Path $env:WINDIR 'Sysnative\WindowsPowerShell\v1.0\powershell.exe'
	if (Test-Path $nativePowerShell) {
		& $nativePowerShell -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath @args
		exit $LASTEXITCODE
	}
}

# --- Config ---

$PrinterName = "HP LaserJet P4515x"
$PrinterIP = "192.168.1.138"
$PortName = "IP_$PrinterIP"

# Prefer an already-installed driver; otherwise auto-detect and install a driver bundled in the package.
$PreferredDriverNames = @(
	"HP LaserJet P4515 PCL6 Class Driver"
	"HP Universal Printing PS"
)

# Folder (shipped inside the .intunewin) that holds the printer driver INF(s).
# The correct INF and driver model are detected automatically at run time,
# so you can drop in a different printer's driver without editing this script.
$BundledDriverFolderName = "UPD"
$LogDirectory = Join-Path $env:ProgramData "PrinterDeployIntune"
$LogPath = Join-Path $LogDirectory "install.log"
$LegacyLogDirectory = Join-Path $env:ProgramData "PrinterDeployment"
$LegacyLogPath = Join-Path $LegacyLogDirectory "install.log"

$ErrorActionPreference = "Stop"

function Write-Log {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Message
	)

	$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
	$entry = "$timestamp $Message"
	Add-Content -Path $LogPath -Value $entry
	if ($LegacyLogPath -ne $LogPath) {
		Add-Content -Path $LegacyLogPath -Value $entry
	}
	Write-Output $entry
}

function Resolve-PrinterDriverName {
	param(
		[Parameter(Mandatory = $true)]
		[string[]]$CandidateNames
	)

	foreach ($candidateName in $CandidateNames) {
		if (Get-PrinterDriver -Name $candidateName -ErrorAction SilentlyContinue) {
			return $candidateName
		}
	}

	return $null
}

function Get-CurrentArchInfToken {
	# PROCESSOR_ARCHITEW6432 reports the real OS architecture when running in a
	# 32-bit process on 64-bit Windows; fall back to the process architecture.
	$arch = $env:PROCESSOR_ARCHITEW6432
	if (-not $arch) {
		$arch = $env:PROCESSOR_ARCHITECTURE
	}
	switch ($arch) {
		"AMD64" { return "NTAMD64" }
		"ARM64" { return "NTARM64" }
		"X86" { return "NTX86" }
		default { return "NTAMD64" }
	}
}

function Get-PrinterDriverModelFromInf {
	param(
		[Parameter(Mandatory = $true)]
		[string]$InfPath,
		[Parameter(Mandatory = $true)]
		[string]$ArchToken
	)

	$infContent = Get-Content -Path $InfPath -ErrorAction SilentlyContinue
	if (-not $infContent) {
		return $null
	}

	# Only printer-class INFs are eligible.
	if (-not ($infContent | Select-String -Pattern '^\s*Class\s*=\s*Printer\b' -Quiet)) {
		return $null
	}

	# Model lines look like: "Friendly Name" = InstallSection.NT<arch>,HardwareId
	$pattern = '^\s*"([^"]+)"\s*=\s*[^,]*\.' + [regex]::Escape($ArchToken) + '\b'
	$names = foreach ($line in $infContent) {
		$match = [regex]::Match($line, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
		if ($match.Success) {
			$match.Groups[1].Value
		}
	}

	if (-not $names) {
		return $null
	}

	# Prefer the canonical model name (skip "Driver Disk" and versioned aliases), then the most frequent.
	$best = $names |
		Group-Object |
		Sort-Object `
			@{ Expression = { if ($_.Name -match 'Driver Disk|\(') { 1 } else { 0 } } }, `
			@{ Expression = { $_.Count }; Descending = $true } |
		Select-Object -First 1

	return [pscustomobject]@{
		ModelName = $best.Name
		MatchCount = ($names | Measure-Object).Count
	}
}

function Get-CatalogPathForInf {
	param(
		[Parameter(Mandatory = $true)]
		[string]$InfPath,
		[Parameter(Mandatory = $true)]
		[string]$UpdFolder
	)

	foreach ($line in (Get-Content -Path $InfPath -ErrorAction SilentlyContinue)) {
		$match = [regex]::Match($line, '^\s*CatalogFile(\.\w+)?\s*=\s*(?<file>\S+)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
		if ($match.Success) {
			$candidate = Join-Path $UpdFolder $match.Groups['file'].Value
			if (Test-Path $candidate) {
				return $candidate
			}
		}
	}

	return $null
}

function Add-DriverPublisherToTrustedStore {
	param(
		[Parameter(Mandatory = $true)]
		[string]$SignedFilePath
	)

	$signature = Get-AuthenticodeSignature -FilePath $SignedFilePath
	if (-not $signature -or -not $signature.SignerCertificate) {
		Write-Log "No signer certificate found on '$SignedFilePath'; skipping publisher trust."
		return
	}

	$certificate = $signature.SignerCertificate
	$store = New-Object System.Security.Cryptography.X509Certificates.X509Store("TrustedPublisher", "LocalMachine")
	$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
	try {
		if ($store.Certificates | Where-Object { $_.Thumbprint -eq $certificate.Thumbprint }) {
			Write-Log "Driver publisher already trusted: $($certificate.Subject) [$($certificate.Thumbprint)]"
		} else {
			Write-Log "Trusting driver publisher: $($certificate.Subject) [$($certificate.Thumbprint)]"
			$store.Add($certificate)
		}
	} finally {
		$store.Close()
	}
}

function Install-BundledPrinterDriver {
	param(
		[Parameter(Mandatory = $true)]
		[string]$UpdFolder
	)

	if (-not (Test-Path $UpdFolder)) {
		throw "Bundled driver folder not found in package: $UpdFolder"
	}

	$archToken = Get-CurrentArchInfToken
	Write-Log "Detecting bundled printer driver INF for architecture '$archToken' in: $UpdFolder"

	$candidates = @()
	foreach ($inf in (Get-ChildItem -Path $UpdFolder -Filter *.inf -File -ErrorAction SilentlyContinue)) {
		$model = Get-PrinterDriverModelFromInf -InfPath $inf.FullName -ArchToken $archToken
		if ($model) {
			$candidates += [pscustomobject]@{
				InfPath = $inf.FullName
				InfName = $inf.Name
				ModelName = $model.ModelName
				MatchCount = $model.MatchCount
			}
		}
	}

	if (-not $candidates) {
		throw "No printer driver INF in '$UpdFolder' supports this architecture ($archToken). Ensure the matching driver is bundled."
	}

	# The main printer driver INF declares the most models; pick it over fax/scan helper INFs.
	$selected = $candidates | Sort-Object MatchCount -Descending | Select-Object -First 1
	Write-Log "Selected bundled driver INF '$($selected.InfName)' providing model '$($selected.ModelName)'."

	# Silent driver staging requires the publisher's certificate to be trusted.
	$catalogPath = Get-CatalogPathForInf -InfPath $selected.InfPath -UpdFolder $UpdFolder
	if ($catalogPath) {
		Add-DriverPublisherToTrustedStore -SignedFilePath $catalogPath
	} else {
		Write-Log "No catalog file resolved for INF '$($selected.InfName)'; proceeding without pre-trusting publisher."
	}

	Write-Log "Staging driver into the driver store: $($selected.InfPath)"
	$pnputilOutput = & pnputil.exe /add-driver "$($selected.InfPath)" /install 2>&1
	$pnputilExit = $LASTEXITCODE
	foreach ($line in $pnputilOutput) {
		Write-Log "pnputil: $line"
	}

	# pnputil returns 0 on success and 3010 when a reboot is required; both mean the driver was staged.
	if ($pnputilExit -ne 0 -and $pnputilExit -ne 3010) {
		throw "pnputil failed to stage driver '$($selected.InfName)' (exit code $pnputilExit)."
	}

	if (-not (Get-PrinterDriver -Name $selected.ModelName -ErrorAction SilentlyContinue)) {
		Write-Log "Registering printer driver: $($selected.ModelName)"
		Add-PrinterDriver -Name $selected.ModelName
	}

	if (-not (Get-PrinterDriver -Name $selected.ModelName -ErrorAction SilentlyContinue)) {
		throw "Driver '$($selected.ModelName)' was not available after staging INF '$($selected.InfName)'."
	}

	return $selected.ModelName
}

if (-not (Test-Path $LogDirectory)) {
	New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
}

if (-not (Test-Path $LegacyLogDirectory)) {
	New-Item -ItemType Directory -Path $LegacyLogDirectory -Force | Out-Null
}

try {
	Write-Log "Starting printer install. PrinterName='$PrinterName' PrinterIP='$PrinterIP' PreferredDrivers='$($PreferredDriverNames -join ", ")'"

	$DriverName = Resolve-PrinterDriverName -CandidateNames $PreferredDriverNames
	if (-not $DriverName) {
		Write-Log "No preferred driver present. Detecting and installing a bundled driver from the package."
		$DriverName = Install-BundledPrinterDriver -UpdFolder (Join-Path $PSScriptRoot $BundledDriverFolderName)
	}

	# --- Install printer ---
	Write-Log "Using installed printer driver: $DriverName"

	if (Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue) {
		Write-Log "Printer port already present: $PortName"
	} else {
		Write-Log "Creating printer port: $PortName"
		Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIP
	}

	$existingPrinter = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
	if ($existingPrinter) {
		Write-Log "Printer already present: $PrinterName"
		if ($existingPrinter.PortName -ne $PortName) {
			Write-Log "Updating printer port from '$($existingPrinter.PortName)' to '$PortName'"
			Set-Printer -Name $PrinterName -PortName $PortName
		} else {
			Write-Log "Printer already uses target port: $PortName"
		}
	} else {
		Write-Log "Creating printer: $PrinterName"
		Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName
	}

	Write-Log "Printer install completed successfully"
	exit 0
} catch {
	Write-Log "ERROR: $($_.Exception.Message)"
	throw
}





























