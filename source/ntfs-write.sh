#! /bin/bash
#
# NTFS Write 
# Enable native OS X Read & Write support for NTFS formated storage media 
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
# To run script make executable with: sudo chmod +x ntfs-write.sh
# and then run with: sudo ntfs-write.sh
#
### Vars
apptitle="NTFS Write"
version="1.4 beta"
export LC_ALL=en_US.UTF-8
mountpath="/Volumes"
currentuser=$( stat -f%Su /dev/console )
userhome=$( eval echo "~$currentuser" )
userdesktop="$userhome/Desktop"

echo "NTFS Write Started" 
#echo "PROGRESS:0"

# Set Icon directory and file 
iconfile="/System/Library/Extensions/IOStorageFamily.kext/Contents/Resources/Removable.icns"
action="Enable"

# Check if Disk Dev was dropped
if [ "$(dirname "$1")" == "$mountpath" ] ; then
   memcard=$( df | grep "$mountpath" | awk {'print $1'} | grep "\/dev\/" )
   ntfscheck=$( diskutil info "$1" | grep "File System Personality" | awk {'print $4'} )
   readonlycheck=$( diskutil info "$1" | grep "Read-Only Volume" | awk {'print $3'} )

   if [ "$memcard" ] && [ "$ntfscheck" == "NTFS" ] && [ "$readonlycheck" == "Yes" ] ; then
     devdisk=$( echo $memcard )
     action="Enable"
   fi
fi

# Remove Desktop old Shortcuts if present
# Generate list of shortcuts
shortcuts=$( ls -l "$userdesktop" | grep "\-> \/Volumes" )
countshortcuts=$( echo "$shortcuts" | wc -l )
# check each shortcut if it is still valid and remove if needed
if [ "$shortcuts" ] ; then
  IFS='
  '
  for item in "$shortcuts" ; do
      volume=$( echo "$item" | cut -d'>' -f2 | xargs )
      symlink=$( basename "$volume" )
      if [ ! -d "$volume" ] ; then
        rm "$userdesktop/$symlink"
      fi
    done
fi

# Select Disk Volume Dialog
function getdevdisk () {
  # Check for mounted devices in user media folder
  # Parse memcard disk volume Goodies
  memcard=$( df | grep "$mountpath" | awk {'print $1'} | grep "\/dev\/" )
  # Get dev names of drive - remove partition numbers
  checkdev=$( echo $memcard  )
  # Remove duplicate dev names
  devdisks=$( echo $checkdev | xargs -n1 | sort -u | xargs )
  # How many devs found
  countdev=$( echo $devdisks | wc -w )
  # Retry detection if no media found
  if [ $countdev -eq 0 ] ; then
    exit 1
  fi

  # Generate select Dialog 
  devitems=""
  # Generate list of devices
  for (( c=1; c<=$countdev; c++ ))
    do
      devitem=$( echo $devdisks | awk -v c=$c '{print $c}')
      drivesizehuman=$( diskutil info $devitem | grep "Total\ Size" | awk {'print $3" "$4'} )
      disknum=$( diskutil info "$devitem" | grep "Device Node" | awk {'print $3'} | grep "\/dev\/" )
      diskname=$( diskutil info "$devitem" | grep "Volume Name" | cut -d ":" -f2 | xargs)
      ntfscheck=$( diskutil info "$devitem" | grep "File System Personality" | awk {'print $4'} )
      readonlycheck=$( diskutil info "$devitem" | grep "Read-Only Volume" | awk {'print $3'} )
      protocol=$( diskutil info "$devitem" | grep "Protocol" | awk {'print $2'} )
      location=$( diskutil info "$devitem" | grep "Device Location" | awk {'print $3'} )

      # Only select NTFS volumes that are read only
      if [ "$ntfscheck" == "NTFS" ] && [ "$readonlycheck" == "Yes" ] ; then
         # Create List of "item","item","item" for select dialog
         devitems=$devitems"\"\t$drivesizehuman \t\t$diskname \t$protocol $location \t\t$disknum\""
         # Add comma if not last item
         if [ $c -ne $countdev ] ; then
          devitems=$devitems","
         fi
      fi
  done

  if [ "$devitems" ] ; then
    # Select Dialog
    devselect="$( osascript -e 'tell application "System Events" to activate' -e 'tell application "System Events" to return (choose from list {'"$devitems"'} with prompt "Select a NTFS Volume to remount Read & Write" with title "'"$apptitle"' " OK button name "Continue" cancel button name "Cancel")')"
    # get dev value back from devselect
    devdisk=$( echo $devselect | rev | awk '{print $1}' | rev )
    # Return value or false
    echo $devdisk
  fi
}

### ENABLE RW
if [ "$action" == "Enable" ] ; then

  # Check if volume was dropped already
  if [ ! "$devdisk" ] ; then
  	# Get memcard device name
    echo "Select your NTFS Volume"
    #echo "PROGRESS:20"
    # Select Disk Volume
    devdisk=$( getdevdisk )
    echo $devdisk
  fi
  
  # Cancel if no disk selected
  if [ ! "$devdisk" ] || [ "$devdisk" == "false" ]; then
    echo "No NTFS Read-Only Volumes Selected. Nothing to do."
    exit 0
  fi
 
  # Get the Volume Name
  diskname=$(diskutil info "$devdisk" | grep "Volume\ Name" | cut -d ":" -f2 | xargs)
  # Unmount Volume
  diskutil umount "$devdisk"
  # Create Mountpoint 
  if [ ! -d "$mountpath/$diskname" ] ; then
    mkdir "$mountpath/$diskname"
  fi
  # Remount Read Write Finally (SUDO)
  mount -t ntfs -o rw,auto,nobrowse "$devdisk" "$mountpath/$diskname" && echo "$diskname has been re-mounted Read & Write"
  # Check RW active
  readonlycheck=$( diskutil info "$devdisk" | grep "Read-Only Volume" | awk {'print $3'} )
  if [ "$readonlycheck" == "No" ] ; then
    # Notification
    # Create desktop shortcut
    ln -s "$mountpath/$diskname" "$userdesktop"
    # Open folder
    osascript -e 'tell application "Finder" to open ("'"$mountpath/$diskname"'" as POSIX file) '

  else
    # Display dialog if we cannot remount RW
    osascript -e 'tell app "System Events" to display dialog "Could not re-mount '"$diskname"' \nin Read & Write mode." buttons {"Ok"} default button 1 with title "'"$apptitle"' '"$version"'" with icon POSIX file "'"$iconfile"'"  '
  fi
  
fi
