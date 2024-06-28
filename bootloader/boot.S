.set CODE_SEG_SELECTOR, 0x8      # 段选择子，表示选择GDT中的第1个段描述符即代码段描述符
.set DATA_SEG_SELECTOR, 0x10     # 段选择子，表示选择GDT中的第2个段描述符即数据段描述符
.set CR0_PE_ON,         0x1      # 控制寄存器CR0，开启保护功能的trigger，将其置为1表示开启分页

# 解释：CODE_SEG_SELECTOR = 0x8，如下
# 　　　　　　　　INDEX　　　　　　　　TI     CPL
#　　　　    0000 0000 0000 1      00      0
# 代表选择了GDT中的第1个段描述符，特权级0级（最高），选择GDT全局段

# -------------------------------------- boot代码段（必须放在第一个扇区）-------------------------------------------------

.text
.globl _start
_start:                                     # 相当于c语言中的main函数，是汇编程序的入口
  .code16                                   # 指示以下代码是在实模式下执行
  cli                                       # 关中断，因为后面对段寄存器的操作需要关中断
  cld                                       # 将标志寄存器中的方向标志位DF设置为0，使得字符串操作指令（movs）将按照从低地址到高地址的方向执行

  xorw    %ax,%ax                           # 使用xorw指令清零ax，效果相当于movw $0, %ax

# 下面三条指令负责清零ds, es, ss寄存器（段寄存器）
  movw    %ax,%ds             
  movw    %ax,%es             
  movw    %ax,%ss             

# 打开A20地址位：A20地址位由键盘控制器芯片8042控制，8042有两个IO端口：0x60和0x64 
seta20_1:
  inb     $0x64,%al                         # 读出0x64端口得到8042的状态寄存器
  testb   $0x2,%al                          # 看看第2bit，若为0代表键盘输入缓冲区为空，可以写入
  jnz     seta20_1                          # 否则继续等待

  movb    $0xd1,%al                         # 发送0xd1命令到0x64端口
  outb    %al,$0x64

seta20_2:
  inb     $0x64,%al                         # 同0x64端口一样的流程
  testb   $0x2,%al
  jnz     seta20_2

  movb    $0xdf,%al                         # 发送0xdf到0x60端口
  outb    %al,$0x60

# 至此，A20地址位已经打开

# 通过gdtr载入一个GDT，并启用保护模式
  lgdt    gdtr                              # 载入gdt
  movl    %cr0, %eax
  orl     $CR0_PE_ON, %eax
  movl    %eax, %cr0                        # 按下trigger，打开保护模式
  ljmp    $CODE_SEG_SELECTOR, $boot32       # 跳转到boot32处执行（cs=CODE_SEG_SELECTOR，ip=boot32）

  .code32                                   # 指示以下代码是在保护模式下执行
boot32:
# 应保护模式的要求，下面的指令将设置32位保护模式下的段选择子以提供基于GDT的地址翻译
  movw    $DATA_SEG_SELECTOR, %ax 
  movw    %ax, %ds                
  movw    %ax, %es                
  movw    %ax, %fs                
  movw    %ax, %gs                
  movw    %ax, %ss                
  
# 将栈顶设定在start处，也就是地址0x7c00处，call指令将返回地址入栈，将控制权交给loader：其负责载入内核并启动
  movl    $_start, %esp
  call    loader

# 显然若是启动正常，call之后不应该返回，若返回则说明loader没有正常启动，于是跳转到boot_fail_loop处无限循环
boot_fail_loop:
  jmp     boot_fail_loop

# 添加启动区最后的签名 magic number
.org 510  
  .word 0xAA55

# --------------------------------------------- boot代码结束 -------------------------------------------------

# 以下这些定义的数据可以将其存储在代码段中，不用.data也行
# 定义GDT
.p2align 2                                  # 对齐：2字节一个word
gdt:                                        # 每1项就是一个8字节段描述符结构，至少1个项
	.word 0,0                                 # 按约定GDT第一项为空，基地址是0x0000
	.byte 0,0,0,0

	.word 0xffff,0                            # 代码段描述符，基地址也是0x0000
	.byte 0,0x9a,0xcf,0
  
	.word 0xffff,0                            # 数据段描述符，基地址是0x0000
	.byte 0,0x92,0xcf,0

gdtr:                                       # gdtr寄存器会载入这个地址的结构，共6个字节
  .word   0x17                              # 0x17 = 24，代表gdt表的大小为24（3*8）字节
  .long   gdt                               # gdt表的地址，大小2个word


# 注1：初始代码段的基地址为啥会设为0？
# 答：保护模式下，地址线变成了 32 根，这意味着只需要偏移量就能寻址整个 4GB 内存空间
# 因此参照linux的设计，我们基本放弃使用分段机制，将段基址设为0，此时即线性地址 = 段基址（0） + 偏移量（逻辑地址），
# 这样，线性地址为0x7c00的代码段起始地址（start标记处），其基地址为0x0000，而偏移量（逻辑地址）为0x7c00

# 注2：我们知道代码段中的地址其实是相对于start的偏移地址
# 因此，若想让代码段中的地址指向正确（如boot32标志），则需要将start设置为0x7c00，然后将代码段基地址设为0x0000， 这样，代码段中的地址 = 0x7c00 + 偏移量
# intel风格的代码中通过 org 0x7c00 实现，而 AT&T 风格的代码通过链接器选项 -Ttext 0x7c00 实现