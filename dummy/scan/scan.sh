down_par(){
    while ! command -v ./parallel &> /dev/null
    do
        # printf "\rDownloading Parallel"
        wget -q http://git.savannah.gnu.org/cgit/parallel.git/plain/src/parallel -O parallel
        chmod 755 parallel
        printf "will cite" | ./parallel --citation &> /dev/null
    done
}
fast_search(){
    host=$1
    if [[ $host =~ http[s]? ]]; then
        url="$host"
    else 
        url="http://$host"
    fi
    temp_http_header=$(mktemp)
    temp_http_response=$(mktemp)
    code=$(curl -s $url --insecure -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.102 Safari/537.36 OPR/90.0.4480.100' --connect-timeout 5 --max-time 5 --write-out '%{http_code}' --dump-header $temp_http_header -o $temp_http_response)
##    echo "$host - $temp_http_header\n"
    rm -f $temp_http_header
    rm -f $temp_http_response
    echo -ne "$code|$url|$result\r"
    if [[ $code == "200" ]]; then
        echo -ne "$url 200 OK\n"
        echo "$code|$url">>200.txt
    fi
}

down_par
export -f fast_search
./parallel -j 250 -a urls.txt fast_search {}
