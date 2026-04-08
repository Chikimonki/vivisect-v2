#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    char name[32];
    void (*func)();
} Object;

Object *obj = NULL;

void win() {
    printf("\n🎉 RCE ACHIEVED! Flag: FLAG{heap_exploitation_master}\n\n");
    system("/bin/sh");
}

void vuln() {
    char *buf = malloc(64);
    strcpy(buf, "normal data");
    
    free(buf);
    
    // Use-after-free vulnerability
    strcpy(buf, "pwned");
    
    printf("[*] This should crash... unless you hooked malloc/free!\n");
}

int main(int argc, char **argv) {
    printf("[*] Use-after-free demo\n");
    
    if (argc > 1 && strcmp(argv[1], "trigger") == 0) {
        vuln();
    } else {
        printf("[*] Run with 'trigger' to activate\n");
    }
    
    return 0;
}
