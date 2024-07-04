
bootloader.out:     file format elf32-i386


Disassembly of section .text:

00007c00 <_start>:

.text
.globl _start
_start:                                     # 相当于c语言中的main函数，是汇编程序的入口
  .code16                                   # 指示以下代码是在实模式下执行
  cli                                       # 关中断，因为后面对段寄存器的操作需要关中断
    7c00:	fa                   	cli    
  cld                                       # 将标志寄存器中的方向标志位DF设置为0，使得字符串操作指令（movs）将按照从低地址到高地址的方向执行
    7c01:	fc                   	cld    

  xorw    %ax,%ax                           # 使用xorw指令清零ax，效果相当于movw $0, %ax
    7c02:	31 c0                	xor    %eax,%eax

# 下面三条指令负责清零ds, es, ss寄存器（段寄存器）
  movw    %ax,%ds             
    7c04:	8e d8                	mov    %eax,%ds
  movw    %ax,%es             
    7c06:	8e c0                	mov    %eax,%es
  movw    %ax,%ss             
    7c08:	8e d0                	mov    %eax,%ss

00007c0a <seta20_1>:

# 打开A20地址位：A20地址位由键盘控制器芯片8042控制，8042有两个IO端口：0x60和0x64 
seta20_1:
  inb     $0x64,%al                         # 读出0x64端口得到8042的状态寄存器
    7c0a:	e4 64                	in     $0x64,%al
  testb   $0x2,%al                          # 看看第2bit，若为0代表键盘输入缓冲区为空，可以写入
    7c0c:	a8 02                	test   $0x2,%al
  jnz     seta20_1                          # 否则继续等待
    7c0e:	75 fa                	jne    7c0a <seta20_1>

  movb    $0xd1,%al                         # 发送0xd1命令到0x64端口
    7c10:	b0 d1                	mov    $0xd1,%al
  outb    %al,$0x64
    7c12:	e6 64                	out    %al,$0x64

00007c14 <seta20_2>:

seta20_2:
  inb     $0x64,%al                         # 同0x64端口一样的流程
    7c14:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7c16:	a8 02                	test   $0x2,%al
  jnz     seta20_2
    7c18:	75 fa                	jne    7c14 <seta20_2>

  movb    $0xdf,%al                         # 发送0xdf到0x60端口
    7c1a:	b0 df                	mov    $0xdf,%al
  outb    %al,$0x60
    7c1c:	e6 60                	out    %al,$0x60

# 至此，A20地址位已经打开

# 通过gdtr载入一个GDT，并启用保护模式
  lgdt    gdtr                              # 载入gdt
    7c1e:	0f 01 16             	lgdtl  (%esi)
    7c21:	64 7c 0f             	fs jl  7c33 <boot32+0x1>
  movl    %cr0, %eax
    7c24:	20 c0                	and    %al,%al
  orl     $CR0_PE_ON, %eax
    7c26:	66 83 c8 01          	or     $0x1,%ax
  movl    %eax, %cr0                        # 按下trigger，打开保护模式
    7c2a:	0f 22 c0             	mov    %eax,%cr0
  ljmp    $CODE_SEG_SELECTOR, $boot32       # 跳转到boot32处执行（cs=CODE_SEG_SELECTOR，ip=boot32）
    7c2d:	ea                   	.byte 0xea
    7c2e:	32 7c 08 00          	xor    0x0(%eax,%ecx,1),%bh

00007c32 <boot32>:

  .code32                                   # 指示以下代码是在保护模式下执行
boot32:
# 应保护模式的要求，下面的指令将设置32位保护模式下的段选择子以提供基于GDT的地址翻译
  movw    $DATA_SEG_SELECTOR, %ax 
    7c32:	66 b8 10 00          	mov    $0x10,%ax
  movw    %ax, %ds                
    7c36:	8e d8                	mov    %eax,%ds
  movw    %ax, %es                
    7c38:	8e c0                	mov    %eax,%es
  movw    %ax, %fs                
    7c3a:	8e e0                	mov    %eax,%fs
  movw    %ax, %gs                
    7c3c:	8e e8                	mov    %eax,%gs
  movw    %ax, %ss                
    7c3e:	8e d0                	mov    %eax,%ss
  
# 将栈顶设定在start处，也就是地址0x7c00处，call指令将返回地址入栈，将控制权交给loader：其负责载入内核并启动
  movl    $_start, %esp
    7c40:	bc 00 7c 00 00       	mov    $0x7c00,%esp
  call    loader
    7c45:	e8 cb 00 00 00       	call   7d15 <loader>

00007c4a <boot_fail_loop>:

# 显然若是启动正常，call之后不应该返回，若返回则说明loader没有正常启动，于是跳转到boot_fail_loop处无限循环
boot_fail_loop:
  jmp     boot_fail_loop
    7c4a:	eb fe                	jmp    7c4a <boot_fail_loop>

00007c4c <gdt>:
	...
    7c54:	ff                   	(bad)  
    7c55:	ff 00                	incl   (%eax)
    7c57:	00 00                	add    %al,(%eax)
    7c59:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
    7c60:	00                   	.byte 0x0
    7c61:	92                   	xchg   %eax,%edx
    7c62:	cf                   	iret   
	...

