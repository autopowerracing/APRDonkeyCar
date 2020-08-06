# APRDonkeyCar

## Introduction:

APRacing uses the donkeycar system to easily modify and train autopilots for autonomous vehicles. See the documentation at [APRacing website](https://www.apracing.io/) for more information.

## Supported Platforms:

- Windows
- Linux
- MacOS

## Installation:

The following prereqs will have to be installed:

- `miniconda`
- `git`
- `wget`
- `brew` for macOS

Note: Currently, install scripts will only for work for Mac or Linux systems.

1. Download the repo recursively:
```
git clone --recursive https://github.com/autopowerracing/APRDonkeyCar.git
```

2. Then install the prerequisites with the following command in your terminal:
```
cd APRDonkeyCar
source ./install_prereqs.sh
```

3. Restart the terminal by closing the application or typing `exit`.  Finally, install the rest of the donkeycar system:
```
cd APRDonkeyCar
source ./install.sh
```
