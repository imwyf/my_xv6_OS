
./obj/kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <kernel_entry>:
# 我们还没有开启分页，而内核代码实际被存放在物理地址 0x00100000 处，因此手动将虚拟地址转换为其对应的物理地址：即 0x80100000 -> 0x00100000

.globl kernel_entry
kernel_entry:
# 固定页表大小 
  movl    %cr4, %eax
80100000:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax                  # 4MB/页
80100003:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100006:	0f 22 e0             	mov    %eax,%cr4
  # 将 entry_pgdir 的物理地址载入 cr3 寄存器并开启分页
  movl    $(K_V2P_WO(entry_pgdir)), %eax
80100009:	b8 00 20 10 00       	mov    $0x102000,%eax
  movl    %eax, %cr3
8010000e:	0f 22 d8             	mov    %eax,%cr3
  movl    %cr0, %eax
80100011:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100014:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100019:	0f 22 c0             	mov    %eax,%cr0

# entrypgdir 直接将虚拟地址前4Mb映射到物理地址前4Mb

# 现在的栈是bootloader设置的不处在内核中，因此把栈设为内核栈
  movl $(stack + K_STACKSIZE), %esp
8010001c:	bc b0 59 10 80       	mov    $0x801059b0,%esp

# 不能用 call，其使用的是相对寻址，所以 eip 仍然会在低地址处偏移来寻址，而此时 eip 指向的是低的虚拟地址，因此通过 jmp 重置 eip 以指向高地址处
  mov $main, %eax
80100021:	b8 28 00 10 80       	mov    $0x80100028,%eax
  jmp *%eax
80100026:	ff e0                	jmp    *%eax

80100028 <main>:
      };

void use_lock();

int main()
{
80100028:	8d 4c 24 04          	lea    0x4(%esp),%ecx
8010002c:	83 e4 f0             	and    $0xfffffff0,%esp
8010002f:	ff 71 fc             	push   -0x4(%ecx)
80100032:	55                   	push   %ebp
80100033:	89 e5                	mov    %esp,%ebp
80100035:	51                   	push   %ecx
80100036:	83 ec 04             	sub    $0x4,%esp
    cons_init();
80100039:	e8 88 16 00 00       	call   801016c6 <cons_init>
    cprintf("\n");
8010003e:	83 ec 0c             	sub    $0xc,%esp
80100041:	68 be 18 10 80       	push   $0x801018be
80100046:	e8 16 14 00 00       	call   80101461 <cprintf>
    cprintf("------> Hello, OS World!\n");
8010004b:	c7 04 24 00 18 10 80 	movl   $0x80101800,(%esp)
80100052:	e8 0a 14 00 00       	call   80101461 <cprintf>
    kmem_init(); // 内存管理初始化
80100057:	e8 a6 03 00 00       	call   80100402 <kmem_init>
    cprintf("------> kmem_init() finish!\n");
8010005c:	c7 04 24 1a 18 10 80 	movl   $0x8010181a,(%esp)
80100063:	e8 f9 13 00 00       	call   80101461 <cprintf>
    conf_mcpu();
80100068:	e8 db 07 00 00       	call   80100848 <conf_mcpu>
    cprintf("------> conf_mcpu() finish!\n");
8010006d:	c7 04 24 37 18 10 80 	movl   $0x80101837,(%esp)
80100074:	e8 e8 13 00 00       	call   80101461 <cprintf>
    conf_gdt();
80100079:	e8 21 04 00 00       	call   8010049f <conf_gdt>
    cprintf("------> conf_gdt() finish!\n");
8010007e:	c7 04 24 54 18 10 80 	movl   $0x80101854,(%esp)
80100085:	e8 d7 13 00 00       	call   80101461 <cprintf>
    interrupt_init();
8010008a:	e8 18 0a 00 00       	call   80100aa7 <interrupt_init>
    cprintf("------> interrupt_init() finish!\n");
8010008f:	c7 04 24 90 18 10 80 	movl   $0x80101890,(%esp)
80100096:	e8 c6 13 00 00       	call   80101461 <cprintf>
    proc_init();
8010009b:	e8 21 0e 00 00       	call   80100ec1 <proc_init>
    cprintf("------> proc_init() finish!\n");
801000a0:	c7 04 24 70 18 10 80 	movl   $0x80101870,(%esp)
801000a7:	e8 b5 13 00 00       	call   80101461 <cprintf>
#include "types.h"

static inline void
hlt(void)
{
    asm volatile("hlt");
801000ac:	f4                   	hlt    
    hlt();
}
801000ad:	b8 00 00 00 00       	mov    $0x0,%eax
801000b2:	8b 4d fc             	mov    -0x4(%ebp),%ecx
801000b5:	c9                   	leave  
801000b6:	8d 61 fc             	lea    -0x4(%ecx),%esp
801000b9:	c3                   	ret    

801000ba <use_lock>:

void use_lock()
{
801000ba:	55                   	push   %ebp
801000bb:	89 e5                	mov    %esp,%ebp
801000bd:	83 ec 08             	sub    $0x8,%esp
    cons_uselock();
801000c0:	e8 6a 13 00 00       	call   8010142f <cons_uselock>
    kmem_uselock();
801000c5:	e8 02 00 00 00       	call   801000cc <kmem_uselock>
}
801000ca:	c9                   	leave  
801000cb:	c3                   	ret    

801000cc <kmem_uselock>:
    switch_pgdir(NULL); // NULL 代表切换为内核页表
}

void kmem_uselock()
{
    kmem.use_lock = 1;
801000cc:	c7 05 34 33 10 80 01 	movl   $0x1,0x80103334
801000d3:	00 00 00 
}
801000d6:	c3                   	ret    

801000d7 <kmem_free>:

/**
 *  释放虚拟地址v指向的内存
 */
void kmem_free(char* vaddr)
{
801000d7:	55                   	push   %ebp
801000d8:	89 e5                	mov    %esp,%ebp
801000da:	53                   	push   %ebx
801000db:	83 ec 04             	sub    $0x4,%esp
801000de:	8b 5d 08             	mov    0x8(%ebp),%ebx
    if ((vaddr_t)vaddr % PGSIZE || vaddr < end || K_V2P(vaddr) >= P_ADDR_PHYSTOP)
801000e1:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
801000e7:	75 15                	jne    801000fe <kmem_free+0x27>
801000e9:	81 fb b0 59 10 80    	cmp    $0x801059b0,%ebx
801000ef:	72 0d                	jb     801000fe <kmem_free+0x27>
801000f1:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801000f7:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
801000fc:	76 10                	jbe    8010010e <kmem_free+0x37>
        cprintf("kfree error \n");
801000fe:	83 ec 0c             	sub    $0xc,%esp
80100101:	68 b2 18 10 80       	push   $0x801018b2
80100106:	e8 56 13 00 00       	call   80101461 <cprintf>
8010010b:	83 c4 10             	add    $0x10,%esp

    memset(vaddr, 1, PGSIZE); // 清空该页内存
8010010e:	83 ec 04             	sub    $0x4,%esp
80100111:	68 00 10 00 00       	push   $0x1000
80100116:	6a 01                	push   $0x1
80100118:	53                   	push   %ebx
80100119:	e8 4c 0e 00 00       	call   80100f6a <memset>

    if (kmem.use_lock)
8010011e:	83 c4 10             	add    $0x10,%esp
80100121:	83 3d 34 33 10 80 00 	cmpl   $0x0,0x80103334
80100128:	75 1b                	jne    80100145 <kmem_free+0x6e>
        acquire(&kmem.lock);
    struct list_node* node = (struct list_node*)vaddr;
    node->next = kmem.freelist;
8010012a:	a1 38 33 10 80       	mov    0x80103338,%eax
8010012f:	89 03                	mov    %eax,(%ebx)
    kmem.freelist = node;
80100131:	89 1d 38 33 10 80    	mov    %ebx,0x80103338
    if (kmem.use_lock)
80100137:	83 3d 34 33 10 80 00 	cmpl   $0x0,0x80103334
8010013e:	75 17                	jne    80100157 <kmem_free+0x80>
        release(&kmem.lock);
}
80100140:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100143:	c9                   	leave  
80100144:	c3                   	ret    
        acquire(&kmem.lock);
80100145:	83 ec 0c             	sub    $0xc,%esp
80100148:	68 00 33 10 80       	push   $0x80103300
8010014d:	e8 76 05 00 00       	call   801006c8 <acquire>
80100152:	83 c4 10             	add    $0x10,%esp
80100155:	eb d3                	jmp    8010012a <kmem_free+0x53>
        release(&kmem.lock);
80100157:	83 ec 0c             	sub    $0xc,%esp
8010015a:	68 00 33 10 80       	push   $0x80103300
8010015f:	e8 be 05 00 00       	call   80100722 <release>
80100164:	83 c4 10             	add    $0x10,%esp
}
80100167:	eb d7                	jmp    80100140 <kmem_free+0x69>

