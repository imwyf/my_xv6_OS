# 编译工具链
CC = gcc
AS = gas
LD = ld
OBJCOPY = objcopy
OBJDUMP = objdump
# 编译选项
CFLAGS = -fno-pic -static -fno-builtin -fno-strict-aliasing -O1 -Wall -MD -ggdb -m32 -Wno-error -fno-omit-frame-pointer -std=gnu99
CFLAGS += -I.
CFLAGS += $(shell $(CC) -fno-stack-protector -E -x c /dev/null >/dev/null 2>&1 && echo -fno-stack-protector)
ASFLAGS = -m32 -gdwarf-2 -Wa,-divide
LDFLAGS += -m $(shell $(LD) -V | grep elf_i386 2>/dev/null | head -n 1)
GCC_LIB := $(shell $(CC) $(CFLAGS) -print-libgcc-file-name)

SRCDIR = ./src
OBJDIR = ./obj
INCDIR = ./inc

# 源文件列表
SRCS = \
	kernel_entry.S\
	main.c\
	kernel_mem.c\
	lock.c\
	cpu.c\
	interrupt.c\
	proc.c\
	lib.c

# 待链接的 obj 文件列表
OBJS = $(addprefix $(OBJDIR)/, $(addsuffix .o, $(basename $(SRCS))))

myos.img: bootloader kernel
	dd if=/dev/zero of=$(OBJDIR)/myos.img count=10000
	dd if=$(OBJDIR)/bootloader of=$(OBJDIR)/myos.img conv=notrunc
	dd if=$(OBJDIR)/kernel of=$(OBJDIR)/myos.img seek=2 conv=notrunc

bootloader:
	$(CC) $(CFLAGS) -c $(SRCDIR)/loader.c -o $(OBJDIR)/loader.o
	$(CC) $(CFLAGS) -c $(SRCDIR)/boot.S -o $(OBJDIR)/boot.o
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x7C00 -o $(OBJDIR)/bootloader.o $(OBJDIR)/boot.o $(OBJDIR)/loader.o
	$(OBJDUMP) -S $(OBJDIR)/bootloader.o > $(OBJDIR)/bootloader.asm
	$(OBJCOPY) -S -O binary -j .text $(OBJDIR)/bootloader.o $(OBJDIR)/bootloader

kernel: $(SRCS)
	$(LD) $(LDFLAGS) -T $(SRCDIR)/kernel.ld -o $(OBJDIR)/kernel $(OBJS)
	$(OBJDUMP) -S $(OBJDIR)/kernel > $(OBJDIR)/kernel.asm
	$(OBJDUMP) -t $(OBJDIR)/kernel | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $(OBJDIR)/kernel.sym

# 编译每一个 .S 和 .c 文件
$(SRCS):
	$(CC) $(CFLAGS) -c $(SRCDIR)/$@ -o $(addprefix $(OBJDIR)/, $(addsuffix .o, $(basename $@)))


ifndef QEMU
QEMU = $(shell if which qemu > /dev/null; \
	then echo qemu; exit; \
	elif which qemu-system-i386 > /dev/null; \
	then echo qemu-system-i386; exit; \
	elif which qemu-system-x86_64 > /dev/null; \
	then echo qemu-system-x86_64; exit; \
	else \
	qemu=/Applications/Q.app/Contents/MacOS/i386-softmmu.app/Contents/MacOS/i386-softmmu; \
	if test -x $$qemu; then echo $$qemu; exit; fi; fi; \
	echo "***" 1>&2; \
	echo "*** Error: Couldn't find a working QEMU executable." 1>&2; \
	echo "*** Is the directory containing the qemu binary in your PATH" 1>&2; \
	echo "*** or have you tried setting the QEMU variable in Makefile?" 1>&2; \
	echo "***" 1>&2; exit 1)
endif

# try to generate a unique GDB port
GDBPORT = 1234
# QEMU's gdb stub command line changed in 0.11
QEMUGDB = $(shell if $(QEMU) -help | grep -q '^-gdb'; \
	then echo "-gdb tcp::$(GDBPORT)"; \
	else echo "-s -p $(GDBPORT)"; fi)

ifndef CPUS
CPUS := 2
endif

QEMUOPTS = -drive file=$(OBJDIR)/myos.img,index=0,media=disk,format=raw -smp $(CPUS) -m 512 -nographic

qemu: clean myos.img
	$(QEMU) -serial mon:stdio $(QEMUOPTS)

qemu-gdb: clean myos.img
	@echo "*** Now run 'gdb'." 1>&2
	$(QEMU) -serial mon:stdio $(QEMUOPTS) -S $(QEMUGDB)

clean:
	rm -f ./obj/* *.tex *.dvi *.idx *.aux *.log *.ind *.ilg \
	*.o *.d *.asm *.sym *.out bootloader kernel myos.img

