#!/bin/bash

diff(){
    awk 'BEGIN{RS=ORS=" "}
        {NR==FNR?a[$0]++:a[$0]--}
        END{for(k in a)if(a[k])print k}' <(echo -n "${!1}") <(echo -n "${!2}")
}

is_file_exists(){
    local f="$1"
    [[ -f "$f" ]] && return 0 || return 1
}

usage(){
    echo "Usage: $0 input.img.xz"
    echo "Supported images are $(tput bold)only$(tput sgr0) in the .img.xz format."
    exit 1
}

# Checking the user did things right

if [ "$EUID" -ne 0 ]
then
    echo "Please run as root! (aka, with sudo)"
    exit 1
fi

if ( ! is_file_exists usb_flasher)
then
    echo "Please make the project before you execute this script!"
    exit 1
fi

if [[ $# -ne 1 ]]
then
    echo "You did not provide an image to flash! This script must be ran with an image as the first (and only) argument."
    exit 1
else
    input=$1
fi

if ( ! is_file_exists "$input" )
then
    echo "Your image doesn't exist! Please provide a real file to flash."
    usage
    exit 1
fi

# Actually starting to do stuff
echo
echo "We're going to flash your BeagleBone with the image from $input"
echo "Please do not insert any USB Sticks or mount external drives during the procedure or bad things may happen."

echo
read -sp "When the BeagleBone is connected in USB Boot mode press [y/n]" -n 1 -r

# Stopping if they didn't input a "y" (case insensitive)
if ( ! [[ $REPLY =~ ^[Yy]$ ]])
then
    echo
    exit 0
fi

# An array of all the drives before we start
before=($(ls /dev | grep "sd[a-z]$"))

echo
echo "Putting the BeagleBone into flashing mode! (You can ignore any libusb errors)"

# Use the usb_flasher program to put the board into usb flashing mode
echo
./usb_flasher
rc=$?

# Check the return code from the usb_flasher to make sure it completed correctly
if [[ $rc != 0 ]];
then
    echo "The BeagleBone cannot be put in USB Flashing mode! Something has gone horribly wrong. Please try again and hope for the best..."
    exit $rc
fi

echo "BeagleBone has been put into flashing mode!"

# It takes exactly 12 seconds for this to complete. every. single. time. I have a feeling there's something making that true...
echo -n "Now waiting for the BeagleBone to be mounted"
for i in {1..12}
do
    echo -n "."
    sleep 1
done
echo 

# Get the drives after flashing and figure out what the new one is
# This is why you can't mount anything new while it's running.
after=($(ls /dev | grep "sd[a-z]$"))
bbb=($(diff after[@] before[@]))

if [ -z "$bbb" ];
then
    echo "The BeagleBone cannot be detected. Most likely there was an issue mounting it."
    echo "Please try the program again."
    exit 1
fi

echo "Mounted Beaglebone detected!"

echo
if [ ${#bbb[@]} != "1" ]
then
    echo "You inserted an USB stick or mounted an external drive. Please rerun the script without doing that."
    exit 1
fi

echo "Are you sure the BeagleBone is mounted at /dev/$bbb? If not, see the troubleshooting tips in the guide."
read -sp "Run the 'df' command to confirm [y/n]" -n 1

if ( ! [[ $REPLY =~ ^[Yy]$ ]] )
then
    echo
    exit
fi

# Any of the partitions of the Beaglebone that were mounted
parts=($(ls /dev | grep "$bbb[1,2]"))

echo
for index in ${!parts[*]}
do
    # Lazy unmounting of said partitions
    # This means it'll remove them now, but wait until it's not busy to actually unmount it
    umount -l /dev/${parts[$index]}
done

# Wait to help make sure they actually unmount
sleep 3

echo "Flashing now! Be patient, it will take 5 - 8 minutes!"

# Use xz to uncompress the image then pipe that into dd which writes it to the board
xzcat $input -v | dd of=/dev/$bbb bs=1M
sleep 1

echo
echo "Checking file system for errors..."
e2fsck -f /dev/${bbb}1

echo
echo "Resizing file system (just in case!). Likely to say nothing needs to happen."
resize2fs /dev/${bbb}1

echo "Flashing all complete!"
