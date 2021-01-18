#!/bin/bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the  Free Software  Foundation, either  version 3 of the License, or
# (at your option) any later version.
#
# This  program  is  distributed  in the hope that  it  will be useful,
# but  WITHOUT ANY  WARRANTY; without  even  the  implied  warranty  of
# MERCHANTABILITY  or FITNESS  FOR  A  PARTICULAR  PURPOSE. See the GNU
# General Public License for more details.
#
# You should  have received  a copy  of the  GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#  _________________________________________________________________
# /                                                                 \
# | Author:       Marco Vitetta (also known as ErVito)              |
# | E-mail:       ervito.development [at] (NO SPAM) gmail [dot] com |
# | WebSite:      http://ervito.altervista.org                      |
# |_________________________________________________________________|
# |                                                                 |
# | Versions:                                                       |
# |   1.0.0       First public release                              |
# \_________________________________________________________________/

echo "LANResolver installer v1.0.0"
echo

if [[ ! -e "$HOME/LANResolver" ]]
then
    echo "Creating directory \"$HOME/LANResolver\"..."
    mkdir -p "$HOME/LANResolver"
fi

cd "$HOME/LANResolver"

echo "Creating the script..."
cat >LANResolver.sh <<'EOF'
#!/bin/bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the  Free Software  Foundation, either  version 3 of the License, or
# (at your option) any later version.
#
# This  program  is  distributed  in the hope that  it  will be useful,
# but  WITHOUT ANY  WARRANTY; without  even  the  implied  warranty  of
# MERCHANTABILITY  or FITNESS  FOR  A  PARTICULAR  PURPOSE. See the GNU
# General Public License for more details.
#
# You should  have received  a copy  of the  GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#  _________________________________________________________________
# /                                                                 \
# | Author:       Marco Vitetta (also known as ErVito)              |
# | E-mail:       ervito.development [at] (NO SPAM) gmail [dot] com |
# | WebSite:      http://ervito.altervista.org                      |
# |_________________________________________________________________|
# |                                                                 |
# | Versions:                                                       |
# |   1.0.0       First public release                              |
# \_________________________________________________________________/

#########################################################
###             CONFIGURATION PARAMETERS              ###
#########################################################
ENTRIES_TTL=900                         # Expressed in seconds.
SCAN_PERIOD=300                         # Expressed in seconds.
WEIGHT_DYNAMIC_RESOLUTIONS=1
WEIGHT_STATIC_RESOLUTIONS=0

#########################################################
###                     CONSTANTS                     ###
#########################################################
BASE_DIR_PATH="$HOME/LANResolver"
LAN_RESOLVER_MAJOR=1
LAN_RESOLVER_MINOR=0
LAN_RESOLVER_PATCH=0

#########################################################
###                     FUNCTIONS                     ###
#########################################################

# Public: Print debug messages (if the debug mode is enabled).
#
# The function expects two parameters:
#
# $1 - The debug level
# $2 - The message to printf if the level is greater than zero
function debug() {
    if (($1 > 0))
    then
        printf "$2"
    fi
}

