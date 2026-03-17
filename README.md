# SimplyPrint Nebula Smart Kit Firmware

> [!NOTE]
> This script is heavily based on ![pellcorps's script](https://github.com/pellcorp/creality/tree/main/firmware)
> and ![koen1's script](https://github.com/koen01/nebula_firmware)

This project automates fetching the latest Creality Nebula firmware, rooting it, and repacking it into a new image.

## Overview

![create.sh](create.sh) downloads the official Creality Nebula firmware, extracts it, and repacks a rooted version with
the following modifications:

- Enables ssh/root access and injects a new root password
- Adds the ![installer.sh](root/installer.sh) script to `/root` which installs and runs
  the ![Creality Helper Script](https://github.com/Guilouz/Creality-Helper-Script) for installing Klipper, SimplyPrint,
  and other related tools.
- Adds a factory reset option by checking if a file named `factory_reset` exists on the USB stick

## Firmware and Klipper installation

1. Download the latest `NEBULA_ota_img_V6.*.img` file from
   the ![latest release](https://github.com/SimplyPrint/printer-nebula-firmware/releases/latest)
2. Transfer it to the USB stick that came with the Nebula
3. Insert it into the Nebula and press the ***Upgrade*** button, once the firmware upgrade pop-up appears, and wait for
   the installation to finish

<p align="center">
    <img height="375" alt="Nebula screen with upgrade pop-up" src="docs/Nebula_upgrade-popup.png" />
</p>

4. Go to ***Settings*** -> ***Network*** on the Nebula, and find it´s IP address

<p align="center">
    <img height="375" alt="Nebula screen with settings button" src="docs/Nebula_default-screen.png" />
    <img height="375" alt="Nebula screen with network button" src="docs/Nebula_settings-page.png" />
    <img height="375" alt="Nebula screen with network SSID and IP" src="docs/Nebula_network-tab.png" />
</p>

5. Connect to the Nebula over ssh with it´s IP address and the user `root` with the password `creality`
6. Run the Creality Helper Script by running `./installer.sh`
7. Choose `1) [Install] Menu` once the script has launched, and install the following:
    - `1) Moonraker and Nginx`
    - `2) Fluidd (port 4408)` or `3) Mainsail (port 4409)`
    - `5) Klipper Gcode Shell Command`
    - `10) Nebula Camera Settings Control`
    - `11) USB Camera Support`
    - `17) SimplyPrint`
8. Enable the Nebula camera by navigating to `5) [Tools] Menu` in the main menu, and choose
   `3) Enable camera settings in Moonraker`
9. Open a browser and navigate to `http://[YOUR IP]:[Fluidd/Mainsail port]`, e.g. `http://192.168.0.42:4409`, to open
   the Mainsail or Fluidd instance

### Factory resetting

> [!WARNING]
> Performing a factory reset will permanently delete all user-installed software, custom configurations, and most stored
> data.
> Only your Wi-Fi settings, printer identity, and essential system configuration files will be preserved.

1. Add an empty file named `factory_reset` (no file extension) to the USB stick
2. Turn off the Nebula, insert the USB stick, and turn it on again
3. Wait until the Nebula has booted up completely

The upgrade pop-up will show up, if the rooted firmware is present on the USB stick, which indicates a successful
factory reset.

## Usage

### Dependencies

```
7z
wget
mksquashfs
unsquashfs
openssl     # (or mkpasswd)
```

#### (Optional Dependencies)

To run `get-version.py` and automatically fetch the latest firmware version and download link, you need:

```
uv       # https://github.com/astral-sh/uv
python3
```

### Running the script

1. Clone or download the repository and navigate into it.
   ```bash
   git clone https://github.com/SimplyPrint/printer-nebula-firmware
   cd printer-nebula-firmware
    ```
2. You can either:
    1. Choose a firmware version and find the download link for it
       on [Creality's website](https://www.creality.com/download/creality-nebula-smart-kit).
    2. Run `get-version.py` to fetch the newest firmware version and download link.
   ```bash
   uv sync
   uv run get-version.py
   ```
3. Set the firmware version and download link variables.
    ```bash
    export CREALITY_VERSION=<PASTE_FW_VERSION_HERE>
    export DOWNLOAD_URL=<PASTE_LINK_HERE>
    ```
   `ROOT_PASSWORD` sets the root user password (defaults to `creality`).
4. Run the script (it may ask for your password).
   ```bash
   ./create.sh
   ```
   The script will create a custom `.img` file in the current directory.
