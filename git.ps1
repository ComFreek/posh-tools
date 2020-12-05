function gs {
	& git status
}

function gpl {
	& git pull
}

function gpu {
	& git push
}

# commit all ("ca") in a git repo
function ca {
	& git add --all
	& git commit -m $($args -join " ")
	& git status
}

# commit all ammend ("caa") in a git repo
function caa {
	& git commit --all --amend -m $($args -join " ")
	& git status
}

function cas {
	& git commit --all -m $(($args -join " ") + " [skip ci]")
	& git status
}

# commit all & push ("cap") in a git repo
function cap {
	ca @args
	& git push
}

. (Join-Path $PSScriptRoot ".\git-online.ps1")