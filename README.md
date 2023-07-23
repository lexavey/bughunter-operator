# bughunter-operator

## Requirements

Install `curl` `openssl` `nmap` `git` `perl` `python`

    apt update && apt upgrade
    apt install curl nmap openssl git perl python -y

## Quickstart
### Step 1 
#### Download 
    git clone https://github.com/lexavey/bughunter-operator
    cd bughunter-operator
    chmod +x ./scan.sh
### Step 2 
#### Get list 
    mkdir -p list
    cp archive/random/urls_universal.txt list/
### Step 3 
#### Disconnect your WiFi & Use 0 balance 0 data SIMCARD 
    ./scan.sh scan sni bulk

## Common error
#### Error message
    syntax error at ./bin/parallel line 2992, at EOF
    Missing right curly or square bracket at ./bin/parallel line 2992, at end of line
    Execution of ./bin/parallel aborted due to compilation errors.
#### Solution
    Update your perl/dont use termux, use Linux Deploy app in playstore https://play.google.com/store/apps/details?id=ru.meefik.linuxdeploy (ROOT)
    Download.
    Setting properties. (Down right)
    Distribution : Ubuntu
    Architecture : arm64
    Password : 123
    SSH : Enable
    Back.
    Install (Upper right)
    Configure.
    Start.
    Connect ssh from termux : ssh android@localhost -p 22



#### Knowing work
    root@localhost:~/bughunter-operator# perl -v
    This is perl 5, version 26, subversion 1 (v5.26.1) built for aarch64-linux-gnu-thread-multi
    (with 62 registered patches, see perl -V for more detail)

    Copyright 1987-2017, Larry Wall

    Perl may be copied only under the terms of either the Artistic License or the
    GNU General Public License, which may be found in the Perl 5 source kit.

    Complete documentation for Perl, including FAQ lists, should be found on
    this system using "man perl" or "perldoc perl".  If you have access to the
    Internet, point your browser at http://www.perl.org/, the Perl Home Page.
    
