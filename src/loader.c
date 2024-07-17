/*************************************************************************
 * loader.c - 加载ELF格式的内核二进制文件进内存，然后启动内核
 *************************************************************************/

#include "inc/i_asm.h"
#include <inc/elf.h>

#define SECT_SIZE 512
#define PAGE_SIZE SECT_SIZE * 8 // 4kb
#define ELF_HEADER_TMP ((Elf32_Ehdr*)0x10000) // 内核镜像被拷贝到的位置

void read_sect(void*, uint32_t);
void read_seg(uint32_t, uint32_t, uint32_t);

void loader()
{
    read_seg((uint32_t)ELF_HEADER_TMP, PAGE_SIZE, 0); // 先读入一页来找到ELF头

    /* 检测是否是elf文件 */
    if (ELF_HEADER_TMP->e_ident[0] != 0x7f || ELF_HEADER_TMP->e_ident[1] != 'E' || ELF_HEADER_TMP->e_ident[2] != 'L' || ELF_HEADER_TMP->e_ident[3] != 'F') {
        return;
    }

    /* 复制各个段到指定的内存地址 */
    Elf32_Phdr* phdr = (Elf32_Phdr*)((uint8_t*)ELF_HEADER_TMP + ELF_HEADER_TMP->e_phoff); // 通过ELF头找到 Program Header Table
    Elf32_Phdr* ephdr = phdr + ELF_HEADER_TMP->e_phnum; // Program Header Table 尾指针
    for (; phdr < ephdr; phdr++) // 遍历Table中每一项
        read_seg(phdr->p_paddr, phdr->p_memsz, phdr->p_offset); // paddr该段的物理地址 memsz该段占用的字节 offset该段在文件中的偏移

    /* 跳入内核 */
    ((void (*)(void))(ELF_HEADER_TMP->e_entry))(); // 将e_entry作为函数指针跳入
}

/**
 * 从硬盘中的ELF文件的offset处开始，复制size大小的数据到内存的dst处
 */
void read_seg(uint32_t dst, uint32_t size, uint32_t offset)
{
    /* 由于此时没有启动文件系统，只能通过PIO模式访问硬盘，读取是一个扇区一个扇区的读 */
    uint32_t end = dst + size;
    dst &= ~(SECT_SIZE - 1);
    uint32_t sect_no = (offset / SECT_SIZE) + 2; // 根据offset向下舍入到扇区边界，最后得到的sect_no是offset所处的扇区的序号，+2因为ELF文件从第三个扇区开始
    while (dst < end) {
        read_sect((uint8_t*)dst, sect_no);
        dst += SECT_SIZE;
        sect_no++;
    }
}

/**
 * 读取0x1F7端口来判断硬盘是否可读
 */
void waitdisk(void)
{
    while ((inb(0x1F7) & 0xC0) != 0x40)
        ;
}

/**
 * PIO模式：从硬盘第sect_no扇区开始读取下一个扇区至内存的dst
 */
void read_sect(void* dst, uint32_t sect_no)
{
    waitdisk();

    outb(0x1F2, 1); // 读一个扇区
    outb(0x1F3, sect_no);
    outb(0x1F4, sect_no >> 8);
    outb(0x1F5, sect_no >> 16);
    outb(0x1F6, (sect_no >> 24) | 0xE0);
    outb(0x1F7, 0x20); // 0x20 代表读扇区

    waitdisk();

    insl(0x1F0, dst, SECT_SIZE / 4); // 读到dst处
}
