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
        url="$host"
    fi
    code=$(curl -o /dev/null -s $url --insecure -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.102 Safari/537.36 OPR/90.0.4480.100' --connect-timeout 5 --max-time 5 --write-out '%{http_code}')

    echo -ne "$code|$url|$result\r"
    if [[ $code != "000" ]]; then
        echo -ne "$url $code 				OK\n"
        echo "$url">>nonproxy_$code.txt
    fi
}

down_par
export -f fast_search

results=( $(find "list" -type f -name "*.txt") )
if (( ${#results[@]} )) ; then
    echo Found
    for file in "${results[@]}" ; do
        cat $file >> host.txt
        rm -f $file
        ./parallel -j 100 -a host.txt fast_search {}
        rm host.txt
    done
else
    exit;
fi
