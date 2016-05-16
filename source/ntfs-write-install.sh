# !/bin/bash
#
# NTFS Write - Installer / Uninstaller
#
# By The Fan Club 2016
# http://www.thefanclub.co.za
#
### BEGIN LICENSE
# Copyright (c) 2016, The Fan Club <info@thefanclub.co.za>
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranties of
# MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
# PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.
### END LICENSE
#
### NOTES 
#
# Dependencies : diskutil mount 
#
# Program packaged with Platypus - http://sveinbjorn.org/platypus
#
# To run script make executable with: sudo chmod +x ntfs-write-install.sh
# and then run with: sudo ntfs-write-install.sh
#
### Vars
apptitle="NTFS Write - Installer"
version="1.4 beta"
appversion=$( echo $version | awk {'print $1'})
export LC_ALL=en_US.UTF-8
mountpath="/Volumes"
currentuser=$( stat -f%Su /dev/console )
userhome=$( eval echo "~$currentuser" )
userdesktop="$userhome/Desktop"
launchdaemonpath="/Library/LaunchDaemons/co.za.thefanclub.ntfs-write.plist"
launchdaemonfile="co.za.thefanclub.ntfs-write.plist"

ntfswritepath="/usr/local/bin/ntfs-write.sh"
ntfswritefile="ntfs-write.sh"

appoldversion=$( cat "$ntfswritepath" | grep "version=" | cut -d"\"" -f2 | awk {'print $1'} )

action=""

# Set Icon directory and file 
iconfile="/System/Library/Extensions/IOStorageFamily.kext/Contents/Resources/Removable.icns"

echo "NTFS Write Installer Started" 

# Select Backup or Restore if not in args
echo "Select Install | Update | Uninstall"
echo "PROGRESS:10"
if [ ! "$action" ] ; then
  if [ -f "$ntfswritepath" ] ; then
    # Check for update
    vercheck=$(echo "$appversion > $appoldversion" | bc -l)
    if (( "$vercheck" )) ; then
      # Update
      response=$(osascript -e 'tell app "System Events" to display dialog "Click Update to install NTFS Write version '"$version"' on your system.\n\nSelect Cancel to Quit" buttons {"Cancel", "Update"} default button 2 with title "'"$apptitle"' '"$version"'" with icon POSIX file "'"$iconfile"'"  ')
    else
      # Uninstall
      response=$(osascript -e 'tell app "System Events" to display dialog "Click Uninstall to remove NTFS Write from your system.\n\nSelect Cancel to Quit" buttons {"Cancel", "Uninstall"} default button 2 with title "'"$apptitle"' '"$version"'" with icon POSIX file "'"$iconfile"'"  ')
    fi
  else
    # Install
    response=$(osascript -e 'tell app "System Events" to display dialog "Click Install to setup NTFS Write on your system.\n\nSelect Cancel to Quit" buttons {"Cancel", "Install"} default button 2 with title "'"$apptitle"' '"$version"'" with icon POSIX file "'"$iconfile"'"  ')
  fi
  action=$(echo $response | cut -d ':' -f2)

  if [ ! "$action" ] ; then
    echo "Program cancelled"
    exit 0
  fi
fi
 
### INSTALL 
if [ "$action" == "Install" ] || [ "$action" == "Update" ] ; then
  echo "Installing ..."
  # Copy Launch Daemon into place
  cp "$launchdaemonfile" "$launchdaemonpath"
  # Copy NTFS Write into place
  # Check dir exists
  if [ ! -d "$(dirname $ntfswritepath)" ]; then
    mkdir $(dirname $ntfswritepath)
  fi
  # Copy file 
  cp "$ntfswritefile" "$ntfswritepath"
  # Set permissions and ownership
  chmod +x "$ntfswritepath"
  chown root:wheel "$launchdaemonpath"
  chmod 644 "$launchdaemonpath"
  # Load service
  #launchctl load -w "$launchdaemonpath"
  # Check if installed failed
  if [ ! -f "$ntfswritepath" ] || [ ! -f "$launchdaemonpath" ]; then
    response=$(osascript -e 'tell app "System Events" to display dialog "NTFS Write '"$action"' failed.\n\nPlease make sure you have administator rights to install this software." buttons {"Done"} default button 1 with title "'"$apptitle"' '"$version"'" with icon POSIX file "'"$iconfile"'"  ')
    exit 0
  fi

  # Reboot or not
  if [ "$action" == "Install" ]; then
    response=$(osascript -e 'tell app "System Events" to display dialog "NTFS Write install complete.\n\nWhen you attach or insert NTFS formatted media\nNTFS Write will prompt for remounting the volume with full read and write access. \n\nYou have to Reboot to complete the setup." buttons {"Later", "Reboot"} default button 2 with title "'"$apptitle"' '"$version"'" with icon POSIX file "'"$iconfile"'"  ')
    # Reboot if needed
    action=$(echo $response | cut -d ':' -f2)
    if [ "$action" == "Reboot" ] ; then
      reboot 
    fi
  fi

  if [ "$action" == "Update" ]; then
    response=$(osascript -e 'tell app "System Events" to display dialog "NTFS Write update complete.\n\n" buttons {"Done"} default button 1 with title "'"$apptitle"' '"$version"'" with icon POSIX file "'"$iconfile"'"  ')
  fi
fi

### Un INSTALL 
if [ "$action" == "Uninstall" ] ; then
  echo "UN-Installing ..."
  # Unload launchd service
  launchctl unload "$launchdaemonpath"
  rm "$ntfswritepath"
  rm "$launchdaemonpath"
  osascript -e 'tell app "System Events" to display dialog "NTFS Write uninstall complete.\n\nAll files and settings removed." buttons {"Done"} default button 1 with title "'"$apptitle"' '"$version"'" with icon POSIX file "'"$iconfile"'"  '
fi

echo "Done"
exit 0

