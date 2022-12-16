# bughunter-operator

## Requirements
Install `curl` `openssl` `nmap` `git`

    apt update && apt upgrade
    apt install curl nmap openssl git -y
## Quickstart
### Step 1 
#### Download 
    git clone https://github.com/lexavey/bughunter-operator
    cd bughunter-operator
    chmod +x ./scan.sh
### Step 2 
#### Get list 
    cp archive/random/whatsapp.com.txt list
    cp archive/xl/xl.co.id.txt list
### Step 3 
#### Scan 
    ./scan.sh scan sni_curl bulk
