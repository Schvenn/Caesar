# A shift character function for file obfuscation/deobfuscation.
param ([Parameter(Position = 0)] [string]$source, [Parameter(Position = 1)] [int]$shift = 1, [Parameter(Position = 2)] [string]$outfile, [switch]$undo, [switch]$screen, [switch]$noheader, [switch]$quiet, [switch]$help, [switch]$commands); ""

$gethelp = @"
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

The obfuscation works as follows:

• All alphabetic characters and only those, are shifted to a subsequent value, determined by the $shift value provided to the script via the command line.
• Case-sensitivity is maintained.
• All non-alphabetic characters remain unchanged, with the following exceptions:
	• Spaces are replaced by "~".
	• Carriage returns and line feeds "\r\n" are replaced by "°¬".
	• When a blank line is found, these are filled with random characters, starting with one of "¼½¾" and ending with the aforementioned line feed characters.

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

This tool was not developed to create some next generation encryption methodology that cannot be broken by a myriad of quantum computers. It was designed as a proof of concept for Red Team testing and to create a simple obfuscation tool, with practical end user application in mind.

"@

$getcommands=@"
# In order to see the function in action, the following commands demonstrate the capabilities of the Caesar function.

caesar "encrypt me" 10 # Encrypt a string to screen.
caesar "encrypt me" 10 "file.caesar"; gc file.caesar # Encrypt a string to disk and view the file.
caesar "oxmbizd~wo" 10 -undo # Decrypt a string to screen.
caesar "oxmbizd~wo" 10 "file.caesar.undo" -undo; gc file.caesar.undo # Decrypt a string to disk and view the file.
caesar "file.caesar" 10 -undo # Decrypt a string input that was saved to disk and view on screen. The file won't contain a header.
caesar "file.caesar" 10 "file.caesar.undo2" -undo; gc file.caesar.undo # Decrypt a string input saved to disk and view the file. The file won't contain a header.
del file.caesar.undo; del file.caesar.undo2; del file.caesar # Remove string demonstrations.

$string = "alternate encrypt me"; $file = "file.txt"; Out-File -FilePath $file -InputObject $string # Create a sample file for the demonstration.
caesar "file.txt" 10 # Encrypt a file to screen.
caesar "file.txt" 10 "file.txt.caesar" -quiet; gc file.txt.caesar # Encrypt a file to disk, but suppress verbose output and view the file.
caesar "file.txt" 10 "file.txt.caesar" -noheader; gc file.txt.caesar # Encrypt a file to disk, but save it without a header and view the file.
caesar "file.txt" 10 "file.txt.caesar"; gc file.txt.caesar # Encrypt a file to disk and view the file.
caesar "file.txt.caesar" 10 -undo -screen # Decrypt a file to screen.
caesar "file.txt.caesar" 10 -undo; gc file.txt.undo # Decrypt a file using the default options, which are saved in the header.
caesar "file.txt.caesar" 10 alternate.undo -undo; gc alternate.undo # Decrypt a file using an alternate destination file and view the file.
del file.txt.caesar; del file.txt; del file.txt.undo; del alternate.undo # Remove file demonstrations

$string = "Çæšª®Q?l3-µkvdobxkdo~oxmbizd~wo"; $file="file.broken"; Out-File -FilePath $file -InputObject $string # Create a sample file with a broken header for the demonstration.
caesar "file.broken" 10 -undo # Decrypt a file with a broken header to screen.
caesar "file.broken" 10 "file.fixed.undo" -undo; gc file.fixed.undo # Decrypt a file with a broken header to disk and view the file.
del file.fixed.undo; del file.broken # Remove file demonstrations.

Now, if you really want to see something cool, check out this truly minimalist version of the function designed to eliminate all screen output and provide a real challenge for Blue and Purple team detection:

-------------------------
function c {param([string]$s,[int]$sh=1,[string]$o,[switch]$u,[switch]$nh);$sc={param($c,$sh)$cd=[int][char]$c;if($cd-ge 65-and $cd-le 90){[char]((($cd-65+$sh+26)%26)+65)}elseif($cd-ge 97-and $cd-le 122){[char]((($cd-97+$sh+26)%26)+97)}else{$c}};$rs={param($l)$cs=([char[]](33..126|?{$_-notin 172,173,188,189,190}))-join '';-join(1..$l|%{$cs[(Get-Random -Maximum $cs.Length)]})};$t=(Test-Path $s)?(Get-Content $s -Raw):$s;$f=Test-Path $s;$fn=[IO.Path]::GetFileName($s);if($u){if($t-match"^çæšª®.{10}\d{3}(\d{2}).{10}([^\¼½¾µ°¬]{5,})(?=.{10}µ)"){$sh=-[int]$matches[1];$fn2=($matches[2].ToCharArray()|%{&$sc $_ $sh})-join'';$t=$t-replace"^çæšª®.{10}\d{3}\d{2}.{10}.+?µ",""}else{$t=$t-replace"^ç.+µ",'';$t=$t-replace"^.+µ",'';$sh=-$sh}};$t=$t-replace" ","~";$t=$t-replace"`r","°"-replace"`n","¬";$t=[regex]::Replace($t,"°¬°¬",{ "°¬"+("¼","½","¾"|Get-Random)+(&$rs (Get-Random -Minimum 40 -Maximum 1000))+"°¬" });$o2=($t.ToCharArray()|%{&$sc $_ $sh}) -join'';if($u){$o2=$o2-replace"°¬[¼½¾].+?°¬","°¬°¬";$o2=$o2-replace"~"," ";$o2=$o2-replace"°¬","`r`n"};if(-not $u-and -not $nh -and $f){$ss=$sh.ToString("00");$h="çæšª®"+(&$rs 10)+(Get-Random -Minimum 100 -Maximum 999).ToString()+$ss+(&$rs 10);$fn2=(($fn+".undo").ToCharArray()|%{&$sc $_ $sh}) -join'';$h+=$fn2+(&$rs 10)+"µ";$o2=$h+$o2};if($o){$fn2=$o};if($fn2){$o2.TrimEnd("`r","`n")|Out-File $fn2 -Encoding utf8 -NoNewline}}
-------------------------

