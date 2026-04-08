#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    char name[32];
    void (*func)();
} Object;

Object *obj = NULL;

void win() {
    printf("\n🎉 RCE ACHIEVED! Flag: FLAG{heap_master}\n\n");
    system("/bin/sh");
}

void vuln() {
    Object *obj = malloc(sizeof(Object));
    strcpy(obj->name, "legit");
    obj->func = NULL;
    
    free(obj);
    
    // Use-after-free: call the function pointer
    if (obj->func) {
        printf("[*] Calling function pointer...\n");
        obj->func();
    } else {
        printf("[-] No function pointer :(\n");
    }
}

int main() {
    vuln();
    return 0;
}
