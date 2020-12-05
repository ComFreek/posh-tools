function Get-GitOnlineURI {
	<#
	  .SYNOPSIS
		Matches a Git remote URI against a list of known Git servers that have offer
		web interfaces, such as GitHub.com.
		Upon a match, a URI is returned at which the repository can be viewed in
		the corresponding web interface.

		The parameters Path and Committish control which path (folder or file) and
		which commit/branch the returned URI should show at the web interface.

	.DESCRIPTION
		A longer description.

	.INPUTS
		You can pipe the Git remote URI as input.

	.OUTPUTS
		Upon success -- if the remote could be matched, a single URI as a string is returned.
		Upon failure, an error message is written via Write-Error and nothing is returned.

	.EXAMPLE
		Get-GitOnlineURI https://github.com/github/docs.git data/variables
		"https://github.com/github/docs/tree/master/data/variables"

		(Here we use the repository github/docs on GitHub.com as an example.
		You can view all links in your web browser.)

	.EXAMPLE
		Get-GitOnlineURI https://github.com/github/docs.git -Committish 9c47a9e503d5c6a3a4f7b3bc80177c5bcd3653c9
		https://github.com/github/docs/tree/9c47a9e503d5c6a3a4f7b3bc80177c5bcd3653c9

	.EXAMPLE
		Get-GitOnlineURI https://github.com/github/docs.git data/variables -Committish 9c47a9e503d5c6a3a4f7b3bc80177c5bcd3653c9
		https://github.com/github/docs/tree/9c47a9e503d5c6a3a4f7b3bc80177c5bcd3653c9/data/variables

	.EXAMPLE
		Get-GitOnlineURI https://github.com/github/docs.git -Committish main
		https://github.com/github/docs/tree/main

	.EXAMPLE
		Get-GitOnlineURI https://gitlab.com/gitlab/www-gitlab-com.git -GitLabInstances @("gitlab.com")
		https://gitlab.com/gitlab/www-gitlab-com

	.NOTES
		The returend URI ought to be human-readable: e.g. for a GitHub remote if both Path and Committish
		are empty, then the returned URI is `"https://github.com/<user>/<repo>"` and *not*
		`"https://github.com/<user>/<repo>/tree/<DefaultBranch>"`.

	#>
  param(
		<#
			A Git remote URI, all protocols are supported.

			Known remote URI formats (and thus Git servers this function can resolve) are:

			- for GitHub:
				- https://github.com/<user>/<repo>.git
				- git@github.com:<user>/<repo>.git
			- for GitLab:
				- https://<instance>/<user>/<repo>.git
				- git@<instance>:<user>/<repo>.git

			if <instance> is supplied in the GitLabInstances parameter.
			See examples.
		#>
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Remote,

		<#
			A relative path to a folder or file for which the returned URI will be tailored.
			When empty, the returned URI will show the repository's root (in the state as instructed
			by Committish).

			The path *must* use (single) forward slashes.
			The path *must not* start with a slash, end with a slash, or contain relative parts
			like "." or "..".

			Valid paths:

				- folder
				- folder/subfolder
				- folder/subfolder/file.txt

			Unsupported paths are:

				- /folder
				- folder/
				- folder\subfolder
				- folder/subfolder/../file.txt
		#>
		[string]$Path,

		<#
			Either empty, a full revision SHA1, a shortened revision SHA1, a tag name, or a branch name.

			For instance, valid argument values are:

				- 9c47a9e503d5c6a3a4f7b3bc80177c5bcd3653c9  # full revision SHA1
				- 9c47a9e                                   # shortened revision SHA1
				- v20.0.0                                   # tag name
				- main                                      # branch name
		#>
		[string]$Committish,

		<#
			The branch on which to show Path if Committish is empty.
		#>
		[ValidateNotNullOrEmpty()]
		[string]$DefaultBranch = 'master',

		[String[]]$GitLabInstances = @()
	)

	# GitHub
	$githubRegex = "((git@github\.com:)|(https://github.com/))(?<user>[^/]+)/(?<repo>[^.]+)\.git"
	if ($Remote -match $githubRegex) {
		if ($Committish) {
			$committish = "/tree/" + $Committish
		} elseif ($Path) {
			$committish = "/tree/" + $DefaultBranch
		}		
		
		if ($Path) {
			$path = "/" + $Path
		}
		

		return "https://github.com/" + $matches["user"] + "/" + $matches["repo"] + $Committish + $Path
	}

	# GitLab
	$gitlabRegex = "((git@(?<host>[^:]+):)|(https://(?<host>[^/]+)/))(?<user>[^/]+/)(?<repo>[^.]+)\.git"
	if (($Remote -match $gitlabRegex) -and ($GitLabInstances -contains $matches["host"])) {
		if ($Committish) {
			$Committish = "/-/tree/" + $Committish
		} elseif ($Path) {
			$Committish = "/-/tree/" + $DefaultBranch
		}

		if ($Path) {
			$Path = "/" + $Path
		}

		return "https://" + $matches["host"] + "/" + $matches["user"] + $matches["repo"] + $Committish + $Path
	}

	$gitlabInstancesStr = if ($GitLabInstances) { $GitLabInstances -join "," } else { "<empty array>" }

	Write-Error -ErrorAction Stop `
		("Could not parse Git remote URI ``$Remote``. " + `
		 "GitLab instances taken into account (via -GitLabInstances) were: $gitlabInstancesStr")
}

