#Program by Allegra Van Rossum, released under GNU General Public License version 3.0. Included Packages have their own licenses- please read "legal.txt" before using a package.
#Please review the license before using the code in a new work. It is not the same as the GNU Public License: I use this one because a lot of the packages use creative commons material.
#Keep in mind that the packages also have their own "legal.txt", with their own stipulations, if you use them.

#The purpose of this program is to act as a 'pseudo-AI.' It is by no means a full AI, nor is it a substitute for a human GM.
#However, the hope is that for 1-2 players, it may suffice as a way to game when no GM is available.
#Packages for more game systems may eventually come.

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
use Array::Transpose; #QOL for reading


my $nb_err = 0;

my_main(); #Go all the way to the bottom for this function



sub regexName
{
	my $eval_me = substr($_[0], 1);
	return random_regex(${eval_me});
}

sub generatePersonality
{
	# 0: pkg_name, 1: NPC-0 or PC-1; 2: Culture-string;
	# Should be passed in by generateCharacter. Otherwise, default is NPC, and Culture is selected at random.
	
	my @char_motivations;
	my @char_cultures; #Unlikely, but possible (2% chance) to have more than one
	my @char_factions; #Unlikely, but possible (5% chance) to have more than one. The first one is their "current" faction, others are past factions that may affect their motivations
	my @char_roles; #Unlikely, but possible (2% chance) to have more than one
	
	my $pkg_name = $_[0];
	
	opendir(my $dh_1, "${pkg_name}\\motivations\\cultures") or die "Can't open /motivations/cultures!";
	my @all_cultures = grep {/\.csv$/i && -f "${pkg_name}\\motivations\\cultures\\$_"} readdir $dh_1;
	closedir($dh_1);
	
	opendir(my $dh_2, "${pkg_name}\\motivations\\factions") or die "Can't open /motivations/factions!";
	my @all_factions = grep {/\.csv$/i && -f "${pkg_name}\\motivations\\factions\\$_"} readdir $dh_2;
	closedir($dh_2);
	
	opendir(my $dh_3, "${pkg_name}\\motivations\\roles") or die "Can't open /motivations/roles!";
	my @all_roles = grep {/\.csv$/i && -f "${pkg_name}\\motivations\\roles\\$_"} readdir $dh_3;
	closedir($dh_3);
	
	for my $i (0..(scalar @all_cultures - 1))
	{
		$all_cultures[$i] = substr($all_cultures[$i],0,-4);
	}
	for my $i (0..(scalar @all_factions - 1))
	{
		$all_factions[$i] = substr($all_factions[$i],0,-4);
	}
	for my $i (0..(scalar @all_roles - 1))
	{
		$all_roles[$i] = substr($all_roles[$i],0,-4);
	}
		
	
	my $char_type = 0;
	#0 is NPC, 1 is PC. Avoids having PCs with a goal of "DESTROY THE UNIVERSE" or "EXTERMINATE HUMANITY."
	#For evil or nonstandard PCs, simply remove "NPCONLY" from the .csv with the personalities you want to include.
	
	if (exists($_[1]))
	{
		$char_type = $_[1];
	}
	
	if (exists($_[2]))
	{
		#check to make sure chosen culture is also in motivations/cultures. If it's not, select a culture at random
		#this is used in cases where name cultures differ from motivation cultures
		my %culture_check = map { $_ => 1 } @all_cultures;
		if (exists($culture_check{$_[2]}) && int(rand(100)) < 95) #5% chance to get something else anyways. It should help a little for cultures that don't have name lists. 
		{
			push @char_cultures, $_[2];
		}
		else
		{
			push @char_cultures, @all_cultures[int(rand(scalar @all_cultures))];
		}
	}
	else
	{
		#select a culture at random from motivations/cultures
		push @char_cultures, @all_cultures[int(rand(scalar @all_cultures))];
	}
	
	#chance to have additional cultures
	
	#grep used from here: https://stackoverflow.com/questions/2860226/how-can-i-check-if-a-perl-array-contains-a-particular-value
	
	while (int(rand(100)) < 2)
	{
		my $count = 0;
		my $extra_culture = @all_cultures[int(rand(scalar @all_cultures))];
		
		my %cult_check = map { $_ => 1 } @char_cultures;
		while (exists($cult_check{$extra_culture}) && $count < 5)
		{
			$extra_culture = @all_cultures[int(rand(scalar @all_cultures))];
			$count++;
		}
		if ($count < 5)
		{
			push @char_cultures, $extra_culture;
		}
	}
	
	
	#push faction
	push @char_factions, @all_factions[int(rand(scalar @all_factions))];
	
	#chance to have additional factions
	while (int(rand(100)) < 5)
	{
		my $count = 0;
		my $extra_faction = @all_factions[int(rand(scalar @all_factions))];
		
		my %faction_check = map { $_ => 1 } @char_factions;
		while (exists($faction_check{$extra_faction}) && $count < 5)
		{
			$extra_faction = @all_factions[int(rand(scalar @all_factions))];
			$count++;
		}
		if ($count < 5)
		{
			push @char_factions, $extra_faction;
		}
	}
	
	#push role
	push @char_roles, @all_roles[int(rand(scalar @all_roles))];
	
	#chance to have additional roles
	while (int(rand(100)) < 2)
	{
		my $count = 0;
		my $extra_role = @all_roles[int(rand(scalar @all_roles))];
		
		my %role_check = map { $_ => 1 } @char_roles;
		while (exists($role_check{$extra_role}) && $count < 5)
		{
			$extra_role = @all_roles[int(rand(scalar @all_roles))];
			$count++;
		}
		if ($count < 5)
		{
			push @char_roles, $extra_role;
		}
	}
	
	
	#motivations
	
	my @pos_motivations;
	my @neg_motivations;
	#Load in potential motivations
	for my $i (0..(scalar @char_factions - 1))
	{
		my $motivation_list = "${pkg_name}\\motivations\\factions\\$char_factions[$i].csv";
		open (my $fh, '<', $motivation_list) or die "Error! Couldn\'t open ${motivation_list}!\n";
		my $dummy = <$fh>; #skip header
		while (my $line = <$fh>)
		{
			chomp $line;
			my @fields = split(/,/, $line); #csv
			
			if (exists($fields[0]))
			{
				push @pos_motivations, $fields[0];
			}
			
			if (exists($fields[1]))
			{
				push @neg_motivations, $fields[1];
			}
		}
		
		close ($fh);
	}
	
	for my $i (0..(scalar @char_cultures - 1))
	{
		my $motivation_list = "${pkg_name}\\motivations\\cultures\\$char_cultures[$i].csv";
		open (my $fh, '<', $motivation_list) or die "Error! Couldn\'t open ${motivation_list}!\n";
		my $dummy = <$fh>; #skip header
		while (my $line = <$fh>)
		{
			chomp $line;
			my @fields = split(/,/, $line); #csv
			
			if (exists($fields[0]))
			{
				push @pos_motivations, $fields[0];
			}
			
			if (exists($fields[1]))
			{
				push @neg_motivations, $fields[1];
			}
		}
		
		close ($fh);
	}
	
	for my $i (0..(scalar @char_roles - 1))
	{
		my $motivation_list = "${pkg_name}\\motivations\\roles\\$char_roles[$i].csv";
		open (my $fh, '<', $motivation_list) or die "Error! Couldn\'t open ${motivation_list}!\n";
		my $dummy = <$fh>; #skip header
		while (my $line = <$fh>)
		{
			chomp $line;
			my @fields = split(/,/, $line); #csv
			
			if (exists($fields[0]))
			{
				push @pos_motivations, $fields[0];
			}
			
			if (exists($fields[1]))
			{
				push @neg_motivations, $fields[1];
			}
		}
		
		close ($fh);
	}
	
	#load generic
	my $dummy_var = 0;
	while($dummy_var ==0)
	{
		my $motivation_list = "${pkg_name}\\motivations\\generic.csv";
		open (my $fh, '<', $motivation_list) or die "Error! Couldn\'t open ${motivation_list}!\n";
		my $dummy = <$fh>; #skip header
		while (my $line = <$fh>)
		{
			chomp $line;
			my @fields = split(/,/, $line); #csv
			
			if (exists($fields[0]))
			{
				push @pos_motivations, $fields[0];
			}
			
			if (exists($fields[1]))
			{
				push @neg_motivations, $fields[1];
			}
		}
		
		close ($fh);
		$dummy_var = 1;
	}
		
	
	my $pos_count = 2 + int(rand(3));
	my $neg_count = 1 + int(rand(2));
	
	if (scalar @pos_motivations == 0)
	{
		push @pos_motivations, "Apathy";
	}
	if (scalar @neg_motivations == 0)
	{
		push @neg_motivations, @pos_motivations[int(rand(scalar @pos_motivations))];
	}	
	
	for my $i (1..$pos_count)
	{
		my $new_motivation = $pos_motivations[int(rand(scalar @pos_motivations))];
		
		my %mot_check = map { $_ => 1 } @char_motivations;
		my $count = 0;
		while (exists($mot_check{".+" . $new_motivation}) && $count < 5)
		{
			$new_motivation = @pos_motivations[int(rand(scalar @pos_motivations))];
			$count++;
		}
		if ($count < 5)
		{
			push @char_motivations, ".+" . $new_motivation;
		}
				
	}
	
	for my $i (1..$neg_count)
	{
		my $new_motivation = $neg_motivations[int(rand(scalar @neg_motivations))];
		
		my %mot_check = map { $_ => 1 } @char_motivations;
		my $count = 0;
		while (exists($mot_check{".-" . $new_motivation}) && $count < 5)
		{
			$new_motivation = @neg_motivations[int(rand(scalar @neg_motivations))];
			$count++;
		}
		if ($count < 5)
		{
			push @char_motivations, ".-" . $new_motivation;
		}
				
	}
	
	
	
	
	
	
	#output
	
	my @return_out;
	push @return_out, scalar @char_cultures;
	push @return_out, scalar @char_factions;
	push @return_out, scalar @char_roles;
	push @return_out, scalar @char_motivations;
	foreach (@char_cultures) 
	{
		push @return_out, $_;
	}
	foreach (@char_factions)
	{
		push @return_out, $_;
	}
	foreach (@char_roles)
	{
		push @return_out, $_;
	}
	foreach (@char_motivations)
	{
		push @return_out, $_;
	}
	
	return @return_out;
}

