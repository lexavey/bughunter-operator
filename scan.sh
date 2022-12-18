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
  echo "Error: you need curl or wget to proceed" >&2;
  exit 1
fi

colorize_text(){
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
    colorize_text
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
func_sni_curl(){
    host_target=$1
    host_check=$DEFAULT_SNI_HOST
    echo_type=$2
    colorize_text
    code=$(
        curl --insecure -vvI --connect-to $host_target:443:$host_check:443 --connect-timeout $DEFAULT_CONNECT_TIMEOUT --max-time $DEFAULT_MAX_TIMEOUT "https://$host_target"  2>&1 | awk 'BEGIN { cert=0 } /^\* SSL connection/ { cert=1 } /^\*/ { if (cert) print } ' | grep subject
    )
    if [ ! -z "${code}" ]; then
        if [ "$echo_type" == "bulk" ]; then
            printf "[~%0${5}d~ ~%s~]~%-100s~[${green}%s${resetColor}]\n" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
        else
            printf "[${green} %s ${resetColor}]\n" "$code"
        fi
        echo "$host_target">>"result/sni_curl.txt"
    else
        if [ "$echo_type" == "bulk" ]; then
            printf "[~%0${5}d~ ~%s~]~%-100s~[${red}%s${resetColor}]\r" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
        else
            printf "[${red} %s ${resetColor}]\n" "$code"
        fi
    fi
}
func_sni_openssl(){
    host_target=$1
    host_check=$DEFAULT_SNI_HOST
    echo_type=$2
    colorize_text
    code=$(
        echo | timeout $DEFAULT_TIMEOUT openssl s_client -servername $host_target -connect $host_check:443 -no_check_time 2>/dev/null | grep -F subject
        )
    
    if [ ! -z "${code}" ]; then
        if [ "$echo_type" == "bulk" ]; then
            printf "[~%0${5}d~ ~%s~]~%-100s~[${green}%s${resetColor}]\n" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
        else
            printf "[${green} %s ${resetColor}]\n" "$code"
        fi
        echo "$host_target">>"result/sni_openssl.txt"
    else
        if [ "$echo_type" == "bulk" ]; then
            printf "[~%0${5}d~ ~%s~]~%-100s~[${red}%s${resetColor}]\r" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
        else
            printf "[${red} %s ${resetColor}]\n" "$code"
        fi
    fi
}
func_http_status(){
    host_target=$1
    echo_type=$2
    tmp_file=$(mktemp -u tmp/HTTP_XXXXXXX)
    colorize_text
    gocurl=$(curl -o $tmp_file -s "http://$host_target" -k -H "user-agent: $DEFAULT_USER_AGENT" --connect-timeout $DEFAULT_CONNECT_TIMEOUT --max-time $DEFAULT_MAX_TIMEOUT --write-out '%{http_code} %{redirect_url}')
    code=$(printf '%s' "$gocurl" | awk '{print $1}')
    if [[ $code == "200" ]]; then
        if [ "$echo_type" == "bulk" ]; then
            printf "[~%0${5}d~ ~%s~]~%-100s~[${green}%s${resetColor}]\n" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
        else
            printf "[${green} %s ${resetColor}]\n" "$code"
        fi
        printf "%s\n%s\n" "[ $host_target ]---------------------------" "$(cat $tmp_file | head -n 10)">>"result/http_status_$code.txt"
        rm -rf $tmp_file
        exit;
    elif [ $code == "301" ] || [ $code == "302" ]; then
        redirect_url=$(printf '%s' "$gocurl" | awk '{print $2}')
        if [ "$echo_type" == "bulk" ]; then
            if [[ $redirect_url == $BLACKLIST_REDIRECT ]];then
                printf "[~%0${5}d~ ~%s~]~%-100s~[${red}%s${resetColor}]\n" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
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
        printf "%s\n%s\n" "[ $host_target ]---------------------------" "($redirect_url)">>"result/http_status_$code.txt"
        rm -rf $tmp_file
        exit;
    elif [[ $code != "000" ]]; then
        if [ "$echo_type" == "bulk" ]; then
            printf "[~%0${5}d~ ~%s~]~%-100s~[${yellow}%s${resetColor}]\n" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
        else
            printf "[${yellow} %s ${resetColor}]\n" "$code"
        fi
        printf "%s\n%s\n" "[ $host_target ]---------------------------" "$(cat $tmp_file | head -n 10)">>"result/http_status_$code.txt"
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
func_https_status(){
    host_target=$1
    echo_type=$2
    tmp_file=$(mktemp -u tmp/HTTPS_XXXXXXX)
    colorize_text
    gocurl=$(curl -o /dev/null -s "https://$host_target" -k -H "user-agent: $DEFAULT_USER_AGENT" --connect-timeout $DEFAULT_CONNECT_TIMEOUT --max-time $DEFAULT_MAX_TIMEOUT --write-out '%{http_code} %{redirect_url}')
    code=$(printf '%s' "$gocurl" | awk '{print $1}')
    if [[ $code == "200" ]]; then
        if [ "$echo_type" == "bulk" ]; then
            printf "[~%0${5}d~ ~%s~]~%-100s~[${green}%s${resetColor}]\n" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
        else
            printf "[${green} %s ${resetColor}]\n" "$code"
        fi
        printf "%s\n%s\n" "[ $host_target ]---------------------------" "$(cat $tmp_file | head -n 10)">>"result/https_status_$code.txt"
        rm -rf $tmp_file
        exit;
    elif [ $code == "301" ] || [ $code == "302" ]; then
        redirect_url=$(printf '%s' "$gocurl" | awk '{print $2}')
        if [ "$echo_type" == "bulk" ]; then
            if [[ $redirect_url == $BLACKLIST_REDIRECT ]];then
                printf "[~%0${5}d~ ~%s~]~%-100s~[${red}%s${resetColor}]\n" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
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
        printf "%s\n%s\n" "[ $host_target ]---------------------------" "($redirect_url)">>"result/https_status_$code.txt"
        rm -rf $tmp_file
        exit;
    elif [[ $code != "000" ]]; then
        if [ "$echo_type" == "bulk" ]; then
            printf "[~%0${5}d~ ~%s~]~%-100s~[${yellow}%s${resetColor}]\n" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
        else
            printf "[${yellow} %s ${resetColor}]\n" "$code"
        fi
        printf "%s\n%s\n" "[ $host_target ]---------------------------" "$(cat $tmp_file | head -n 10)">>"result/https_status_$code.txt"
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
}
func_proxy(){
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
    colorize_text
    gocurl=$(curl -o $tmp_file -s "$PROXY_TARGET" -k -H "user-agent: $DEFAULT_USER_AGENT" --connect-timeout $DEFAULT_CONNECT_TIMEOUT --max-time $DEFAULT_MAX_TIMEOUT -x $proxy_url --proxy-insecure --write-out '%{http_code} %{redirect_url}')
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
func_get_folder(){
    folder=$1
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
        ./bin/parallel -k -j $DEFAULT_THREAD -a $file_to_scan $function_to_exec {} "bulk" {#} $file_total_lines $pad_number_length
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
    helper "$0 scan [help,sni_curl,sni_openssl,http_status,https_status,proxy] Scan List"
    helper "$0 scanall [help,list]                                             Scan All List sni_curl,sni_openssl,http_status,https_status,proxy"
    helper "$0 generate [help,ip]                                              Generate list IP"
    helper "$0 update                                                          Update this script"
    echo 
    ;;

    "scan" )
        case $2 in "help")
            helper_banner
            helper "$0 $1 help                                  Show this message"
            helper "$0 $1 sni_curl [help,HOST]                  Scan SNI with curl"
            helper "$0 $1 sni_openssl [help,HOST]               Scan SNI with openssl"
            helper "$0 $1 http_status [help,HOST]               Scan HTTP status"
            helper "$0 $1 https_status [help,HOST]              Scan HTTPS status"
            helper "$0 $1 proxy [help,*HOST[proxy]]             Scan Proxy status"
            echo
        ;;
        "sni_curl" )
            case $3 in "help")
            helper_banner
            helper "$0 $1 $2 help                         Show this message"
            helper "$0 $1 $2 singgle [*HOST]              Scan SNI singgle HOST (Ex: $0 $1 sni_curl singgle domain.com)"
            helper "$0 $1 $2 bulk [list_folder]           Scan SNI bulk list (Default folder : \"$PWD/list\")"
            echo
            ;;
            "singgle" )
                if [ ! -z "${4}" ]; then
                    banner
                    printf "%s" "Scanning singgle HOST : $4 " 
                    printf "%s" "$(func_sni_curl $4)"
                    echo
                else
                    banner
                    echo "Error, no domain, Ex : $0 $1 $2 $3 domain.com"
                fi
            ;;
            "bulk" )
                if [ ! -z "${4}" ]; then
                    banner
                    func_get_folder "$4" "func_sni_curl"
                else
                    banner
                    func_get_folder "$PWD/list" "func_sni_curl"
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
        
        "sni_openssl" )
            case $3 in "help")
            helper_banner
            helper "$0 $1 $2 help                         Show this message"
            helper "$0 $1 $2 singgle [*HOST]              Scan SNI singgle HOST (Ex: $0 $1 sni_curl singgle domain.com)"
            helper "$0 $1 $2 bulk [list_folder]           Scan SNI bulk list (Default folder : \"$PWD/list\")"
            echo
            ;;
            "singgle" )
                if [ ! -z "${4}" ]; then
                    banner
                    printf "%s" "Scanning singgle HOST : $4 " 
                    printf "%s" "$(func_sni_openssl $4)"
                    echo
                else
                    banner
                    echo "Error, no HOST, Ex : $0 $1 $2 $3 domain.com"
                fi
            ;;
            "bulk" )
                if [ ! -z "${4}" ]; then
                    banner
                    func_get_folder "$4" "func_sni_openssl"
                else
                    banner
                    func_get_folder "$PWD/list" "func_sni_openssl"
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
            helper "$0 $1 $2 singgle [*HOST]              Scan SNI singgle HOST (Ex: $0 $1 sni_curl singgle domain.com)"
            helper "$0 $1 $2 bulk [list_folder]           Scan SNI bulk list (Default folder : \"$PWD/list\")"
            echo
            ;;
            "singgle" )
                if [ ! -z "${4}" ]; then
                    banner
                    printf "%s" "Scanning singgle HOST : $4 " 
                    printf "%s" "$(func_$2 $4)"
                    echo
                else
                    banner
                    echo "Error, no HOST, Ex : $0 $1 $2 $3 domain.com"
                fi
            ;;
            "bulk" )
                if [ ! -z "${4}" ]; then
                    banner
                    func_get_folder "$4" "func_$2"
                else
                    banner
                    func_get_folder "$PWD/list" "func_$2"
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
            helper "$0 $1 $2 singgle [*HOST]              Scan SNI singgle HOST (Ex: $0 $1 sni_curl singgle domain.com)"
            helper "$0 $1 $2 bulk [list_folder]           Scan SNI bulk list (Default folder : \"$PWD/list\")"
            echo
            ;;
            "singgle" )
                if [ ! -z "${4}" ]; then
                    banner
                    printf "%s" "Scanning singgle HOST : $4 " 
                    printf "%s" "$(func_$2 $4)"
                    echo
                else
                    banner
                    echo "Error, no HOST, Ex : $0 $1 $2 $3 domain.com"
                fi
            ;;
            "bulk" )
                if [ ! -z "${4}" ]; then
                    banner
                    func_get_folder "$4" "func_$2"
                else
                    banner
                    func_get_folder "$PWD/list" "func_$2"
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
                    printf "%s" "$(func_$2 $4 "singgle")"
                    echo
                else
                    banner
                    echo "Error, no HOST, Ex : $0 $1 $2 $3 domain.com"
                fi
            ;;
            "bulk" )
                
                banner
                func_get_folder "$LIST" "func_$2"
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
            helper "$0 $1 $2 singgle [*domain]            Scan SNI singgle domain (Ex: $0 $1 sni_curl singgle domain.com)"
            helper "$0 $1 $2 bulk [list_folder]           Scan SNI bulk list (Default folder : \"$PWD/list\")"
            echo
            ;;
            "singgle" )
                if [ ! -z "${4}" ]; then
                    banner
                    printf "%s" "Scanning singgle domain : $4 " 
                    printf "%s" "$(func_sni_curl $4)"
                    echo
                else
                    banner
                    echo "Error, no domain, Ex : $0 $1 $2 $3 domain.com"
                fi
            ;;
            "bulk" )
                if [ ! -z "${4}" ]; then
                    banner
                    func_get_folder "$4" "func_sni_curl"
                else
                    banner
                    func_get_folder "$PWD/list" "func_sni_curl"
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
            func_get_folder "$PWD/list" "func_proxy"
        ;;
        "base" )
            # start $1 help
            banner
            func_get_folder "$PWD/list" "func_sni_curl"
            # func_get_folder "$PWD/list" "func_sni_openssl"
            func_get_folder "$PWD/list" "func_http_status"
            func_get_folder "$PWD/list" "func_https_status"
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
            helper "$0 $1 $2 singgle [*domain]            Scan SNI singgle domain (Ex: $0 $1 sni_curl singgle domain.com)"
            helper "$0 $1 $2 bulk [list_folder]           Scan SNI bulk list (Default folder : \"$PWD/list\")"
            echo
            ;;
            "singgle" )
                if [ ! -z "${4}" ]; then
                    banner
                    printf "%s" "Scanning singgle domain : $4 " 
                    printf "%s" "$(func_sni_curl $4)"
                    echo
                else
                    banner
                    echo "Error, no domain, Ex : $0 $1 $2 $3 domain.com"
                fi
            ;;
            "bulk" )
                if [ ! -z "${4}" ]; then
                    banner
                    func_get_folder "$4" "func_sni_curl"
                else
                    banner
                    func_get_folder "$PWD/list" "func_sni_curl"
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
export -f func_sni_curl func_sni_openssl colorize_text func_http_status func_https_status func_proxy
rm -rf  tmp
mkdir -p result
mkdir -p list
mkdir -p archive
mkdir -p tmp
mkdir -p bin
start "$@"