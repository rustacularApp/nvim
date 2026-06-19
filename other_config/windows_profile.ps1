
# ----- dev helpers for Rustacular (put in Microsoft.PowerShell_profile.ps1) -----
#

$Global:DevShellExe = 'powershell'    # or 'pwsh'

$Global:RustacularFrontendPath = 'C:\development\projects\Rustacular\rustacular'
$Global:RustacularBackendPath  = 'C:\development\projects\Rustacular\backend'
$Global:RustacularDatabasePath = 'postgres://sohailmd123:toormd123@127.0.0.1:6432/rustacular'


$Global:NewsFrontendPath = 'C:\development\projects\NewsAppTemplate\frontend'
$Global:NewsBackendPath  = 'C:\development\projects\NewsAppTemplate\backend'
$Global:NewsDatabasePath = 'postgres://sohailmd123:toormd123@127.0.0.1:6432/news_template'

function Open-Neovim {
	$path = 'C:\Users\sohai\AppData\Local\nvim'

	Push-Location $path
	try {
		nvim .
	} finally {
		Pop-Location
	}
}


# Run flutter in the rustacular frontend (in the same window)
function Start-Frontend-Rustacular {
    param([switch]$NewWindow)

    if ($NewWindow) {
        Start-Process -FilePath 'powershell' -ArgumentList '-NoExit','-Command',"Set-Location `'$RustacularFrontendPath`'; flutter run"
    } else {
        Push-Location $RustacularFrontendPath
        try { flutter run --dart-define-from-file=env.json}
        finally { Pop-Location }
    }
}

function Start-Frontend-News {
    param([switch]$NewWindow)

    if ($NewWindow) {
        Start-Process -FilePath 'powershell' -ArgumentList '-NoExit','-Command',"Set-Location `'$NewsFrontendPath`'; flutter run"
    } else {
        Push-Location $NewsFrontendPath
        try { flutter run --dart-define-from-file=env.json}
        finally { Pop-Location }
    }
}

function Start-Frontend-Fold {
    param([switch]$NewWindow)
    $path = 'C:\development\projects\Rustacular\rustacular'

    if ($NewWindow) {
        Start-Process -FilePath 'powershell' -ArgumentList '-NoExit','-Command',"Set-Location `'$path`'; flutter run"
    } else {
        Push-Location $path
        try { flutter run -d emulator-5556 --dart-define-from-file=env.json}
        finally { Pop-Location }
    }
}

function Start-Emulator {
	param(
		[string]$EmulatorName = 'Medium_Phone'
	)
	flutter emulators --launch $EmulatorName
}

function Start-Emulator-Fold {
	param(
		[string]$EmulatorName = 'Pixel_Fold'
	)
	flutter emulators --launch $EmulatorName
}


function Start-Emulator-Frontend {
    param(
		[switch]$NewWindow,
		[string]$EmulatorName = 'Medium_Phone'
	)
    $path = 'C:\development\projects\Rustacular\rustacular'

	 if ($NewWindow) {
        Start-Process -FilePath 'powershell' -ArgumentList '-NoExit','-Command',"
            flutter emulators --launch $EmulatorName
            Start-Sleep -Seconds 10
            Set-Location '$path'
            flutter run --dart-define-from-file=env.json
        "
    } else {
        Push-Location $path
        try {
            flutter emulators --launch $EmulatorName
            Start-Sleep -Seconds 10
            flutter run --dart-define-from-file=env.json
        }
        finally { Pop-Location }
    }
}


# Run watchexec + cargo in backend (in the same window)
function Start-Backend-Rustacular {
    param([switch]$NewWindow)
    $cmd  = "watchexec -r -c -e rs -- cargo run"

    if ($NewWindow) {
        Start-Process -FilePath 'powershell' -ArgumentList '-NoExit','-Command',"Set-Location `'$RustacularBackendPath`'; $cmd"
    } else {
        Push-Location $RustacularBackendPath
        try { Invoke-Expression $cmd }
        finally { Pop-Location }
    }
}

