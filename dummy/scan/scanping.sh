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
	dig +short "$url" | awk '{ print ; exit }' > /dev/null
    if [ $? -eq 0 ]; then
    	echo -ne "node $url is up\n" 
    	echo "$url">>pingok.txt
    else
    	echo -ne "node $url is down\r"
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
