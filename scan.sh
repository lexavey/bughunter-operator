#!/bin/bash -e
export DEFAULT_SNI_HOST="sanggoro5.nextvpn.cc" ## sni_curl,sni_openssl
export DEFAULT_USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.102 Safari/537.36 OPR/90.0.4480.100" ## http_status,https_status
export BLACKLIST_REDIRECT="http://www.google.com/" ## http_status,https_status
export DEFAULT_CONNECT_TIMEOUT="5" ## sni_curl
export DEFAULT_MAX_TIMEOUT="5" ## sni_curl
export DEFAULT_TIMEOUT="10" ## sni_openssl
export DEFAULT_THREAD="100" ## bulk


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

colorize_text(){
    red=$'\e[01;31m'
    green=$'\e[01;32m'
    yellow=$'\e[01;33m'
    blue=$'\e[01;34m'
    magenta=$'\e[01;35m'
    resetColor=$'\e[0m'
}

check_deps(){
    if ! has "./parallel"; then
        DOWNLOAD http://git.savannah.gnu.org/cgit/parallel.git/plain/src/parallel parallel
        chmod 755 parallel
        printf "will cite" | ./parallel --citation &> /dev/null
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
    host_check=$DEFAULT_SNI_HOST
    echo_type=$2
    colorize_text
    gocurl=$(curl -o /dev/null -s "http://$host_target" -k -H "user-agent: $DEFAULT_USER_AGENT" --connect-timeout $DEFAULT_CONNECT_TIMEOUT --max-time $DEFAULT_MAX_TIMEOUT --write-out '%{http_code} %{redirect_url}')
    code=$(printf '%s' "$gocurl" | awk '{print $1}')
    if [[ $code == "200" ]]; then
        if [ "$echo_type" == "bulk" ]; then
            printf "[~%0${5}d~ ~%s~]~%-100s~[${green}%s${resetColor}]\n" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
        else
            printf "[${green} %s ${resetColor}]\n" "$code"
        fi
    elif [[ $code == "301" ]]; then
        redirect_url=$(printf '%s' "$gocurl" | awk '{print $2}')
        if [ "$echo_type" == "bulk" ]; then
            if [[ $redirect_url == $BLACKLIST_REDIRECT ]];then
                printf "[~%0${5}d~ ~%s~]~%-100s~[${red}%s${resetColor}]\n" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
            else
                printf "[~%0${5}d~ ~%s~]~%-100s~[${green}%s${resetColor}]\n" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
                echo "$host_target $redirect_url">>"result/http_status_${code}_redirect.txt"
            fi
        else
            if [[ $redirect_url == $BLACKLIST_REDIRECT ]];then
                printf "[${red} %s ${resetColor}] $redirect_url\n" "$code"
            else
                printf "[${green} %s ${resetColor}] $redirect_url\n" "$code"
                echo "$host_target $redirect_url">>"result/http_status_${code}_redirect.txt"
            fi
        fi
    elif [[ $code != "000" ]]; then
        if [ "$echo_type" == "bulk" ]; then
            printf "[~%0${5}d~ ~%s~]~%-100s~[${yellow}%s${resetColor}]\n" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
        else
            printf "[${yellow} %s ${resetColor}]\n" "$code"
        fi
    else
        if [ "$echo_type" == "bulk" ]; then
            printf "[~%0${5}d~ ~%s~]~%-100s~[${red}%s${resetColor}]\r" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
        else
            printf "[${red} %s ${resetColor}]\n" "$code"
        fi
    fi




    echo "$host_target">>"result/http_status_$code.txt"
}
func_https_status(){
    host_target=$1
    host_check=$DEFAULT_SNI_HOST
    echo_type=$2
    colorize_text
    gocurl=$(curl -o /dev/null -s "https://$host_target" -k -H "user-agent: $DEFAULT_USER_AGENT" --connect-timeout $DEFAULT_CONNECT_TIMEOUT --max-time $DEFAULT_MAX_TIMEOUT --write-out '%{http_code} %{redirect_url}')
    code=$(printf '%s' "$gocurl" | awk '{print $1}')
    if [[ $code == "200" ]]; then
        if [ "$echo_type" == "bulk" ]; then
            printf "[~%0${5}d~ ~%s~]~%-100s~[${green}%s${resetColor}]\n" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
        else
            printf "[${green} %s ${resetColor}]\n" "$code"
        fi
    elif [[ $code == "301" ]]; then
        redirect_url=$(printf '%s' "$gocurl" | awk '{print $2}')
        if [ "$echo_type" == "bulk" ]; then
            if [[ $redirect_url == $BLACKLIST_REDIRECT ]];then
                printf "[~%0${5}d~ ~%s~]~%-100s~[${red}%s${resetColor}]\n" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
            else
                printf "[~%0${5}d~ ~%s~]~%-100s~[${green}%s${resetColor}]\n" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
                echo "$host_target $redirect_url">>"result/https_status_${code}_redirect.txt"
            fi
        else
            if [[ $redirect_url == $BLACKLIST_REDIRECT ]];then
                printf "[${red} %s ${resetColor}] $redirect_url\n" "$code"
            else
                printf "[${green} %s ${resetColor}] $redirect_url\n" "$code"
                echo "$host_target $redirect_url">>"result/https_status_${code}_redirect.txt"
            fi
        fi
    elif [[ $code != "000" ]]; then
        if [ "$echo_type" == "bulk" ]; then
            printf "[~%0${5}d~ ~%s~]~%-100s~[${yellow}%s${resetColor}]\n" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
        else
            printf "[${yellow} %s ${resetColor}]\n" "$code"
        fi
    else
        if [ "$echo_type" == "bulk" ]; then
            printf "[~%0${5}d~ ~%s~]~%-100s~[${red}%s${resetColor}]\r" "${3}" "${4}" "$host_target~" "~$code~" | tr ' ~' '- '
        else
            printf "[${red} %s ${resetColor}]\n" "$code"
        fi
    fi




    echo "$host_target">>"result/https_status_$code.txt"
}

