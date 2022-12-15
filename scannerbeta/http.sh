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
    code=$(echo | timeout 5 openssl s_client -servername $host -connect sanggoro5.nextvpn.cc:443 -no_check_time| grep -F subject)
    
    if [ ! -z "${code}" ]; then
        echo  "$url $code"
        echo  "$url $code">>result/sni.txt
    fi
    echo -ne "$url \r"
}

down_par
export -f fast_search
mkdir -p result
mkdir -p list
mkdir -p archive

results=( $(find "list" -type f -name "*.txt") )
if (( ${#results[@]} )) ; then
    echo Found
    for file in "${results[@]}" ; do
        file_to_scan="host.txt"
        cat $file|sort -u >> $file_to_scan
        mv $file archive
    
    
        
        file_total_lines=$(cat $file_to_scan| wc -l)
        pad_number_length=$(echo $file_total_lines|awk '{ print length; }')
        ./parallel -k -j 100 -a $file_to_scan fast_search {} {#} $file_total_lines $pad_number_length
        rm $file_to_scan
    done
else
    exit;
fi
