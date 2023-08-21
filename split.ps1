param(
    [string]$inputFile = "$env:USERPROFILE\desktop\decrypted-file.bin",
    [string]$outputDirectory = "$env:USERPROFILE\desktop\",
    [string]$hexPattern = "53514C697465"
)

# Read the binary file as a byte array
$fileBytes = [System.IO.File]::ReadAllBytes($inputFile)

# Convert the hex pattern to a byte array
$patternBytes = [byte[]]::new($hexPattern.Length / 2)
for ($i = 0; $i -lt $patternBytes.Length; $i++) {
    $patternBytes[$i] = [convert]::ToByte($hexPattern.Substring($i * 2, 2), 16)
}

# Find positions of the hex pattern within the binary file
$positions = @()
$offset = 0
while ($offset -lt ($fileBytes.Length - $patternBytes.Length + 1)) {
    $position = [array]::IndexOf($fileBytes, $patternBytes[0], $offset)
    if ($position -eq -1) {
        break
    }
    $match = $true
    for ($i = 1; $i -lt $patternBytes.Length; $i++) {
        if ($fileBytes[$position + $i] -ne $patternBytes[$i]) {
            $match = $false
            break
        }
    }
    if ($match) {
        $positions += $position
        $offset = $position + $patternBytes.Length
    } else {
        $offset = $position + 1
    }
}

if ($positions.Count -eq 0) {
    Write-Host "Hex pattern not found in the file."
    exit
}

# Split the file into chunks based on the found positions ${chunkNum} not need in filename
$chunkNum = 0
foreach ($position in $positions) {
    $chunkNum++
    
    # Create a chunk with data before the hex pattern
    $startPos = 0
    $endPos = $position - 1
    $length = $endPos - $startPos + 1
    $chunkData = $fileBytes[$startPos..$endPos]
    $outputFile = Join-Path -Path $outputDirectory -ChildPath "FH5_save_header.bin"
    [System.IO.File]::WriteAllBytes($outputFile, $chunkData)
    
    # Create a chunk with the hex pattern and subsequent data
    $startPos = $position
    $endPos = $fileBytes.Length - 1
    $length = $endPos - $startPos + 1
    $chunkData = $fileBytes[$startPos..$endPos]
    $outputFile = Join-Path -Path $outputDirectory -ChildPath "FH5_save_database.slt"
    [System.IO.File]::WriteAllBytes($outputFile, $chunkData)
    
    $startPos = $position + $patternBytes.Length
}

Write-Host "File split into $chunkNum chunks."
