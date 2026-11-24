# Unpacks sources from a saved Studio MCP result (json) onto disk: perl tools/FromStudio.pl result.json
# The result holds, per file:  @@FILE path/on/disk.luau \n source @@END   (padded past 50 KB so it is saved to a file).
use strict;
local $/;
open my $h, '<:raw', $ARGV[0] or die $!;
my $t = <$h>;
close $h;
my %m = (n => "\n", t => "\t", r => "\r", b => "\b", f => "\f");
while ($t =~ /\@\@FILE (\S+?)\\n(.*?)\@\@END/sg) {
	my ($f, $s) = ($1, $2);
	$s =~ s/\\(?:u([0-9a-fA-F]{4})|(.))/my $u = $1; my $c = $2; if (defined $u) { my $x = chr hex $u; utf8::encode($x); $x } else { exists $m{$c} ? $m{$c} : $c }/ges;
	open my $o, '>:raw', $f or die "$f $!";
	print $o $s;
	close $o;
	print "$f ", length $s, "\n";
}
