#!/usr/bin/perl

# eM-UpdaterCMD
# Written by evilmaniac
# http://www.evilmania.net

use Cwd;
use Term::ANSIColor;

#####################
## Default Profile ##
#####################

%hProfiles = (
	'l4d2'	=> {
			'DirImage'	 => '/home/evilmaniac/Documents/updater-test',
			'ImagePrefix'	 => 'l4d2_',
			'PrimaryImage'   => '00',
			'DirLogs'	 => 'left4dead2/addons/sourcemod/logs',
			'DirListConf'	 => [
					     	'start*',
						'left4dead2/addons/sourcemod/configs/sourcebans/sourcebans.cfg',
						'left4dead2/cfg/Server.cfg'
					    ],
			'DirListPayload' => [
						'left4dead2/addons',
						'left4dead2/cfg/em_cfg',
						'left4dead2/cfg/Server.cfg',
						'left4dead2/cfg/sourcemod',
						'left4dead2/em_motd.txt',
						'left4dead2/em_host.txt'
					    ],
		   },
	'tf2'	=> {
			'DirImage'	 => '/home/evilmania/hlds/tf2',
			'ImagePrefix'	 => 'tf2_',
			'PrimaryImage'   => '00',
			'DirLogs'	 => 'tf/addons/sourcemod/logs',
			'DirListConf'	 => [
					     	'start*',
						'tf/addons/sourcemod/configs/sourcebans/sourcebans.cfg',
						'tf/cfg/Server.cfg'
					    ],
			'DirListPayload' => [
						'tf/addons',
						'tf/cfg/Server.cfg',
						'tf/cfg/sourcemod',
						'tf/em_motd.txt',
						'tf/em_host.txt'
					    ],
		   }
);

###############
## Variables ##
###############

%hFunctions = (
	'help' 		=> {
			    	'Refrence'	=> \&DisplayHelp,
				'Description'	=> 'Displays this message'
			   },
	'scan' 		=> {
				'Refrence'	=> \&ListInstallations,
				'Description'	=> 'Scans if the currently set profile has any installation images'
			   },
	'echo' 		=> {
				'Refrence'	=> \&Echo,
				'Description'	=> 'Prints any arguments passed'
			   },
	'genconf' 	=> {
			   	'Refrence'	=> \&GenConf,
				'Description'	=> 'Generates a configuration archive for each detected isntallation image'
			   },
	'genpayload'	=> {
			   	'Refrence'	=> \&GenPayload,
				'Description'	=> 'Generates a complete payload, used to patch a freshly installed primary image'
			   },
	'genlog'	=> {
				'Refrence'	=> \&GenLogArchive,
				'Description'	=> 'Generates an archive, storing all log files in an archive'
			   },
	'patch'		=> {
				'Refrence'	=> \&ApplyPatch,
				'Description'	=> 'Applies a .tar.gz patch file to all detected installation images'
			   },
	'set',		=> {
				'Refrence'	=> \&SetUpdaterCvar,
				'Description'	=> 'Modifies a Cvar. Usage: set <cvar> <value>'
			   },
        'exit' 		=> {
				'Refrence'	=> \&Exit,
				'Description'	=> 'Terminates the UpdaterCMD'
			   }
);

%hSettings = (
	'version'	  => 0.72,
	'profile'	  => 'l4d2',
	'sys_name'	  => 'eM-UpdaterCMD',
	'tar_verbose'	  => 1,
	'safe_mode'	  => 1,
	'console_prefix'  => 'UpdaterCMD',
	'error_prefix'	  => 'Error',
	'error_seperator' => ': ',
	'exit_message'	  => 'Terminating...',
);

%hColors = (
	'error_prefix'	  => 'red',
	'exit_message'	  => 'bold',
	'help_command'	  => 'bold',
	'help_title'	  => 'underline'
);

&CommandInput();

#############
## Console ##
#############

