<#

Fully flattens an array.

Source: <https://stackoverflow.com/a/33545660/603003>
Author: Matt <https://stackoverflow.com/users/3829407/matt>
License: CC BY-SA 3.0 <https://creativecommons.org/licenses/by-sa/3.0/>

#>
function Flatten-Array {
  $input | ForEach-Object{
      if ($_ -is [array]){$_ | Flatten-Array}else{$_}
  } | Where-Object{![string]::IsNullorEmpty($_)}
}

function Flatten-Args {
	($input | Flatten-Array) -join " "
}

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

function gplrec {
	git submodule foreach "git pull"
}

function gpu {
	Request-Keepass # from generic.ps1
	& git push
}

# commit all ("ca") in a git repo
function ca {
	& git add --all
	& git commit -m $($args | Flatten-Args)
	& git status
}

# commit all ammend ("caa") in a git repo
function caa {
	& git commit --all --amend -m $($args | Flatten-Args)
	& git status
}

function cas {
	& git commit --all -m $(($args | Flatten-Args) + " [skip ci]")
	& git status
}

# commit all & push ("cap") in a git repo
function cap {
	ca @args
	gpu
}

. (Join-Path $PSScriptRoot ".\git-online.ps1")