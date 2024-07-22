
#include "inc/i_asm.h"
#include "inc/i_kernel.h"
#include "inc/lock.h"
#include "inc/mem.h"
#include "inc/types.h"

/*************************************************************************
 * lib.c - 定义本 OS 会使用的辅助函数
 *************************************************************************/

void* memset(void* dst, int c, uint32_t n)
{
    if ((int)dst % 4 == 0 && n % 4 == 0) {
        c &= 0xFF;
        stosl(dst, (c << 24) | (c << 16) | (c << 8) | c, n / 4);
    } else
        stosb(dst, c, n);
    return dst;
}

int memcmp(const void* v1, const void* v2, uint32_t n)
{
    const uint8_t *s1, *s2;

    s1 = v1;
    s2 = v2;
    while (n-- > 0) {
        if (*s1 != *s2)
            return *s1 - *s2;
        s1++, s2++;
    }

    return 0;
}

void* memmove(void* dst, const void* src, uint32_t n)
{
    const char* s;
    char* d;

    s = src;
    d = dst;
    if (s < d && s + n > d) {
        s += n;
        d += n;
        while (n-- > 0)
            *--d = *--s;
    } else
        while (n-- > 0)
            *d++ = *s++;

    return dst;
}

// memcpy exists to placate GCC.  Use memmove.
void* memcpy(void* dst, const void* src, uint32_t n)
{
    return memmove(dst, src, n);
}

int strncmp(const char* p, const char* q, uint32_t n)
{
    while (n > 0 && *p && *p == *q)
        n--, p++, q++;
    if (n == 0)
        return 0;
    return (uint8_t)*p - (uint8_t)*q;
}

char* strncpy(char* s, const char* t, int n)
{
    char* os;

    os = s;
    while (n-- > 0 && (*s++ = *t++) != 0)
        ;
    while (n-- > 0)
        *s++ = 0;
    return os;
}

// Like strncpy but guaranteed to NUL-terminate.
char* safestrcpy(char* s, const char* t, int n)
{
    char* os;

    os = s;
    if (n <= 0)
        return os;
    while (--n > 0 && (*s++ = *t++) != 0)
        ;
    *s = 0;
    return os;
}

int strlen(const char* s)
{
    int n;

    for (n = 0; s[n]; n++)
        ;
    return n;
}

/* ************************************************************************** */
// PC keyboard interface constants
void cprintf(char* fmt, ...);

#define KBS_TERR 0x20 /* kbd transmission error or from mouse */
#define KBSTATP 0x64 // kbd controller status port(I)
#define KBS_DIB 0x01 // kbd data in buffer
#define KBDATAP 0x60 // kbd data port(I)

#define NO 0

#define SHIFT (1 << 0)
#define CTL (1 << 1)
#define ALT (1 << 2)

#define CAPSLOCK (1 << 3)
#define NUMLOCK (1 << 4)
#define SCROLLLOCK (1 << 5)

#define E0ESC (1 << 6)

// Special keycodes
#define KEY_HOME 0xE0
#define KEY_END 0xE1
#define KEY_UP 0xE2
#define KEY_DN 0xE3
#define KEY_LF 0xE4
#define KEY_RT 0xE5
#define KEY_PGUP 0xE6
#define KEY_PGDN 0xE7
#define KEY_INS 0xE8
#define KEY_DEL 0xE9

// C('A') == Control-A
#define C(x) (x - '@')

static uint8_t shiftcode[256]
    = {
          [0x1D] CTL,
          [0x2A] SHIFT,
          [0x36] SHIFT,
          [0x38] ALT,
          [0x9D] CTL,
          [0xB8] ALT
      };

static uint8_t togglecode[256] = {
    [0x3A] CAPSLOCK,
    [0x45] NUMLOCK,
    [0x46] SCROLLLOCK
};

static uint8_t normalmap[256] = {
    NO, 0x1B, '1', '2', '3', '4', '5', '6', // 0x00
    '7', '8', '9', '0', '-', '=', '\b', '\t',
    'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', // 0x10
    'o', 'p', '[', ']', '\n', NO, 'a', 's',
    'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', // 0x20
    '\'', '`', NO, '\\', 'z', 'x', 'c', 'v',
    'b', 'n', 'm', ',', '.', '/', NO, '*', // 0x30
    NO, ' ', NO, NO, NO, NO, NO, NO,
    NO, NO, NO, NO, NO, NO, NO, '7', // 0x40
    '8', '9', '-', '4', '5', '6', '+', '1',
    '2', '3', '0', '.', NO, NO, NO, NO, // 0x50
    [0x9C] '\n', // KP_Enter
    [0xB5] '/', // KP_Div
    [0xC8] KEY_UP, [0xD0] KEY_DN,
    [0xC9] KEY_PGUP, [0xD1] KEY_PGDN,
    [0xCB] KEY_LF, [0xCD] KEY_RT,
    [0x97] KEY_HOME, [0xCF] KEY_END,
    [0xD2] KEY_INS, [0xD3] KEY_DEL
};

