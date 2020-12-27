function gs {
	& git status
}

function gd {
	& git diff
}

# Display the "git difference to origin" (e.g. if git status says "you're two commits ahead of origin", this command prints out which commits they are)
function gdo {
	& git log "@{u}"..HEAD
}

function gpl {
	& git pull
}

function gpu {
	Request-Keepass # from generic.ps1
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
	gpu
}

. (Join-Path $PSScriptRoot ".\git-online.ps1")