function Join-PathGracefully {
	param(
		[string] $a,
		[string] $b
	)
	
	if ($a) {
		if ($b) {
			return Join-Path $a $b
		} else {
			return $a
		}
	} else {
		return $b
	}
}

function Find-GitOnlineURI {
	<#
	  .SYNOPSIS
		Receives a file path and, by identifying the containing Git repository and parsing
		its remotes (against some standard ones), returns the URI at which the file path
		can be viewed in the web interface corresponding to the remote.

	.INPUTS
		You can pipe the file path as input.

	.OUTPUTS
		Upon success, a single URI as a string is returned.
		Upon failure, an error message is written via Write-Error and nothing is returned.

	.EXAMPLE
		Find-GitOnlineURI repo/src
		https://github.com/user/repo/tree/9c47a9e503d5c6a3a4f7b3bc80177c5bcd3653c9/src

		Assume `repo` is a folder in which `https://github.com/user/repo` was cloned
		and the latest local commit is `9c47a9e503d5c6a3a4f7b3bc80177c5bcd3653c9`.

	.EXAMPLE
		Find-GitOnlineURI repo/src -Revision branch
		https://github.com/user/repo/tree/devel/src

		In addition to example I, assume the branch that is currently locally checked out
		in `repo` is `devel`.
	#>
	param(
		<#
			A local file path to a folder or file contained in a Git repository.

			The path can point to a folder or file arbitrarily nested in a Git repository.
			The innermost Git repository that can be found by stepping up is used.
		#>
		[Parameter(ValueFromPipeline=$true)]
		[string] $Path = '.',
		
		<#
			The "revision" controls for which committish the URI is returned.

			See help of `Get-GitOnlineURI` for how committishes influence the URI.
			Here is how the committish is determined depending on the revision argument:

			- 'head'  :  the output of `git rev-parse HEAD`
						 (usually a the full SHA1 of the latest commit)

			- 'branch':  the current branch (git branch --show-current)

			- 'none'  :  leave out the committish in the call to `Get-GitOnlineURI`
		#>
		[ValidateNotNullOrEmpty()]
		[ValidateSet('head', 'branch', 'none', 'a')]
		[string]$Revision = 'head',

		[string[]]$GitLabInstances = @()
	)

	$file = ""

	# For easily running some Git commands below, we switch to the context of Path
	if ((Get-Item $path) -is [System.IO.DirectoryInfo]) {
		Push-Location $path
	} else {
		# $Path probably points to a file
		Push-Location (Split-Path $path -Parent)
		$file = Split-Path $path -Leaf
	}

	# The path relative to the Git repository, already in a format (forward slashes only, no ".", no "..")
	# ready to pass on to Get-GitOnlineURI.
	$relpath = Join-PathGracefully $(git rev-parse --show-prefix) $file

	# Determine the remote branch that the current brach tracks
	# (from https://stackoverflow.com/a/9753364/603003)
	$trackedRef = git for-each-ref --format='%(upstream:short)' "$(git symbolic-ref -q HEAD)"
	($trackedRemote, $trackedRemoteBranch) = $trackedRef -split "/",2 # only split on first slash as branch names may contain slashes

	$trackedRemoteURI = $(git remote get-url $trackedRemote)

	$committish = switch ($revision) {
		'head'    { $(git rev-parse HEAD)        }
		'branch'  { $(git branch --show-current) }
		'none'    { '' }
		''        { Write-Error -ErrorAction Stop `
								"Failed to validate revision argument ``$revision``. Did PowerShell not " +
								"validate the argument or did you change the parameter type without " +
								" changing the switch statement from which this error originates, too?" }
	}
	
	Pop-Location

	Get-GitOnlineURI `
		-Remote $trackedRemoteURI -Path $relpath -Committish $committish `
		-DefaultBranch $trackedRemoteBranch `
		-GitLabInstances $GitLabInstances
}

function Open-GitOnline {
	<#
	  .SYNOPSIS
		Receives a file path and, by identifying the containing Git repository and parsing
		its remotes (against some standard ones), open the URI at which the file path
		can be viewed in the web interface corresponding to the remote.

	  .DESCRIPTION
		This function simply opens the URI as returned by Find-GitOnlineURI via Start-Process.
		
		See Find-GitOnlineURI for more documentation on the parameters and the returned URI that
		is then opened.

	.INPUTS
		You can pipe the file path as input.

	.OUTPUTS
		None
	#>
	param(
		[Parameter(ValueFromPipeline=$true)]
		[string]$Path = '.',
		
		[ValidateNotNullOrEmpty()]
		[ValidateSet('default','branch','head')]
		[string]$Revision = 'head'
	)

	$gitlabInstances = $env:GITLAB_INSTANCES -split ","

	Find-GitOnlineURI -Path $Path -Revision $Revision -GitLabInstances $gitlabInstances | % {
		Start-Process -FilePath $_
	}
}

Set-Alias -Name ogo -Value Open-GitOnline