static uint8_t shiftmap[256] = {
    NO, 033, '!', '@', '#', '$', '%', '^', // 0x00
    '&', '*', '(', ')', '_', '+', '\b', '\t',
    'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', // 0x10
    'O', 'P', '{', '}', '\n', NO, 'A', 'S',
    'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', // 0x20
    '"', '~', NO, '|', 'Z', 'X', 'C', 'V',
    'B', 'N', 'M', '<', '>', '?', NO, '*', // 0x30
    NO, ' ', NO, NO, NO, NO, NO, NO,
    NO, NO, NO, NO, NO, NO, NO, '7', // 0x40
    '8', '9', '-', '4', '5', '6', '+', '1',
    '2', '3', '0', '.', NO, NO, NO, NO, // 0x50
    [0x9C] '\n', // KP_Enter
    [0xB5] '/', // KP_Div
    [0xC8] KEY_UP, [0xD0] KEY_DN,
    [0xC9] KEY_PGUP, [0xD1] KEY_PGDN,
    [0xCB] KEY_LF, [0xCD] KEY_RT,
    [0x97] KEY_HOME, [0xCF] KEY_END,
    [0xD2] KEY_INS, [0xD3] KEY_DEL
};

static uint8_t ctlmap[256] = {
    NO, NO, NO, NO, NO, NO, NO, NO,
    NO, NO, NO, NO, NO, NO, NO, NO,
    C('Q'), C('W'), C('E'), C('R'), C('T'), C('Y'), C('U'), C('I'),
    C('O'), C('P'), NO, NO, '\r', NO, C('A'), C('S'),
    C('D'), C('F'), C('G'), C('H'), C('J'), C('K'), C('L'), NO,
    NO, NO, NO, C('\\'), C('Z'), C('X'), C('C'), C('V'),
    C('B'), C('N'), C('M'), NO, NO, C('/'), NO, NO,
    [0x9C] '\r', // KP_Enter
    [0xB5] C('/'), // KP_Div
    [0xC8] KEY_UP, [0xD0] KEY_DN,
    [0xC9] KEY_PGUP, [0xD1] KEY_PGDN,
    [0xCB] KEY_LF, [0xCD] KEY_RT,
    [0x97] KEY_HOME, [0xCF] KEY_END,
    [0xD2] KEY_INS, [0xD3] KEY_DEL
};

#define MONO_BASE 0x3B4
#define MONO_BUF 0xB0000
#define CGA_BASE 0x3D4
#define CGA_BUF 0xB8000

#define CRT_ROWS 25
#define CRT_COLS 80
#define CRT_SIZE (CRT_ROWS * CRT_COLS)

static void cons_intr(int (*proc)(void));
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
    inb(0x84);
    inb(0x84);
    inb(0x84);
    inb(0x84);
}

/***** Serial I/O code *****/

#define COM1 0x3F8

#define COM_RX 0 // In:	Receive buffer (DLAB=0)
#define COM_TX 0 // Out: Transmit buffer (DLAB=0)
#define COM_DLL 0 // Out: Divisor Latch Low (DLAB=1)
#define COM_DLM 1 // Out: Divisor Latch High (DLAB=1)
#define COM_IER 1 // Out: Interrupt Enable Register
#define COM_IER_RDI 0x01 //   Enable receiver data interrupt
#define COM_IIR 2 // In:	Interrupt ID Register
#define COM_FCR 2 // Out: FIFO Control Register
#define COM_LCR 3 // Out: Line Control Register
#define COM_LCR_DLAB 0x80 //   Divisor latch access bit
#define COM_LCR_WLEN8 0x03 //   Wordlength: 8 bits
#define COM_MCR 4 // Out: Modem Control Register
#define COM_MCR_RTS 0x02 // RTS complement
#define COM_MCR_DTR 0x01 // DTR complement
#define COM_MCR_OUT2 0x08 // Out2 complement
#define COM_LSR 5 // In:	Line Status Register
#define COM_LSR_DATA 0x01 //   Data available
#define COM_LSR_TXRDY 0x20 //   Transmit buffer avail
#define COM_LSR_TSRE 0x40 //   Transmitter off

static bool serial_exists;

static int
serial_proc_data(void)
{
    if (!(inb(COM1 + COM_LSR) & COM_LSR_DATA))
        return -1;
    return inb(COM1 + COM_RX);
}

void serial_intr(void)
{
    if (serial_exists)
        cons_intr(serial_proc_data);
}

