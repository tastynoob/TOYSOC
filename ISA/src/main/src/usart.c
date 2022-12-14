#include "usart.h"

void send_char(char c) {
    USART->write = c;
}
void send_string(char* s) {
    for (int i = 0;s[i];i++) {
        send_char(s[i]);
    }
}
byte get_char() {
    while (1) {
        int rx_finish = USART->ctrl & 0x2;
        int rx_err = USART->ctrl & 0x4;
        if (rx_finish | rx_err) {
            return USART->read;
        }
    }
}

int get_line(char* buff) {
    for (int i = 0;;i++) {
        buff[i] = get_char();
        if ((buff[i] == '\n') || (buff[i] == '\r')) {
            buff[i+1] = 0;
            return i+1;
        }
    }
}





int _write(int fd, char* pBuffer, int size) {
    for (int i = 0; i < size; i++) {
        send_char(pBuffer[i]);
    }
    return size;
}