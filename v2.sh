#!/bin/bash

# function to display the menu
show_menu() {
    echo "Select an option:"
    echo "1. Option 1 - perform action A"
    echo "2. Option 2 - perform action B"
    echo "3. Option 3 - perform action C"
    echo "4. Exit"
}

# function to read the user's choice
get_choice() {
    read -p "Enter your choice: " choice
    case $choice in
        1) option1 ;;
        2) option2 ;;
        3) option3 ;;
        4) exit 0 ;;
        *) echo "Invalid choice. Please try again." ;;
    esac
}

# function for option 1
option1() {
    read -p "Enter a parameter for option 1: " param
    echo "You chose option 1 with parameter $param"
}

# function for option 2
option2() {
    read -p "Enter a parameter for option 2: " param
    echo "You chose option 2 with parameter $param"
}

# function for option 3
option3() {
    read -p "Enter a parameter for option 3: " param
    echo "You chose option 3 with parameter $param"
}

# function to display help for option 1
help_option1() {
    echo "Option 1 - perform action A"
    echo "Usage: $0 1 [parameter]"
}

# function to display help for option 2
help_option2() {
    echo "Option 2 - perform action B"
    echo "Usage: $0 2 [parameter]"
}

# function to display help for option 3
help_option3() {
    echo "Option 3 - perform action C"
    echo "Usage: $0 3 [parameter]"
}

# function to display global help
show_help() {
    echo "Usage: $0 [option] [parameter]"
    echo "Options:"
    echo "-h: Display this help message"
    echo "-m: Show menu"
    echo "-h1: Display help for option 1"
    echo "-h2: Display help for option 2"
    echo "-h3: Display help for option 3"
}

# check for command line options
while getopts "hm123:u:" opt; do
  case $opt in
    h)
      show_help
      exit 0
      ;;
    m)
      show_menu
      get_choice
      exit 0
      ;;
    1)
      option1 "$OPTARG"
      exit 0
      ;;
    2)
      option2 "$OPTARG"
      exit 0
      ;;
    3)
      option3 "$OPTARG"
      exit 0
      ;;
    h1)
      help_option1
      exit 0
      ;;
    h2)
      help_option2
      exit 0
      ;;
    h3)
      help_option3
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
  esac
done

# if no options are provided, show the menu
show_menu
get_choice

