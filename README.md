##  [English](README.md) | [Bahasa Indonesia](README-id.md)
## English Version

# BugHunter Operator

## Requirements

Before using the BugHunter Operator, make sure you have the following packages installed: `curl`, `openssl`, `nmap`, `git`, `perl`, and `python`.

You can install these packages using the following commands:

```bash
apt update && apt upgrade
apt install curl nmap openssl git perl python -y
```

## Quickstart

### Step 1 - Download
Clone the BugHunter Operator repository and navigate to the project directory:

```bash
git clone https://github.com/lexavey/bughunter-operator
cd bughunter-operator
chmod +x ./run.sh
```

### Step 2 - Get the list
Create a directory named `list` and copy the URL list to it:

```bash
mkdir -p list
cp archive/random/urls_universal.txt list/
```

### Step 3 - Scan
To perform the scanning process, follow these steps:

1. Disconnect your WiFi and use a data SIMCARD for a more accurate scan.

2. Run the scanning script without a custom domain list:

```bash
./run.sh scan sni go
```

Or, if you want to use a custom domain list, create a text file (e.g., `domain.txt`) containing the list of domains you want to scan, and then use the following command:

```bash
./run.sh scan sni go domain.txt
```

These commands will initiate the scanning process and display the results of the scan.

## Common Error

### Error message

```
syntax error at ./bin/parallel line 2992, at EOF
Missing right curly or square bracket at ./bin/parallel line 2992, at end of line
Execution of ./bin/parallel aborted due to compilation errors.
```

### Solution

To resolve this error, update your Perl version. If you are using Termux, consider using the Linux Deploy app from the Play Store: https://play.google.com/store/apps/details?id=ru.meefik.linuxdeploy (ROOT)

Follow these steps:

1. Download the Linux Deploy app.
2. Set the properties (Down right):
   - Distribution: Ubuntu
   - Architecture: arm64
   - Password: 123
   - SSH: Enable
3. Go back.
4. Install (Upper right).
5. Configure.
6. Start.
7. Connect SSH from Termux using the following command: `ssh android@localhost -p 22`

### Checking Perl version

To check your Perl version, run the following command:

```bash
perl -v
```

You should see output similar to:

```
This is perl 5, version 26, subversion 1 (v5.26.1) built for aarch64-linux-gnu-thread-multi
(with 62 registered patches, see perl -V for more detail)

Copyright 1987-2017, Larry Wall

Perl may be copied only under the terms of either the Artistic License or the
GNU General Public License, which may be found in the Perl 5 source kit.

Complete documentation for Perl, including FAQ lists, should be found on
this system using "man perl" or "perldoc perl". If you have access to the


Internet, point your browser at http://www.perl.org/, the Perl Home Page.
```

Feel free to reach out if you need any further assistance or have more questions!