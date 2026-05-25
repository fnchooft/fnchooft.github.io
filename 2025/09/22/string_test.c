#define STB_SPRINTF_IMPLEMENTATION
#include "stb_sprintf.h"  // Single header version
#include <stdio.h>

int main() {
    char buffer[100];
    
    // 1. Basic formatting (like sprintf)
    stbsp_sprintf(buffer, "Hello, %s! You have %d messages.", "User", 5);
    puts(buffer);  // Output: "Hello, User! You have 5 messages."

    // 2. Safer bounds checking
    stbsp_snprintf(buffer, sizeof(buffer), "Pi ≈ %.5f", 3.1415926535);
    puts(buffer);  // Output: "Pi ≈ 3.14159"

    // 3. Advanced features (no standard library equivalent)
    stbsp_sprintf(buffer, "Hex: %08x | Binary: %b", 255, 255);
    puts(buffer);  // Output: "Hex: 000000ff | Binary: 11111111"

    // 4. Custom formatting (no allocations)
    stbsp_sprintf(buffer, "Commas: %'d", 1000000);
    puts(buffer);  // Output: "Commas: 1,000,000"
    
    return 0;
}
