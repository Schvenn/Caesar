# Caesar
A basic text obfuscation tool designed for Red Team testing, with some practical end-user functionality in mind.

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
In order to see the function in action, the following commands demonstrate the capabilities of the Caesar function.

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
