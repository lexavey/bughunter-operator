#!/bin/bash -e
source config.sh
# set -e
has() {
  type "$1" > /dev/null 2>&1
  return $?
}
if has "curl"; then
  DOWNLOAD() {
    echo "Download parallel"
    curl -SL -o "$2" "$1"
  }
else
  echo "Error: you need curl" >&2;
  exit 1
fi

color(){
    red=$'\e[01;31m'
    green=$'\e[01;32m'
    yellow=$'\e[01;33m'
    blue=$'\e[01;34m'
    magenta=$'\e[01;35m'
    resetColor=$'\e[0m'
}
updatescript() {
    # without this git merge fails on windows
    mv ./scan.sh  './.#scan.sh'
    rm -f ./.scan.sh 
    cp './.#scan.sh' ./scan.sh
    git checkout -- ./scan.sh
    color
    git remote add bughunter-operator https://github.com/lexavey/bughunter-operator 2> /dev/null || true
    git fetch bughunter-operator
    git merge bughunter-operator/master --ff-only || \
        echo "${yellow}Couldn't automatically update ${resetColor}"
}
check_deps(){
    if ! has "./bin/parallel"; then
        DOWNLOAD http://git.savannah.gnu.org/cgit/parallel.git/plain/src/parallel ./bin/parallel
        chmod 755 ./bin/parallel
        printf "will cite" | ./bin/parallel --citation &> /dev/null
    fi
}
function_sni(){
    LINE=$1
    LINE_NUM=$2
    TOTAL_LINE=$3
    PAD_NUMBER_LENGTH=$4
    host_check=$DEFAULT_SNI_HOST
    color
    code=$(
        curl --insecure -vvI --connect-to $LINE:443:$host_check:443 --connect-timeout $DEFAULT_CONNECT_TIMEOUT --max-time $DEFAULT_MAX_TIMEOUT "https://$LINE"  2>&1 | awk 'BEGIN { cert=0 } /^\* SSL connection/ { cert=1 } /^\*/ { if (cert) print } ' | grep subject
    )
    if [ ! -z "${code}" ]; then
        printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${green}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" "SNI" "$LINE"| tr ' ~' '- '
        printf "\n"
        echo "$LINE">>"result/sni.txt"
    else
        printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${red}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" "OFF" "$LINE"| tr ' ~' '- '
        printf "\r"
    fi
}
function_http_ws(){
    LINE=$1
    LINE_NUM=$2
    TOTAL_LINE=$3
    PAD_NUMBER_LENGTH=$4
    tmp_file=$(mktemp -u tmp/HTTP_WS_XXXXXXX)
    color
    gocurl=$(curl -o $tmp_file -s -I -X GET -H "Host: $DEFAULT_SNI_HOST" -H "Upgrade: Websocket" -H "Connection: Keep-Alive" -H "Proxy-Connection: Keep-Alive" "http://$LINE" --connect-timeout $DEFAULT_CONNECT_TIMEOUT --max-time $DEFAULT_MAX_TIMEOUT --write-out '%{http_code} %{redirect_url}')
    code=$(printf '%s' "$gocurl" | awk '{print $1}')
    if [[ $code == "101" ]]; then
        printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${green}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" $code "$LINE"| tr ' ~' '- '
        printf "\n"
        echo "$LINE">>"result/http_ws_${code}.txt"
        printf "%s\n%s\n" "[ $LINE ]" "$(cat $tmp_file | head -n 10)">>"result/http_ws_${code}_details.txt"
        rm -rf $tmp_file
        exit;
    elif [ $code == "301" ] || [ $code == "302" ]; then
        redirect_url=$(printf '%s' "$gocurl" | awk '{print $2}')
        if echo "$BLACKLIST_REDIRECT" | grep -q -w "$redirect_url"; then
            printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${red}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" $code "$LINE"| tr ' ~' '- '
            printf "\n"
        else
            printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${yellow}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" $code "$LINE"| tr ' ~' '- '
            printf "\n"
            echo "$LINE">>"result/http_ws_${code}.txt"
            printf "%s\n%s\n" "[ $LINE ]" "$(cat $tmp_file | head -n 10)">>"result/http_ws_${code}_details.txt"
        fi
        rm -rf $tmp_file
        exit;
    elif [[ $code != "000" ]]; then
        printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${magenta}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" $code "$LINE"| tr ' ~' '- '
        printf "\n"
        echo "$LINE">>"result/http_ws_${code}.txt"
        printf "%s\n%s\n" "[ $LINE ]" "$(cat $tmp_file | head -n 10)">>"result/http_ws_${code}_details.txt"
        rm -rf $tmp_file
        exit;
    else
        printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${red}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" $code "$LINE"| tr ' ~' '- '
        printf "\r"
        rm -rf $tmp_file
        exit;
    fi
    rm -rf $tmp_file
}
function_https_ws(){
    LINE=$1
    LINE_NUM=$2
    TOTAL_LINE=$3
    PAD_NUMBER_LENGTH=$4
    tmp_file=$(mktemp -u tmp/HTTPS_WS_XXXXXXX)
    color
    response=$(python -c "import socket, ssl; payload = b'GET / HTTP/1.1\\r\\nHost: $DEFAULT_SNI_HOST\\r\\n\\r\\n'; server_address = ('$LINE', 443); client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM); ssl_client_socket = ssl.create_default_context().wrap_socket(client_socket, server_hostname='$DEFAULT_SNI_HOST'); ssl_client_socket.settimeout(5); ssl_client_socket.connect(server_address); ssl_client_socket.sendall(payload); print(ssl_client_socket.recv(1024).decode()); print(ssl_client_socket.recv(1024).decode())" 2>/dev/null 1>"$tmp_file")
    code=$(grep -osP 'HTTP/\d.\d \K\d{3}' "$tmp_file")
    if [[ $code == "101" ]]; then
        printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${green}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" $code "$LINE"| tr ' ~' '- '
        printf "\n"
        echo "$LINE">>"result/https_ws_${code}.txt"
        printf "%s\n%s\n" "[ $LINE ]" "$(cat $tmp_file | head -n 10)">>"result/https_ws_${code}_details.txt"
        rm -rf $tmp_file
        exit;
    else
        # if [ -e $tmp_file ]; then
        #     printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${red}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" $code "$LINE"| tr ' ~' '- '
        #     printf "\n"
        #     rm -rf $tmp_file
        #     exit;
        # fi
        printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${red}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" "NULL" "$LINE"| tr ' ~' '- '
        printf "\r"
        # echo "$LINE">>"result/https_ws_${code}.txt"
        # printf "%s\n%s\n" "[ $LINE ]" "$(cat $tmp_file | head -n 10)">>"result/https_ws_${code}_details.txt"
        rm -rf $tmp_file
        exit;
    fi

    rm -rf $tmp_file
}


