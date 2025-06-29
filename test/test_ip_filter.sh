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

# Test /24 subnet boundaries
echo -e "\nTesting /24 subnet boundaries:"
test_ip_filter "192.168.1.1"   "in"     "192.168.1.0/24"
test_ip_filter "192.168.1.254" "in"     "192.168.1.0/24"
test_ip_filter "192.168.1.255" "in"     "192.168.1.0/24"
test_ip_filter "192.168.2.1"   "not in" "192.168.1.0/24"
test_ip_filter "192.168.0.255" "not in" "192.168.1.0/24"

# Test /16 subnet boundaries
echo -e "\nTesting /16 subnet boundaries:"
test_ip_filter "172.16.0.1"    "in"     "172.16.0.0/16"
test_ip_filter "172.16.255.254" "in"    "172.16.0.0/16"
test_ip_filter "172.17.0.1"    "not in" "172.16.0.0/16"
test_ip_filter "172.15.255.255" "not in" "172.16.0.0/16"

# Test /8 subnet boundaries
echo -e "\nTesting /8 subnet boundaries:"
test_ip_filter "10.0.0.1"      "in"     "10.0.0.0/8"
test_ip_filter "10.255.255.254" "in"    "10.0.0.0/8"
test_ip_filter "11.0.0.1"      "not in" "10.0.0.0/8"
test_ip_filter "9.255.255.255" "not in" "10.0.0.0/8"

# Test /32 (single host) subnet
echo -e "\nTesting /32 (single host) subnet:"
test_ip_filter "192.168.100.50" "in"     "192.168.100.50/32"
test_ip_filter "192.168.100.51" "not in" "192.168.100.50/32"

# Test /20 subnet (complex case)
echo -e "\nTesting /20 subnet boundaries:"
test_ip_filter "10.10.0.1"    "in"     "10.10.0.0/20"
test_ip_filter "10.10.15.254" "in"     "10.10.0.0/20"
test_ip_filter "10.10.16.1"   "not in" "10.10.0.0/20"
test_ip_filter "10.9.255.255" "not in" "10.10.0.0/20"

# Test /28 subnet (small subnet)
echo -e "\nTesting /28 subnet boundaries:"
test_ip_filter "192.168.1.16"  "in"     "192.168.1.16/28"
test_ip_filter "192.168.1.31"  "in"     "192.168.1.16/28"
test_ip_filter "192.168.1.15"  "not in" "192.168.1.16/28"
test_ip_filter "192.168.1.32"  "not in" "192.168.1.16/28"

# Test /30 subnet (point-to-point)
echo -e "\nTesting /30 subnet boundaries:"
test_ip_filter "192.168.1.200" "in"     "192.168.1.200/30"
test_ip_filter "192.168.1.203" "in"     "192.168.1.200/30"
test_ip_filter "192.168.1.199" "not in" "192.168.1.200/30"
test_ip_filter "192.168.1.204" "not in" "192.168.1.200/30"

# Test private IP ranges
echo -e "\nTesting common private IP ranges:"
test_ip_filter "192.168.0.1"   "in"     "192.168.0.0/16"
test_ip_filter "172.16.0.1"    "in"     "172.16.0.0/12"
test_ip_filter "172.31.255.254" "in"    "172.16.0.0/12"
test_ip_filter "172.32.0.1"    "not in" "172.16.0.0/12"
test_ip_filter "10.0.0.1"      "in"     "10.0.0.0/8"

# Test edge cases
echo -e "\nTesting edge cases:"
test_ip_filter "0.0.0.0"       "in"     "0.0.0.0/8"
test_ip_filter "127.0.0.1"     "in"     "127.0.0.0/8"
test_ip_filter "255.255.255.255" "in"   "255.255.255.0/24"

# Test with different CIDR notations
echo -e "\nTesting various CIDR notations:"
test_ip_filter "10.0.0.1"      "in"     "10.0.0.0/1"
test_ip_filter "128.0.0.1"     "not in" "10.0.0.0/1"
test_ip_filter "192.168.1.100" "in"     "192.168.1.0/25"
test_ip_filter "192.168.1.200" "not in" "192.168.1.0/25"

# Test boundary conditions for /20 subnet (common in enterprise)
echo -e "\nTesting /20 subnet edge cases:"
test_ip_filter "172.20.16.1"   "in"     "172.20.16.0/20"
test_ip_filter "172.20.31.255" "in"     "172.20.16.0/20"
test_ip_filter "172.20.15.255" "not in" "172.20.16.0/20"
test_ip_filter "172.20.32.1"   "not in" "172.20.16.0/20"

# Test /22 subnet (common in cloud environments)
echo -e "\nTesting /22 subnet boundaries:"
test_ip_filter "10.0.4.1"      "in"     "10.0.4.0/22"
test_ip_filter "10.0.7.255"    "in"     "10.0.4.0/22"
test_ip_filter "10.0.3.255"    "not in" "10.0.4.0/22"
test_ip_filter "10.0.8.1"      "not in" "10.0.4.0/22"

echo -e "\n${COLOR_GREEN}All IP subnet filtering tests passed!${COLOR_RESET}"

