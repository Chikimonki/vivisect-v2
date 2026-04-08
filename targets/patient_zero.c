#include <stdio.h>
#include <string.h>

int authenticate(const char *password) {
    return strcmp(password, "VIVISECT") == 0;
}

void secret_function(void) {
    printf("\n[ACCESS GRANTED]\n");
    printf("The nuclear launch codes are: 00000000\n\n");
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <password>\n", argv[0]);
        return 1;
    }
    if (authenticate(argv[1])) {
        secret_function();
        return 0;
    }
    printf("Access denied.\n");
    return 1;
}
