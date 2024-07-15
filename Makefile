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

OBJS = \
	main.o\
	kernel_mem.o

myos.img: bootloader kernel
	dd if=/dev/zero of=myos.img count=10000
	dd if=bootloader of=myos.img conv=notrunc
	dd if=kernel of=myos.img seek=2 conv=notrunc

bootloader: boot.S loader.c
	$(CC) $(CFLAGS) -c loader.c
	$(CC) $(CFLAGS) -c boot.S
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x7C00 -o bootloader.out boot.o loader.o
	$(OBJDUMP) -S bootloader.out > bootloader.asm
	$(OBJCOPY) -S -O binary -j .text bootloader.out bootloader

kernel: kernel_entry $(OBJS)
	$(LD) $(LDFLAGS) -T kernel.ld -o kernel kernel_entry.o $(OBJS) $(GCC_LIB)
	$(OBJDUMP) -S kernel > kernel.asm
	$(OBJDUMP) -t kernel | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > kernel.sym

kernel_entry:
	$(CC) $(CFLAGS) -c kernel_entry.S

$(OBJS): %.o: %.c
	$(CC) $(CFLAGS) -c $<

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

QEMUOPTS = -drive file=myos.img,index=0,media=disk,format=raw -smp $(CPUS) -m 512 -nographic

qemu: clean myos.img
	$(QEMU) -serial mon:stdio $(QEMUOPTS)

.gdbinit: .gdbinit.tmpl
	sed "s/localhost:1234/localhost:$(GDBPORT)/" < $^ > $@

qemu-gdb: clean myos.img .gdbinit
	@echo "*** Now run 'gdb'." 1>&2
	$(QEMU) -serial mon:stdio $(QEMUOPTS) -S $(QEMUGDB)

clean:
	rm -f *.tex *.dvi *.idx *.aux *.log *.ind *.ilg \
	*.o *.d *.asm *.sym *.out bootloader kernel myos.img .gdbinit

