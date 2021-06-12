#!/bin/sh

#
# Copies media files listed in a Plex Playlist to Android and
# creates an m3u playlist and copies that to the phone also.
#
# Copyright (c) September 27 2018 Terry Carmen, MIT Licence
#
# terry@bupkis.org
#
# No plexpass or login required.
#
# Dependencies: adb, sqlite, grep, cut & "USB debugging" enabled on phone
#
# Note: After copying, reboot your phone.
# Mine only rescans the music at boot for some reason.#
#

##################################################################
# UPDATE THIS TO POINT TO WHEREVER YOUR MUSIC LIVES ON YOUR PHONE
# UPDATE THIS TO POINT TO WHEREVER YOUR MUSIC LIVES ON YOUR PHONE
# UPDATE THIS TO POINT TO WHEREVER YOUR MUSIC LIVES ON YOUR PHONE
# UPDATE THIS TO POINT TO WHEREVER YOUR MUSIC LIVES ON YOUR PHONE

android_music_dir="Files/"
playlist_folder="Playlists/"

# UPDATE THIS TO POINT TO WHEREVER YOUR MUSIC LIVES ON YOUR PHONE
# UPDATE THIS TO POINT TO WHEREVER YOUR MUSIC LIVES ON YOUR PHONE
# UPDATE THIS TO POINT TO WHEREVER YOUR MUSIC LIVES ON YOUR PHONE
# UPDATE THIS TO POINT TO WHEREVER YOUR MUSIC LIVES ON YOUR PHONE
##################################################################

#####################################################
#
# Nothing below this line needs changing
#
#####################################################

#####################################################
# Figure out where plex keeps it's db files.
#####################################################

#plexhome=`grep plex /etc/passwd |cut -d":" -f6`
plexhome="/share/CACHEDEV1_DATA/Container/Media-Managment/Plex/config"
database="$plexhome/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"

if [ ! -d "$playlist_folder" ]; then
  # Take action if $DIR exists. #
  mkdir $playlist_folder
fi

# this figures out what playlists exist and lists them, when run with no parameters
SQL=" \
	SELECT COUNT(*) FROM media_parts \
	LEFT OUTER JOIN media_items on media_items.id = media_parts.media_item_id \
	LEFT OUTER JOIN play_queue_generators on play_queue_generators.metadata_item_id = media_items.metadata_item_id \
	LEFT OUTER JOIN metadata_items on metadata_items.id = play_queue_generators.playlist_id \
	WHERE metadata_items.title = '$1';"
records=$(sqlite3 "$database" "$SQL")

#echo $1
if [[ "$1" == -*h* ]] || [[ "$2" == -*h* ]]; then
	echo "Usage: PlexExport.sh [OPTION] [\"Playlist Name in Quotes\"]"
	echo "Mandatory arguments to long options are mandatory for short options too."
	echo "-a, --all         export all Playlists"
	echo "-c, --copy        copy actually the files"
	echo "-h, --help	  open this help menu"
	echo ""
elif [[ "$1" == -*a* ]] || [[ "$2" == -*a* ]]; then
	#declare -a playlists=()

	echo "Ok I will download all these:"
	SQL=" \
	SELECT DISTINCT metadata_items.title \
	FROM media_parts \
	LEFT OUTER JOIN media_items on media_items.id = media_parts.media_item_id \
	LEFT OUTER JOIN play_queue_generators on play_queue_generators.metadata_item_id = media_items.metadata_item_id \
	LEFT OUTER JOIN metadata_items on metadata_items.id =	play_queue_generators.playlist_id;"

	IFS=$'\n' playlists=($(sqlite3 "$database" "$SQL"))

	#readarray -t playlists < <( $( sqlite3 "$database" "$SQL" ) )

	for i in "${playlists[@]}"; do
		echo "$i"
	done
	#echo ${playlists[0]}

	#for it in $( sqlite3 "$database" "$SQL" ); do
	#	echo "$it"
	#	playlists+="$it"
	#done
	#while read -r playlist; do
	echo ""
else
	#[ "$records" -eq "0" ]; then
	echo "Usage: PlexExport.sh [OPTION] [\"Playlist Name in Quotes\"]"
	echo "Mandatory arguments to long options are mandatory for short options too."
	echo "-a, --all         export all Playlists"
	echo "-c, --copy        copy actually the files"
	echo "-h, --help	  open this help menu"
	echo ""
	echo "Valid Playlists are:"

	SQL=" \
	SELECT DISTINCT metadata_items.title \
	FROM media_parts \
	LEFT OUTER JOIN media_items on media_items.id = media_parts.media_item_id \
	LEFT OUTER JOIN play_queue_generators on play_queue_generators.metadata_item_id = media_items.metadata_item_id \
	LEFT OUTER JOIN metadata_items on metadata_items.id =	play_queue_generators.playlist_id;"

	sqlite3 "$database" "$SQL"
	echo ""
fi

for i in "${playlists[@]}"; do
	if [[ "$1" == -*c* ]] || [[ "$2" == -*c* ]]; then
		#####################################################
		# Copy the files to the phone
		#####################################################
		SQL=" \
	SELECT
	replace( file, '\', '\\') as path
	FROM media_parts
	LEFT OUTER JOIN media_items on media_items.id = media_parts.media_item_id
	LEFT OUTER JOIN play_queue_generators on play_queue_generators.metadata_item_id = media_items.metadata_item_id
	LEFT OUTER JOIN metadata_items on metadata_items.id =	play_queue_generators.playlist_id
	WHERE metadata_items.title = \"$i\";"
		sqlite3 "$database" "$SQL" | while read -r line; do
			echo "Copying $line"
			adb push "$line" "$android_music_dir"
		done
	fi
	#####################################################
	# Create the playlist and copy it to the phone
	#####################################################
	SQL=" \
	SELECT
	at.title,
	s.title,
	mi.duration/1000 as seconds,
	replace(mp.file , rtrim(mp.file , replace(mp.file , '/', '')), '') as file
	FROM metadata_items as s
	INNER JOIN media_items as mi on s.id = mi.metadata_item_id
	INNER JOIN media_parts as mp on  mi.id = mp.media_item_id
	INNER JOIN play_queue_generators as pqg on pqg.metadata_item_id =	mi.metadata_item_id
	INNER JOIN metadata_items as pl on  pl.id = pqg.playlist_id
	INNER JOIN metadata_items as al on  s.parent_id = al.id
	INNER JOIN metadata_items as at on  al.parent_id = at.id
	WHERE pl.title=\"$i\";"
	echo "#EXTM3U" >"$playlist_folder/$i.m3u"
	echo "" >>"$playlist_folder/$i.m3u"
	IFS='|'
	sqlite3 "$database" "$SQL" | while read -r at ti d f; do
		echo "#EXTINF: $d, $at - $ti" >>"Playlists/$i.m3u"
		echo "$f" >>"$playlist_folder/$i.m3u"
		echo "" >>"$playlist_folder/$i.m3u"

	done
	echo "Exported: $i"
	#adb push "$i.m3u" "$android_music_dir"
done
