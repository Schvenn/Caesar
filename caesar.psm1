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

# Inline help.
if ($help) {function scripthelp ($section) {line yellow 100 -pre; $pattern = "(?ims)^## ($section.*?)(##|\z)"; $match = [regex]::Match($scripthelp, $pattern); $lines = $match.Groups[1].Value.TrimEnd() -split "`r?`n", 2; Write-Host $lines[0] -f yellow; line yellow 100
if ($lines.Count -gt 1) {wordwrap $lines[1] 100 | Out-String | Out-Host -Paging}; line yellow 100}

$scripthelp = Get-Content -Raw -Path $PSCommandPath; $sections = [regex]::Matches($scripthelp, "(?im)^## (.+?)(?=\r?\n)")
if ($sections.Count -eq 1) {cls; Write-Host "$([System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)) Help:" -f cyan; scripthelp $sections[0].Groups[1].Value; ""; return}
$selection = $null
do {cls; Write-Host "$([System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)) Help Sections:`n" -f cyan; for ($i = 0; $i -lt $sections.Count; $i++) {"{0}: {1}" -f ($i + 1), $sections[$i].Groups[1].Value}
if ($selection) {scripthelp $sections[$selection - 1].Groups[1].Value}
$input = Read-Host "`nEnter a section number to view"
if ($input -match '^\d+$') {$index = [int]$input
if ($index -ge 1 -and $index -le $sections.Count) {$selection = $index}
else {$selection = $null}} else {""; return}}
while ($true); return}

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
$CommonWords = @(); $CommonWords = $Dictionary -split ','; $bestShift = $null; $highestCount = 0; $bestShiftCount = 0
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
$bruteforce = $bruteforce -replace "^Ç.+µ", ''; $bruteforce = $bruteforce -replace "^.+µ", ''; $bruteforce = $bruteforce -replace "°¬[¼½¾].+?°¬", "°¬°¬"; $bruteforce = $bruteforce -replace "~", " "; $bruteforce = $bruteforce -replace "°¬", "`r`n"; $bruteforce | Out-File -FilePath $undoFile -Encoding UTF8 -n; return}}
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

<# Everything below this line are the help screens for this function.
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

I am not adding it separately, because I don't want to encourage abuse, which can happen even with a script as limited as this one. However, since it is still an effective obfuscation tool for red Team activities, by still including it here, I can at least create some limited security through obscurity.
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

