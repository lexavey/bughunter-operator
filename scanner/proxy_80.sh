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
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color
    host=$1
    code=$(curl -o /dev/null -s "http://$host" -k -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.102 Safari/537.36 OPR/90.0.4480.100' -x "http://$host:80" --connect-timeout 5 --max-time 5 --write-out '%{http_code}')
    if [[ $code == "200" ]]; then
        printf "[~%0${4}d~ ~%s~]~%-100s~[${GREEN}%s${NC}]\n" "${2}" "${3}" "$host~" "~$code~" | tr ' ~' '- '
    elif [[ $code != "000" ]]; then
        printf "[~%0${4}d~ ~%s~]~%-100s~[${YELLOW}%s${NC}]\n" "${2}" "${3}" "$host~" "~$code~" | tr ' ~' '- '
    else
        printf "[~%0${4}d~ ~%s~]~%-100s~[${RED}%s${NC}]\r" "${2}" "${3}" "$host~" "~$code~" | tr ' ~' '- '
    fi
    echo "$host">>"result/proxy_80_http_$code.txt"
}

down_par
export -f fast_search
mkdir -p result
mkdir -p list
mkdir -p archive
find "list" -type f -name "*.txt" -print0 | while IFS= read -r -d '' file; do
    echo "Job start for $file";
	file_to_scan="host.txt"
    cat "$file"|sort -u >> $file_to_scan
    mv "$file" archive
    file_total_lines=$(cat $file_to_scan| wc -l)
    pad_number_length=$(echo $file_total_lines|awk '{ print length; }')
    ./parallel -k -j 60 -a $file_to_scan fast_search {} {#} $file_total_lines $pad_number_length
    rm $file_to_scan
    echo
    echo "Job done for $file";
done


