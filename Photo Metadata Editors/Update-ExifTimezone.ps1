#############################################################################
#
# Photo Metadata Editor - Update TimeZones Using exiftool
# (PME_exif)
#
# Description: 
# Updates the exif metadata of each photo to reflect the correct timezone
# while keeping the date and time of the original photo
#
# Author: Kyle Dunkerley
# Date: 02/05/2025
# 
#############################################################################

# -------  Change these values for your use case -------  #

# Define the folder containing your photos
$folderPath = "Path_to_folder"

# The timezone to update to
# EG: Australia is +10:00 for AEDT and +11:00 for AEST
# For this one, I have used Veitnam ($timezone)
$timeZone = "$timezone"


# -------  The script -------  #
# Change nothing under this line unless you like tinkering

# Install ExifTool via WinGet
winget install --id PhilHarvey.ExifTool -e

# Define the expected installation path
$ExifToolPath = "C:\Program Files\ExifTool"

# Verify the installation
if (!(Test-Path $ExifToolPath)) {
    Write-Host "ExifTool installation path not found. Check manually."
    exit
}

# Get current system path variables
$CurrentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)

# Check if ExifTool is already in the path
if ($CurrentPath -like "*$ExifToolPath*") {
    Write-Host "ExifTool is already in the system PATH."
} else {
    # Append ExifTool path to system variables
    $NewPath = "$CurrentPath;$ExifToolPath"
    [System.Environment]::SetEnvironmentVariable("Path", $NewPath, [System.EnvironmentVariableTarget]::Machine)
    
    Write-Host "ExifTool has been added to the system PATH."
}

# Verify by checking the version
Write-Host "Verifying ExifTool installation..."
Start-Process -NoNewWindow -Wait -FilePath "exiftool" -ArgumentList "-ver"

# Check if folder exists
if (-not (Test-Path $folderPath)) {
    Write-Host "`e[31mERROR: Folder path does not exist: $folderPath`e[0m"
    exit
}

# Get all JPG files in the folder
$jpgFiles = Get-ChildItem -Path $folderPath -Filter "*.jpg" -File


# Process each image file
foreach ($file in $jpgFiles) {
    Write-Host "Processing $($file.FullName)"

    try {
        # Delete any lingering ExifTool temporary files
        Remove-Item "$($file.FullName)_exiftool_tmp" -ErrorAction SilentlyContinue

        # Read original timestamp and timezone offset
        $dateTaken = & $exifToolPath -DateTimeOriginal -S -s -d "%Y:%m:%d %H:%M:%S" "$($file.FullName)"
        $offsetTimeOriginal = & $exifToolPath -OffsetTimeOriginal -S -s "$($file.FullName)"

        # Ensure DateTimeOriginal is valid
        if ($dateTaken -eq $null -or $dateTaken -eq "") {
            Write-Host "ERROR: Skipping $($file.FullName) - No valid DateTimeOriginal found $resetText" -ForegroundColor Red
            continue
        }

        # Check if the photo is already set to the correct timezone
        if ($offsetTimeOriginal -eq $timeZone) {
            Write-Host "Skipping $($file.FullName) - Already set to $timeZone $resetText" -ForegroundColor Green
            continue
        }

        # Determine Melbourne timezone offset based on daylight saving period
        $dateTimeObj = [DateTime]::ParseExact($dateTaken, "yyyy:MM:dd HH:mm:ss", $null)
        $originalTimezone = if ($dateTimeObj.Month -ge 10 -or $dateTimeObj.Month -le 3) { "+11:00 (AEDT)" } else { "+10:00 (AEST)" }

        Write-Host "Original timestamp: $dateTaken | Original timezone: $originalTimezone"

        # Update timezone offset
        & $exifToolPath "-OffsetTimeOriginal=$timezone" "-OffsetTimeDigitized=$timezone" "$($file.FullName)"
        Write-Host "Updated timezone offset to $timezone for $($file.FullName)" -ForegroundColor Green

        # Sync metadata properly
        & $exifToolPath "-overwrite_original" "-P" "-XMP:all=IPTC:all" "$($file.FullName)"
        Write-Host "Metadata synchronized for $($file.FullName)" -ForegroundColor Green

        # Re-read the new timestamp
        $newTimestamp = & $exifToolPath -DateTimeOriginal -S -s -d "%Y:%m:%d %H:%M:%S" "$($file.FullName)"

        # Output new timestamp in green
        Write-Host "SUCCESS: New timestamp: $newTimestamp | New timezone: $timezone $resetText" -ForegroundColor Green
    
    } catch {
        Write-Host "ERROR: Failed to process $($file.FullName) - $_ $resetText" -ForegroundColor Red
    }
}

Write-Host "Processing complete. Changes applied using ExifTool, with full metadata sync. $resetText" -ForegroundColor Green