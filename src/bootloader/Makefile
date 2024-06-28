# ** 这不是完整的Makefile！！！
# 这是负责编译bootloader的Makefile，他将boot.S和loader.c编译成boot.o和loader.o，然后将它们链接成bootloaer
# 之后bootloaer将与内核二进制文件kernel一起被编译进内核镜像文件kernel_img

# 编译工具链
CC = gcc
LD = ld
OBJCOPY = objcopy
OBJDUMP = objdump

#  编译选项
LDFLAGS = -m elf_i386
CFLAGS := -O1 -fno-builtin # -fno-builtin 避免内核中未定义函数的引用，-O1 以避免内联
CFLAGS += -fno-omit-frame-pointer # 保留 frame pointer
CFLAGS += -std=gnu99
CFLAGS += -static # 静态链接
CFLAGS += -fno-tree-ch # 防止了 read_ebp() 之前的重新排序
CFLAGS += -nostdinc # 避免使用标准库
CFLAGS += -Wall -Wno-format -Wno-unused -Werror -gstabs+ -m32 # -gstabs+ 生成stabs格式的调试信息,-m32 32位编译
CFLAGS += $(shell $(CC) -fno-stack-protector -E -x c /dev/null >/dev/null 2>&1 && echo -fno-stack-protector)

# 下面定义编译时产生的文件名
SRC_BOOT = boot.S
SRC_LOADER = loader.c
TARGET_BOOT = boot.o
TARGET_LOADER = loader.o
BIN_BOOTLOADER_TMP = bootloader.out # 临时文件，用于存放链接之后的bootloaderELF文件
BIN_BOOTLOADER = bootloader # 最终生成的bootloader二进制文件
DIS_BOOTLOADER = bootloader.asm # 反汇编文件

all: make_bootloader clean

make_bootloader:
# 编译boot
	$(CC) $(CFLAGS) $(SRC_BOOT) -c -o $(TARGET_BOOT) 
# 编译loader
	$(CC) $(CFLAGS) $(SRC_LOADER) -Os -c -o $(TARGET_LOADER)
# link
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x7C00 -o $(BIN_BOOTLOADER_TMP) $(TARGET_BOOT) $(TARGET_LOADER)
# 将ELF文件转换为bin文件
	$(OBJCOPY) -S -O binary -g -j .text $(BIN_BOOTLOADER_TMP) $(BIN_BOOTLOADER)
# 反汇编以供DEBUG
	$(OBJDUMP) -D $(BIN_BOOTLOADER_TMP) > $(DIS_BOOTLOADER)

clean: # 清理中间文件
	rm -f $(TARGET_BOOT) $(TARGET_LOADER) $(BIN_BOOTLOADER_TMP)