00007c64 <gdtr>:
    7c64:	17                   	pop    %ss
    7c65:	00 4c 7c 00          	add    %cl,0x0(%esp,%edi,2)
	...

00007c6a <waitdisk>:

/**
 * 读取0x1F7端口来判断硬盘是否可读
 */
void waitdisk(void)
{
    7c6a:	55                   	push   %ebp
    7c6b:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
    uint8_t data;
    asm volatile("inb %w1,%0"
    7c6d:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7c72:	ec                   	in     (%dx),%al
    while ((inb(0x1F7) & 0xC0) != 0x40)
    7c73:	83 e0 c0             	and    $0xffffffc0,%eax
    7c76:	3c 40                	cmp    $0x40,%al
    7c78:	75 f8                	jne    7c72 <waitdisk+0x8>
        ;
}
    7c7a:	5d                   	pop    %ebp
    7c7b:	c3                   	ret    

00007c7c <read_sect>:

/**
 * PIO模式：从硬盘第sect_no扇区开始读取下一个扇区至内存的dst
 */
void read_sect(void* dst, uint32_t sect_no)
{
    7c7c:	55                   	push   %ebp
    7c7d:	89 e5                	mov    %esp,%ebp
    7c7f:	57                   	push   %edi
    7c80:	53                   	push   %ebx
    7c81:	8b 5d 0c             	mov    0xc(%ebp),%ebx
    waitdisk();
    7c84:	e8 e1 ff ff ff       	call   7c6a <waitdisk>
 * outb(port,data): 向port写入1字节数据data
 */
static inline void
outb(int port, uint8_t data)
{
    asm volatile("outb %0,%w1"
    7c89:	ba f2 01 00 00       	mov    $0x1f2,%edx
    7c8e:	b8 01 00 00 00       	mov    $0x1,%eax
    7c93:	ee                   	out    %al,(%dx)
    7c94:	b2 f3                	mov    $0xf3,%dl
    7c96:	89 d8                	mov    %ebx,%eax
    7c98:	ee                   	out    %al,(%dx)
    7c99:	0f b6 c7             	movzbl %bh,%eax
    7c9c:	b2 f4                	mov    $0xf4,%dl
    7c9e:	ee                   	out    %al,(%dx)

    outb(0x1F2, 1); // 读一个扇区
    outb(0x1F3, sect_no);
    outb(0x1F4, sect_no >> 8);
    outb(0x1F5, sect_no >> 16);
    7c9f:	89 d8                	mov    %ebx,%eax
    7ca1:	c1 e8 10             	shr    $0x10,%eax
    7ca4:	b2 f5                	mov    $0xf5,%dl
    7ca6:	ee                   	out    %al,(%dx)
    outb(0x1F6, (sect_no >> 24) | 0xE0);
    7ca7:	c1 eb 18             	shr    $0x18,%ebx
    7caa:	89 d8                	mov    %ebx,%eax
    7cac:	83 c8 e0             	or     $0xffffffe0,%eax
    7caf:	b2 f6                	mov    $0xf6,%dl
    7cb1:	ee                   	out    %al,(%dx)
    7cb2:	b2 f7                	mov    $0xf7,%dl
    7cb4:	b8 20 00 00 00       	mov    $0x20,%eax
    7cb9:	ee                   	out    %al,(%dx)
    outb(0x1F7, 0x20); // 0x20 代表读扇区

    waitdisk();
    7cba:	e8 ab ff ff ff       	call   7c6a <waitdisk>
    asm volatile("cld\n\trepne\n\tinsl"
    7cbf:	8b 7d 08             	mov    0x8(%ebp),%edi
    7cc2:	b9 80 00 00 00       	mov    $0x80,%ecx
    7cc7:	ba f0 01 00 00       	mov    $0x1f0,%edx
    7ccc:	fc                   	cld    
    7ccd:	f2 6d                	repnz insl (%dx),%es:(%edi)

    insl(0x1F0, dst, SECT_SIZE / 4); // 读到dst处
}
    7ccf:	5b                   	pop    %ebx
    7cd0:	5f                   	pop    %edi
    7cd1:	5d                   	pop    %ebp
    7cd2:	c3                   	ret    

00007cd3 <read_seg>:
{
    7cd3:	55                   	push   %ebp
    7cd4:	89 e5                	mov    %esp,%ebp
    7cd6:	57                   	push   %edi
    7cd7:	56                   	push   %esi
    7cd8:	53                   	push   %ebx
    7cd9:	83 ec 08             	sub    $0x8,%esp
    7cdc:	8b 5d 08             	mov    0x8(%ebp),%ebx
    uint32_t end = dst + size;
    7cdf:	89 de                	mov    %ebx,%esi
    7ce1:	03 75 0c             	add    0xc(%ebp),%esi
    dst &= ~(SECT_SIZE - 1);
    7ce4:	81 e3 00 fe ff ff    	and    $0xfffffe00,%ebx
    uint32_t sect_no = (offset / SECT_SIZE) + 1; // 根据offset向下舍入到扇区边界，最后得到的sect_no是offset所处的扇区的序号
    7cea:	8b 7d 10             	mov    0x10(%ebp),%edi
    7ced:	c1 ef 09             	shr    $0x9,%edi
    7cf0:	83 c7 01             	add    $0x1,%edi
    while (dst < end) {
    7cf3:	39 de                	cmp    %ebx,%esi
    7cf5:	76 16                	jbe    7d0d <read_seg+0x3a>
        read_sect((uint8_t*)dst, sect_no);
    7cf7:	89 7c 24 04          	mov    %edi,0x4(%esp)
    7cfb:	89 1c 24             	mov    %ebx,(%esp)
    7cfe:	e8 79 ff ff ff       	call   7c7c <read_sect>
        dst += SECT_SIZE;
    7d03:	81 c3 00 02 00 00    	add    $0x200,%ebx
    while (dst < end) {
    7d09:	39 de                	cmp    %ebx,%esi
    7d0b:	77 ea                	ja     7cf7 <read_seg+0x24>
}
    7d0d:	83 c4 08             	add    $0x8,%esp
    7d10:	5b                   	pop    %ebx
    7d11:	5e                   	pop    %esi
    7d12:	5f                   	pop    %edi
    7d13:	5d                   	pop    %ebp
    7d14:	c3                   	ret    

00007d15 <loader>:
{
    7d15:	55                   	push   %ebp
    7d16:	89 e5                	mov    %esp,%ebp
    7d18:	56                   	push   %esi
    7d19:	53                   	push   %ebx
    7d1a:	83 ec 10             	sub    $0x10,%esp
    read_seg((uint32_t)ELF_HEADER_TMP, PAGE_SIZE, 0); // 先读入一页来找到ELF头
    7d1d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
    7d24:	00 
    7d25:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
    7d2c:	00 
    7d2d:	c7 04 24 00 00 01 00 	movl   $0x10000,(%esp)
    7d34:	e8 9a ff ff ff       	call   7cd3 <read_seg>
    if (ELF_HEADER_TMP->e_ident[0] != 0x7f || ELF_HEADER_TMP->e_ident[1] != 'E' || ELF_HEADER_TMP->e_ident[2] != 'L' || ELF_HEADER_TMP->e_ident[3] != 'F') {
    7d39:	81 3d 00 00 01 00 7f 	cmpl   $0x464c457f,0x10000
    7d40:	45 4c 46 
    7d43:	74 02                	je     7d47 <loader+0x32>
    7d45:	eb fe                	jmp    7d45 <loader+0x30>
    Elf_Phdr* phdr = (Elf_Phdr*)((uint8_t*)ELF_HEADER_TMP + ELF_HEADER_TMP->e_phoff); // 通过ELF头找到 Program Header Table
    7d47:	a1 1c 00 01 00       	mov    0x1001c,%eax
    7d4c:	8d 98 00 00 01 00    	lea    0x10000(%eax),%ebx
    Elf_Phdr* ephdr = phdr + ELF_HEADER_TMP->e_phnum; // Program Header Table 尾指针
    7d52:	0f b7 35 2c 00 01 00 	movzwl 0x1002c,%esi
    7d59:	c1 e6 05             	shl    $0x5,%esi
    7d5c:	01 de                	add    %ebx,%esi
    for (; phdr < ephdr; phdr++) // 遍历Table中每一项
    7d5e:	39 f3                	cmp    %esi,%ebx
    7d60:	73 20                	jae    7d82 <loader+0x6d>
        read_seg(phdr->p_paddr, phdr->p_memsz, phdr->p_offset); // paddr该段的物理地址 memsz该段占用的字节 offset该段在文件中的偏移
    7d62:	8b 43 04             	mov    0x4(%ebx),%eax
    7d65:	89 44 24 08          	mov    %eax,0x8(%esp)
    7d69:	8b 43 14             	mov    0x14(%ebx),%eax
    7d6c:	89 44 24 04          	mov    %eax,0x4(%esp)
    7d70:	8b 43 0c             	mov    0xc(%ebx),%eax
    7d73:	89 04 24             	mov    %eax,(%esp)
    7d76:	e8 58 ff ff ff       	call   7cd3 <read_seg>
    for (; phdr < ephdr; phdr++) // 遍历Table中每一项
    7d7b:	83 c3 20             	add    $0x20,%ebx
    7d7e:	39 de                	cmp    %ebx,%esi
    7d80:	77 e0                	ja     7d62 <loader+0x4d>
    ((void (*)(void))(ELF_HEADER_TMP->e_entry))(); // 将e_entry作为函数指针跳入
    7d82:	ff 15 18 00 01 00    	call   *0x10018
}
    7d88:	83 c4 10             	add    $0x10,%esp
    7d8b:	5b                   	pop    %ebx
    7d8c:	5e                   	pop    %esi
    7d8d:	5d                   	pop    %ebp
    7d8e:	c3                   	ret    