function Start-Backend-News {
    param([switch]$NewWindow)
    $cmd  = "watchexec -r -c -e rs -- cargo run"

    if ($NewWindow) {
        Start-Process -FilePath 'powershell' -ArgumentList '-NoExit','-Command',"Set-Location `'$NewsBackendPath`'; $cmd"
    } else {
        Push-Location $NewsBackendPath
        try { Invoke-Expression $cmd }
        finally { Pop-Location }
    }
}

function Start-Dart-Watch-Rustacular {
	param([switch]$NewWindow)
	$cmd = "dart run build_runner watch --delete-conflicting-outputs"

	if ($NewWindow) {
		Start-Process -FilePath 'powershell' -ArgumentList '-NoExit','-Command',"Set-Location `'$RustacularFrontendPath`'; $cmd"
	} else {
		Push-Location $RustacularFrontendPath
		try { Invoke-Expression $cmd }
		finally { Pop-Location }
	}
}

function Start-Dart-Watch-News {
	param([switch]$NewWindow)
	$cmd = "dart run build_runner watch --delete-conflicting-outputs"

	if ($NewWindow) {
		Start-Process -FilePath 'powershell' -ArgumentList '-NoExit','-Command',"Set-Location `'$NewsFrontendPath`'; $cmd"
	} else {
		Push-Location $NewsFrontendPath
		try { Invoke-Expression $cmd }
		finally { Pop-Location }
	}
}

# Start both in new windows (concurrent)
function Start-Dev-All {
    # open frontend in new PowerShell window and backend in another
    Start-Frontend -NewWindow
    Start-Backend  -NewWindow
}

# (Optional) If you use Windows Terminal (wt) and want two tabs:
function Start-Dev-WT {
    wt new-tab powershell -NoExit -Command "Set-Location 'C:\development\projects\Rustacular\rustacular'; flutter run" `
       ; new-tab powershell -NoExit -Command "Set-Location 'C:\development\projects\Rustacular\backend'; watchexec -r -c -e rs -- cargo run"
}




# ---- Neovim open helpers for Rustacular ----

# Set the shell executable used when opening a new window.
# Change to 'pwsh' if you run PowerShell 7.

# Open nvim in the frontend in the current window
function Open-FrontendNvim-Rustacular {
    Push-Location $Global:RustacularFrontendPath
    try {
        nvim .
    } finally {
        Pop-Location
    }
}

function Open-FrontendNvim-News {
    Push-Location $Global:NewsFrontendPath
    try {
        nvim .
    } finally {
        Pop-Location
    }
}

function Open-BackendNvim-Rustacular {
    Push-Location $Global:RustacularBackendPath
    try {
        nvim .
    } finally {
        Pop-Location
    }
}

function Open-BackendNvim-News {
    Push-Location $Global:NewsBackendPath
    try {
        nvim .
    } finally {
        Pop-Location
    }
}

function Sea-Orm-MigrateReset-Rustacular {
	Push-Location $Global:RustacularBackendPath
	try {
		sea-orm-cli migrate reset -u $Global:RustacularDatabasePath
	} finally {
		Pop-Location
	}
}

function Sea-Orm-MigrateUp-Rustacular {
	Push-Location $Global:RustacularBackendPath
	try {
		sea-orm-cli migrate up -u $Global:RustacularDatabasePath
	} finally {
		Pop-Location
	}
}


function Sea-Orm-GenerateEntity-Rustacular {
	Push-Location $Global:RustacularBackendPath
	try {
		sea-orm-cli generate entity -u $Global:RustacularDatabasePath -o ./src/entity --expanded-format --with-serde both
	} finally {
		Pop-Location
	}
}


function Sea-Orm-MigrateReset-News {
	Push-Location $Global:RustacularBackendPath
	try {
		sea-orm-cli migrate reset -u $Global:RustacularDatabasePath
	} finally {
		Pop-Location
	}
}

function Sea-Orm-MigrateUp-News {
	Push-Location $Global:RustacularBackendPath
	try {
		sea-orm-cli migrate up -u $Global:RustacularDatabasePath
	} finally {
		Pop-Location
	}
}


function Sea-Orm-GenerateEntity-News {
	Push-Location $Global:RustacularBackendPath
	try {
		sea-orm-cli generate entity -u $Global:RustacularDatabasePath -o ./src/entity --expanded-format --with-serde both
	} finally {
		Pop-Location
	}
}

# Open frontend nvim in a NEW PowerShell window
function Open-FrontendNvim-NewWindow {
    $p = $Global:RustacularFrontendPath
    Start-Process -FilePath $Global:DevShellExe -ArgumentList '-NoExit','-Command',"Set-Location `'$p`'; nvim ."
}

