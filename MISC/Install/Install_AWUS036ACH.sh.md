# Install Alfa awus036ach

The `Install_AWUS036ACH.sh` script is designed to configure a Wi-Fi adapter on a Kali Linux system. It updates and upgrades existing packages, installs necessary packages, and installs the driver for the Realtek RTL88xxAU wireless chipset. Additionally, it provides instructions to configure the adapter for monitor mode.

## Usage
To use the script, follow these steps:

1. Make sure you have permission to execute the script. If not, run the following command to grant permission:
console

```bash
chmod +x wifi_adapter_config.sh
```

2. Execute the script by running the following command:

```bash
sudo ./wifi_adapter_config.sh
```

The script will update and upgrade existing packages, install necessary packages, install the driver for the Realtek RTL88xxAU wireless chipset, and provide instructions to configure the adapter for monitor mode.

## Explanation
The script uses a combination of `sudo apt-get` commands, `git` commands, and `make` commands to update and upgrade existing packages, install necessary packages, and install the driver for the Realtek RTL88xxAU wireless chipset.

* `sudo apt-get update`: This command updates the package list from the repositories.

* `sudo apt-get upgrade -y`: This command upgrades all installed packages to their latest available versions.

* `sudo apt-get dist-upgrade -y`: This command performs an intelligent upgrade, handling changes in package dependencies, and installing new packages if necessary.

* `sudo apt-get install -y dkms git realtek-rtl88xxau-dkms`: This command installs the necessary packages for the driver to work properly. `dkms` is a package that provides support for building and installing kernel modules, while `git` is a version control system used to download the driver source code from the repository. `realtek-rtl88xxau-dkms` is the package that contains the driver code for the Realtek RTL88xxAU wireless chipset.

* `git clone https://github.com/aircrack-ng/rtl8812au.git`: This command clones the driver source code repository from GitHub.

* `cd rtl8812au`: This command changes the current working directory to the newly created rtl8812au directory.

* `make`: This command builds the driver from the source code.

* `sudo make install`: This command installs the built driver to the appropriate location on the system.

Additionally, the script provides instructions to configure the adapter for monitor mode by displaying the following commands:

`sudo ip link set wlan1 down`: This command brings down the Wi-Fi adapter.

`sudo iw dev wlan1 set type monitor`: This command sets the Wi-Fi adapter to monitor mode.

`sudo ip link set wlan1 up`: This command brings up the Wi-Fi adapter in monitor mode.

Finally, the script displays a link to the article "Configuring the Alpha AWUS036ACH Wi-Fi Adapter on Kali Linux" on Hackernoon, which provides additional information on configuring the Wi-Fi adapter.
