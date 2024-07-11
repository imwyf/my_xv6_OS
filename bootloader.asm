
bootloader.out:     file format elf32-i386


Disassembly of section .text:

00007c00 <_start>:
.text
.globl _start
_start:                                     # 相当于c语言中的main函数，是汇编程序的入口
  .code16                                   # 指示以下代码是在实模式下执行
# 利用13中断读取loader至7e00
	mov $0x7e00, %bx
    7c00:	bb 00 7e b4 02       	mov    $0x2b47e00,%ebx
	mov $0x2, %ah
	mov $0x2, %cx
    7c05:	b9 02 00 b0 01       	mov    $0x1b00002,%ecx
	mov $1, %al
	mov $0x0080, %dx
    7c0a:	ba 80 00 cd 13       	mov    $0x13cd0080,%edx
	int $0x13

  cli                                       # 关中断，因为后面对段寄存器的操作需要关中断
    7c0f:	fa                   	cli    
  cld                                       # 将标志寄存器中的方向标志位DF设置为0，使得字符串操作指令（movs）将按照从低地址到高地址的方向执行
    7c10:	fc                   	cld    

  xorw    %ax,%ax                           # 使用xorw指令清零ax，效果相当于movw $0, %ax
    7c11:	31 c0                	xor    %eax,%eax

# 下面三条指令负责清零ds, es, ss寄存器（段寄存器）
  movw    %ax,%ds             
    7c13:	8e d8                	mov    %eax,%ds
  movw    %ax,%es             
    7c15:	8e c0                	mov    %eax,%es
  movw    %ax,%ss             
    7c17:	8e d0                	mov    %eax,%ss

00007c19 <seta20_1>:

# 打开A20地址位：A20地址位由键盘控制器芯片8042控制，8042有两个IO端口：0x60和0x64 
seta20_1:
  inb     $0x64,%al                         # 读出0x64端口得到8042的状态寄存器
    7c19:	e4 64                	in     $0x64,%al
  testb   $0x2,%al                          # 看看第2bit，若为0代表键盘输入缓冲区为空，可以写入
    7c1b:	a8 02                	test   $0x2,%al
  jnz     seta20_1                          # 否则继续等待
    7c1d:	75 fa                	jne    7c19 <seta20_1>

  movb    $0xd1,%al                         # 发送0xd1命令到0x64端口
    7c1f:	b0 d1                	mov    $0xd1,%al
  outb    %al,$0x64
    7c21:	e6 64                	out    %al,$0x64

00007c23 <seta20_2>:

seta20_2:
  inb     $0x64,%al                         # 同0x64端口一样的流程
    7c23:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7c25:	a8 02                	test   $0x2,%al
  jnz     seta20_2
    7c27:	75 fa                	jne    7c23 <seta20_2>

  movb    $0xdf,%al                         # 发送0xdf到0x60端口
    7c29:	b0 df                	mov    $0xdf,%al
  outb    %al,$0x60
    7c2b:	e6 60                	out    %al,$0x60

# 至此，A20地址位已经打开

# 通过gdtr载入一个GDT，并启用保护模式
  lgdt    gdtr                              # 载入gdt
    7c2d:	0f 01 16             	lgdtl  (%esi)
    7c30:	74 7c                	je     7cae <gdtr+0x3a>
  movl    %cr0, %eax
    7c32:	0f 20 c0             	mov    %cr0,%eax
  orl     $CR0_PE_ON, %eax
    7c35:	66 83 c8 01          	or     $0x1,%ax
  movl    %eax, %cr0                        # 按下trigger，打开保护模式
    7c39:	0f 22 c0             	mov    %eax,%cr0
  ljmp    $CODE_SEG_SELECTOR, $boot32       # 跳转到boot32处执行（cs=CODE_SEG_SELECTOR，ip=boot32）
    7c3c:	ea                   	.byte 0xea
    7c3d:	41                   	inc    %ecx
    7c3e:	7c 08                	jl     7c48 <boot32+0x7>
	...

