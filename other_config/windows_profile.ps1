
# ----- dev helpers for Rustacular (put in Microsoft.PowerShell_profile.ps1) -----

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
function Start-Frontend {
    param([switch]$NewWindow)
    $path = 'C:\development\projects\Rustacular\rustacular'

    if ($NewWindow) {
        Start-Process -FilePath 'powershell' -ArgumentList '-NoExit','-Command',"Set-Location `'$path`'; flutter run"
    } else {
        Push-Location $path
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
function Start-Backend {
    param([switch]$NewWindow)
    $path = 'C:\development\projects\Rustacular\backend'
    $cmd  = "watchexec -r -c -e rs -- cargo run"

    if ($NewWindow) {
        Start-Process -FilePath 'powershell' -ArgumentList '-NoExit','-Command',"Set-Location `'$path`'; $cmd"
    } else {
        Push-Location $path
        try { Invoke-Expression $cmd }
        finally { Pop-Location }
    }
}

function Start-Dart-Watch {
	param([switch]$NewWindow)
	$path = 'C:\development\projects\Rustacular\rustacular'
	$cmd = "dart run build_runner watch --delete-conflicting-outputs"

	if ($NewWindow) {
		Start-Process -FilePath 'powershell' -ArgumentList '-NoExit','-Command',"Set-Location `'$path`'; $cmd"
	} else {
		Push-Location $path
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
$Global:DevShellExe = 'powershell'    # or 'pwsh'

$Global:RustacularFrontendPath = 'C:\development\projects\Rustacular\rustacular'
$Global:RustacularBackendPath  = 'C:\development\projects\Rustacular\backend'
$Global:RustacularDatabasePath = 'postgres://sohailmd123:toormd123@localhost:5432/rustacular'

# Open nvim in the frontend in the current window
function Open-FrontendNvim {
    Push-Location $Global:RustacularFrontendPath
    try {
        nvim .
    } finally {
        Pop-Location
    }
}

# Open nvim in the backend in the current window
function Open-BackendNvim {
    Push-Location $Global:RustacularBackendPath
    try {
        nvim .
    } finally {
        Pop-Location
    }
}

function Sea-Orm-MigrateReset {
	Push-Location $Global:RustacularBackendPath
	try {
		sea-orm-cli migrate reset -u $Global:RustacularDatabasePath
	} finally {
		Pop-Location
	}
}

function Sea-Orm-MigrateUp {
	Push-Location $Global:RustacularBackendPath
	try {
		sea-orm-cli migrate up -u $Global:RustacularDatabasePath
	} finally {
		Pop-Location
	}
}


function Sea-Orm-GenerateEntity {
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

function Delete-Frontend-App {
	try {
		adb -s emulator-5554 uninstall com.rustacular.app
	} catch {
		"No Such App exists"
	}
}

# Open both in separate NEW windows
function Open-DevNvim-All {
    Open-FrontendNvim-NewWindow
    Open-BackendNvim-NewWindow
}

# Optional: short aliases
Set-Alias ofn Open-FrontendNvim
Set-Alias obn Open-BackendNvim
Set-Alias ofnw Open-FrontendNvim-NewWindow
Set-Alias obnw Open-BackendNvim-NewWindow
Set-Alias odna Open-DevNvim-All
Set-Alias sdb Start-Backend
Set-Alias sdf Start-Frontend
Set-Alias sdf1 Start-Frontend-Fold
Set-Alias sde Start-Emulator
Set-Alias sdef Start-Emulator-Frontend
Set-Alias sde1 Start-Emulator-Fold
Set-Alias sda Start-Dev-All
Set-Alias sdw Start-Dart-Watch
Set-Alias onv Open-Neovim
Set-Alias dfa Delete-Frontend-App
Set-Alias smr Sea-Orm-MigrateReset
Set-Alias smu Sea-Orm-MigrateUp
Set-Alias sge Sea-Orm-GenerateEntity

# Optional: If you use Windows Terminal (wt), open two tabs that run nvim in each folder
function Open-DevNvim-WT {
    # requires 'wt' on PATH (Windows Terminal)
    wt new-tab powershell -NoExit -Command "Set-Location '$Global:RustacularFrontendPath'; nvim ." `
       ; new-tab powershell -NoExit -Command "Set-Location '$Global:RustacularBackendPath'; nvim ."
}