func_get_folder(){
    folder=$1
    function_to_exec=$2
    file_to_scan="tmp/host.txt"
    find "$folder" -type f -print0 | while IFS= read -r -d '' file; do
        echo "Job start for $file";
        sed 's/\r$//' "$file"|sort -u > $file_to_scan
        # mv "$file" archive
        file_total_lines=$(cat $file_to_scan| wc -l)
        pad_number_length=$(echo $file_total_lines|awk '{ print length; }')
        ./parallel -k -j $DEFAULT_THREAD -a $file_to_scan $function_to_exec {} "bulk" {#} $file_total_lines $pad_number_length
        rm $file_to_scan
        echo
        echo "Job done for $file";
    done
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

start() {
  if [ $# -lt 1 ]; then
    start base
    return
  fi
  check_deps
  case $1 in
    "help" )
    helper_banner
    helper "$0 help                                                                 Show this message"
    helper "$0 scan [type[help,sni_curl,sni_openssl,http_status,https_status]]      Scan List"
    helper "$0 generate [type[help,range_ip]]                                       Generate list IP"
    echo 
    ;;

    "scan" )
        case $2 in "help")
            helper_banner
            helper "$0 $1 help                                  Show this message"
            helper "$0 $1 sni_curl [type[help,domain]]          Scan SNI with curl"
            helper "$0 $1 sni_openssl [type[help,IP]]           Scan SNI with openssl"
            helper "$0 $1 http_status [type[help,IP]]           Scan HTTP status"
            helper "$0 $1 https_status [type[help,IP]]          Scan HTTPS status"
            echo
        ;;
        "sni_curl" )
            case $3 in "help")
            helper_banner
            helper "$0 $1 $2 help                         Show this message"
            helper "$0 $1 $2 singgle [*domain]            Scan SNI singgle domain (Ex: $0 $1 sni_curl singgle domain.com)"
            helper "$0 $1 $2 bulk [list_folder]           Scan SNI bulk list (Default folder : \"$PWD/list\")"
            # helper "                         Scan SNI with given list (folder list)                                                  "
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
            helper "$0 $1 $2 singgle [*domain]            Scan SNI singgle domain (Ex: $0 $1 sni_curl singgle domain.com)"
            helper "$0 $1 $2 bulk [list_folder]           Scan SNI bulk list (Default folder : \"$PWD/list\")"
            # helper "                         Scan SNI with given list (folder list)                                                  "
            echo
            ;;
            "singgle" )
                if [ ! -z "${4}" ]; then
                    banner
                    printf "%s" "Scanning singgle domain : $4 " 
                    printf "%s" "$(func_sni_openssl $4)"
                    echo
                else
                    banner
                    echo "Error, no domain, Ex : $0 $1 $2 $3 domain.com"
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
            helper "$0 $1 $2 singgle [*domain]            Scan SNI singgle domain (Ex: $0 $1 sni_curl singgle domain.com)"
            helper "$0 $1 $2 bulk [list_folder]           Scan SNI bulk list (Default folder : \"$PWD/list\")"
            # helper "                         Scan SNI with given list (folder list)                                                  "
            echo
            ;;
            "singgle" )
                if [ ! -z "${4}" ]; then
                    banner
                    printf "%s" "Scanning singgle domain : $4 " 
                    printf "%s" "$(func_$2 $4)"
                    echo
                else
                    banner
                    echo "Error, no domain, Ex : $0 $1 $2 $3 domain.com"
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
            helper "$0 $1 $2 singgle [*domain]            Scan SNI singgle domain (Ex: $0 $1 sni_curl singgle domain.com)"
            helper "$0 $1 $2 bulk [list_folder]           Scan SNI bulk list (Default folder : \"$PWD/list\")"
            # helper "                         Scan SNI with given list (folder list)                                                  "
            echo
            ;;
            "singgle" )
                if [ ! -z "${4}" ]; then
                    banner
                    printf "%s" "Scanning singgle domain : $4 " 
                    printf "%s" "$(func_$2 $4)"
                    echo
                else
                    banner
                    echo "Error, no domain, Ex : $0 $1 $2 $3 domain.com"
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
            helper "$0 $1 range_ip [help,[start-end]]            Generate Range IP"
            helper "$0 $1 subnet_ip [help,[ip/prefix]]           Generate Range Subnet IP"
            echo
        ;;
        "range_ip")
            case $3 in "help")
            helper_banner
            helper "$0 $1 $2 help                         Show this message"
            helper "$0 $1 $2 [start-end]                  Generate IP and save to default location"
            helper "$0 $1 $2 [start-end] show             Show output"
            helper "$0 $1 $2 [start-end] save [path]      Save to custom location"
            echo 
            helper "Generate IP based on range [start-end]"
            helper "Default save to \"$PWD/list/[start-end].txt\""
            echo
            echo "Example :"
            helper "$0 $1 $2 192.168.1.1-10"
            helper "$0 $1 $2 192.168.1.1-10 save /tmp/save.txt"
            helper "$0 $1 $2 192.168.1.1-10 show"
            echo
            ;;
            "go" )
                if [ ! -z "${4}" ]; then
                    echo $0 $1 $2 $3 $4 $5 $6
                    banner
                    printf "%s\n" "Generating IP : $4 " 
                    local generate=$(nmap -sL -n $4 | egrep -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
                    if [ "$5" == "show" ]; then
                        # printf "%s" "$generate"
                        echo "showne";
                    fi
                    echo
                else
                    start $1 $2 help
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
    "base" )
      start help
    ;;
    
    * )
      start base
    ;;
  esac
}



export -f func_sni_curl func_sni_openssl colorize_text func_http_status func_https_status
rm -rf  tmp
mkdir -p result
mkdir -p list
mkdir -p archive
mkdir -p tmp
start "$@"