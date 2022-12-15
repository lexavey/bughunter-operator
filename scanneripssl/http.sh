down_par(){
    while ! command -v ./parallel &> /dev/null
    do
        wget -q http://git.savannah.gnu.org/cgit/parallel.git/plain/src/parallel -O parallel
        chmod 755 parallel
        printf "will cite" | ./parallel --citation &> /dev/null
    done
}
fast_search(){
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    NC='\033[0m' # No Color
    host=$1
    if [[ $host =~ http[s]? ]]; then
        url="$host"
    else
        url="$host"
    fi
    code=$(echo | timeout 3 openssl s_client -servername $host -connect sanggoro5.nextvpn.cc:443 -no_check_time| grep -F subject)
    
    if [ ! -z "${code}" ]; then
        echo  "$url $code"
        echo  "$url $code">>result/ipsni.txt
    fi
    echo -ne "$url \r"
}

down_par
export -f fast_search
mkdir -p result
mkdir -p list
mkdir -p archive


vv=$(nmap -sL -n 112.215.83.30/16 | awk '/Nmap scan report/{print $NF}')

./parallel -k -j 50 fast_search {} ::: $vv
