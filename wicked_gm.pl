#Program by Allegra Van Rossum, released under CC-BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)
#Please review the license before using the code in a new work. It is not the same as the GNU Public License: I use this one because a lot of the packages use creative commons material.
#Keep in mind that the packages also have their own "legal.txt", with their own stipulations, if you use them.

#The purpose of this program is to act as a 'pseudo-AI.' It is by no means a full AI, nor is it a substitute for a human GM.
#However, the hope is that for 1-2 players, it may suffice as a way to game when no GM is available.
#Packages for more game systems may eventually come. For now, Eclipse Phase is used since it's creative commons and I'm more comfortable with that.

#This project was also a way for me to learn Perl, hence why you'll see switches and other weird things going on

#Version 0.1 is just a fancy name generator

use Carp;
use IO::File;
use Params::Util;
use strict;
use warnings;
use Text::CSV-xs;
use Filter::Util::Call;
use Text::Balanced;
use Switch;
use String::Random qw(random_regex random_string);

my $nb_err = 0;

my_main();



sub regexName
{
	my $eval_me = substr($_[0], 1);
	return random_regex(${eval_me});
}

sub generateCharacter
{
	my $pkg_name = $_[0];	
	my $extraname = 0;
	if ($_[1] ne "NOEXTRA")
	{
		$extraname = 1;
	}
	
	
	opendir(my $dh, "${pkg_name}\\names") or die "Can't open /names/!";
	my @cultures = grep {/\.csv$/i && -f "${pkg_name}\\names\\$_"} readdir $dh;
	closedir($dh);
	
	my $char_cult = substr(@cultures[int(rand(scalar @cultures))], 0, -4);
	
	my $name_list = "${pkg_name}\\names\\${char_cult}.csv";
	
	if (int(rand(100)) >= 90) #10% chance of getting a name from another culture
	{
		my $new_name = substr(@cultures[int(rand(scalar @cultures))], 0, -4);
		$name_list = "${pkg_name}\\names\\${new_name}.csv";
	}

	my @names;


	#Using some code under cc-by-sa from https://stackoverflow.com/questions/3065095/how-do-i-efficiently-parse-a-csv-file-in-perl

	open (my $fh, '<', $name_list) or die "Error! Couldn\'t open ${name_list}!\n";

	while (my $line = <$fh>)
	{
		chomp $line;
		my @fields = split(/,/, $line); #csv
		push @names, \@fields;
	}
	
	close ($fh);

	my $columns = scalar @{ $names[0] };
	my $rows = scalar @names;
	
	my $last_n = -1;
	my $male_n = -1;
	my $fem_n = -1;
	my $neu_n = -1;
	my $nb_n = -1;

	#Some code cc-by-sa from https://stackoverflow.com/questions/974656/automatically-get-loop-index-in-foreach-loop-in-perl

	my $index = 0;

	foreach(@{ $names[0]})
	{
		switch($names[0][$index])
		{
			case "ln"	{$last_n = $index;}
			case "f"	{$fem_n = $index;}
			case "m"	{$male_n = $index;}
			case "nb"	{$nb_n = $index;}
			case "n"	{$neu_n = $index;} #This is used for names that any gender can use- depending on the system, this may be different from nb names.
		}
		$index++;
	}

	my $dice_roll = int(rand(100)); 
	#0 - 99. 45% chance male, 45% chance female, 10% chance nb. Eventually, this will be based on the setting- nb is bumped up a bit from 2020 demographics so that I can test it easier
	#A setting like EP, for example, is going to have a higher than average nb population because of ALIs and the changing nature of how transhumanity views bodies, minds, etc.


	my $char_gender = "nb";

	if ($dice_roll < 45)
	{
		$char_gender = "f";
		if ($fem_n == -1 && $neu_n == -1)
		{
			print "No names available for the generated gender and culture (Gender \"${char_gender}\", Culture \"${char_cult}\". If you keep getting this error, add a 'n' column in your names csv.\n";
			exit(); #TODO: Try again 10 times or so on failure
		}
	}
	elsif ($dice_roll < 90)
	{
		$char_gender = "m";
		if ($male_n == -1 && $neu_n == -1)
		{
			print "No names available for the generated gender and culture (Gender \"${char_gender}\", Culture \"${char_cult}\". If you keep getting this error, add a 'n' column in your names csv.\n";
			exit(); #TODO: Try again 10 times or so on failure
		}
	}
	else
	{
		if ($nb_n == -1 && $neu_n == -1 && $male_n == -1 && $fem_n == -1)
		{
			print "This error should only occur if your columns are labeled incorrectly, you have no name columns, or you only have an \"ln\" column. If the setting only uses last names, please label that column as \"n\", not as \"ln\".\n";
			exit(); #This error should quit- if there are no valid name lists, you can't name characters.
		}
		elsif ($nb_n == -1 && $neu_n == -1 && $nb_err == 0)
		{
			print "WARN Generated NB character, but there are no \"nb\" or \"n\" names. Selecting another type at random...\n";
			$nb_err = 1;
		}
	}

	my $char_name;
	my $firstname = '';
	
	
	#If there's a way to condense the following algorithm, let me know. Basically, I want a 90% chance that the first name matches the gender. Then, there's an 8% chance of a neutral name. Finally, a 2% chance of a different-gender name
	#Since none of my test data has a specific "nb" column, and all autonomist names are neutral, currently the "nb" names will randomly select a "male" or "female" name.

	if ($char_gender eq "m")
	{
		#Either male_n OR neu_n exists. 90% chance to have male_n, if it exists
		$dice_roll = int(rand(100));
		if ($dice_roll < 90)
		{
			if ($male_n != -1)
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$male_n];
				}
			}
			else
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$neu_n];
				}
			}
		}
		else
		{
			if ($fem_n != -1 && $dice_roll >= 98)
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$fem_n];
				}
			}
			elsif ($neu_n != -1)
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$neu_n];
				}
			}
			else
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$male_n];
				}
			}
		}
	}
	elsif ($char_gender eq "f")
	{
		#Either fem_n OR neu_n exists. 90% chance to have male_n, if it exists
		$dice_roll = int(rand(100));
		if ($dice_roll < 90)
		{
			if ($fem_n != -1)
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$fem_n];
				}
			}
			else
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$neu_n];
				}
			}
		}
		else
		{
			if ($male_n != -1 && $dice_roll >= 98)
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$male_n];
				}
			}
			elsif ($neu_n != -1)
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$neu_n];
				}
			}
			else
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$fem_n];
				}
			}
		}
	}
	elsif ($char_gender eq "nb")
	{
		$dice_roll = int(rand(100));
		if ($dice_roll < 90)
		{
			if ($nb_n != -1)
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$fem_n];
				}
			}
			elsif ($neu_n != -1)
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$neu_n];
				}
			}
			elsif ($fem_n != -1 && $dice_roll % 2 == 0)
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$fem_n];
				}
			}
			elsif ($male_n != -1)
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$male_n];
				}
			}
			else
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$fem_n];
				}
			}
		}
		else
		{
			if ($male_n != -1 && $dice_roll >= 95)
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$male_n];
				}
			}
			elsif ($fem_n != -1)
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$fem_n];
				}
			}
			elsif ($neu_n != -1)
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$neu_n];
				}
			}
			elsif ($male_n != -1)
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$male_n];
				}
			}
			else
			{
				while ($firstname eq '')
				{
					$firstname = $names[ int(rand($rows - 1) + 1) ][$nb_n];
				}
			}
		}
	}

	if (substr($firstname, 0, 1) eq "_")
	{
		$firstname = regexName($firstname);
	}


	$char_name = $firstname;
	my $lastname = "X";
	if ($last_n != -1)
	{	
		#I have far fewer lastnames than I do firstnames in my test data. All the firstname columns need to be the same length, and they need to be longer than the lastname column. Otherwise, I'll run into issues.
		
		#Let me know if there's an efficient way to count the size of a column, other than iterating through all of its members.
		while (length $lastname <= 1)
		{
			my $rollit = int(rand($rows - 1) + 1);
			if (exists($names[$rollit][$last_n]) && length $names[$rollit][$last_n] > 1)
			{
				$lastname = $names[$rollit][$last_n];
			}
			else
			{
				$lastname = "X";
			}
		}
		if (substr($lastname, 0, 1) eq "_")
		{
			$lastname = regexName($lastname);
		}
			
		
		$char_name = $char_name . " " . $lastname;
	}
	
	
	
	if ($extraname != 0)
	{
		if (int(rand(100)) % 4 > 0 && $last_n != -1)
		{
			$char_name = $firstname . " " . $_[1] . " " . $lastname;
			
		}
		elsif (int(rand(100)) % 2 == 0)
		{
			$char_name = $char_name . " " . $_[1];
		}
		else
		{
			$char_name = $_[1] . " " . $char_name;
		}
	}

	if ($last_n == -1 && $extraname != 1 && int(rand(100)) > (40 + ((length $char_name) * 3))) 
	{
		return generateCharacter($pkg_name, $char_name);
	}
	elsif ($extraname != 1 && int(rand(100)) > (85 + (length $char_name))) #Much smaller chance of a "doubled" name, because otherwise this will get ridiculous
	{
		return generateCharacter($pkg_name, $char_name);
	}
	return "$char_name, $char_cult, $char_gender";

}

