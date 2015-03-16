#!/bin/bash
dir="$1"
ls -- "$1"/?.txt | 
while IFS= read -r i
do
	echo "$i"
	sprfname="${i##*/}"
	sprname="spr${sprfname%.txt}"
	echo sprname="$sprname"
	# tr '0123456789:;<' '3706274331676' < "$i" |
	tr "`sed -n 1p "$dir/palette_transform.txt"`" \
	   "`sed -n 2p "$dir/palette_transform.txt"`" \
	   < "$i" |
		bash ./gen_sprite.sh "$sprname" >"$dir/$sprfname".tmp.crs
done

#bash ../gen_sprite.sh spr9 <9-2.txt >9.txt.crs
