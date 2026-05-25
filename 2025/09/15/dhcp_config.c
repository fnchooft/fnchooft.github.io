#include <stdio.h>
#include <stdbool.h>
#include <string.h>

#define STB_DS_IMPLEMENTATION
#include "stb_ds.h"

#define STRING_LENGTH_MAX 32

#define STRCPY(dest, src) do { \
    static_assert(sizeof(dest) <= STRING_LENGTH_MAX, "Buffer overflow risk"); \
    strncpy((dest), (src), sizeof(dest)-1); \
    (dest)[sizeof(dest)-1] = '\0'; \
} while(0)

// --------------------------
// Type Definitions
// --------------------------

typedef enum {
    LOG_KERN,
    LOG_MAIL,
    LOG_LOCAL7
} LogFacility;

typedef struct {
    char low_addr[STRING_LENGTH_MAX];
    char high_addr[STRING_LENGTH_MAX];
    bool dynamic_bootp;
} DhcpRange;

typedef struct {
    char net[STRING_LENGTH_MAX];
    char mask[STRING_LENGTH_MAX];
    DhcpRange range;  // No longer a pointer
    bool has_range;   // Flag to indicate presence
    char routers[STRING_LENGTH_MAX];
    char max_lease_time[STRING_LENGTH_MAX];
} DhcpSubnet;

typedef struct {
    char name[STRING_LENGTH_MAX];
    DhcpSubnet* subnets;
} DhcpSharedNetwork;

typedef struct {
    char default_lease_time[STRING_LENGTH_MAX];
    char max_lease_time[STRING_LENGTH_MAX];
    LogFacility log_facility;
    
    struct {
        DhcpSubnet* subnets;
    } subnets;
    
    struct {
        DhcpSharedNetwork* networks;
    } shared_networks;
} DhcpConfig;

// --------------------------
// Helper Functions
// --------------------------

void init_subnet(DhcpSubnet* subnet, const char* net, const char* mask) {
    memset(subnet, 0, sizeof(DhcpSubnet));
    STRCPY(subnet->net, net);
    STRCPY(subnet->mask, mask);
    STRCPY(subnet->max_lease_time, "PT7200S");
    subnet->has_range = false;
}

void set_range(DhcpSubnet* subnet, const char* low, const char* high, bool dynamic_bootp) {
    STRCPY(subnet->range.low_addr, low);
    if (high) {
        STRCPY(subnet->range.high_addr, high);
    }
    subnet->range.dynamic_bootp = dynamic_bootp;
    subnet->has_range = true;
}

void free_dhcp_config(DhcpConfig* config) {
    if (!config) return;
    arrfree(config->subnets.subnets);
    
    for (int i = 0; i < arrlen(config->shared_networks.networks); i++) {
        arrfree(config->shared_networks.networks[i].subnets);
    }
    arrfree(config->shared_networks.networks);
}

// --------------------------
// Main Program
// --------------------------

void print_config(const DhcpConfig* config) {
    printf("DHCP Configuration:\n");
    printf("  Default Lease Time: %s\n", config->default_lease_time);
    printf("  Max Lease Time: %s\n", config->max_lease_time);
    printf("  Log Facility: %d\n", config->log_facility);
    
    printf("\nSubnets:\n");
    for (int i = 0; i < arrlen(config->subnets.subnets); i++) {
        const DhcpSubnet* s = &config->subnets.subnets[i];
        printf("  - %s/%s\n", s->net, s->mask);
        if (s->has_range) {
            printf("    Range: %s-%s (BOOTP: %s)\n", 
                   s->range.low_addr,
                   s->range.high_addr[0] ? s->range.high_addr : "N/A",
                   s->range.dynamic_bootp ? "enabled" : "disabled");
        }
    }
    
    printf("\nShared Networks:\n");
    for (int i = 0; i < arrlen(config->shared_networks.networks); i++) {
        const DhcpSharedNetwork* n = &config->shared_networks.networks[i];
        printf("  Network: %s\n", n->name);
        for (int j = 0; j < arrlen(n->subnets); j++) {
            const DhcpSubnet* s = &n->subnets[j];
            printf("    - %s/%s\n", s->net, s->mask);
        }
    }
}

int main() {
    DhcpConfig config = {0};
    
    // Initialize fixed-size strings
    STRCPY(config.default_lease_time, "PT600S");
    STRCPY(config.max_lease_time, "PT7200S");
    config.log_facility = LOG_LOCAL7;
    
    // Add regular subnets
    DhcpSubnet subnet1;
    init_subnet(&subnet1, "192.168.1.0", "255.255.255.0");
    STRCPY(subnet1.routers, "192.168.1.1");
    set_range(&subnet1, "192.168.1.100", "192.168.1.200", false);
    arrput(config.subnets.subnets, subnet1);
    
    // Add shared network
    DhcpSharedNetwork shared = {0};
    STRCPY(shared.name, "Office-Network");
    
    DhcpSubnet shared_subnet1;
    init_subnet(&shared_subnet1, "10.0.1.0", "255.255.255.0");
    set_range(&shared_subnet1, "10.0.1.50", "10.0.1.150", true);
    arrput(shared.subnets, shared_subnet1);

    DhcpSubnet shared_subnet2;
    init_subnet(&shared_subnet2, "192.168.15.0", "255.255.255.0");
    set_range(&shared_subnet2, "192.168.15.50", "192.168.15.150", true);
    arrput(shared.subnets, shared_subnet2);
    
    arrput(config.shared_networks.networks, shared);
    
    print_config(&config);
    free_dhcp_config(&config);
    return 0;
}
