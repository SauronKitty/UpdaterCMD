#!/usr/bin/perl -w

# eM-Console
# Written by evilmaniac
# http://www.evilmania.net

package Em::Console;
use strict;

use Cwd;
use File::Path;
use Term::ANSIColor;
use Exporter qw(import);

our @EXPORT_OK = qw(exeSysCmd fileExists dirExists changeDir rmDir rmFile printError getDate DisplayHelp SetCvar);

#####################
##    Variables    ##
#####################

my %hSettings = (
	'version'	  => '0.1',
	'cmd_verbose'	  => 0,
	'error_prefix'	  => 'Error',
	'error_seperator' => ': ',
	'exit_message'	  => 'Terminating...'
);

my %hColors = (
	'error_prefix'	  => 'red',
	'exit_message'	  => 'bold',
	'help_command'	  => 'bold',
	'help_title'	  => 'underline'
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
	'error_chdir'			=> 'Unable to change directory',
	'error_rmfile'			=> 'Unable to remove file',
	'error_rmdir'			=> 'Unable to remove directpry',
	'error_cp_archive'		=> 'An error occured while copying the archive',
	'abort_steam_update'		=> 'Server file update has been aborted',
	'generic_echo_000'		=> 'Nothing to echo',
	'generic_getfoldername_000'	=> 'Unable to return folder name',
	'generic_forkimage_000'		=> 'Unable to create an installation image'
);

#####################
##      Engine     ##
#####################

# Executes a shell command
sub exeSysCmd(){
	if(@_ == 1){
		my($sCmd) = @_;
		my $sCmdOutput = `$sCmd`; # Execute $sCmd and place output inside $sCmdOutput
		if($hSettings{'cmd_verbose'}){ print($sCmdOutput); }
	}
	else { &printError($hErrorMessages{'invalid_num_arg'}, __FILE__.':'.__LINE__); }
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
			else { &printError($hErrorMessages{'not_file'}, __FILE__.':'.__LINE__); }
		}
		else { &printError($hErrorMessages{'dne_file'}, __FILE__.':'.__LINE__); }
	}
	else { &printError($hErrorMessages{'invalid_num_arg'}, __FILE__.':'.__LINE__); }
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
			else { &printError($hErrorMessages{'not_path'}, __FILE__.':'.__LINE__); }
		}
		#else { &printError($hErrorMessages{'dne_path'}, __FILE__.':'.__LINE__); }
	}
	else { &printError($hErrorMessages{'invalid_num_arg'}, __FILE__.':'.__LINE__); }
	return 0;
}
# Changes pwd to the given dir
# TODO This should not be checking if the target directory exists or not
# That check needs to be done by the caller function. This is not optimal.
sub changeDir(){
	if(@_ == 1){ # Needs update
		my($sDir) = @_;
		if(&dirExists($sDir)){
			chdir($sDir) || &printError($hErrorMessages{'error_chdir'}, __FILE__.':'.__LINE__);
			return 1;
		}
		else { &printError($hErrorMessages{'error_chdir'}, __FILE__.':'.__LINE__); }
	}
	else { &printError($hErrorMessages{'invalid_num_arg'}, __FILE__.':'.__LINE__); }
	return 0;
}
# Removes a given directory
sub rmDir(){
	if(@_ == 1){
		my($sDir) = @_;
		if(&dirExists($sDir)){
			&exeSysCmd("rm -rf $sDir");
		}
		else { &printError($hErrorMessages{'error_rmdir'}, __FILE__.':'.__LINE__); }
	}
	else { &printError($hErrorMessages{'invalid_num_arg'}, __FILE__.':'.__LINE__); }
	return;
}
# Removes a given file
sub rmFile(){
	if(@_ == 1){
		my($sFile) = @_;
		if(&fileExists($sFile)){
			&exeSysCmd("rm $sFile");
		}
		else { &printError($hErrorMessages{'error_rmfile'}, __FILE__.':'.__LINE__); }
	}
	else { &printError($hErrorMessages{'invalid_num_arg'}, __FILE__.':'.__LINE__); }
	return;
}
sub printError(){
	if(@_ == 2){
		my($sErrorMsg, $iLineNum) = @_;
		print(colored([$hColors{'error_prefix'}], $hSettings{'error_prefix'}).$hSettings{'error_seperator'}.$sErrorMsg." ($iLineNum)\n");
	} else { &printError($hErrorMessages{'invalid_num_arg'}, __FILE__.':'.__LINE__); }
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

# Updates a value in the %hSettings hash.
sub SetCvar(){
	if(@_ == 2){
		my($sSetting, $sNewValue) = @_;
		if (exists $hSettings{$sSetting}){
			$hSettings{$sSetting} = $sNewValue;
		}
		else { &printError($hErrorMessages{'dne_cvar'}, __FILE__.':'.__LINE__); }
	}
	else { &printError($hErrorMessages{'invalid_num_arg'}, __FILE__.':'.__LINE__); }
	return;
}
# Displays each command currently available
sub DisplayHelp(){
	if(@_ == 3){
		my($sSysName, $sSysVersion) = @_; my %hFunctionHash = %{$_[2]};
		print $sSysName.' | v'.$sSysVersion."\n".colored([$hColors{'help_title'}], 'Commands').":\n";
		foreach my $Key (keys %hFunctionHash){
		printf("- %s: %s\n", colored([$hColors{'help_command'}], $Key), $hFunctionHash{$Key}{'Description'});
		}
	} else { &printError($hErrorMessages{'invalid_num_arg'}, __FILE__.':'.__LINE__); }
	return;
}
# Displays all arguments passed onto a cmd. Used for debugging
# purposes.
sub Echo(){
	if(@_ > 0){
		foreach my $Token (@_){ print $Token.' '; }
		print "\n";
	}
	else { &printError($hErrorMessages{'generic_echo_000'}, __FILE__.':'.__LINE__); } # Nothing to echo
	return;
}
# Terminates the application
sub Exit(){
	print(colored([$hColors{'exit_message'}], $hSettings{'exit_message'})."\n");
	exit(0);
}