80100169 <kmem_free_pages>:
{
80100169:	55                   	push   %ebp
8010016a:	89 e5                	mov    %esp,%ebp
8010016c:	56                   	push   %esi
8010016d:	53                   	push   %ebx
8010016e:	8b 75 0c             	mov    0xc(%ebp),%esi
    p = (char*)PGROUNDUP((vaddr_t)start);
80100171:	8b 45 08             	mov    0x8(%ebp),%eax
80100174:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
8010017a:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
    for (; p + PGSIZE <= (char*)end; p += PGSIZE) {
80100180:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80100186:	39 de                	cmp    %ebx,%esi
80100188:	72 1c                	jb     801001a6 <kmem_free_pages+0x3d>
        kmem_free(p);
8010018a:	83 ec 0c             	sub    $0xc,%esp
8010018d:	8d 83 00 f0 ff ff    	lea    -0x1000(%ebx),%eax
80100193:	50                   	push   %eax
80100194:	e8 3e ff ff ff       	call   801000d7 <kmem_free>
    for (; p + PGSIZE <= (char*)end; p += PGSIZE) {
80100199:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010019f:	83 c4 10             	add    $0x10,%esp
801001a2:	39 de                	cmp    %ebx,%esi
801001a4:	73 e4                	jae    8010018a <kmem_free_pages+0x21>
}
801001a6:	8d 65 f8             	lea    -0x8(%ebp),%esp
801001a9:	5b                   	pop    %ebx
801001aa:	5e                   	pop    %esi
801001ab:	5d                   	pop    %ebp
801001ac:	c3                   	ret    

801001ad <kmem_alloc>:

/**
 * 分配一页内存，返回指向内存的指针，失败返回NULL
 */
char* kmem_alloc(void)
{
801001ad:	55                   	push   %ebp
801001ae:	89 e5                	mov    %esp,%ebp
801001b0:	53                   	push   %ebx
801001b1:	83 ec 04             	sub    $0x4,%esp
    struct list_node* node = NULL;

    if (kmem.use_lock)
801001b4:	83 3d 34 33 10 80 00 	cmpl   $0x0,0x80103334
801001bb:	75 21                	jne    801001de <kmem_alloc+0x31>
        acquire(&kmem.lock);
    node = kmem.freelist;
801001bd:	8b 1d 38 33 10 80    	mov    0x80103338,%ebx
    if (node)
801001c3:	85 db                	test   %ebx,%ebx
801001c5:	74 10                	je     801001d7 <kmem_alloc+0x2a>
        kmem.freelist = node->next;
801001c7:	8b 03                	mov    (%ebx),%eax
801001c9:	a3 38 33 10 80       	mov    %eax,0x80103338
    if (kmem.use_lock)
801001ce:	83 3d 34 33 10 80 00 	cmpl   $0x0,0x80103334
801001d5:	75 23                	jne    801001fa <kmem_alloc+0x4d>
        release(&kmem.lock);
    return (char*)node;
}
801001d7:	89 d8                	mov    %ebx,%eax
801001d9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801001dc:	c9                   	leave  
801001dd:	c3                   	ret    
        acquire(&kmem.lock);
801001de:	83 ec 0c             	sub    $0xc,%esp
801001e1:	68 00 33 10 80       	push   $0x80103300
801001e6:	e8 dd 04 00 00       	call   801006c8 <acquire>
    node = kmem.freelist;
801001eb:	8b 1d 38 33 10 80    	mov    0x80103338,%ebx
    if (node)
801001f1:	83 c4 10             	add    $0x10,%esp
801001f4:	85 db                	test   %ebx,%ebx
801001f6:	75 cf                	jne    801001c7 <kmem_alloc+0x1a>
801001f8:	eb d4                	jmp    801001ce <kmem_alloc+0x21>
        release(&kmem.lock);
801001fa:	83 ec 0c             	sub    $0xc,%esp
801001fd:	68 00 33 10 80       	push   $0x80103300
80100202:	e8 1b 05 00 00       	call   80100722 <release>
80100207:	83 c4 10             	add    $0x10,%esp
    return (char*)node;
8010020a:	eb cb                	jmp    801001d7 <kmem_alloc+0x2a>

8010020c <kmmap>:

/**
 * 在页表 pgdir 中进行虚拟内存到物理内存的映射：虚拟地址 vaddr -> 物理地址 paddr，映射长度为 size，权限为 perm，成功返回0，不成功返回-1
 */
static int kmmap(pde_t* pgdir, void* vaddr, uint32_t size, paddr_t paddr, int perm)
{
8010020c:	55                   	push   %ebp
8010020d:	89 e5                	mov    %esp,%ebp
8010020f:	57                   	push   %edi
80100210:	56                   	push   %esi
80100211:	53                   	push   %ebx
80100212:	83 ec 2c             	sub    $0x2c,%esp
80100215:	89 45 dc             	mov    %eax,-0x24(%ebp)
    char *va_start, *va_end;
    pte_t* pte;

    if (size == 0) {
80100218:	85 c9                	test   %ecx,%ecx
8010021a:	74 20                	je     8010023c <kmmap+0x30>
8010021c:	89 d0                	mov    %edx,%eax
        cprintf("kmmap() error: size = 0, it should be > 0\n");
        return -1;
    }

    /* 先对齐，并求出需要映射的虚拟地址范围 */
    va_start = (char*)PGROUNDDOWN((vaddr_t)vaddr);
8010021e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
80100224:	89 d7                	mov    %edx,%edi
    va_end = (char*)PGROUNDDOWN(((vaddr_t)vaddr) + size - 1);
80100226:	8d 44 08 ff          	lea    -0x1(%eax,%ecx,1),%eax
8010022a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010022f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100232:	8b 45 08             	mov    0x8(%ebp),%eax
80100235:	29 d0                	sub    %edx,%eax
80100237:	89 45 d8             	mov    %eax,-0x28(%ebp)
8010023a:	eb 5a                	jmp    80100296 <kmmap+0x8a>
        cprintf("kmmap() error: size = 0, it should be > 0\n");
8010023c:	83 ec 0c             	sub    $0xc,%esp
8010023f:	68 c8 18 10 80       	push   $0x801018c8
80100244:	e8 18 12 00 00       	call   80101461 <cprintf>
        return -1;
80100249:	83 c4 10             	add    $0x10,%esp
8010024c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100251:	e9 ba 00 00 00       	jmp    80100310 <kmmap+0x104>
    pde_t* pde; // 页目录项（一级）
    pte_t* pte; // 页表项（二级）

    pde = &pgdir[PDX(vaddr)]; // 根据 vaddr 获取对应的页目录项
    if (*pde & PTE_P) { // 页目录项存在
        pte = (pte_t*)K_P2V(PTE_ADDR(*pde)); // 取出 PPN 所对应的二级页表（即 pte 数组）的地址
80100256:	25 00 f0 ff ff       	and    $0xfffff000,%eax
            return NULL;

        memset(pte, 0, PGSIZE);
        *pde = K_V2P(pte) | perm | PTE_P; // 将二级页表的物理地址写入页目录项
    }
    return &pte[PTX(vaddr)]; // 从二级页表中取出对应的页表项
8010025b:	89 fa                	mov    %edi,%edx
8010025d:	c1 ea 0a             	shr    $0xa,%edx
80100260:	81 e2 fc 0f 00 00    	and    $0xffc,%edx
80100266:	8d 9c 10 00 00 00 80 	lea    -0x80000000(%eax,%edx,1),%ebx
        if ((pte = get_pte(pgdir, va_start, 1, perm)) == NULL) // 找到 pte
8010026d:	85 db                	test   %ebx,%ebx
8010026f:	0f 84 8f 00 00 00    	je     80100304 <kmmap+0xf8>
        if (*pte & PTE_P) {
80100275:	f6 03 01             	testb  $0x1,(%ebx)
80100278:	75 73                	jne    801002ed <kmmap+0xe1>
        *pte = paddr | perm | PTE_P; // 填写 pte
8010027a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010027d:	0b 45 0c             	or     0xc(%ebp),%eax
80100280:	83 c8 01             	or     $0x1,%eax
80100283:	89 03                	mov    %eax,(%ebx)
        if (va_start == va_end) // 映射完成
80100285:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100288:	39 c7                	cmp    %eax,%edi
8010028a:	0f 84 88 00 00 00    	je     80100318 <kmmap+0x10c>
        va_start += PGSIZE;
80100290:	81 c7 00 10 00 00    	add    $0x1000,%edi
    while (1) {
80100296:	89 7d e0             	mov    %edi,-0x20(%ebp)
80100299:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010029c:	01 f8                	add    %edi,%eax
8010029e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    pde = &pgdir[PDX(vaddr)]; // 根据 vaddr 获取对应的页目录项
801002a1:	89 f8                	mov    %edi,%eax
801002a3:	c1 e8 16             	shr    $0x16,%eax
801002a6:	8b 4d dc             	mov    -0x24(%ebp),%ecx
801002a9:	8d 34 81             	lea    (%ecx,%eax,4),%esi
    if (*pde & PTE_P) { // 页目录项存在
801002ac:	8b 06                	mov    (%esi),%eax
801002ae:	a8 01                	test   $0x1,%al
801002b0:	75 a4                	jne    80100256 <kmmap+0x4a>
        if (!need_alloc || (pte = (pte_t*)kmem_alloc()) == NULL) // 不需要分配或分配失败
801002b2:	e8 f6 fe ff ff       	call   801001ad <kmem_alloc>
801002b7:	89 c3                	mov    %eax,%ebx
801002b9:	85 c0                	test   %eax,%eax
801002bb:	74 4e                	je     8010030b <kmmap+0xff>
        memset(pte, 0, PGSIZE);
801002bd:	83 ec 04             	sub    $0x4,%esp
801002c0:	68 00 10 00 00       	push   $0x1000
801002c5:	6a 00                	push   $0x0
801002c7:	50                   	push   %eax
801002c8:	e8 9d 0c 00 00       	call   80100f6a <memset>
        *pde = K_V2P(pte) | perm | PTE_P; // 将二级页表的物理地址写入页目录项
801002cd:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801002d3:	0b 45 0c             	or     0xc(%ebp),%eax
801002d6:	83 c8 01             	or     $0x1,%eax
801002d9:	89 06                	mov    %eax,(%esi)
    return &pte[PTX(vaddr)]; // 从二级页表中取出对应的页表项
801002db:	8b 45 e0             	mov    -0x20(%ebp),%eax
801002de:	c1 e8 0a             	shr    $0xa,%eax
801002e1:	25 fc 0f 00 00       	and    $0xffc,%eax
801002e6:	01 c3                	add    %eax,%ebx
801002e8:	83 c4 10             	add    $0x10,%esp
801002eb:	eb 88                	jmp    80100275 <kmmap+0x69>
            cprintf("kmmap error: pte already present\n");
801002ed:	83 ec 0c             	sub    $0xc,%esp
801002f0:	68 f4 18 10 80       	push   $0x801018f4
801002f5:	e8 67 11 00 00       	call   80101461 <cprintf>
            return -1;
801002fa:	83 c4 10             	add    $0x10,%esp
801002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100302:	eb 0c                	jmp    80100310 <kmmap+0x104>
            return -1;
80100304:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100309:	eb 05                	jmp    80100310 <kmmap+0x104>
8010030b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100310:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100313:	5b                   	pop    %ebx
80100314:	5e                   	pop    %esi
80100315:	5f                   	pop    %edi
80100316:	5d                   	pop    %ebp
80100317:	c3                   	ret    
    return 0;
80100318:	b8 00 00 00 00       	mov    $0x0,%eax
8010031d:	eb f1                	jmp    80100310 <kmmap+0x104>

8010031f <set_kernel_pgdir>:
{
8010031f:	55                   	push   %ebp
80100320:	89 e5                	mov    %esp,%ebp
80100322:	53                   	push   %ebx
80100323:	83 ec 04             	sub    $0x4,%esp
    if ((kernel_pgdir = (pde_t*)kmem_alloc()) == 0) // 分配一页内存作为一级页表页（即页目录）
80100326:	e8 82 fe ff ff       	call   801001ad <kmem_alloc>
8010032b:	89 c3                	mov    %eax,%ebx
8010032d:	85 c0                	test   %eax,%eax
8010032f:	0f 84 ac 00 00 00    	je     801003e1 <set_kernel_pgdir+0xc2>
    memset(kernel_pgdir, 0, PGSIZE);
80100335:	83 ec 04             	sub    $0x4,%esp
80100338:	68 00 10 00 00       	push   $0x1000
8010033d:	6a 00                	push   $0x0
8010033f:	50                   	push   %eax
80100340:	e8 25 0c 00 00       	call   80100f6a <memset>
    if (kmmap(kernel_pgdir, (void*)K_ADDR_BASE, P_ADDR_EXTMEM - 0, (paddr_t)0, PTE_W) < 0) { // 映射低1MB内存
80100345:	83 c4 08             	add    $0x8,%esp
80100348:	6a 02                	push   $0x2
8010034a:	6a 00                	push   $0x0
8010034c:	b9 00 00 10 00       	mov    $0x100000,%ecx
80100351:	ba 00 00 00 80       	mov    $0x80000000,%edx
80100356:	89 d8                	mov    %ebx,%eax
80100358:	e8 af fe ff ff       	call   8010020c <kmmap>
8010035d:	83 c4 10             	add    $0x10,%esp
80100360:	85 c0                	test   %eax,%eax
80100362:	78 6c                	js     801003d0 <set_kernel_pgdir+0xb1>
    if (kmmap(kernel_pgdir, (void*)K_ADDR_LOAD, K_V2P(data) - K_V2P(K_ADDR_LOAD), K_V2P(K_ADDR_LOAD), 0) < 0) { // 映射内核代码段和数据段占据的内存
80100364:	83 ec 08             	sub    $0x8,%esp
80100367:	6a 00                	push   $0x0
80100369:	68 00 00 10 00       	push   $0x100000
8010036e:	b9 00 20 00 00       	mov    $0x2000,%ecx
80100373:	ba 00 00 10 80       	mov    $0x80100000,%edx
80100378:	89 d8                	mov    %ebx,%eax
8010037a:	e8 8d fe ff ff       	call   8010020c <kmmap>
8010037f:	83 c4 10             	add    $0x10,%esp
80100382:	85 c0                	test   %eax,%eax
80100384:	78 4a                	js     801003d0 <set_kernel_pgdir+0xb1>
    if (kmmap(kernel_pgdir, (void*)data, P_ADDR_PHYSTOP - K_V2P(data), K_V2P(data), PTE_W) < 0) { // 映射内核数据段后面的内存
80100386:	b9 00 00 00 8e       	mov    $0x8e000000,%ecx
8010038b:	81 e9 00 20 10 80    	sub    $0x80102000,%ecx
80100391:	83 ec 08             	sub    $0x8,%esp
80100394:	6a 02                	push   $0x2
80100396:	68 00 20 10 00       	push   $0x102000
8010039b:	ba 00 20 10 80       	mov    $0x80102000,%edx
801003a0:	89 d8                	mov    %ebx,%eax
801003a2:	e8 65 fe ff ff       	call   8010020c <kmmap>
801003a7:	83 c4 10             	add    $0x10,%esp
801003aa:	85 c0                	test   %eax,%eax
801003ac:	78 22                	js     801003d0 <set_kernel_pgdir+0xb1>
    if (kmmap(kernel_pgdir, (void*)P_ADDR_DEVSPACE, 0 - P_ADDR_DEVSPACE, (paddr_t)P_ADDR_DEVSPACE, PTE_W) < 0) { // 映射设备内存（直接映射）
801003ae:	83 ec 08             	sub    $0x8,%esp
801003b1:	6a 02                	push   $0x2
801003b3:	68 00 00 00 fe       	push   $0xfe000000
801003b8:	b9 00 00 00 02       	mov    $0x2000000,%ecx
801003bd:	ba 00 00 00 fe       	mov    $0xfe000000,%edx
801003c2:	89 d8                	mov    %ebx,%eax
801003c4:	e8 43 fe ff ff       	call   8010020c <kmmap>
801003c9:	83 c4 10             	add    $0x10,%esp
801003cc:	85 c0                	test   %eax,%eax
801003ce:	79 11                	jns    801003e1 <set_kernel_pgdir+0xc2>
    kmem_free((char*)kernel_pgdir);
801003d0:	83 ec 0c             	sub    $0xc,%esp
801003d3:	53                   	push   %ebx
801003d4:	e8 fe fc ff ff       	call   801000d7 <kmem_free>
    return 0;
801003d9:	83 c4 10             	add    $0x10,%esp
801003dc:	bb 00 00 00 00       	mov    $0x0,%ebx
}
801003e1:	89 d8                	mov    %ebx,%eax
801003e3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801003e6:	c9                   	leave  
801003e7:	c3                   	ret    

801003e8 <switch_pgdir>:
{
801003e8:	55                   	push   %ebp
801003e9:	89 e5                	mov    %esp,%ebp
    if (p == NULL) {
801003eb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801003ef:	74 02                	je     801003f3 <switch_pgdir+0xb>
}
801003f1:	5d                   	pop    %ebp
801003f2:	c3                   	ret    
        lcr3(K_V2P(kernel_pgdir));
801003f3:	a1 3c 33 10 80       	mov    0x8010333c,%eax
801003f8:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint32_t val)
{
    asm volatile("movl %0,%%cr3"
801003fd:	0f 22 d8             	mov    %eax,%cr3
}
80100400:	eb ef                	jmp    801003f1 <switch_pgdir+0x9>

80100402 <kmem_init>:
{
80100402:	55                   	push   %ebp
80100403:	89 e5                	mov    %esp,%ebp
80100405:	83 ec 10             	sub    $0x10,%esp
    initlock(&kmem.lock, "kmem");
80100408:	68 c0 18 10 80       	push   $0x801018c0
8010040d:	68 00 33 10 80       	push   $0x80103300
80100412:	e8 6f 01 00 00       	call   80100586 <initlock>
    kmem.use_lock = 0;
80100417:	c7 05 34 33 10 80 00 	movl   $0x0,0x80103334
8010041e:	00 00 00 
    kmem_free_pages(end, K_P2V(P_ADDR_LOWMEM)); // 释放[end, 4MB]部分给新的内核页表使用
80100421:	83 c4 08             	add    $0x8,%esp
80100424:	68 00 00 40 80       	push   $0x80400000
80100429:	68 b0 59 10 80       	push   $0x801059b0
8010042e:	e8 36 fd ff ff       	call   80100169 <kmem_free_pages>
    kernel_pgdir = set_kernel_pgdir(); // 设置内核页表
80100433:	e8 e7 fe ff ff       	call   8010031f <set_kernel_pgdir>
80100438:	a3 3c 33 10 80       	mov    %eax,0x8010333c
    switch_pgdir(NULL); // NULL 代表切换为内核页表
8010043d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80100444:	e8 9f ff ff ff       	call   801003e8 <switch_pgdir>
}
80100449:	83 c4 10             	add    $0x10,%esp
8010044c:	c9                   	leave  
8010044d:	c3                   	ret    

8010044e <free_pgdir>:
{
8010044e:	55                   	push   %ebp
8010044f:	89 e5                	mov    %esp,%ebp
80100451:	56                   	push   %esi
80100452:	53                   	push   %ebx
80100453:	8b 75 08             	mov    0x8(%ebp),%esi
80100456:	bb 00 00 00 00       	mov    $0x0,%ebx
8010045b:	eb 0b                	jmp    80100468 <free_pgdir+0x1a>
    for (int i = 0; i < NPDENTRIES; i++) {
8010045d:	83 c3 04             	add    $0x4,%ebx
80100460:	81 fb 00 10 00 00    	cmp    $0x1000,%ebx
80100466:	74 22                	je     8010048a <free_pgdir+0x3c>
        if (p->pgdir[i] & PTE_P) {
80100468:	8b 46 04             	mov    0x4(%esi),%eax
8010046b:	8b 04 18             	mov    (%eax,%ebx,1),%eax
8010046e:	a8 01                	test   $0x1,%al
80100470:	74 eb                	je     8010045d <free_pgdir+0xf>
            kmem_free(v);
80100472:	83 ec 0c             	sub    $0xc,%esp
            char* v = K_P2V(PTE_ADDR(p->pgdir[i]));
80100475:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010047a:	05 00 00 00 80       	add    $0x80000000,%eax
            kmem_free(v);
8010047f:	50                   	push   %eax
80100480:	e8 52 fc ff ff       	call   801000d7 <kmem_free>
80100485:	83 c4 10             	add    $0x10,%esp
80100488:	eb d3                	jmp    8010045d <free_pgdir+0xf>
    kmem_free((char*)p->pgdir); // 释放页目录
8010048a:	83 ec 0c             	sub    $0xc,%esp
8010048d:	ff 76 04             	push   0x4(%esi)
80100490:	e8 42 fc ff ff       	call   801000d7 <kmem_free>
}
80100495:	83 c4 10             	add    $0x10,%esp
80100498:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010049b:	5b                   	pop    %ebx
8010049c:	5e                   	pop    %esi
8010049d:	5d                   	pop    %ebp
8010049e:	c3                   	ret    

8010049f <conf_gdt>:

/**
 * 内核完全运行在高地址之上了，相应的一些结构的地址也得切换到高地址上面去，比如说 GDTR 中存放的 GDT 地址和界限。
 */
void conf_gdt(void)
{
8010049f:	55                   	push   %ebp
801004a0:	89 e5                	mov    %esp,%ebp
801004a2:	83 ec 18             	sub    $0x18,%esp

    // Map "logical" addresses to virtual addresses using identity map.
    // Cannot share a CODE descriptor for both kernel and user
    // because it would have to have DPL_USR, but the CPU forbids
    // an interrupt from CPL=0 to DPL=3.
    c = &cpus[cpuid()];
801004a5:	e8 83 03 00 00       	call   8010082d <cpuid>
    c->gdt[SEG_SELECTOR_KCODE] = SEG(STA_X | STA_R, 0, 0xffffffff, 0);
801004aa:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
801004b0:	66 c7 80 d8 33 10 80 	movw   $0xffff,-0x7fefcc28(%eax)
801004b7:	ff ff 
801004b9:	66 c7 80 da 33 10 80 	movw   $0x0,-0x7fefcc26(%eax)
801004c0:	00 00 
801004c2:	c6 80 dc 33 10 80 00 	movb   $0x0,-0x7fefcc24(%eax)
801004c9:	c6 80 dd 33 10 80 9a 	movb   $0x9a,-0x7fefcc23(%eax)
801004d0:	c6 80 de 33 10 80 cf 	movb   $0xcf,-0x7fefcc22(%eax)
801004d7:	c6 80 df 33 10 80 00 	movb   $0x0,-0x7fefcc21(%eax)
    c->gdt[SEG_SELECTOR_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801004de:	66 c7 80 e0 33 10 80 	movw   $0xffff,-0x7fefcc20(%eax)
801004e5:	ff ff 
801004e7:	66 c7 80 e2 33 10 80 	movw   $0x0,-0x7fefcc1e(%eax)
801004ee:	00 00 
801004f0:	c6 80 e4 33 10 80 00 	movb   $0x0,-0x7fefcc1c(%eax)
801004f7:	c6 80 e5 33 10 80 92 	movb   $0x92,-0x7fefcc1b(%eax)
801004fe:	c6 80 e6 33 10 80 cf 	movb   $0xcf,-0x7fefcc1a(%eax)
80100505:	c6 80 e7 33 10 80 00 	movb   $0x0,-0x7fefcc19(%eax)
    c->gdt[SEG_SELECTOR_UCODE] = SEG(STA_X | STA_R, 0, 0xffffffff, DPL_USER);
8010050c:	66 c7 80 e8 33 10 80 	movw   $0xffff,-0x7fefcc18(%eax)
80100513:	ff ff 
80100515:	66 c7 80 ea 33 10 80 	movw   $0x0,-0x7fefcc16(%eax)
8010051c:	00 00 
8010051e:	c6 80 ec 33 10 80 00 	movb   $0x0,-0x7fefcc14(%eax)
80100525:	c6 80 ed 33 10 80 fa 	movb   $0xfa,-0x7fefcc13(%eax)
8010052c:	c6 80 ee 33 10 80 cf 	movb   $0xcf,-0x7fefcc12(%eax)
80100533:	c6 80 ef 33 10 80 00 	movb   $0x0,-0x7fefcc11(%eax)
    c->gdt[SEG_SELECTOR_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
8010053a:	66 c7 80 f0 33 10 80 	movw   $0xffff,-0x7fefcc10(%eax)
80100541:	ff ff 
80100543:	66 c7 80 f2 33 10 80 	movw   $0x0,-0x7fefcc0e(%eax)
8010054a:	00 00 
8010054c:	c6 80 f4 33 10 80 00 	movb   $0x0,-0x7fefcc0c(%eax)
80100553:	c6 80 f5 33 10 80 f2 	movb   $0xf2,-0x7fefcc0b(%eax)
8010055a:	c6 80 f6 33 10 80 cf 	movb   $0xcf,-0x7fefcc0a(%eax)
80100561:	c6 80 f7 33 10 80 00 	movb   $0x0,-0x7fefcc09(%eax)
    lgdt(c->gdt, sizeof(c->gdt));
80100568:	05 d0 33 10 80       	add    $0x801033d0,%eax
    pd[0] = size - 1;
8010056d:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
    pd[1] = (uint32_t)p;
80100573:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
    pd[2] = (uint32_t)p >> 16;
80100577:	c1 e8 10             	shr    $0x10,%eax
8010057a:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
    asm volatile("lgdt (%0)"
8010057e:	8d 45 f2             	lea    -0xe(%ebp),%eax
80100581:	0f 01 10             	lgdtl  (%eax)
}
80100584:	c9                   	leave  
80100585:	c3                   	ret    

80100586 <initlock>:
#include "inc/i_lib.h"
#include "inc/mem.h"
#include "inc/types.h"

void initlock(struct spinlock* lock, char* name)
{
80100586:	55                   	push   %ebp
80100587:	89 e5                	mov    %esp,%ebp
80100589:	8b 45 08             	mov    0x8(%ebp),%eax
    lock->name = name;
8010058c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010058f:	89 50 04             	mov    %edx,0x4(%eax)
    lock->locked = 0;
80100592:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    lock->cpu = 0;
80100598:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
8010059f:	5d                   	pop    %ebp
801005a0:	c3                   	ret    

801005a1 <getcallerpcs>:

/**
 * 通过 %ebp 链，在 pcs[ ] 中记录当前调用栈
 */
void getcallerpcs(void* v, uint32_t pcs[])
{
801005a1:	55                   	push   %ebp
801005a2:	89 e5                	mov    %esp,%ebp
801005a4:	53                   	push   %ebx
801005a5:	8b 45 08             	mov    0x8(%ebp),%eax
801005a8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
    uint32_t* ebp;
    int i;

    ebp = (uint32_t*)v - 2;
801005ab:	8d 50 f8             	lea    -0x8(%eax),%edx
    for (i = 0; i < 10; i++) {
        if (ebp == 0 || ebp < (uint32_t*)K_ADDR_BASE || ebp == (uint32_t*)0xffffffff)
801005ae:	05 f8 ff ff 7f       	add    $0x7ffffff8,%eax
801005b3:	3d fe ff ff 7f       	cmp    $0x7ffffffe,%eax
801005b8:	77 40                	ja     801005fa <getcallerpcs+0x59>
    for (i = 0; i < 10; i++) {
801005ba:	b8 00 00 00 00       	mov    $0x0,%eax
            break;
        pcs[i] = ebp[1]; // saved %eip
801005bf:	8b 5a 04             	mov    0x4(%edx),%ebx
801005c2:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
        ebp = (uint32_t*)ebp[0]; // saved %ebp
801005c5:	8b 12                	mov    (%edx),%edx
    for (i = 0; i < 10; i++) {
801005c7:	83 c0 01             	add    $0x1,%eax
801005ca:	83 f8 0a             	cmp    $0xa,%eax
801005cd:	74 26                	je     801005f5 <getcallerpcs+0x54>
        if (ebp == 0 || ebp < (uint32_t*)K_ADDR_BASE || ebp == (uint32_t*)0xffffffff)
801005cf:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
801005d5:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
801005db:	76 e2                	jbe    801005bf <getcallerpcs+0x1e>
    }
    for (; i < 10; i++)
801005dd:	83 f8 09             	cmp    $0x9,%eax
801005e0:	7f 13                	jg     801005f5 <getcallerpcs+0x54>
801005e2:	8d 04 81             	lea    (%ecx,%eax,4),%eax
801005e5:	8d 51 28             	lea    0x28(%ecx),%edx
        pcs[i] = 0;
801005e8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    for (; i < 10; i++)
801005ee:	83 c0 04             	add    $0x4,%eax
801005f1:	39 d0                	cmp    %edx,%eax
801005f3:	75 f3                	jne    801005e8 <getcallerpcs+0x47>
}
801005f5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801005f8:	c9                   	leave  
801005f9:	c3                   	ret    
    for (i = 0; i < 10; i++) {
801005fa:	b8 00 00 00 00       	mov    $0x0,%eax
801005ff:	eb e1                	jmp    801005e2 <getcallerpcs+0x41>

80100601 <pushcli>:
    popcli();
    return ret;
}

void pushcli(void)
{
80100601:	55                   	push   %ebp
80100602:	89 e5                	mov    %esp,%ebp
80100604:	53                   	push   %ebx
80100605:	83 ec 04             	sub    $0x4,%esp

static inline uint32_t
read_eflags(void)
{
    uint32_t eflags;
    asm volatile("pushfl; popl %0"
80100608:	9c                   	pushf  
80100609:	5b                   	pop    %ebx
}

static inline void
cli(void)
{
    asm volatile("cli");
8010060a:	fa                   	cli    
    int eflags;

    eflags = read_eflags();
    cli();
    if (mycpu()->ncli == 0)
8010060b:	e8 b7 01 00 00       	call   801007c7 <mycpu>
80100610:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80100617:	74 11                	je     8010062a <pushcli+0x29>
        mycpu()->intena = eflags & FL_IF;
    mycpu()->ncli += 1;
80100619:	e8 a9 01 00 00       	call   801007c7 <mycpu>
8010061e:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80100625:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100628:	c9                   	leave  
80100629:	c3                   	ret    
        mycpu()->intena = eflags & FL_IF;
8010062a:	e8 98 01 00 00       	call   801007c7 <mycpu>
8010062f:	81 e3 00 02 00 00    	and    $0x200,%ebx
80100635:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
8010063b:	eb dc                	jmp    80100619 <pushcli+0x18>

8010063d <popcli>:

void popcli(void)
{
8010063d:	55                   	push   %ebp
8010063e:	89 e5                	mov    %esp,%ebp
80100640:	83 ec 08             	sub    $0x8,%esp
    asm volatile("pushfl; popl %0"
80100643:	9c                   	pushf  
80100644:	58                   	pop    %eax
    if (read_eflags() & FL_IF || --mycpu()->ncli < 0) {
80100645:	f6 c4 02             	test   $0x2,%ah
80100648:	75 18                	jne    80100662 <popcli+0x25>
8010064a:	e8 78 01 00 00       	call   801007c7 <mycpu>
8010064f:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80100655:	8d 51 ff             	lea    -0x1(%ecx),%edx
80100658:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
8010065e:	85 d2                	test   %edx,%edx
80100660:	79 11                	jns    80100673 <popcli+0x36>
        cprintf("popcli error: ");
80100662:	83 ec 0c             	sub    $0xc,%esp
80100665:	68 16 19 10 80       	push   $0x80101916
8010066a:	e8 f2 0d 00 00       	call   80101461 <cprintf>
    asm volatile("hlt");
8010066f:	f4                   	hlt    
}
80100670:	83 c4 10             	add    $0x10,%esp
        hlt();
    }
    if (mycpu()->ncli == 0 && mycpu()->intena)
80100673:	e8 4f 01 00 00       	call   801007c7 <mycpu>
80100678:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
8010067f:	74 02                	je     80100683 <popcli+0x46>
        sti();
}
80100681:	c9                   	leave  
80100682:	c3                   	ret    
    if (mycpu()->ncli == 0 && mycpu()->intena)
80100683:	e8 3f 01 00 00       	call   801007c7 <mycpu>
80100688:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
8010068f:	74 f0                	je     80100681 <popcli+0x44>
}

static inline void
sti(void)
{
    asm volatile("sti");
80100691:	fb                   	sti    
}
80100692:	eb ed                	jmp    80100681 <popcli+0x44>

80100694 <holding>:
{
80100694:	55                   	push   %ebp
80100695:	89 e5                	mov    %esp,%ebp
80100697:	56                   	push   %esi
80100698:	53                   	push   %ebx
80100699:	8b 75 08             	mov    0x8(%ebp),%esi
    pushcli();
8010069c:	e8 60 ff ff ff       	call   80100601 <pushcli>
    ret = lock->locked && lock->cpu == mycpu();
801006a1:	bb 00 00 00 00       	mov    $0x0,%ebx
801006a6:	83 3e 00             	cmpl   $0x0,(%esi)
801006a9:	75 0b                	jne    801006b6 <holding+0x22>
    popcli();
801006ab:	e8 8d ff ff ff       	call   8010063d <popcli>
}
801006b0:	89 d8                	mov    %ebx,%eax
801006b2:	5b                   	pop    %ebx
801006b3:	5e                   	pop    %esi
801006b4:	5d                   	pop    %ebp
801006b5:	c3                   	ret    
    ret = lock->locked && lock->cpu == mycpu();
801006b6:	8b 5e 08             	mov    0x8(%esi),%ebx
801006b9:	e8 09 01 00 00       	call   801007c7 <mycpu>
801006be:	39 c3                	cmp    %eax,%ebx
801006c0:	0f 94 c3             	sete   %bl
801006c3:	0f b6 db             	movzbl %bl,%ebx
801006c6:	eb e3                	jmp    801006ab <holding+0x17>

801006c8 <acquire>:
{
801006c8:	55                   	push   %ebp
801006c9:	89 e5                	mov    %esp,%ebp
801006cb:	53                   	push   %ebx
801006cc:	83 ec 04             	sub    $0x4,%esp
    pushcli(); // disable interrupts to avoid deadlock.
801006cf:	e8 2d ff ff ff       	call   80100601 <pushcli>
    if (holding(lock)) {
801006d4:	83 ec 0c             	sub    $0xc,%esp
801006d7:	ff 75 08             	push   0x8(%ebp)
801006da:	e8 b5 ff ff ff       	call   80100694 <holding>
801006df:	83 c4 10             	add    $0x10,%esp
801006e2:	85 c0                	test   %eax,%eax
801006e4:	75 37                	jne    8010071d <acquire+0x55>
    asm volatile("lock; xchgl %0, %1"
801006e6:	b9 01 00 00 00       	mov    $0x1,%ecx
    while (xchg(&lock->locked, 1) != 0) // 获取锁
801006eb:	8b 55 08             	mov    0x8(%ebp),%edx
801006ee:	89 c8                	mov    %ecx,%eax
801006f0:	f0 87 02             	lock xchg %eax,(%edx)
801006f3:	85 c0                	test   %eax,%eax
801006f5:	75 f4                	jne    801006eb <acquire+0x23>
    __sync_synchronize(); // 防止编译优化
801006f7:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
    lock->cpu = mycpu();
801006fc:	8b 5d 08             	mov    0x8(%ebp),%ebx
801006ff:	e8 c3 00 00 00       	call   801007c7 <mycpu>
80100704:	89 43 08             	mov    %eax,0x8(%ebx)
    getcallerpcs(&lock, lock->pcs);
80100707:	83 ec 08             	sub    $0x8,%esp
8010070a:	8b 45 08             	mov    0x8(%ebp),%eax
8010070d:	83 c0 0c             	add    $0xc,%eax
80100710:	50                   	push   %eax
80100711:	8d 45 08             	lea    0x8(%ebp),%eax
80100714:	50                   	push   %eax
80100715:	e8 87 fe ff ff       	call   801005a1 <getcallerpcs>
8010071a:	83 c4 10             	add    $0x10,%esp
}
8010071d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100720:	c9                   	leave  
80100721:	c3                   	ret    

80100722 <release>:
{
80100722:	55                   	push   %ebp
80100723:	89 e5                	mov    %esp,%ebp
80100725:	53                   	push   %ebx
80100726:	83 ec 10             	sub    $0x10,%esp
80100729:	8b 5d 08             	mov    0x8(%ebp),%ebx
    if (!holding(lock)) {
8010072c:	53                   	push   %ebx
8010072d:	e8 62 ff ff ff       	call   80100694 <holding>
80100732:	83 c4 10             	add    $0x10,%esp
80100735:	85 c0                	test   %eax,%eax
80100737:	75 05                	jne    8010073e <release+0x1c>
}
80100739:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010073c:	c9                   	leave  
8010073d:	c3                   	ret    
    lock->pcs[0] = 0;
8010073e:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    lock->cpu = 0;
80100745:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    __sync_synchronize();
8010074c:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
    asm volatile("movl $0, %0"
80100751:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
    popcli();
80100757:	e8 e1 fe ff ff       	call   8010063d <popcli>
8010075c:	eb db                	jmp    80100739 <release+0x17>

8010075e <search_fp>:
/**
 * 在 [a,a+len] 这一段内存寻找 floating pointer 结构
 */
static struct mp*
search_fp(uint32_t a, int len)
{
8010075e:	55                   	push   %ebp
8010075f:	89 e5                	mov    %esp,%ebp
80100761:	57                   	push   %edi
80100762:	56                   	push   %esi
80100763:	53                   	push   %ebx
80100764:	83 ec 0c             	sub    $0xc,%esp
    uint8_t *e, *p, *addr;

    addr = K_P2V(a);
80100767:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
    e = addr + len;
8010076d:	8d 3c 16             	lea    (%esi,%edx,1),%edi
    for (p = addr; p < e; p += sizeof(struct mp))
80100770:	39 fe                	cmp    %edi,%esi
80100772:	73 4c                	jae    801007c0 <search_fp+0x62>
80100774:	8d 98 10 00 00 80    	lea    -0x7ffffff0(%eax),%ebx
8010077a:	eb 0e                	jmp    8010078a <search_fp+0x2c>
        if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
8010077c:	84 c0                	test   %al,%al
8010077e:	74 36                	je     801007b6 <search_fp+0x58>
    for (p = addr; p < e; p += sizeof(struct mp))
80100780:	83 c6 10             	add    $0x10,%esi
80100783:	83 c3 10             	add    $0x10,%ebx
80100786:	39 fe                	cmp    %edi,%esi
80100788:	73 27                	jae    801007b1 <search_fp+0x53>
        if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
8010078a:	83 ec 04             	sub    $0x4,%esp
8010078d:	6a 04                	push   $0x4
8010078f:	68 25 19 10 80       	push   $0x80101925
80100794:	56                   	push   %esi
80100795:	e8 05 08 00 00       	call   80100f9f <memcmp>
8010079a:	83 c4 10             	add    $0x10,%esp
8010079d:	85 c0                	test   %eax,%eax
8010079f:	75 df                	jne    80100780 <search_fp+0x22>
801007a1:	89 f2                	mov    %esi,%edx
        sum += addr[i];
801007a3:	0f b6 0a             	movzbl (%edx),%ecx
801007a6:	01 c8                	add    %ecx,%eax
    for (i = 0; i < len; i++)
801007a8:	83 c2 01             	add    $0x1,%edx
801007ab:	39 da                	cmp    %ebx,%edx
801007ad:	75 f4                	jne    801007a3 <search_fp+0x45>
801007af:	eb cb                	jmp    8010077c <search_fp+0x1e>
            return (struct mp*)p;
    return 0;
801007b1:	be 00 00 00 00       	mov    $0x0,%esi
}
801007b6:	89 f0                	mov    %esi,%eax
801007b8:	8d 65 f4             	lea    -0xc(%ebp),%esp
801007bb:	5b                   	pop    %ebx
801007bc:	5e                   	pop    %esi
801007bd:	5f                   	pop    %edi
801007be:	5d                   	pop    %ebp
801007bf:	c3                   	ret    
    return 0;
801007c0:	be 00 00 00 00       	mov    $0x0,%esi
801007c5:	eb ef                	jmp    801007b6 <search_fp+0x58>

801007c7 <mycpu>:
{
801007c7:	55                   	push   %ebp
801007c8:	89 e5                	mov    %esp,%ebp
801007ca:	56                   	push   %esi
801007cb:	53                   	push   %ebx
    asm volatile("pushfl; popl %0"
801007cc:	9c                   	pushf  
801007cd:	58                   	pop    %eax
    if (read_eflags() & FL_IF) {
801007ce:	f6 c4 02             	test   $0x2,%ah
801007d1:	75 33                	jne    80100806 <mycpu+0x3f>
    apicid = lapic_id();
801007d3:	e8 5b 05 00 00       	call   80100d33 <lapic_id>
    for (i = 0; i < num_cpu; ++i) {
801007d8:	8b 35 40 33 10 80    	mov    0x80103340,%esi
801007de:	85 f6                	test   %esi,%esi
801007e0:	7e 44                	jle    80100826 <mycpu+0x5f>
801007e2:	ba 00 00 00 00       	mov    $0x0,%edx
        if (cpus[i].apicid == apicid)
801007e7:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
801007ed:	0f b6 99 60 33 10 80 	movzbl -0x7fefcca0(%ecx),%ebx
801007f4:	39 c3                	cmp    %eax,%ebx
801007f6:	74 21                	je     80100819 <mycpu+0x52>
    for (i = 0; i < num_cpu; ++i) {
801007f8:	83 c2 01             	add    $0x1,%edx
801007fb:	39 f2                	cmp    %esi,%edx
801007fd:	75 e8                	jne    801007e7 <mycpu+0x20>
    return NULL;
801007ff:	b8 00 00 00 00       	mov    $0x0,%eax
80100804:	eb 19                	jmp    8010081f <mycpu+0x58>
        cprintf("mycpu called with interrupts enabled\n");
80100806:	83 ec 0c             	sub    $0xc,%esp
80100809:	68 30 19 10 80       	push   $0x80101930
8010080e:	e8 4e 0c 00 00       	call   80101461 <cprintf>
    asm volatile("hlt");
80100813:	f4                   	hlt    
}
80100814:	83 c4 10             	add    $0x10,%esp
80100817:	eb ba                	jmp    801007d3 <mycpu+0xc>
            return &cpus[i];
80100819:	8d 81 60 33 10 80    	lea    -0x7fefcca0(%ecx),%eax
}
8010081f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100822:	5b                   	pop    %ebx
80100823:	5e                   	pop    %esi
80100824:	5d                   	pop    %ebp
80100825:	c3                   	ret    
    return NULL;
80100826:	b8 00 00 00 00       	mov    $0x0,%eax
8010082b:	eb f2                	jmp    8010081f <mycpu+0x58>

8010082d <cpuid>:
{
8010082d:	55                   	push   %ebp
8010082e:	89 e5                	mov    %esp,%ebp
80100830:	83 ec 08             	sub    $0x8,%esp
    return mycpu() - cpus;
80100833:	e8 8f ff ff ff       	call   801007c7 <mycpu>
80100838:	2d 60 33 10 80       	sub    $0x80103360,%eax
8010083d:	c1 f8 04             	sar    $0x4,%eax
80100840:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
80100846:	c9                   	leave  
80100847:	c3                   	ret    

80100848 <conf_mcpu>:

/**
 * 检测其他处理器，并将其配置写入 cpu 结构
 */
void conf_mcpu(void)
{
80100848:	55                   	push   %ebp
80100849:	89 e5                	mov    %esp,%ebp
8010084b:	57                   	push   %edi
8010084c:	56                   	push   %esi
8010084d:	53                   	push   %ebx
8010084e:	83 ec 1c             	sub    $0x1c,%esp
    if ((p = ((bda[0x0F] << 8) | bda[0x0E]) << 4)) { //在EBDA中最开始1K中寻找
80100851:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80100858:	c1 e0 08             	shl    $0x8,%eax
8010085b:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80100862:	09 d0                	or     %edx,%eax
80100864:	c1 e0 04             	shl    $0x4,%eax
80100867:	0f 84 c1 00 00 00    	je     8010092e <conf_mcpu+0xe6>
        if ((mp = search_fp(p, 1024)))
8010086d:	ba 00 04 00 00       	mov    $0x400,%edx
80100872:	e8 e7 fe ff ff       	call   8010075e <search_fp>
80100877:	89 c3                	mov    %eax,%ebx
80100879:	85 c0                	test   %eax,%eax
8010087b:	75 19                	jne    80100896 <conf_mcpu+0x4e>
    return search_fp(0xF0000, 0x10000); //在0xf0000~0xfffff中查找
8010087d:	ba 00 00 01 00       	mov    $0x10000,%edx
80100882:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80100887:	e8 d2 fe ff ff       	call   8010075e <search_fp>
8010088c:	89 c3                	mov    %eax,%ebx
    if ((mp = find_fp()) == 0 || mp->physaddr == 0)
8010088e:	85 c0                	test   %eax,%eax
80100890:	0f 84 cc 00 00 00    	je     80100962 <conf_mcpu+0x11a>
80100896:	8b 7b 04             	mov    0x4(%ebx),%edi
80100899:	85 ff                	test   %edi,%edi
8010089b:	0f 84 c5 00 00 00    	je     80100966 <conf_mcpu+0x11e>
    conf = (struct mpconf*)K_P2V((uint32_t)mp->physaddr); // 根据 floating pointer 找到 MP Configuration Table
801008a1:	8d b7 00 00 00 80    	lea    -0x80000000(%edi),%esi
    if (memcmp(conf, "PCMP", 4) != 0)
801008a7:	83 ec 04             	sub    $0x4,%esp
801008aa:	6a 04                	push   $0x4
801008ac:	68 2a 19 10 80       	push   $0x8010192a
801008b1:	56                   	push   %esi
801008b2:	e8 e8 06 00 00       	call   80100f9f <memcmp>
801008b7:	89 c2                	mov    %eax,%edx
801008b9:	83 c4 10             	add    $0x10,%esp
801008bc:	85 c0                	test   %eax,%eax
801008be:	0f 85 a6 00 00 00    	jne    8010096a <conf_mcpu+0x122>
    if (conf->version != 1 && conf->version != 4)
801008c4:	0f b6 87 06 00 00 80 	movzbl -0x7ffffffa(%edi),%eax
801008cb:	3c 01                	cmp    $0x1,%al
801008cd:	74 08                	je     801008d7 <conf_mcpu+0x8f>
801008cf:	3c 04                	cmp    $0x4,%al
801008d1:	0f 85 9a 00 00 00    	jne    80100971 <conf_mcpu+0x129>
    if (sum((uint8_t*)conf, conf->length) != 0)
801008d7:	0f b7 8f 04 00 00 80 	movzwl -0x7ffffffc(%edi),%ecx
    for (i = 0; i < len; i++)
801008de:	66 85 c9             	test   %cx,%cx
801008e1:	0f 84 91 00 00 00    	je     80100978 <conf_mcpu+0x130>
801008e7:	89 f8                	mov    %edi,%eax
801008e9:	0f b7 c9             	movzwl %cx,%ecx
801008ec:	01 cf                	add    %ecx,%edi
        sum += addr[i];
801008ee:	0f b6 88 00 00 00 80 	movzbl -0x80000000(%eax),%ecx
801008f5:	01 ca                	add    %ecx,%edx
    for (i = 0; i < len; i++)
801008f7:	83 c0 01             	add    $0x1,%eax
801008fa:	39 f8                	cmp    %edi,%eax
801008fc:	75 f0                	jne    801008ee <conf_mcpu+0xa6>
        return 0;
801008fe:	84 d2                	test   %dl,%dl
80100900:	b8 00 00 00 00       	mov    $0x0,%eax
80100905:	0f 45 f0             	cmovne %eax,%esi
80100908:	0f 45 d8             	cmovne %eax,%ebx
8010090b:	89 5d e0             	mov    %ebx,-0x20(%ebp)
    struct mpioapic* ioapic;

    /* 寻找有多少个处理器表项，多少个处理器表项就代表有多少个处理器，然后将相关信息填进全局的 CPU 数据结构 */
    conf = find_mpct(&mp);
    ismp = 1;
    lapic = (uint32_t*)conf->lapicaddr;
8010090e:	8b 46 24             	mov    0x24(%esi),%eax
80100911:	a3 e8 38 10 80       	mov    %eax,0x801038e8
    for (p = (uint8_t*)(conf + 1), e = (uint8_t*)conf + conf->length; p < e;) { // 跳过表头，从第一个表项开始for循环
80100916:	8d 46 2c             	lea    0x2c(%esi),%eax
80100919:	0f b7 56 04          	movzwl 0x4(%esi),%edx
8010091d:	01 f2                	add    %esi,%edx
    ismp = 1;
8010091f:	bb 01 00 00 00       	mov    $0x1,%ebx
        switch (*p) { //选取当前表项
80100924:	be 00 00 00 00       	mov    $0x0,%esi
80100929:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
    for (p = (uint8_t*)(conf + 1), e = (uint8_t*)conf + conf->length; p < e;) { // 跳过表头，从第一个表项开始for循环
8010092c:	eb 5a                	jmp    80100988 <conf_mcpu+0x140>
        p = ((bda[0x14] << 8) | bda[0x13]) * 1024;
8010092e:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80100935:	c1 e0 08             	shl    $0x8,%eax
80100938:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
8010093f:	09 d0                	or     %edx,%eax
80100941:	c1 e0 0a             	shl    $0xa,%eax
        if ((mp = search_fp(p - 1024, 1024)))
80100944:	2d 00 04 00 00       	sub    $0x400,%eax
80100949:	ba 00 04 00 00       	mov    $0x400,%edx
8010094e:	e8 0b fe ff ff       	call   8010075e <search_fp>
80100953:	89 c3                	mov    %eax,%ebx
80100955:	85 c0                	test   %eax,%eax
80100957:	0f 85 39 ff ff ff    	jne    80100896 <conf_mcpu+0x4e>
8010095d:	e9 1b ff ff ff       	jmp    8010087d <conf_mcpu+0x35>
        return 0;
80100962:	89 c6                	mov    %eax,%esi
80100964:	eb a8                	jmp    8010090e <conf_mcpu+0xc6>
80100966:	89 fe                	mov    %edi,%esi
80100968:	eb a4                	jmp    8010090e <conf_mcpu+0xc6>
        return 0;
8010096a:	be 00 00 00 00       	mov    $0x0,%esi
8010096f:	eb 9d                	jmp    8010090e <conf_mcpu+0xc6>
        return 0;
80100971:	be 00 00 00 00       	mov    $0x0,%esi
80100976:	eb 96                	jmp    8010090e <conf_mcpu+0xc6>
    for (i = 0; i < len; i++)
80100978:	89 5d e0             	mov    %ebx,-0x20(%ebp)
8010097b:	eb 91                	jmp    8010090e <conf_mcpu+0xc6>
        switch (*p) { //选取当前表项
8010097d:	83 e9 03             	sub    $0x3,%ecx
80100980:	80 f9 01             	cmp    $0x1,%cl
80100983:	76 15                	jbe    8010099a <conf_mcpu+0x152>
80100985:	89 75 e4             	mov    %esi,-0x1c(%ebp)
    for (p = (uint8_t*)(conf + 1), e = (uint8_t*)conf + conf->length; p < e;) { // 跳过表头，从第一个表项开始for循环
80100988:	39 d0                	cmp    %edx,%eax
8010098a:	73 4b                	jae    801009d7 <conf_mcpu+0x18f>
        switch (*p) { //选取当前表项
8010098c:	0f b6 08             	movzbl (%eax),%ecx
8010098f:	80 f9 02             	cmp    $0x2,%cl
80100992:	74 34                	je     801009c8 <conf_mcpu+0x180>
80100994:	77 e7                	ja     8010097d <conf_mcpu+0x135>
80100996:	84 c9                	test   %cl,%cl
80100998:	74 05                	je     8010099f <conf_mcpu+0x157>
            p += sizeof(struct mpioapic);
            continue;
        case MPBUS:
        case MPIOINTR:
        case MPLINTR:
            p += 8;
8010099a:	83 c0 08             	add    $0x8,%eax
            continue;
8010099d:	eb e9                	jmp    80100988 <conf_mcpu+0x140>
            if (num_cpu < MAX_CPU) {
8010099f:	8b 0d 40 33 10 80    	mov    0x80103340,%ecx
801009a5:	83 f9 07             	cmp    $0x7,%ecx
801009a8:	7f 19                	jg     801009c3 <conf_mcpu+0x17b>
                cpus[num_cpu].apicid = proc->apicid; // apic id可以标识一个CPU
801009aa:	69 f9 b0 00 00 00    	imul   $0xb0,%ecx,%edi
801009b0:	0f b6 58 01          	movzbl 0x1(%eax),%ebx
801009b4:	88 9f 60 33 10 80    	mov    %bl,-0x7fefcca0(%edi)
                num_cpu++; //找到一个CPU表项，CPU数量加1
801009ba:	83 c1 01             	add    $0x1,%ecx
801009bd:	89 0d 40 33 10 80    	mov    %ecx,0x80103340
            p += sizeof(struct mpproc); //跳过当前CPU表项继续循环
801009c3:	83 c0 14             	add    $0x14,%eax
            continue;
801009c6:	eb c0                	jmp    80100988 <conf_mcpu+0x140>
            ioapic_id = ioapic->apicno;
801009c8:	0f b6 48 01          	movzbl 0x1(%eax),%ecx
801009cc:	88 0d e4 38 10 80    	mov    %cl,0x801038e4
            p += sizeof(struct mpioapic);
801009d2:	83 c0 08             	add    $0x8,%eax
            continue;
801009d5:	eb b1                	jmp    80100988 <conf_mcpu+0x140>
        default:
            ismp = 0;
            break;
        }
    }
    if (!ismp) {
801009d7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
801009da:	85 db                	test   %ebx,%ebx
801009dc:	74 26                	je     80100a04 <conf_mcpu+0x1bc>
        cprintf("Didn't find a suitable machine");
        hlt();
    }

    if (mp->imcrp) {
801009de:	8b 45 e0             	mov    -0x20(%ebp),%eax
801009e1:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
801009e5:	74 15                	je     801009fc <conf_mcpu+0x1b4>
    asm volatile("outb %0,%w1"
801009e7:	b8 70 00 00 00       	mov    $0x70,%eax
801009ec:	ba 22 00 00 00       	mov    $0x22,%edx
801009f1:	ee                   	out    %al,(%dx)
    asm volatile("inb %w1,%0"
801009f2:	ba 23 00 00 00       	mov    $0x23,%edx
801009f7:	ec                   	in     (%dx),%al
        // Bochs doesn't support IMCR, so this doesn't run on Bochs.
        // But it would on real hardware.
        outb(0x22, 0x70); // Select IMCR
        outb(0x23, inb(0x23) | 1); // Mask external interrupts.
801009f8:	83 c8 01             	or     $0x1,%eax
    asm volatile("outb %0,%w1"
801009fb:	ee                   	out    %al,(%dx)
    }
801009fc:	8d 65 f4             	lea    -0xc(%ebp),%esp
801009ff:	5b                   	pop    %ebx
80100a00:	5e                   	pop    %esi
80100a01:	5f                   	pop    %edi
80100a02:	5d                   	pop    %ebp
80100a03:	c3                   	ret    
        cprintf("Didn't find a suitable machine");
80100a04:	83 ec 0c             	sub    $0xc,%esp
80100a07:	68 58 19 10 80       	push   $0x80101958
80100a0c:	e8 50 0a 00 00       	call   80101461 <cprintf>
    asm volatile("hlt");
80100a11:	f4                   	hlt    
}
80100a12:	83 c4 10             	add    $0x10,%esp
80100a15:	eb c7                	jmp    801009de <conf_mcpu+0x196>

80100a17 <lapic_write>:
/**
 * 写入 lapic
 */
static void lapic_write(int index, int value)
{
    lapic[index] = value;
80100a17:	8b 0d e8 38 10 80    	mov    0x801038e8,%ecx
80100a1d:	8d 04 81             	lea    (%ecx,%eax,4),%eax
80100a20:	89 10                	mov    %edx,(%eax)
    lapic[ID]; // wait for write to finish, by reading
80100a22:	a1 e8 38 10 80       	mov    0x801038e8,%eax
80100a27:	8b 40 20             	mov    0x20(%eax),%eax
}
80100a2a:	c3                   	ret    

80100a2b <cmos_read>:
        lapic_write(EOI, 0);
}

static uint32_t
cmos_read(uint32_t reg)
{
80100a2b:	55                   	push   %ebp
80100a2c:	89 e5                	mov    %esp,%ebp
80100a2e:	83 ec 14             	sub    $0x14,%esp
    asm volatile("outb %0,%w1"
80100a31:	ba 70 00 00 00       	mov    $0x70,%edx
80100a36:	ee                   	out    %al,(%dx)
    outb(CMOS_PORT, reg);
    spin(200);
80100a37:	68 c8 00 00 00       	push   $0xc8
80100a3c:	e8 a8 0d 00 00       	call   801017e9 <spin>
    asm volatile("inb %w1,%0"
80100a41:	ba 71 00 00 00       	mov    $0x71,%edx
80100a46:	ec                   	in     (%dx),%al

    return inb(CMOS_RETURN);
80100a47:	0f b6 c0             	movzbl %al,%eax
}
80100a4a:	c9                   	leave  
80100a4b:	c3                   	ret    

80100a4c <fill_rtcdate>:

static void
fill_rtcdate(struct time_GWT* r)
{
80100a4c:	55                   	push   %ebp
80100a4d:	89 e5                	mov    %esp,%ebp
80100a4f:	53                   	push   %ebx
80100a50:	83 ec 04             	sub    $0x4,%esp
80100a53:	89 c3                	mov    %eax,%ebx
    r->second = cmos_read(SECS);
80100a55:	b8 00 00 00 00       	mov    $0x0,%eax
80100a5a:	e8 cc ff ff ff       	call   80100a2b <cmos_read>
80100a5f:	89 03                	mov    %eax,(%ebx)
    r->minute = cmos_read(MINS);
80100a61:	b8 02 00 00 00       	mov    $0x2,%eax
80100a66:	e8 c0 ff ff ff       	call   80100a2b <cmos_read>
80100a6b:	89 43 04             	mov    %eax,0x4(%ebx)
    r->hour = cmos_read(HOURS);
80100a6e:	b8 04 00 00 00       	mov    $0x4,%eax
80100a73:	e8 b3 ff ff ff       	call   80100a2b <cmos_read>
80100a78:	89 43 08             	mov    %eax,0x8(%ebx)
    r->day = cmos_read(DAY);
80100a7b:	b8 07 00 00 00       	mov    $0x7,%eax
80100a80:	e8 a6 ff ff ff       	call   80100a2b <cmos_read>
80100a85:	89 43 0c             	mov    %eax,0xc(%ebx)
    r->month = cmos_read(MONTH);
80100a88:	b8 08 00 00 00       	mov    $0x8,%eax
80100a8d:	e8 99 ff ff ff       	call   80100a2b <cmos_read>
80100a92:	89 43 10             	mov    %eax,0x10(%ebx)
    r->year = cmos_read(YEAR);
80100a95:	b8 09 00 00 00       	mov    $0x9,%eax
80100a9a:	e8 8c ff ff ff       	call   80100a2b <cmos_read>
80100a9f:	89 43 14             	mov    %eax,0x14(%ebx)
}
80100aa2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100aa5:	c9                   	leave  
80100aa6:	c3                   	ret    

80100aa7 <interrupt_init>:
    if (!lapic)
80100aa7:	83 3d e8 38 10 80 00 	cmpl   $0x0,0x801038e8
80100aae:	0f 84 ab 01 00 00    	je     80100c5f <interrupt_init+0x1b8>
{
80100ab4:	55                   	push   %ebp
80100ab5:	89 e5                	mov    %esp,%ebp
80100ab7:	56                   	push   %esi
80100ab8:	53                   	push   %ebx
    lapic_write(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80100ab9:	ba 3f 01 00 00       	mov    $0x13f,%edx
80100abe:	b8 3c 00 00 00       	mov    $0x3c,%eax
80100ac3:	e8 4f ff ff ff       	call   80100a17 <lapic_write>
    lapic_write(TDCR, X1);
80100ac8:	ba 0b 00 00 00       	mov    $0xb,%edx
80100acd:	b8 f8 00 00 00       	mov    $0xf8,%eax
80100ad2:	e8 40 ff ff ff       	call   80100a17 <lapic_write>
    lapic_write(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80100ad7:	ba 20 00 02 00       	mov    $0x20020,%edx
80100adc:	b8 c8 00 00 00       	mov    $0xc8,%eax
80100ae1:	e8 31 ff ff ff       	call   80100a17 <lapic_write>
    lapic_write(TICR, 10000000);
80100ae6:	ba 80 96 98 00       	mov    $0x989680,%edx
80100aeb:	b8 e0 00 00 00       	mov    $0xe0,%eax
80100af0:	e8 22 ff ff ff       	call   80100a17 <lapic_write>
    lapic_write(LINT0, MASKED);
80100af5:	ba 00 00 01 00       	mov    $0x10000,%edx
80100afa:	b8 d4 00 00 00       	mov    $0xd4,%eax
80100aff:	e8 13 ff ff ff       	call   80100a17 <lapic_write>
    lapic_write(LINT1, MASKED);
80100b04:	ba 00 00 01 00       	mov    $0x10000,%edx
80100b09:	b8 d8 00 00 00       	mov    $0xd8,%eax
80100b0e:	e8 04 ff ff ff       	call   80100a17 <lapic_write>
    if (((lapic[VER] >> 16) & 0xFF) >= 4)
80100b13:	a1 e8 38 10 80       	mov    0x801038e8,%eax
80100b18:	8b 40 30             	mov    0x30(%eax),%eax
80100b1b:	c1 e8 10             	shr    $0x10,%eax
80100b1e:	a8 fc                	test   $0xfc,%al
80100b20:	0f 85 13 01 00 00    	jne    80100c39 <interrupt_init+0x192>
    lapic_write(ERROR, T_IRQ0 + IRQ_ERROR);
80100b26:	ba 33 00 00 00       	mov    $0x33,%edx
80100b2b:	b8 dc 00 00 00       	mov    $0xdc,%eax
80100b30:	e8 e2 fe ff ff       	call   80100a17 <lapic_write>
    lapic_write(ESR, 0);
80100b35:	ba 00 00 00 00       	mov    $0x0,%edx
80100b3a:	b8 a0 00 00 00       	mov    $0xa0,%eax
80100b3f:	e8 d3 fe ff ff       	call   80100a17 <lapic_write>
    lapic_write(ESR, 0);
80100b44:	ba 00 00 00 00       	mov    $0x0,%edx
80100b49:	b8 a0 00 00 00       	mov    $0xa0,%eax
80100b4e:	e8 c4 fe ff ff       	call   80100a17 <lapic_write>
    lapic_write(EOI, 0);
80100b53:	ba 00 00 00 00       	mov    $0x0,%edx
80100b58:	b8 2c 00 00 00       	mov    $0x2c,%eax
80100b5d:	e8 b5 fe ff ff       	call   80100a17 <lapic_write>
    lapic_write(ICRHI, 0);
80100b62:	ba 00 00 00 00       	mov    $0x0,%edx
80100b67:	b8 c4 00 00 00       	mov    $0xc4,%eax
80100b6c:	e8 a6 fe ff ff       	call   80100a17 <lapic_write>
    lapic_write(ICRLO, BCAST | INIT | LEVEL);
80100b71:	ba 00 85 08 00       	mov    $0x88500,%edx
80100b76:	b8 c0 00 00 00       	mov    $0xc0,%eax
80100b7b:	e8 97 fe ff ff       	call   80100a17 <lapic_write>
    while (lapic[ICRLO] & DELIVS)
80100b80:	8b 15 e8 38 10 80    	mov    0x801038e8,%edx
80100b86:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
80100b8c:	f6 c4 10             	test   $0x10,%ah
80100b8f:	75 f5                	jne    80100b86 <interrupt_init+0xdf>
    lapic_write(TPR, 0);
80100b91:	ba 00 00 00 00       	mov    $0x0,%edx
80100b96:	b8 20 00 00 00       	mov    $0x20,%eax
80100b9b:	e8 77 fe ff ff       	call   80100a17 <lapic_write>
    asm volatile("outb %0,%w1"
80100ba0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100ba5:	ba 21 00 00 00       	mov    $0x21,%edx
80100baa:	ee                   	out    %al,(%dx)
80100bab:	ba a1 00 00 00       	mov    $0xa1,%edx
80100bb0:	ee                   	out    %al,(%dx)
    ioapic_mmio = (volatile struct ioapic_mmio*)IOAPIC_MMIO;
80100bb1:	c7 05 e0 38 10 80 00 	movl   $0xfec00000,0x801038e0
80100bb8:	00 c0 fe 

/* ioapic_mmio */

static uint32_t ioapic_read(int reg)
{
    ioapic_mmio->reg = reg;
80100bbb:	c7 05 00 00 c0 fe 01 	movl   $0x1,0xfec00000
80100bc2:	00 00 00 
    return ioapic_mmio->data;
80100bc5:	a1 e0 38 10 80       	mov    0x801038e0,%eax
80100bca:	8b 58 10             	mov    0x10(%eax),%ebx
    maxintr = (ioapic_read(REG_VER) >> 16) & 0xFF;
80100bcd:	c1 eb 10             	shr    $0x10,%ebx
80100bd0:	0f b6 db             	movzbl %bl,%ebx
    ioapic_mmio->reg = reg;
80100bd3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    return ioapic_mmio->data;
80100bd9:	a1 e0 38 10 80       	mov    0x801038e0,%eax
80100bde:	8b 40 10             	mov    0x10(%eax),%eax
    if (id != ioapic_id)
80100be1:	0f b6 15 e4 38 10 80 	movzbl 0x801038e4,%edx
80100be8:	0f b6 d2             	movzbl %dl,%edx
    id = ioapic_read(REG_ID) >> 24;
80100beb:	c1 e8 18             	shr    $0x18,%eax
    if (id != ioapic_id)
80100bee:	39 c2                	cmp    %eax,%edx
80100bf0:	75 5b                	jne    80100c4d <interrupt_init+0x1a6>
{
80100bf2:	ba 10 00 00 00       	mov    $0x10,%edx
80100bf7:	b8 00 00 00 00       	mov    $0x0,%eax
        ioapic_write(REG_TABLE + 2 * i, INT_DISABLED | (T_IRQ0 + i));
80100bfc:	8d 48 20             	lea    0x20(%eax),%ecx
80100bff:	81 c9 00 00 01 00    	or     $0x10000,%ecx
}

static void ioapic_write(int reg, uint32_t data)
{
    ioapic_mmio->reg = reg;
80100c05:	8b 35 e0 38 10 80    	mov    0x801038e0,%esi
80100c0b:	89 16                	mov    %edx,(%esi)
    ioapic_mmio->data = data;
80100c0d:	8b 35 e0 38 10 80    	mov    0x801038e0,%esi
80100c13:	89 4e 10             	mov    %ecx,0x10(%esi)
    ioapic_mmio->reg = reg;
80100c16:	8d 4a 01             	lea    0x1(%edx),%ecx
80100c19:	89 0e                	mov    %ecx,(%esi)
    ioapic_mmio->data = data;
80100c1b:	8b 0d e0 38 10 80    	mov    0x801038e0,%ecx
80100c21:	c7 41 10 00 00 00 00 	movl   $0x0,0x10(%ecx)
    for (i = 0; i <= maxintr; i++) {
80100c28:	83 c0 01             	add    $0x1,%eax
80100c2b:	83 c2 02             	add    $0x2,%edx
80100c2e:	39 c3                	cmp    %eax,%ebx
80100c30:	7d ca                	jge    80100bfc <interrupt_init+0x155>
}
80100c32:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100c35:	5b                   	pop    %ebx
80100c36:	5e                   	pop    %esi
80100c37:	5d                   	pop    %ebp
80100c38:	c3                   	ret    
        lapic_write(PCINT, MASKED);
80100c39:	ba 00 00 01 00       	mov    $0x10000,%edx
80100c3e:	b8 d0 00 00 00       	mov    $0xd0,%eax
80100c43:	e8 cf fd ff ff       	call   80100a17 <lapic_write>
80100c48:	e9 d9 fe ff ff       	jmp    80100b26 <interrupt_init+0x7f>
        cprintf("ioapic_init: id isn't equal to ioapic_id; not a MP\n");
80100c4d:	83 ec 0c             	sub    $0xc,%esp
80100c50:	68 78 19 10 80       	push   $0x80101978
80100c55:	e8 07 08 00 00       	call   80101461 <cprintf>
80100c5a:	83 c4 10             	add    $0x10,%esp
80100c5d:	eb 93                	jmp    80100bf2 <interrupt_init+0x14b>
80100c5f:	c3                   	ret    

80100c60 <lapic_startap>:
{
80100c60:	55                   	push   %ebp
80100c61:	89 e5                	mov    %esp,%ebp
80100c63:	56                   	push   %esi
80100c64:	53                   	push   %ebx
80100c65:	8b 75 08             	mov    0x8(%ebp),%esi
80100c68:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80100c6b:	b8 0f 00 00 00       	mov    $0xf,%eax
80100c70:	ba 70 00 00 00       	mov    $0x70,%edx
80100c75:	ee                   	out    %al,(%dx)
80100c76:	b8 0a 00 00 00       	mov    $0xa,%eax
80100c7b:	ba 71 00 00 00       	mov    $0x71,%edx
80100c80:	ee                   	out    %al,(%dx)
    wrv[0] = 0;
80100c81:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
80100c88:	00 00 
    wrv[1] = addr >> 4;
80100c8a:	89 d8                	mov    %ebx,%eax
80100c8c:	c1 e8 04             	shr    $0x4,%eax
80100c8f:	66 a3 69 04 00 80    	mov    %ax,0x80000469
    lapic_write(ICRHI, apicid << 24);
80100c95:	c1 e6 18             	shl    $0x18,%esi
80100c98:	89 f2                	mov    %esi,%edx
80100c9a:	b8 c4 00 00 00       	mov    $0xc4,%eax
80100c9f:	e8 73 fd ff ff       	call   80100a17 <lapic_write>
    lapic_write(ICRLO, INIT | LEVEL | ASSERT);
80100ca4:	ba 00 c5 00 00       	mov    $0xc500,%edx
80100ca9:	b8 c0 00 00 00       	mov    $0xc0,%eax
80100cae:	e8 64 fd ff ff       	call   80100a17 <lapic_write>
    spin(200);
80100cb3:	83 ec 0c             	sub    $0xc,%esp
80100cb6:	68 c8 00 00 00       	push   $0xc8
80100cbb:	e8 29 0b 00 00       	call   801017e9 <spin>
    lapic_write(ICRLO, INIT | LEVEL);
80100cc0:	ba 00 85 00 00       	mov    $0x8500,%edx
80100cc5:	b8 c0 00 00 00       	mov    $0xc0,%eax
80100cca:	e8 48 fd ff ff       	call   80100a17 <lapic_write>
    spin(100); // should be 10ms, but too slow in Bochs!
80100ccf:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80100cd6:	e8 0e 0b 00 00       	call   801017e9 <spin>
        lapic_write(ICRLO, STARTUP | (addr >> 12));
80100cdb:	c1 eb 0c             	shr    $0xc,%ebx
80100cde:	80 cf 06             	or     $0x6,%bh
        lapic_write(ICRHI, apicid << 24);
80100ce1:	89 f2                	mov    %esi,%edx
80100ce3:	b8 c4 00 00 00       	mov    $0xc4,%eax
80100ce8:	e8 2a fd ff ff       	call   80100a17 <lapic_write>
        lapic_write(ICRLO, STARTUP | (addr >> 12));
80100ced:	89 da                	mov    %ebx,%edx
80100cef:	b8 c0 00 00 00       	mov    $0xc0,%eax
80100cf4:	e8 1e fd ff ff       	call   80100a17 <lapic_write>
        spin(200);
80100cf9:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80100d00:	e8 e4 0a 00 00       	call   801017e9 <spin>
        lapic_write(ICRHI, apicid << 24);
80100d05:	89 f2                	mov    %esi,%edx
80100d07:	b8 c4 00 00 00       	mov    $0xc4,%eax
80100d0c:	e8 06 fd ff ff       	call   80100a17 <lapic_write>
        lapic_write(ICRLO, STARTUP | (addr >> 12));
80100d11:	89 da                	mov    %ebx,%edx
80100d13:	b8 c0 00 00 00       	mov    $0xc0,%eax
80100d18:	e8 fa fc ff ff       	call   80100a17 <lapic_write>
        spin(200);
80100d1d:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80100d24:	e8 c0 0a 00 00       	call   801017e9 <spin>
}
80100d29:	83 c4 10             	add    $0x10,%esp
80100d2c:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100d2f:	5b                   	pop    %ebx
80100d30:	5e                   	pop    %esi
80100d31:	5d                   	pop    %ebp
80100d32:	c3                   	ret    

80100d33 <lapic_id>:
    if (!lapic)
80100d33:	a1 e8 38 10 80       	mov    0x801038e8,%eax
80100d38:	85 c0                	test   %eax,%eax
80100d3a:	74 07                	je     80100d43 <lapic_id+0x10>
    return lapic[ID] >> 24;
80100d3c:	8b 40 20             	mov    0x20(%eax),%eax
80100d3f:	c1 e8 18             	shr    $0x18,%eax
80100d42:	c3                   	ret    
        return 0;
80100d43:	b8 00 00 00 00       	mov    $0x0,%eax
}
80100d48:	c3                   	ret    

80100d49 <lapic_eoi>:
    if (lapic)
80100d49:	83 3d e8 38 10 80 00 	cmpl   $0x0,0x801038e8
80100d50:	74 17                	je     80100d69 <lapic_eoi+0x20>
{
80100d52:	55                   	push   %ebp
80100d53:	89 e5                	mov    %esp,%ebp
80100d55:	83 ec 08             	sub    $0x8,%esp
        lapic_write(EOI, 0);
80100d58:	ba 00 00 00 00       	mov    $0x0,%edx
80100d5d:	b8 2c 00 00 00       	mov    $0x2c,%eax
80100d62:	e8 b0 fc ff ff       	call   80100a17 <lapic_write>
}
80100d67:	c9                   	leave  
80100d68:	c3                   	ret    
80100d69:	c3                   	ret    

80100d6a <cmos_time>:
{
80100d6a:	55                   	push   %ebp
80100d6b:	89 e5                	mov    %esp,%ebp
80100d6d:	57                   	push   %edi
80100d6e:	56                   	push   %esi
80100d6f:	53                   	push   %ebx
80100d70:	83 ec 4c             	sub    $0x4c,%esp
80100d73:	8b 7d 08             	mov    0x8(%ebp),%edi
    sb = cmos_read(CMOS_STATB);
80100d76:	b8 0b 00 00 00       	mov    $0xb,%eax
80100d7b:	e8 ab fc ff ff       	call   80100a2b <cmos_read>
    bcd = (sb & (1 << 2)) == 0;
80100d80:	83 e0 04             	and    $0x4,%eax
80100d83:	89 45 b4             	mov    %eax,-0x4c(%ebp)
        fill_rtcdate(&t1);
80100d86:	8d 5d d0             	lea    -0x30(%ebp),%ebx
        fill_rtcdate(&t2);
80100d89:	8d 75 b8             	lea    -0x48(%ebp),%esi
        fill_rtcdate(&t1);
80100d8c:	89 d8                	mov    %ebx,%eax
80100d8e:	e8 b9 fc ff ff       	call   80100a4c <fill_rtcdate>
        if (cmos_read(CMOS_STATA) & CMOS_UIP)
80100d93:	b8 0a 00 00 00       	mov    $0xa,%eax
80100d98:	e8 8e fc ff ff       	call   80100a2b <cmos_read>
80100d9d:	a8 80                	test   $0x80,%al
80100d9f:	75 eb                	jne    80100d8c <cmos_time+0x22>
        fill_rtcdate(&t2);
80100da1:	89 f0                	mov    %esi,%eax
80100da3:	e8 a4 fc ff ff       	call   80100a4c <fill_rtcdate>
        if (memcmp(&t1, &t2, sizeof(t1)) == 0)
80100da8:	83 ec 04             	sub    $0x4,%esp
80100dab:	6a 18                	push   $0x18
80100dad:	56                   	push   %esi
80100dae:	53                   	push   %ebx
80100daf:	e8 eb 01 00 00       	call   80100f9f <memcmp>
80100db4:	83 c4 10             	add    $0x10,%esp
80100db7:	85 c0                	test   %eax,%eax
80100db9:	75 d1                	jne    80100d8c <cmos_time+0x22>
    if (bcd) {
80100dbb:	83 7d b4 00          	cmpl   $0x0,-0x4c(%ebp)
80100dbf:	75 78                	jne    80100e39 <cmos_time+0xcf>
        CONV(second);
80100dc1:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100dc4:	89 c2                	mov    %eax,%edx
80100dc6:	c1 ea 04             	shr    $0x4,%edx
80100dc9:	8d 14 92             	lea    (%edx,%edx,4),%edx
80100dcc:	83 e0 0f             	and    $0xf,%eax
80100dcf:	8d 04 50             	lea    (%eax,%edx,2),%eax
80100dd2:	89 45 d0             	mov    %eax,-0x30(%ebp)
        CONV(minute);
80100dd5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100dd8:	89 c2                	mov    %eax,%edx
80100dda:	c1 ea 04             	shr    $0x4,%edx
80100ddd:	8d 14 92             	lea    (%edx,%edx,4),%edx
80100de0:	83 e0 0f             	and    $0xf,%eax
80100de3:	8d 04 50             	lea    (%eax,%edx,2),%eax
80100de6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        CONV(hour);
80100de9:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100dec:	89 c2                	mov    %eax,%edx
80100dee:	c1 ea 04             	shr    $0x4,%edx
80100df1:	8d 14 92             	lea    (%edx,%edx,4),%edx
80100df4:	83 e0 0f             	and    $0xf,%eax
80100df7:	8d 04 50             	lea    (%eax,%edx,2),%eax
80100dfa:	89 45 d8             	mov    %eax,-0x28(%ebp)
        CONV(day);
80100dfd:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e00:	89 c2                	mov    %eax,%edx
80100e02:	c1 ea 04             	shr    $0x4,%edx
80100e05:	8d 14 92             	lea    (%edx,%edx,4),%edx
80100e08:	83 e0 0f             	and    $0xf,%eax
80100e0b:	8d 04 50             	lea    (%eax,%edx,2),%eax
80100e0e:	89 45 dc             	mov    %eax,-0x24(%ebp)
        CONV(month);
80100e11:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100e14:	89 c2                	mov    %eax,%edx
80100e16:	c1 ea 04             	shr    $0x4,%edx
80100e19:	8d 14 92             	lea    (%edx,%edx,4),%edx
80100e1c:	83 e0 0f             	and    $0xf,%eax
80100e1f:	8d 04 50             	lea    (%eax,%edx,2),%eax
80100e22:	89 45 e0             	mov    %eax,-0x20(%ebp)
        CONV(year);
80100e25:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e28:	89 c2                	mov    %eax,%edx
80100e2a:	c1 ea 04             	shr    $0x4,%edx
80100e2d:	8d 14 92             	lea    (%edx,%edx,4),%edx
80100e30:	83 e0 0f             	and    $0xf,%eax
80100e33:	8d 04 50             	lea    (%eax,%edx,2),%eax
80100e36:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    *r = t1;
80100e39:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100e3c:	89 07                	mov    %eax,(%edi)
80100e3e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e41:	89 47 04             	mov    %eax,0x4(%edi)
80100e44:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100e47:	89 47 08             	mov    %eax,0x8(%edi)
80100e4a:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e4d:	89 47 0c             	mov    %eax,0xc(%edi)
80100e50:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100e53:	89 47 10             	mov    %eax,0x10(%edi)
80100e56:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e59:	89 47 14             	mov    %eax,0x14(%edi)
    r->year += 2000;
80100e5c:	81 47 14 d0 07 00 00 	addl   $0x7d0,0x14(%edi)
}
80100e63:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100e66:	5b                   	pop    %ebx
80100e67:	5e                   	pop    %esi
80100e68:	5f                   	pop    %edi
80100e69:	5d                   	pop    %ebp
80100e6a:	c3                   	ret    

80100e6b <ioapic_enable>:
}

void ioapic_enable(int irq, int cpunum)
{
80100e6b:	55                   	push   %ebp
80100e6c:	89 e5                	mov    %esp,%ebp
80100e6e:	8b 45 08             	mov    0x8(%ebp),%eax
    // Mark interrupt edge-triggered, active high,
    // enabled, and routed to the given cpunum,
    // which happens to be that cpu's APIC ID.
    ioapic_write(REG_TABLE + 2 * irq, T_IRQ0 + irq);
80100e71:	8d 50 20             	lea    0x20(%eax),%edx
80100e74:	8d 44 00 10          	lea    0x10(%eax,%eax,1),%eax
    ioapic_mmio->reg = reg;
80100e78:	8b 0d e0 38 10 80    	mov    0x801038e0,%ecx
80100e7e:	89 01                	mov    %eax,(%ecx)
    ioapic_mmio->data = data;
80100e80:	8b 0d e0 38 10 80    	mov    0x801038e0,%ecx
80100e86:	89 51 10             	mov    %edx,0x10(%ecx)
    ioapic_write(REG_TABLE + 2 * irq + 1, cpunum << 24);
80100e89:	8b 55 0c             	mov    0xc(%ebp),%edx
80100e8c:	c1 e2 18             	shl    $0x18,%edx
80100e8f:	83 c0 01             	add    $0x1,%eax
    ioapic_mmio->reg = reg;
80100e92:	89 01                	mov    %eax,(%ecx)
    ioapic_mmio->data = data;
80100e94:	a1 e0 38 10 80       	mov    0x801038e0,%eax
80100e99:	89 50 10             	mov    %edx,0x10(%eax)
80100e9c:	5d                   	pop    %ebp
80100e9d:	c3                   	ret    

80100e9e <myproc>:

/**
 * 获取当前进程
 */
struct proc* myproc(void)
{
80100e9e:	55                   	push   %ebp
80100e9f:	89 e5                	mov    %esp,%ebp
80100ea1:	53                   	push   %ebx
80100ea2:	83 ec 04             	sub    $0x4,%esp
    struct cpu* cpu;
    struct proc* proc;
    pushcli();
80100ea5:	e8 57 f7 ff ff       	call   80100601 <pushcli>
    cpu = mycpu();
80100eaa:	e8 18 f9 ff ff       	call   801007c7 <mycpu>
    proc = cpu->proc;
80100eaf:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
    popcli();
80100eb5:	e8 83 f7 ff ff       	call   8010063d <popcli>
    return proc;
}
80100eba:	89 d8                	mov    %ebx,%eax
80100ebc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100ebf:	c9                   	leave  
80100ec0:	c3                   	ret    

80100ec1 <proc_init>:

void proc_init()
{
80100ec1:	55                   	push   %ebp
80100ec2:	89 e5                	mov    %esp,%ebp
80100ec4:	83 ec 10             	sub    $0x10,%esp
    initlock(&proc_table.lock, "proc_table");
80100ec7:	68 ac 19 10 80       	push   $0x801019ac
80100ecc:	68 00 39 10 80       	push   $0x80103900
80100ed1:	e8 b0 f6 ff ff       	call   80100586 <initlock>
    proc_table.use_lock = 0;
80100ed6:	c7 05 34 39 10 80 00 	movl   $0x0,0x80103934
80100edd:	00 00 00 
    proc_table.next_pid = 1;
80100ee0:	c7 05 38 39 10 80 01 	movl   $0x1,0x80103938
80100ee7:	00 00 00 
80100eea:	83 c4 10             	add    $0x10,%esp
    for (struct proc* p = proc_table.procs; p < &proc_table.procs[MAX_PROC]; p++) {
80100eed:	b8 3c 39 10 80       	mov    $0x8010393c,%eax
        p->state = DIED;
80100ef2:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    for (struct proc* p = proc_table.procs; p < &proc_table.procs[MAX_PROC]; p++) {
80100ef9:	83 c0 38             	add    $0x38,%eax
80100efc:	3d 3c 47 10 80       	cmp    $0x8010473c,%eax
80100f01:	75 ef                	jne    80100ef2 <proc_init+0x31>
    }
}
80100f03:	c9                   	leave  
80100f04:	c3                   	ret    

80100f05 <proc_uselock>:

void proc_uselock() { proc_table.use_lock = 1; }
80100f05:	c7 05 34 39 10 80 01 	movl   $0x1,0x80103934
80100f0c:	00 00 00 
80100f0f:	c3                   	ret    

80100f10 <serial_proc_data>:
    asm volatile("inb %w1,%0"
80100f10:	ba fd 03 00 00       	mov    $0x3fd,%edx
80100f15:	ec                   	in     (%dx),%al
static bool serial_exists;

static int
serial_proc_data(void)
{
    if (!(inb(COM1 + COM_LSR) & COM_LSR_DATA))
80100f16:	a8 01                	test   $0x1,%al
80100f18:	74 0a                	je     80100f24 <serial_proc_data+0x14>
80100f1a:	ba f8 03 00 00       	mov    $0x3f8,%edx
80100f1f:	ec                   	in     (%dx),%al
        return -1;
    return inb(COM1 + COM_RX);
80100f20:	0f b6 c0             	movzbl %al,%eax
80100f23:	c3                   	ret    
        return -1;
80100f24:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100f29:	c3                   	ret    

80100f2a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
80100f2a:	55                   	push   %ebp
80100f2b:	89 e5                	mov    %esp,%ebp
80100f2d:	53                   	push   %ebx
80100f2e:	83 ec 04             	sub    $0x4,%esp
80100f31:	89 c3                	mov    %eax,%ebx
    int c;

    while ((c = (*proc)()) != -1) {
80100f33:	eb 23                	jmp    80100f58 <cons_intr+0x2e>
        if (c == 0)
            continue;
        cons.buf[cons.wpos++] = c;
80100f35:	8b 0d 64 49 10 80    	mov    0x80104964,%ecx
80100f3b:	8d 51 01             	lea    0x1(%ecx),%edx
80100f3e:	88 81 60 47 10 80    	mov    %al,-0x7fefb8a0(%ecx)
        if (cons.wpos == CONSBUFSIZE)
80100f44:	81 fa 00 02 00 00    	cmp    $0x200,%edx
            cons.wpos = 0;
80100f4a:	b8 00 00 00 00       	mov    $0x0,%eax
80100f4f:	0f 44 d0             	cmove  %eax,%edx
80100f52:	89 15 64 49 10 80    	mov    %edx,0x80104964
    while ((c = (*proc)()) != -1) {
80100f58:	ff d3                	call   *%ebx
80100f5a:	83 f8 ff             	cmp    $0xffffffff,%eax
80100f5d:	74 06                	je     80100f65 <cons_intr+0x3b>
        if (c == 0)
80100f5f:	85 c0                	test   %eax,%eax
80100f61:	75 d2                	jne    80100f35 <cons_intr+0xb>
80100f63:	eb f3                	jmp    80100f58 <cons_intr+0x2e>
    }
}
80100f65:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100f68:	c9                   	leave  
80100f69:	c3                   	ret    

80100f6a <memset>:
{
80100f6a:	55                   	push   %ebp
80100f6b:	89 e5                	mov    %esp,%ebp
80100f6d:	57                   	push   %edi
80100f6e:	8b 55 08             	mov    0x8(%ebp),%edx
80100f71:	8b 4d 10             	mov    0x10(%ebp),%ecx
    if ((int)dst % 4 == 0 && n % 4 == 0) {
80100f74:	89 d0                	mov    %edx,%eax
80100f76:	09 c8                	or     %ecx,%eax
80100f78:	a8 03                	test   $0x3,%al
80100f7a:	75 14                	jne    80100f90 <memset+0x26>
        stosl(dst, (c << 24) | (c << 16) | (c << 8) | c, n / 4);
80100f7c:	c1 e9 02             	shr    $0x2,%ecx
        c &= 0xFF;
80100f7f:	0f b6 45 0c          	movzbl 0xc(%ebp),%eax
        stosl(dst, (c << 24) | (c << 16) | (c << 8) | c, n / 4);
80100f83:	69 c0 01 01 01 01    	imul   $0x1010101,%eax,%eax
    asm volatile("cld; rep stosl"
80100f89:	89 d7                	mov    %edx,%edi
80100f8b:	fc                   	cld    
80100f8c:	f3 ab                	rep stos %eax,%es:(%edi)
}
80100f8e:	eb 08                	jmp    80100f98 <memset+0x2e>
    asm volatile("cld; rep stosb"
80100f90:	89 d7                	mov    %edx,%edi
80100f92:	8b 45 0c             	mov    0xc(%ebp),%eax
80100f95:	fc                   	cld    
80100f96:	f3 aa                	rep stos %al,%es:(%edi)
}
80100f98:	89 d0                	mov    %edx,%eax
80100f9a:	8b 7d fc             	mov    -0x4(%ebp),%edi
80100f9d:	c9                   	leave  
80100f9e:	c3                   	ret    

80100f9f <memcmp>:
{
80100f9f:	55                   	push   %ebp
80100fa0:	89 e5                	mov    %esp,%ebp
80100fa2:	56                   	push   %esi
80100fa3:	53                   	push   %ebx
80100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa7:	8b 55 0c             	mov    0xc(%ebp),%edx
80100faa:	8b 75 10             	mov    0x10(%ebp),%esi
    while (n-- > 0) {
80100fad:	85 f6                	test   %esi,%esi
80100faf:	74 29                	je     80100fda <memcmp+0x3b>
80100fb1:	01 c6                	add    %eax,%esi
        if (*s1 != *s2)
80100fb3:	0f b6 08             	movzbl (%eax),%ecx
80100fb6:	0f b6 1a             	movzbl (%edx),%ebx
80100fb9:	38 d9                	cmp    %bl,%cl
80100fbb:	75 11                	jne    80100fce <memcmp+0x2f>
        s1++, s2++;
80100fbd:	83 c0 01             	add    $0x1,%eax
80100fc0:	83 c2 01             	add    $0x1,%edx
    while (n-- > 0) {
80100fc3:	39 c6                	cmp    %eax,%esi
80100fc5:	75 ec                	jne    80100fb3 <memcmp+0x14>
    return 0;
80100fc7:	b8 00 00 00 00       	mov    $0x0,%eax
80100fcc:	eb 08                	jmp    80100fd6 <memcmp+0x37>
            return *s1 - *s2;
80100fce:	0f b6 c1             	movzbl %cl,%eax
80100fd1:	0f b6 db             	movzbl %bl,%ebx
80100fd4:	29 d8                	sub    %ebx,%eax
}
80100fd6:	5b                   	pop    %ebx
80100fd7:	5e                   	pop    %esi
80100fd8:	5d                   	pop    %ebp
80100fd9:	c3                   	ret    
    return 0;
80100fda:	b8 00 00 00 00       	mov    $0x0,%eax
80100fdf:	eb f5                	jmp    80100fd6 <memcmp+0x37>

80100fe1 <memmove>:
{
80100fe1:	55                   	push   %ebp
80100fe2:	89 e5                	mov    %esp,%ebp
80100fe4:	56                   	push   %esi
80100fe5:	53                   	push   %ebx
80100fe6:	8b 75 08             	mov    0x8(%ebp),%esi
80100fe9:	8b 45 0c             	mov    0xc(%ebp),%eax
80100fec:	8b 4d 10             	mov    0x10(%ebp),%ecx
    if (s < d && s + n > d) {
80100fef:	39 f0                	cmp    %esi,%eax
80100ff1:	72 20                	jb     80101013 <memmove+0x32>
        while (n-- > 0)
80100ff3:	8d 1c 08             	lea    (%eax,%ecx,1),%ebx
80100ff6:	89 f2                	mov    %esi,%edx
80100ff8:	85 c9                	test   %ecx,%ecx
80100ffa:	74 11                	je     8010100d <memmove+0x2c>
            *d++ = *s++;
80100ffc:	83 c0 01             	add    $0x1,%eax
80100fff:	83 c2 01             	add    $0x1,%edx
80101002:	0f b6 48 ff          	movzbl -0x1(%eax),%ecx
80101006:	88 4a ff             	mov    %cl,-0x1(%edx)
        while (n-- > 0)
80101009:	39 d8                	cmp    %ebx,%eax
8010100b:	75 ef                	jne    80100ffc <memmove+0x1b>
}
8010100d:	89 f0                	mov    %esi,%eax
8010100f:	5b                   	pop    %ebx
80101010:	5e                   	pop    %esi
80101011:	5d                   	pop    %ebp
80101012:	c3                   	ret    
    if (s < d && s + n > d) {
80101013:	8d 14 08             	lea    (%eax,%ecx,1),%edx
80101016:	39 d6                	cmp    %edx,%esi
80101018:	73 d9                	jae    80100ff3 <memmove+0x12>
        while (n-- > 0)
8010101a:	8d 51 ff             	lea    -0x1(%ecx),%edx
8010101d:	85 c9                	test   %ecx,%ecx
8010101f:	74 ec                	je     8010100d <memmove+0x2c>
            *--d = *--s;
80101021:	0f b6 0c 10          	movzbl (%eax,%edx,1),%ecx
80101025:	88 0c 16             	mov    %cl,(%esi,%edx,1)
        while (n-- > 0)
80101028:	83 ea 01             	sub    $0x1,%edx
8010102b:	83 fa ff             	cmp    $0xffffffff,%edx
8010102e:	75 f1                	jne    80101021 <memmove+0x40>
80101030:	eb db                	jmp    8010100d <memmove+0x2c>

80101032 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
80101032:	55                   	push   %ebp
80101033:	89 e5                	mov    %esp,%ebp
80101035:	57                   	push   %edi
80101036:	56                   	push   %esi
80101037:	53                   	push   %ebx
80101038:	83 ec 1c             	sub    $0x1c,%esp
8010103b:	89 c7                	mov    %eax,%edi
    asm volatile("inb %w1,%0"
8010103d:	ba fd 03 00 00       	mov    $0x3fd,%edx
80101042:	ec                   	in     (%dx),%al
         !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
80101043:	a8 20                	test   $0x20,%al
80101045:	75 27                	jne    8010106e <cons_putc+0x3c>
    for (i = 0;
80101047:	bb 00 00 00 00       	mov    $0x0,%ebx
8010104c:	b9 84 00 00 00       	mov    $0x84,%ecx
80101051:	be fd 03 00 00       	mov    $0x3fd,%esi
80101056:	89 ca                	mov    %ecx,%edx
80101058:	ec                   	in     (%dx),%al
80101059:	ec                   	in     (%dx),%al
8010105a:	ec                   	in     (%dx),%al
8010105b:	ec                   	in     (%dx),%al
         i++)
8010105c:	83 c3 01             	add    $0x1,%ebx
8010105f:	89 f2                	mov    %esi,%edx
80101061:	ec                   	in     (%dx),%al
         !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
80101062:	a8 20                	test   $0x20,%al
80101064:	75 08                	jne    8010106e <cons_putc+0x3c>
80101066:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
8010106c:	7e e8                	jle    80101056 <cons_putc+0x24>
    outb(COM1 + COM_TX, c);
8010106e:	89 f8                	mov    %edi,%eax
80101070:	88 45 e7             	mov    %al,-0x19(%ebp)
    asm volatile("outb %0,%w1"
80101073:	ba f8 03 00 00       	mov    $0x3f8,%edx
80101078:	ee                   	out    %al,(%dx)
    asm volatile("inb %w1,%0"
80101079:	ba 79 03 00 00       	mov    $0x379,%edx
8010107e:	ec                   	in     (%dx),%al
    for (i = 0; !(inb(0x378 + 1) & 0x80) && i < 12800; i++)
8010107f:	84 c0                	test   %al,%al
80101081:	78 27                	js     801010aa <cons_putc+0x78>
80101083:	bb 00 00 00 00       	mov    $0x0,%ebx
80101088:	b9 84 00 00 00       	mov    $0x84,%ecx
8010108d:	be 79 03 00 00       	mov    $0x379,%esi
80101092:	89 ca                	mov    %ecx,%edx
80101094:	ec                   	in     (%dx),%al
80101095:	ec                   	in     (%dx),%al
80101096:	ec                   	in     (%dx),%al
80101097:	ec                   	in     (%dx),%al
80101098:	83 c3 01             	add    $0x1,%ebx
8010109b:	89 f2                	mov    %esi,%edx
8010109d:	ec                   	in     (%dx),%al
8010109e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
801010a4:	7f 04                	jg     801010aa <cons_putc+0x78>
801010a6:	84 c0                	test   %al,%al
801010a8:	79 e8                	jns    80101092 <cons_putc+0x60>
    asm volatile("outb %0,%w1"
801010aa:	ba 78 03 00 00       	mov    $0x378,%edx
801010af:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
801010b3:	ee                   	out    %al,(%dx)
801010b4:	ba 7a 03 00 00       	mov    $0x37a,%edx
801010b9:	b8 0d 00 00 00       	mov    $0xd,%eax
801010be:	ee                   	out    %al,(%dx)
801010bf:	b8 08 00 00 00       	mov    $0x8,%eax
801010c4:	ee                   	out    %al,(%dx)
        c |= 0x0700;
801010c5:	89 f8                	mov    %edi,%eax
801010c7:	80 cc 07             	or     $0x7,%ah
801010ca:	81 ff 00 01 00 00    	cmp    $0x100,%edi
801010d0:	0f 42 f8             	cmovb  %eax,%edi
    switch (c & 0xff) {
801010d3:	89 f8                	mov    %edi,%eax
801010d5:	0f b6 c0             	movzbl %al,%eax
801010d8:	89 fb                	mov    %edi,%ebx
801010da:	80 fb 0a             	cmp    $0xa,%bl
801010dd:	0f 84 e4 00 00 00    	je     801011c7 <cons_putc+0x195>
801010e3:	83 f8 0a             	cmp    $0xa,%eax
801010e6:	7f 46                	jg     8010112e <cons_putc+0xfc>
801010e8:	83 f8 08             	cmp    $0x8,%eax
801010eb:	0f 84 aa 00 00 00    	je     8010119b <cons_putc+0x169>
801010f1:	83 f8 09             	cmp    $0x9,%eax
801010f4:	0f 85 da 00 00 00    	jne    801011d4 <cons_putc+0x1a2>
        cons_putc(' ');
801010fa:	b8 20 00 00 00       	mov    $0x20,%eax
801010ff:	e8 2e ff ff ff       	call   80101032 <cons_putc>
        cons_putc(' ');
80101104:	b8 20 00 00 00       	mov    $0x20,%eax
80101109:	e8 24 ff ff ff       	call   80101032 <cons_putc>
        cons_putc(' ');
8010110e:	b8 20 00 00 00       	mov    $0x20,%eax
80101113:	e8 1a ff ff ff       	call   80101032 <cons_putc>
        cons_putc(' ');
80101118:	b8 20 00 00 00       	mov    $0x20,%eax
8010111d:	e8 10 ff ff ff       	call   80101032 <cons_putc>
        cons_putc(' ');
80101122:	b8 20 00 00 00       	mov    $0x20,%eax
80101127:	e8 06 ff ff ff       	call   80101032 <cons_putc>
        break;
8010112c:	eb 25                	jmp    80101153 <cons_putc+0x121>
    switch (c & 0xff) {
8010112e:	83 f8 0d             	cmp    $0xd,%eax
80101131:	0f 85 9d 00 00 00    	jne    801011d4 <cons_putc+0x1a2>
        crt_pos -= (crt_pos % CRT_COLS);
80101137:	0f b7 05 a0 49 10 80 	movzwl 0x801049a0,%eax
8010113e:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
80101144:	c1 e8 16             	shr    $0x16,%eax
80101147:	8d 04 80             	lea    (%eax,%eax,4),%eax
8010114a:	c1 e0 04             	shl    $0x4,%eax
8010114d:	66 a3 a0 49 10 80    	mov    %ax,0x801049a0
    if (crt_pos >= CRT_SIZE) // 当输出字符超过终端范围
80101153:	0f b7 1d a0 49 10 80 	movzwl 0x801049a0,%ebx
8010115a:	66 81 fb cf 07       	cmp    $0x7cf,%bx
8010115f:	0f 87 92 00 00 00    	ja     801011f7 <cons_putc+0x1c5>
    outb(addr_6845, 14);
80101165:	8b 0d a8 49 10 80    	mov    0x801049a8,%ecx
8010116b:	b8 0e 00 00 00       	mov    $0xe,%eax
80101170:	89 ca                	mov    %ecx,%edx
80101172:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos >> 8);
80101173:	0f b7 1d a0 49 10 80 	movzwl 0x801049a0,%ebx
8010117a:	8d 71 01             	lea    0x1(%ecx),%esi
8010117d:	89 d8                	mov    %ebx,%eax
8010117f:	66 c1 e8 08          	shr    $0x8,%ax
80101183:	89 f2                	mov    %esi,%edx
80101185:	ee                   	out    %al,(%dx)
80101186:	b8 0f 00 00 00       	mov    $0xf,%eax
8010118b:	89 ca                	mov    %ecx,%edx
8010118d:	ee                   	out    %al,(%dx)
8010118e:	89 d8                	mov    %ebx,%eax
80101190:	89 f2                	mov    %esi,%edx
80101192:	ee                   	out    %al,(%dx)
    serial_putc(c); // 向串口输出
    lpt_putc(c);
    cga_putc(c); // 向控制台输出字符
}
80101193:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101196:	5b                   	pop    %ebx
80101197:	5e                   	pop    %esi
80101198:	5f                   	pop    %edi
80101199:	5d                   	pop    %ebp
8010119a:	c3                   	ret    
        if (crt_pos > 0) {
8010119b:	0f b7 05 a0 49 10 80 	movzwl 0x801049a0,%eax
801011a2:	66 85 c0             	test   %ax,%ax
801011a5:	74 be                	je     80101165 <cons_putc+0x133>
            crt_pos--;
801011a7:	83 e8 01             	sub    $0x1,%eax
801011aa:	66 a3 a0 49 10 80    	mov    %ax,0x801049a0
            crt_buf[crt_pos] = (c & ~0xff) | ' ';
801011b0:	0f b7 c0             	movzwl %ax,%eax
801011b3:	66 81 e7 00 ff       	and    $0xff00,%di
801011b8:	83 cf 20             	or     $0x20,%edi
801011bb:	8b 15 a4 49 10 80    	mov    0x801049a4,%edx
801011c1:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
801011c5:	eb 8c                	jmp    80101153 <cons_putc+0x121>
        crt_pos += CRT_COLS;
801011c7:	66 83 05 a0 49 10 80 	addw   $0x50,0x801049a0
801011ce:	50 
801011cf:	e9 63 ff ff ff       	jmp    80101137 <cons_putc+0x105>
        crt_buf[crt_pos++] = c; /* write the character */
801011d4:	0f b7 05 a0 49 10 80 	movzwl 0x801049a0,%eax
801011db:	8d 50 01             	lea    0x1(%eax),%edx
801011de:	66 89 15 a0 49 10 80 	mov    %dx,0x801049a0
801011e5:	0f b7 c0             	movzwl %ax,%eax
801011e8:	8b 15 a4 49 10 80    	mov    0x801049a4,%edx
801011ee:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
        break;
801011f2:	e9 5c ff ff ff       	jmp    80101153 <cons_putc+0x121>
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t)); // 已有字符往上移动一行
801011f7:	8b 35 a4 49 10 80    	mov    0x801049a4,%esi
801011fd:	83 ec 04             	sub    $0x4,%esp
80101200:	68 00 0f 00 00       	push   $0xf00
80101205:	8d 86 a0 00 00 00    	lea    0xa0(%esi),%eax
8010120b:	50                   	push   %eax
8010120c:	56                   	push   %esi
8010120d:	e8 cf fd ff ff       	call   80100fe1 <memmove>
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++) // 清零最后一行
80101212:	8d 86 00 0f 00 00    	lea    0xf00(%esi),%eax
80101218:	8d 96 a0 0f 00 00    	lea    0xfa0(%esi),%edx
8010121e:	83 c4 10             	add    $0x10,%esp
            crt_buf[i] = 0x0700 | ' ';
80101221:	66 c7 00 20 07       	movw   $0x720,(%eax)
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++) // 清零最后一行
80101226:	83 c0 02             	add    $0x2,%eax
80101229:	39 d0                	cmp    %edx,%eax
8010122b:	75 f4                	jne    80101221 <cons_putc+0x1ef>
        crt_pos -= CRT_COLS; // 索引向前移动，即从最后一行的开头写入
8010122d:	83 eb 50             	sub    $0x50,%ebx
80101230:	66 89 1d a0 49 10 80 	mov    %bx,0x801049a0
80101237:	e9 29 ff ff ff       	jmp    80101165 <cons_putc+0x133>

8010123c <printint>:
    return 1;
}

static void
printint(int xx, int base, int sign)
{
8010123c:	55                   	push   %ebp
8010123d:	89 e5                	mov    %esp,%ebp
8010123f:	57                   	push   %edi
80101240:	56                   	push   %esi
80101241:	53                   	push   %ebx
80101242:	83 ec 2c             	sub    $0x2c,%esp
80101245:	89 d3                	mov    %edx,%ebx
    static char digits[] = "0123456789abcdef";
    char buf[16];
    int i;
    uint32_t x;

    if (sign && (sign = xx < 0))
80101247:	85 c9                	test   %ecx,%ecx
80101249:	74 04                	je     8010124f <printint+0x13>
8010124b:	85 c0                	test   %eax,%eax
8010124d:	78 61                	js     801012b0 <printint+0x74>
        x = -xx;
    else
        x = xx;
8010124f:	89 c1                	mov    %eax,%ecx
80101251:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

    i = 0;
80101258:	bf 00 00 00 00       	mov    $0x0,%edi
    do {
        buf[i++] = digits[x % base];
8010125d:	89 fe                	mov    %edi,%esi
8010125f:	83 c7 01             	add    $0x1,%edi
80101262:	89 c8                	mov    %ecx,%eax
80101264:	ba 00 00 00 00       	mov    $0x0,%edx
80101269:	f7 f3                	div    %ebx
8010126b:	0f b6 92 00 1a 10 80 	movzbl -0x7fefe600(%edx),%edx
80101272:	88 54 3d d7          	mov    %dl,-0x29(%ebp,%edi,1)
    } while ((x /= base) != 0);
80101276:	89 ca                	mov    %ecx,%edx
80101278:	89 c1                	mov    %eax,%ecx
8010127a:	39 da                	cmp    %ebx,%edx
8010127c:	73 df                	jae    8010125d <printint+0x21>

    if (sign)
8010127e:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80101282:	74 08                	je     8010128c <printint+0x50>
        buf[i++] = '-';
80101284:	c6 44 3d d8 2d       	movb   $0x2d,-0x28(%ebp,%edi,1)
80101289:	8d 7e 02             	lea    0x2(%esi),%edi

    while (--i >= 0)
8010128c:	85 ff                	test   %edi,%edi
8010128e:	7e 18                	jle    801012a8 <printint+0x6c>
80101290:	8d 75 d8             	lea    -0x28(%ebp),%esi
80101293:	8d 5c 3d d7          	lea    -0x29(%ebp,%edi,1),%ebx
        cons_putc(buf[i]);
80101297:	0f be 03             	movsbl (%ebx),%eax
8010129a:	e8 93 fd ff ff       	call   80101032 <cons_putc>
    while (--i >= 0)
8010129f:	89 d8                	mov    %ebx,%eax
801012a1:	83 eb 01             	sub    $0x1,%ebx
801012a4:	39 f0                	cmp    %esi,%eax
801012a6:	75 ef                	jne    80101297 <printint+0x5b>
}
801012a8:	83 c4 2c             	add    $0x2c,%esp
801012ab:	5b                   	pop    %ebx
801012ac:	5e                   	pop    %esi
801012ad:	5f                   	pop    %edi
801012ae:	5d                   	pop    %ebp
801012af:	c3                   	ret    
        x = -xx;
801012b0:	f7 d8                	neg    %eax
801012b2:	89 c1                	mov    %eax,%ecx
    if (sign && (sign = xx < 0))
801012b4:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
        x = -xx;
801012bb:	eb 9b                	jmp    80101258 <printint+0x1c>

801012bd <memcpy>:
{
801012bd:	55                   	push   %ebp
801012be:	89 e5                	mov    %esp,%ebp
801012c0:	83 ec 0c             	sub    $0xc,%esp
    return memmove(dst, src, n);
801012c3:	ff 75 10             	push   0x10(%ebp)
801012c6:	ff 75 0c             	push   0xc(%ebp)
801012c9:	ff 75 08             	push   0x8(%ebp)
801012cc:	e8 10 fd ff ff       	call   80100fe1 <memmove>
}
801012d1:	c9                   	leave  
801012d2:	c3                   	ret    

801012d3 <strncmp>:
{
801012d3:	55                   	push   %ebp
801012d4:	89 e5                	mov    %esp,%ebp
801012d6:	53                   	push   %ebx
801012d7:	8b 55 08             	mov    0x8(%ebp),%edx
801012da:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801012dd:	8b 45 10             	mov    0x10(%ebp),%eax
    while (n > 0 && *p && *p == *q)
801012e0:	85 c0                	test   %eax,%eax
801012e2:	74 29                	je     8010130d <strncmp+0x3a>
801012e4:	0f b6 1a             	movzbl (%edx),%ebx
801012e7:	84 db                	test   %bl,%bl
801012e9:	74 16                	je     80101301 <strncmp+0x2e>
801012eb:	3a 19                	cmp    (%ecx),%bl
801012ed:	75 12                	jne    80101301 <strncmp+0x2e>
        n--, p++, q++;
801012ef:	83 c2 01             	add    $0x1,%edx
801012f2:	83 c1 01             	add    $0x1,%ecx
    while (n > 0 && *p && *p == *q)
801012f5:	83 e8 01             	sub    $0x1,%eax
801012f8:	75 ea                	jne    801012e4 <strncmp+0x11>
        return 0;
801012fa:	b8 00 00 00 00       	mov    $0x0,%eax
801012ff:	eb 0c                	jmp    8010130d <strncmp+0x3a>
    if (n == 0)
80101301:	85 c0                	test   %eax,%eax
80101303:	74 0d                	je     80101312 <strncmp+0x3f>
    return (uint8_t)*p - (uint8_t)*q;
80101305:	0f b6 02             	movzbl (%edx),%eax
80101308:	0f b6 11             	movzbl (%ecx),%edx
8010130b:	29 d0                	sub    %edx,%eax
}
8010130d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101310:	c9                   	leave  
80101311:	c3                   	ret    
        return 0;
80101312:	b8 00 00 00 00       	mov    $0x0,%eax
80101317:	eb f4                	jmp    8010130d <strncmp+0x3a>

80101319 <strncpy>:
{
80101319:	55                   	push   %ebp
8010131a:	89 e5                	mov    %esp,%ebp
8010131c:	57                   	push   %edi
8010131d:	56                   	push   %esi
8010131e:	53                   	push   %ebx
8010131f:	8b 75 08             	mov    0x8(%ebp),%esi
80101322:	8b 55 10             	mov    0x10(%ebp),%edx
    while (n-- > 0 && (*s++ = *t++) != 0)
80101325:	89 f1                	mov    %esi,%ecx
80101327:	89 d3                	mov    %edx,%ebx
80101329:	83 ea 01             	sub    $0x1,%edx
8010132c:	85 db                	test   %ebx,%ebx
8010132e:	7e 17                	jle    80101347 <strncpy+0x2e>
80101330:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80101334:	83 c1 01             	add    $0x1,%ecx
80101337:	8b 45 0c             	mov    0xc(%ebp),%eax
8010133a:	0f b6 78 ff          	movzbl -0x1(%eax),%edi
8010133e:	89 f8                	mov    %edi,%eax
80101340:	88 41 ff             	mov    %al,-0x1(%ecx)
80101343:	84 c0                	test   %al,%al
80101345:	75 e0                	jne    80101327 <strncpy+0xe>
    while (n-- > 0)
80101347:	89 c8                	mov    %ecx,%eax
80101349:	8d 4c 19 ff          	lea    -0x1(%ecx,%ebx,1),%ecx
8010134d:	85 d2                	test   %edx,%edx
8010134f:	7e 0f                	jle    80101360 <strncpy+0x47>
        *s++ = 0;
80101351:	83 c0 01             	add    $0x1,%eax
80101354:	c6 40 ff 00          	movb   $0x0,-0x1(%eax)
    while (n-- > 0)
80101358:	89 ca                	mov    %ecx,%edx
8010135a:	29 c2                	sub    %eax,%edx
8010135c:	85 d2                	test   %edx,%edx
8010135e:	7f f1                	jg     80101351 <strncpy+0x38>
}
80101360:	89 f0                	mov    %esi,%eax
80101362:	5b                   	pop    %ebx
80101363:	5e                   	pop    %esi
80101364:	5f                   	pop    %edi
80101365:	5d                   	pop    %ebp
80101366:	c3                   	ret    

80101367 <safestrcpy>:
{
80101367:	55                   	push   %ebp
80101368:	89 e5                	mov    %esp,%ebp
8010136a:	56                   	push   %esi
8010136b:	53                   	push   %ebx
8010136c:	8b 75 08             	mov    0x8(%ebp),%esi
8010136f:	8b 45 0c             	mov    0xc(%ebp),%eax
80101372:	8b 55 10             	mov    0x10(%ebp),%edx
    if (n <= 0)
80101375:	85 d2                	test   %edx,%edx
80101377:	7e 1e                	jle    80101397 <safestrcpy+0x30>
80101379:	8d 5c 10 ff          	lea    -0x1(%eax,%edx,1),%ebx
8010137d:	89 f2                	mov    %esi,%edx
    while (--n > 0 && (*s++ = *t++) != 0)
8010137f:	39 d8                	cmp    %ebx,%eax
80101381:	74 11                	je     80101394 <safestrcpy+0x2d>
80101383:	83 c0 01             	add    $0x1,%eax
80101386:	83 c2 01             	add    $0x1,%edx
80101389:	0f b6 48 ff          	movzbl -0x1(%eax),%ecx
8010138d:	88 4a ff             	mov    %cl,-0x1(%edx)
80101390:	84 c9                	test   %cl,%cl
80101392:	75 eb                	jne    8010137f <safestrcpy+0x18>
    *s = 0;
80101394:	c6 02 00             	movb   $0x0,(%edx)
}
80101397:	89 f0                	mov    %esi,%eax
80101399:	5b                   	pop    %ebx
8010139a:	5e                   	pop    %esi
8010139b:	5d                   	pop    %ebp
8010139c:	c3                   	ret    

8010139d <strlen>:
{
8010139d:	55                   	push   %ebp
8010139e:	89 e5                	mov    %esp,%ebp
801013a0:	8b 55 08             	mov    0x8(%ebp),%edx
    for (n = 0; s[n]; n++)
801013a3:	80 3a 00             	cmpb   $0x0,(%edx)
801013a6:	74 10                	je     801013b8 <strlen+0x1b>
801013a8:	b8 00 00 00 00       	mov    $0x0,%eax
801013ad:	83 c0 01             	add    $0x1,%eax
801013b0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
801013b4:	75 f7                	jne    801013ad <strlen+0x10>
}
801013b6:	5d                   	pop    %ebp
801013b7:	c3                   	ret    
    for (n = 0; s[n]; n++)
801013b8:	b8 00 00 00 00       	mov    $0x0,%eax
    return n;
801013bd:	eb f7                	jmp    801013b6 <strlen+0x19>

801013bf <serial_intr>:
    if (serial_exists)
801013bf:	80 3d ac 49 10 80 00 	cmpb   $0x0,0x801049ac
801013c6:	75 01                	jne    801013c9 <serial_intr+0xa>
801013c8:	c3                   	ret    
{
801013c9:	55                   	push   %ebp
801013ca:	89 e5                	mov    %esp,%ebp
801013cc:	83 ec 08             	sub    $0x8,%esp
        cons_intr(serial_proc_data);
801013cf:	b8 10 0f 10 80       	mov    $0x80100f10,%eax
801013d4:	e8 51 fb ff ff       	call   80100f2a <cons_intr>
}
801013d9:	c9                   	leave  
801013da:	c3                   	ret    

801013db <kbd_intr>:
{
801013db:	55                   	push   %ebp
801013dc:	89 e5                	mov    %esp,%ebp
801013de:	83 ec 08             	sub    $0x8,%esp
    cons_intr(kbd_proc_data);
801013e1:	b8 b5 15 10 80       	mov    $0x801015b5,%eax
801013e6:	e8 3f fb ff ff       	call   80100f2a <cons_intr>
}
801013eb:	c9                   	leave  
801013ec:	c3                   	ret    

801013ed <cons_getc>:
{
801013ed:	55                   	push   %ebp
801013ee:	89 e5                	mov    %esp,%ebp
801013f0:	83 ec 08             	sub    $0x8,%esp
    serial_intr();
801013f3:	e8 c7 ff ff ff       	call   801013bf <serial_intr>
    kbd_intr();
801013f8:	e8 de ff ff ff       	call   801013db <kbd_intr>
    if (cons.rpos != cons.wpos) {
801013fd:	a1 60 49 10 80       	mov    0x80104960,%eax
    return 0;
80101402:	ba 00 00 00 00       	mov    $0x0,%edx
    if (cons.rpos != cons.wpos) {
80101407:	3b 05 64 49 10 80    	cmp    0x80104964,%eax
8010140d:	74 1c                	je     8010142b <cons_getc+0x3e>
        c = cons.buf[cons.rpos++];
8010140f:	8d 48 01             	lea    0x1(%eax),%ecx
80101412:	0f b6 90 60 47 10 80 	movzbl -0x7fefb8a0(%eax),%edx
            cons.rpos = 0;
80101419:	3d ff 01 00 00       	cmp    $0x1ff,%eax
8010141e:	b8 00 00 00 00       	mov    $0x0,%eax
80101423:	0f 45 c1             	cmovne %ecx,%eax
80101426:	a3 60 49 10 80       	mov    %eax,0x80104960
}
8010142b:	89 d0                	mov    %edx,%eax
8010142d:	c9                   	leave  
8010142e:	c3                   	ret    

8010142f <cons_uselock>:
void cons_uselock() { cons.use_lock = 1; }
8010142f:	c7 05 9c 49 10 80 01 	movl   $0x1,0x8010499c
80101436:	00 00 00 
80101439:	c3                   	ret    

8010143a <cputchar>:
{
8010143a:	55                   	push   %ebp
8010143b:	89 e5                	mov    %esp,%ebp
8010143d:	83 ec 08             	sub    $0x8,%esp
    cons_putc(c);
80101440:	8b 45 08             	mov    0x8(%ebp),%eax
80101443:	e8 ea fb ff ff       	call   80101032 <cons_putc>
}
80101448:	c9                   	leave  
80101449:	c3                   	ret    

8010144a <getchar>:
{
8010144a:	55                   	push   %ebp
8010144b:	89 e5                	mov    %esp,%ebp
8010144d:	83 ec 08             	sub    $0x8,%esp
    while ((c = cons_getc()) == 0)
80101450:	e8 98 ff ff ff       	call   801013ed <cons_getc>
80101455:	85 c0                	test   %eax,%eax
80101457:	74 f7                	je     80101450 <getchar+0x6>
}
80101459:	c9                   	leave  
8010145a:	c3                   	ret    

8010145b <iscons>:
}
8010145b:	b8 01 00 00 00       	mov    $0x1,%eax
80101460:	c3                   	ret    

80101461 <cprintf>:

void cprintf(char* fmt, ...)
{
80101461:	55                   	push   %ebp
80101462:	89 e5                	mov    %esp,%ebp
80101464:	57                   	push   %edi
80101465:	56                   	push   %esi
80101466:	53                   	push   %ebx
80101467:	83 ec 1c             	sub    $0x1c,%esp
    int i, c;
    uint32_t* argp;
    char* s;

    if (cons.use_lock)
8010146a:	83 3d 9c 49 10 80 00 	cmpl   $0x0,0x8010499c
80101471:	75 17                	jne    8010148a <cprintf+0x29>
        acquire(&cons.lock);

    argp = (uint32_t*)(void*)(&fmt + 1);
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++) {
80101473:	8b 7d 08             	mov    0x8(%ebp),%edi
80101476:	0f b6 07             	movzbl (%edi),%eax
80101479:	85 c0                	test   %eax,%eax
8010147b:	74 34                	je     801014b1 <cprintf+0x50>
{
8010147d:	8d 4d 0c             	lea    0xc(%ebp),%ecx
80101480:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
80101483:	be 00 00 00 00       	mov    $0x0,%esi
80101488:	eb 3f                	jmp    801014c9 <cprintf+0x68>
        acquire(&cons.lock);
8010148a:	83 ec 0c             	sub    $0xc,%esp
8010148d:	68 68 49 10 80       	push   $0x80104968
80101492:	e8 31 f2 ff ff       	call   801006c8 <acquire>
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++) {
80101497:	8b 7d 08             	mov    0x8(%ebp),%edi
8010149a:	0f b6 07             	movzbl (%edi),%eax
8010149d:	83 c4 10             	add    $0x10,%esp
801014a0:	85 c0                	test   %eax,%eax
801014a2:	75 d9                	jne    8010147d <cprintf+0x1c>
            cons_putc(c);
            break;
        }
    }

    if (cons.use_lock)
801014a4:	83 3d 9c 49 10 80 00 	cmpl   $0x0,0x8010499c
801014ab:	0f 85 ef 00 00 00    	jne    801015a0 <cprintf+0x13f>
        release(&cons.lock);
}
801014b1:	8d 65 f4             	lea    -0xc(%ebp),%esp
801014b4:	5b                   	pop    %ebx
801014b5:	5e                   	pop    %esi
801014b6:	5f                   	pop    %edi
801014b7:	5d                   	pop    %ebp
801014b8:	c3                   	ret    
            cons_putc(c);
801014b9:	e8 74 fb ff ff       	call   80101032 <cons_putc>
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++) {
801014be:	83 c6 01             	add    $0x1,%esi
801014c1:	0f b6 04 37          	movzbl (%edi,%esi,1),%eax
801014c5:	85 c0                	test   %eax,%eax
801014c7:	74 db                	je     801014a4 <cprintf+0x43>
        if (c != '%') {
801014c9:	83 f8 25             	cmp    $0x25,%eax
801014cc:	75 eb                	jne    801014b9 <cprintf+0x58>
        c = fmt[++i] & 0xff;
801014ce:	83 c6 01             	add    $0x1,%esi
801014d1:	0f b6 1c 37          	movzbl (%edi,%esi,1),%ebx
        if (c == 0)
801014d5:	85 db                	test   %ebx,%ebx
801014d7:	74 cb                	je     801014a4 <cprintf+0x43>
        switch (c) {
801014d9:	83 fb 70             	cmp    $0x70,%ebx
801014dc:	74 3a                	je     80101518 <cprintf+0xb7>
801014de:	7f 2e                	jg     8010150e <cprintf+0xad>
801014e0:	83 fb 25             	cmp    $0x25,%ebx
801014e3:	0f 84 92 00 00 00    	je     8010157b <cprintf+0x11a>
801014e9:	83 fb 64             	cmp    $0x64,%ebx
801014ec:	0f 85 98 00 00 00    	jne    8010158a <cprintf+0x129>
            printint(*argp++, 10, 1);
801014f2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801014f5:	8d 58 04             	lea    0x4(%eax),%ebx
801014f8:	8b 00                	mov    (%eax),%eax
801014fa:	b9 01 00 00 00       	mov    $0x1,%ecx
801014ff:	ba 0a 00 00 00       	mov    $0xa,%edx
80101504:	e8 33 fd ff ff       	call   8010123c <printint>
80101509:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
            break;
8010150c:	eb b0                	jmp    801014be <cprintf+0x5d>
        switch (c) {
8010150e:	83 fb 73             	cmp    $0x73,%ebx
80101511:	74 21                	je     80101534 <cprintf+0xd3>
80101513:	83 fb 78             	cmp    $0x78,%ebx
80101516:	75 72                	jne    8010158a <cprintf+0x129>
            printint(*argp++, 16, 0);
80101518:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010151b:	8d 58 04             	lea    0x4(%eax),%ebx
8010151e:	8b 00                	mov    (%eax),%eax
80101520:	b9 00 00 00 00       	mov    $0x0,%ecx
80101525:	ba 10 00 00 00       	mov    $0x10,%edx
8010152a:	e8 0d fd ff ff       	call   8010123c <printint>
8010152f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
            break;
80101532:	eb 8a                	jmp    801014be <cprintf+0x5d>
            if ((s = (char*)*argp++) == 0)
80101534:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101537:	8d 50 04             	lea    0x4(%eax),%edx
8010153a:	89 55 e0             	mov    %edx,-0x20(%ebp)
8010153d:	8b 00                	mov    (%eax),%eax
8010153f:	85 c0                	test   %eax,%eax
80101541:	74 11                	je     80101554 <cprintf+0xf3>
80101543:	89 c3                	mov    %eax,%ebx
            for (; *s; s++)
80101545:	0f b6 00             	movzbl (%eax),%eax
            if ((s = (char*)*argp++) == 0)
80101548:	89 55 e4             	mov    %edx,-0x1c(%ebp)
            for (; *s; s++)
8010154b:	84 c0                	test   %al,%al
8010154d:	75 0f                	jne    8010155e <cprintf+0xfd>
8010154f:	e9 6a ff ff ff       	jmp    801014be <cprintf+0x5d>
                s = "(null)";
80101554:	bb b7 19 10 80       	mov    $0x801019b7,%ebx
            for (; *s; s++)
80101559:	b8 28 00 00 00       	mov    $0x28,%eax
                cons_putc(*s);
8010155e:	0f be c0             	movsbl %al,%eax
80101561:	e8 cc fa ff ff       	call   80101032 <cons_putc>
            for (; *s; s++)
80101566:	83 c3 01             	add    $0x1,%ebx
80101569:	0f b6 03             	movzbl (%ebx),%eax
8010156c:	84 c0                	test   %al,%al
8010156e:	75 ee                	jne    8010155e <cprintf+0xfd>
            if ((s = (char*)*argp++) == 0)
80101570:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101573:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80101576:	e9 43 ff ff ff       	jmp    801014be <cprintf+0x5d>
            cons_putc('%');
8010157b:	b8 25 00 00 00       	mov    $0x25,%eax
80101580:	e8 ad fa ff ff       	call   80101032 <cons_putc>
            break;
80101585:	e9 34 ff ff ff       	jmp    801014be <cprintf+0x5d>
            cons_putc('%');
8010158a:	b8 25 00 00 00       	mov    $0x25,%eax
8010158f:	e8 9e fa ff ff       	call   80101032 <cons_putc>
            cons_putc(c);
80101594:	89 d8                	mov    %ebx,%eax
80101596:	e8 97 fa ff ff       	call   80101032 <cons_putc>
            break;
8010159b:	e9 1e ff ff ff       	jmp    801014be <cprintf+0x5d>
        release(&cons.lock);
801015a0:	83 ec 0c             	sub    $0xc,%esp
801015a3:	68 68 49 10 80       	push   $0x80104968
801015a8:	e8 75 f1 ff ff       	call   80100722 <release>
801015ad:	83 c4 10             	add    $0x10,%esp
}
801015b0:	e9 fc fe ff ff       	jmp    801014b1 <cprintf+0x50>

801015b5 <kbd_proc_data>:
{
801015b5:	55                   	push   %ebp
801015b6:	89 e5                	mov    %esp,%ebp
801015b8:	53                   	push   %ebx
801015b9:	83 ec 04             	sub    $0x4,%esp
    asm volatile("inb %w1,%0"
801015bc:	ba 64 00 00 00       	mov    $0x64,%edx
801015c1:	ec                   	in     (%dx),%al
    if ((stat & KBS_DIB) == 0)
801015c2:	a8 01                	test   $0x1,%al
801015c4:	0f 84 ee 00 00 00    	je     801016b8 <kbd_proc_data+0x103>
    if (stat & KBS_TERR)
801015ca:	a8 20                	test   $0x20,%al
801015cc:	0f 85 ed 00 00 00    	jne    801016bf <kbd_proc_data+0x10a>
801015d2:	ba 60 00 00 00       	mov    $0x60,%edx
801015d7:	ec                   	in     (%dx),%al
801015d8:	89 c2                	mov    %eax,%edx
    if (data == 0xE0) {
801015da:	3c e0                	cmp    $0xe0,%al
801015dc:	74 61                	je     8010163f <kbd_proc_data+0x8a>
    } else if (data & 0x80) {
801015de:	84 c0                	test   %al,%al
801015e0:	78 70                	js     80101652 <kbd_proc_data+0x9d>
    } else if (shift & E0ESC) {
801015e2:	8b 0d 40 47 10 80    	mov    0x80104740,%ecx
801015e8:	f6 c1 40             	test   $0x40,%cl
801015eb:	74 0e                	je     801015fb <kbd_proc_data+0x46>
        data |= 0x80;
801015ed:	83 c8 80             	or     $0xffffff80,%eax
801015f0:	89 c2                	mov    %eax,%edx
        shift &= ~E0ESC;
801015f2:	83 e1 bf             	and    $0xffffffbf,%ecx
801015f5:	89 0d 40 47 10 80    	mov    %ecx,0x80104740
    shift |= shiftcode[data];
801015fb:	0f b6 d2             	movzbl %dl,%edx
801015fe:	0f b6 82 40 1b 10 80 	movzbl -0x7fefe4c0(%edx),%eax
80101605:	0b 05 40 47 10 80    	or     0x80104740,%eax
    shift ^= togglecode[data];
8010160b:	0f b6 8a 40 1a 10 80 	movzbl -0x7fefe5c0(%edx),%ecx
80101612:	31 c8                	xor    %ecx,%eax
80101614:	a3 40 47 10 80       	mov    %eax,0x80104740
    c = charcode[shift & (CTL | SHIFT)][data];
80101619:	89 c1                	mov    %eax,%ecx
8010161b:	83 e1 03             	and    $0x3,%ecx
8010161e:	8b 0c 8d 14 1a 10 80 	mov    -0x7fefe5ec(,%ecx,4),%ecx
80101625:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
80101629:	0f b6 da             	movzbl %dl,%ebx
    if (shift & CAPSLOCK) {
8010162c:	a8 08                	test   $0x8,%al
8010162e:	74 5d                	je     8010168d <kbd_proc_data+0xd8>
        if ('a' <= c && c <= 'z')
80101630:	89 da                	mov    %ebx,%edx
80101632:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
80101635:	83 f9 19             	cmp    $0x19,%ecx
80101638:	77 47                	ja     80101681 <kbd_proc_data+0xcc>
            c += 'A' - 'a';
8010163a:	83 eb 20             	sub    $0x20,%ebx
    if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
8010163d:	eb 0c                	jmp    8010164b <kbd_proc_data+0x96>
        shift |= E0ESC;
8010163f:	83 0d 40 47 10 80 40 	orl    $0x40,0x80104740
        return 0;
80101646:	bb 00 00 00 00       	mov    $0x0,%ebx
}
8010164b:	89 d8                	mov    %ebx,%eax
8010164d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101650:	c9                   	leave  
80101651:	c3                   	ret    
        data = (shift & E0ESC ? data : data & 0x7F);
80101652:	8b 0d 40 47 10 80    	mov    0x80104740,%ecx
80101658:	83 e0 7f             	and    $0x7f,%eax
8010165b:	f6 c1 40             	test   $0x40,%cl
8010165e:	0f 44 d0             	cmove  %eax,%edx
        shift &= ~(shiftcode[data] | E0ESC);
80101661:	0f b6 d2             	movzbl %dl,%edx
80101664:	0f b6 82 40 1b 10 80 	movzbl -0x7fefe4c0(%edx),%eax
8010166b:	83 c8 40             	or     $0x40,%eax
8010166e:	0f b6 c0             	movzbl %al,%eax
80101671:	f7 d0                	not    %eax
80101673:	21 c8                	and    %ecx,%eax
80101675:	a3 40 47 10 80       	mov    %eax,0x80104740
        return 0;
8010167a:	bb 00 00 00 00       	mov    $0x0,%ebx
8010167f:	eb ca                	jmp    8010164b <kbd_proc_data+0x96>
        else if ('A' <= c && c <= 'Z')
80101681:	83 ea 41             	sub    $0x41,%edx
            c += 'a' - 'A';
80101684:	8d 4b 20             	lea    0x20(%ebx),%ecx
80101687:	83 fa 1a             	cmp    $0x1a,%edx
8010168a:	0f 42 d9             	cmovb  %ecx,%ebx
    if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
8010168d:	f7 d0                	not    %eax
8010168f:	a8 06                	test   $0x6,%al
80101691:	75 b8                	jne    8010164b <kbd_proc_data+0x96>
80101693:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
80101699:	75 b0                	jne    8010164b <kbd_proc_data+0x96>
        cprintf("Rebooting!\n");
8010169b:	83 ec 0c             	sub    $0xc,%esp
8010169e:	68 be 19 10 80       	push   $0x801019be
801016a3:	e8 b9 fd ff ff       	call   80101461 <cprintf>
    asm volatile("outb %0,%w1"
801016a8:	b8 03 00 00 00       	mov    $0x3,%eax
801016ad:	ba 92 00 00 00       	mov    $0x92,%edx
801016b2:	ee                   	out    %al,(%dx)
}
801016b3:	83 c4 10             	add    $0x10,%esp
801016b6:	eb 93                	jmp    8010164b <kbd_proc_data+0x96>
        return -1;
801016b8:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801016bd:	eb 8c                	jmp    8010164b <kbd_proc_data+0x96>
        return -1;
801016bf:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801016c4:	eb 85                	jmp    8010164b <kbd_proc_data+0x96>

801016c6 <cons_init>:
{
801016c6:	55                   	push   %ebp
801016c7:	89 e5                	mov    %esp,%ebp
801016c9:	57                   	push   %edi
801016ca:	56                   	push   %esi
801016cb:	53                   	push   %ebx
801016cc:	83 ec 14             	sub    $0x14,%esp
    initlock(&cons.lock, "console");
801016cf:	68 ca 19 10 80       	push   $0x801019ca
801016d4:	68 68 49 10 80       	push   $0x80104968
801016d9:	e8 a8 ee ff ff       	call   80100586 <initlock>
    cons.use_lock = 0;
801016de:	c7 05 9c 49 10 80 00 	movl   $0x0,0x8010499c
801016e5:	00 00 00 
    was = *cp;
801016e8:	0f b7 15 00 80 0b 80 	movzwl 0x800b8000,%edx
    *cp = (uint16_t)0xA55A;
801016ef:	66 c7 05 00 80 0b 80 	movw   $0xa55a,0x800b8000
801016f6:	5a a5 
    if (*cp != 0xA55A) {
801016f8:	0f b7 05 00 80 0b 80 	movzwl 0x800b8000,%eax
801016ff:	83 c4 10             	add    $0x10,%esp
80101702:	bb b4 03 00 00       	mov    $0x3b4,%ebx
        cp = (uint16_t*)(K_ADDR_BASE + MONO_BUF);
80101707:	be 00 00 0b 80       	mov    $0x800b0000,%esi
    if (*cp != 0xA55A) {
8010170c:	66 3d 5a a5          	cmp    $0xa55a,%ax
80101710:	0f 84 ab 00 00 00    	je     801017c1 <cons_init+0xfb>
        addr_6845 = MONO_BASE;
80101716:	89 1d a8 49 10 80    	mov    %ebx,0x801049a8
    asm volatile("outb %0,%w1"
8010171c:	b8 0e 00 00 00       	mov    $0xe,%eax
80101721:	89 da                	mov    %ebx,%edx
80101723:	ee                   	out    %al,(%dx)
    pos = inb(addr_6845 + 1) << 8;
80101724:	8d 7b 01             	lea    0x1(%ebx),%edi
    asm volatile("inb %w1,%0"
80101727:	89 fa                	mov    %edi,%edx
80101729:	ec                   	in     (%dx),%al
8010172a:	0f b6 c8             	movzbl %al,%ecx
8010172d:	c1 e1 08             	shl    $0x8,%ecx
    asm volatile("outb %0,%w1"
80101730:	b8 0f 00 00 00       	mov    $0xf,%eax
80101735:	89 da                	mov    %ebx,%edx
80101737:	ee                   	out    %al,(%dx)
    asm volatile("inb %w1,%0"
80101738:	89 fa                	mov    %edi,%edx
8010173a:	ec                   	in     (%dx),%al
    crt_buf = (uint16_t*)cp;
8010173b:	89 35 a4 49 10 80    	mov    %esi,0x801049a4
    pos |= inb(addr_6845 + 1);
80101741:	0f b6 c0             	movzbl %al,%eax
80101744:	09 c8                	or     %ecx,%eax
    crt_pos = pos;
80101746:	66 a3 a0 49 10 80    	mov    %ax,0x801049a0
    kbd_intr();
8010174c:	e8 8a fc ff ff       	call   801013db <kbd_intr>
    asm volatile("outb %0,%w1"
80101751:	b9 00 00 00 00       	mov    $0x0,%ecx
80101756:	bb fa 03 00 00       	mov    $0x3fa,%ebx
8010175b:	89 c8                	mov    %ecx,%eax
8010175d:	89 da                	mov    %ebx,%edx
8010175f:	ee                   	out    %al,(%dx)
80101760:	bf fb 03 00 00       	mov    $0x3fb,%edi
80101765:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
8010176a:	89 fa                	mov    %edi,%edx
8010176c:	ee                   	out    %al,(%dx)
8010176d:	b8 0c 00 00 00       	mov    $0xc,%eax
80101772:	ba f8 03 00 00       	mov    $0x3f8,%edx
80101777:	ee                   	out    %al,(%dx)
80101778:	be f9 03 00 00       	mov    $0x3f9,%esi
8010177d:	89 c8                	mov    %ecx,%eax
8010177f:	89 f2                	mov    %esi,%edx
80101781:	ee                   	out    %al,(%dx)
80101782:	b8 03 00 00 00       	mov    $0x3,%eax
80101787:	89 fa                	mov    %edi,%edx
80101789:	ee                   	out    %al,(%dx)
8010178a:	ba fc 03 00 00       	mov    $0x3fc,%edx
8010178f:	89 c8                	mov    %ecx,%eax
80101791:	ee                   	out    %al,(%dx)
80101792:	b8 01 00 00 00       	mov    $0x1,%eax
80101797:	89 f2                	mov    %esi,%edx
80101799:	ee                   	out    %al,(%dx)
    asm volatile("inb %w1,%0"
8010179a:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010179f:	ec                   	in     (%dx),%al
801017a0:	89 c1                	mov    %eax,%ecx
    serial_exists = (inb(COM1 + COM_LSR) != 0xFF);
801017a2:	3c ff                	cmp    $0xff,%al
801017a4:	0f 95 05 ac 49 10 80 	setne  0x801049ac
801017ab:	89 da                	mov    %ebx,%edx
801017ad:	ec                   	in     (%dx),%al
801017ae:	ba f8 03 00 00       	mov    $0x3f8,%edx
801017b3:	ec                   	in     (%dx),%al
    if (!serial_exists)
801017b4:	80 f9 ff             	cmp    $0xff,%cl
801017b7:	74 1e                	je     801017d7 <cons_init+0x111>
}
801017b9:	8d 65 f4             	lea    -0xc(%ebp),%esp
801017bc:	5b                   	pop    %ebx
801017bd:	5e                   	pop    %esi
801017be:	5f                   	pop    %edi
801017bf:	5d                   	pop    %ebp
801017c0:	c3                   	ret    
        *cp = was;
801017c1:	66 89 15 00 80 0b 80 	mov    %dx,0x800b8000
801017c8:	bb d4 03 00 00       	mov    $0x3d4,%ebx
    cp = (uint16_t*)(K_ADDR_BASE + CGA_BUF);
801017cd:	be 00 80 0b 80       	mov    $0x800b8000,%esi
801017d2:	e9 3f ff ff ff       	jmp    80101716 <cons_init+0x50>
        cprintf("Serial port does not exist!\n");
801017d7:	83 ec 0c             	sub    $0xc,%esp
801017da:	68 d2 19 10 80       	push   $0x801019d2
801017df:	e8 7d fc ff ff       	call   80101461 <cprintf>
801017e4:	83 c4 10             	add    $0x10,%esp
}
801017e7:	eb d0                	jmp    801017b9 <cons_init+0xf3>

801017e9 <spin>:
 * 自旋 ms 微秒
 */
void spin(int ms)
{
    // TODO：
}
801017e9:	c3                   	ret    