# Open backend nvim in a NEW PowerShell window
function Open-BackendNvim-NewWindow {
    $p = $Global:RustacularBackendPath
    Start-Process -FilePath $Global:DevShellExe -ArgumentList '-NoExit','-Command',"Set-Location `'$p`'; nvim ."
}

function Delete-Frontend-App-Rustacular {
	try {
		adb -s emulator-5554 uninstall com.rustacular.app
	} catch {
		"No Such App exists"
	}
}

function Delete-Frontend-App-News {
	try {
		adb -s emulator-5554 uninstall com.example.frontend
	} catch {
		"No Such App exists"
	}
}


function Delete-Frontend-App-Fold {
	try {
		adb -s emulator-5556 uninstall com.rustacular.app
	} catch {
		"No Such App exists"
	}
}

# Open both in separate NEW windows
function Open-DevNvim-All {
    Open-FrontendNvim-NewWindow
    Open-BackendNvim-NewWindow
}

# short aliases Common
Set-Alias ofnw Open-FrontendNvim-NewWindow
Set-Alias obnw Open-BackendNvim-NewWindow
Set-Alias odna Open-DevNvim-All



# Optional: short aliases Rustacular
Set-Alias ofn_rustacular Open-FrontendNvim-Rustacular
Set-Alias obn_rustacular Open-BackendNvim-Rustacular
Set-Alias sdb_rustacular Start-Backend-Rustacular
Set-Alias sdfe_rustacular Start-Frontend
Set-Alias sdfe1_rustacular Start-Frontend-Fold
Set-Alias sde Start-Emulator
Set-Alias sdef Start-Emulator-Frontend
Set-Alias sde1 Start-Emulator-Fold
Set-Alias sda Start-Dev-All
Set-Alias sdw Start-Dart-Watch
Set-Alias onv Open-Neovim
Set-Alias dfa_rustacular Delete-Frontend-App-Rustacular
Set-Alias dfa1 Delete-Frontend-App-Fold
Set-Alias smr_rustacular Sea-Orm-MigrateReset-Rustacular
Set-Alias smu_rustacular Sea-Orm-MigrateUp-Rustacular
Set-Alias sge_rustacular Sea-Orm-GenerateEntity-Rustacular

Set-Alias ofn_news Open-FrontendNvim-News
Set-Alias obn_news Open-BackendNvim-News
Set-Alias sdb_news Start-Backend-News
Set-Alias sdfe_news Start-Frontend-News
Set-Alias sdw_news Start-Dart-Watch-News
Set-Alias dfa_news Delete-Frontend-App-News
Set-Alias smr_news Sea-Orm-MigrateReset-News
Set-Alias smu_news Sea-Orm-MigrateUp-News
Set-Alias sge_news Sea-Orm-GenerateEntity-News

# Optional: If you use Windows Terminal (wt), open two tabs that run nvim in each folder
function Open-DevNvim-WT {
    # requires 'wt' on PATH (Windows Terminal)
    wt new-tab powershell -NoExit -Command "Set-Location '$Global:RustacularFrontendPath'; nvim ." `
       ; new-tab powershell -NoExit -Command "Set-Location '$Global:RustacularBackendPath'; nvim ."
}

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