$Dictionary = "abandon,ability,able,aboriginal,abortion,about,above,abroad,abs,absent,absolute,absorption,abstract,abuse,academic,academy,accent,accept,access,accessory,accident,accomplish,accord,account,accredit,accuracy,accurate,accused,acer,achieve,achieved,achieving,acid,acne,acoustic,acquire,acquired,acre,acrobat,acros,acrylic,act,action,activated,activation,active,activist,activity,actress,actual,acute,adapt,adaptation,adaptive,add,addiction,addition,address,addresses,adequate,adjacent,adjust,admin,admission,admit,admitted,adobe,adolescent,adopt,adoption,adult,advance,advanced,advantage,adventure,adverse,advert,advertise,advertiser,advice,advise,advised,advisor,advocacy,advocate,adware,aerial,aerospace,affair,affect,affiliate,affiliated,afford,afraid,aft,afternoon,afterward,ag,again,against,age,agency,agenda,agent,aggregate,aggressive,agree,agreed,ahead,aid,aim,aircraft,airfare,airline,airplane,airport,alan,alarm,alaska,albert,album,alcohol,alert,alexander,algebra,algorithm,alias,alien,align,alike,alive,alleged,allergy,alliance,allied,allocated,allocation,allow,alloy,almost,alone,along,alpha,alpine,already,also,alt,alternate,although,alto,aluminium,aluminum,alumni,alway,amateur,amazing,amazon,ambassador,amber,ambient,amen,amend,amino,among,amongst,amount,amplifier,analog,analyse,analysis,analyst,analytical,analyze,analyzed,anatomy,anchor,ancient,angel,anger,angle,angola,angry,anima,animal,animated,anime,anna,annex,annotated,annotation,announce,announced,annoy,annual,anonymous,another,answer,antenna,anti,antibody,antique,antivirus,anxiety,anybody,anymore,anyone,anything,anytime,anyway,anywhere,apache,apart,apollo,app,apparatus,apparel,apparent,appeal,appear,appendix,apple,appliance,applicable,applicant,applied,appoint,appraisal,appreciate,approach,approaches,approval,approve,approved,aqua,aquarium,aquatic,arabic,arb,arbitrary,arcade,arch,architect,archive,archived,arctic,area,arena,argue,argued,argument,aris,arise,arm,around,arrange,arranged,array,arrest,arrival,arrive,arrived,arrow,art,arthritis,article,artificial,artwork,as,asbestos,aside,ask,aspect,ass,assault,assembled,assembly,asses,asset,assign,assistant,associate,associated,assume,assumed,assuming,assumption,assurance,assure,assured,asthma,astrology,astronomy,asylum,athlete,athletic,atlas,atmosphere,atom,atomic,attach,attack,attempt,attend,attention,attitude,attorney,attract,attraction,attractive,attribute,auburn,auction,audience,audio,audit,august,aurora,austral,authentic,author,authorized,auto,automat,automatic,automation,automobile,automotive,autumn,available,avatar,avenue,average,aviation,avoid,awa,award,aware,awesome,awful,axis,babe,baby,bachelor,back,background,backup,bacon,bacteria,bacterial,bad,badge,bag,bailey,baker,baking,bal,balanced,bald,ball,ballet,balloon,ballot,banana,band,bandwidth,bang,bangkok,bank,bankruptcy,banned,banner,baptist,bar,barbie,bare,bargain,barn,barrel,barrier,barry,bas,base,baseball,baseline,basic,basin,basis,basket,basketball,batch,bath,bathroom,batman,batter,battle,be,beach,beaches,bead,beam,bean,bear,beast,beat,beaut,beautiful,beaver,became,because,become,becoming,bed,bedding,bedroom,beef,been,before,began,begin,beginner,beginning,begun,behalf,behavior,behaviour,behind,bel,belief,believe,believed,bell,belle,belong,below,belt,bench,benchmark,bend,beneath,beneficial,benefit,benjamin,bent,berlin,berry,beside,best,beta,beth,better,betting,betty,between,bever,beverage,beyond,bias,bible,biblical,bicycle,bid,bidder,bidding,bigg,bike,bikini,bill,billion,binary,bind,bingo,bio,biograph,biological,biology,bird,birth,birthday,bishop,bit,bite,bizarre,black,blackberry,blackjack,blade,blah,blame,blank,blanket,blast,bleed,blend,bless,blind,blink,block,blog,blogger,blogging,blond,blonde,blood,bloom,blow,blue,board,boat,bobby,bod,bold,bolivia,bolt,bomb,bond,bone,bonus,book,bookmark,bookstore,bool,boom,boost,boot,booth,bor,bord,born,borough,bos,boston,both,bottle,bottom,bought,boulder,boulevard,bound,boundary,bouquet,boutique,bowl,box,boxes,boy,bra,bracelet,bracket,brad,brain,brake,branch,branches,brand,brave,brazil,breach,bread,break,breakdown,breakfast,breast,breath,breed,brick,bridal,bride,bridge,brief,bright,brilliant,bring,bristol,broad,broadband,broadcast,broadway,brochure,broke,broken,broker,bronze,brook,broth,brought,brown,brows,browse,brunette,brush,brussels,brutal,bubble,buck,buddy,budget,buff,buffalo,bug,build,built,bulgar,bulk,bull,bullet,bulletin,bump,bunch,bundle,bunn,burden,bureau,buried,burke,burn,burst,burton,bus,buses,bush,business,businesses,butler,butt,butterfly,button,buy,buzz,byte,cabin,cabinet,cable,cache,cached,cafe,cage,cake,calcium,calculate,calculated,calculator,calendar,call,calm,cam,camcord,came,camel,camera,camp,campaign,campus,canada,canal,cancel,cancelled,cancer,candidate,candle,candy,cannon,canon,cant,canvas,canyon,cap,capability,capable,capacity,cape,capital,capitol,captain,capture,captured,car,carb,carbon,card,cardiac,care,careful,cargo,carl,carmen,carnival,carol,carpet,carr,carried,carrier,cart,cartoon,cartridge,casa,case,cash,cashier,casino,cassette,cast,castle,casual,cat,catalog,catalogue,catalyst,catch,category,cater,cathedral,catholic,cattle,caught,cause,caused,causing,caution,cave,cayman,cedar,ceil,celeb,celebrate,celebrity,cell,cellular,cement,cemetery,census,cent,central,centre,century,ceramic,ceremony,certain,certified,ch,chad,chain,chair,chairman,challenge,challenged,chamber,champagne,champion,chancellor,chang,change,channel,chao,chapel,chapt,char,charact,charge,charged,charger,charging,charitable,charleston,charlie,charlotte,charm,chart,chase,chassis,chat,che,cheap,cheat,check,checklist,checkout,cheese,chef,chem,chemical,chemistry,cheque,cherry,chess,chevy,chick,chicken,chief,child,childhood,children,chile,china,chinese,chip,chocolate,choice,choir,choose,choosing,chorus,chose,chosen,chrome,chronic,chronicle,chubby,chuck,church,churches,ciao,cigarette,cinema,cingular,circle,circuit,circular,circus,cisco,cit,citation,cite,citizen,civic,civil,claim,clan,clarity,class,classes,classic,classified,classroom,clause,clay,clean,cleanup,clear,clerk,click,client,cliff,climate,climb,clinic,clip,clock,clone,close,closed,closer,closest,closing,closure,cloth,clothe,cloud,club,cluster,coach,coaches,coal,coalition,coast,coat,cocktail,cod,code,coffee,cognitive,cohen,coin,col,cold,cole,colin,collapse,collar,colleague,collect,collection,collective,college,collins,cologne,colon,colonial,colorado,colour,column,combat,combine,combined,combining,combo,come,comedy,comfort,comic,coming,comm,command,comment,commentary,commerce,commercial,commission,commit,committed,committee,commodity,common,communist,community,comp,compact,companion,company,comparable,compare,compared,comparing,comparison,compatible,compete,competent,competing,compile,compiled,compiler,complaint,complement,complete,completed,completing,completion,complex,compliance,compliant,component,compos,composite,compound,compress,compromise,compute,computed,computer,computing,con,concept,conceptual,concern,concert,conclude,concluded,conclusion,concord,concrete,condition,condo,conduct,conf,confer,confidence,confident,configure,configured,confirm,conflict,confused,confusion,congo,congress,connect,connection,conscious,consensus,consent,consider,consistent,console,consortium,conspiracy,constant,constitute,constraint,construct,consult,consultant,consumer,contact,contain,content,contest,context,continent,continue,continued,continuing,continuity,continuous,contract,contrary,contrast,contribute,control,controlled,controller,convenient,convention,conversion,convert,convict,conviction,convinced,cook,cookbook,cookie,cool,coop,coordinate,cop,cope,copied,copper,copyright,coral,cord,core,cork,corn,corporate,corpus,correct,correction,corruption,cosmetic,cost,costa,costume,cottage,cotton,could,council,counsel,count,country,couple,coupled,coupon,courage,courier,course,court,courtesy,cove,cover,coverage,cowboy,crack,cradle,craft,craig,crap,crash,crazy,cream,create,created,creating,creation,creative,creativity,creator,creature,credit,creek,crest,crew,cricket,crime,criminal,crisis,criteria,criterion,critic,critical,criticism,crop,cross,crossword,crowd,crown,crucial,crude,cruise,crystal,cube,cubic,cuisine,cult,cultural,culture,cumulative,cup,cure,curious,currency,current,curriculum,curs,curve,custody,custom,customise,customize,customized,cut,cute,cutting,cyber,cycle,cycling,cylinder,cyprus,daddy,daily,dairy,dais,dale,damage,damaged,dame,dan,dance,dancing,dang,dangerous,danish,danny,dare,dark,dash,data,database,date,dated,dating,daughter,dawn,day,de,dead,deadline,deaf,deal,dealt,dean,dear,death,deb,debate,debt,debug,debut,decade,decent,decide,decided,decimal,decision,deck,declare,declared,decline,declined,decor,decorating,decorative,decrease,decreased,dedicated,deem,deep,def,default,defeat,defect,defend,defendant,defense,defensive,deferred,deficit,define,defined,defining,definite,definition,degree,delay,delegation,delete,deleted,delicious,delight,deliver,dell,delta,deluxe,demand,demo,democracy,democrat,democratic,den,deni,denial,dens,dense,dental,dentist,depart,departure,depend,dependent,deploy,deposit,depot,depression,depth,deputy,derby,derived,descend,describe,described,describing,desert,deserve,design,designated,desirable,desire,desired,desk,desktop,desperate,despite,destiny,destroy,detail,detect,detection,detective,determine,determined,devel,develop,deviant,deviation,device,devil,devon,devot,di,diabetes,diagnosis,diagnostic,diagram,dial,dialog,dialogue,diameter,diamond,diane,diary,dice,dictionary,die,diesel,diet,dietary,diff,differ,different,difficult,dig,digit,dimension,din,dinner,diploma,direct,direction,directive,director,dirt,disability,disable,disabled,disagree,disaster,disc,discharge,discipline,disclaim,disclose,disclosure,disco,discount,discover,discrete,discretion,discus,discusses,discussion,disease,dish,dishes,disk,disorder,dispatch,display,disposal,dispute,distant,distinct,distribute,district,disturb,div,dive,divers,diverse,divide,divided,dividend,divine,division,divorce,do,doc,dock,doctor,doctrine,docu,dodge,doe,dog,doll,dollar,domain,dome,domestic,dominant,don,dona,donate,donated,done,donna,doom,dosage,dose,double,doubt,dover,down,download,downtown,dozen,draft,drag,dragon,drain,drainage,drama,dramatic,draw,drawn,dream,dress,dresses,drew,dried,drill,drink,drive,driven,driver,driving,drop,dropped,drove,drug,drum,drunk,dry,dual,duck,dude,duke,dumb,dump,duplicate,dura,durable,during,dust,dutch,duty,dying,dynamic,each,eagle,ear,earl,earlier,earliest,earn,earring,earth,earthquake,eas,ease,easier,easily,east,eastern,eat,ebon,ebook,echo,eclipse,ecological,ecology,ecommerce,economic,economy,edge,edit,edition,editorial,educated,education,educator,effect,effective,efficiency,efficient,effort,egg,eight,either,eld,elect,election,electric,electro,electron,electronic,elegant,element,elementary,elephant,elevation,eleven,eligible,eliminate,elite,else,elsewhere,emacs,email,embassy,embedded,emerald,emerg,emergency,emirate,emission,emma,emotion,emotional,emperor,emphasis,empire,empirical,employ,employee,empt,enable,enabled,enabling,enclosed,enclosure,encoding,encounter,encourage,encouraged,encryption,end,endanger,endorsed,enemy,energy,engage,engaged,engaging,engine,english,enhance,enhanced,enhancing,enjoy,enlarge,enormous,enough,enquiry,enroll,ensemble,ensure,ensuring,enter,enterprise,entire,entitled,entity,entrance,entry,envelope,enzyme,epic,episode,equal,equation,equip,equipped,equity,equivalent,eric,erotica,err,escape,escort,especial,ess,essay,essential,establish,estate,estimate,estimated,estimation,eternal,ethic,ethical,ethnic,euro,evaluate,evaluated,evaluating,evaluation,even,event,eventual,ever,everybody,everyday,everyone,everything,everywhere,evidence,evident,evil,evolution,ex,exact,exam,examine,examined,examining,example,exceed,excel,excellence,excellent,except,exception,excerpt,excess,excessive,exchange,excite,excited,exciting,exclude,excluded,excluding,exclusion,exclusive,excuse,exec,execute,executed,execution,executive,exempt,exemption,exercise,exhaust,exhibit,exhibition,exist,exit,exotic,expand,expansion,expect,expense,expensive,experience,experiment,expert,expertise,expiration,expire,expired,explain,explicit,explore,explorer,exploring,explosion,expo,export,exposure,express,expression,extend,extension,extensive,extent,exterior,external,extra,extract,extraction,extreme,eye,eyed,fabric,fabulous,face,faced,facial,facilitate,facility,facing,fact,factor,faculty,fail,failure,fair,faith,fake,fall,fallen,false,fame,familiar,family,famous,fan,fancy,fantastic,fantasy,fare,farm,fashion,fast,fatal,fate,father,fatty,fault,favor,favorite,favour,favourite,fe,fear,feat,feature,featured,featuring,federal,federation,fee,feedback,feel,feet,fell,fellow,felt,female,fence,ferry,festival,fetish,fever,few,fib,fibre,fiction,field,fifteen,fifth,fifty,fight,figure,figured,fil,file,filename,fill,film,filter,fin,final,financial,financing,find,fine,finger,finish,finite,fir,fire,fireplace,firewall,firm,firmware,first,fiscal,fish,fisher,fist,fit,fitt,five,fix,fixes,fixture,flag,flame,flash,flat,flavor,fleece,fleet,flesh,flex,flight,flip,float,flood,floor,floppy,flor,floral,flour,flow,fluid,flush,flux,fly,foam,focal,focus,focuses,fold,folk,follow,font,food,fool,foot,footage,football,footwear,for,forbidden,force,forced,ford,forecast,foreign,forestry,forever,forge,forget,forgot,forgotten,fork,form,format,formation,formatting,formula,fort,forth,fortune,forum,forward,fossil,foster,fought,foul,found,foundation,fountain,four,fourth,fra,fraction,fragrance,frame,framed,framework,framing,franchise,frank,frankfurt,franklin,fraud,free,freedom,freelance,freeware,freeze,freight,french,frequency,frequent,fresh,fridge,friend,frog,from,front,frontier,frontpage,frost,frozen,fruit,fuel,fuji,full,function,fund,funeral,funk,funny,furnish,furniture,furth,fusion,future,fuzz,gadget,gage,gain,galax,gale,gallery,gam,gambling,game,gamma,gang,gap,garage,garbage,garden,garlic,gasoline,gate,gateway,gath,gauge,gave,gay,gazette,gear,geek,gender,gene,genealogy,genera,general,generate,generated,generating,generator,generic,generous,genesis,genetic,geneva,genius,genome,genre,gent,gentle,gentleman,genuine,geographic,geography,geological,geology,geometry,german,get,getting,ghost,giant,gibson,gift,gilbert,girl,girlfriend,give,given,giving,glad,glance,glass,glasses,glen,global,globe,glory,glossary,glove,glow,glucose,gnome,go,goal,goat,god,goe,gold,golden,golf,gone,gonna,good,google,gore,gorgeous,gospel,gossip,gothic,gotta,gotten,gourmet,govern,grab,grace,grad,grade,gradual,graduate,graduated,graduation,graham,grain,gram,grammar,grand,grande,granny,grant,graph,graphic,grateful,gratis,grav,grave,gray,great,greece,greek,green,greenhouse,greet,grew,grey,grid,griffin,grill,grip,grocer,groove,gross,ground,group,grove,grow,grown,growth,gu,guarantee,guaranteed,guard,gues,guestbook,guid,guide,guideline,guild,guilt,guinea,guitar,gulf,gun,guru,guy,habit,habitat,hack,hair,half,hall,halo,hamburg,hammer,han,hand,handbag,handbook,handheld,handle,handled,handling,handmade,hang,happen,happi,happy,harass,harbor,harbour,hard,hardcover,hardware,hardwood,harm,harmful,harmony,harp,harry,hart,harvest,hash,hat,hate,have,haven,having,hawk,hazard,hazardous,head,headline,headphone,headset,heal,health,healthcare,hear,heard,heart,heat,heath,heaven,heavily,heavy,heel,height,held,helicopt,hello,helmet,help,helpful,hence,henry,hepatitis,herald,herb,here,hereby,herein,heritage,hero,heroes,herself,hidden,hide,hierarch,high,highland,highlight,highway,hiking,hill,himself,hint,hire,hired,hiring,hist,historic,history,hit,hitting,ho,hobby,hockey,hold,hole,holiday,holland,hollow,holly,holme,holocaust,home,homeland,homepage,hometown,homework,hon,honda,hone,hong,hood,hook,hop,hope,hopeful,horizon,horizontal,hormone,horn,horrible,horror,horse,hose,hospital,host,hostel,hotel,hottest,hour,house,household,housewares,housewives,housing,however,huge,hull,hum,human,humid,hundred,hung,hungry,hunt,hurricane,hurt,husband,hybrid,hydraulic,hydrogen,hygiene,hypothesis,icon,idea,ideal,ident,identical,identified,identifier,identify,idle,idol,ignore,ignored,ill,illegal,image,imagine,imaging,immediate,immigrant,immune,immunology,impact,impair,imperial,implement,implied,implies,import,important,impose,imposed,impossible,impress,impression,impressive,improv,improve,inbox,incentive,inch,inches,incidence,incident,include,included,including,inclusion,inclusive,income,incoming,incomplete,incorrect,increase,increased,increasing,incredible,incurred,indeed,index,indexes,india,indicate,indicated,indicating,indication,indicator,indices,indie,indigenous,indirect,individual,indoor,induced,induction,industrial,industry,infant,infect,infection,infectious,infinite,inflation,influence,influenced,info,inform,infrared,inherit,initial,initiated,initiative,injection,injured,injury,inkjet,inn,innocent,innovation,innovative,input,inquire,inquiry,insect,insert,insertion,inside,insider,insight,inspect,inspection,inspired,install,instance,instant,instead,institute,instruct,instrument,insula,insulin,insurance,insured,intake,integer,integral,integrate,integrated,integrity,intel,intend,intense,intensity,intensive,intent,intention,inter,interact,interface,interim,interior,intern,internal,internet,interstate,interval,interview,intimate,into,intranet,intro,introduce,introduced,invalid,invasion,invention,inventor,invest,invisible,invitation,invite,invited,invoice,involve,involved,involving,iron,irrigation,island,isle,isolated,isolation,issue,issued,ita,italic,item,itself,ivory,jack,jacket,jade,jaguar,jail,jake,james,jane,japan,java,jazz,jean,jeep,jeff,jenny,jerry,jersey,jesse,jesus,jet,jew,jewel,jeweller,jewelry,jill,jimmy,job,john,johnny,johnson,join,joint,joke,jones,jordan,joseph,josh,journal,journalism,journey,jud,judge,judgment,judicial,juice,jump,junction,jungle,junior,junk,jury,just,justice,justify,juvenile,karaoke,karma,keen,keep,kell,keno,kent,kept,kernel,kerry,key,keyboard,keyword,kick,kid,kidney,kill,kilometer,kinase,kind,kinda,king,kingdom,kirk,kis,kit,kitchen,kitty,knee,knew,knife,knight,knit,knitting,knive,knock,know,knowledge,known,kyle,lab,label,laboratory,labour,lace,lack,lad,ladder,laden,laid,lake,lamb,lambda,lamp,lance,land,landscape,lane,lang,language,laptop,large,larger,largest,las,last,lat,late,latex,latina,latino,latitude,latter,laugh,launch,launches,laundry,laura,law,lawn,lawsuit,lawyer,lay,layout,lazy,lead,leader,leaf,league,lean,learn,leas,lease,least,leather,leave,leaving,lecture,leed,left,leg,legacy,legal,legend,legendary,legitimate,leisure,lemon,lend,length,lens,lense,leone,les,lesbian,lesson,let,letter,letting,lev,level,lewis,liability,liable,lib,liberal,liberty,librarian,library,licence,license,licensed,licensing,lick,lie,life,lifestyle,lifetime,lift,light,lightning,like,liked,likelihood,likewise,lime,limit,limitation,limousine,lin,line,linear,lingerie,link,linux,lion,lip,liquid,list,listen,lite,literacy,literal,literary,literature,litigation,little,live,lived,liver,livestock,living,load,loan,lobby,loca,local,locale,locate,located,locator,lock,lodge,lodging,log,logan,logged,logging,logic,login,logistic,logo,lone,long,longitude,look,lookup,loop,loose,lord,los,lose,losses,lost,lot,lotter,lotus,loud,louis,lounge,love,loved,lover,loving,low,luck,luggage,luke,lunch,lung,luxury,lying,lyric,machine,machinery,macintosh,macro,mad,made,madison,madonna,magazine,magic,magnet,magnetic,magnitude,maiden,mail,mailman,main,mainland,mainstream,maintain,major,mak,make,makeup,male,mali,mall,mambo,man,manage,managed,manager,managing,manchester,mandate,mandator,manga,manhattan,manner,manual,map,maple,mapping,mar,marathon,marble,marc,march,margin,maria,marijuana,marina,marine,maritime,mark,market,marri,marriage,marsh,marshall,mart,martial,martin,marvel,mas,mask,mason,massage,massive,mast,mat,match,matches,mate,material,maternity,math,matrix,matt,mattress,mature,maximize,maximum,may,maybe,meal,mean,meaningful,meant,meanwhile,measure,measured,measuring,meat,mechanic,mechanical,mechanism,med,medal,media,medicaid,medical,medicare,medication,medicine,medieval,meditation,medium,meet,mega,member,membrane,memo,memorial,memory,men,ment,menu,merc,merchant,mercury,mere,merge,merger,merit,merry,mes,mesa,mesh,message,messaging,messenger,met,meta,metabolism,metadata,metal,metallic,method,metre,metric,metro,mice,michael,michigan,micro,microphone,microwave,middle,midi,midland,midnight,might,migration,mike,mild,mile,mileage,militar,milk,mill,millennium,million,mime,mind,mine,mineral,mini,miniature,minimal,minimize,minimum,mining,minister,ministry,minor,mint,minus,minute,miracle,mirror,mis,missile,mission,mistake,mistress,mix,mixture,mo,mobile,mobility,mod,mode,model,modelling,modem,moderate,moderator,modern,modified,modify,modular,module,moisture,mold,molecular,molecule,mom,momentum,monetary,money,monitor,monkey,mono,monster,monte,month,montre,mood,moon,moral,more,moreover,morgan,morn,morocco,morris,mortal,mortgage,mos,mose,most,mot,motel,moth,motivated,motivation,motorcycle,mount,mountain,mouse,mouth,move,moved,mover,movie,moving,much,multimedia,multiple,municipal,murder,murphy,murra,muscle,museum,music,must,mustang,mutual,myrtle,myself,myspace,mysterious,mystery,myth,na,nail,naked,nam,name,nancy,nano,narrative,narrow,nasty,nationwide,native,natural,nature,naught,nav,naval,navigate,navigation,navigator,ne,near,nearby,necessary,necessity,neck,necklace,needle,negative,neighbor,neither,nelson,neon,nep,nerve,nervous,nest,network,neural,neutral,never,new,newbie,newsletter,newspaper,newton,next,niagara,nice,nick,nickel,nickname,niger,night,nightlife,nightmare,nine,nirvana,nitrogen,no,noble,nobody,node,noise,nomina,nominated,none,nonprofit,noon,norm,norman,north,northeast,northern,northwest,nose,not,note,notebook,nothing,notice,noticed,notified,notify,nova,novel,novelty,november,nowhere,nuclear,nudist,nuke,null,numb,numeric,numerous,nurs,nurse,nurser,nut,nutrition,nylon,oak,oasis,obes,obituaries,object,objective,obligation,observe,observed,observer,obtain,obvious,occasion,occupation,occupied,occur,occurred,occurrence,occurring,ocean,odd,off,offense,offensive,office,officer,official,offline,offset,offshore,often,oil,oka,old,olive,oliver,omega,omission,on,once,one,ongoing,onion,online,onto,oop,op,open,opera,operate,operated,operating,operator,opinion,opponent,oppos,opposite,opposition,optic,optical,optimal,optimize,optimum,oracle,oral,orange,orbit,orchestra,ord,ordinance,ordinar,organ,organic,organised,organism,organize,organized,organizer,organizing,orient,oriental,origin,orleans,oscar,other,otherwise,ought,our,ourselves,out,outcome,outdo,outlet,outline,outlined,outlook,output,outreach,outside,oval,oven,over,overall,overcome,overhead,overnight,oversea,overview,own,owner,oxford,oxide,oxygen,ozone,pace,pacific,pack,package,packaging,packet,pad,page,paid,pain,painful,paint,paintball,pair,palace,pale,palm,panama,panel,panic,pant,pantyhose,pap,paperback,para,parade,paradise,paragraph,parallel,parameter,parcel,parent,paris,parish,park,parliament,part,parti,partial,particle,particular,partner,pas,passage,passe,passenger,passion,passive,passport,password,past,pasta,paste,patch,patches,patent,path,pathology,patient,patio,patrick,patrol,pattern,paul,pavilion,pay,payable,payday,payroll,pe,pea,peace,peaceful,peak,pearl,pediatric,pee,pen,penalty,pencil,pend,pendant,penguin,peninsula,penny,pension,people,pepper,perceived,percent,percentage,perception,perfect,perform,perfume,perhaps,period,periodic,peripheral,permalink,permanent,permission,permit,permitted,perry,persistent,person,personnel,pest,pet,petite,petition,petroleum,phantom,pharmacy,phase,phenomenon,philosophy,phoenix,phone,photo,photograph,photoshop,phrase,physic,physical,physiology,piano,pic,pick,pickup,picnic,picture,piece,pierce,pike,pill,pillow,pilot,pin,pine,ping,pink,pioneer,pipe,pipeline,pirate,pitch,pixel,pizza,place,placed,placing,plain,plaintiff,plan,plane,planet,planned,planner,planning,plant,plasma,plastic,plate,platform,platinum,play,playback,playlist,plaza,pleas,pleasant,please,pleasure,pledge,plenty,plot,plu,plug,plumb,po,pocket,podcast,poem,poet,poetry,point,poison,poker,polar,pole,police,policy,polish,politic,political,poll,pollution,polo,polymer,polyphonic,pond,pool,pope,popular,population,porcelain,pork,port,portfolio,portion,portland,portrait,pos,pose,position,positive,posses,possession,possible,possibly,post,postage,postcard,potato,potatoes,potential,pott,potter,poultry,pound,pour,poverty,pow,powder,powerful,practical,practice,prairie,praise,pray,preceding,precious,precise,precision,predict,prediction,prefer,preferred,prefix,pregnancy,pregnant,premier,premiere,premise,premium,prep,prepaid,prepare,prepared,preparing,prescribed,presence,present,preserve,president,press,pressure,pretty,prevent,prevention,preview,previous,price,priced,pricing,pride,priest,primarily,primary,prime,prince,principal,principle,print,prior,prison,privacy,private,privilege,prize,pro,probably,probe,problem,procedure,proceed,process,processes,produce,produced,producer,producing,product,production,productive,profess,profession,profile,profit,program,programme,programmer,progress,prohibit,project,projection,prominent,promise,promised,promising,promo,promote,promoted,promoting,prompt,proof,prop,property,prophet,proportion,proposal,propose,proposed,prospect,prostate,protect,protection,protective,protein,protocol,prototype,proud,prove,proved,proven,provide,provided,providence,provider,providing,province,provincial,provision,proxy,psychiatry,psychology,pub,public,publish,pull,pulse,pump,punch,punish,punk,pupil,puppy,purchase,purchased,purchasing,pure,purple,purpose,purse,pursuant,pursue,pursuit,push,put,putt,puzzle,python,quad,qualified,qualify,quality,quant,quantum,quart,quebec,queen,query,quest,question,queue,quick,quiet,quilt,quit,quite,quiz,quizzes,quotation,quote,quoted,rabbit,race,racial,racing,rack,radar,radiation,radical,radio,radius,rage,raid,rail,railroad,railway,rain,rainbow,rais,raise,rally,ralph,ranch,rand,random,rang,range,rank,rapid,rare,rat,rate,rath,ratio,rational,ray,re,reach,reaches,reaction,read,readily,real,realize,realized,realm,realtor,realty,rear,reason,reasonably,rebate,rebel,rebound,recall,receipt,receive,received,receiver,receiving,recent,recept,reception,recipe,recipient,recognised,recognize,recognized,recommend,record,recover,recreation,recruit,recycling,redeem,redhead,reduce,reduced,reducing,reduction,reef,reel,ref,refer,referenced,referral,referred,referring,refinance,refine,refined,reflect,reflection,reform,refresh,refugee,refund,refuse,refused,regard,reggae,regime,region,register,registrar,registry,regression,regula,regular,regulated,regulator,rehab,reject,relate,related,relating,relation,relative,relax,relaxation,relay,release,released,relevance,relevant,reliable,reliance,relief,religion,religious,reload,relocation,remain,remainder,remark,remedy,remember,remind,remix,remote,removable,removal,remove,removed,removing,rend,renew,reno,rent,rep,repair,repeat,replace,replaced,replacing,replica,replied,report,repositor,represent,reprint,reproduce,reproduced,republic,republican,reputation,request,require,required,requiring,res,rescue,research,resell,reserve,reserved,reservoir,reset,resid,resident,resistant,resolution,resolve,resolved,resort,resource,respect,respective,respond,respondent,response,rest,restaurant,restore,restrict,result,resume,retail,retain,retention,retire,retired,retreat,retrieval,retrieve,retrieved,retro,return,reunion,reveal,revelation,revenge,revenue,reverse,review,revised,revision,revolution,reward,rhythm,ribbon,rice,rich,rick,rid,ride,ridge,right,ring,ringtone,ripe,rise,rising,risk,river,riverside,road,robin,robot,robust,rock,rocket,roger,role,roll,rom,roman,romantic,roof,room,roommate,root,rope,rose,rost,rota,rotary,rouge,rough,roulette,round,rout,route,routine,rover,row,royal,royalty,rub,rubber,rug,rugby,rule,ruled,ruling,run,runner,running,rural,rush,russia,ruth,sacred,sacrifice,safari,safe,safer,safety,sage,said,sail,saint,sake,sal,salad,salary,sale,salmon,salon,salt,salvation,samba,same,sample,sampling,san,sand,sandwich,sapphire,satellite,satin,satisfied,satisfy,sauce,sav,savage,savannah,save,say,scale,scan,scanned,scanner,scanning,scar,scenario,scene,scenic,schedule,scheduled,scheduling,schema,scheme,scholar,school,science,scient,scientific,scoop,scope,score,scored,scoring,scotia,scout,scratch,screen,screenshot,screw,script,scroll,scuba,sculpture,sea,seafood,seal,sean,search,searches,season,seat,sec,second,secondary,secret,secretary,sect,secure,secured,security,see,seed,seek,seem,seen,seg,select,selection,selective,self,sell,semester,semi,seminar,senate,senator,send,senior,sens,sense,sensitive,sent,separate,separated,separation,sept,sequence,ser,serial,serious,serum,serve,served,server,service,serving,session,set,sett,settle,settled,setup,seven,seventh,several,severe,sew,sexual,sh,shade,shadow,shaft,shake,shall,shame,shanghai,shape,shaped,share,shared,shareware,sharing,shark,sharon,sharp,shaved,shaw,she,sheep,sheet,shelf,shell,shelter,shepherd,sheriff,shield,shift,shine,ship,shipped,shipping,shirt,shock,shoe,shoot,shop,shopper,shopping,shore,short,shortcut,shot,should,show,showcase,shown,showtime,shut,shuttle,sick,side,siemens,sierra,sight,sigma,sign,signature,silence,silent,silicon,silk,sill,silver,sim,similar,simp,simple,simplified,simulation,since,sing,single,sink,sist,site,sitting,situated,situation,sixth,size,sized,skat,ski,skill,skin,skip,skirt,slave,sleep,sleeve,slide,slideshow,slight,slim,slip,slope,slot,slow,small,smart,smell,smile,smilies,smith,smoke,smoking,smooth,snake,snap,snapshot,snow,snowboard,soap,soccer,social,society,sociology,sock,socket,sodium,sofa,soft,softball,software,soil,solar,sold,soldi,sole,solid,solo,solution,solve,solved,solving,soma,some,somebody,somehow,someone,somerset,something,sometime,somewhat,somewhere,son,song,sonic,soon,sorry,sort,sought,soul,sound,soundtrack,soup,source,south,southeast,southern,southwest,soviet,spa,space,spain,spam,span,spank,spare,spatial,speak,spear,spec,special,specialty,specific,specified,specify,spectrum,speech,speeches,speed,spell,spencer,spend,spent,sperm,sphere,spice,spider,spie,spin,spine,spirit,spiritual,split,spoke,spoken,spokesman,sponsor,sport,spot,spotlight,spouse,spray,spread,spring,sprint,spyware,squad,square,stability,stable,stack,stadium,staff,stage,stain,stake,stamp,stand,standard,star,starr,start,startup,stat,state,statewide,static,station,stationer,statistic,status,statute,statutory,stay,stead,steal,steam,steel,steer,stem,step,stereo,sterling,steven,stick,still,stock,stolen,stomach,stone,stood,stop,stopped,stopping,storage,store,stored,storm,story,straight,strain,strand,strang,strange,strap,strategic,strategy,stream,street,strength,strengthen,stress,stretch,strict,strike,striking,string,strip,stripe,stroke,strong,struck,structural,structure,structured,struggle,stuck,stud,student,studied,studio,stuff,stunning,stupid,style,stylish,stylus,subject,subjective,sublime,submission,submit,submitted,submitting,subscribe,subscriber,subsection,subsequent,subsidiary,substance,substitute,subtle,suburban,succeed,succes,successful,such,suck,sudden,suffer,sufficient,sugar,suggest,suggestion,suicide,suit,suite,summar,summer,summit,sunglasses,sunn,sunrise,sunset,sunshine,sup,superb,superior,supervisor,supple,supplied,supplier,supply,support,suppose,supposed,supreme,sure,surf,surface,surge,surgeon,surger,surgical,surname,surplus,surprise,surprised,surprising,surrey,surround,survey,survival,survive,survivor,suspect,suspend,suspension,sustain,swap,sweet,swift,swim,swimming,swing,swiss,switch,switches,sword,symbol,sympathy,symphony,symposium,symptom,sync,syndicate,syndrome,synopsis,syntax,synthesis,synthetic,system,systematic,tab,table,tablet,tackle,tactic,tag,tagged,tail,tak,take,taken,tale,talent,talk,tall,tank,tape,target,tariff,task,taste,tattoo,taught,taxa,taxes,taxi,teach,teaches,team,tear,tech,technic,technical,technique,techno,technology,teddy,teen,teenage,teeth,telecom,telephone,telephony,telescope,television,tell,temp,template,temple,temporary,tenant,tend,tennis,tension,tent,term,terminal,terrace,terrain,terrible,territory,terror,terrorism,terry,test,testa,testimony,texas,text,textbook,textile,texture,than,thank,that,the,theater,theatre,thee,theft,their,them,theme,themselves,then,theolog,theorem,theory,therapist,therapy,there,thereafter,thereby,therefore,thereof,thermal,thesaurus,these,thesis,theta,thick,thin,thing,think,third,thirty,this,thong,thorough,those,thou,though,thought,thousand,thread,threat,threaten,three,threshold,thrill,throat,through,throughout,throw,thrown,thru,thumb,thumbnail,thunder,thus,ti,ticket,tide,tie,tiffany,tig,tight,tile,till,timber,time,timeline,timer,timing,timothy,tin,tip,tire,tired,tissue,titan,titanium,title,titled,tobacco,today,toddler,together,toilet,token,told,tolerance,toll,tomato,tomatoes,tommy,tomorrow,ton,tone,tongue,tonight,took,tool,toolbar,toolbox,toolkit,tooth,top,topic,torture,total,touch,tough,tour,tourism,tournament,tow,toward,town,toxic,toy,trace,track,tract,trad,trade,trademark,tradition,traffic,tragedy,trail,train,trance,trans,transcript,transexual,transfer,transform,transit,transition,translate,translated,translator,transmit,transport,trap,trash,trauma,travel,traveller,travelling,travis,tray,treasure,treasurer,treasury,treat,tree,trek,tremendous,trend,trial,triangle,tribal,tribe,tribunal,tribune,tribute,trick,trie,tried,trigger,trim,trin,trio,trip,triple,triumph,trivia,troop,tropical,trouble,trout,troy,truck,true,truly,trunk,trust,trustee,truth,try,tsunami,tube,tui,tum,tun,tune,tunnel,turbo,turkey,turn,turtle,tutorial,twelve,twenty,twice,twin,twist,tyler,type,typical,typing,ug,ultimate,ultra,un,unable,uncle,undefined,under,understand,understood,undertake,undertaken,underwear,undo,unexpected,unified,uniform,union,unique,unit,universe,unknown,unlike,unlimited,unlock,unsigned,until,untitled,unto,unusual,unwrap,upcoming,update,updated,updating,upgrade,upgrading,upload,upon,upper,upset,urban,urge,urgent,us,usage,use,useful,username,usual,utility,utilize,vacancies,vacation,vaccine,vacuum,valentine,valid,validation,valium,valley,valuable,valuation,value,valued,valve,vampire,vanilla,var,varia,variable,variance,varied,variety,various,vast,vault,vector,vega,vegetable,vegetarian,vegetation,vehicle,velocity,velvet,vend,venture,venue,verbal,verified,verify,verse,version,versus,vertex,vertical,very,vessel,veteran,veterinary,vice,victim,victor,victoria,vid,video,vienna,view,viking,villa,village,vintage,vinyl,viol,viola,violent,violin,viral,virgin,virginia,virtual,virtue,virus,viruses,visa,visibility,visible,vision,visit,vista,visual,vital,vitamin,vocabular,vocal,vocational,voice,void,voip,volleyball,volt,voltage,volume,voluntary,volunteer,vote,voted,voter,voting,vulnerable,wage,wagon,wait,waiver,wake,wale,walk,wall,wallet,wallpaper,walnut,wanna,want,war,warcraft,ward,ware,warehouse,warm,warn,warrant,warren,warrior,wash,waste,wat,watch,watches,waterproof,watershed,watt,wave,way,we,weak,wealth,weapon,wear,weather,webcam,webcast,weblog,webmaster,webpage,website,webster,wedding,week,weekend,weight,weird,welcome,weld,welfare,well,wellington,welsh,went,were,west,western,whale,what,whatever,wheat,wheel,when,whenever,where,whereas,wherever,whether,which,while,whilst,white,whole,wholesale,whom,whose,wick,wide,wider,widescreen,widespread,width,wife,wiki,wild,wildlife,will,william,willow,win,wind,window,wine,wing,winn,winter,wire,wired,wiring,wisdom,wise,wish,wishes,wit,witch,with,withdrawal,within,without,witnesses,wive,wizard,wolf,woman,women,wonder,wonderful,wood,wooden,wool,worcester,word,work,workflow,workforce,workout,workplace,workshop,world,worldwide,worm,worn,worried,worry,worse,worship,worst,worth,would,wound,wrap,wrapped,wrapping,wrestling,wright,wrist,writ,write,written,wrong,wrote,xerox,yacht,yahoo,yale,yang,yard,yarn,yeah,year,yeast,yellow,yesterday,yield,yoga,york,young,your,yourself,youth,zero,zinc,zone,zoning,zoom"
