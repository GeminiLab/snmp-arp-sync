export SOURCED=1
. $(dirname "$0")/../snmp-arp-sync.sh

COLOR_GREEN="\033[0;32m"
COLOR_RED="\033[0;31m"
COLOR_RESET="\033[0m"

test_mac_normalize() {
    local raw_mac="$1"
    local expected_norm_mac="$2"

    norm_mac=$(normalize_mac "$raw_mac")

    if [ "$norm_mac" = "$expected_norm_mac" ]; then
        echo -e "Test ${COLOR_GREEN}PASSED${COLOR_RESET}: MAC '$raw_mac' normalized to '$norm_mac'"
    else
        echo -e "Test ${COLOR_RED}FAILED${COLOR_RESET}: MAC '$raw_mac' normalized to '$norm_mac', expected '$expected_norm_mac'"
        exit 1
    fi
}

# Test cases for MAC normalization
echo "Testing colon-separated MAC addresses..."
test_mac_normalize "00:1A:2B:3C:4D:5E" "00:1a:2b:3c:4d:5e"
test_mac_normalize "1A:2B:3C:4D:5E:6F" "1a:2b:3c:4d:5e:6f"
test_mac_normalize "1a:2b:3c:4d:5e:6f" "1a:2b:3c:4d:5e:6f"
test_mac_normalize "00:1A:2b:3C:4d:5E" "00:1a:2b:3c:4d:5e"

echo "Testing space-separated MAC addresses..."
test_mac_normalize "00 1A 2B 3C 4D 5E" "00:1a:2b:3c:4d:5e"
test_mac_normalize "1A 2B 3C 4D 5E 6F" "1a:2b:3c:4d:5e:6f"
test_mac_normalize "1a 2b 3c 4d 5e 6f" "1a:2b:3c:4d:5e:6f"
test_mac_normalize "00 1A 2b 3C 4d 5E" "00:1a:2b:3c:4d:5e"

echo "Testing missing leading zeros..."
test_mac_normalize "1:2:3:4:5:6" "01:02:03:04:05:06"
test_mac_normalize "1a:2:3:4d:5e:6f" "1a:02:03:4d:5e:6f"
test_mac_normalize "1 2 3 4 5 6" "01:02:03:04:05:06"
test_mac_normalize "1a 2 3 4d 5e 6f" "1a:02:03:4d:5e:6f"
