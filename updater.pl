#!/usr/bin/perl

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
	'help' 		=> \&DisplayHelp,
	'scan' 		=> \&ListInstallations,
	'echo' 		=> \&Echo,
	'genconf' 	=> \&GenConf,
	'genpayload'	=> \&GenPayload,
	'genlogarchive'	=> \&GenLogArchive,
	'patch'		=> \&ApplyPatch,
	'set',		=> \&SetUpdaterCvar,
        'exit' 		=> \&Exit,
);

%hSettings = (
	'version'	  => 0.70,
	'sys_name'	  => 'eM-UpdaterCMD',
	'tar_verbose'	  => 1,
	'console_prefix'  => 'UpdaterCMD',
	'error_prefix'	  => 'Error',
	'error_seperator' => ': ',
	'exit_message'	  => 'Terminating...',
);

%hColors = (
	'error_prefix'	  => 'red',
	'exit_message'	  => '',
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

        if (exists $hFunctions{$usrCommand}){ &{$hFunctions{$usrCommand}}(@usrTokens); }
        else { &printError("Command not found"); }

        &CommandInput();
}

############
## Engine ##
############

# executes a shell command
sub exeSysCmd(){
	my($sCmd) = @_;
	system("$sCmd\n");
	return;
}
# lists contents of a compressed tar archive
sub listContents(){
	if(scalar @_ == 1){
		my($sArchiveName) = @_[0];

		if(-e $sArchiveName){ &exeSysCmd("tar -ztvf $sArchiveName"); }
		else { &printError("Archive [$sArchiveName] not found"); }
	}
	else { &printError("Archive name not specified"); }
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
	else{ &printError("Invalid number of arguments received");}
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
			else{ &printError("An error occured while copying the archive"); return; }
		}
		else{ &printError("Archive [$sArchiveName] not found"); return; }
	}
	else { &printError("Invalid number of arguments received"); return; }
	return
}
# returns a list of all installation images
sub getInstallations(){
	return <$hProfiles{'l4d2'}{'DirImage'}/$hProfiles{'l4d2'}{'ImagePrefix'}*>;
}
# prints an error message to the user
sub printError(){
	my($sErrorMsg) = @_;
	print(colored([$hColors{'error_prefix'}],$hSettings{'error_prefix'}).$hSettings{'error_seperator'}.$sErrorMsg."\n");
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
	my($sDirName) = @_;
	if($sDirName eq $hProfiles{'l4d2'}{'ImagePrefix'}.$hProfiles{'l4d2'}{'PrimaryImage'}){ return 1; } 
	else{ return 0; }
}

##############
## Commands ##
##############

##
# Displays each command currently available
#
##
sub DisplayHelp(){
	print $hSettings{'sys_name'}." | v".$hSettings{'version'}."\n\nCommands:\n";
	foreach my $Key (keys %hFunctions){ print $Key."\n"; }
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
	else { &printError("Nothing to echo"); }
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

		$sDir =~ /^.+\/(.+)$/; # Calculate image number e.g. l4d2_XX where XX is the image id
		if(&isPrimary($1)) { next; } # Skip primary installation image
		&packFiles("$sCwd/$1", join(' ', @{$hProfiles{'l4d2'}{'DirListConf'}}));
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

		$sDir =~ /^.+\/(.+)$/; # Calculate image number e.g. l4d2_XX where XX is the image number
		if(&isPrimary($1)) { next; } # Skip primary installation image
		&exeSysCmd("mkdir -p $sCwd/logs/$1");
		&packFiles("$Cwd/logs/$1/log-$1-".&getDate(), "-C ".$hProfiles{'l4d2'}{'DirLogs'});
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

	chdir($hProfiles{'l4d2'}{'DirImage'}.'/'.$hProfiles{'l4d2'}{'ImagePrefix'}.$hProfiles{'l4d2'}{'PrimaryImage'});
	&packFiles("$sCwd/em_payload-".&getDate(), join(' ', @{$hProfiles{'l4d2'}{'DirListPayload'}}));
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
			else { &printError("Patching aborted"); return; }
		}
		else { &printError("No installation images found"); }
	}
	else { &printError("Archive name not specified"); }
	return;
}
##
# Updates a value in the %hSettings hash.
#
##
sub SetUpdaterCvar{
	if(@_ == 2) {
		my($sSetting, $sNewValue) = @_;

		if (exists $hSettings{$sSetting}){ $hSettings{$sSetting} = $sNewValue; }
		else { &printError("Cvar not found"); return; }
	}
	else { &printError("Invalid number of arguments"); }
	return;
}
##
# Terminates the application
#
##
sub Exit(){
	print($hSettings{'exit_message'}."\n");
	exit(0);
}
