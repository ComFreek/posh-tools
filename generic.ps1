$p = $profile

if (-not $(Get-Module -ListAvailable -Name VirtualDesktop)) {
	Write-Error @"
The PowerShell module VirtualDesktop needs to be installed: Install-Module VirtualDesktop.
See <https://github.com/MScholtes/PSVirtualDesktop>.
"@
}

Add-Type @"
  using System;
  using System.Runtime.InteropServices;
  public class WindowUtils {
     [DllImport("user32.dll")]
	 public static extern IntPtr GetForegroundWindow();
	 
	 [DllImport("user32.dll")]
	 [return: MarshalAs(UnmanagedType.Bool)]
     public static extern bool SetForegroundWindow(IntPtr hWnd);
  }
"@

function Request-NamedDesktop {
	<#
		.SYNOPSIS
			Retrieves or creates (if non-existing) the virtual desktop with the given name.
		
		.INPUTS
			The desktop name can be piped into this function.

		.OUTPUTS
			A virtual desktop with the given name.

		.EXAMPLE
			Request-NamedDesktop "My Secret Desktop"
		.EXAMPLE
			"My Secret Desktop" | Request-NamedDesktop | Switch-Desktop
		
		.NOTES
			The function assumes that the PSVirtualDesktop module [0] is installed.

			[0]: https://github.com/MScholtes/PSVirtualDesktop
	#>
	param(
		<#
			The name of the virtual desktop to retrieve or create (if non-existing)
		#>
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[ValidateNotNullOrEmpty()]	
		[string]$name
	)

	$desktop = Get-DesktopList | Where-Object Name -eq $name | Select-Object -First 1
	if ($desktop) {
		Get-Desktop -Index $desktop.Number
	} else {
		$desktop = New-Desktop
		$desktop | Set-DesktopName -Name $name
		$desktop
	}
}

function Request-Keepass {
	<#
		.SYNOPSIS
			Starts KeePass if it is not running yet, and moves KeePass to a dedicated
			KeePass virtual desktop named, which is created if non-existing.
		
		.DESCRIPTION
			KeePass can be used with its KeeAgent plugin to conveniently use SSH keys, say,
			for git pull/push [0]. 

			For that KeePass needs to be started. Moreover, I'd like KeePass to not clutter my
			main virtual desktop. Hence, this function starts KeePass if needed, and -- in any
			case whether started or not -- moves KeePass to a dedicated KeePass virtual desktop.

			See also Request-KeepassDesktop for this dedicated virtual desktop.

			[0]: https://gist.github.com/ComFreek/b4bddf7f46d77222110731f3c9aecbba.

		.NOTES
			The function assumes that the PSVirtualDesktop module [0] is installed.

			[0]: https://github.com/MScholtes/PSVirtualDesktop
	#>
	$keepassDesktopName = "KeePass Desktop"
	$keepassPath = "C:\Program Files (x86)\KeePass Password Safe 2\KeePass.exe"
	$keepassProcessName = "keepass"

	$keepass = Get-Process $keepassProcessName -ErrorAction SilentlyContinue | Select-Object -First 1
	if (-not $keepass) {
		# KeePass is not running => start it, wait until it full window shows (after password entry
		# from user), and then switch it to the dedicated virtual desktop
		#
		# Also, pay attention to move focus again to the window (probably terminal) that had focus
		# before
		& $keepassPath

		$focusOldWindow = [WindowUtils]::GetForegroundWindow()

		$title = $null
		while (-not $title -contains "KeePass") {
			Start-Sleep -Milliseconds 500
			$keepass = Get-Process $keepassProcessName | Select-Object -First 1
			$title = $keepass | Select-Object -ExpandProperty MainWindowTitle
		}
	}

	$keepass |
		Select-Object -First 1 -ExpandProperty MainWindowHandle |
		Move-Window (Request-NamedDesktop $keepassDesktopName) |
		Out-Null
	
	if ($focusOldWindow) {
		[WindowUtils]::SetForegroundWindow($focusOldWindow) | Out-Null
	}
}
Set-Alias -Name kps -Value Request-Keepass

function profile {
	# launch a new Notepad++ process and wait for it to exit
	notepad++ -multiInst -nosession -notabbar -noPlugin $profile | Out-Null
	# then reload the profile in the global context (". $profile" would load into this function's context)
	$Global:ExecutionContext.SessionState.InvokeCommand.InvokeScript(". $profile")
}

function pp {
	profile
}

function e {
	exit
}

# "back"
function b {
	Pop-Location
}