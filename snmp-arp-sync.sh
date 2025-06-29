#!/bin/sh

# snmp-arp-sync.sh - Synchronize ARP entries using SNMP data

# Log functions
log_normal() {
    if [ $QUIET -eq 0 ]; then
        echo "$1"
    fi
}

log_verbose() {
    if [ $VERBOSE -eq 1 ] && [ $QUIET -eq 0 ]; then
        echo "$1"
    fi
}

arg_error() {
    echo "Error: $1" >&2
    echo "Use -h or --help for usage information." >&2
    exit 1
}

# Print usage information
usage() {
    echo "Usage: $0 -s <SNMP_SERVER> -I <INTERFACE> [-c <COMMUNITY>] [-f <FILTER_SUBNET>] [-n] [-v|-q] [-h]"
    echo ""
    echo "Options:"
    echo "  -s, --server       SNMP server address"
    echo "  -I, --interface    Network interface to update ARP entries (e.g., br-lan, eth0)"
    echo "  -c, --community    SNMP community string (default: public)"
    echo "  -O, --object       SNMP object identifier (OID) to query (default: .1.3.6.1.2.1.4.22.1.2)"
    echo "  -f, --filter       Optional subnet filter in CIDR format (e.g., 10.10.16.0/20)"
    echo ""
    echo "  -n, --dry-run      Perform a dry run without executing ip neigh commands"
    echo "  -v, --verbose      Enable verbose output"
    echo "  -q, --quiet        Suppress all output except errors, overrides verbose mode"
    echo "  -h, --help         Show this help message"
    exit 1
}

# Argument parsing
SNMP_COMMUNITY="public"
SNMP_OID=".1.3.6.1.2.1.4.22.1.2"
QUIET=0
VERBOSE=0
DRY_RUN=0

if [ -z "$SOURCED" ]; then
    SOURCED=0
fi

while [ "$#" -gt 0 ]; do
    case "$1" in
        -s|--server)
            SNMP_HOST="$2"
            shift 2
            ;;
        -I|--interface)
            INTERFACE="$2"
            shift 2
            ;;
        -c|--community)
            SNMP_COMMUNITY="$2"
            shift 2
            ;;
        -O|--object)
            SNMP_OID="$2"
            shift 2
            ;;
        -f|--filter)
            FILTER_SUBNET="$2"
            shift 2
            ;;
        -n|--dry-run)
            DRY_RUN=1
            shift 1
            ;;
        -v|--verbose)
            VERBOSE=1
            shift 1
            ;;
        -q|--quiet)
            QUIET=1
            shift 1
            ;;
        -h|--help)
            usage
            ;;
        -S|--sourced)
            # Hidden option to indicate the script is sourced, used for testing. This is not
            # intended for end users. If arguments cannot be passed when being sourced, export
            # SOURCED=1 before sourcing.
            SOURCED=1
            shift 1
            ;;
        -*)
            arg_error "Unknown option: $1"
            ;;
        *)
            arg_error "Unexpected argument: $1"
            ;;
    esac
done

# Check if an IP is in a given subnet.
ip_in_subnet() {
    local ip="$1"
    local subnet="$2"

    local awk_script='
    function ip2int(ip) {
        n = split(ip, a, ".")
        ret = 0
        for (i = 1; i <= n; i++) ret = (ret * 256) + a[i]
        return ret
    }
    BEGIN {
        split(ARGV[2], parts, "/")
        subnet_ip = parts[1]
        prefix = parts[2] + 0
        mask = xor((2 ** (32 - prefix)) - 1, 0xFFFFFFFF)
        subnet = and(ip2int(subnet_ip), mask)

        target = ip2int(ARGV[1])

        if (and(target, mask) == subnet)
            exit 0
        else
            exit 1
    }
    '

    awk "$awk_script" "$ip" "$subnet"
    return $?
}

# Normalize a MAC address string with colon or space as separator, adding leading zeros for each
# part if necessary. Converts uppercase letters to lowercase.
normalize_mac() {
    raw_mac="$1"
    norm_mac=""

    # Determine the separator
    for sep in ':' ' '; do
        echo "$raw_mac" | grep -q "$sep" && IFS="$sep" && break
    done

    # For best compatibility, we use the "set -- $(echo ...)" pattern to split the MAC address
    set -- $(echo "$raw_mac")

    # Add leading zeros if necessary
    for part in "$@"; do
        part=$(echo "$part" | tr 'A-Z' 'a-z')  # Convert to lowercase
        [ ${#part} -eq 1 ] && part="0$part"
        norm_mac="${norm_mac}${part}:"
    done

    echo "${norm_mac%:}"
}

# Main function to sync ARP entries
snmp_arp_sync_main() {
    # Temporary file to store snmpwalk output
    TMP_FILE="/tmp/snmp_arp_table.txt"

    # Remove temporary file if it exists
    [ -f "$TMP_FILE" ] && rm -f "$TMP_FILE"

    # Check required arguments
    if [ -z "$SNMP_HOST" ] || [ -z "$INTERFACE" ]; then
        arg_error "SNMP server and interface are required."
    fi

    if [ $DRY_RUN -eq 1 ]; then
        log_normal "Dry run mode enabled, no changes will be made."
    fi

    # Read ARP table from SNMP
    log_verbose "Fetching ARP table from SNMP server: $SNMP_HOST with community: $SNMP_COMMUNITY"
    snmpwalk -v2c -c "$SNMP_COMMUNITY" "$SNMP_HOST" "$SNMP_OID" > "$TMP_FILE"
    log_verbose "SNMP ARP table fetched and saved to $TMP_FILE"

    # Process the ARP entries
    cat "$TMP_FILE" | while read -r line; do
        IP=$(echo "$line" | awk -F '.' '{print $(NF-3)"."$(NF-2)"."$(NF-1)"."$(NF)}' | awk -F ' = ' '{print $1}')
        RAW_MAC=$(echo "$line" | awk -F ': ' '{print $2}' | tr 'A-Z' 'a-z')

        MAC=$(normalize_mac "$RAW_MAC")

        log_verbose ""
        log_verbose "Line: \"$line\" => IP: $IP, MAC: $MAC   "

        if ! echo "$MAC" | grep -Eq '^([0-9a-f]{2}:){5}[0-9a-f]{2}$' || ! echo "$IP" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
            log_verbose "-> Invalid line, skipping..."
            continue
        fi

        # Filter by subnet if specified
        if [ -n "$FILTER_SUBNET" ]; then
            if ip_in_subnet "$IP" "$FILTER_SUBNET"; then
                log_verbose "-> IP $IP is in filter subnet $FILTER_SUBNET, processing..."
            else
                log_verbose "-> IP $IP is not in filter subnet $FILTER_SUBNET, skipping..."
                continue
            fi
        fi

        log_normal "$IP -> $MAC"
        if [ $DRY_RUN -eq 0 ]; then
            ip neigh replace "$IP" lladdr "$MAC" dev "$INTERFACE"
        fi
    done

    # Clean up temporary file
    rm -f "$TMP_FILE"
    log_verbose "ARP sync completed. Temporary file $TMP_FILE removed."
}

if [ $SOURCED -eq 1 ]; then
    # If sourced, do not run main function
    log_normal "Script sourced, not executing main function."
else
    # If not sourced, run the main function
    snmp_arp_sync_main
fi
