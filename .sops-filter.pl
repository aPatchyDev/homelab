#!/usr/bin/env perl

use strict;
use IPC::Open2;
use IPC::Open3;
binmode STDIN;
binmode STDOUT;
undef $/;

my $mode = shift @ARGV or die "Mode (clean/smudge) required\n";
my $file = shift @ARGV or die "Filename required\n";
my $input = <STDIN>;

sub run_sops {
	my ($data, $flag) = @_;
	my $pid = open2(my $out, my $in, "sops", $flag, "--filename-override", $file, "/dev/stdin");
	binmode $in;
	binmode $out;
	print $in $data;
	close $in;
	my $result = <$out>;
	close $out;
	waitpid($pid, 0);
	my $status = $? >> 8;
	if ($status != 0) {
		die "Error: SOPS exited with $status\n";
	}
	return $result;
}

if ($mode eq "smudge") {
	print run_sops($input, "-d");
} elsif ($mode eq "clean") {
	my $head_enc = "";
	open(my $null, ">", "/dev/null");
	my $pid = open3(undef, my $git_fh, $null, "git", "cat-file", "-p", "HEAD:$file");
	binmode $git_fh;
	$head_enc = <$git_fh>;
	close $git_fh;
	close $null;

	if (length($head_enc) > 0 && run_sops($head_enc, "-d") eq $input) {
		print $head_enc;
	} else {
		print run_sops($input, "-e");
	}
} else {
	die "Unknown mode: $mode\n";
}