00007c41 <boot32>:

  .code32                                   # 指示以下代码是在保护模式下执行
boot32:
# 应保护模式的要求，下面的指令将设置32位保护模式下的段选择子以提供基于GDT的地址翻译
  movw    $DATA_SEG_SELECTOR, %ax 
    7c41:	66 b8 10 00          	mov    $0x10,%ax
  movw    %ax, %ds                
    7c45:	8e d8                	mov    %eax,%ds
  movw    %ax, %es                
    7c47:	8e c0                	mov    %eax,%es
  movw    %ax, %fs                
    7c49:	8e e0                	mov    %eax,%fs
  movw    %ax, %gs                
    7c4b:	8e e8                	mov    %eax,%gs
  movw    %ax, %ss                
    7c4d:	8e d0                	mov    %eax,%ss
  
# 将栈顶设定在start处，也就是地址0x7c00处，call指令将返回地址入栈，将控制权交给loader：其负责载入内核并启动
  movl    $_start, %esp
    7c4f:	bc 00 7c 00 00       	mov    $0x7c00,%esp
  call    loader
    7c54:	e8 55 02 00 00       	call   7eae <loader>

00007c59 <boot_fail_loop>:

# 显然若是启动正常，call之后不应该返回，若返回则说明loader没有正常启动，于是跳转到boot_fail_loop处无限循环
boot_fail_loop:
  jmp     boot_fail_loop
    7c59:	eb fe                	jmp    7c59 <boot_fail_loop>
    7c5b:	90                   	nop

00007c5c <gdt>:
	...
    7c64:	ff                   	(bad)  
    7c65:	ff 00                	incl   (%eax)
    7c67:	00 00                	add    %al,(%eax)
    7c69:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
    7c70:	00                   	.byte 0x0
    7c71:	92                   	xchg   %eax,%edx
    7c72:	cf                   	iret   
	...

00007c74 <gdtr>:
    7c74:	17                   	pop    %ss
    7c75:	00 5c 7c 00          	add    %bl,0x0(%esp,%edi,2)
	...
    7dfd:	00 55 aa             	add    %dl,-0x56(%ebp)

00007e00 <waitdisk>:

/**
 * 读取0x1F7端口来判断硬盘是否可读
 */