function_http_status(){
    LINE=$1
    LINE_NUM=$2
    TOTAL_LINE=$3
    PAD_NUMBER_LENGTH=$4
    tmp_file=$(mktemp -u tmp/HTTP_STATUS_XXXXXXX)
    color
    gocurl=$(curl -o $tmp_file -s -I "http://$LINE" -k -H "user-agent: $DEFAULT_USER_AGENT" --connect-timeout $DEFAULT_CONNECT_TIMEOUT --max-time $DEFAULT_MAX_TIMEOUT --write-out '%{http_code} %{redirect_url}')
    code=$(printf '%s' "$gocurl" | awk '{print $1}')
    if [[ $code == "200" ]]; then
        printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${green}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" $code "$LINE"| tr ' ~' '- '
        printf "\n"
        echo "$LINE">>"result/http_status_${code}.txt"
        printf "%s\n%s\n" "[ $LINE ]" "$(cat $tmp_file | head -n 10)">>"result/http_status_${code}_details.txt"
        rm -rf $tmp_file
        exit;
    elif [ $code == "301" ] || [ $code == "302" ]; then
        redirect_url=$(printf '%s' "$gocurl" | awk '{print $2}')
        if echo "$BLACKLIST_REDIRECT" | grep -q -w "$redirect_url"; then
            printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${red}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" $code "$LINE"| tr ' ~' '- '
            printf "\n"
        else
            printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${yellow}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" $code "$LINE"| tr ' ~' '- '
            printf "\n"
            echo "$LINE">>"result/http_status_${code}.txt"
            printf "%s\n%s\n" "[ $LINE ] [ $redirect_url ]" "$(cat $tmp_file | head -n 10)">>"result/http_status_${code}_details.txt"
        fi
        rm -rf $tmp_file
        exit;
    elif [[ $code != "000" ]]; then
        printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${magenta}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" $code "$LINE"| tr ' ~' '- '
        printf "\n"
        echo "$LINE">>"result/http_status_${code}.txt"
        printf "%s\n%s\n" "[ $LINE ]" "$(cat $tmp_file | head -n 10)">>"result/http_status_${code}_details.txt"
        rm -rf $tmp_file
        exit;
    else
        printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${red}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" $code "$LINE"| tr ' ~' '- '
        printf "\r"
        rm -rf $tmp_file
        exit;
    fi

    rm -rf $tmp_file
}
function_https_status(){
    LINE=$1
    LINE_NUM=$2
    TOTAL_LINE=$3
    PAD_NUMBER_LENGTH=$4
    tmp_file=$(mktemp -u tmp/HTTPS_STATUS_XXXXXXX)
    color
    gocurl=$(curl -o $tmp_file -s -I -k "https://$LINE" -k -H "user-agent: $DEFAULT_USER_AGENT" --connect-timeout $DEFAULT_CONNECT_TIMEOUT --max-time $DEFAULT_MAX_TIMEOUT --write-out '%{http_code} %{redirect_url}')
    code=$(printf '%s' "$gocurl" | awk '{print $1}')
    if [[ $code == "200" ]]; then
        printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${green}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" $code "$LINE"| tr ' ~' '- '
        printf "\n"
        echo "$LINE">>"result/https_status_${code}.txt"
        printf "%s\n%s\n" "[ $LINE ]" "$(cat $tmp_file | head -n 10)">>"result/https_status_${code}_details.txt"
        rm -rf $tmp_file
        exit;
    elif [ $code == "301" ] || [ $code == "302" ]; then
        redirect_url=$(printf '%s' "$gocurl" | awk '{print $2}')
        if echo "$BLACKLIST_REDIRECT" | grep -q -w "$redirect_url"; then
            printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${red}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" $code "$LINE"| tr ' ~' '- '
            printf "\n"
        else
            printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${yellow}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" $code "$LINE"| tr ' ~' '- '
            printf "\n"
            echo "$LINE">>"result/https_status_${code}.txt"
            printf "%s\n%s\n" "[ $LINE ] [ $redirect_url ]" "$(cat $tmp_file | head -n 10)">>"result/https_status_${code}_details.txt"
        fi
        rm -rf $tmp_file
        exit;
    elif [[ $code != "000" ]]; then
        printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${magenta}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" $code "$LINE"| tr ' ~' '- '
        printf "\n"
        echo "$LINE">>"result/https_status_${code}.txt"
        printf "%s\n%s\n" "[ $LINE ]" "$(cat $tmp_file | head -n 10)">>"result/https_status_${code}_details.txt"
        rm -rf $tmp_file
        exit;
    else
        printf "[~%0${PAD_NUMBER_LENGTH}d~ ~%s~]~[~${red}%s${resetColor}~]~%-${terminal_width}s~" "${LINE_NUM}" "${TOTAL_LINE}" $code "$LINE"| tr ' ~' '- '
        printf "\r"
        rm -rf $tmp_file
        exit;
    fi

    rm -rf $tmp_file
}
function_proxy(){
    host_target=$1
    echo_type=$2
    if [ ! -z "${PROXY_TARGET}" ]; then
        export PROXY_TARGET=$PROXY_TARGET
    else
        export PROXY_TARGET="http://$host_target"
    fi
    if [ ! -z "${PROXY_PREFIX}" ]; then
        export PROXY_PREFIX=$PROXY_PREFIX
    else
        export PROXY_PREFIX="http://"
    fi

    if [ ! -z "${PROXY_HOST}" ]; then
        export PROXY_HOST=$PROXY_HOST
    else
        export PROXY_HOST="$host_target"
    fi

    if [ ! -z "${PROXY_PORT}" ]; then
        export PROXY_PORT=$PROXY_PORT
    else
        export PROXY_PORT="80"
    fi
    proxy_url="${PROXY_PREFIX}${PROXY_HOST}:${PROXY_PORT}"
    tmp_file=$(mktemp -u tmp/Proxy_XXXXXXX)
    color
    gocurl=$(curl -o $tmp_file -s "$PROXY_TARGET" -I -k -H "user-agent: $DEFAULT_USER_AGENT" --connect-timeout $DEFAULT_CONNECT_TIMEOUT --max-time $DEFAULT_MAX_TIMEOUT -x $proxy_url --proxy-insecure --write-out '%{http_code} %{redirect_url}')
    code=$(printf '%s' "$gocurl" | awk '{print $1}')
    stdout=$(printf '%s' "$gocurl" | awk '{print $3}')
    if [[ $code == "200" ]]; then
        if [ "$echo_type" == "bulk" ]; then
            printf "[~%0${5}d~ ~%s~]~%-100s~[${green}%s${resetColor}]\n" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
        else
            printf "[${green} %s ${resetColor}]\n" "$code"
        fi
        printf "%s\n%s\n" "[ $host_target ]---------------------------" "$(cat $tmp_file | head -n 10)">>"result/proxy_${PROXY_PORT}_$code.txt"
        rm -rf $tmp_file
        exit;
    elif [[ $code == "301" ]] || [[ $code == "302" ]]; then
        redirect_url=$(printf '%s' "$gocurl" | awk '{print $2}')
        if [ "$echo_type" == "bulk" ]; then
            if [[ $redirect_url == $BLACKLIST_REDIRECT ]];then
                printf "[~%0${5}d~ ~%s~]~%-100s~[${red}%s${resetColor}]\r" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
            else
                printf "[~%0${5}d~ ~%s~]~%-100s~[${green}%s${resetColor}]\n" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
            fi
        else
            if [[ $redirect_url == $BLACKLIST_REDIRECT ]];then
                printf "[${red} %s ${resetColor}] $redirect_url\n" "$code"
            else
                printf "[${green} %s ${resetColor}] $redirect_url\n" "$code"
            fi
        fi
        printf "%s\n%s\n" "[ $host_target ]---------------------------" "($redirect_url)">>"result/proxy_${PROXY_PORT}_$code.txt"
        rm -rf $tmp_file
        exit;
    elif [[ $code != "000" ]]; then
        if [ "$echo_type" == "bulk" ]; then
            printf "[~%0${5}d~ ~%s~]~%-100s~[${yellow}%s${resetColor}]\n" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
        else
            printf "[${yellow} %s ${resetColor}]\n" "$code"
        fi
        printf "%s\n%s\n" "[ $host_target ]---------------------------" "$(cat $tmp_file | head -n 10)">>"result/proxy_${PROXY_PORT}_$code.txt"
        rm -rf $tmp_file
        exit;
    else
        if [ "$echo_type" == "bulk" ]; then
            printf "[~%0${5}d~ ~%s~]~%-100s~[${red}%s${resetColor}]\r" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
        else
            printf "[${red} %s ${resetColor}]\n" "$code"
        fi
        rm -rf $tmp_file
        exit;
    fi

    rm -rf $tmp_file
}
function_get_folder(){
    folder=$1
    if [ ! -e "$folder" ] || [ ! -f "$folder" ] && [ ! -d "$folder" ]; then
        echo "Error: "${folder}" Kosong."
        exit;
    fi
    function_to_exec=$2
    echo "Thread                : $DEFAULT_THREAD"
    echo "Timeout               : $DEFAULT_TIMEOUT"
    echo "Max Timeout           : $DEFAULT_MAX_TIMEOUT"
    echo "Max Connect           : $DEFAULT_CONNECT_TIMEOUT"
    echo "Blacklist Redirect    : $BLACKLIST_REDIRECT"
    echo "User Agent            : $DEFAULT_USER_AGENT"
    echo "SNI HOST              : $DEFAULT_SNI_HOST"
    echo
    echo "Target                : $folder"
    echo "Exec                  : $function_to_exec"
    echo
    file_to_scan="tmp/host.txt"
    find "$folder" -type f -print0 | while IFS= read -r -d '' file; do
        echo "Job start for $file";
        sed 's/\r$//' "$file"|sort -u > $file_to_scan
        # mv "$file" archive
        file_total_lines=$(cat $file_to_scan| wc -l)
        pad_number_length=$(echo $file_total_lines|awk '{ print length; }')
        ./bin/parallel -k -j $DEFAULT_THREAD -a $file_to_scan $function_to_exec {} {#} $file_total_lines $pad_number_length
        rm $file_to_scan
        echo
        echo "Job done for $file";
    done
    echo
}
banner(){
    echo
    echo "BugHunter Operator"
    echo
}
helper_banner(){
    banner
    echo "Usage:"
}
helper(){
    echo "    $1                                  "
}
getparam(){
    for i in "$@"; do
        case $i in
            -ppr=*|--proxy_prefix=*)
            export PROXY_PREFIX="${i#*=}"
            shift # past argument=value
            ;;
            -pho=*|--proxy_host=*)
            export PROXY_HOST="${i#*=}"
            shift # past argument=value
            ;;
            -ppo=*|--proxy_port=*)
            export PROXY_PORT="${i#*=}"
            shift # past argument=value
            ;;
            -pta=*|--proxy_target=*)
            export PROXY_TARGET="${i#*=}"
            shift # past argument=value
            ;;
            -li=*|--list=*)
            export LIST="${i#*=}"
            shift # past argument=value
            ;;
            
            --default)
            DEFAULT=YES
            shift # past argument with no value
            ;;
            -*|--*)
            echo "Unknown option $i"
            exit 1
            ;;
            *)
            ;;
        esac
    done
}
start() {
  if [ $# -lt 1 ]; then
    start base
    return
  fi
  check_deps
  case $1 in
    "help" )
    helper_banner
    helper "$0 help                                                            Show this message"
    helper "$0 scan                                                            Scan List"
    helper "$0 scanall                                                         Scan All List "
    helper "$0 generate                                                        Generate list IP"
    helper "$0 update                                                          Update this script"
    echo 
    ;;

    "scan" )
        case $2 in "help")
            helper_banner
            helper "$0 $1 help                                  Show this message"
            helper "$0 $1 sni                                   Scan SNI"
            helper "$0 $1 http_ws                               Scan HTTP WebSocket"
            helper "$0 $1 https_ws                              Scan SNI+HTTP WebSocket"
            helper "$0 $1 http_status                           Scan HTTP status"
            helper "$0 $1 https_status                          Scan HTTPS status"
            helper "$0 $1 proxy [help,*HOST[proxy]]             Scan Proxy status"
            echo
        ;;
        "sni" )
            case $3 in "help")
            helper_banner
            helper "$0 $1 $2 help                         Show this message"
            helper "$0 $1 $2 go [list_folder]             Scan SNI bulk list (Default folder : \"$PWD/list\")"
            echo
            ;;
            "go" )
                if [ ! -z "${4}" ]; then
                    banner
                    function_get_folder "$4" "function_sni"
                else
                    banner
                    function_get_folder "$PWD/list" "function_sni"
                fi
            ;;
            "base" )
                start scan $2 help
            ;;
            * )
                start scan $2 base
            ;;
            esac
        ;;
        "http_status" )
            case $3 in "help")
            helper_banner
            helper "$0 $1 $2 help                         Show this message"
            helper "$0 $1 $2 go [list_folder]           Scan SNI bulk list (Default folder : \"$PWD/list\")"
            echo
            ;;
            "go" )
                if [ ! -z "${4}" ]; then
                    banner
                    function_get_folder "$4" "function_$2"
                else
                    banner
                    function_get_folder "$PWD/list" "function_$2"
                fi
            ;;
            "base" )
                start scan $2 help
            ;;
            * )
                start scan $2 base
            ;;
            esac
        ;;
        "http_ws" )
            case $3 in "help")
            helper_banner
            helper "$0 $1 $2 help                         Show this message"
            helper "$0 $1 $2 go [list_folder]             Scan SNI bulk list (Default folder : \"$PWD/list\")"
            echo
            ;;
            "go" )
                if [ ! -z "${4}" ]; then
                    banner
                    function_get_folder "$4" "function_$2"
                else
                    banner
                    function_get_folder "$PWD/list" "function_$2"
                fi
            ;;
            "base" )
                start scan $2 help
            ;;
            * )
                start scan $2 base
            ;;
            esac
        ;;
        "https_ws" )
            case $3 in "help")
            helper_banner
            helper "$0 $1 $2 help                         Show this message"
            helper "$0 $1 $2 go [list_folder]           Scan SNI bulk list (Default folder : \"$PWD/list\")"
            echo
            ;;
            "go" )
                if [ ! -z "${4}" ]; then
                    banner
                    function_get_folder "$4" "function_$2"
                else
                    banner
                    function_get_folder "$PWD/list" "function_$2"
                fi
            ;;
            "base" )
                start scan $2 help
            ;;
            * )
                start scan $2 base
            ;;
            esac
        ;;
        "https_status" )
            case $3 in "help")
            helper_banner
            helper "$0 $1 $2 help                         Show this message"
            helper "$0 $1 $2 go [list_folder]           Scan SNI bulk list (Default folder : \"$PWD/list\")"
            echo
            ;;
            "go" )
                if [ ! -z "${4}" ]; then
                    banner
                    function_get_folder "$4" "function_$2"
                else
                    banner
                    function_get_folder "$PWD/list" "function_$2"
                fi
            ;;
            "base" )
                start scan $2 help
            ;;
            * )
                start scan $2 base
            ;;
            esac
        ;;

        "proxy" )
            getparam "$@"
            if [ ! -z "${LIST}" ]; then
                export LIST=$LIST
            else
                export LIST="$PWD/list"
            fi
            case $3 in "help")
            helper_banner
            helper "$0 $1 $2 help                         Show this message"
            helper "$0 $1 $2 singgle [*HOST [proxy]]      Scan Proxy singgle HOST"
            helper "$0 $1 $2 bulk --list [folder/file]    Scan Proxy bulk list Directory (Default folder : \"$PWD/list\")"
            echo
            echo "Example :"
            helper "$0 $1 $2 singgle domain.com"
            helper "$0 $1 $2 singgle domain.com --proxy_host=google.com --proxy_port=443 --proxy_prefix=https://"
            helper "$0 $1 $2 singgle domain.com --proxy_port=443 --proxy_prefix=https://"
            helper "$0 $1 $2 singgle domain.com --proxy_port=443 --proxy_prefix=https:// --proxy_target=http://ifconfig.me"
            echo
            helper "$0 $1 $2 bulk"
            helper "$0 $1 $2 bulk --proxy_host=google.com --proxy_port=443 --proxy_prefix=https://"
            helper "$0 $1 $2 bulk --proxy_port=443 --proxy_prefix=https://"
            helper "$0 $1 $2 bulk --proxy_port=443 --proxy_prefix=https:// --proxy_target=http://ifconfig.me"
            echo
            helper "$0 $1 $2 bulk --list=\"archive\" "
            helper "$0 $1 $2 bulk --list=\"archive\" --proxy_host=google.com --proxy_port=443 --proxy_prefix=https://"
            helper "$0 $1 $2 bulk --list=\"archive\" --proxy_port=443 --proxy_prefix=https://"
            helper "$0 $1 $2 bulk --list=\"archive\" --proxy_port=443 --proxy_prefix=https:// --proxy_target=http://ifconfig.me"                  
            echo
            ;;
            "singgle" )
                if [ ! -z "${4}" ]; then
                    banner
                    printf "%s\n" "Scanning singgle HOST : $4" 
                    printf "%s" "$(function_$2 $4 "singgle")"
                    echo
                else
                    banner
                    echo "Error, no HOST, Ex : $0 $1 $2 $3 domain.com"
                fi
            ;;
            "bulk" )
                
                banner
                function_get_folder "$LIST" "function_$2"
            ;;
            "base" )
                start scan $2 help
            ;;
            * )
                start scan $2 base
            ;;
            esac
        ;;

        "base" )
            # echo "------------base----------------"
            # echo $1 $2 $3
            # echo "------------endbase----------------"
            start $1 help
        ;;
        * )
        # echo "-------------***--------------"
        # echo $1 $2 $3
        # echo "-------------end ***--------------"
            start $1 base
        ;;
        esac
    ;;

    "generate" )
        case $2 in "help")
            helper_banner
            helper "$0 $1 help                                   Show this message"
            helper "$0 $1 ip [help,[[start-end][ip/prefix]]      Generate Range IP"
            echo
        ;;
        "ip")
            case $3 in "help")
            helper_banner
            helper "$0 $1 $2 help                                      Show this message"
            helper "$0 $1 $2 [[start-end][ip/prefix]]                  Generate IP and save to default location"
            helper "$0 $1 $2 [[start-end][ip/prefix]] show             Show output"
            helper "$0 $1 $2 [[start-end][ip/prefix]] save [path]      Save to custom location"
            echo 
            helper "Generate IP based on range [[start-end][ip/prefix]]"
            helper "Default save to \"$PWD/list/[[start-end][ip_prefix]].txt\""
            echo
            echo "Example :"
            helper "$0 $1 $2 192.168.1.1-10"
            helper "$0 $1 $2 192.168.1.1-10 save /tmp/save.txt"
            helper "$0 $1 $2 192.168.1.1-10 show"
            helper "$0 $1 $2 192.168.1.1/32 show"
            helper "$0 $1 $2 192.168.1.1/24 show"
            helper "$0 $1 $2 192.168.1.1/16 show"
            echo
            ;;
            "go" )
                if [ ! -z "${4}" ]; then
                    echo $0 $1 $2 $3 $4 $5 $6
                    banner
                    printf "%s\n\n" "Generating IP : $4 " 
                    local generate=$(nmap -sL -n $4 | egrep -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
                    if [ ! -z "$generate" ]; then
                    
                        if [ "$5" == "show" ]; then
                            printf "%s" "$generate"
                        else
                            
                            if [ ! -z "${6}" ]; then
                                echo $generate | tr " " "\n">"$6"
                                printf "%s" "Saved to : $6"
                            else
                                save=$(echo $4|sed 's/\//_/g')
                                echo $generate | tr " " "\n">"$PWD/list/${save}.txt"
                                printf "%s" "Saved to : $PWD/list/${save}.txt"
                            fi
                        fi
                    else
                        echo "ERROR"
                    fi
                    echo
                    echo
                else
                    start $1 $2 help
                fi
            ;;
            * ) 
                start $1 $2 go $3 $4 $5
            ;;
            esac
        ;;
        "base" )
            start $1 help
        ;;
        * )
            start $1 base
        ;;
        esac
    ;;

    "scanall" )
        case $2 in "help")
            helper_banner
            helper "$0 $1 help                                   Show this message"
            helper "$0 $1 list                                   Using List"
            echo
        ;;
        "list")
            case $3 in "help")
            helper_banner
            helper "$0 $1 $2 help                         Show this message"
            helper "$0 $1 $2 singgle [*domain]            Scan SNI singgle domain (Ex: $0 $1 sni singgle domain.com)"
            helper "$0 $1 $2 bulk [list_folder]           Scan SNI bulk list (Default folder : \"$PWD/list\")"
            echo
            ;;
            "singgle" )
                if [ ! -z "${4}" ]; then
                    banner
                    printf "%s" "Scanning singgle domain : $4 " 
                    printf "%s" "$(function_sni $4)"
                    echo
                else
                    banner
                    echo "Error, no domain, Ex : $0 $1 $2 $3 domain.com"
                fi
            ;;
            "bulk" )
                if [ ! -z "${4}" ]; then
                    banner
                    function_get_folder "$4" "function_sni"
                else
                    banner
                    function_get_folder "$PWD/list" "function_sni"
                fi
            ;;
            "base" )
                start $1 $2 help
            ;;
            * )
                start $1 $2 base
            ;;
            esac
        ;;
        "proxy" )
            getparam "$@"
            function_get_folder "$PWD/list" "function_proxy"
        ;;
        "base" )
            # start $1 help
            banner
            function_get_folder "$PWD/list" "function_sni"
            function_get_folder "$PWD/list" "function_http_status"
            function_get_folder "$PWD/list" "function_https_status"
        ;;
        * )
            start $1 base
            start $1 proxy --proxy_port=80 --proxy_prefix=http://
            start $1 proxy --proxy_port=443 --proxy_prefix=https://
        ;;
        esac
    ;;

    "template" )
        case $2 in "help")
            helper_banner
            helper "$0 $1 help                                   Show this message"
            helper "$0 $1 range_ip [type[help,[start-end]]]      Generate Range IP"
            helper "$0 $1 subnet_ip [type[help,[ip/prefix]]]     Generate Range Subnet IP"
            echo
        ;;
        "range_ip")
            case $3 in "help")
            helper_banner
            helper "$0 $1 $2 help                         Show this message"
            helper "$0 $1 $2 singgle [*domain]            Scan SNI singgle domain (Ex: $0 $1 sni singgle domain.com)"
            helper "$0 $1 $2 bulk [list_folder]           Scan SNI bulk list (Default folder : \"$PWD/list\")"
            echo
            ;;
            "singgle" )
                if [ ! -z "${4}" ]; then
                    banner
                    printf "%s" "Scanning singgle domain : $4 " 
                    printf "%s" "$(function_sni $4)"
                    echo
                else
                    banner
                    echo "Error, no domain, Ex : $0 $1 $2 $3 domain.com"
                fi
            ;;
            "bulk" )
                if [ ! -z "${4}" ]; then
                    banner
                    function_get_folder "$4" "function_sni"
                else
                    banner
                    function_get_folder "$PWD/list" "function_sni"
                fi
            ;;
            "base" )
                start $1 $2 help
            ;;
            * )
                start $1 $2 base
            ;;
            esac
        ;;
        "base" )
            start $1 help
        ;;
        * )
            start $1 base
        ;;
        esac
    ;;
    "update" )
      updatescript
    ;;
    "base" )
      start help
    ;;
    
    * )
      start base
    ;;
  esac
}
export -f color function_sni function_http_status function_https_status function_proxy function_http_ws function_https_ws
rm -rf  tmp
mkdir -p result
mkdir -p list
mkdir -p archive
mkdir -p tmp
mkdir -p bin
start "$@"