$p = $profile

function kps {
	& "C:\Program Files (x86)\KeePass Password Safe 2\KeePass.exe"
}

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