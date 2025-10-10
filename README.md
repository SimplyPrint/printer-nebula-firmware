# SimplyPrint Nebula Smart Kit Firmware
> [!NOTE]
> This script is heavily based on ![pellcorps's script](https://github.com/pellcorp/creality/tree/main/firmware) and ![koen1's script](https://github.com/koen01/nebula_firmware)

This project automates fetching the latest Creality Nebula firmware, rooting it, and repacking it into a new image.

## Overview
`create.sh` downloads the official Creality Nebula firmware, extracts it, and repacks a rooted version with the following modifications:
- Enables ssh/root access and injects a new root password
- Adds the `/root/installer.sh` script that installs and runs the ![Creality Helper Script](https://github.com/Guilouz/Creality-Helper-Script) for installing Klipper, SimplyPrint, and other related tools.
- Adds a factory reset option by checking if a file named `factory_reset` exists on the USB stick

## Firmware installation
1. Download the latest `NEBULA_ota_img_V6.*.img` file from the ![latest release](https://github.com/SimplyPrint/printer-nebula-firmware/releases/latest)
2. Transfer it to the USB stick that came with the Nebula
3. Insert it into the Nebula and press the ***Upgrade*** button, once the firmware upgrade pop-up appears, and wait for the installation to finish
4. Go into ***Settings*** -> ***Network*** and find the Nebula's IP address
5. Connect to the Nebula over ssh (default: `root@creality`)
6. Run the installer script by running `./installer.sh`
7. Choose `1) [Install] Menu` once the script has launched and install the following:
    - `1) Moonraker and Nginx`
    - `2) Fluidd (port 4408)` or `3) Mainsail (port 4409)`
    - `5) Klipper Gcode Shell Command`
    - `10) Nebula Camera Settings Control`
    - `11) USB Camera Support`
    - `17) SimplyPrint`
8. Enable the webcam for moonraker by navigating to `5) [Tools] Menu` in the main menu, and choose `3) Enable camera settings in Moonraker`
9. Open a browser and navigate to `http://[YOUR IP]:[Fluidd/Mainsail port]`, fx. `http://192.168.0.42:4409`, to open the Mainsail or Fluidd instance

### Factory reset
> [!WARNING]
> Performing a factory reset will permanently delete all user-installed software, custom configurations, and most stored data.
> Only your Wi-Fi settings, printer identity, and essential system configuration files will be preserved.

1. Add an empty file named `factory_reset` (no file extension) to the USB stick
2. Turn off the Nebula, insert the USB stick, and turn it on again
3. Wait until the Nebula has booted up completely

The upgrade pop-up will show up, if the rooted firmware is present on the USB stick, which indicates a successful factory reset.

## Usage
### Required packages
```
7z
wget
mksquashfs
unsquashfs
openssl (or mkpasswd)
```
### Running the script
1. Clone or download the repository and navigate into it
   ```bash
   git clone https://github.com/SimplyPrint/printer-nebula-firmware
   cd printer-nebula-firmware
    ```
2. Set the firmware version with the `CREALITY_VERSION` variable and run the script:
    ```bash
    export CREALITY_VERSION=1.1.0.29
    ./create.sh
    ```
    The `ROOT_PASSWORD` variable defines the password for the root user, and defaults to `creality`.