# LANResolver: a local network resolver for MAC or private IP addresses.

LANResolver is an all-in-one script that solves MAC by IP (or vice versa) and it replies to asynchronous requests by other applications.

The program replies to external requests looking at its internal resolutions list based on the user-defined static resolutions and the IPs solved dynamically.

To resolve IPs dynamically the script must be run in deamon mode (`-d` option).

In that mode the program executes cyclically an [arp-scan](https://en.wikipedia.org/wiki/Address_Resolution_Protocol) on the local networks.

## Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Options](#options)
- [Usage](#usage)
- [Versions](#versions)
- [Credits](#credits)
- [License](#license)

## Installation

Run the setup to install the script in your home (it will be placed in `$HOME/LANResolver`):
```
bash /absolute/path/to/Setup\ LANResolver.sh
```

## Configuration

Once installed, the script `$HOME/LANResolver/LANResolver.sh` can be tuned changing the following variables that are declared at the beginning of the program:

Parameter | Unit | Default | Description
--------- | ---- | ------- | -----------
`ENTRIES_TTL` | Seconds | 900 | Lifetime of each resolution (if it won't be renewed with an ARP reply)
`SCAN_PERIOD` | Seconds | 300 | Time interval between two subsequent ARP scans
`WEIGHT_DYNAMIC_RESOLUTIONS` || 1 | Weight associated to dynamic resolutions, they will be shown if this weight is greater than statics' one or if no static resolution has been added
`WEIGHT_STATIC_RESOLUTIONS` || 0 | Weight associated to static resolutions, they will be shown if this weight is greater than dynamics' one or if no dynamic resolution has been added

## Options

Option | Description
------ | -----------
`-d` or `--daemon` | Launch the program in daemon mode
`-g <key>` or `--get <key>` | Print the value of the given key (IP or MAC)
`-h` or  `--help` | Show these messages (all available options)
`-i <file>` or `--import <file>` | Import the resolutions from a file
`-l` or `--list` | Print the list of resolutions
`-s <k> <v>` or `--set <k> <v>` | Set the static resolution with key k (IP or MAC) and value v (MAC or IP)
`-u <k> [v]` or `--unset <k> [v]` | Unset the static resolution(s) with key k (IP or MAC) and, if specified, the value v (MAC or IP)
`-v` or `--verbose` | Enable the debug mode

## Usage

Run the script in deamon mode:
```
bash $HOME/LANResolver/LANResolver.sh -d
```

In that mode the program will execute a `sudo arp-scan -l` every 5 minutes (by deafult, the period can be modified changing directly the constant `SCAN_PERIOD` defined in the script).

The root permissions are required only to run the scan but, once inserted the password when the program is executed in daemon mode, it replies to the subsequent resolution requests without any other input by the user.

Print all the resolutions stored in the internal list (added statically by the user or inserted dinamically by the program):
```
bash $HOME/LANResolver/LANResolver.sh -l
```

Let's say that only one device has replied to the last arp-scan and any static resolution has been added, an example of output is:
```
dynamic,192.168.1.123,aa:bb:cc:dd:ee:ff,1609459200
```

Field | Description
----- | -----------
dynamic | This is the kind of resolution (native types used by the program are `static` and `dynamic`)
192.168.1.123 | The IP solved by the arp-scan
aa:bb:cc:dd:ee:ff | The MAC address of the device that has replied to the ARP request
1609459200 | The timestamp expressed in seconds from the epoch

Add a static resolution for the device a1:b1:c1:d1:e1:f1 which has static IP 192.168.1.234, execute this command:
```
bash $HOME/LANResolver/LANResolver.sh -s 192.168.1.234 a1:b1:c1:d1:e1:f1
```

Printing now the resolution list it will be:
```
dynamic,192.168.1.123,aa:bb:cc:dd:ee:ff,1609459200
static,192.168.1.234,a1:b1:c1:d1:e1:f1,1609459345
```

To see which IP has received a known device/MAC (let's say aa:bb:cc:dd:ee:ff) run the get command (`-g` option):
```
bash $HOME/LANResolver/LANResolver.sh -g aa:bb:cc:dd:ee:ff
```

If two or more resolutions match a given IP or MAC, the program will show some of them accordingly to the type of each resolution (`static` and `dynamic`) and the values of the constants `WEIGHT_DYNAMIC_RESOLUTIONS` and `WEIGHT_STATIC_RESOLUTIONS` defined in the script.
It will be shown the resolutions of the type with the greater weight and the matching resolutions that aren't of a native type (neither `static` nor `dynamic`) will be always shown.

## Versions
1.0.0 - First public release

## Credits
This script has been written by ErVito

## License
This project is licensed under the GNU GPL v3 or any later leversion.
