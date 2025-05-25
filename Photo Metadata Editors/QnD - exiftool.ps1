# Define your folder path
$folderPath = "\\diskyboi\NAS01\Kyle's OneDrive\Pictures\01. Import\Jeremy's Photos\Vietnam\VNTZ"

# Get all JPG files in the folder
$jpgFiles = Get-ChildItem -Path $folderPath -Filter "*.jpg" -File

# Change directory to target folder
cd $folderPath



# Process files in parallel (Utilizing all 8 CPUs)
$jpgFiles | ForEach-Object -Parallel {

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

    exiftool -OffsetTimeOriginal=+07:00 -OffsetTime=+07:00 -OffsetTimeDigitized=+07:00 $_.FullName
} -ThrottleLimit 8  # Maximize CPU usage by running 8 parallel tasks

exiftool $jpgFiles