sub generate_name
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
	
	if (length $firstname > 9 && int(rand(100)) < 2)
	{
		my $chopped = 3 + int(rand(4));
		if (substr($firstname, (-1 * $chopped), 1) ne " ")
		{
			$firstname = substr($firstname, 0, (-1 * $chopped) + 1);
		}
		else
		{
			$firstname = substr($firstname, 0, (-1 * $chopped));
		}
		
	}
	
	if (length $firstname > 8 && int(rand(100)) < 2) #randomly adds a diminutive. Chance that it just chops it.
	{
		if (substr($firstname, -4, 1) ne " ")
		{
			$firstname = substr($firstname, 0, -3) . random_regex('[aeiouy][a-z]?[aeiou]?');
		}
		else
		{
			$firstname = substr($firstname, 0, -4) . random_regex('[aeiouy][a-z]?[aeiou]?');
		}
		
	}
	
	if (length $firstname < 10 && int(rand(100)) < 2) #randomly adds another human-readable name
	{
		$firstname = $firstname . "-" . random_regex('[BCDFGHJKLMNPRSTWVY][aeiou][bcdfghjklmnprstvwy][aeiou]?[bcdfghjklmnprstvwy]?[aeioun]?');		
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

	if ($last_n == -1 && $extraname != 1 && int(rand(100)) > (30 + ((length $char_name) * 4))) 
	{
		return generate_name($pkg_name, $char_name, $_[2]);
	}
	elsif ($extraname != 1 && int(rand(100)) > (85 + (length $char_name))) #Much smaller chance of a "doubled" name, because otherwise this will get ridiculous
	{
		return generate_name($pkg_name, $char_name, $_[2]);
	}
	
	my @out_array = ($char_name,$char_gender,$char_cult);
	return @out_array;
}
	
