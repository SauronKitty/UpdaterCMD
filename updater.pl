#!/usr/bin/perl

use Cwd;

#####################
## Default Profile ##
#####################

$sImageDir 	= "/home/evilmaniac/Documents/updater-test";
$sDirPrefix 	= "l4d2_";
$sPrimaryImage 	= "00";

# FileLists should not contain a forward slash at the beginning
# e.g:
# Instead of using "./direcotry/xyz" use "directory/xyz"

$sLogFileDir = "left4dead2/addons/sourcemod/logs";

@sConfigFileList = (
	"start*",
	"left4dead2/addons/sourcemod/configs/sourcebans/sourcebans.cfg",
	"left4dead2/cfg/Server.cfg"
);

@sPayloadFileList = (
	"left4dead2/addons",
	"left4dead2/cfg/em_cfg",
	"left4dead2/cfg/Server.cfg",
	"left4dead2/cfg/sourcemod",
	"left4dead2/em_motd.txt",
	"left4dead2/em_host.txt"
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
	'version'	  => 0.6,
	'sys_name'	  => 'eM-UpdaterCMD',
	'tar_verbose'	  => 1,
	'console_prefix'  => 'UpdaterCMD',
	'error_prefix'	  => 'Error',
	'error_seperator' => ': ',
);

&CommandInput();

#############
## Console ##
#############

sub CommandInput(){
	print $hSettings{'console_prefix'}." -> ";
	my $usrCommand = <>;
	$usrCommand =~ s/[\$#@~!&*;,?^\|`\\]+//g; # Filter un-wanted symbols to avoid
						  # accidental command injection
        &ProcessCommand($usrCommand);
}

sub ProcessCommand(){
	my($usrInput) = $_[0];
	$usrInput =~ s/\n//;

	my(@usrTokens) = split(/\s+/,$usrInput);
	$usrCommand = shift(@usrTokens);

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
	my($sArchiveName, $sFiles) = @_;
	my $sFlags;

	if($hSettings{'tar_verbose'}) { $sFlags = '-zcvf'; }
	else { $sFlags = 'zcf'; }

	&exeSysCmd("tar $sFlags $sArchiveName.tar.gz $sFiles");
	return;
}
# extracts given tar archive at required destination
sub unpackFiles(){
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
# returns a list of all installation images
sub getInstallations(){
	return <$sImageDir/$sDirPrefix*>;
}
# prints an error message to the user
sub printError(){
	my($sErrorMsg) = @_;
	print($hSettings{'error_prefix'}.$hSettings{'error_seperator'}.$sErrorMsg."\n");
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
	if($sDirName eq $sDirPrefix.$sPrimaryImage){ return 1; } 
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
# Lists all installations in the $sImageDir directory including
# primary installation and all forked installations
##
sub ListInstallations(){
	my @sDirs = getInstallations();
	foreach $sDir (@sDirs){
		print($sDir."\n");
	}
	return;
}

sub Echo(){
	foreach my $Token (@_){ print $Token." "; }
	print "\n";
	return;
}
##
# Generates configuration file images from the forked installation
# images. Includes all files in the @sConfigFileList array
##
sub GenConf(){
	my $sCwd  = getcwd();
	my @sDirs = &getInstallations();

	foreach my $sDir (@sDirs){
		chdir($sDir);

		$sDir =~ /^.+\/(.+)$/; # Calculate image number e.g. l4d2_XX where XX is the image number
		if(&isPrimary($1)) { next; } # Skip primary installation image
		&packFiles("$sCwd/$1", join(' ', @sConfigFileList));
	}
	chdir($sCwd);
	return;
}
###
# Generated a back up of each server's log files
# TODO chdir must change to absolute directory path (where the logs are stored)
###
sub GenLogArchive(){
	my $sCwd  = getcwd();
	my @sDirs = &getInstallations();

	foreach my $sDir (@sDirs){
		chdir($sDir);

		$sDir =~ /^.+\/(.+)$/; # Calculate image number e.g. l4d2_XX where XX is the image number
		if(&isPrimary($1)) { next; } # Skip primary installation image
		&exeSysCmd("mkdir -p $sCwd/logs/$1");
		&packFiles("$Cwd/logs/$1/log-$1-".&getDate(), "-C $sLogFileDir");
	}
	chdir($sCwd);
	return;
}
##
# Generates a payload image from the primary installation
# Includes all files dictated in the @sPayloadFileList array
##
sub GenPayload(){
	my $sCwd = getcwd();

	chdir($sImageDir.'/'.$sDirPrefix.$sPrimaryImage);
	&packFiles("$sCwd/em_payload-".&getDate(), join(' ', @sPayloadFileList));
	chdir($sCwd);
}
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
        print("Terminating. . .\n");
	exit(0);
}