sub my_main
{

	print "HOW TO USE THIS PROGRAM\n\n";

	print "Please make sure your package is in the same directory as this file.\n";
	print "The folder should be labeled \"pkg_GAME\", where GAME is the name of the system you are using.\n";
	print "Remember to match the case on input and avoid special characters.\n";
	print "Your input to access this package will be \"GAME\".\n\n";

	print "If you do not have your own package, this program should've come with the Eclipse Phase package.\n";
	print "The EP package is stored under \"pkg_EP\". To use this, you would enter in \"EP\".\n\n";

	print "What package are you using today?\n";


	my $pkg_name = <STDIN>;
	chomp $pkg_name;
	$pkg_name = 'pkg_' . $pkg_name;

	if (-d $pkg_name)
	{
		print "${pkg_name} was found! Make sure to review the legal information in \"legal.txt\".\n";

	}
	elsif (-e $pkg_name)
	{
		print "${pkg_name} exists, but it's a file, not a directory. Please make sure that the package is installed in a folder named ${pkg_name}, and that you keep the original file names of the files within it.\n";
		exit(); #TODO: bring user back to package prompt.
	}
	else
	{
		print "I'm sorry, but we couldn't find ${pkg_name}.\n";
		exit(); #TODO: bring user back to package prompt.
	}

	print "How many characters? (Integers only, please.)\n";
	
	my $char_number = <STDIN>;

	print "Loading package...\n";


	open (my $csv_out, ">", "characters.csv") or die "characters.csv: $!";

	for (1..$char_number)
	{
		my $my_character = generateCharacter($pkg_name, "NOEXTRA");
		print $my_character . "\n";
		say $csv_out $my_character;
		
	}
	
	close $csv_out;
	print "Characters saved to characters.csv\n";
}