sub generate_character #0: Package Name, 1: NPC or PC
{
	my @out_array;
	
	my @out_name = generate_name($_[0], "NOEXTRA", $_[1]);
	push @out_array, $out_name[0];
	push @out_array, $out_name[1];
	
	my @out_personality = generatePersonality($_[0], $_[1], $out_name[2]);
	foreach (@out_personality)
	{
		push @out_array, $_;
	}
	
	return @out_array;

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

	say $csv_out "Name,Gender,No. of Cultures,No. of Factions,No. of Roles,No. of Motivations";

	my @all_characters;
	my @headers = ("Name","Gender","No. of Cultures","No. of Factions","No. of Roles","No. of Motivations");
	for (1..20)
	{
		push @headers, "Data"; #To ensure data isn't lost when being transposed.
	}
	push @all_characters, \@headers; 
		
	for my $i (1..$char_number)
	{
		my @new_char = generate_character($pkg_name, 0);
		push @all_characters, \@new_char;
		print $new_char[0] . "\n";
		my $csv_output = "";
		foreach (@new_char)
		{
			$csv_output = $csv_output . $_ . ",";
		}
		say $csv_out $csv_output;
	}
	
	close $csv_out;
	
	
	open (my $csv2_out, ">", "characters_readable.csv") or die "characters_readable.csv: $!";
	@all_characters = transpose(\@all_characters);

	for my $i (0..(scalar @all_characters - 1))
	{
		my $csv_output = "";
		
		for my $j (0..(scalar @{$all_characters[$i]} - 1))
		{
			if (defined $all_characters[$i][$j])
			{
				$csv_output = $csv_output . $all_characters[$i][$j] . ",";
			}
			else
			{
				$csv_output = $csv_output . " " . ",";
			}
		}
		
		say $csv2_out $csv_output;
	}
	close $csv2_out;
	print "Characters saved to characters.csv, A human-readable version is in characters_readable.csv.\n";
}