void waitdisk(void)
{
    7e00:	55                   	push   %ebp
    7e01:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
    uint8_t data;
    asm volatile("inb %w1,%0"
    7e03:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7e08:	ec                   	in     (%dx),%al
    while ((inb(0x1F7) & 0xC0) != 0x40)
    7e09:	83 e0 c0             	and    $0xffffffc0,%eax
    7e0c:	3c 40                	cmp    $0x40,%al
    7e0e:	75 f8                	jne    7e08 <waitdisk+0x8>
        ;
}
    7e10:	5d                   	pop    %ebp
    7e11:	c3                   	ret    

00007e12 <read_sect>:

/**
 * PIO模式：从硬盘第sect_no扇区开始读取下一个扇区至内存的dst
 */
void read_sect(void* dst, uint32_t sect_no)
{
    7e12:	55                   	push   %ebp
    7e13:	89 e5                	mov    %esp,%ebp
    7e15:	57                   	push   %edi
    7e16:	53                   	push   %ebx
    7e17:	8b 5d 0c             	mov    0xc(%ebp),%ebx
    waitdisk();
    7e1a:	e8 e1 ff ff ff       	call   7e00 <waitdisk>
 * outb(port,data): 向port写入1字节数据data
 */
static inline void
outb(int port, uint8_t data)
{
    asm volatile("outb %0,%w1"
    7e1f:	ba f2 01 00 00       	mov    $0x1f2,%edx
    7e24:	b8 01 00 00 00       	mov    $0x1,%eax
    7e29:	ee                   	out    %al,(%dx)
    7e2a:	b2 f3                	mov    $0xf3,%dl
    7e2c:	89 d8                	mov    %ebx,%eax
    7e2e:	ee                   	out    %al,(%dx)
    7e2f:	0f b6 c7             	movzbl %bh,%eax
    7e32:	b2 f4                	mov    $0xf4,%dl
    7e34:	ee                   	out    %al,(%dx)

    outb(0x1F2, 1); // 读一个扇区
    outb(0x1F3, sect_no);
    outb(0x1F4, sect_no >> 8);
    outb(0x1F5, sect_no >> 16);
    7e35:	89 d8                	mov    %ebx,%eax
    7e37:	c1 e8 10             	shr    $0x10,%eax
    7e3a:	b2 f5                	mov    $0xf5,%dl
    7e3c:	ee                   	out    %al,(%dx)
    outb(0x1F6, (sect_no >> 24) | 0xE0);
    7e3d:	c1 eb 18             	shr    $0x18,%ebx
    7e40:	89 d8                	mov    %ebx,%eax
    7e42:	83 c8 e0             	or     $0xffffffe0,%eax
    7e45:	b2 f6                	mov    $0xf6,%dl
    7e47:	ee                   	out    %al,(%dx)
    7e48:	b2 f7                	mov    $0xf7,%dl
    7e4a:	b8 20 00 00 00       	mov    $0x20,%eax
    7e4f:	ee                   	out    %al,(%dx)
    outb(0x1F7, 0x20); // 0x20 代表读扇区

    waitdisk();
    7e50:	e8 ab ff ff ff       	call   7e00 <waitdisk>
    asm volatile("cld\n\trepne\n\tinsl"
    7e55:	8b 7d 08             	mov    0x8(%ebp),%edi
    7e58:	b9 80 00 00 00       	mov    $0x80,%ecx
    7e5d:	ba f0 01 00 00       	mov    $0x1f0,%edx
    7e62:	fc                   	cld    
    7e63:	f2 6d                	repnz insl (%dx),%es:(%edi)

    insl(0x1F0, dst, SECT_SIZE / 4); // 读到dst处
}
    7e65:	5b                   	pop    %ebx
    7e66:	5f                   	pop    %edi
    7e67:	5d                   	pop    %ebp
    7e68:	c3                   	ret    

00007e69 <read_seg>:
{
    7e69:	55                   	push   %ebp
    7e6a:	89 e5                	mov    %esp,%ebp
    7e6c:	57                   	push   %edi
    7e6d:	56                   	push   %esi
    7e6e:	53                   	push   %ebx
    7e6f:	83 ec 08             	sub    $0x8,%esp
    7e72:	8b 5d 08             	mov    0x8(%ebp),%ebx
    uint32_t end = dst + size;
    7e75:	89 df                	mov    %ebx,%edi
    7e77:	03 7d 0c             	add    0xc(%ebp),%edi
    dst &= ~(SECT_SIZE - 1);
    7e7a:	81 e3 00 fe ff ff    	and    $0xfffffe00,%ebx
    uint32_t sect_no = (offset / SECT_SIZE) + 2; // 根据offset向下舍入到扇区边界，最后得到的sect_no是offset所处的扇区的序号，+2因为ELF文件从第三个扇区开始
    7e80:	8b 75 10             	mov    0x10(%ebp),%esi
    7e83:	c1 ee 09             	shr    $0x9,%esi
    7e86:	83 c6 02             	add    $0x2,%esi
    while (dst < end) {
    7e89:	39 df                	cmp    %ebx,%edi
    7e8b:	76 19                	jbe    7ea6 <read_seg+0x3d>
        read_sect((uint8_t*)dst, sect_no);
    7e8d:	89 74 24 04          	mov    %esi,0x4(%esp)
    7e91:	89 1c 24             	mov    %ebx,(%esp)
    7e94:	e8 79 ff ff ff       	call   7e12 <read_sect>
        dst += SECT_SIZE;
    7e99:	81 c3 00 02 00 00    	add    $0x200,%ebx
        sect_no++;
    7e9f:	83 c6 01             	add    $0x1,%esi
    while (dst < end) {
    7ea2:	39 df                	cmp    %ebx,%edi
    7ea4:	77 e7                	ja     7e8d <read_seg+0x24>
}
    7ea6:	83 c4 08             	add    $0x8,%esp
    7ea9:	5b                   	pop    %ebx
    7eaa:	5e                   	pop    %esi
    7eab:	5f                   	pop    %edi
    7eac:	5d                   	pop    %ebp
    7ead:	c3                   	ret    

00007eae <loader>:
{
    7eae:	55                   	push   %ebp
    7eaf:	89 e5                	mov    %esp,%ebp
    7eb1:	56                   	push   %esi
    7eb2:	53                   	push   %ebx
    7eb3:	83 ec 10             	sub    $0x10,%esp
    read_seg((uint32_t)ELF_HEADER_TMP, PAGE_SIZE, 0); // 先读入一页来找到ELF头
    7eb6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
    7ebd:	00 
    7ebe:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
    7ec5:	00 
    7ec6:	c7 04 24 00 00 01 00 	movl   $0x10000,(%esp)
    7ecd:	e8 97 ff ff ff       	call   7e69 <read_seg>
    if (ELF_HEADER_TMP->e_ident[0] != 0x7f || ELF_HEADER_TMP->e_ident[1] != 'E' || ELF_HEADER_TMP->e_ident[2] != 'L' || ELF_HEADER_TMP->e_ident[3] != 'F') {
    7ed2:	81 3d 00 00 01 00 7f 	cmpl   $0x464c457f,0x10000
    7ed9:	45 4c 46 
    7edc:	75 41                	jne    7f1f <loader+0x71>
    Elf32_Phdr* phdr = (Elf32_Phdr*)((uint8_t*)ELF_HEADER_TMP + ELF_HEADER_TMP->e_phoff); // 通过ELF头找到 Program Header Table
    7ede:	a1 1c 00 01 00       	mov    0x1001c,%eax
    7ee3:	8d 98 00 00 01 00    	lea    0x10000(%eax),%ebx
    Elf32_Phdr* ephdr = phdr + ELF_HEADER_TMP->e_phnum; // Program Header Table 尾指针
    7ee9:	0f b7 35 2c 00 01 00 	movzwl 0x1002c,%esi
    7ef0:	c1 e6 05             	shl    $0x5,%esi
    7ef3:	01 de                	add    %ebx,%esi
    for (; phdr < ephdr; phdr++) // 遍历Table中每一项
    7ef5:	39 f3                	cmp    %esi,%ebx
    7ef7:	73 20                	jae    7f19 <loader+0x6b>
        read_seg(phdr->p_paddr, phdr->p_memsz, phdr->p_offset); // paddr该段的物理地址 memsz该段占用的字节 offset该段在文件中的偏移
    7ef9:	8b 43 04             	mov    0x4(%ebx),%eax
    7efc:	89 44 24 08          	mov    %eax,0x8(%esp)
    7f00:	8b 43 14             	mov    0x14(%ebx),%eax
    7f03:	89 44 24 04          	mov    %eax,0x4(%esp)
    7f07:	8b 43 0c             	mov    0xc(%ebx),%eax
    7f0a:	89 04 24             	mov    %eax,(%esp)
    7f0d:	e8 57 ff ff ff       	call   7e69 <read_seg>
    for (; phdr < ephdr; phdr++) // 遍历Table中每一项
    7f12:	83 c3 20             	add    $0x20,%ebx
    7f15:	39 de                	cmp    %ebx,%esi
    7f17:	77 e0                	ja     7ef9 <loader+0x4b>
    ((void (*)(void))(ELF_HEADER_TMP->e_entry))(); // 将e_entry作为函数指针跳入
    7f19:	ff 15 18 00 01 00    	call   *0x10018
}
    7f1f:	83 c4 10             	add    $0x10,%esp
    7f22:	5b                   	pop    %ebx
    7f23:	5e                   	pop    %esi
    7f24:	5d                   	pop    %ebp
    7f25:	c3                   	ret    
