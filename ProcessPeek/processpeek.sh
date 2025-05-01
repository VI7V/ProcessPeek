#!/bin/bash

# ProcessPeek - Dialog-based Linux Process and Resource Monitor
LOGFILE="$HOME/processpeek.log"

# Check for root permission
if [[ $EUID -ne 0 ]]; then
    dialog --title "Permission Denied" --msgbox "Please run this script as root!" 8 40
    clear
    exit 1
fi

# Ensure log file exists
touch "$LOGFILE"

# Function to list running processes
list_processes() {
    ps -eo pid,ppid,user,cmd,%mem,%cpu --sort=-%cpu | head -n 20 > /tmp/processes.txt
    dialog --title "Top Running Processes" --textbox /tmp/processes.txt 20 80
    rm -f /tmp/processes.txt
}

# Function to search for a process by name
search_process() {
    PROC_NAME=$(dialog --inputbox "Enter process name to search:" 8 40 3>&1 1>&2 2>&3)

    if [[ -z "$PROC_NAME" ]]; then
        dialog --msgbox "No process name entered!" 6 40
        return
    fi

    ps aux | grep -i "$PROC_NAME" | grep -v "grep" > /tmp/search.txt

    if [[ -s /tmp/search.txt ]]; then
        dialog --title "Search Results for '$PROC_NAME'" --textbox /tmp/search.txt 20 80
        echo "$(date): [SEARCH] '$PROC_NAME' searched by $USER" >> "$LOGFILE"
    else
        dialog --msgbox "No process found with name '$PROC_NAME'" 6 40
    fi

    rm -f /tmp/search.txt
}

# Function to kill a process by PID
kill_process() {
    PID=$(dialog --inputbox "Enter PID to kill:" 8 40 3>&1 1>&2 2>&3)

    if [[ ! "$PID" =~ ^[0-9]+$ ]]; then
        dialog --msgbox "Invalid PID entered!" 6 40
        return
    fi

    if ! ps -p "$PID" > /dev/null; then
        dialog --msgbox "No such process with PID $PID" 6 40
        return
    fi

    dialog --yesno "Are you sure you want to kill process PID $PID?" 7 40
    if [[ $? -eq 0 ]]; then
        kill -9 "$PID" &&         dialog --msgbox "Process $PID has been killed." 6 40 &&         echo "$(date): [KILL] Process $PID killed by $USER" >> "$LOGFILE"
    else
        dialog --msgbox "Operation cancelled." 6 40
    fi
}

# Function to view system resources
view_resources() {
    {
        echo "CPU Load:"
        top -bn1 | grep "Cpu(s)"
        echo ""
        echo "Memory Usage:"
        free -h
        echo ""
        echo "Disk Usage:"
        df -h
    } > /tmp/resources.txt

    dialog --title "System Resource Usage" --textbox /tmp/resources.txt 20 80
    rm -f /tmp/resources.txt
}

# Main menu
main_menu() {
    while true; do
        CHOICE=$(dialog --clear --backtitle "ProcessPeek"             --title "Main Menu"             --menu "Select an option:" 15 50 6             1 "List Running Processes"             2 "Search Process by Name"             3 "Kill a Process by PID"             4 "View System Resource Usage"             5 "Exit"             3>&1 1>&2 2>&3)

        case $CHOICE in
            1) list_processes ;;
            2) search_process ;;
            3) kill_process ;;
            4) view_resources ;;
            5) break ;;
        esac
    done
    clear
}

# Launch the menu
main_menu
