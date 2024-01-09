



write-host "What would you like to do?"
write-host "A) Collect new baseline"
write-host "B) Begin monitoring files with saved Baseline?"

$response = Read-Host -Prompt "Please enter 'A' or 'B'"
write-host ""

#write-host "User entered $($response)"

Function Calculate-File-Hash($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}

Function Erase-Baseline-If-Already-Exists() {
    $baselineExists = Test-Path -Path .\baseline.txt

    if ($baselineExists) {
        #Delete it
        Remove-Item -Path .\baseline.txt
    }
}

if ($response -eq "A".ToUpper()) {
    #Delete baseline.txt if already exists
    Erase-Baseline-If-Already-Exists

    #Calculate the Hash from the target files and store in baseline.txt
    write-host "Calculate Hashes, make new baseline.txt" -ForegroundColor Cyan

    #Collect all files in the target folder
    $files = Get-ChildItem -Path .\files

    #For file, calculate the hash, and write to baseline.txt
    foreach ($f in $files) {
        $hash = Calculate-File-Hash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-FIle -FilePath .\baseline.txt -Append
    }
}
elseif ($response -eq "B".ToUpper()) {
    $fileHashDictionary = @{}

    #Load filehash from baseline.txt and store them in a dictionary
    $filePathsAndHashes = Get-Content -Path .\baseline.txt

    foreach ($f in $filePathsAndHashes) {
        $fileHashDictionary.add($f.Split("|")[0],$f.Split("|")[1])
    }

    #$fileHashDictionary.keys
    #$fileHashDictionary.Values

    #Begin (continuously) monitoring files with saved Baseline
    write-host "Read existing baseline.txt, start monitoring files." -ForegroundColor Magenta

    while ($true) {
        #Write-Host "Checking if files match..."
        Start-Sleep -Seconds 1

        $files = Get-ChildItem -Path .\files

        #For file, calculate the hash, and write to baseline.txt
        foreach ($f in $files) {
            $hash = Calculate-File-Hash $f.FullName
            #"$($hash.Path)|$($hash.Hash)" | Out-FIle -FilePath .\baseline.txt -Append

            #Notify if a new file has been created
            if ($fileHashDictionary[$hash.Path] -eq $null) {
                #A new file has been creatted
                Write-Host "$($hash.Path) has been created!" -Foreground Green
            }
            else {
                #Notify if a new file has been changed
                if ($fileHashDictionary[$hash.Path] -eq $hash.Hash) {
                    #The file has not changed
                }
                else {
                    Write-Host "$($hash.Path) has changed!!!" -ForegroundColor Yellow
                }
            }
        }

        foreach ($key in $fileHashDictionary.keys) {
            $baslineFileStillExists = Test-Path -Path $key
            if (-Not $baslineFileStillExists) {
                #One of the baseline files must have been deletted, notify user
                Write-Host "$($key) has been deleted!" -ForegroundColor Red
            }
        }

    }
}