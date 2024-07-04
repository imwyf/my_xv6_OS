
bootloader.o:     file format elf32-i386


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
    7c21:	e8 7f 0f 20 c0       	call   c0208ba5 <_end+0xc0200bb5>
  movl    %cr0, %eax
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
    7c45:	e8 6f 02 00 00       	call   7eb9 <loader>

00007c4a <boot_fail_loop>:

# 显然若是启动正常，call之后不应该返回，若返回则说明loader没有正常启动，于是跳转到boot_fail_loop处无限循环
boot_fail_loop:
  jmp     boot_fail_loop
    7c4a:	eb fe                	jmp    7c4a <boot_fail_loop>
	...
    7dfc:	00 00                	add    %al,(%eax)
    7dfe:	55                   	push   %ebp
    7dff:	aa                   	stos   %al,%es:(%edi)

00007e00 <waitdisk>:

static inline uint8_t
inb(int port)
{
    uint8_t data;
    asm volatile("inb %w1,%0"
    7e00:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7e05:	ec                   	in     (%dx),%al
/**
 * 读取0x1F7端口来判断硬盘是否可读
 */
void waitdisk(void)
{
    while ((inb(0x1F7) & 0xC0) != 0x40)
    7e06:	83 e0 c0             	and    $0xffffffc0,%eax
    7e09:	3c 40                	cmp    $0x40,%al
    7e0b:	75 f8                	jne    7e05 <waitdisk+0x5>
        ;
}
    7e0d:	c3                   	ret    

00007e0e <read_sect>:

/**
 * PIO模式：从硬盘第sect_no扇区开始读取下一个扇区至内存的dst
 */
void read_sect(void* dst, uint32_t sect_no)
{
    7e0e:	55                   	push   %ebp
    7e0f:	89 e5                	mov    %esp,%ebp
    7e11:	57                   	push   %edi
    7e12:	53                   	push   %ebx
    7e13:	8b 5d 0c             	mov    0xc(%ebp),%ebx
    waitdisk();
    7e16:	e8 e5 ff ff ff       	call   7e00 <waitdisk>
 * outb(port,data): 向port写入1字节数据data
 */
static inline void
outb(int port, uint8_t data)
{
    asm volatile("outb %0,%w1"
    7e1b:	b8 01 00 00 00       	mov    $0x1,%eax
    7e20:	ba f2 01 00 00       	mov    $0x1f2,%edx
    7e25:	ee                   	out    %al,(%dx)
    7e26:	ba f3 01 00 00       	mov    $0x1f3,%edx
    7e2b:	89 d8                	mov    %ebx,%eax
    7e2d:	ee                   	out    %al,(%dx)

    outb(0x1F2, 1); // 读一个扇区
    outb(0x1F3, sect_no);
    outb(0x1F4, sect_no >> 8);
    7e2e:	89 d8                	mov    %ebx,%eax
    7e30:	c1 e8 08             	shr    $0x8,%eax
    7e33:	ba f4 01 00 00       	mov    $0x1f4,%edx
    7e38:	ee                   	out    %al,(%dx)
    outb(0x1F5, sect_no >> 16);
    7e39:	89 d8                	mov    %ebx,%eax
    7e3b:	c1 e8 10             	shr    $0x10,%eax
    7e3e:	ba f5 01 00 00       	mov    $0x1f5,%edx
    7e43:	ee                   	out    %al,(%dx)
    outb(0x1F6, (sect_no >> 24) | 0xE0);
    7e44:	89 d8                	mov    %ebx,%eax
    7e46:	c1 e8 18             	shr    $0x18,%eax
    7e49:	83 c8 e0             	or     $0xffffffe0,%eax
    7e4c:	ba f6 01 00 00       	mov    $0x1f6,%edx
    7e51:	ee                   	out    %al,(%dx)
    7e52:	b8 20 00 00 00       	mov    $0x20,%eax
    7e57:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7e5c:	ee                   	out    %al,(%dx)
    outb(0x1F7, 0x20); // 0x20 代表读扇区

    waitdisk();
    7e5d:	e8 9e ff ff ff       	call   7e00 <waitdisk>
    asm volatile("cld\n\trepne\n\tinsl"
    7e62:	8b 7d 08             	mov    0x8(%ebp),%edi
    7e65:	b9 80 00 00 00       	mov    $0x80,%ecx
    7e6a:	ba f0 01 00 00       	mov    $0x1f0,%edx
    7e6f:	fc                   	cld    
    7e70:	f2 6d                	repnz insl (%dx),%es:(%edi)

    insl(0x1F0, dst, SECT_SIZE / 4); // 读到dst处
}
    7e72:	5b                   	pop    %ebx
    7e73:	5f                   	pop    %edi
    7e74:	5d                   	pop    %ebp
    7e75:	c3                   	ret    

00007e76 <read_seg>:
{
    7e76:	55                   	push   %ebp
    7e77:	89 e5                	mov    %esp,%ebp
    7e79:	57                   	push   %edi
    7e7a:	56                   	push   %esi
    7e7b:	53                   	push   %ebx
    7e7c:	83 ec 0c             	sub    $0xc,%esp
    7e7f:	8b 5d 08             	mov    0x8(%ebp),%ebx
    uint32_t end = dst + size;
    7e82:	89 df                	mov    %ebx,%edi
    7e84:	03 7d 0c             	add    0xc(%ebp),%edi
    dst &= ~(SECT_SIZE - 1);
    7e87:	81 e3 00 fe ff ff    	and    $0xfffffe00,%ebx
    uint32_t sect_no = (offset / SECT_SIZE) + 2; // 根据offset向下舍入到扇区边界，最后得到的sect_no是offset所处的扇区的序号
    7e8d:	8b 75 10             	mov    0x10(%ebp),%esi
    7e90:	c1 ee 09             	shr    $0x9,%esi
    7e93:	83 c6 02             	add    $0x2,%esi
    while (dst < end) {
    7e96:	39 df                	cmp    %ebx,%edi
    7e98:	76 17                	jbe    7eb1 <read_seg+0x3b>
        read_sect((uint8_t*)dst, sect_no);
    7e9a:	83 ec 08             	sub    $0x8,%esp
    7e9d:	56                   	push   %esi
    7e9e:	53                   	push   %ebx
    7e9f:	e8 6a ff ff ff       	call   7e0e <read_sect>
        dst += SECT_SIZE;
    7ea4:	81 c3 00 02 00 00    	add    $0x200,%ebx
    while (dst < end) {
    7eaa:	83 c4 10             	add    $0x10,%esp
    7ead:	39 df                	cmp    %ebx,%edi
    7eaf:	77 e9                	ja     7e9a <read_seg+0x24>
}
    7eb1:	8d 65 f4             	lea    -0xc(%ebp),%esp
    7eb4:	5b                   	pop    %ebx
    7eb5:	5e                   	pop    %esi
    7eb6:	5f                   	pop    %edi
    7eb7:	5d                   	pop    %ebp
    7eb8:	c3                   	ret    

00007eb9 <loader>:
{
    7eb9:	55                   	push   %ebp
    7eba:	89 e5                	mov    %esp,%ebp
    7ebc:	56                   	push   %esi
    7ebd:	53                   	push   %ebx
    read_seg((uint32_t)ELF_HEADER_TMP, PAGE_SIZE, 0); // 先读入一页来找到ELF头
    7ebe:	83 ec 04             	sub    $0x4,%esp
    7ec1:	6a 00                	push   $0x0
    7ec3:	68 00 10 00 00       	push   $0x1000
    7ec8:	68 00 00 01 00       	push   $0x10000
    7ecd:	e8 a4 ff ff ff       	call   7e76 <read_seg>
    if (ELF_HEADER_TMP->e_ident[0] != 0x7f || ELF_HEADER_TMP->e_ident[1] != 'E' || ELF_HEADER_TMP->e_ident[2] != 'L' || ELF_HEADER_TMP->e_ident[3] != 'F') {
    7ed2:	83 c4 10             	add    $0x10,%esp
    7ed5:	81 3d 00 00 01 00 7f 	cmpl   $0x464c457f,0x10000
    7edc:	45 4c 46 
    7edf:	74 02                	je     7ee3 <loader+0x2a>
        while (1)
    7ee1:	eb fe                	jmp    7ee1 <loader+0x28>
    Elf_Phdr* phdr = (Elf_Phdr*)((uint8_t*)ELF_HEADER_TMP + ELF_HEADER_TMP->e_phoff); // 通过ELF头找到 Program Header Table
    7ee3:	a1 1c 00 01 00       	mov    0x1001c,%eax
    7ee8:	8d 98 00 00 01 00    	lea    0x10000(%eax),%ebx
    Elf_Phdr* ephdr = phdr + ELF_HEADER_TMP->e_phnum; // Program Header Table 尾指针
    7eee:	0f b7 35 2c 00 01 00 	movzwl 0x1002c,%esi
    7ef5:	c1 e6 05             	shl    $0x5,%esi
    7ef8:	01 de                	add    %ebx,%esi
    for (; phdr < ephdr; phdr++) // 遍历Table中每一项
    7efa:	39 f3                	cmp    %esi,%ebx
    7efc:	73 1b                	jae    7f19 <loader+0x60>
        read_seg(phdr->p_paddr, phdr->p_memsz, phdr->p_offset); // paddr该段的物理地址 memsz该段占用的字节 offset该段在文件中的偏移
    7efe:	83 ec 04             	sub    $0x4,%esp
    7f01:	ff 73 04             	push   0x4(%ebx)
    7f04:	ff 73 14             	push   0x14(%ebx)
    7f07:	ff 73 0c             	push   0xc(%ebx)
    7f0a:	e8 67 ff ff ff       	call   7e76 <read_seg>
    for (; phdr < ephdr; phdr++) // 遍历Table中每一项
    7f0f:	83 c3 20             	add    $0x20,%ebx
    7f12:	83 c4 10             	add    $0x10,%esp
    7f15:	39 de                	cmp    %ebx,%esi
    7f17:	77 e5                	ja     7efe <loader+0x45>
    ((void (*)(void))(ELF_HEADER_TMP->e_entry))(); // 将e_entry作为函数指针跳入
    7f19:	ff 15 18 00 01 00    	call   *0x10018
}
    7f1f:	8d 65 f8             	lea    -0x8(%ebp),%esp
    7f22:	5b                   	pop    %ebx
    7f23:	5e                   	pop    %esi
    7f24:	5d                   	pop    %ebp
    7f25:	c3                   	ret    