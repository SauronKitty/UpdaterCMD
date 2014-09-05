#!/usr/bin/perl -w

# eM-UpdaterCMD
# Written by evilmaniac
# http://www.evilmania.net

use strict;

use Cwd;
use File::Path;
use Term::ANSIColor;

BEGIN { push @INC, getcwd(); }
use Em::Console;

#####################
##    Variables    ##
#####################

my %hSettings = (
	'version'	  => '1.1',
	'profile'	  => 'l4d2',
	'sys_name'	  => 'eM-UpdaterCMD',
	'dir_primary'	  => '/home/emania/hlds/',
	'dir_steamcmd'	  => '/home/emania/SteamCMD/',
	'dir_output'	  => getcwd(),
	'exe_steamcmd'	  => 'steamcmd.sh',
	'fork_verbose'	  => 0,
	'cmd_verbose'	  => 0,
	'auto_patch'	  => 1,
	'console_prefix'  => 'UpdaterCMD',
	'error_prefix'	  => 'Error',
	'error_seperator' => ': ',
	'exit_message'	  => 'Terminating.'
);

my %hColors = (
	'error_prefix'	  => 'red',
	'exit_message'	  => 'bold',
	'help_command'	  => 'bold',
	'help_title'	  => 'underline'
);

my %hDownloads = (
	'url_steamcmd'	  => 'http://media.steampowered.com/installer/steamcmd_linux.tar.gz'
);

my %hErrorMessages = ( # Added to reduce the number of strings that must be initialized on run time
		       # Will also make translations easier if needed in the future.
	'invalid_num_arg'		=> 'Invalid number of arguments',
	'invalid_archive_name'		=> 'Archive name invalid or not specified',
	'usr_root'			=> 'You are not permitted to run this application as the root user',
	'not_file'			=> 'Given path leads to a directory and not a file',
	'not_path'			=> 'Given path leads to a file and not a directory',
	'dne_archive'			=> 'Given archive does not exist',
	'dne_conf_archive'		=> 'Configuration image not found',
	'dne_file'			=> 'Given file does not exist',
	'dne_path'			=> 'Given path does not exist',
	'dne_patch'			=> 'Patch file does not exist',
	'dne_primary'			=> 'Primary installation image does not exist',
	'dne_profile'			=> 'Profile does not exist',
	'dne_image'			=> 'Image does not exist',
	'dne_cmd'			=> 'Command does not exist',
	'dne_cvar'			=> 'Cvar does not exist',
	'dne_steamcmd'			=> 'SteamCMD installation has not been found',
	'error_chdir'			=> 'Unable to change directory',
	'error_rmfile'			=> 'Unable to remove file',
	'error_rmdir'			=> 'Unable to remove directpry',
	'error_image_exists'		=> 'Image already exists',
	'error_cp_archive'		=> 'An error occured while copying the archive',
	'error_dirlist_empty'		=> 'DirListPayload is empty. Please check the '.$hSettings{'profile'}.' profile settings',
	'error_steamcmd_update' 	=> 'Unable to update server files',
	'abort_patching'		=> 'Patching has been aborted',
	'abort_steam_update'		=> 'Server file update has been aborted',
	'generic_echo_000'		=> 'Nothing to echo',
	'generic_getfoldername_000'	=> 'Unable to return folder name',
	'generic_forkimage_000'		=> 'Unable to create an installation image'
);