"@

# Help files.
if ($help) {cls; [console]::foregroundcolor="white"; Write-Host $gethelp; [console]::foregroundcolor="gray"; return}
if ($commands) {cls; [console]::foregroundcolor="white"; Write-Host $getcommands; [console]::foregroundcolor="gray"; return}

# Shifts alphabetic characters based on $shift variable provided.
function Shift-Char ($char, $shift) {$code = [int][char]$char
if ($code -ge 65 -and $code -le 90) { return [char]((($code - 65 + $shift + 26) % 26) + 65) }
elseif ($code -ge 97 -and $code -le 122) { return [char]((($code - 97 + $shift + 26) % 26) + 97) }
else { return $char }}

# Create random strings for header and blank line content creation.
function Random-String($length) {$chars = ([char[]](33..126 | Where-Object {$_ -notin @(172, 173, 188, 189, 190)})) -join ''; -join (1..$length | ForEach-Object { $chars[(Get-Random -Max $chars.Length)] })}

# Distinguish files from text input.
if (Test-Path $source) {$text = Get-Content $source -Raw; $isFileInput = $true; $filename = [System.IO.Path]::GetFileName($source)}
else {$text = $source; $isFileInput = $false}
$originaltext = $text

# Undo logic to reverse shifting.
if ($undo) {if ($text -match "^Çæšª®.{10}\d{3}(\d{2}).{10}([^\¼½¾µ°¬]{5,})(?=.{10}µ)") {$extractedShift = [int]$matches[1]; $shift = -$extractedShift; $encFilename = $matches[2]; $decFilename = ($encFilename.ToCharArray() | ForEach-Object { Shift-Char $_ $shift }) -join ''
if (-not $screen) {if ($PSBoundParameters.ContainsKey('outfile')) {$saveAs = $outfile}
else {$saveAs = $decFilename}}
$text = $text -replace "^Çæšª®.{10}\d{3}\d{2}.{10}.+?µ", ''}
else {$text = $text -replace "^Ç.+µ", ''; $text = $text -replace "^.+µ", ''
if ($isFileInput) {Write-Host -f Yellow "There was an invalid or missing header. Proceeding without header."}
$shift = -$shift
if (-not $screen) {$saveAs = $outfile}}}

# Ensure $shift is a representative value of the alphabet, 0-26.
if (-not $undo) {if ($shift -gt 26) { $shift = $shift % 26 }

# Select file as output if either the source was a file, or the user requested a file to be saved.
if ($isFileInput) {$saveAs = $outfile}
elseif ($PSBoundParameters.ContainsKey('outfile')) {$saveAs = $outfile}}

# Remaining character replacements: space, CR/LF, blank lines.
$text = $text -replace " ", "~"; $text = $text -replace "`r", "°" -replace "`n", "¬"; $text = [regex]::Replace($text, "°¬°¬", { "°¬" + ("¼","½","¾" | Get-Random) + (Random-String (Get-Random -Min 40 -Max 1000)) + "°¬" })

# Call the character shift function.
$output = ($text.ToCharArray() | ForEach-Object { Shift-Char $_ $shift }) -join ''; if ($undo) {$output = $output -replace "°¬[¼½¾].+?°¬", "°¬°¬"; $output = $output -replace "~", " "; $output = $output -replace "°¬", "`r`n"}; $outputwithoutheader = $output

# If encoding file, default to adding header. Do not do so for string input or -noheader flag.
if (-not $undo -and $isFileInput -and -not $noheader) {$shiftStr = $shift.ToString("00"); $header = "Çæšª®" + (Random-String 10) + (Get-Random -Minimum 100 -Maximum 999).ToString() + $shiftStr + (Random-String 10); $encFileName = (($filename + ".undo").ToCharArray() | ForEach-Object { Shift-Char $_ $shift }) -join ''; $header += $encFileName + (Random-String 10) + "µ"; $output = $header + $output}

# Display output to screen unless -quiet flag set.
if (-not $quiet) {Write-Host -f Yellow ("-"*100); Write-Host $originaltext; Write-Host -f Yellow ("-"*100); Write-Host $outputwithoutheader; Write-Host -f Yellow ("-"*100); ""}

# Save file if not outputting only to screen.
if (-not $screen -and $saveAs -is [string] -and $saveAs.Trim() -ne '') {Write-Host -f Cyan "Saved to file: $saveAs`n"; $output = $output.TrimEnd("`r", "`n"); $output | Out-File -FilePath $saveAs -Encoding UTF8 -NoNewline}
