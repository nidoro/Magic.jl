#ifdef _WIN32
#include <windows.h>
#include <bcrypt.h>
#else
#include <stdio.h>
#include <stdlib.h>
#endif

#include <string.h>

void RU__InitAndReadFromURandomDevice(char* buffer, int bytes);
void (*RU_ReadFromURandomDevice)(char* buffer, int bytes) = RU__InitAndReadFromURandomDevice;

#ifdef _WIN32
// Windows implementation
void RU__ReadFromURandomDevice(char* buffer, int bytes) {
    BCryptGenRandom(NULL, (PUCHAR)buffer, bytes, BCRYPT_USE_SYSTEM_PREFERRED_RNG);
}

void RU__InitAndReadFromURandomDevice(char* buffer, int bytes) {
    // On Windows, no initialization needed
    RU__ReadFromURandomDevice(buffer, bytes);
    RU_ReadFromURandomDevice = RU__ReadFromURandomDevice;
}
#else
// Linux implementation
FILE* RU_devurandom = 0;

void RU_OpenURandomDevice() {
    RU_devurandom = fopen("/dev/urandom", "rb");
    if (!RU_devurandom) {
        fprintf(stderr, "Failed to open /dev/urandom\n");
        exit(1);
    }
}

void RU__ReadFromURandomDevice(char* buffer, int bytes) {
    fread(buffer, bytes, 1, RU_devurandom);
}

void RU__InitAndReadFromURandomDevice(char* buffer, int bytes) {
    RU_OpenURandomDevice();
    RU__ReadFromURandomDevice(buffer, bytes);
    RU_ReadFromURandomDevice = RU__ReadFromURandomDevice;
}
#endif

int RU_GetRandomInt(int min, int max) {
    unsigned int r;
    RU_ReadFromURandomDevice((char*) &r, sizeof(r));
    return min + (r % (int)(max - min + 1));
}

#define RU_CHAR_SET_ALPHA_NUM "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

void RU_GenerateRandomString(char* buffer, int size, const char* charSet) {
    int charSetLen = strlen(charSet);
    RU_ReadFromURandomDevice(buffer, size);
    for (int i = 0; i < size; ++i) {
        buffer[i] = charSet[((unsigned int)buffer[i]) % charSetLen];
    }
    buffer[size] = 0;
}