static void
serial_putc(int c)
{
    int i;

    for (i = 0;
         !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
         i++)
        delay();

    outb(COM1 + COM_TX, c);
}

static void
serial_init(void)
{
    // Turn off the FIFO
    outb(COM1 + COM_FCR, 0);

    // Set speed; requires DLAB latch
    outb(COM1 + COM_LCR, COM_LCR_DLAB);
    outb(COM1 + COM_DLL, (uint8_t)(115200 / 9600));
    outb(COM1 + COM_DLM, 0);

    // 8 data bits, 1 stop bit, parity off; turn off DLAB latch
    outb(COM1 + COM_LCR, COM_LCR_WLEN8 & ~COM_LCR_DLAB);

    // No modem controls
    outb(COM1 + COM_MCR, 0);
    // Enable rcv interrupts
    outb(COM1 + COM_IER, COM_IER_RDI);

    // Clear any preexisting overrun indications and interrupts
    // Serial port doesn't exist if COM_LSR returns 0xFF
    serial_exists = (inb(COM1 + COM_LSR) != 0xFF);
    (void)inb(COM1 + COM_IIR);
    (void)inb(COM1 + COM_RX);
}

/***** Parallel port output code *****/
// For information on PC parallel port programming, see the class References
// page.

static void
lpt_putc(int c)
{
    int i;

    for (i = 0; !(inb(0x378 + 1) & 0x80) && i < 12800; i++)
        delay();
    outb(0x378 + 0, c);
    outb(0x378 + 2, 0x08 | 0x04 | 0x01);
    outb(0x378 + 2, 0x08);
}

/***** Text-mode CGA/VGA display output *****/

static unsigned addr_6845;
static uint16_t* crt_buf;
static uint16_t crt_pos;

static void
cga_init(void)
{
    volatile uint16_t* cp;
    uint16_t was;
    unsigned pos;

    cp = (uint16_t*)(K_ADDR_BASE + CGA_BUF);
    was = *cp;
    *cp = (uint16_t)0xA55A;
    if (*cp != 0xA55A) {
        cp = (uint16_t*)(K_ADDR_BASE + MONO_BUF);
        addr_6845 = MONO_BASE;
    } else {
        *cp = was;
        addr_6845 = CGA_BASE;
    }

    /* Extract cursor location */
    outb(addr_6845, 14);
    pos = inb(addr_6845 + 1) << 8;
    outb(addr_6845, 15);
    pos |= inb(addr_6845 + 1);

    crt_buf = (uint16_t*)cp;
    crt_pos = pos;
}

static void
cga_putc(int c)
{
    // if no attribute given, then use black on white
    if (!(c & ~0xFF))
        c |= 0x0700;

    switch (c & 0xff) {
    // 对于转义字符的处理
    case '\b':
        if (crt_pos > 0) {
            crt_pos--;
            crt_buf[crt_pos] = (c & ~0xff) | ' ';
        }
        break;
    case '\n':
        crt_pos += CRT_COLS;
        /* fallthru */
    case '\r':
        crt_pos -= (crt_pos % CRT_COLS);
        break;
    case '\t':
        cons_putc(' ');
        cons_putc(' ');
        cons_putc(' ');
        cons_putc(' ');
        cons_putc(' ');
        break;
    default:
        crt_buf[crt_pos++] = c; /* write the character */
        break;
    }

    // What is the purpose of this?
    if (crt_pos >= CRT_SIZE) // 当输出字符超过终端范围
    {
        int i;
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t)); // 已有字符往上移动一行
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++) // 清零最后一行
            crt_buf[i] = 0x0700 | ' ';
        crt_pos -= CRT_COLS; // 索引向前移动，即从最后一行的开头写入
    }

    /* move that little blinky thing */
    outb(addr_6845, 14);
    outb(addr_6845 + 1, crt_pos >> 8);
    outb(addr_6845, 15);
    outb(addr_6845 + 1, crt_pos);
}

/***** Keyboard input code *****/

#define NO 0

#define SHIFT (1 << 0)
#define CTL (1 << 1)
#define ALT (1 << 2)

#define CAPSLOCK (1 << 3)
#define NUMLOCK (1 << 4)
#define SCROLLLOCK (1 << 5)

#define E0ESC (1 << 6)

static uint8_t* charcode[4] = {
    normalmap,
    shiftmap,
    ctlmap,
    ctlmap
};