sub CommandInput(){
	print $hSettings{'console_prefix'}." -> ";
	my $usrCommand = <>;
	$usrCommand =~ s/[\$#@~!&*;,?^\|`\\\n]+//g; # Filter un-wanted symbols to avoid
						    # accidental command injection
        &ProcessCommand($usrCommand);
}

sub ProcessCommand(){
	my($usrInput) = $_[0];

	my(@usrTokens) = split(/\s+/,$usrInput);
	my $usrCommand = shift(@usrTokens);

        if (exists $hFunctions{$usrCommand}){ &{$hFunctions{$usrCommand}{'Refrence'}}(@usrTokens); }
        else { &printError("Command not found", __LINE__); }

        &CommandInput();
}

############
## Engine ##
############

# executes a shell command
sub exeSysCmd(){
	if(@_ == 1){
		my($sCmd) = @_;
		system("$sCmd\n");
	}
	else { &printError("Invalid number of arguments", __LINE__); }
	return;
}
# removes a given directory
sub rmDir(){
	if(@_ == 1){
		my($sDir) = @_;
		if(-e $sDir){
			if(-d $sDir){
				&exeSysCmd("rm -rf $sDir");
			}
			else { &printError("Given path is not a directory", __LINE__); }
		}
		else { &printError("Given path does not exist", __LINE__); }
	}
	else { &printError("Invalid number of arguments", __LINE__); }
	return;
}
# lists contents of a compressed tar archive
sub listContents(){
	if(@_ == 1){
		my($sArchiveName) = @_[0];

		if(-e $sArchiveName){ &exeSysCmd("tar -ztvf $sArchiveName"); }
		else { &printError("Archive [$sArchiveName] not found", __LINE__); }
	}
	else { &printError("Archive name not specified", __LINE__); }
	return;
}
# compresses given files into a tar archive
sub packFiles(){
	if(@_ == 2){
		my($sArchiveName, $sFiles) = @_;
		my $sFlags;

		if($hSettings{'tar_verbose'}) { $sFlags = '-zcvf'; }
		else { $sFlags = 'zcf'; }

		&exeSysCmd("tar $sFlags $sArchiveName.tar.gz $sFiles");
	}
	else{ &printError("Invalid number of arguments received", __LINE__); }
	return;
}
# extracts given tar archive at required destination
sub unpackFiles(){
	if(@_ == 2){
		my($sArchiveName, $sTargetDir) = @_;
		my $sFlags;

		if($hSettings{'tar_verbose'}) { $sFlags = '-zxvf'; }
		else { $sFlags = 'zxf'; }

		my $sCwd = getcwd();
		if(-e $sArchiveName){
			&exeSysCmd("cp $sArchiveName $sTargetDir");
			if(-e "$sTargetDir/$sArchiveName"){
				chdir($sTargetDir);
				&exeSysCmd("tar $sFlags $sArchiveName");
				&exeSysCmd("rm $sArchiveName");
				chdir($sCwd);
			}
			else{ &printError("An error occured while copying the archive", __LINE__); return; }
		}
		else{ &printError("Archive [$sArchiveName] not found", __LINE__); return; }
	}
	else { &printError("Invalid number of arguments received", __LINE__); return; }
	return
}
# returns the folder name from a given path
sub getFolderName(){
	if(@_ == 1){
		my($sDirPath) = @_;
		if(-d $sDirPath) { $sDirPath =~ /^.+\/(.+)$/; return($1); }
		else{ &printError("Received argument is not a directory path, or director does not exist", __LINE__); }
	}
	else { &printError("Invalid number of arguments", __LINE__); }
	return
}
# returns a list of all installation images
sub getInstallations(){
	return <$hProfiles{$hSettings{'profile'}}{'DirImage'}/$hProfiles{$hSettings{'profile'}}{'ImagePrefix'}*>;
}
# prints an error message to the user
sub printError(){
	if(@_ == 2){
		my($sErrorMsg, $iLineNum) = @_;
		print(colored([$hColors{'error_prefix'}], $hSettings{'error_prefix'}).$hSettings{'error_seperator'}.$sErrorMsg." ($iLineNum)\n");
	} else { &printError("Invalid number of arguments", __LINE__); }
	return;
}
# returns date in the YYYY.MM.DD format
sub getDate(){
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year += 1900; # Year is returned as a value starting from 1900, therefore we must
		       # add 1900 to calculate present date.
	$mon += 1;     # Months start from 0, therefore we must add 1
	return("$year.$mon.$mday");
}
# checks whether or not an installation folder
# is a primary installation image or not. Returns
# 1 if it is, 0 otherwise
sub isPrimary(){
	if(@_ == 1){
		my($sDirName) = @_;
		if($sDirName eq $hProfiles{$hSettings{'profile'}}{'ImagePrefix'}.$hProfiles{$hSettings{'profile'}}{'PrimaryImage'}){ return 1; } 
		else{ return 0; }
	}
	else { &printError("Invalid number of arguments", __LINE__); }
}

##############
## Commands ##
##############

##
# Displays each command currently available
#
##
sub DisplayHelp(){
	print $hSettings{'sys_name'}." | v".$hSettings{'version'}."\n\n".colored([$hColors{'help_title'}], Commands).":\n";
	foreach my $Key (keys %hFunctions){
		printf("- %s: %s\n", colored([$hColors{'help_command'}], $Key), $hFunctions{$Key}{'Description'});
	}
	return;
}
##
# Lists all installations in the hProfiles.game.DirImage directory 
# including primary installation and all forked installations
##
sub ListInstallations(){
	my @sDirs = getInstallations();
	foreach $sDir (@sDirs){
		print($sDir."\n");
	}
	return;
}
###
# Displays all arguments passed onto a cmd. Used for debugging
# purposes.
###
sub Echo(){
	if(@_ > 0){
		foreach my $Token (@_){ print $Token." "; }
		print "\n";
	}
	else { &printError("Nothing to echo", __LINE__); }
	return;
}
##
# Generates configuration file images from the forked installation
# images. Includes all files in the hProfiles.game.'DirListConf' array
##
sub GenConf(){
	my $sCwd  = getcwd();
	my @sDirs = &getInstallations();

	foreach my $sDir (@sDirs){
		chdir($sDir);

		if(&isPrimary(&getFolderName($sDir))) { next; } # Skip primary installation image
		&packFiles("$sCwd/$1", join(' ', @{$hProfiles{$hSettings{'profile'}}{'DirListConf'}}));
	}
	chdir($sCwd);
	return;
}
###
# Generated a back up of each server's log files
# TODO chdir must change to absolute directory path
# (where the logs are stored)
###
sub GenLogArchive(){
	my $sCwd  = getcwd();
	my @sDirs = &getInstallations();

	foreach my $sDir (@sDirs){
		chdir($sDir);

		if(&isPrimary(&getFolderName($sDir))) { next; } # Skip primary installation image
		&exeSysCmd("mkdir -p $sCwd/logs/$1");
		&packFiles("$Cwd/logs/$1/log-$1-".&getDate(), "-C ".$hProfiles{$hSettings{'profile'}}{'DirLogs'});
	}
	chdir($sCwd);
	return;
}
##
# Generates a payload image from the primary installation
# Includes all files in the hProfiles.game.DirListPayload 
# array
##
sub GenPayload(){
	my $sCwd = getcwd();

	chdir($hProfiles{$hSettings{'profile'}}{'DirImage'}.'/'.$hProfiles{$hSettings{'profile'}}{'ImagePrefix'}.$hProfiles{$hSettings{'profile'}}{'PrimaryImage'});
	&packFiles("$sCwd/em_payload-".&getDate(), join(' ', @{$hProfiles{$hSettings{'profile'}}{'DirListPayload'}}));
	chdir($sCwd);
}
##
# Applies a .tar.gz patch archive to all installation images
#
##
sub ApplyPatch{
	if(@_ == 1){
		my($sArchiveName) = @_;
		my @sDirs = &getInstallations();
		my $iNumImages = scalar @sDirs;
		if($iNumImages > 0){
			&listContents($sArchiveName);
			print("Apply patch ? (y/n) -> ");
			my $sUsrReply = <>;
			if($sUsrReply =~ /^[Y]?$/i){
				foreach $sDir (@sDirs){ &unpackFiles($sArchiveName, $sDir); }
			}
			else { &printError("Patching aborted", __LINE__); return; }
		}
		else { &printError("No installation images found", __LINE__); }
	}
	else { &printError("Archive name not specified", __LINE__); }
	return;
}
##
# Updates a value in the %hSettings hash.
#
##
sub SetUpdaterCvar{
	if(@_ == 2) {
		my($sSetting, $sNewValue) = @_;

		if (exists $hSettings{$sSetting}){
			if($sSetting eq 'profile'){
				if(!exists $hProfiles{$sNewValue}){ &printError("Profile does not exist", __LINE__); return; }
			}
			$hSettings{$sSetting} = $sNewValue;
		}
		else { &printError("Cvar not found", __LINE__); return; }
	}
	else { &printError("Invalid number of arguments", __LINE__); }
	return;
}
##
# Terminates the application
#
##
sub Exit(){
	print(colored([$hColors{'exit_message'}], $hSettings{'exit_message'})."\n");
	exit(0);
}
