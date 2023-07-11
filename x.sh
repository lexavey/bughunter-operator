#!/bin/bash

CONFIG_FILE="config.sh"
source $CONFIG_FILE

function handle_sigint() {
    echo "Received Ctrl-C signal. Do you want to pause or exit?"
    read -p "Enter 'p' to pause or 'e' to exit: " choice
    case $choice in
        p|P)
            echo "Pausing script. Press Enter to resume."
            read
            ;;
        *)
            echo "Exiting script."
            exit
            ;;
    esac
}

trap handle_sigint SIGINT

# The rest of your script goes here...
colorize_text(){
    red=$'\e[01;31m'
    green=$'\e[01;32m'
    yellow=$'\e[01;33m'
    blue=$'\e[01;34m'
    magenta=$'\e[01;35m'
    resetColor=$'\e[0m'
}
parallel(){
    folder=$1
    function_to_exec=$2
    printf "Thread                : $DEFAULT_THREAD\n"
    printf "Timeout               : $DEFAULT_TIMEOUT\n"
    printf "Max Timeout           : $DEFAULT_MAX_TIMEOUT\n"
    printf "Max Connect           : $DEFAULT_CONNECT_TIMEOUT\n"
    printf "Blacklist Redirect    : $BLACKLIST_REDIRECT\n"
    printf "User Agent            : $DEFAULT_USER_AGENT\n"
    printf "SNI HOST              : $DEFAULT_SNI_HOST\n\n"
    printf "Target                : $folder\n"
    printf "Exec                  : $function_to_exec\n\n"
    file_to_scan="tmp/host.txt"
    find "$folder" -type f -print0 | while IFS= read -r -d '' file; do
        printf "Job start for $file\n"
        sed 's/\r$//' "$file"|sort -u > $file_to_scan
        file_total_lines=$(cat $file_to_scan| wc -l)
        pad_number_length=$(echo $file_total_lines|awk '{ print length; }')
        ./bin/parallel -k -j $DEFAULT_THREAD -a $file_to_scan $function_to_exec {} "bulk" {#} $file_total_lines $pad_number_length | tr '\n' '\r'
        rm $file_to_scan
        printf "\nJob done for $file\n\n"
    done
}

# Define the update_setting function
update_setting() {
    setting_name=$1
    current_value=$(grep "^export $setting_name=" $CONFIG_FILE | cut -d'"' -f2)
    echo "Current value: $current_value"
    read -p "Do you want to update this setting? (y/n) " update_choice
    case $update_choice in
        y|Y)
            read -p "Enter new value: " new_value
            sed -i "s/^export $setting_name=.*/export $setting_name=\"$new_value\"/" $CONFIG_FILE
            echo "Setting updated!";;
        n|N)
            echo "Setting not updated.";;
        *)
            echo "Invalid choice. Setting not updated.";;
    esac
}
scan_sni(){
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
scan_sni_menu() {
    clear
    echo "=== SCAN SNI ==="
    echo "1. Scan SNI"
    echo "2. Settings"
    echo "3. Back to Main Menu"
    read -p "Enter your choice: " sni_choice
    case $sni_choice in
        1)
            if [ -z "$(ls -A list)" ]; then
                echo "The target folder 'list' is empty. Please add some domain lists before running the scan."
            else
                parallel "list" scan_sni
            fi
            ;;
        2) show_settings_menu ;;
        3) clear; main_menu ;;
        *) echo "Invalid option"; sleep 1; scan_sni_menu ;;
    esac
}


# Define the show_settings_menu function
show_settings_menu() {
    echo "Select a setting to update:"
    echo "1. Default SNI host"
    echo "2. Default user agent"
    echo "3. Blacklist redirect"
    echo "4. Default connect timeout"
    echo "5. Default max timeout"
    echo "6. Default timeout"
    echo "7. Default thread"
    echo "8. Return to main menu"
    read -p "Enter your choice: " settings_choice
    case $settings_choice in
        1) update_setting "DEFAULT_SNI_HOST" ;;
        2) update_setting "DEFAULT_USER_AGENT" ;;
        3) update_setting "BLACKLIST_REDIRECT" ;;
        4) update_setting "DEFAULT_CONNECT_TIMEOUT" ;;
        5) update_setting "DEFAULT_MAX_TIMEOUT" ;;
        6) update_setting "DEFAULT_TIMEOUT" ;;
        7) update_setting "DEFAULT_THREAD" ;;
        8) return ;;
        *) echo "Invalid choice, please try again." ;;
    esac
    show_settings_menu
}

# Define the show_menu function
show_menu() {
    echo "Select an option:"
    echo "1. Scan"
    echo "2. Generate"
    echo "3. Help"
    echo "4. Settings"
    echo "5. Exit"
    read -p "Enter your choice: " menu_choice
    case $menu_choice in
        1)
            echo "Select an option:"
            echo "1. SNI"
            echo "2. HTTP Status"
            echo "3. HTTPS Status"
            echo "4. Proxy Status"
            read -p "Enter your choice: " scan_choice
            case $scan_choice in
                1) scan_sni_menu ;;
                2) echo "Starting HTTP status scan..." ;;
                3) echo "Starting HTTPS status scan..." ;;
                4) echo "Starting proxy status scan..." ;;
                *) echo "Invalid choice, please try again." ;;
            esac
            ;;
        2)
            echo "Select an option:"
            echo "1. Generate IP"
            echo "2. Generate Target"
            read -p "Enter your choice: " generate_choice
            case $generate_choice in
                1) echo "Generating IP list..." ;;
                2) echo "Generating target list..." ;;
                *) echo "Invalid choice, please try again." ;;
            esac
            ;;
        3) echo "Help menu selected." ;;
        4) show_settings_menu ;;
        5) exit ;;
        *) echo "Invalid choice, please try again." ;;
    esac
    show_menu
}
export -f scan_sni colorize_text
# Call the show_menu function to start the program
show_menu
