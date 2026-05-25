#define STB_DS_IMPLEMENTATION
#include "stb_ds.h"
#include <stdio.h>
#include <string.h>

// --- Interface Status Enum ---
typedef enum {
    INTERFACE_UP = 1,       // Ready to pass packets
    INTERFACE_DOWN = 2,     // Not ready + not in test mode
    INTERFACE_TESTING = 3   // In test mode
} InterfaceStatus;

const char* status_to_string(InterfaceStatus s) {
    static const char* strings[] = {
        [INTERFACE_UP]      = "UP (Ready to pass packets)",
        [INTERFACE_DOWN]    = "DOWN (Not ready)",
        [INTERFACE_TESTING] = "TESTING (In test mode)"
    };
    return strings[s];
}

// --- Data Structures ---
typedef struct {
    int id;
    int vlan;
    char type[32];  // "access", "trunk", etc.
} SubInterface;

typedef struct {
    char name[64];
    char desc[128];
    InterfaceStatus status;
    SubInterface* subinterfaces; // stb_ds dynamic array
} NetworkInterface;

// --- Core Functions ---
void add_subinterface(NetworkInterface* intf, int id, int vlan, const char* type) {
    SubInterface sub = {.id = id, .vlan = vlan};
    strncpy(sub.type, type, sizeof(sub.type)-1);
    arrput(intf->subinterfaces, sub);
}

void clear_subinterfaces(NetworkInterface* intf) {
    if (intf && intf->subinterfaces) {
        arrfree(intf->subinterfaces);
        intf->subinterfaces = NULL;
    }
}

void remove_subinterfaces_by_vlan(NetworkInterface* intf, int vlan) {
    if (!intf || !intf->subinterfaces) return;
    
    SubInterface* filtered = NULL;
    for (int i = 0; i < arrlen(intf->subinterfaces); i++) {
        if (intf->subinterfaces[i].vlan != vlan) {
            arrput(filtered, intf->subinterfaces[i]);
        }
    }
    
    arrfree(intf->subinterfaces);
    intf->subinterfaces = filtered;
}

void print_interface(const NetworkInterface* intf) {
    printf("┌─ %s [%s]\n│  Status: %s\n│  Desc: %s\n", 
           intf->name, 
           arrlen(intf->subinterfaces) ? "Composite" : "Simple",
           status_to_string(intf->status),
           intf->desc);
    
    for (int i = 0; i < arrlen(intf->subinterfaces); i++) {
        printf("├── Subif %d: VLAN %d (%s)\n", 
               intf->subinterfaces[i].id,
               intf->subinterfaces[i].vlan,
               intf->subinterfaces[i].type);
    }
    printf("└────────────────\n");
}

// --- Main Program ---
int main() {
    printf("=== Network Interface Demo ===\n\n");
    
    // Create interface with subinterfaces
    NetworkInterface eth0 = {
        .name = "eth0", 
        .desc = "Main Ethernet port",
        .status = INTERFACE_UP
    };
    add_subinterface(&eth0, 1, 100, "access");
    add_subinterface(&eth0, 2, 200, "trunk");
    add_subinterface(&eth0, 3, 100, "hybrid");
    
    // Create wireless interface
    NetworkInterface wlan0 = {
        .name = "wlan0",
        .desc = "Wireless interface (testing mode)",
        .status = INTERFACE_TESTING
    };
    add_subinterface(&wlan0, 1, 300, "access");
    
    // Print initial state
    printf("Initial interfaces:\n");
    print_interface(&eth0);
    print_interface(&wlan0);
    
    // Demo VLAN removal
    printf("\nRemoving VLAN 100 from eth0...\n");
    remove_subinterfaces_by_vlan(&eth0, 100);
    print_interface(&eth0);
    
    // Demo clear
    printf("\nClearing all wlan0 subinterfaces...\n");
    clear_subinterfaces(&wlan0);
    print_interface(&wlan0);
    
    // Cleanup
    clear_subinterfaces(&eth0);
    clear_subinterfaces(&wlan0);
    
    return 0;
}