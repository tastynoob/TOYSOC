

typedef struct
{
    int ctrl;
    int write;
    int read;
}USART_DEF;


typedef unsigned char byte;


#define USART_BASE 0xf0000000

#define USART ((volatile USART_DEF*)USART_BASE)


void send_char(char c);
void send_string(char* s);
byte get_char();
int get_line(char* buff);
