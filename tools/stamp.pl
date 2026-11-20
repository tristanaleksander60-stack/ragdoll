#!/usr/bin/perl
# V8-6.2 (build stamp and sync check): writes ServerScriptService/Server/BuildStamp.luau, the manifest
# of every synced script: its Studio path and an FNV-1a 32-bit checksum of its text (carriage
# returns left out, so a CRLF file and its Studio Source agree). tools/SyncCheck.luau computes the
# same in Studio and lists every script that differs or is missing. Run from the repo root:
#   perl tools/stamp.pl
use strict;
use warnings;
use File::Find;

my %roots = (
	"ServerScriptService" => "ServerScriptService",
	"ReplicatedStorage/ReplicatedStorage" => "ReplicatedStorage",
	"StarterPlayerScripts/StarterPlayerScripts" => "StarterPlayer.StarterPlayerScripts",
);

sub fnv {
	my ($text) = @_;
	my $h = 2166136261;
	for my $c (unpack("C*", $text)) {
		next if $c == 13;
		$h ^= $c;
		$h = ($h * 16777619) & 0xFFFFFFFF;
	}
	return $h;
}

my %entries;
for my $dir (sort keys %roots) {
	my $prefix = $roots{$dir};
	find(
		{
			no_chdir => 1,
			wanted => sub {
				my $f = $File::Find::name;
				return unless $f =~ /\.luau$/;
				return if $f =~ /BuildStamp\.luau$/;
				my $rel = substr($f, length($dir) + 1);
				$rel =~ s/\.(server|local)\.luau$//;
				$rel =~ s/\.luau$//;
				$rel =~ s{/}{.}g;
				open(my $in, '<:raw', $f) or die "$f: $!";
				local $/;
				my $text = <$in>;
				close $in;
				$entries{"$prefix.$rel"} = fnv($text);
			},
		},
		$dir
	);
}

my $commit = `git rev-parse --short HEAD`;
chomp $commit;
my @t = gmtime();
my $made = sprintf("%04d-%02d-%02d %02d:%02d UTC", $t[5] + 1900, $t[4] + 1, $t[3], $t[2], $t[1]);
open(my $out, '>:raw', "ServerScriptService/Server/BuildStamp.luau") or die $!;
print $out "--!strict\n";
print $out "-- V8-6.2 (build stamp): written by tools/stamp.pl, never by hand. The commit this build sits on,\n";
print $out "-- when it was made, and every synced script's checksum (tools/SyncCheck.luau compares them).\n";
print $out "return table.freeze({\n";
print $out "\tcommit = \"$commit\",\n";
print $out "\tmade = \"$made\",\n";
print $out "\tscripts = table.freeze({\n";
for my $k (sort keys %entries) {
	print $out "\t\t[\"$k\"] = $entries{$k},\n";
}
print $out "\t}),\n";
print $out "})\n";
close $out;
printf "stamped %d scripts on %s\n", scalar(keys %entries), $commit;
