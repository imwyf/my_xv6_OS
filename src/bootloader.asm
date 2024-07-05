
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
    7c45:	e8 d9 00 00 00       	call   7d23 <loader>

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

static inline uint8_t
inb(int port)
{
    uint8_t data;
    asm volatile("inb %w1,%0"
    7c6a:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7c6f:	ec                   	in     (%dx),%al
/**
 * 读取0x1F7端口来判断硬盘是否可读
 */
void waitdisk(void)
{
    while ((inb(0x1F7) & 0xC0) != 0x40)
    7c70:	83 e0 c0             	and    $0xffffffc0,%eax
    7c73:	3c 40                	cmp    $0x40,%al
    7c75:	75 f8                	jne    7c6f <waitdisk+0x5>
        ;
}
    7c77:	c3                   	ret    

00007c78 <read_sect>:

/**
 * PIO模式：从硬盘第sect_no扇区开始读取下一个扇区至内存的dst
 */
void read_sect(void* dst, uint32_t sect_no)
{
    7c78:	55                   	push   %ebp
    7c79:	89 e5                	mov    %esp,%ebp
    7c7b:	57                   	push   %edi
    7c7c:	53                   	push   %ebx
    7c7d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
    waitdisk();
    7c80:	e8 e5 ff ff ff       	call   7c6a <waitdisk>
 * outb(port,data): 向port写入1字节数据data
 */
static inline void
outb(int port, uint8_t data)
{
    asm volatile("outb %0,%w1"
    7c85:	b8 01 00 00 00       	mov    $0x1,%eax
    7c8a:	ba f2 01 00 00       	mov    $0x1f2,%edx
    7c8f:	ee                   	out    %al,(%dx)
    7c90:	ba f3 01 00 00       	mov    $0x1f3,%edx
    7c95:	89 d8                	mov    %ebx,%eax
    7c97:	ee                   	out    %al,(%dx)

    outb(0x1F2, 1); // 读一个扇区
    outb(0x1F3, sect_no);
    outb(0x1F4, sect_no >> 8);
    7c98:	89 d8                	mov    %ebx,%eax
    7c9a:	c1 e8 08             	shr    $0x8,%eax
    7c9d:	ba f4 01 00 00       	mov    $0x1f4,%edx
    7ca2:	ee                   	out    %al,(%dx)
    outb(0x1F5, sect_no >> 16);
    7ca3:	89 d8                	mov    %ebx,%eax
    7ca5:	c1 e8 10             	shr    $0x10,%eax
    7ca8:	ba f5 01 00 00       	mov    $0x1f5,%edx
    7cad:	ee                   	out    %al,(%dx)
    outb(0x1F6, (sect_no >> 24) | 0xE0);
    7cae:	89 d8                	mov    %ebx,%eax
    7cb0:	c1 e8 18             	shr    $0x18,%eax
    7cb3:	83 c8 e0             	or     $0xffffffe0,%eax
    7cb6:	ba f6 01 00 00       	mov    $0x1f6,%edx
    7cbb:	ee                   	out    %al,(%dx)
    7cbc:	b8 20 00 00 00       	mov    $0x20,%eax
    7cc1:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7cc6:	ee                   	out    %al,(%dx)
    outb(0x1F7, 0x20); // 0x20 代表读扇区

    waitdisk();
    7cc7:	e8 9e ff ff ff       	call   7c6a <waitdisk>
    asm volatile("cld\n\trepne\n\tinsl"
    7ccc:	8b 7d 08             	mov    0x8(%ebp),%edi
    7ccf:	b9 80 00 00 00       	mov    $0x80,%ecx
    7cd4:	ba f0 01 00 00       	mov    $0x1f0,%edx
    7cd9:	fc                   	cld    
    7cda:	f2 6d                	repnz insl (%dx),%es:(%edi)

    insl(0x1F0, dst, SECT_SIZE / 4); // 读到dst处
}
    7cdc:	5b                   	pop    %ebx
    7cdd:	5f                   	pop    %edi
    7cde:	5d                   	pop    %ebp
    7cdf:	c3                   	ret    

00007ce0 <read_seg>:
{
    7ce0:	55                   	push   %ebp
    7ce1:	89 e5                	mov    %esp,%ebp
    7ce3:	57                   	push   %edi
    7ce4:	56                   	push   %esi
    7ce5:	53                   	push   %ebx
    7ce6:	83 ec 0c             	sub    $0xc,%esp
    7ce9:	8b 5d 08             	mov    0x8(%ebp),%ebx
    uint32_t end = dst + size;
    7cec:	89 df                	mov    %ebx,%edi
    7cee:	03 7d 0c             	add    0xc(%ebp),%edi
    dst &= ~(SECT_SIZE - 1);
    7cf1:	81 e3 00 fe ff ff    	and    $0xfffffe00,%ebx
    uint32_t sect_no = (offset / SECT_SIZE) + 1; // 根据offset向下舍入到扇区边界，最后得到的sect_no是offset所处的扇区的序号
    7cf7:	8b 75 10             	mov    0x10(%ebp),%esi
    7cfa:	c1 ee 09             	shr    $0x9,%esi
    7cfd:	83 c6 01             	add    $0x1,%esi
    while (dst < end) {
    7d00:	39 df                	cmp    %ebx,%edi
    7d02:	76 17                	jbe    7d1b <read_seg+0x3b>
        read_sect((uint8_t*)dst, sect_no);
    7d04:	83 ec 08             	sub    $0x8,%esp
    7d07:	56                   	push   %esi
    7d08:	53                   	push   %ebx
    7d09:	e8 6a ff ff ff       	call   7c78 <read_sect>
        dst += SECT_SIZE;
    7d0e:	81 c3 00 02 00 00    	add    $0x200,%ebx
    while (dst < end) {
    7d14:	83 c4 10             	add    $0x10,%esp
    7d17:	39 df                	cmp    %ebx,%edi
    7d19:	77 e9                	ja     7d04 <read_seg+0x24>
}
    7d1b:	8d 65 f4             	lea    -0xc(%ebp),%esp
    7d1e:	5b                   	pop    %ebx
    7d1f:	5e                   	pop    %esi
    7d20:	5f                   	pop    %edi
    7d21:	5d                   	pop    %ebp
    7d22:	c3                   	ret    

00007d23 <loader>:
{
    7d23:	55                   	push   %ebp
    7d24:	89 e5                	mov    %esp,%ebp
    7d26:	56                   	push   %esi
    7d27:	53                   	push   %ebx
    read_seg((uint32_t)ELF_HEADER_TMP, PAGE_SIZE, 0); // 先读入一页来找到ELF头
    7d28:	83 ec 04             	sub    $0x4,%esp
    7d2b:	6a 00                	push   $0x0
    7d2d:	68 00 10 00 00       	push   $0x1000
    7d32:	68 00 00 01 00       	push   $0x10000
    7d37:	e8 a4 ff ff ff       	call   7ce0 <read_seg>
    if (ELF_HEADER_TMP->e_ident[0] != 0x7f || ELF_HEADER_TMP->e_ident[1] != 'E' || ELF_HEADER_TMP->e_ident[2] != 'L' || ELF_HEADER_TMP->e_ident[3] != 'F') {
    7d3c:	83 c4 10             	add    $0x10,%esp
    7d3f:	81 3d 00 00 01 00 7f 	cmpl   $0x464c457f,0x10000
    7d46:	45 4c 46 
    7d49:	74 01                	je     7d4c <loader+0x29>
    asm volatile("hlt");
    7d4b:	f4                   	hlt    
    Elf32_Phdr* phdr = (Elf32_Phdr*)((uint8_t*)ELF_HEADER_TMP + ELF_HEADER_TMP->e_phoff); // 通过ELF头找到 Program Header Table
    7d4c:	a1 1c 00 01 00       	mov    0x1001c,%eax
    7d51:	8d 98 00 00 01 00    	lea    0x10000(%eax),%ebx
    Elf32_Phdr* ephdr = phdr + ELF_HEADER_TMP->e_phnum; // Program Header Table 尾指针
    7d57:	0f b7 35 2c 00 01 00 	movzwl 0x1002c,%esi
    7d5e:	c1 e6 05             	shl    $0x5,%esi
    7d61:	01 de                	add    %ebx,%esi
    for (; phdr < ephdr; phdr++) // 遍历Table中每一项
    7d63:	39 f3                	cmp    %esi,%ebx
    7d65:	73 1b                	jae    7d82 <loader+0x5f>
        read_seg(phdr->p_paddr, phdr->p_memsz, phdr->p_offset); // paddr该段的物理地址 memsz该段占用的字节 offset该段在文件中的偏移
    7d67:	83 ec 04             	sub    $0x4,%esp
    7d6a:	ff 73 04             	push   0x4(%ebx)
    7d6d:	ff 73 14             	push   0x14(%ebx)
    7d70:	ff 73 0c             	push   0xc(%ebx)
    7d73:	e8 68 ff ff ff       	call   7ce0 <read_seg>
    for (; phdr < ephdr; phdr++) // 遍历Table中每一项
    7d78:	83 c3 20             	add    $0x20,%ebx
    7d7b:	83 c4 10             	add    $0x10,%esp
    7d7e:	39 de                	cmp    %ebx,%esi
    7d80:	77 e5                	ja     7d67 <loader+0x44>
    ((void (*)(void))(ELF_HEADER_TMP->e_entry))(); // 将e_entry作为函数指针跳入
    7d82:	ff 15 18 00 01 00    	call   *0x10018
}
    7d88:	8d 65 f8             	lea    -0x8(%ebp),%esp
    7d8b:	5b                   	pop    %ebx
    7d8c:	5e                   	pop    %esi
    7d8d:	5d                   	pop    %ebp
    7d8e:	c3                   	ret    