/*
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
    int c;
    uint8_t stat, data;
    static uint32_t shift;

    stat = inb(KBSTATP);
    if ((stat & KBS_DIB) == 0)
        return -1;
    // Ignore data from mouse.
    if (stat & KBS_TERR)
        return -1;

    data = inb(KBDATAP);

    if (data == 0xE0) {
        // E0 escape character
        shift |= E0ESC;
        return 0;
    } else if (data & 0x80) {
        // Key released
        data = (shift & E0ESC ? data : data & 0x7F);
        shift &= ~(shiftcode[data] | E0ESC);
        return 0;
    } else if (shift & E0ESC) {
        // Last character was an E0 escape; or with 0x80
        data |= 0x80;
        shift &= ~E0ESC;
    }

    shift |= shiftcode[data];
    shift ^= togglecode[data];

    c = charcode[shift & (CTL | SHIFT)][data];
    if (shift & CAPSLOCK) {
        if ('a' <= c && c <= 'z')
            c += 'A' - 'a';
        else if ('A' <= c && c <= 'Z')
            c += 'a' - 'A';
    }

    // Process special keys
    // Ctrl-Alt-Del: reboot
    if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
        cprintf("Rebooting!\n");
        outb(0x92, 0x3); // courtesy of Chris Frost
    }

    return c;
}

void kbd_intr(void)
{
    cons_intr(kbd_proc_data);
}

static void
kbd_init(void)
{
    // Drain the kbd buffer so that QEMU generates interrupts.
    kbd_intr();
    // irq_setmask_8259A(irq_mask_8259A & ~(1 << IRQ_KBD));
}

/***** General device-independent console code *****/
// Here we manage the console input buffer,
// where we stash characters received from the keyboard or serial port
// whenever the corresponding interrupt occurs.

#define CONSBUFSIZE 512

static struct
{
    uint8_t buf[CONSBUFSIZE];
    uint32_t rpos;
    uint32_t wpos;
    struct spinlock lock;
    int use_lock;
} cons;

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
    int c;

    while ((c = (*proc)()) != -1) {
        if (c == 0)
            continue;
        cons.buf[cons.wpos++] = c;
        if (cons.wpos == CONSBUFSIZE)
            cons.wpos = 0;
    }
}

// return the next input character from the console, or 0 if none waiting
int cons_getc(void)
{
    int c;

    // poll for any pending input characters,
    // so that this function works even when interrupts are disabled
    // (e.g., when called from the kernel monitor).
    serial_intr();
    kbd_intr();

    // grab the next character from the input buffer.
    if (cons.rpos != cons.wpos) {
        c = cons.buf[cons.rpos++];
        if (cons.rpos == CONSBUFSIZE)
            cons.rpos = 0;
        return c;
    }
    return 0;
}

// output a character to the console
static void
cons_putc(int c)
{
    serial_putc(c); // 向串口输出
    lpt_putc(c);
    cga_putc(c); // 向控制台输出字符
}

// initialize the console devices
void cons_init(void)
{
    initlock(&cons.lock, "console");
    cons.use_lock = 0;

    cga_init();
    kbd_init();
    serial_init();

    if (!serial_exists)
        cprintf("Serial port does not exist!\n");
}

void cons_uselock() { cons.use_lock = 1; }

// `High'-level console I/O.  Used by readline and cprintf.

void cputchar(int c)
{
    cons_putc(c);
}

int getchar(void)
{
    int c;

    while ((c = cons_getc()) == 0)
        /* do nothing */;
    return c;
}

int iscons(int fdnum)
{
    // used by readline
    return 1;
}

static void
printint(int xx, int base, int sign)
{
    static char digits[] = "0123456789abcdef";
    char buf[16];
    int i;
    uint32_t x;

    if (sign && (sign = xx < 0))
        x = -xx;
    else
        x = xx;

    i = 0;
    do {
        buf[i++] = digits[x % base];
    } while ((x /= base) != 0);

    if (sign)
        buf[i++] = '-';

    while (--i >= 0)
        cons_putc(buf[i]);
}

void cprintf(char* fmt, ...)
{
    int i, c;
    uint32_t* argp;
    char* s;

    if (cons.use_lock)
        acquire(&cons.lock);

    argp = (uint32_t*)(void*)(&fmt + 1);
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++) {
        if (c != '%') {
            cons_putc(c);
            continue;
        }
        c = fmt[++i] & 0xff;
        if (c == 0)
            break;
        switch (c) {
        case 'd':
            printint(*argp++, 10, 1);
            break;
        case 'x':
        case 'p':
            printint(*argp++, 16, 0);
            break;
        case 's':
            if ((s = (char*)*argp++) == 0)
                s = "(null)";
            for (; *s; s++)
                cons_putc(*s);
            break;
        case '%':
            cons_putc('%');
            break;
        default:
            // Print unknown % sequence to draw attention.
            cons_putc('%');
            cons_putc(c);
            break;
        }
    }

    if (cons.use_lock)
        release(&cons.lock);
}

/**
 * 自旋 ms 微秒
 */
void spin(int ms)
{
    // TODO：
}

// void error()
