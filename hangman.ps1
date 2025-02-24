cls
$wins = 0
$losses = 0

$worddir = "$env:LOCALAPPDATA\Powershell Hangman"
$wordfile = "words_categories.csv"

write-host "Checking for word directory: " -nonewline
sleep -seconds 1

if (!(test-path $worddir)) {
	write-host "Path $worddir not found" -fore yellow
	sleep -seconds 1
	
	write-host "Creating directory: " -nonewline
	sleep -seconds 1
	
	try {
		new-item -itemtype directory -path $worddir -value "Powershell Hangman" | out-null
		write-host "Directory created successfully" -fore green
		sleep -seconds 1
	}
	catch {
		write-host "Error directory creation failed" -fore red
		sleep -seconds 1
	}
	
	write-host "Fetching word list: " -nonewline
	sleep -seconds 1
	
	try {
		invoke-webrequest -uri "https://raw.githubusercontent.com/frodough/PowershellHangman/refs/heads/main/words_categories.csv" -outfile "$worddir\$wordfile"
		write-host "Successfully downloaded word list" -fore green
		sleep -seconds 1
	}
	catch {
		write-host "Error fetching word list." -fore red
		sleep -seconds 1
	}
} else {
	write-host "Successfully found game directory" -fore green
	sleep -seconds 1
	write-host "Checking for word list: " -nonewline
	sleep -seconds 1
	
	if (!(test-path "$worddir\$wordfile")) {
		write-host "Wordlist not found" -fore yellow
		
		try {
			invoke-webrequest -uri "https://raw.githubusercontent.com/frodough/PowershellHangman/refs/heads/main/words_categories.csv" -outfile "$worddir\$wordfile"
			write-host "Successfully downloaded word list" -fore green
			sleep -seconds 1
		}
		catch {
			write-host "Error fetching word list." -fore red
			sleep -seconds 1
		}
	} else {
		write-host "Wordlist successfully found" -fore green
		sleep -seconds 1
	}
}

do {
	$intro = @"
 _                                             
| |__   __ _ _ __   __ _ _ __ ___   __ _ _ __  
| '_ \ / _`  | '_ \ / _`  | '_ ` _  \ / _`  | '_ \ 
| | | | (_| | | | | (_| | | | | | | (_| | | | |
|_| |_|\__,_|_| |_|\__, |_| |_| |_|\__,_|_| |_|
                   |___/                       
"@
    $man = 
@"
  +-----+
  |     |
        |
        |	
        |
        |
===========
"@, 
@"
  +-----+
  |     |
  O     |
        |
        |
        |
===========
"@, 
@"
  +-----+
  |     |
  O     |
  |     |
        |
        |
===========
"@, 
@"
  +-----+
  |     |
  O     |
 /|     |
        |
        |
===========
"@, 
@"
  +-----+
  |     |
  O     |
 /|\    |
        |
        |
===========
"@, 
@"
  +-----+
  |     |
  O     |
 /|\    |
 /      |
        |
===========
"@, 
@"
  +-----+
  |     |
  O     |
 /|\    |
 / \    |
        |
===========
GAME OVER!
"@

	$levels = @{
		"1" = @{ max = 6; minlength = 2; maxlength = 15; words = import-csv "$worddir\$wordfile"; setting = "Easy" }
		"2" = @{ max = 6; minlength = 2; maxlength = 25; words = import-csv "$worddir\$wordfile"; setting = "Normal" }
		"3" = @{ max = 4; minlength = 2; maxlength = 50; words = import-csv "$worddir\$wordfile"; setting = "Hard" }
	}

	do {
		cls
		write-host $intro
		write-host "`n1: Easy`n2: Normal`n3: Hard"
		$difficulty = read-host "`nPick a difficulty"
	} 
	until ($levels.containskey($difficulty))
	
	$wordhash = @{}
	
	foreach ($entry in $levels[$difficulty]["words"]) {
		$category = $entry.category
		$word = ($entry.word).tolower()
		$wordhash[$category] += "$word,"
	}
	
	$randomcat = $wordhash.keys | get-random
	$randomwrd = ($wordhash[$randomcat]).trimend(",")
	$randomwrd = $randomwrd.split(",")
	
	$max = $levels[$difficulty]["max"]
	
	$wlist = $randomwrd | ? { $_.length -ge $levels[$difficulty]["minlength"] -and $_.length -le $levels[$difficulty]["maxlength"] }
	$word = $wlist | get-random
	$warray = $word.tochararray()
	$dword = @("_") * $warray.length
	$char = @()
	$attempts = 0
    $message = ""

	while ($dword -join "" -ne $word -and $attempts -lt $max) {
        cls
		write-host "$($intro)"
        write-host ("=" * 47) -fore cyan
        write-host "   Wins: $($wins)   Losses: $($losses)   Turns Remaining: $($max - $attempts)" -fore cyan
        write-host ("=" * 47) -fore cyan
        
		if ($warray -contains " ") {
			for ($i = 0; $i -lt $warray.length; $i++) {
				if ($warray[$i] -match " ") {
					$dword[$i] = " "
				}
			}
		}
		
		write-host "`n$($man[$attempts])"
		write-host "Difficulity: $($levels[$difficulty]["setting"])"
		write-host "Category: $($randomcat)"
		write-host "`nWord: $($dword -join " ")"
		write-host "Guessed: $($char -join ", ")"
		write-host $message
	
		$guess = read-host "Enter a letter"
        write-host
    	
		if (!($guess -match "^[a-z]$")) {
			$message = "Invalid input. Enter a valid character."
		} else {
        	if ($char -contains $guess) {
            	$message = "You already guessed that letter!"
        	} else {
                $message = ""
            	$char += $guess.tolower()

		    	if ($warray -contains $guess) {
			    	for ($i = 0; $i -lt $warray.length; $i++) {
				    	if ($warray[$i] -eq $guess) {
					    	$dword[$i] = $guess.tolower()
				    	}
			    	}
		    	} else {
			    	$attempts++
	        	}
        	}
    	}
	}

	if ($attempts -eq $max) {
        $losses++
		cls
		write-host "$($intro)"
        write-host ("=" * 47) -fore cyan
        write-host "   Wins: $($wins)   Losses: $($losses)   Turns Remaining: $($max - $attempts)" -fore cyan
        write-host ("=" * 47) -fore cyan
		write-host "`n$($man[6])"
		write-host "Difficulity: $($levels[$difficulty]["setting"])"
		write-host "`nWord: $($word)"
    	write-host "Nice try but the word was $($word), if your not too scared try again!"
		$again = read-host "`nPlay again?"
	} else {
        $wins++
		cls
		write-host "$($intro)"
        write-host ("=" * 47) -fore cyan
        write-host "   Wins: $($wins)   Losses: $($losses)   Turns Remaining: $($max - $attempts)" -fore cyan
        write-host ("=" * 47) -fore cyan
		write-host "`n$($man[$attempts])"
		write-host "Difficulity: $($levels[$difficulty]["setting"])"
		write-host "`nWord: $($word)"
    	write-host "Congrats on guessing the word $($word)! You must be a superstar or the word was something a baby could guess!"
		$again = read-host "`nPlay again?"
	}
} 

until ($again -eq "n")
