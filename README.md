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

This tool was not developed to create some next generation encryption methodology that cannot be broken by a myriad of quantum computers. It was designed as a proof of concept for Red Team testing and to create a simple obfuscation tool, with practical end user application in mind.

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

	• Create a sample file with a broken header for the
		$string = "Çæšª®Q?l3-µkvdobxkdo~oxmbizd~wo"; $file="file.broken"; Out-File -FilePath $file -InputObject $string demonstration.
	• Decrypt a file with a broken header to screen.
		caesar "file.broken" 10 -undo
	• Decrypt a file with a broken header to disk and view the file.
		caesar "file.broken" 10 "file.fixed.undo" -undo; gc file.fixed.undo
	• Remove demonstration files.
		del file.fixed.undo; del file.broken

## Brute Force Demonstrations

	• Create a successful sample file for the brute force
		caesar "Gaius Julius Caesar was a Roman ruler and his salads taste really good, too." 712100 "caesar.born" demonstration.
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

	function c {param([string]$s,[int]$sh=1,[string]$o,[switch]$u,[switch]$nh);$sc={param($c,$sh)$cd=[int][char]$c;if($cd-ge 65-and $cd-le 90){[char]((($cd-65+$sh+26)%26)+65)}elseif($cd-ge 97-and $cd-le 122){[char]((($cd-97+$sh+26)%26)+97)}else{$c}};$rs={param($l)$cs=([char[]](33..126|?{$_-notin 172,173,188,189,190}))-join '';-join(1..$l|%{$cs[(Get-Random -Maximum $cs.Length)]})};$t=(Test-Path $s)?(Get-Content $s -Raw):$s;$f=Test-Path $s;$fn=[IO.Path]::GetFileName($s);if($u){if($t-match"^çæšª®.{10}\d{3}(\d{2}).{10}([^\¼½¾µ°¬]{5,})(?=.{10}µ)"){$sh=-[int]$matches[1];$fn2=($matches[2].ToCharArray()|%{&$sc $_ $sh})-join'';$t=$t-replace"^çæšª®.{10}\d{3}\d{2}.{10}.+?µ",""}else{$t=$t-replace"^ç.+µ",'';$t=$t-replace"^.+µ",'';$sh=-$sh}};$t=$t-replace" ","~";$t=$t-replace"`r","°"-replace"`n","¬";$t=[regex]::Replace($t,"°¬°¬",{"°¬"+("¼","½","¾"|Get-Random)+(&$rs (Get-Random -Minimum 40 -Maximum 1000))+"°¬"});$o2=($t.ToCharArray()|%{&$sc $_ $sh}) -join'';if($u){$o2=$o2-replace"°¬[¼½¾].+?°¬","°¬°¬";$o2=$o2-replace"~"," ";$o2=$o2-replace"°¬","`r`n"};if(-not $u-and -not $nh -and $f){$ss=$sh.ToString("00");$h="çæšª®"+(&$rs 10)+(Get-Random -Minimum 100 -Maximum 999).ToString()+$ss+(&$rs 10);$fn2=(($fn+".undo").ToCharArray()|%{&$sc $_ $sh}) -join'';$h+=$fn2+(&$rs 10)+"µ";$o2=$h+$o2};if($o){$fn2=$o};if($fn2){$o2.TrimEnd("`r","`n")|Out-File $fn2 -Encoding utf8 -nonewline}}

I am not adding it separately, because I don't want to encourage abuse, which can happen even with a script as limited as this one. However, since it is still an effective obfuscation tool for Red Team activities, by still including it here, I can at least create some limited security through obscurity.
