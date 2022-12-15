#!/bin/bash 

# set -e
has() {
  type "$1" > /dev/null 2>&1
  return $?
}

if has "wget"; then
  DOWNLOAD() {
    wget --no-check-certificate -nc -O "$2" "$1"
  }
elif has "curl"; then
  DOWNLOAD() {
    curl -sSL -o "$2" "$1"
  }
else
  echo "Error: you need curl or wget to proceed" >&2;
  exit 1
fi

red=$'\e[01;31m'
green=$'\e[01;32m'
yellow=$'\e[01;33m'
blue=$'\e[01;34m'
magenta=$'\e[01;35m'
resetColor=$'\e[0m'

check_deps(){
    if ! has "./parallel"; then
        DOWNLOAD http://git.savannah.gnu.org/cgit/parallel.git/plain/src/parallel parallel
        chmod 755 parallel
        printf "will cite" | ./parallel --citation &> /dev/null
    fi
}

fast_search(){
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color
    host=$1
    code=$(
        curl --insecure -vvI --connect-to $host:443:sanggoro5.nextvpn.cc:443 --connect-timeout 5 --max-time 5 "https://$host"  2>&1 | awk 'BEGIN { cert=0 } /^\* SSL connection/ { cert=1 } /^\*/ { if (cert) print } '|grep subject
        )
    if [ ! -z "${code}" ]; then
        printf "[~%0${4}d~ ~%s~]~%-100s~[${GREEN}%s${NC}]\n" "${2}" "${3}" "$host~" "~$code~" | tr ' ~' '- '
        echo "$host">>"result/sni_curl.txt"
    else
        printf "[~%0${4}d~ ~%s~]~%-100s~[${RED}%s${NC}]\r" "${2}" "${3}" "$host~" "~$code~" | tr ' ~' '- '
    fi
}

export -f fast_search
mkdir -p result
mkdir -p list
mkdir -p archive
find "./list" -type f -name "*.txt" -print0 | while IFS= read -r -d '' file; do
    echo "Job start for $file";
	file_to_scan="host.txt"
    sed 's/\r$//' "$file"|sort -u > $file_to_scan
    # mv "$file" archive
    file_total_lines=$(cat $file_to_scan| wc -l)
    pad_number_length=$(echo $file_total_lines|awk '{ print length; }')
    ./parallel -k -j 200 -a $file_to_scan fast_search {} {#} $file_total_lines $pad_number_length
    rm $file_to_scan
    echo
    echo "Job done for $file";
done


start() {
  if [ $# -lt 1 ]; then
    start base
    return
  fi
  check_deps
  case $1 in
    "help" )
      echo
      echo "BugHunter Operator"
      echo
      echo "Usage:"
      echo "    $0 help                       Show this message"
      echo "    $0 scan [type]                                  "
      echo "    $0      example : scan ssl                                  "
      echo "    $0 install ls                         List available packages"
      echo
    ;;

    "ls" )
      echo "!node - Node.js"
      echo "!tmux - TMUX"
      echo "!nak - NAK"
      echo "!ptyjs - pty.js"
      echo "!collab - collab"
      echo "coffee - Coffee Script"
      echo "less - Less"
      echo "sass - Sass"
      echo "typescript - TypeScript"
      echo "stylus - Stylus"
    ;;
    "base" )
    #   echo "Installing base packages. Use help [ $0 help ] for more options"
      start help
    ;;
    
    * )
      start base
    ;;
  esac
}
start