my %hFunctions = (
	'help' 		=> {
			    	'Refrence'	=> \&pDisplayHelp,
				'Description'	=> 'Displays this message'
			   },
	'scan' 		=> {
				'Refrence'	=> \&ListInstallations,
				'Description'	=> 'Displays installation images of currently set profile'
			   },
	'echo' 		=> {
				'Refrence'	=> \&pEcho,
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
	'patchall'	=> {
				'Refrence'	=> \&PatchAll,
				'Description'	=> 'Applies a .tar.gz patch file to all detected installation images. Usage: patch <patchfile>'
			   },
	'patchimage'	=> {
				'Refrence'	=> \&PatchImage,
				'Description'	=> 'Apples a .tar.gz patch to a single installation image denoted by only a suffix. Usage: patchimage <patchfile> <suffix>'
			   },
	'set',		=> {
				'Refrence'	=> \&SetUpdaterCvar,
				'Description'	=> 'Modifies a cvar. Usage: set <cvar> <value>'
			   },
	'spawnimage',	=> {
				'Refrence'	=> \&SpawnImage,
				'Description'	=> 'Spawns an additional installation image based on the initial one. Accept 1 optional argument; an image suffix.'
			   },
	'respawnimage'	=> {
				'Refrence'	=> \&RespawnImage,
				'Description'	=> 'Recreates an image from the primary installation directory and attempts to patch it with a configuration archive. Requires an image suffix.'
			   },
	'update'	=> {
				'Refrence'	=> \&UpdateServerFiles,
				'Description'	=> 'Downloads the latest patch files from the Valve servers and updates the primary isntallation image'
			   },
	'install'	=> {
				'Refrence'	=> \&InstallServerFiles,
				'Description'	=> 'Installs the game files for currently selected profile (set profile <profile>)'
			   },
        'exit' 		=> {
				'Refrence'	=> \&pExit,
				'Description'	=> 'Exits the UpdaterCMD'
			   }
);

#####################
## Default Profile ##
#####################

my %hProfiles = (
	'l4d2'	=> { # Left 4 Dead 2
			'AppId'		 => '222860',
			'DirImage'	 => $hSettings{'dir_primary'}.'l4d2',
			'ImagePrefix'	 => 'l4d2_',
			'PrimaryImage'   => '00',
			'IgnorePrimary'	 => '1', # Ignore primary image when backing up server configuration
						 # should be 0 if primary installation is used to run server
						 # and the server is not run through a hard linked image
			'DirLogs'	 => 'left4dead2/addons/sourcemod/logs/*',
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
	'csgo'	=> { # Counter-Strike: Global Offensive
			'AppId'		 => '740',
			'DirImage'	 => $hSettings{'dir_primary'}.'csgo',
			'ImagePrefix'	 => 'csgo_',
			'PrimaryImage'   => '00',
			'IgnorePrimary'	 => '1',
			'DirLogs'	 => 'csgo/addons/sourcemod/logs/*',
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
	'tf2'	=> { # Team Fortress 2
			'AppId'		 => '232250',
			'DirImage'	 => $hSettings{'dir_primary'}.'tf2',
			'ImagePrefix'	 => 'tf2_',
			'PrimaryImage'   => '00',
			'IgnorePrimary'	 => '1',
			'DirLogs'	 => 'tf/addons/sourcemod/logs/*',
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
		   },
	'ns2'	=> { # Natural Selection 2
			'AppId'		 => '4940',
			'DirImage'	 => $hSettings{'dir_primary'}.'ns2',
			'ImagePrefix'	 => 'ns2_',
			'PrimaryImage'   => '00',
			'IgnorePrimary'	 => '0',
			'DirLogs'	 => 'logs/*',
			'DirListConf'	 => [
						'start*',
						'config/ServerConfig.json',
						'config/ServerAdmin.json',
						'config/MapCycle.json',
						'config/ConsistencyConfig.json',
						'config/BannedPlayers.json'
					    ],
			'DirListPayload' => [
					    ],
		   }
);

#####################
##      Main       ##
#####################

sub Main(){
	# Check if running as root user. If we are; terminate
	if($ENV{LOGNAME} eq 'root'){ &printError($hErrorMessages{'usr_root'}, __FILE__.':'.__LINE__); &Exit(); }

	if(!exists $hProfiles{$hSettings{'profile'}}){
		&printError($hErrorMessages{'dne_profile'}, __FILE__.':'.__LINE__);
	}
	else{
		# Configure Em::Console
		&Em::Console::SetCvar('cmd_verbose', $hSettings{'cmd_verbose'});
		&Em::Console::SetCvar('error_prefix', $hSettings{'error_prefix'});
		&Em::Console::SetCvar('error_seperator', $hSettings{'error_seperator'});
		&Em::Console::SetCvar('exit_message', $hSettings{'exit_message'});

		print(colored(['bold'], "Loaded ".$hSettings{'sys_name'}.' '.$hSettings{'version'}."\n"));
		&CommandInput();
	}
	&Exit();
}

&Main();

#####################
##     Console     ##
#####################

sub CommandInput(){
	print '('.$hSettings{'profile'}.') '.$hSettings{'console_prefix'}.' -> ';
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
	else { &printError($hErrorMessages{'dne_cmd'}, __FILE__.':'.__LINE__); }

        &CommandInput();
}

#####################
##      Engine     ##
#####################

##
# Image related functions
##

# Will generate a derivative installation from the primary one. Takes 1 argument; the suffix to the image that will be created
sub forkImage(){
	if(@_ == 1){
		my($sImageSuffix) = @_;
		my $sPrimaryImage = &getPrimaryImagePath();
		my $sDestination  = $hProfiles{$hSettings{'profile'}}{'DirImage'}.'/'.
				    $hProfiles{$hSettings{'profile'}}{'ImagePrefix'}.
				    $sImageSuffix;
		unless(-e $sDestination){ # &Em::Console::dirExists() prints an error, which we do not want in this case
			if(&Em::Console::dirExists($sPrimaryImage)){
				if($hSettings{'fork_verbose'}){ &Em::Console::exeSysCmd("cp -Rlv $sPrimaryImage $sDestination"); }
				else { &Em::Console::exeSysCmd("cp -Rl $sPrimaryImage $sDestination"); }
			}
			else { &printError($hErrorMessages{'generic_forkimage_000'}, __FILE__.':'.__LINE__); }
		}
		else { &printError($hErrorMessages{'error_image_exists'}, __FILE__.':'.__LINE__); }
	}
	else { &printError($hErrorMessages{'invalid_num_arg'}, __FILE__.':'.__LINE__); }
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
	else { &printError($hErrorMessages{'invalid_num_arg'}, __FILE__.':'.__LINE__); }
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
		my($sArchiveName) = $_[0];

		if(&Em::Console::fileExists($sArchiveName)){ &Em::Console::exeSysCmd("tar -ztvf $sArchiveName"); }
		else { &printError($hErrorMessages{'dne_archive'}, __FILE__.':'.__LINE__); }
	}
	else { &printError($hErrorMessages{'invalid_archive_name'}, __FILE__.':'.__LINE__); }
	return;
}
# Compresses given files into a tar archive
sub packFiles(){
	if(@_ == 2){
		my($sArchiveName, $sFiles) = @_;
		&Em::Console::exeSysCmd("tar -zcvf $sArchiveName.tar.gz $sFiles");
	}
	else{ &printError($hErrorMessages{'invalid_num_arg'}, __FILE__.':'.__LINE__); }
	return;
}
# Extracts given tar archive at required destination
sub unpackFiles(){
	if(@_ == 2){
		my($sArchivePath, $sTargetDir) = @_;

		my $sCwd = getcwd();
		if(&Em::Console::fileExists($sArchivePath)){
			### VOLATILE ### NEEDS MORE TESTING ###
			my $sArchiveName = $sArchivePath;
			if($sArchivePath =~ m/^.+\/(.+\.tar\.gz)$/){ $sArchiveName = $1; } # If a path has been passed instead of an archive name
			###    END   ### 000                ###

			&Em::Console::exeSysCmd("cp $sArchivePath $sTargetDir");
			if(&Em::Console::fileExists("$sTargetDir/$sArchiveName")){
				&Em::Console::changeDir($sTargetDir);
				&Em::Console::exeSysCmd("tar -zxvf $sArchiveName");
				&Em::Console::exeSysCmd("rm $sArchiveName"); # Using a direct system call as the &removeFile() function
								# will check whether the file exists once again.
				&Em::Console::changeDir($sCwd);
			}
			else{ &printError($hErrorMessages{'error_cp_archive'}, __FILE__.':'.__LINE__); return; }
		}
		else{ &printError($hErrorMessages{'dne_archive'}, __FILE__.':'.__LINE__); return; }
	}
	else { &printError($hErrorMessages{'invalid_num_arg'}, __FILE__.':'.__LINE__); return; }
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
# Get path to the profile's patch folder
sub getPatchDir(){
	if(@_ == 1){
		my($sArchiveName) = @_;
		if(&Em::Console::fileExists($sArchiveName)){ return($sArchiveName); }
		else {
			$sArchiveName = $hSettings{'dir_output'}.'/'.$hSettings{'profile'}.'/patches/'.$sArchiveName;
			if(&Em::Console::fileExists($sArchiveName)){ return($sArchiveName); }
		}
		&printError($hErrorMessages{'dne_patch'}, __FILE__.':'.__LINE__);
	}
	else { &printError($hErrorMessages{'invalid_num_arg'}, __FILE__.':'.__LINE__); }
	&CommandInput(); # Return to command line after this function fails
}
# Returns the folder name from a given path
sub getFolderName(){
	if(@_ == 1){
		my($sDirPath) = @_;
		if(&Em::Console::dirExists($sDirPath)) { $sDirPath =~ /^.+\/(.+)$/; return($1); }
		else{ &printError($hErrorMessages{'generic_getfoldername_000'}, __FILE__.':'.__LINE__); }
	}
	else { &printError($hErrorMessages{'invalid_num_arg'}, __FILE__.':'.__LINE__); }
	return
}
# Prints a status message to the user
sub printStatus(){
	if(@_ == 1){
		my($sStatusMsg) = @_;
		print($sStatusMsg."\n");
	} else { &printError($hErrorMessages{'invalid_num_arg'}, __FILE__.':'.__LINE__); }
	return;
}
# Prints an error message to the user
sub printError(){
	&Em::Console::printError(@_);
	return;
}

#####################
##     Commands    ##
#####################

# Displays each command currently available
# The arguments to this function are passed to the Em::Console package &DisplayHelp()
sub pDisplayHelp(){
	&Em::Console::DisplayHelp($hSettings{'sys_name'}, $hSettings{'version'}, \%hFunctions);
	return;
}
# Lists all installations in the hProfiles.game.DirImage directory 
# including primary installation and all forked installations
sub ListInstallations(){
	my @sDirs = getInstallations();
	foreach my $sDir (@sDirs){
		print($sDir."\n");
	}
	return;
}
# Displays all arguments passed onto a cmd. Used for debugging purposes.
# The arguments to this function are passed to the Em::Console package &Echo()
sub pEcho(){
	&Em::Console::Echo(@_);
	return;
}
# Generates configuration file images from the forked installation
# images. Includes all files in the hProfiles.game.'DirListConf' array
sub GenConf(){
	my $sCwd  = getcwd();
	my @sDirs = &getInstallations();

	foreach my $sDir (@sDirs){
		&Em::Console::changeDir($sDir);

		my $sFolder = &getFolderName($sDir);
		if($hProfiles{$hSettings{'profile'}}{'IgnorePrimary'}){
			if(&isPrimary($sFolder)) { next; } # Skip primary installation image
		}
		my $sDirOutput = $hSettings{'dir_output'}.'/'.$hSettings{'profile'}."/$sFolder"; # /<output_directory>/<profile_name>/<image_name>
		&Em::Console::exeSysCmd('mkdir -p '.$sDirOutput); # Create folder if it does not exist

		&packFiles($sDirOutput."/$sFolder", join(' ', @{$hProfiles{$hSettings{'profile'}}{'DirListConf'}}));
	}
	&Em::Console::changeDir($sCwd);
	return;
}
# Generated a back up of each server's log files
# TODO chdir must change to absolute directory path
# (where the logs are stored)
sub GenLogArchive(){
	my $sCwd  = getcwd();
	my @sDirs = &getInstallations();

	foreach my $sDir (@sDirs){
		&Em::Console::changeDir($sDir);

		my $sFolder = &getFolderName($sDir);
		if($hProfiles{$hSettings{'profile'}}{'IgnorePrimary'}){
			if(&isPrimary($sFolder)) { next; } # Skip primary installation image
		}
		my $sDirOutput = $hSettings{'dir_output'}.'/'.$hSettings{'profile'}."/$sFolder/logs";
		&Em::Console::exeSysCmd('mkdir -p '.$sDirOutput);

		&packFiles($sDirOutput."/log-$sFolder-".&Em::Console::getDate(), $hProfiles{$hSettings{'profile'}}{'DirLogs'});
	}
	&Em::Console::changeDir($sCwd);
	return;
}
# Generates a payload image from the primary installation
# Includes all files in the hProfiles.game.DirListPayload 
# array
sub GenPayload(){
	my $sCwd = getcwd();

	&Em::Console::changeDir($hProfiles{$hSettings{'profile'}}{'DirImage'}.'/'.$hProfiles{$hSettings{'profile'}}{'ImagePrefix'}.$hProfiles{$hSettings{'profile'}}{'PrimaryImage'});
	if(scalar @{$hProfiles{$hSettings{'profile'}}{'DirListPayload'}}){
		my $sDirOutput = $hSettings{'dir_output'}.'/'.$hSettings{'profile'};
		&Em::Console::exeSysCmd('mkdir -p '.$sDirOutput);

		&packFiles($sDirOutput."/em_payload-".$hSettings{'profile'}.'-'.&Em::Console::getDate(), join(' ', @{$hProfiles{$hSettings{'profile'}}{'DirListPayload'}}));
	}
	else { &printError($hErrorMessages{'error_dirlist_empty'}, __FILE__.':'.__LINE__); }
	&Em::Console::changeDir($sCwd);
}
# Applies a .tar.gz patch archive to all installation images
sub PatchAll(){
	if(@_ == 1){
		my($sArchiveName) = @_;
		my @sDirs = &getInstallations();
		my $iNumImages = scalar @sDirs;
		if($iNumImages > 0){
			$sArchiveName = &getPatchDir($sArchiveName);
			&listContents($sArchiveName);
			print("Apply patch ? (y/n) -> ");
			my $sUsrReply = <>;
			if($sUsrReply =~ /^[Y]?$/i){
				foreach my $sDir (@sDirs){ &unpackFiles($sArchiveName, $sDir); }
			}
			else { &printError($hErrorMessages{'abort_patching'}, __FILE__.':'.__LINE__); return; }
		}
		else { &printError($hErrorMessages{'dne_image'}, __FILE__.':'.__LINE__); }
	}
	else { &printError($hErrorMessages{'invalid_archive_name'}, __FILE__.':'.__LINE__); }
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
		$sArchiveName = &getPatchDir($sArchiveName);
		if(&Em::Console::dirExists($sDestination)){
			&unpackFiles($sArchiveName, $sDestination);
		}
		else { &printError($hErrorMessages{'dne_primary'}, __FILE__.':'.__LINE__); }
	}
	else { &printError($hErrorMessages{'invalid_num_arg'}, __FILE__.':'.__LINE__); }
	return;
}
# Updates a value in the %hSettings hash.
sub SetUpdaterCvar(){
	if(@_ == 2){
		my($sSetting, $sNewValue) = @_;

		if (exists $hSettings{$sSetting}){
			if($sSetting eq 'profile'){
				if(!exists $hProfiles{$sNewValue}){ &printError($hErrorMessages{'dne_profile'}, __FILE__.':'.__LINE__); }
				else { $hSettings{$sSetting} = $sNewValue; }
			}
			else { $hSettings{$sSetting} = $sNewValue; }
		}
		else { &printError($hErrorMessages{'dne_cvar'}, __FILE__.':'.__LINE__); }
	}
	else { &printError($hErrorMessages{'invalid_num_arg'}, __FILE__.':'.__LINE__); }
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
# Terminates the application
sub pExit(){
	&Em::Console::Exit();
}

#####################
##   HL Commands   ##
#####################

# Respawns an image. Requires an image suffix to be passed as a parameter
sub RespawnImage(){
	if(@_ == 1){
		my($sImageSuffix) = @_;
		my $sDestination  = $hProfiles{$hSettings{'profile'}}{'DirImage'}.'/'.
				    $hProfiles{$hSettings{'profile'}}{'ImagePrefix'}.
				    $sImageSuffix;
		if(&Em::Console::dirExists($sDestination)){
			# Backup configuration image
			&printStatus("Generating configuration image");
			GenConf();
			# Backup logs
			&printStatus("Generating log archive");
			GenLogArchive();

			rmtree($sDestination);
			&SpawnImage($sImageSuffix);

			my $sDirOutput 	= $hSettings{'dir_output'}.'/'.$hSettings{'profile'}.'/'.&getFolderName($sDestination);
			my $sPatchImage = $sDirOutput.'/'.&getFolderName($sDestination).".tar.gz";

			if(-e $sPatchImage){
				if($hSettings{'auto_patch'} != 1){
					print("Patch image ($sPatchImage) found. Apply patch? (Y/N)\n");
					my $sUsrReply = <>;
					unless($sUsrReply =~ /^[Y]?$/i){
						&printError($hErrorMessages{'abort_patching'}, __FILE__.':'.__LINE__);
						return;
					}
				}
				&PatchImage($sPatchImage, $sImageSuffix);
				&printStatus("Patch applied");
			}
			else { &printError($hErrorMessages{'dne_conf_archive'}, __FILE__.':'.__LINE__); }
		}
		else { &printError($hErrorMessages{'dne_image'}, __FILE__.':'.__LINE__); return; }
	}
	else { &printError($hErrorMessages{'invalid_num_arg'}, __FILE__.':'.__LINE__); }
	return;
}

#####################
## SteamCMD Wrap   ##
#####################

##
# Engine based functions
##

# Returns location of the SteamCMD.sh if SteamCMD is found. Otherwise returns false.
sub checkSteamCmd(){
	my $sCmdDir = $hSettings{'dir_steamcmd'}.$hSettings{'exe_steamcmd'};

	if(&Em::Console::fileExists($sCmdDir)){
		return $sCmdDir;
	}
	else { &printError($hErrorMessages{'dne_steamcmd'}, __FILE__.':'.__LINE__); }
	return 0;
}
#
sub InstallSteamCmd(){ # Incomplete
	my $sCmdDir = $hSettings{'dir_steamcmd'};
	&Em::Console::exeSysCmd('mkdir -p '.$sCmdDir);
	&Em::Console::exeSysCmd('wget '.$hDownloads{'url_steamcmd'}.' -O steamcmd.tar.gz');
	&unpackFiles('steamcmd.tar.gz', $hSettings{'dir_steamcmd'});
	return;
}

##
# Wrapper functions
##

# Passes commands to SteamCMD to update server file installations
sub UpdateServerFiles(){
	my $sCmdDir = &checkSteamCmd() or do{ &printError($hErrorMessages{'error_steamcmd_update'}, __FILE__.':'.__LINE__); return; };

	my $sPrimaryImage = &getPrimaryImagePath();
	if(&Em::Console::dirExists($sPrimaryImage)){
		my $sAppId = $hProfiles{$hSettings{'profile'}}{'AppId'};
		&Em::Console::exeSysCmd("sh $sCmdDir +login anonymous +force_install_dir $sPrimaryImage +app_update $sAppId +quit");
	} #TODO: Ask user if he wishes to install the game files if no installation is found
	else { &printError($hErrorMessages{'dne_primary'}, __FILE__.':'.__LINE__); }
	return;
}
# Creates missing folders required to install the files for a primary image; then calls the &UpdateServerFiles()
# function in order to download the necessary files
sub InstallServerFiles(){
	my $sCmdDir = &checkSteamCmd() or do{ &printError($hErrorMessages{'error_steamcmd_update'}, __FILE__.':'.__LINE__); return; };

	my $sPrimaryImage = &getPrimaryImagePath();
	unless(&Em::Console::dirExists($sPrimaryImage)){
		&printError($hErrorMessages{'dne_primary'}, __FILE__.':'.__LINE__);

		&printStatus("Creating directory");
		&Em::Console::exeSysCmd('mkdir -p '.$sPrimaryImage);

		&printStatus("Installing server files");
		&UpdateServerFiles();
	}
	else { &UpdateServerFiles(); }
	return;
}
