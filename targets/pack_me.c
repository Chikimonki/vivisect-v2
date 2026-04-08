#include <stdio.h>

void hidden_function() {
    printf("🔓 You found the hidden function!\n");
    printf("Flag: FLAG{unpacking_works}\n");
}

int main() {
    printf("This binary is packed with UPX\n");
    hidden_function();
    return 0;
}
