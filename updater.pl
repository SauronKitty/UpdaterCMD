#!/usr/bin/perl

# eM-UpdaterCMD
# Written by evilmaniac
# http://www.evilmania.net

use Cwd;
use Term::ANSIColor;

#####################
##    Variables    ##
#####################

%hSettings = (
	'version'	  => 0.95,
	'profile'	  => 'l4d2',
	'sys_name'	  => 'eM-UpdaterCMD',
	'dir_primary'	  => '/home/emania/hlds/',
	'dir_steamcmd'	  => '/home/emania/SteamCMD/',
	'fork_verbose'	  => 0,
	'tar_verbose'	  => 0,
	'console_prefix'  => 'UpdaterCMD',
	'error_prefix'	  => 'Error',
	'error_seperator' => ': ',
	'exit_message'	  => 'Terminating...'
);

%hColors = (
	'error_prefix'	  => 'red',
	'exit_message'	  => 'bold',
	'help_command'	  => 'bold',
	'help_title'	  => 'underline'
);

%hFunctions = (
	'help' 		=> {
			    	'Refrence'	=> \&DisplayHelp,
				'Description'	=> 'Displays this message'
			   },
	'scan' 		=> {
				'Refrence'	=> \&ListInstallations,
				'Description'	=> 'Displays installation images of currently set profile'
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
	'patchall'		=> {
				'Refrence'	=> \&ApplyPatch,
				'Description'	=> 'Applies a .tar.gz patch file to all detected installation images. patch <patchfile>.tar.gz'
			   },
	'patchimage'	=> {
				'Refrence'	=> \&PatchImage,
				'Description'	=> 'Apples a .tar.gz patch to a single installation image denoted by only a suffix. patchimage <patchfile>.tar.gz <suffix>'
			   },
	'set',		=> {
				'Refrence'	=> \&SetUpdaterCvar,
				'Description'	=> 'Modifies a cvar. Usage: set <cvar> <value>'
			   },
	'spawnimage',	=> {
				'Refrence'	=> \&SpawnImage,
				'Description'	=> 'Spawns an additional installation image based on the initial one. Accept 1 optional argument; an image suffix.'
			   },
	'update'	=> {
				'Refrence'	=> \&UpdateServerFiles,
				'Description'	=> 'Will download the latest server files from valve into the primary image'
			   },
        'exit' 		=> {
				'Refrence'	=> \&Exit,
				'Description'	=> 'Exits the UpdaterCMD'
			   }
);

#####################
## Default Profile ##
#####################

%hProfiles = (
	'l4d2'	=> {
			'AppId'		 => '222860',
			'DirImage'	 => $hSettings{'dir_primary'}.'l4d2',
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
	'csgo'	=> {
			'AppId'		 => '740',
			'DirImage'	 => $hSettings{'dir_primary'}.'csgo',
			'ImagePrefix'	 => 'csgo_',
			'PrimaryImage'   => '00',
			'DirLogs'	 => 'csgo/addons/sourcemod/logs',
			'DirListConf'	 => [
					     	'start*',
						'csgo/addons/sourcemod/configs/sourcebans/sourcebans.cfg',
						'csgo/cfg/server.cfg'
					    ],
			'DirListPayload' => [
						'csgo/addons',
						'csgo/cfg/server.cfg',
						'csgo/cfg/sourcemod',
						'csgo/em_motd.txt',
						'csgo/em_host.txt'
					    ],
		   },
	'tf2'	=> {
			'AppId'		 => '232250',
			'DirImage'	 => $hSettings{'dir_primary'}.'tf2',
			'ImagePrefix'	 => 'tf2_',
			'PrimaryImage'   => '00',
			'DirLogs'	 => 'tf/addons/sourcemod/logs',
			'DirListConf'	 => [
					     	'start*',
						'tf/addons/sourcemod/configs/sourcebans/sourcebans.cfg',
						'tf/cfg/server.cfg'
					    ],
			'DirListPayload' => [
						'tf/addons',
						'tf/cfg/server.cfg',
						'tf/cfg/sourcemod',
						'tf/em_motd.txt',
						'tf/em_host.txt'
					    ],
		   }
);

#####################
##      Main       ##
#####################

&CommandInput();

#####################
##     Console     ##
#####################

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

#####################
##      Engine     ##
#####################

##
# Bash related functions
##

# Executes a shell command
sub exeSysCmd(){
	if(@_ == 1){
		my($sCmd) = @_;
		system("$sCmd\n");
	}
	else { &printError("Invalid number of arguments", __LINE__); }
	return;
}
# Checks if a given file exists
sub fileExists(){
	if(@_ == 1){
		my($sFile) = @_;
		if(-e $sFile){
			if(-f $sFile){
				return 1;
			}
			else { &printError("Given path does not lead to a file", __LINE__); }
		}
		else { &printError("Given file does not exist", __LINE__); }
	}
	else { &printError("Invalid number of arguments", __LINE__); }
	return 0;
}
# Checks if a given folder exists
sub dirExists(){
	if(@_ == 1){
		my($sDir) = @_;
		if(-e $sDir){
			if(-d $sDir){
				return 1;
			}
			else { &printError("Given path is not a directory", __LINE__); }
		}
		else { &printError("Given path does not exist", __LINE__); }
	}
	else { &printError("Invalid number of arguments", __LINE__); }
	return 0;
}
# Changes pwd to the given dir
sub changeDir(){
	if(@_ == 1){
		my($sDir) = @_;
		if(&dirExists($sDir)){
			chdir($sDir) || &printError("Unable to change directory", __LINE__);
			return 1;
		}
		else { &printError("Unable to change directory", __LINE__); }
	}
	else { &printError("Invalid number of arguments", __LINE__); }
	&Exit();
	return 0;
}
# Removes a given directory
sub rmDir(){
	if(@_ == 1){
		my($sDir) = @_;
		if(&dirExists($sDir)){
			&exeSysCmd("rm -rf $sDir");
		}
		else { &printError("Unable to remove directory", __LINE__); }
	}
	else { &printError("Invalid number of arguments", __LINE__); }
	return;
}
# Removes a given file
sub rmFile(){
	if(@_ == 1){
		my($sFile) = @_;
		if(&fileExists($sFile)){
			&exeSysCmd("rm $sFile");
		}
		else { &printError("Unable to remove file", __LINE__); }
	}
	else { &printError("Invalid number or arguments", __LINE__); }
	return;
}

##
# Image related functions
##

# Will generate a derivative installation from the primary one. Takes 1 argument; the suffix to the image that will be created
sub forkImage(){
	if(@_ == 1){
		my($sImageSuffix) = @_;
#		my $sPrimaryImage = $hProfiles{$hSettings{'profile'}}{'DirImage'}.'/'.
#				    $hProfiles{$hSettings{'profile'}}{'ImagePrefix'}.
#				    $hProfiles{$hSettings{'profile'}}{'PrimaryImage'};
		my $sPrimaryImage = &getPrimaryImagePath();
		my $sDestination  = $hProfiles{$hSettings{'profile'}}{'DirImage'}.'/'.
				    $hProfiles{$hSettings{'profile'}}{'ImagePrefix'}.
				    $sImageSuffix;
		unless(-e $sDestination){ # &dirExists() prints an error, which we do not want in this case
			if(&dirExists($sPrimaryImage)){
				if($hSettings{'fork_verbose'}){ &exeSysCmd("cp -Rlv $sPrimaryImage $sDestination"); }
				else { &exeSysCmd("cp -Rl $sPrimaryImage $sDestination"); }
			}
			else { &printError("Unable to create an installation image", __LINE__); }
		}
		else { &printError("Image already exists", __LINE__); }
	}
	else { &printError("Invalid number or arguments", __LINE__); }
	return;
}

# Checks whether or not an installation folder
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
# Returns a list of all installation images
sub getInstallations(){
	return <$hProfiles{$hSettings{'profile'}}{'DirImage'}/$hProfiles{$hSettings{'profile'}}{'ImagePrefix'}*>;
}

##
# Archive related functions
##

# Lists contents of a compressed tar archive
sub listContents(){
	if(@_ == 1){
		my($sArchiveName) = @_[0];

		if(&fileExists($sArchiveName)){ &exeSysCmd("tar -ztvf $sArchiveName"); }
		else { &printError("An error occured while attempting to locate the archive", __LINE__); }
	}
	else { &printError("Archive name not specified", __LINE__); }
	return;
}
# Compresses given files into a tar archive
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
# Extracts given tar archive at required destination
sub unpackFiles(){
	if(@_ == 2){
		my($sArchiveName, $sTargetDir) = @_;
		my $sFlags;

		if($hSettings{'tar_verbose'}) { $sFlags = '-zxvf'; }
		else { $sFlags = 'zxf'; }

		my $sCwd = getcwd();
		if(&fileExists($sArchiveName)){
			&exeSysCmd("cp $sArchiveName $sTargetDir");
			if(&fileExists("$sTargetDir/$sArchiveName")){
				&changeDir($sTargetDir);
				&exeSysCmd("tar $sFlags $sArchiveName");
				&exeSysCmd("rm $sArchiveName"); # Using a direct system call as the &removeFile() function
								# will check whether the file exists once again.
				&changeDir($sCwd);
			}
			else{ &printError("An error occured while copying the archive", __LINE__); return; }
		}
		else{ &printError("An error occured while attempting to locate the archive", __LINE__); return; }
	}
	else { &printError("Invalid number of arguments received", __LINE__); return; }
	return
}

##
# Specialized functions
##

# Get path to the primary installation image
sub getPrimaryImagePath(){
	my $sPrimaryImage = $hProfiles{$hSettings{'profile'}}{'DirImage'}.'/'.
			    $hProfiles{$hSettings{'profile'}}{'ImagePrefix'}.
			    $hProfiles{$hSettings{'profile'}}{'PrimaryImage'};
	return($sPrimaryImage);
}
# Returns the folder name from a given path
sub getFolderName(){
	if(@_ == 1){
		my($sDirPath) = @_;
		if(-d $sDirPath) { $sDirPath =~ /^.+\/(.+)$/; return($1); }
		else{ &printError("Received argument is not a directory path, or director does not exist", __LINE__); }
	}
	else { &printError("Invalid number of arguments", __LINE__); }
	return
}
# Prints an error message to the user
sub printError(){
	if(@_ == 2){
		my($sErrorMsg, $iLineNum) = @_;
		print(colored([$hColors{'error_prefix'}], $hSettings{'error_prefix'}).$hSettings{'error_seperator'}.$sErrorMsg." ($iLineNum)\n");
	} else { &printError("Invalid number of arguments", __LINE__); }
	return;
}
# Returns date in the YYYY.MM.DD format
sub getDate(){
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year += 1900; # Year is returned as a value starting from 1900, therefore we must
		       # add 1900 to calculate present date.
	$mon += 1;     # Months start from 0, therefore we must add 1
	return("$year.$mon.$mday");
}

#####################
##     Commands    ##
#####################

# Displays each command currently available
sub DisplayHelp(){
	print $hSettings{'sys_name'}." | v".$hSettings{'version'}."\n".colored([$hColors{'help_title'}], Commands).":\n";
	foreach my $Key (keys %hFunctions){
		printf("- %s: %s\n", colored([$hColors{'help_command'}], $Key), $hFunctions{$Key}{'Description'});
	}
	return;
}
# Lists all installations in the hProfiles.game.DirImage directory 
# including primary installation and all forked installations
sub ListInstallations(){
	my @sDirs = getInstallations();
	foreach $sDir (@sDirs){
		print($sDir."\n");
	}
	return;
}
# Displays all arguments passed onto a cmd. Used for debugging
# purposes.
sub Echo(){
	if(@_ > 0){
		foreach my $Token (@_){ print $Token." "; }
		print "\n";
	}
	else { &printError("Nothing to echo", __LINE__); }
	return;
}
# Generates configuration file images from the forked installation
# images. Includes all files in the hProfiles.game.'DirListConf' array
sub GenConf(){
	my $sCwd  = getcwd();
	my @sDirs = &getInstallations();

	foreach my $sDir (@sDirs){
		&changeDir($sDir);

		my $sFolder = &getFolderName($sDir);
		if(&isPrimary($sFolder)) { next; } # Skip primary installation image
		&packFiles("$sCwd/$sFolder", join(' ', @{$hProfiles{$hSettings{'profile'}}{'DirListConf'}}));
	}
	&changeDir($sCwd);
	return;
}
# Generated a back up of each server's log files
# TODO chdir must change to absolute directory path
# (where the logs are stored)
sub GenLogArchive(){
	my $sCwd  = getcwd();
	my @sDirs = &getInstallations();

	foreach my $sDir (@sDirs){
		&changeDir($sDir);

		if(&isPrimary(&getFolderName($sDir))) { next; } # Skip primary installation image
		&exeSysCmd("mkdir -p $sCwd/logs/$1");
		&packFiles("$Cwd/logs/$1/log-$1-".&getDate(), "-C ".$hProfiles{$hSettings{'profile'}}{'DirLogs'});
	}
	&changeDir($sCwd);
	return;
}
# Generates a payload image from the primary installation
# Includes all files in the hProfiles.game.DirListPayload 
# array
sub GenPayload(){
	my $sCwd = getcwd();

	&changeDir($hProfiles{$hSettings{'profile'}}{'DirImage'}.'/'.$hProfiles{$hSettings{'profile'}}{'ImagePrefix'}.$hProfiles{$hSettings{'profile'}}{'PrimaryImage'});
	&packFiles("$sCwd/em_payload-".$hSettings{'profile'}.'-'.&getDate(), join(' ', @{$hProfiles{$hSettings{'profile'}}{'DirListPayload'}}));
	&changeDir($sCwd);
}
# Applies a .tar.gz patch archive to all installation images
# TODO: rename function to PatchAll()
sub ApplyPatch(){
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
# Patches a single image given an image suffix and an archive name
# TODO: Must accept full image name as opposed to suffix only
sub PatchImage(){
	if(@_ == 2){
		my($sArchiveName, $sImageSuffix) = @_;
		my $sDestination  = $hProfiles{$hSettings{'profile'}}{'DirImage'}.'/'.
				    $hProfiles{$hSettings{'profile'}}{'ImagePrefix'}.
				    $sImageSuffix;
		if(&fileExists($sArchiveName){
			if(&dirExists($sDestination)){
				&unpackFiles($sArchiveName, $sDestination);
			}
			else { &printError("Installation image not found", __LINE__); }
		}
		else { &printError("Patch file not found", __LINE__); }
	}
	else { &printError("Invalid number of arguments", __LINE__); }
	return;
}
# Updates a value in the %hSettings hash.
sub SetUpdaterCvar(){
	if(@_ == 2){
		my($sSetting, $sNewValue) = @_;

		if (exists $hSettings{$sSetting}){
			if($sSetting eq 'profile'){
				if(!exists $hProfiles{$sNewValue}){ &printError("Profile does not exist", __LINE__); }
				else { $hSettings{$sSetting} = $sNewValue; }
			}
			else { $hSettings{$sSetting} = $sNewValue; }
		}
		else { &printError("Cvar not found", __LINE__); }
	}
	else { &printError("Invalid number of arguments", __LINE__); }
	return;
}
# Creates an installation image
sub SpawnImage(){
	if(@_ == 0){
		my @sDirs = &getInstallations();
		foreach my $sDir (@sDirs){
			unless(&isPrimary(&getFolderName($sDir))){ print($sDir."\n"); }
			else { print(colored(['bold'], $sDir)."\n"); } # Primary image will be bold
		}
		print("Please insert a suffix for the image you wish to create: ");
		my $sSuffix = <>;
		print("Process started\n");
		&forkImage($sSuffix);
	}
	else { &forkImage($_[0]); }
	return;
}
# Passes commands to SteamCMD to update server file installations
sub UpdateServerFiles(){
	my $sCmdDir = $hSettings{'dir_steamcmd'}."steamcmd.sh";

	if(&fileExists($sCmdDir)){
		my $sPrimaryImage = &getPrimaryImagePath();
		my $sAppId	  = $hProfiles{$hSettings{'profile'}}{'AppId'};

		&exeSysCmd("sh $sCmdDir +login anonymous +force_install_dir $sPrimaryImage +app_update $sAppId +quit");
	}
	else { &printError("SteamCMD not found", __LINE__); }
	return;
}
# Terminates the application
sub Exit(){
	print(colored([$hColors{'exit_message'}], $hSettings{'exit_message'})."\n");
	exit(0);
}
