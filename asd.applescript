install()
set profileAlias to choose file with prompt "Please select an ALPS profile:"
set thePath to convertPathToPOSIXString(profileAlias)
runAsd(thePath)

on open theDroppedItems
	install()
	set thePath to (POSIX path of first item of theDroppedItems)
	runAsd(thePath as string)
end open

on install()
	do shell script "open -a Docker"
	
	repeat until DockerStarted()
		delay 1
	end repeat
	
	set installCmd to "docker pull ghcr.io/alps-asd/app-state-diagram:latest ; touch ~/.asd-install"
	set lockFile to "~/.asd-install"
	
	try
		do shell script "rm " & lockFile
	end try
	
	do shell script installCmd
	
	repeat until FileExists(lockFile)
		delay 1
	end repeat
	
	do shell script "rm " & lockFile
end install


on runAsd(thePath)
	set directory to characters 1 thru -((offset of "/" in (reverse of items of thePath as string)) + 1) of thePath as string
	set fileName to name of (info for thePath)
	set runCmd to "docker run --env COMPOSER_PROCESS_TIMEOUT=0 -v " & directory & ":/work -it --init --rm --name asd -p 3000:3000 ghcr.io/alps-asd/app-state-diagram composer global exec asd -- --watch /work/" & fileName
	
	tell application "Terminal"
		activate
		do script runCmd
	end tell
	
	delay 5
	open location "http://localhost:3000"
end runAsd

on DockerStarted()
	set dockerPs to do shell script "/usr/local/bin/docker ps | cut -c 1-9"
	if dockerPs = "" then
		return false
	else
		return true
	end if
end DockerStarted

on FileExists(theFile) -- (String) as Boolean
	tell application "System Events"
		if exists file theFile then
			return true
		else
			return false
		end if
	end tell
end FileExists

on convertPathToPOSIXString(thePath)
	tell application "System Events"
		try
			set thePath to path of disk item (thePath as string)
		on error
			set thePath to path of thePath
		end try
	end tell
	return POSIX path of thePath
end convertPathToPOSIXString