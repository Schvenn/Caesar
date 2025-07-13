function caesar {# A shift character function for file obfuscation/deobfuscation.
param ([Parameter(Position = 0)] [string]$source, [Parameter(Position = 1)] [int]$shift = 1, [Parameter(Position = 2)] [string]$outfile, [switch]$undo, [switch]$screen, [switch]$noheader, [switch]$quiet, [switch]$help, [switch]$bruteforce); ""

# Define file paths relative to the script location
$scriptDir = Split-Path $PSCommandPath

# Modify fields sent to it with proper word wrapping.
function wordwrap ($field, $maximumlinelength) {if ($null -eq $field) {return $null}
$breakchars = ',.;?!\/ '; $wrapped = @()
if (-not $maximumlinelength) {[int]$maximumlinelength = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($maximumlinelength -lt 60) {[int]$maximumlinelength = 60}
if ($maximumlinelength -gt $Host.UI.RawUI.BufferSize.Width) {[int]$maximumlinelength = $Host.UI.RawUI.BufferSize.Width}
foreach ($line in $field -split "`n", [System.StringSplitOptions]::None) {if ($line -eq "") {$wrapped += ""; continue}
$remaining = $line
while ($remaining.Length -gt $maximumlinelength) {$segment = $remaining.Substring(0, $maximumlinelength); $breakIndex = -1
foreach ($char in $breakchars.ToCharArray()) {$index = $segment.LastIndexOf($char)
if ($index -gt $breakIndex) {$breakIndex = $index}}
if ($breakIndex -lt 0) {$breakIndex = $maximumlinelength - 1}
$chunk = $segment.Substring(0, $breakIndex + 1); $wrapped += $chunk; $remaining = $remaining.Substring($breakIndex + 1)}
if ($remaining.Length -gt 0 -or $line -eq "") {$wrapped += $remaining}}
return ($wrapped -join "`n")}

# Display a horizontal line.
function line ($colour, $length, [switch]$pre, [switch]$post, [switch]$double) {if (-not $length) {[int]$length = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($length) {if ($length -lt 60) {[int]$length = 60}
if ($length -gt $Host.UI.RawUI.BufferSize.Width) {[int]$length = $Host.UI.RawUI.BufferSize.Width}}
if ($pre) {Write-Host ""}
$character = if ($double) {"="} else {"-"}
Write-Host -f $colour ($character * $length)
if ($post) {Write-Host ""}}

function help {# Inline help.
# Select content.
$scripthelp = Get-Content -Raw -Path $PSCommandPath; $sections = [regex]::Matches($scripthelp, "(?im)^## (.+?)(?=\r?\n)"); $selection = $null; $lines = @(); $wrappedLines = @(); $position = 0; $pageSize = 30; $inputBuffer = ""

function scripthelp ($section) {$pattern = "(?ims)^## ($([regex]::Escape($section)).*?)(?=^##|\z)"; $match = [regex]::Match($scripthelp, $pattern); $lines = $match.Groups[1].Value.TrimEnd() -split "`r?`n", 2; if ($lines.Count -gt 1) {$wrappedLines = (wordwrap $lines[1] 100) -split "`n", [System.StringSplitOptions]::None}
else {$wrappedLines = @()}
$position = 0}

# Display Table of Contents.
while ($true) {cls; Write-Host -f cyan "$(Get-ChildItem (Split-Path $PSCommandPath) | Where-Object { $_.FullName -ieq $PSCommandPath } | Select-Object -ExpandProperty BaseName) Help Sections:`n"

if ($sections.Count -gt 7) {$half = [Math]::Ceiling($sections.Count / 2)
for ($i = 0; $i -lt $half; $i++) {$leftIndex = $i; $rightIndex = $i + $half; $leftNumber  = "{0,2}." -f ($leftIndex + 1); $leftLabel   = " $($sections[$leftIndex].Groups[1].Value)"; $leftOutput  = [string]::Empty

if ($rightIndex -lt $sections.Count) {$rightNumber = "{0,2}." -f ($rightIndex + 1); $rightLabel  = " $($sections[$rightIndex].Groups[1].Value)"; Write-Host -f cyan $leftNumber -n; Write-Host -f white $leftLabel -n; $pad = 40 - ($leftNumber.Length + $leftLabel.Length)
if ($pad -gt 0) {Write-Host (" " * $pad) -n}; Write-Host -f cyan $rightNumber -n; Write-Host -f white $rightLabel}
else {Write-Host -f cyan $leftNumber -n; Write-Host -f white $leftLabel}}}

else {for ($i = 0; $i -lt $sections.Count; $i++) {Write-Host -f cyan ("{0,2}. " -f ($i + 1)) -n; Write-Host -f white "$($sections[$i].Groups[1].Value)"}}

# Display Header.
line yellow 100
if ($lines.Count -gt 0) {Write-Host  -f yellow $lines[0]}
else {Write-Host "Choose a section to view." -f darkgray}
line yellow 100

# Display content.
$end = [Math]::Min($position + $pageSize, $wrappedLines.Count)
for ($i = $position; $i -lt $end; $i++) {Write-Host -f white $wrappedLines[$i]}

# Pad display section with blank lines.
for ($j = 0; $j -lt ($pageSize - ($end - $position)); $j++) {Write-Host ""}

# Display menu options.
line yellow 100; Write-Host -f white "[↑/↓]  [PgUp/PgDn]  [Home/End]  |  [#] Select section  |  [Q] Quit  " -n; if ($inputBuffer.length -gt 0) {Write-Host -f cyan "section: $inputBuffer" -n}; $key = [System.Console]::ReadKey($true)

# Define interaction.
switch ($key.Key) {'UpArrow' {if ($position -gt 0) { $position-- }; $inputBuffer = ""}
'DownArrow' {if ($position -lt ($wrappedLines.Count - $pageSize)) { $position++ }; $inputBuffer = ""}
'PageUp' {$position -= 30; if ($position -lt 0) {$position = 0}; $inputBuffer = ""}
'PageDown' {$position += 30; $maxStart = [Math]::Max(0, $wrappedLines.Count - $pageSize); if ($position -gt $maxStart) {$position = $maxStart}; $inputBuffer = ""}
'Home' {$position = 0; $inputBuffer = ""}
'End' {$maxStart = [Math]::Max(0, $wrappedLines.Count - $pageSize); $position = $maxStart; $inputBuffer = ""}

'Enter' {if ($inputBuffer -eq "") {"`n"; return}
elseif ($inputBuffer -match '^\d+$') {$index = [int]$inputBuffer
if ($index -ge 1 -and $index -le $sections.Count) {$selection = $index; $pattern = "(?ims)^## ($([regex]::Escape($sections[$selection-1].Groups[1].Value)).*?)(?=^##|\z)"; $match = [regex]::Match($scripthelp, $pattern); $block = $match.Groups[1].Value.TrimEnd(); $lines = $block -split "`r?`n", 2
if ($lines.Count -gt 1) {$wrappedLines = (wordwrap $lines[1] 100) -split "`n", [System.StringSplitOptions]::None}
else {$wrappedLines = @()}
$position = 0}}
$inputBuffer = ""}

default {$char = $key.KeyChar
if ($char -match '^[Qq]$') {"`n"; return}
elseif ($char -match '^\d$') {$inputBuffer += $char}
else {$inputBuffer = ""}}}}}

# External call to help.
if ($help) {help; return}

if (-not $source) {# If the user forgets to provide any parameters, quote Julius Caesar.
$CaesarQuotes = @("`'Veni, vidi, vici.`'`n`'I came, I saw, I conquered.`'", "`'Alea iacta est.`'`n`'The die is cast.`'", "`'Et tu, Brute?`'`n`'And you, Brutus?`'", "`'Non hos timeo, sed illos pallidos et macilentos.`'`n`'It is not these well-fed long-haired men that I fear, but the pale and the hungry-looking.`'", "`'In bello parvis momentis magni casus intercedunt.`'`n`'In war, events of importance are the result of trivial causes.`'", "`'Honorem nomen plus quam mortem timeo.`'`n`'I love the name of honor more than I fear death.`'", "`'Experientia docet omnia.`'`n`'Experience is the teacher of all things.`'"); Write-Host -f white ($CaesarQuotes | Get-Random) -n; Write-Host -f darkcyan " - Julius Caesar`n"; return}

# Normalize shift to ensure it's between 1 and 25
$shift = ($shift % 26); if ($shift -eq 0) {$shift = 1}

# Shifts alphabetic characters based on $shift variable provided.
function shiftchar ($char, $shift) {$code = [int][char]$char
if ($code -ge 65 -and $code -le 90) {return [char]((($code - 65 + $shift + 26) % 26) + 65)}
elseif ($code -ge 97 -and $code -le 122) {return [char]((($code - 97 + $shift + 26) % 26) + 97)}
else {return $char}}

# Create random strings for header and blank line content creation.
function randomstring($length) {$chars = ([char[]](33..126 | Where-Object {$_ -notin @(172, 173, 188, 189, 190)})) -join ''; -join (1..$length | ForEach-Object {$chars[(Get-Random -Max $chars.Length)]})}

# Distinguish files from text input.
if (Test-Path $source) {$text = Get-Content $source -Raw; $isFileInput = $true; $filename = [System.IO.Path]::GetFileName($source)}
else {$text = $source; $isFileInput = $false}
$originaltext = $text

# Undo logic to reverse shifting.
if ($undo) {if ($text -match "^Çæšª®.{10}\d{3}(\d{2}).{10}([^\¼½¾µ°¬]{5,})(?=.{10}µ)") {$extractedShift = [int]$matches[1]; $shift = -$extractedShift; $encFilename = $matches[2]; $decFilename = ($encFilename.ToCharArray() | ForEach-Object {shiftchar $_ $shift}) -join ''
if (-not $screen) {if ($PSBoundParameters.ContainsKey('outfile')) {$saveAs = $outfile}
else {$saveAs = $decFilename}}
$text = $text -replace "^Çæšª®.{10}\d{3}\d{2}.{10}.+?µ", ''}
else {$text = $text -replace "^Ç.+µ", ''; $text = $text -replace "^.+µ", ''
if ($isFileInput) {Write-Host -f yellow "There was an invalid or missing header. Proceeding without header."}
$shift = -$shift
if (-not $screen) {$saveAs = $outfile}}}

# Bruteforce recover a file by searching for patterns of 3 to 10 consecutive words that are 4 or more letters in length.
function recoverbrokenheader {param ([string]$text, [string]$outfile)

# Define pattern and find the best one from the file.
$pattern = '(?i)([A-Z]{4,}[^A-Z]+){3,10}'
if ($text -match $pattern) {$matches = [regex]::Matches($text, $pattern)
if ($matches.Count -gt 0) {$bestMatch = $matches | Sort-Object {($_ -replace '[^A-Za-z~]', '~').Split('~') | Where-Object { $_ -match '^[A-Z]{4,}$' } | Measure-Object | Select-Object -ExpandProperty Count} -Descending | Select-Object -First 1; $matchedString = $bestMatch.Value}
$words = ($matchedString -replace "[^A-Za-z~]", "~").Split('~')
Write-Host -f yellow ("-"*100); Write-Host -f yellow "Sample found of consecutive words: " -n; Write-Host -f white $matchedString; Write-Host -f yellow ("-"*100)

# Load the dictionary, iterate through the $shift values and keep track of the best match.
function decompressbase64gzip ($base64) {$bytes = [Convert]::FromBase64String($base64); $ms = New-Object System.IO.MemoryStream(,$bytes); $gzip = New-Object System.IO.Compression.GzipStream($ms, [IO.Compression.CompressionMode]::Decompress); $reader = New-Object IO.StreamReader($gzip); return $reader.ReadToEnd()}
$script:Dictionary = (decompressbase64gzip $script:CompressedDictionary | ConvertFrom-Json)

$CommonWords = @(); $CommonWords = $script:Dictionary -split ','; $bestShift = $null; $highestCount = 0; $bestShiftCount = 0
for ($shift = 1; $shift -le 25; $shift++) {$shiftedWords = $words | ForEach-Object {$shiftedWord = $_ -replace "([A-Za-z])", {$shiftedChar = shiftchar $_.Value -$shift
return $shiftedChar}; return $shiftedWord}
$result = ($shiftedWords -join " "); $matchCount = ($shiftedWords | Where-Object {$word = $_.ToLower(); $CommonWords.Where({ $commonword = $_; $word -like "*$commonword" -or $word -like "$commonword*"}).Count -gt 0}).Count
if ($matchCount -gt $highestCount) {$highestCount = $matchCount; $bestShift = $shift; $bestShiftCount = 1}
elseif ($matchCount -eq $highestCount) {$bestShiftCount++}
Write-Host -f cyan "$shift - " -n; Write-Host -f white "$result" -n
if ($matchCount -gt 0) {Write-Host -f yellow " $matchCount or more common words found."} else {Write-Host ""}
if ($PSCmdlet.MyInvocation.BoundParameters["outfile"]) {$line = "$shift - $result"; if ($matchCount -gt 0) {$line += " ($matchCount or more common words found.)"}
$line | Out-File -FilePath $outfile -Append -Encoding UTF8}}

# Write file if a best match is found, unless -screen was used.
Write-Host -f yellow ("-"*100)
if ($bestShiftCount -eq 1 -and -not $screen) {Write-Host -f green "`nAutomatically decrypting using best shift: $bestShift"
$undoFile = if ($PSCmdlet.MyInvocation.BoundParameters["outfile"]) {$outfile} else {"$source.undo"}
Write-Host -f cyan "`nSaved to file: $undoFile"; 

# Undo logic to reverse shifting.
$bruteforce = ($text.ToCharArray() | ForEach-Object {shiftchar $_ -$bestShift}) -join ''
$bruteforce = $bruteforce -replace "^Ç.+µ", ''; $bruteforce = $bruteforce -replace "^.+µ", ''; $bruteforce = $bruteforce -replace "°¬[¼½¾].+?°¬", "°¬°¬"; $bruteforce = $bruteforce -replace "~", " "; $bruteforce = $bruteforce -replace "°¬", "`r`n"; $bruteforce | Out-File -FilePath $undoFile -Encoding UTF8 -nonewline; return}}
else {Write-Host -f red "No matching pattern found in the encrypted text."; return}}

# Bruteforce switch functionality
if ($bruteforce) {Write-Host -f cyan "Starting bruteforce recovery..."; recoverbrokenheader -text $text -outfile $outfile; ""; return}

# Select file as output if either the source was a file, or the user requested a file to be saved.
if ($isFileInput -or $PSBoundParameters.ContainsKey('outfile')) {$saveAs = $outfile}

# Remaining character replacements: space, CR/LF, blank lines.
$text = $text -replace " ", "~"; $text = $text -replace "`r", "°" -replace "`n", "¬"; $text = [regex]::Replace($text, "°¬°¬", {"°¬" + ("¼","½","¾" | Get-Random) + (randomstring (Get-Random -Min 40 -Max 1000)) + "°¬"})

# Call the character shift function.
$output = ($text.ToCharArray() | ForEach-Object {shiftchar $_ $shift}) -join ''; if ($undo) {$output = $output -replace "°¬[¼½¾].+?°¬", "°¬°¬"; $output = $output -replace "~", " "; $output = $output -replace "°¬", "`r`n"}; $outputwithoutheader = $output

# If encoding file, default to adding header. Do not do so for string input or -noheader flag.
if (-not $undo -and $isFileInput -and -not $noheader) {$shiftStr = $shift.ToString("00"); $header = "Çæšª®" + (randomstring 10) + (Get-Random -Minimum 100 -Maximum 999).ToString() + $shiftStr + (randomstring 10); $encFileName = (($filename + ".undo").ToCharArray() | ForEach-Object {shiftchar $_ $shift}) -join ''; $header += $encFileName + (randomstring 10) + "µ"; $output = $header + $output}

# Display output to screen unless -quiet flag set.
if (-not $quiet) {Write-Host -f yellow ("-"*100); Write-Host $originaltext; Write-Host -f yellow ("-"*100); Write-Host $outputwithoutheader; Write-Host -f yellow ("-"*100); ""}

# Save file if not outputting only to screen.
if (-not $screen -and $saveAs -is [string] -and $saveAs.Trim() -ne '') {Write-Host -f cyan "Saved to file: $saveAs`n"; $output = $output.TrimEnd("`r", "`n"); $output | Out-File -FilePath $saveAs -Encoding UTF8 -nonewline}}

Export-ModuleMember -Function caesar

<#
## Overview
This Caesar function was designed as a demonstration of the basic Caesar cipher encryption technique, in order to create a simple file obfuscation tool.
It provides users with the ability to obfuscate and deobfuscate files and strings to screen or disk and has the the following capabilities:

• Obfuscate a string to screen or disk using an integer value to represent the number of times to shift the alphabetic characters.

• When obfuscating a string to disk, no header is present in the output by design.

• Obfuscate a file to screen or disk.

• When obfuscating a file to disk, a header is present, unless the -noheader switch is used.

• When obfuscating to screen, the original text and obfuscated text is presented unless the -quiet switch is used.

• Deobfuscate a string to screen or disk using the -undo option and an integer value to represent the number of times to reverse the character shifts.

• Deobfuscate a file to screen if the -screen option is used.

• Deobfuscate a file to disk, using the header to determine the number of times the characters were shifted and the default output file name.

• Deobfuscate a file to disk with the user provided alternate destination.

• Brute force -undo of a file by running the entire 25 character shift against 3 consecutive words in the file in order to find the proper shift value for -undo.
## Obfuscation
The obfuscation works as follows:

• All alphabetic characters and only those, are shifted to a subsequent value, determined by the $shift value provided to the script via the command line.

• Case-sensitivity is maintained.

• All non-alphabetic characters remain unchanged, with the following exceptions:

• Spaces are replaced by "~".

• Carriage returns and line feeds "\r\n" are replaced by "°¬".

• When a blank line is found, these are filled with random characters, starting with one of "¼½¾" and ending with the aforementioned line feed characters.
## Deobfuscation
Deobfuscation reverses the above steps:

• Alphabetic characters are shifted back.

• Spaces are returned to normal.

• Carriage returns and line feeds are returned to normal.

• Blank lines are returned to blank lines.

When saving output to file:

• If a user-provided string is saved to file, no header is added.

• If a file is provides as the source, a header is generated unless the -noheader option is used.

• Headers use the following rules:

• The header starts with the characters "Çæšª®".

• The header is masked with random characters in all but the key locations.

• The header contains a 5 digit number ending in a 2 digit integer representing the number of times the original file was shifted.

• The header contains the original file name with the added extension of ".undo" as the default destination for output. This file name is also obfuscated.

• The header ends with the character "µ".

It is this header generation and straightforward, standardized obfuscation methodology that makes these files easy to deobfuscate, even if the header is damaged or no header is provided. Add to that the fact that each character can only have 26 possible values and that all characters are shifted in the same way and this makes for a very weak, but visually effective means of obfuscating text.

This tool was not developed to create some next generation encryption methodology that cannot be broken by a myriad of quantum computers. It was designed as a proof of concept for red Team testing and to create a simple obfuscation tool, with practical end user application in mind.
## Recovering Files
The final feature of this script is the -BruteForce, which will read an obfuscated file and iterate through all 25 possible combinations of character shift in order to try to find the value that was used against the original file. 

• It does this by first finding a pattern of letters in the encrypted file of between 3 and 10 words in length.

• It then applies each of the possible shifts to this sample string in order to obtain a comparative output.

• Next, it reads the inline dictionary which contains just under 5000 English words between 4 and 10 characters long, in order to see if it can find any matches. This list contains only base words, without suffixes, no proper nouns and is based upon Google's most common English words, validated against the Scrabble English dictionary.

• Usually, one shift value will have substantially more word matches than others and if this is the case, the script will automatically use that to decrypt the file.

• The default file name can be overriden, if the user provides an $outfile parameter and the output can instead be written to screen only if the -screen option is used.
## String Command Demonstrations

• Encrypt a string to screen.
	caesar "encrypt me" 10

• Encrypt a string to disk and view the file.
	caesar "encrypt me" 10 "file.caesar"; gc file.caesar
• Decrypt a string to screen.
	caesar "oxmbizd~wo" 10 -undo

• Decrypt a string to disk and view the file.
	caesar "oxmbizd~wo" 10 "file.caesar.undo" -undo; gc file.caesar.undo

• Decrypt a string input that was saved to disk and view on screen. The file won't contain a header.
	caesar "file.caesar" 10 -undo

• Decrypt a string input saved to disk and view the file. The file won't contain a header.
	caesar "file.caesar" 10 "file.caesar.undo2" -undo; gc file.caesar.undo

• Remove string demonstrations.
	del file.caesar.undo; del file.caesar.undo2; del file.caesar
## File Command Demonstrations
• Create a sample file for the demonstration.
	$string = "alternate encrypt me"; $file = "file.txt"; Out-File -FilePath $file -InputObject $string

• Encrypt a file to screen.
	caesar "file.txt" 10

• Encrypt a file to disk, but suppress verbose output and view the file.
	caesar "file.txt" 10 "file.txt.caesar" -quiet; gc file.txt.caesar

• Encrypt a file to disk, but save it without a header and view the file.
	caesar "file.txt" 10 "file.txt.caesar" -noheader; gc file.txt.caesar

• Encrypt a file to disk and view the file.
	caesar "file.txt" 10 "file.txt.caesar"; gc file.txt.caesar

• Decrypt a file to screen.
	caesar "file.txt.caesar" 10 -undo -screen

• Decrypt a file using the default options, which are saved in the header.
	caesar "file.txt.caesar" 10 -undo; gc file.txt.undo

• Decrypt a file using an alternate destination file and view the file.
	caesar "file.txt.caesar" 10 alternate.undo -undo; gc alternate.undo

• Remove demonstration files.
	del file.txt.caesar; del file.txt; del file.txt.undo; del alternate.undo
## Broken or Missing Header Demonstrations
• Create a sample file with a broken header for the demonstration.
	$string = "Çæšª®Q?l3-µkvdobxkdo~oxmbizd~wo"; $file="file.broken"; Out-File -FilePath $file -InputObject $string

• Decrypt a file with a broken header to screen.
	caesar "file.broken" 10 -undo

• Decrypt a file with a broken header to disk and view the file.
	caesar "file.broken" 10 "file.fixed.undo" -undo; gc file.fixed.undo

• Remove demonstration files.
	del file.fixed.undo; del file.broken
## Brute Force Demonstrations
• Create a successful sample file for the brute force demonstration.
	caesar "Gaius Julius Caesar was a Roman ruler and his salads taste really good, too." 712100 "caesar.born"

• Run the entire 25 character shift against the file in order to attempt recovery, but output to screen only.
	caesar caesar.born -bruteforce -screen

• Brute force the results and save to the default file.
	caesar caesar.born -bruteforce; gc "caesar.born.undo"

• Brute force the results, but save to a custom file.
	caesar caesar.born -outfile "file.other.undo" -bruteforce; gc file.other.undo

• Remove demonstration files.
	del caesar.born; del caesar.born.undo; del file.other.undo
## Red Team
Now, if you really want to see something cool, check out this truly minimalist version of the function designed to eliminate all screen output and provide a real challenge for Blue and Purple team detection:

-------------------------
function c {param([string]$s,[int]$sh=1,[string]$o,[switch]$u,[switch]$nh);$sc={param($c,$sh)$cd=[int][char]$c;if($cd-ge 65-and $cd-le 90){[char]((($cd-65+$sh+26)%26)+65)}elseif($cd-ge 97-and $cd-le 122){[char]((($cd-97+$sh+26)%26)+97)}else{$c}};$rs={param($l)$cs=([char[]](33..126|?{$_-notin 172,173,188,189,190}))-join '';-join(1..$l|%{$cs[(Get-Random -Maximum $cs.Length)]})};$t=(Test-Path $s)?(Get-Content $s -Raw):$s;$f=Test-Path $s;$fn=[IO.Path]::GetFileName($s);if($u){if($t-match"^çæšª®.{10}\d{3}(\d{2}).{10}([^\¼½¾µ°¬]{5,})(?=.{10}µ)"){$sh=-[int]$matches[1];$fn2=($matches[2].ToCharArray()|%{&$sc $_ $sh})-join'';$t=$t-replace"^çæšª®.{10}\d{3}\d{2}.{10}.+?µ",""}else{$t=$t-replace"^ç.+µ",'';$t=$t-replace"^.+µ",'';$sh=-$sh}};$t=$t-replace" ","~";$t=$t-replace"`r","°"-replace"`n","¬";$t=[regex]::Replace($t,"°¬°¬",{"°¬"+("¼","½","¾"|Get-Random)+(&$rs (Get-Random -Minimum 40 -Maximum 1000))+"°¬"});$o2=($t.ToCharArray()|%{&$sc $_ $sh}) -join'';if($u){$o2=$o2-replace"°¬[¼½¾].+?°¬","°¬°¬";$o2=$o2-replace"~"," ";$o2=$o2-replace"°¬","`r`n"};if(-not $u-and -not $nh -and $f){$ss=$sh.ToString("00");$h="çæšª®"+(&$rs 10)+(Get-Random -Minimum 100 -Maximum 999).ToString()+$ss+(&$rs 10);$fn2=(($fn+".undo").ToCharArray()|%{&$sc $_ $sh}) -join'';$h+=$fn2+(&$rs 10)+"µ";$o2=$h+$o2};if($o){$fn2=$o};if($fn2){$o2.TrimEnd("`r","`n")|Out-File $fn2 -Encoding utf8 -nonewline}}
-------------------------

I am not adding it separately, because I don't want to encourage abuse, which can happen even with a script as limited as this one. However, since it is still an effective obfuscation tool for red Team activities, by still including it here, I can at least create some limited security through obscurity. Also note that the wordwrap function in this module forces line breaks where none exist in the code. So, those would have to be removed in order to make this code effective as it is actually a single line of code.
## License
MIT License

Copyright © 2025 Craig Plath

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
THE SOFTWARE.
##>

$script:CompressedDictionary = @'
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
'@