#include <stdio.h>
#include <string.h>
#include <unistd.h>

void win() {
    printf("\n🎉 YOU WIN! Flag: FLAG{symbolic_execution_rocks}\n\n");
}

void lose() {
    printf("❌ Wrong password\n");
}

int main(int argc, char **argv) {
    printf("[*] PID: %d\n", getpid());
    printf("[*] Press Enter to check password...\n");
    getchar();  // WAIT HERE
    
    if (argc != 2) {
        printf("Usage: %s <password>\n", argv[0]);
        return 1;
    }
    
    char *input = argv[1];
    
    printf("[*] Checking password: %s\n", input);
    
    // Complex password check
    if (input[0] == 'S' &&
        input[1] == 'Y' &&
        input[2] == 'M' &&
        input[3] == 'B' &&
        input[4] == 'O' &&
        input[5] == 'L' &&
        input[6] == 'I' &&
        input[7] == 'C') {
        win();
    } else {
        lose();
    }
    
    return 0;
}
