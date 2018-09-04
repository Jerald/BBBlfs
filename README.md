# beaglebone_usb_flasher
#### A full system to flash a BeagleBone over usb.

This system is forked from the [BBBlfs](https://github.com/ungureanuvladvictor/BBBlfs) project. Without his work this likely wouldn't be here. 
Albeit a lot of it was broken and has to be re-engineered... But still his work is the core.


## Build

You need to build the project to create a small executable used to put the BeagleBone into the correct mode to be flashed over USB.

It requires `libusb` and `automake` as dependencies. Download them with your favourite package manager. After that, run the below commands to make the executable:
```bash
./autogen.sh
./configure
make
```

## Usage

Press the S2 button on the BeagleBone and apply power to the board. That's the small button on the opposite side as the ethernet port. The board should now start into USB boot mode.

Connect your BeagleBone to the host PC, the kernel will identify the board as an RNDIS interface. Which is to say, a bare-bones ethernet interface.  No need to check this unless you're having issues.

<!-- Be sure you do not have any BOOTP servers on your network. -->

Navigate to the repo's `bin/` folder and execute `flash_script.sh` **as root**. The first argument should be the image you want to flash. Only `.img.xz` compressed images are supported, that's the same format as you'd get from the BeagleBone website.

For example: `sudo ./flash_script.sh  image.img.xz`

## Troubleshooting

If you have issues with flashing your board, the script provides some minimal error state information which may help. Otherwise, there is a full guide I've wrote for this process with a dedicated troubleshooting section. Check it out [here](https://github.com/Jerald/cmpt433finalproject/blob/master/BeagleBone_USB_Flash_Guide.md#troubleshooting).
