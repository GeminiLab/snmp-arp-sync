# SNMP ARP Sync

![GitHub Workflow Status](https://img.shields.io/github/check-runs/GeminiLab/snmp-arp-sync/master)

A shell script utility for synchronizing ARP entries (IP-MAC mappings) using SNMP data from network devices. 

## Usage

### Basic Syntax

```bash
./snmp-arp-sync.sh -s <SNMP_SERVER> -I <INTERFACE> [OPTIONS]
```

### Required Parameters

- `-s, --server`: SNMP server address (IP or hostname)
- `-I, --interface`: Network interface to update ARP entries (e.g., `br-lan`, `eth0`)

### Optional Parameters

- `-c, --community`: SNMP community string (default: `public`)
- `-O, --object`: SNMP OID to query (default: `.1.3.6.1.2.1.4.22.1.2`)
- `-f, --filter`: Subnet filter in CIDR format (e.g., `10.10.16.0/20`)
- `-n, --dry-run`: Perform a dry run without executing commands
- `-v, --verbose`: Enable verbose output
- `-q, --quiet`: Suppress all output except errors
- `-h, --help`: Show help message

## Examples

### Basic Usage

Sync ARP entries from an SNMP server to the `br-lan` interface:

```bash
./snmp-arp-sync.sh -s 192.168.1.1 -I br-lan
```

### With Custom Community String

```bash
./snmp-arp-sync.sh -s 192.168.1.1 -I br-lan -c private
```

### Filter by Subnet

Only sync ARP entries for devices in the `192.168.1.0/24` subnet:

```bash
./snmp-arp-sync.sh -s 192.168.1.1 -I br-lan -f 192.168.1.0/24
```

### Dry Run with Verbose Output

Test the configuration without making changes:

```bash
./snmp-arp-sync.sh -s 192.168.1.1 -I br-lan -f 192.168.1.0/24 -n -v
```

## Requirements

This scripts depends on several command-line utilities to function correctly:

- **snmpwalk**: SNMP command-line tool (in packages like `snmp`, depending on your distribution)
- **ip**/**awk**/**grep**: Common Linux utilities for network management and text processing, typically pre-installed on most Linux distributions.

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
