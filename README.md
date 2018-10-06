# PlexExport
Export Plex Playlists and Media (Music, Video, etc.) to Android

If you like it, let me know. If you don’t like it, let me know. 😎

Note that this is a bash script so it requires Linux (Redhat, Ubuntu, Fedora, Debian, etc.). 

It *might* work on Mac, since they apparently run a flavor of Linux under the covers, but I 
don't have access to a Mac and can't test it.

When I get a chance, I’ll do a Windows version if nobody else does it first.

Dependencies: 

* adb (install from your package manager)
* sqlite3 (install from your package manager)
* grep (should already be installed)
* cut (should already be installed)

Notes:

After you run it, reboot your phone. Mine only re-scans the music at boot for some reason.

**Configuration:**
* Enable “USB debugging” on your phone
* Set android_music_dir in the script to point to wherever your phone keeps it’s music

**Usage:**
* Connect your phone to your computer via USB
* Enable USB Debugging on your phone in “Developer Tools”
* Open a command prompt on your computer and run: ./PlexExport.sh with no options to show your playlists.
* Run  ./PlexExport.sh “name of your playlist in quotes”
* Reboot your phone (might be optional – mine won’t re-scan media files without a reboot)

Enjoy!

Terry
