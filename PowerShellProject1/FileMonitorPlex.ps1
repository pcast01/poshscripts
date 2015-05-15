#Powershell script FileMonitor script for adding new shows to Plex
########################################################
########################################################
## Purpose: When Vuze completes downloading a show    ##
## then this will check to see if the file names are  ##
## in the correct format then copy to TV completed    ##
## folder and then run theRenamer program to rename   ##
## and move them to D: drive. Check to see what files ##
## were renamed & print them. Next have Plex refresh  ##
## and add them into the Plex server.                 ##
##                                                    ## 
## by Paul Castillo                                   ##  
########################################################

Write-Host "Starting Plex Monitor." -ForegroundColor Red
$Source = "C:\Users\Paul\Documents\Vuze Completed"
$filter = '*.*'                             # <-- set this according to your requirements
try {
	$fsw = New-Object IO.FileSystemWatcher $Source, $filter -Property @{
	 IncludeSubdirectories = $true              # <-- set this according to your requirements
	 NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'
	}
}
    catch {
        Write-Verbose "Error starting FSW-File System Watcher."
        Write-Host "Error starting file system watcher" -ForegroundColor Red
    }
try {
	$onCreated = Register-ObjectEvent $fsw Created -SourceIdentifier FileCreated -Action {
	 $Source = "C:\Users\Paul\Documents\Vuze Completed"
	 $Destination = "C:\Users\Paul\Documents\Vuze TV Completed"
     
     # Check for files with 4 digits for season and episode number.
     Write-Host "Check for 2 digits next to 2 digits..." -ForegroundColor Yellow
     Get-ChildItem "C:\Users\Paul\Documents\Vuze Completed\*.mp4" -Recurse -Exclude *sample* |
        Where-Object { $_.Name -match '(\d{2})(\d{2})'}
     Get-ChildItem "C:\Users\Paul\Documents\Vuze Completed\*.mp4" -Recurse -Exclude *sample* | 
        Where-Object { $_.Name -match '(\d{2})(\d{2})'} | Move-Item -Dest {$_.FullName -replace '(\d{2})(\d{2})', 's$1e$2'}

     # Check for files with 1 digit next to 2 digits for season and episode number.
     Write-Host "Check for 1 digit next to 2 digits..." -ForegroundColor Yellow
     Get-ChildItem "C:\Users\Paul\Documents\Vuze Completed\*.mp4" -Recurse -Exclude *sample* | 
        Where-Object { $_.Name -match '(\d{1})(\d{2})'}

     Get-ChildItem "C:\Users\Paul\Documents\Vuze Completed\*.mp4" -Recurse -Exclude *sample* | 
        Where-Object { $_.Name -match '(\d{1})(\d{2})'} | Move-Item -Dest {$_.FullName -replace '(\d{1})(\d{2})', 's0$1e$2'}

	 Write-Host "Copying new files to TV Completed folder."
     robocopy "C:\Users\Paul\Documents\Vuze Completed" "C:\Users\Paul\Documents\Vuze TV Completed" *.mkv *.avi *.mp4 /S /XF "*sample*"
	 Write-Host "Renaming tvshow with correct names..." -ForegroundColor yellow
     Start-Process 'C:\Program Files (x86)\theRenamer\theRenamer.exe' -Wait -ArgumentList '-fetch'
	 Write-Host "Checking to see what shows were renamed correctly." -ForegroundColor yellow
	 # Run function to check theRenamer logs for shows that were renamed. 
	 CheckTVShows
     # Delete all files in the 'Vuze TV Completed' 
     Get-ChildItem -Path $Destination -Include *.* -File -Recurse | foreach { $_.Delete()}
     # Delete all empty folders in 'Vuze TV Completed'
     dir "C:\Users\Paul\Documents\Vuze TV Completed\*" | foreach { [io.directory]::delete($_.fullname) }
     $a = Get-Date
	 Write-Host "Done. Time is: $a" -ForegroundColor Red
	}
}
catch
{
	Write-Host "Failed to Register event." -ForegroundColor Red
}
#Unregister-Event -SourceIdentifier FileCreated