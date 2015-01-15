#!/bin/bash
pngtopnm "$1" | perl -e '
readline eq "P6\n" or die "not a p6 PNM"; 
($w,$h)=split(" ", readline); 
readline eq "255\n" or die "wrong color depth";
$letter=0x30;
binmode STDIN;

sub add
{
	$letter;
	my $color = $_[0];
	$type{chr($letter)}=$color;
	return chr $letter++;
}

sub cmpr
{
	my $color = $_[0];
	TYPE: for $l (keys %type)
	{
		if ($type{$l} eq $color)
		{
	#		print "\nmatches $l";
			return $l;
		}
	}
#	print "\nadded new";
	return add $color
}

for ($ln=0; $ln<$h; $ln++)
{
	for ($px=0; $px<$w; $px++)
	{
		read(STDIN, $buf, 3);
		print cmpr($buf);
	}
	print "\n";
}
'
