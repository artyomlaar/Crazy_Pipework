dir="${2:-"$1".dir}"
mkdir "$dir"
pngtopnm "$1" | pnmflip -r270 | perl -e >"$dir/world.txt" '

readline eq "P6\n" or die "not a p6 PNM"; 
($w,$h)=split(" ", readline); 
readline eq "255\n" or die "wrong color depth";
$letter=32;
$cletter=0x30;
$dir="'"$dir"'";
binmode STDIN;
open (S, ">$dir/sprites.txt");

sub cadd
{
	my $color = $_[0];
	$ctype{chr($cletter)}=$color;
	return chr $cletter++;
}

sub ccmpr
{
	my $color = $_[0];
	TYPE: for my $l (keys %ctype)
	{
		if ($ctype{$l} eq $color)
		{
	#		print "\nmatches $l";
			return $l;
		}
	}
#	print "\nadded new";
	return cadd $color
}

sub add
{
	$letter;
	my $pos = $_[0];
	if ($letter == 0x2e){ $letter+=2 };
	if ($letter == 0x3a){ $letter++ };
	print S "curses:spr:spr" . chr($letter) . ":16:16\n";
	open (D, "| pnmflip -r90 | pnmtopng >$dir/\\" . chr($letter) . ".png");
	print D "P6\n";
	print D "16 16\n";
	print D "255\n";
	binmode D;
	open (C, q^| perl -e '\''@buf=(); for ($i=0;$i<16;$i++){ for ($j=0;$j<16;$j++){ read STDIN, $buf[$i][$j], 1 }; read STDIN, $b, 1 } for ($j=15;$j>=0;$j--){ for ($i=0;$i<16;$i++){ print $buf[$i][$j] }; print "\n" }'\''^ .
		">$dir/\\" . chr($letter) . ".txt");
	for ($ln=0; $ln<16; $ln++)
	{
		for ($px=$pos; $px<$pos+16; $px++)
		{
			for ($cm=0; $cm<3; $cm++)
			{
				$type{chr($letter)}[$ln][$px-$pos][$cm] = $buf[$ln][$px][$cm];
				print D $buf[$ln][$px][$cm];
				#print "added type{chr($letter)}[$ln][$px-$pos][$cm] = buf[$ln][$px][$cm] $type{chr($letter)}[$ln][$px-$pos][$cm]\n";
			}
			print C ccmpr("$buf[$ln][$px][0]" .
			"$buf[$ln][$px][1]" .
			"$buf[$ln][$px][2]");
		}
		print C "\n";
	}
	close D;
	close C;
	return chr $letter++
}

sub cmpr
{
	my $pos = $_[0];
	TYPE: for $l (keys %type)
	{
		for ($ln=0; $ln<16; $ln++)
		{
			for ($px=$pos; $px<$pos+16; $px++)
			{
				for ($cm=0; $cm<3; $cm++)
				{
#					print "type{$l}[$ln][$px-$pos][$cm] ne buf[$ln][$px][$cm]", $type{$l}[$ln][$px-$pos][$cm] ne $buf[$ln][$px][$cm], "\n";
					if ($type{$l}[$ln][$px-$pos][$cm] ne $buf[$ln][$px][$cm])
					{
						next TYPE;
					}
				}
			}
		}
#		print "\nmatches $l";
		return $l;
	}
#	print "\nadded new";
	return add $pos
}

for ($gln=0; $gln<$h; $gln+=16)
{
	for ($ln=0; $ln<16; $ln++)
	{
		for ($px=0; $px<$w; $px++)
		{
			for ($cm=0; $cm<3; $cm++)
			{
				read(STDIN, $buf[$ln][$px][$cm], 1);
				#print "read buf[$ln][$px][$cm] to $buf[$ln][$px][$cm]\n" 
			}
		}
	}

	for ($pos=0; $pos<$w; $pos+=16)
	{
		print cmpr( $pos );
	}
	print "\n";
}

open (P, "| LANG=C sort >$dir/palette.txt");
open (PT, ">$dir/palette_transform.txt");
my $ptnum=0;

for $n (keys %ctype)
{
	print P "$n = #" . unpack("x0 H6", $ctype{$n}) . "\n";
	print PT chr(0x30+$ptnum++);
}

print PT "\n";

for (my $i=0; $i<$ptnum; $i++)
{
	print PT ($i<8?chr(0x30+$i):"0");
}
print PT "\n";

close P;
close PT;
close S;
'
# read 3*$w*16; analyze;
# add 1st; while {compare current to added, if new { add } else { print code } }