# Public: Export the resolution list to a file.
#
# The function expects one parameter:
#
# $1 - The path to the file to be written
function export_resolutions() {
    if (($# > 0 && $# <= 2))
    then
        local quantifier="all"
        local filepath=""

        case $# in
            1)filepath=$1;;
            2)
                quantifier=$1
                filepath=$2
            ;;
        esac

        debug $verbosity "Exporting $quantifier resolutions to \"$filepath\"...\n"

        if [[ $quantifier == "all" ]]
        then
            if ((${resolutions[@]} > 0))
            then
                for resolution in ${resolutions[@]}
                do
                    echo $resolutions >>"$filepath"
                done
                debug $verbosity "Export completed.\n"
            else
                debug $verbosity "Resolutions list is empty.\n"
                debug $verbosity "Anything has been exported.\n"
            fi
        elif [[ $quantifier == "filtered" ]]
        then
            if ((${#filtered_resolutions_indexes[@]} > 0))
            then
                for i in ${filtered_resolutions_indexes[@]}
                do
                    echo ${resolutions[i]} >>"$filepath"
                done
                debug $verbosity "Export completed.\n"
            else
                debug $verbosity "Filtered resolutions list is empty.\n"
                debug $verbosity "Anything has been exported.\n"
            fi
        else
            debug $verbosity "Unexpected export quantifier \"$quantifier\".\n"
        fi
    else
        debug $verbosity "Export resolutions expects one or two parameters.\n"
    fi
}

# Public: Filter the resolution by type.
# 
# The function expects two parameters:
#
# $1 - The filter quantifier ("only" or "excluding")
# $2 - The type of the resolutions to filter on
#
# The positional index (in the array containing the
# resolutions) of each filtered  entry is stored in
# the global array "filtered_resolution_indexes".
function filter_resolutions() {
    filtered_resolutions_indexes=()
    if (($# == 2))
    then
        local filter_type=$2
        local i=0
        local quantifier=$1

        if [[ $quantifier == "only" || $quantifier == "excluding" ]]
        then
            for ((; i < ${#resolutions[@]}; i++))
            do
                resolution_type="$(get_resolution_type ${resolutions[i]})"
                if [[ $quantifier == "only" && $resolution_type == $filter_type ]]
                then
                    debug $verbosity "Filtering resolution \"${resolutions[i]}\".\n"
                    filtered_resolutions_indexes+=($i)
                fi
                if [[ $quantifier == "excluding" && $resolution_type != $filter_type ]]
                then
                    debug $verbosity "Filtering resolution \"${resolutions[i]}\".\n"
                    filtered_resolutions_indexes+=($i)
                fi
            done
        else
            debug $verbosity "Unexpected filter quantifier \"$quantifier\".\n"
        fi
    else
        debug $verbosity "Filter resolutions expects two parameters.\n"
    fi
}

# Public: Getter function for the IP address.
#
# $1 - The resolution from which extract the IP
#
# Returns the IP address of the resolution passed as argument to the function.
function get_ip_address() {
    local resolution=$1

    # Skip the first field (the resolution type)
    resolution=${resolution#*,}

    echo ${resolution%%,*}
}

# Public: Getter function for the MAC address.
#
# $1 - The resolution from which extract the MAC
#
# Returns the MAC address of the resolution passed as argument to the function.
function get_mac_address() {
    local resolution=$1

    # Skip the first field (the resolution type)
    resolution=${resolution#*,}

    # Skip the second field (the ip address)
    resolution=${resolution#*,}

    echo ${resolution%%,*}
}

# Public: Getter function for the resolution type.
#
# $1 - The resolution from which extract the type
#
# Returns the type of the resolution passed as argument to the function.
function get_resolution_type() {
    local resolution=$1

    echo "${resolution%%,*}"
}

# Public: Get the resolutions by the IP or the MAC address.
#
# $1 - Specify which kind of address has to be solved ("mac" or "ip")
# $2 - The MAC or the IP to be solved
#
# Returns the resolutions by the MAC or the IP address.
function get_resolutions() {
    local i=0
    local found_dynamic_resolution=false
    local found_static_resolution=false
    local output_resolutions=()

    for ((; i < ${#resolutions[@]}; i++))
    do
        if [[ "$(get_$1_address ${resolutions[i]})" == $2 ]]
        then
            output_resolutions+=("${resolutions[i]}")
            if [[ "$(get_resolution_type ${resolutions[i]})" == "dynamic" ]]
            then
                found_dynamic_resolution=true
            elif [[ "$(get_resolution_type ${resolutions[i]})" == "static" ]]
            then
                found_static_resolution=true
            fi
        fi
    done

    i=0

    if (($WEIGHT_DYNAMIC_RESOLUTIONS == $WEIGHT_STATIC_RESOLUTIONS))
    then
        for ((; i < ${#output_resolutions[@]}; i++))
        do
            echo ${output_resolutions[i]}
        done
    elif (($WEIGHT_DYNAMIC_RESOLUTIONS > $WEIGHT_STATIC_RESOLUTIONS))
    then
        for ((; i < ${#output_resolutions[@]}; i++))
        do
            if ! $found_dynamic_resolution || \
               [[ "$(get_resolution_type ${output_resolutions[i]})" != "static" ]]
            then
                echo ${output_resolutions[i]}
            fi
        done
    elif (($WEIGHT_DYNAMIC_RESOLUTIONS < $WEIGHT_STATIC_RESOLUTIONS))
    then
        for ((; i < ${#output_resolutions[@]}; i++))
        do
            if ! $found_static_resolution || \
               [[ "$(get_resolution_type ${output_resolutions[i]})" != "dynamic" ]]
            then
                echo ${output_resolutions[i]}
            fi
        done
    fi
}

# Public: Import the resolutions contained in a CSV file.
#
# The function expects one parameter:
#
# $1 - The filepath of the CSV file
function import_resolutions() {
    if [[ -e "$1" ]]
    then
        debug $verbosity "Importing resolutions from \"$1\"...\n"
        while read resolution
        do
            set_resolution $resolution
        done <"$1"
        debug $verbosity "Import completed.\n"
    else
        debug $verbosity "Resolutions file \"$1\" doesn't exists.\n"
        debug $verbosity "Anything has been imported.\n"
    fi
}

# Public: Check if the IP address, passed as argument to the function, is valid.
#
# $1 - The IP address to check
#
# Returns true if the IP is valid, false otherwise
function is_valid_ip_address() {
    local bytes=0
    local invalid_ip=false
    local ip=$1

    while ((${#ip} > 0 && bytes < 4)) && ! $invalid_ip
    do
        byte=${ip%%.*}
        if [[ "$(echo $byte | tr -d [:digit:])" == "" ]] && \
            ((byte < 256))
        then
            ((bytes++))
            ip=${ip#*.}
        else
            invalid_ip=true
        fi
    done

    if ! $invalid_ip
    then
        true
    else
        false
    fi
}

# Public: Check if the MAC address, passed as argument to the function, is valid.
#
# $1 - The MAC address to check
#
# Returns true if the MAC is valid, false otherwise
function is_valid_mac_address() {
    local bytes=0
    local invalid_mac=false
    local mac="$(echo $1 | tr [:upper:] [:lower:])"

    while ((${#mac} > 0 && bytes < 6)) && ! $invalid_mac
    do
        local digits=0

        byte=${mac%%:*}

        if ((${#byte} == 2))
        then
            ((bytes++))
            mac=${mac#*:}
            while ((digits < 2)) && ! $invalid_mac
            do
                if [[ ${byte:digits:1} == [0123456789abcdef] ]]
                then
                    ((digits++))
                else
                    invalid_mac=true
                fi
            done
        else
            invalid_mac=true
        fi
    done

    if ! $invalid_mac
    then
        true
    else
        false
    fi
}

# Public: Print the resolutions list.
function print_resolutions() {
    local i=0

    for ((; i < ${#resolutions[@]}; i++))
    do
        echo ${resolutions[i]}
    done
}

# Public: Reset (empty) the resolutions file.
#
# The function expects one parameter:
#
# $1 - The filepath
function reset_resolutions() {
    if [[ -e "$1" ]]
    then
        debug $verbosity "Resetting resolutions file \"$1\"...\n"
        echo -n >"$1"
        debug $verbosity "Reset completed.\n"
    else
        debug $verbosity "Resolutions file \"$1\" doesn't exists.\n"
    fi
}

# Public: Add or update a static resolution.
#
# The function expects one parameter:
#
# $1 - The resolution to be added
function set_resolution() {
    if [[ $1 != "" ]]
    then
        resolution="$(echo $1 | tr [:upper:] [:lower:])"

        local i=0
        local ip="$(get_ip_address $resolution)"
        local mac="$(get_mac_address $resolution)"
        local resolution_type="$(get_resolution_type $resolution)"
        local resolutions_updated=false

        for ((; i < ${#resolutions[@]}; i++))
        do
            if [[ $ip == "$(get_ip_address ${resolutions[i]})" && \
                  $mac == "$(get_mac_address ${resolutions[i]})" && \
                  $resolution_type == "$(get_resolution_type ${resolutions[i]})" ]]
            then
                debug $verbosity "Updating a resolution with \"$resolution\".\n"
                resolutions[i]=$resolution
                resolutions_updated=true
            fi
        done

        if ! $resolutions_updated
        then
            debug $verbosity "Adding resolution \"$resolution\".\n"
            resolutions+=("$resolution")
        fi
    fi
}

# Public: Remove beginning and ending spaces of the
#         string passed as argument to the function.
#
# The function expects one parameter:
#
# $1 - The string
function trim() {
    local string="$*"

    # Remove leading whitespace characters
    string="${string#"${string%%[![:space:]]*}"}"

    # Remove trailing whitespace characters
    string="${string%"${string##*[![:space:]]}"}"

    echo "$string"
}

# Public: Remove the expired resolutions from the list.
function unset_expired_resolutions() {
    local i=0

    while ((i < ${#resolutions[@]}))
    do
        local resolution=${resolutions[i]}

        if [[ "$(get_resolution_type $resolution)" == "dynamic" ]]
        then
            if [[ "${resolution##*,}" == "" ]]
            then
                resolution=${resolution%*,}
            fi
            if (($(date '+%s') - ${resolution##*,} >= $ENTRIES_TTL))
            then
                debug $verbosity "Removing dynamic resolution \"${resolutions[i]}\" "
                debug $verbosity "(expired since $(($(date '+%s') - ${resolution##*,}))"
                debug $verbosity " seconds).\n"
                resolutions=(${resolutions[@]:0:i} ${resolutions[@]:((i+1))})
            else
                ((i++))
            fi
        else
            ((i++))
        fi
    done
}

# Public: Remove the filtered resolutions from the list.
function unset_filtered_resolutions() {
    for i in ${filtered_resolution_indexes[@]}
    do
        resolutions=(${resolutions[@]:0:i} ${resolutions[@]:((i+1))})
    done
}

# Public: Remove the static resolutions specified by IP and/or MAC address(es).
#
# The function expects one or two parameters (the order
# is not important if both the addresses are specified):
# 
# $1 - The IP or MAC of which remove the resolution(s)
# $2 - The MAC or IP of which remove the resolution
#
# If both the parameters will be specified,it will be removed
# the exact resolution with the given pair <IP,MAC>.
# If only one parameter will be specified, it will be removed
# all the resolutions containing the given address(IP or MAC).
function unset_static_resolutions() {
    if (($# == 2))
    then
        local i=0
        local unset_ip=${1#$'"'*}
        local unset_mac=${2#$'"'*}

        unset_ip=${unset_ip%*$'"'}
        unset_mac=${unset_mac%*$'"'}
        unset_mac="$(echo $unset_mac | tr [:upper:] [:lower:])"

        while ((i < ${#resolutions[@]}))
        do
            if [[ "$(get_resolution_type ${resolutions[i]})" == "static" ]]
            then
                local remove_resolution=false
                local ip="$(get_ip_address ${resolutions[i]})"
                local mac="$(get_mac_address ${resolutions[i]})"

                if [[ $unset_ip == $ip && $unset_mac == $mac ]]
                then
                    remove_resolution=true
                elif [[ $unset_ip == "" && $unset_mac == $mac ]]
                then
                    remove_resolution=true
                elif [[ $unset_mac == "" && $unset_ip == $ip ]]
                then
                    remove_resolution=true
                fi

                if $remove_resolution
                then
                    debug $verbosity "Removing static resolution \"${resolutions[i]}\".\n"
                    resolutions=(${resolutions[@]:0:i} ${resolutions[@]:((i+1))})
                else
                    ((i++))
                fi
            else
                ((i++))
            fi
        done
    else
        debug $verbosity "Unset command expects two parameters.\n"
    fi
}

#########################################################
###                   MAIN  PROGRAM                   ###
#########################################################

commands=()
filtered_resolutions_indexes=()
dependencies=(arp-scan)
daemon_mode=false
resolutions=()
verbosity=0

commands+=("import_resolutions "$BASE_DIR_PATH/static_resolutions.csv"")

if (($# > 0))                           # $# = number of arguments passed to the script
then
    for ((index=1; index <= $#; index++))
    do
        case ${!index} in
            -d | --daemon)
                daemon_mode=true;;
            -g | --get)
                valid_addr=true
                ((index++))

                # Assuming the parameter is an IP.
                if [[ "$(echo ${!index} | tr -d [:digit:])" == "..." ]] && \
                   $(is_valid_ip_address ${!index})
                then
                    addr_type="ip"
                    addr_value=${!index}
                elif $(is_valid_mac_address ${!index})
                then
                    # Assuming the parameter is a MAC.
                    addr_type="mac"
                    addr_value="$(echo ${!index} | tr [:upper:] [:lower:])"
                else
                    valid_addr=false
                fi

                if $valid_addr
                then
                    commands+=("import_resolutions "$BASE_DIR_PATH/other_resolutions.csv"")
                    commands+=("unset_expired_resolutions")
                    commands+=("get_resolutions $addr_type $addr_value")
                    commands+=("reset_resolutions "$BASE_DIR_PATH/other_resolutions.csv"")
                    commands+=("filter_resolutions excluding static")
                    commands+=("export_resolutions filtered "$BASE_DIR_PATH/other_resolutions.csv"")
                fi
                ;;
            -h | --help)
                printf "LANResolver resolves IPs by MAC addresses and vice versa."
                echo
                printf "All available options are:\n"
                printf " -d         | --daemon       :"
                printf "  Launch the program in daemon mode.\n"
                printf " -g <key>   | --get <key>    :"
                printf "  Print the value of the given key (IP or MAC).\n"
                printf " -h         | --help         :"
                printf "  Show these messages (all the available options).\n"
                printf " -i <file>  | --import <file>:"
                printf "  Import the resolutions from a file.\n"
                printf " -l         | --list         :"
                printf "  Print the list of resolutions.\n"
                printf " -s <k> <v> | --set <k> <v>  :"
                printf "  Set the static resolution with key k (IP or MAC) and"
                printf " value v (MAC or IP).\n"
                printf " -u <k> [v] | --unset <k> [v]:"
                printf "  Unset the static resolution(s) with key k (IP or MAC)"
                printf " and, if specified, the value v (MAC or IP).\n"
                printf " -v         | --verbose      :"
                printf "  Enable the debug mode.\n"
                echo
                exit 0;;
            -i | --import)
                ((index++))
                commands+=("import_resolutions "${!index}"");;
            -l | --list)
                commands+=("import_resolutions "$BASE_DIR_PATH/other_resolutions.csv"")
                commands+=("unset_expired_resolutions")
                commands+=("print_resolutions")
                commands+=("reset_resolutions "$BASE_DIR_PATH/other_resolutions.csv"")
                commands+=("filter_resolutions excluding static")
                commands+=("export_resolutions filtered "$BASE_DIR_PATH/other_resolutions.csv"");;
            -s | --set)
                ((index++))

                # Assuming the first parameter is the IP.
                if [[ "$(echo ${!index} | tr -d [:digit:])" == "..." ]]
                then
                    ip_address=${!index}
                    ((index++))
                    mac_address=${!index}
                else
                    # Assuming the first parameter is the MAC.
                    mac_address=${!index}
                    ((index++))
                    ip_address=${!index}
                fi
                if $(is_valid_ip_address $ip_address) && \
                   $(is_valid_mac_address $mac_address)
                then
                    commands+=("set_resolution "static,$ip_address,$mac_address,$(date '+%s'),"")
                else
                    echo "Error: Invalid IP or MAC in set command."
                fi
                ;;
            -u | --unset)
                ip_address=""
                mac_address=""
                ((index++))

                # Assuming the first parameter is the IP.
                if [[ "$(echo ${!index} | tr -d [:digit:])" == "..." ]]
                then
                    ip_address=${!index}
                    ((index++))
                    if [[ ${!index:0:1} != "-" ]]
                    then
                        mac_address=${!index}
                    else
                        ((index--))
                    fi
                else
                    # Assuming the first parameter is the MAC.
                    mac_address=${!index}
                    ((index++))
                    if [[ ${!index:0:1} != "-" ]]
                    then
                        ip_address=${!index}
                    else
                        ((index--))
                    fi
                fi

                unset_resolution=false

                if [[ $ip_address != "" && $mac_address != "" ]]
                then
                    if $(is_valid_ip_address $ip_address) && \
                       $(is_valid_mac_address $mac_address)
                    then
                        unset_resolution=true
                    fi
                else
                    if [[ $ip_address != "" ]] && $(is_valid_ip_address $ip_address)
                    then
                        unset_resolution=true
                    fi
                    if [[ $mac_address != "" ]] && $(is_valid_mac_address $mac_address)
                    then
                        unset_resolution=true
                    fi
                fi

                if $unset_resolution
                then
                    commands+=("unset_static_resolutions \"$ip_address\" \"$mac_address\"")

                    # Export resolutions is integrated in the command unset.
                else
                    echo "Error: Invalid IP or MAC in unset command."
                fi
                ;;
            -v | --verbose)
                ((verbosity++));;
            *)
                echo
                echo "Error: \"${!index}\" option is invalid."
                echo
                echo "Look at --help (or -h) to know all available options."
                echo
                exit 1
        esac
    done
fi

commands+=("reset_resolutions "$BASE_DIR_PATH/static_resolutions.csv"")
commands+=("filter_resolutions only static")
commands+=("export_resolutions filtered "$BASE_DIR_PATH/static_resolutions.csv"")

for ((index=0; index < ${#commands[@]}; index++))
do
    debug $verbosity "Executing command \"${commands[index]}\".\n"
    ${commands[index]}
done

if [[ $daemon_mode == true ]]
then
    debug $verbosity "Checking dependencies...\n"
    for binary in "${dependencies[@]}"
    do
        debug $verbosity "$binary..."
        if [[ ! -e "$(type -p $binary)" ]]
        then
            debug $verbosity "not found, please install it.\n"
            exit 1
        else
            debug $verbosity "found.\n"
        fi
    done

    debug $verbosity "OK, it has been found all necessary dependencies.\n"

    debug $verbosity "Writing the pidfile with PID $$...\n"
    echo $$ >"$BASE_DIR_PATH/LANResolver.pid"
    debug $verbosity "Pidfile written.\n"

    while true
    do
        filter_resolutions "only" "static"
        unset_filtered_resolutions
        import_resolutions "$BASE_DIR_PATH/static_resolutions.csv"
        reset_resolutions "$BASE_DIR_PATH/static_resolutions.csv"
        filter_resolutions "only" "static"
        export_resolutions "filtered" "$BASE_DIR_PATH/static_resolutions.csv"

        debug $verbosity "Starting ARP scan...\n"
        arp_output="$(sudo arp-scan -l)"
        debug $verbosity "ARP scan completed.\n"

        while read line
        do
            prefix="${line%%.*}"

            # Check if the substring extracted is really a number.
            if [[ "$prefix" != "" && "$(echo "$prefix" | tr -d [:digit:])" == "" ]]
            then

                # Substitute all tabs with spaces.
                line="$(echo $line | tr '\t' ' ')"

                # Let's assume that the line starts with an IP
                # (since it starts with a number followed by a
                # dot).
                ip_address="${line%% *}"
                line="${line#* }"
                mac_address="${line%% *}"
                set_resolution "dynamic,$ip_address,$mac_address,$(date '+%s'),"
            fi
        done < <(echo "$arp_output")

        unset_expired_resolutions
        reset_resolutions "$BASE_DIR_PATH/other_resolutions.csv"
        filter_resolutions "excluding" "static"
        export_resolutions "filtered" "$BASE_DIR_PATH/other_resolutions.csv"

        sleep $SCAN_PERIOD
    done
fi
EOF

echo "Making the script executable..."
sudo chmod +x "LANResolver.sh"
