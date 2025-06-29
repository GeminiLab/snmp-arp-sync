export SOURCED=1
. $(dirname "$0")/../snmp-arp-sync.sh

COLOR_GREEN="\033[0;32m"
COLOR_RED="\033[0;31m"
COLOR_RESET="\033[0m"

test_ip_filter() {
    local test_ip="$1"
    local test_subnet="$3"
    local expected="$2"

    if ip_in_subnet "$test_ip" "$test_subnet"; then
        result="in"
    else
        result="not in"
    fi

    if [ "$result" = "$expected" ]; then
        echo -e "Test ${COLOR_GREEN}PASSED${COLOR_RESET}: IP $test_ip $expected subnet $test_subnet"
    else
        echo -e "Test ${COLOR_RED}FAILED${COLOR_RESET}: IP $test_ip should be $expected subnet $test_subnet"
        exit 1
    fi
}

test_ip_filter "10.10.1.1" "in"     "10.10.0.0/20"
test_ip_filter "10.10.1.1" "not in" "10.10.0.0/24"

