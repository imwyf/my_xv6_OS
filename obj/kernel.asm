
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
8010001c:	bc 20 4b 10 80       	mov    $0x80104b20,%esp

# 不能用 call，其使用的是相对寻址，所以 eip 仍然会在低地址处偏移来寻址，而此时 eip 指向的是低的虚拟地址，因此通过 jmp 重置 eip 以指向高地址处
  mov $main, %eax
80100021:	b8 28 00 10 80       	mov    $0x80100028,%eax
  jmp *%eax
80100026:	ff e0                	jmp    *%eax

80100028 <main>:
              PDXSHIFT]
          = (0) | PTE_P | PTE_W | PTE_PS,
      };

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
80100039:	e8 93 0e 00 00       	call   80100ed1 <cons_init>
    cprintf("\n");
8010003e:	83 ec 0c             	sub    $0xc,%esp
80100041:	68 40 10 10 80       	push   $0x80101040
80100046:	e8 5a 0c 00 00       	call   80100ca5 <cprintf>
    cprintf("------> Hello, OS World!\n");
8010004b:	c7 04 24 e0 0f 10 80 	movl   $0x80100fe0,(%esp)
80100052:	e8 4e 0c 00 00       	call   80100ca5 <cprintf>
    kmem_init(); // 内存管理初始化
80100057:	e8 d3 02 00 00       	call   8010032f <kmem_init>
    cprintf("------> kmem_init() finish!\n");
8010005c:	c7 04 24 fa 0f 10 80 	movl   $0x80100ffa,(%esp)
80100063:	e8 3d 0c 00 00       	call   80100ca5 <cprintf>
    mcpu_init();
80100068:	e8 08 05 00 00       	call   80100575 <mcpu_init>
    cprintf("------> mcpu_init() finish!\n");
8010006d:	c7 04 24 17 10 10 80 	movl   $0x80101017,(%esp)
80100074:	e8 2c 0c 00 00       	call   80100ca5 <cprintf>
#include "types.h"

static inline void
hlt(void)
{
    asm volatile("hlt");
80100079:	f4                   	hlt    
    hlt();
}
8010007a:	b8 00 00 00 00       	mov    $0x0,%eax
8010007f:	8b 4d fc             	mov    -0x4(%ebp),%ecx
80100082:	c9                   	leave  
80100083:	8d 61 fc             	lea    -0x4(%ecx),%esp
80100086:	c3                   	ret    

80100087 <kmem_free>:

/**
 *  释放虚拟地址v指向的内存
 */
void kmem_free(char* vaddr)
{
80100087:	55                   	push   %ebp
80100088:	89 e5                	mov    %esp,%ebp
8010008a:	53                   	push   %ebx
8010008b:	83 ec 04             	sub    $0x4,%esp
8010008e:	8b 5d 08             	mov    0x8(%ebp),%ebx
    if ((vaddr_t)vaddr % PGSIZE || vaddr < end || K_V2P(vaddr) >= P_ADDR_PHYSTOP)
80100091:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80100097:	75 15                	jne    801000ae <kmem_free+0x27>
80100099:	81 fb 20 4b 10 80    	cmp    $0x80104b20,%ebx
8010009f:	72 0d                	jb     801000ae <kmem_free+0x27>
801000a1:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801000a7:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
801000ac:	76 10                	jbe    801000be <kmem_free+0x37>
        cprintf("kfree error \n");
801000ae:	83 ec 0c             	sub    $0xc,%esp
801000b1:	68 34 10 10 80       	push   $0x80101034
801000b6:	e8 ea 0b 00 00       	call   80100ca5 <cprintf>
801000bb:	83 c4 10             	add    $0x10,%esp

    memset(vaddr, 1, PGSIZE); // 清空该页内存
801000be:	83 ec 04             	sub    $0x4,%esp
801000c1:	68 00 10 00 00       	push   $0x1000
801000c6:	6a 01                	push   $0x1
801000c8:	53                   	push   %ebx
801000c9:	e8 eb 06 00 00       	call   801007b9 <memset>

    // if (kmem.use_lock)
    //     acquire(&kmem.lock);
    struct list_node* node = (struct list_node*)vaddr;
    node->next = kmem.freelist;
801000ce:	a1 00 33 10 80       	mov    0x80103300,%eax
801000d3:	89 03                	mov    %eax,(%ebx)
    kmem.freelist = node;
801000d5:	89 1d 00 33 10 80    	mov    %ebx,0x80103300
    // if (kmem.use_lock)
    //     release(&kmem.lock);
}
801000db:	83 c4 10             	add    $0x10,%esp
801000de:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801000e1:	c9                   	leave  
801000e2:	c3                   	ret    

801000e3 <kmem_free_pages>:
{
801000e3:	55                   	push   %ebp
801000e4:	89 e5                	mov    %esp,%ebp
801000e6:	56                   	push   %esi
801000e7:	53                   	push   %ebx
801000e8:	8b 75 0c             	mov    0xc(%ebp),%esi
    p = (char*)PGROUNDUP((vaddr_t)start);
801000eb:	8b 45 08             	mov    0x8(%ebp),%eax
801000ee:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801000f4:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
    for (; p + PGSIZE <= (char*)end; p += PGSIZE) {
801000fa:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80100100:	39 de                	cmp    %ebx,%esi
80100102:	72 1c                	jb     80100120 <kmem_free_pages+0x3d>
        kmem_free(p);
80100104:	83 ec 0c             	sub    $0xc,%esp
80100107:	8d 83 00 f0 ff ff    	lea    -0x1000(%ebx),%eax
8010010d:	50                   	push   %eax
8010010e:	e8 74 ff ff ff       	call   80100087 <kmem_free>
    for (; p + PGSIZE <= (char*)end; p += PGSIZE) {
80100113:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80100119:	83 c4 10             	add    $0x10,%esp
8010011c:	39 de                	cmp    %ebx,%esi
8010011e:	73 e4                	jae    80100104 <kmem_free_pages+0x21>
}
80100120:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100123:	5b                   	pop    %ebx
80100124:	5e                   	pop    %esi
80100125:	5d                   	pop    %ebp
80100126:	c3                   	ret    

80100127 <kmem_alloc>:
{
    struct list_node* node = NULL;

    // if (kmem.use_lock)
    //     acquire(&kmem.lock);
    node = kmem.freelist;
80100127:	a1 00 33 10 80       	mov    0x80103300,%eax
    if (node)
8010012c:	85 c0                	test   %eax,%eax
8010012e:	74 08                	je     80100138 <kmem_alloc+0x11>
        kmem.freelist = node->next;
80100130:	8b 10                	mov    (%eax),%edx
80100132:	89 15 00 33 10 80    	mov    %edx,0x80103300
    // if (kmem.use_lock)
    //     release(&kmem.lock);
    return (char*)node;
}
80100138:	c3                   	ret    

80100139 <kmmap>:

/**
 * 在页表 pgdir 中进行虚拟内存到物理内存的映射：虚拟地址 vaddr -> 物理地址 paddr，映射长度为 size，权限为 perm，成功返回0，不成功返回-1
 */
static int kmmap(pde_t* pgdir, void* vaddr, uint32_t size, paddr_t paddr, int perm)
{
80100139:	55                   	push   %ebp
8010013a:	89 e5                	mov    %esp,%ebp
8010013c:	57                   	push   %edi
8010013d:	56                   	push   %esi
8010013e:	53                   	push   %ebx
8010013f:	83 ec 2c             	sub    $0x2c,%esp
80100142:	89 45 dc             	mov    %eax,-0x24(%ebp)
    char *va_start, *va_end;
    pte_t* pte;

    if (size == 0) {
80100145:	85 c9                	test   %ecx,%ecx
80100147:	74 20                	je     80100169 <kmmap+0x30>
80100149:	89 d0                	mov    %edx,%eax
        cprintf("kmmap() error: size = 0, it should be > 0\n");
        return -1;
    }

    /* 先对齐，并求出需要映射的虚拟地址范围 */
    va_start = (char*)PGROUNDDOWN((vaddr_t)vaddr);
8010014b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
80100151:	89 d7                	mov    %edx,%edi
    va_end = (char*)PGROUNDDOWN(((vaddr_t)vaddr) + size - 1);
80100153:	8d 44 08 ff          	lea    -0x1(%eax,%ecx,1),%eax
80100157:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010015c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
8010015f:	8b 45 08             	mov    0x8(%ebp),%eax
80100162:	29 d0                	sub    %edx,%eax
80100164:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100167:	eb 5a                	jmp    801001c3 <kmmap+0x8a>
        cprintf("kmmap() error: size = 0, it should be > 0\n");
80100169:	83 ec 0c             	sub    $0xc,%esp
8010016c:	68 44 10 10 80       	push   $0x80101044
80100171:	e8 2f 0b 00 00       	call   80100ca5 <cprintf>
        return -1;
80100176:	83 c4 10             	add    $0x10,%esp
80100179:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010017e:	e9 ba 00 00 00       	jmp    8010023d <kmmap+0x104>
    pde_t* pde; // 页目录项（一级）
    pte_t* pte; // 页表项（二级）

    pde = &pgdir[PDX(vaddr)]; // 根据 vaddr 获取对应的页目录项
    if (*pde & PTE_P) { // 页目录项存在
        pte = (pte_t*)K_P2V(PTE_ADDR(*pde)); // 取出 PPN 所对应的二级页表（即 pte 数组）的地址
80100183:	25 00 f0 ff ff       	and    $0xfffff000,%eax
            return NULL;

        memset(pte, 0, PGSIZE);
        *pde = K_V2P(pte) | perm | PTE_P; // 将二级页表的物理地址写入页目录项
    }
    return &pte[PTX(vaddr)]; // 从二级页表中取出对应的页表项
80100188:	89 fa                	mov    %edi,%edx
8010018a:	c1 ea 0a             	shr    $0xa,%edx
8010018d:	81 e2 fc 0f 00 00    	and    $0xffc,%edx
80100193:	8d 9c 10 00 00 00 80 	lea    -0x80000000(%eax,%edx,1),%ebx
        if ((pte = get_pte(pgdir, va_start, 1, perm)) == NULL) // 找到 pte
8010019a:	85 db                	test   %ebx,%ebx
8010019c:	0f 84 8f 00 00 00    	je     80100231 <kmmap+0xf8>
        if (*pte & PTE_P) {
801001a2:	f6 03 01             	testb  $0x1,(%ebx)
801001a5:	75 73                	jne    8010021a <kmmap+0xe1>
        *pte = paddr | perm | PTE_P; // 填写 pte
801001a7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801001aa:	0b 45 0c             	or     0xc(%ebp),%eax
801001ad:	83 c8 01             	or     $0x1,%eax
801001b0:	89 03                	mov    %eax,(%ebx)
        if (va_start == va_end) // 映射完成
801001b2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801001b5:	39 c7                	cmp    %eax,%edi
801001b7:	0f 84 88 00 00 00    	je     80100245 <kmmap+0x10c>
        va_start += PGSIZE;
801001bd:	81 c7 00 10 00 00    	add    $0x1000,%edi
    while (1) {
801001c3:	89 7d e0             	mov    %edi,-0x20(%ebp)
801001c6:	8b 45 d8             	mov    -0x28(%ebp),%eax
801001c9:	01 f8                	add    %edi,%eax
801001cb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    pde = &pgdir[PDX(vaddr)]; // 根据 vaddr 获取对应的页目录项
801001ce:	89 f8                	mov    %edi,%eax
801001d0:	c1 e8 16             	shr    $0x16,%eax
801001d3:	8b 4d dc             	mov    -0x24(%ebp),%ecx
801001d6:	8d 34 81             	lea    (%ecx,%eax,4),%esi
    if (*pde & PTE_P) { // 页目录项存在
801001d9:	8b 06                	mov    (%esi),%eax
801001db:	a8 01                	test   $0x1,%al
801001dd:	75 a4                	jne    80100183 <kmmap+0x4a>
        if (!need_alloc || (pte = (pte_t*)kmem_alloc()) == NULL) // 不需要分配或分配失败
801001df:	e8 43 ff ff ff       	call   80100127 <kmem_alloc>
801001e4:	89 c3                	mov    %eax,%ebx
801001e6:	85 c0                	test   %eax,%eax
801001e8:	74 4e                	je     80100238 <kmmap+0xff>
        memset(pte, 0, PGSIZE);
801001ea:	83 ec 04             	sub    $0x4,%esp
801001ed:	68 00 10 00 00       	push   $0x1000
801001f2:	6a 00                	push   $0x0
801001f4:	50                   	push   %eax
801001f5:	e8 bf 05 00 00       	call   801007b9 <memset>
        *pde = K_V2P(pte) | perm | PTE_P; // 将二级页表的物理地址写入页目录项
801001fa:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80100200:	0b 45 0c             	or     0xc(%ebp),%eax
80100203:	83 c8 01             	or     $0x1,%eax
80100206:	89 06                	mov    %eax,(%esi)
    return &pte[PTX(vaddr)]; // 从二级页表中取出对应的页表项
80100208:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010020b:	c1 e8 0a             	shr    $0xa,%eax
8010020e:	25 fc 0f 00 00       	and    $0xffc,%eax
80100213:	01 c3                	add    %eax,%ebx
80100215:	83 c4 10             	add    $0x10,%esp
80100218:	eb 88                	jmp    801001a2 <kmmap+0x69>
            cprintf("kmmap error: pte already present\n");
8010021a:	83 ec 0c             	sub    $0xc,%esp
8010021d:	68 70 10 10 80       	push   $0x80101070
80100222:	e8 7e 0a 00 00       	call   80100ca5 <cprintf>
            return -1;
80100227:	83 c4 10             	add    $0x10,%esp
8010022a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010022f:	eb 0c                	jmp    8010023d <kmmap+0x104>
            return -1;
80100231:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100236:	eb 05                	jmp    8010023d <kmmap+0x104>
80100238:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010023d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100240:	5b                   	pop    %ebx
80100241:	5e                   	pop    %esi
80100242:	5f                   	pop    %edi
80100243:	5d                   	pop    %ebp
80100244:	c3                   	ret    
    return 0;
80100245:	b8 00 00 00 00       	mov    $0x0,%eax
8010024a:	eb f1                	jmp    8010023d <kmmap+0x104>

8010024c <set_kernel_pgdir>:
{
8010024c:	55                   	push   %ebp
8010024d:	89 e5                	mov    %esp,%ebp
8010024f:	53                   	push   %ebx
80100250:	83 ec 04             	sub    $0x4,%esp
    if ((kernel_pgdir = (pde_t*)kmem_alloc()) == 0) // 分配一页内存作为一级页表页（即页目录）
80100253:	e8 cf fe ff ff       	call   80100127 <kmem_alloc>
80100258:	89 c3                	mov    %eax,%ebx
8010025a:	85 c0                	test   %eax,%eax
8010025c:	0f 84 ac 00 00 00    	je     8010030e <set_kernel_pgdir+0xc2>
    memset(kernel_pgdir, 0, PGSIZE);
80100262:	83 ec 04             	sub    $0x4,%esp
80100265:	68 00 10 00 00       	push   $0x1000
8010026a:	6a 00                	push   $0x0
8010026c:	50                   	push   %eax
8010026d:	e8 47 05 00 00       	call   801007b9 <memset>
    if (kmmap(kernel_pgdir, (void*)K_ADDR_BASE, P_ADDR_EXTMEM - 0, (paddr_t)0, PTE_W) < 0) { // 映射低1MB内存
80100272:	83 c4 08             	add    $0x8,%esp
80100275:	6a 02                	push   $0x2
80100277:	6a 00                	push   $0x0
80100279:	b9 00 00 10 00       	mov    $0x100000,%ecx
8010027e:	ba 00 00 00 80       	mov    $0x80000000,%edx
80100283:	89 d8                	mov    %ebx,%eax
80100285:	e8 af fe ff ff       	call   80100139 <kmmap>
8010028a:	83 c4 10             	add    $0x10,%esp
8010028d:	85 c0                	test   %eax,%eax
8010028f:	78 6c                	js     801002fd <set_kernel_pgdir+0xb1>
    if (kmmap(kernel_pgdir, (void*)K_ADDR_LOAD, K_V2P(data) - K_V2P(K_ADDR_LOAD), K_V2P(K_ADDR_LOAD), 0) < 0) { // 映射内核代码段和数据段占据的内存
80100291:	83 ec 08             	sub    $0x8,%esp
80100294:	6a 00                	push   $0x0
80100296:	68 00 00 10 00       	push   $0x100000
8010029b:	b9 00 20 00 00       	mov    $0x2000,%ecx
801002a0:	ba 00 00 10 80       	mov    $0x80100000,%edx
801002a5:	89 d8                	mov    %ebx,%eax
801002a7:	e8 8d fe ff ff       	call   80100139 <kmmap>
801002ac:	83 c4 10             	add    $0x10,%esp
801002af:	85 c0                	test   %eax,%eax
801002b1:	78 4a                	js     801002fd <set_kernel_pgdir+0xb1>
    if (kmmap(kernel_pgdir, (void*)data, P_ADDR_PHYSTOP - K_V2P(data), K_V2P(data), PTE_W) < 0) { // 映射内核数据段后面的内存
801002b3:	b9 00 00 00 8e       	mov    $0x8e000000,%ecx
801002b8:	81 e9 00 20 10 80    	sub    $0x80102000,%ecx
801002be:	83 ec 08             	sub    $0x8,%esp
801002c1:	6a 02                	push   $0x2
801002c3:	68 00 20 10 00       	push   $0x102000
801002c8:	ba 00 20 10 80       	mov    $0x80102000,%edx
801002cd:	89 d8                	mov    %ebx,%eax
801002cf:	e8 65 fe ff ff       	call   80100139 <kmmap>
801002d4:	83 c4 10             	add    $0x10,%esp
801002d7:	85 c0                	test   %eax,%eax
801002d9:	78 22                	js     801002fd <set_kernel_pgdir+0xb1>
    if (kmmap(kernel_pgdir, (void*)P_ADDR_DEVSPACE, 0 - P_ADDR_DEVSPACE, (paddr_t)P_ADDR_DEVSPACE, PTE_W) < 0) { // 映射设备内存（直接映射）
801002db:	83 ec 08             	sub    $0x8,%esp
801002de:	6a 02                	push   $0x2
801002e0:	68 00 00 00 fe       	push   $0xfe000000
801002e5:	b9 00 00 00 02       	mov    $0x2000000,%ecx
801002ea:	ba 00 00 00 fe       	mov    $0xfe000000,%edx
801002ef:	89 d8                	mov    %ebx,%eax
801002f1:	e8 43 fe ff ff       	call   80100139 <kmmap>
801002f6:	83 c4 10             	add    $0x10,%esp
801002f9:	85 c0                	test   %eax,%eax
801002fb:	79 11                	jns    8010030e <set_kernel_pgdir+0xc2>
    kmem_free((char*)kernel_pgdir);
801002fd:	83 ec 0c             	sub    $0xc,%esp
80100300:	53                   	push   %ebx
80100301:	e8 81 fd ff ff       	call   80100087 <kmem_free>
    return 0;
80100306:	83 c4 10             	add    $0x10,%esp
80100309:	bb 00 00 00 00       	mov    $0x0,%ebx
}
8010030e:	89 d8                	mov    %ebx,%eax
80100310:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100313:	c9                   	leave  
80100314:	c3                   	ret    

80100315 <switch_pgdir>:
{
80100315:	55                   	push   %ebp
80100316:	89 e5                	mov    %esp,%ebp
    if (p == NULL) {
80100318:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010031c:	74 02                	je     80100320 <switch_pgdir+0xb>
}
8010031e:	5d                   	pop    %ebp
8010031f:	c3                   	ret    
        lcr3(K_V2P(kernel_pgdir));
80100320:	a1 04 33 10 80       	mov    0x80103304,%eax
80100325:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint32_t val)
{
    asm volatile("movl %0,%%cr3"
8010032a:	0f 22 d8             	mov    %eax,%cr3
}
8010032d:	eb ef                	jmp    8010031e <switch_pgdir+0x9>

8010032f <kmem_init>:
{
8010032f:	55                   	push   %ebp
80100330:	89 e5                	mov    %esp,%ebp
80100332:	83 ec 10             	sub    $0x10,%esp
    kmem_free_pages(end, K_P2V(P_ADDR_LOWMEM)); // 释放[end, 4MB]部分给新的内核页表使用
80100335:	68 00 00 40 80       	push   $0x80400000
8010033a:	68 20 4b 10 80       	push   $0x80104b20
8010033f:	e8 9f fd ff ff       	call   801000e3 <kmem_free_pages>
    kernel_pgdir = set_kernel_pgdir(); // 设置内核页表
80100344:	e8 03 ff ff ff       	call   8010024c <set_kernel_pgdir>
80100349:	a3 04 33 10 80       	mov    %eax,0x80103304
    switch_pgdir(NULL); // NULL 代表切换为内核页表
8010034e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80100355:	e8 bb ff ff ff       	call   80100315 <switch_pgdir>
}
8010035a:	83 c4 10             	add    $0x10,%esp
8010035d:	c9                   	leave  
8010035e:	c3                   	ret    

8010035f <free_pgdir>:
{
8010035f:	55                   	push   %ebp
80100360:	89 e5                	mov    %esp,%ebp
80100362:	56                   	push   %esi
80100363:	53                   	push   %ebx
80100364:	8b 75 08             	mov    0x8(%ebp),%esi
80100367:	bb 00 00 00 00       	mov    $0x0,%ebx
8010036c:	eb 0b                	jmp    80100379 <free_pgdir+0x1a>
    for (int i = 0; i < NPDENTRIES; i++) {
8010036e:	83 c3 04             	add    $0x4,%ebx
80100371:	81 fb 00 10 00 00    	cmp    $0x1000,%ebx
80100377:	74 22                	je     8010039b <free_pgdir+0x3c>
        if (p->pgdir[i] & PTE_P) {
80100379:	8b 46 04             	mov    0x4(%esi),%eax
8010037c:	8b 04 18             	mov    (%eax,%ebx,1),%eax
8010037f:	a8 01                	test   $0x1,%al
80100381:	74 eb                	je     8010036e <free_pgdir+0xf>
            kmem_free(v);
80100383:	83 ec 0c             	sub    $0xc,%esp
            char* v = K_P2V(PTE_ADDR(p->pgdir[i]));
80100386:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010038b:	05 00 00 00 80       	add    $0x80000000,%eax
            kmem_free(v);
80100390:	50                   	push   %eax
80100391:	e8 f1 fc ff ff       	call   80100087 <kmem_free>
80100396:	83 c4 10             	add    $0x10,%esp
80100399:	eb d3                	jmp    8010036e <free_pgdir+0xf>
    kmem_free((char*)p->pgdir); // 释放页目录
8010039b:	83 ec 0c             	sub    $0xc,%esp
8010039e:	ff 76 04             	push   0x4(%esi)
801003a1:	e8 e1 fc ff ff       	call   80100087 <kmem_free>
}
801003a6:	83 c4 10             	add    $0x10,%esp
801003a9:	8d 65 f8             	lea    -0x8(%ebp),%esp
801003ac:	5b                   	pop    %ebx
801003ad:	5e                   	pop    %esi
801003ae:	5d                   	pop    %ebp
801003af:	c3                   	ret    

801003b0 <mpsearch1>:
}

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint32_t a, int len)
{
801003b0:	55                   	push   %ebp
801003b1:	89 e5                	mov    %esp,%ebp
801003b3:	57                   	push   %edi
801003b4:	56                   	push   %esi
801003b5:	53                   	push   %ebx
801003b6:	83 ec 0c             	sub    $0xc,%esp
    uint8_t *e, *p, *addr;

    addr = K_P2V(a);
801003b9:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
    e = addr + len;
801003bf:	8d 3c 16             	lea    (%esi,%edx,1),%edi
    for (p = addr; p < e; p += sizeof(struct mp))
801003c2:	39 fe                	cmp    %edi,%esi
801003c4:	73 4c                	jae    80100412 <mpsearch1+0x62>
801003c6:	8d 98 10 00 00 80    	lea    -0x7ffffff0(%eax),%ebx
801003cc:	eb 0e                	jmp    801003dc <mpsearch1+0x2c>
        if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
801003ce:	84 c0                	test   %al,%al
801003d0:	74 36                	je     80100408 <mpsearch1+0x58>
    for (p = addr; p < e; p += sizeof(struct mp))
801003d2:	83 c6 10             	add    $0x10,%esi
801003d5:	83 c3 10             	add    $0x10,%ebx
801003d8:	39 fe                	cmp    %edi,%esi
801003da:	73 27                	jae    80100403 <mpsearch1+0x53>
        if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
801003dc:	83 ec 04             	sub    $0x4,%esp
801003df:	6a 04                	push   $0x4
801003e1:	68 92 10 10 80       	push   $0x80101092
801003e6:	56                   	push   %esi
801003e7:	e8 02 04 00 00       	call   801007ee <memcmp>
801003ec:	83 c4 10             	add    $0x10,%esp
801003ef:	85 c0                	test   %eax,%eax
801003f1:	75 df                	jne    801003d2 <mpsearch1+0x22>
801003f3:	89 f2                	mov    %esi,%edx
        sum += addr[i];
801003f5:	0f b6 0a             	movzbl (%edx),%ecx
801003f8:	01 c8                	add    %ecx,%eax
    for (i = 0; i < len; i++)
801003fa:	83 c2 01             	add    $0x1,%edx
801003fd:	39 da                	cmp    %ebx,%edx
801003ff:	75 f4                	jne    801003f5 <mpsearch1+0x45>
80100401:	eb cb                	jmp    801003ce <mpsearch1+0x1e>
            return (struct mp*)p;
    return 0;
80100403:	be 00 00 00 00       	mov    $0x0,%esi
}
80100408:	89 f0                	mov    %esi,%eax
8010040a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010040d:	5b                   	pop    %ebx
8010040e:	5e                   	pop    %esi
8010040f:	5f                   	pop    %edi
80100410:	5d                   	pop    %ebp
80100411:	c3                   	ret    
    return 0;
80100412:	be 00 00 00 00       	mov    $0x0,%esi
80100417:	eb ef                	jmp    80100408 <mpsearch1+0x58>

80100419 <mycpu>:
{
80100419:	55                   	push   %ebp
8010041a:	89 e5                	mov    %esp,%ebp
8010041c:	56                   	push   %esi
8010041d:	53                   	push   %ebx

static inline uint32_t
read_eflags(void)
{
    uint32_t eflags;
    asm volatile("pushfl; popl %0"
8010041e:	9c                   	pushf  
8010041f:	58                   	pop    %eax
    if (read_eflags() & FL_IF) {
80100420:	f6 c4 02             	test   $0x2,%ah
80100423:	75 2e                	jne    80100453 <mycpu+0x3a>
    apicid = lapicid();
80100425:	e8 1f 03 00 00       	call   80100749 <lapicid>
    for (i = 0; i < num_cpu; ++i) {
8010042a:	8b 35 24 33 10 80    	mov    0x80103324,%esi
80100430:	85 f6                	test   %esi,%esi
80100432:	7e 38                	jle    8010046c <mycpu+0x53>
80100434:	ba 00 00 00 00       	mov    $0x0,%edx
        if (cpus[i].apicid == apicid)
80100439:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
8010043f:	0f b6 99 40 33 10 80 	movzbl -0x7fefccc0(%ecx),%ebx
80100446:	39 c3                	cmp    %eax,%ebx
80100448:	74 1c                	je     80100466 <mycpu+0x4d>
    for (i = 0; i < num_cpu; ++i) {
8010044a:	83 c2 01             	add    $0x1,%edx
8010044d:	39 f2                	cmp    %esi,%edx
8010044f:	75 e8                	jne    80100439 <mycpu+0x20>
80100451:	eb 19                	jmp    8010046c <mycpu+0x53>
        cprintf("mycpu called with interrupts enabled\n");
80100453:	83 ec 0c             	sub    $0xc,%esp
80100456:	68 9c 10 10 80       	push   $0x8010109c
8010045b:	e8 45 08 00 00       	call   80100ca5 <cprintf>
    asm volatile("hlt");
80100460:	f4                   	hlt    
}
80100461:	83 c4 10             	add    $0x10,%esp
80100464:	eb bf                	jmp    80100425 <mycpu+0xc>
            return &cpus[i];
80100466:	8d 81 40 33 10 80    	lea    -0x7fefccc0(%ecx),%eax
}
8010046c:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010046f:	5b                   	pop    %ebx
80100470:	5e                   	pop    %esi
80100471:	5d                   	pop    %ebp
80100472:	c3                   	ret    

80100473 <cpuid>:
{
80100473:	55                   	push   %ebp
80100474:	89 e5                	mov    %esp,%ebp
80100476:	83 ec 08             	sub    $0x8,%esp
    return mycpu() - cpus;
80100479:	e8 9b ff ff ff       	call   80100419 <mycpu>
8010047e:	2d 40 33 10 80       	sub    $0x80103340,%eax
80100483:	c1 f8 04             	sar    $0x4,%eax
80100486:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
8010048c:	c9                   	leave  
8010048d:	c3                   	ret    

8010048e <seginit>:
    *pmp = mp;
    return conf;
}

void seginit(void)
{
8010048e:	55                   	push   %ebp
8010048f:	89 e5                	mov    %esp,%ebp
80100491:	83 ec 18             	sub    $0x18,%esp

    // Map "logical" addresses to virtual addresses using identity map.
    // Cannot share a CODE descriptor for both kernel and user
    // because it would have to have DPL_USR, but the CPU forbids
    // an interrupt from CPL=0 to DPL=3.
    c = &cpus[cpuid()];
80100494:	e8 da ff ff ff       	call   80100473 <cpuid>
    c->gdt[SEG_SELECTOR_KCODE] = SEG(STA_X | STA_R, 0, 0xffffffff, 0);
80100499:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
8010049f:	66 c7 80 b8 33 10 80 	movw   $0xffff,-0x7fefcc48(%eax)
801004a6:	ff ff 
801004a8:	66 c7 80 ba 33 10 80 	movw   $0x0,-0x7fefcc46(%eax)
801004af:	00 00 
801004b1:	c6 80 bc 33 10 80 00 	movb   $0x0,-0x7fefcc44(%eax)
801004b8:	c6 80 bd 33 10 80 9a 	movb   $0x9a,-0x7fefcc43(%eax)
801004bf:	c6 80 be 33 10 80 cf 	movb   $0xcf,-0x7fefcc42(%eax)
801004c6:	c6 80 bf 33 10 80 00 	movb   $0x0,-0x7fefcc41(%eax)
    c->gdt[SEG_SELECTOR_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801004cd:	66 c7 80 c0 33 10 80 	movw   $0xffff,-0x7fefcc40(%eax)
801004d4:	ff ff 
801004d6:	66 c7 80 c2 33 10 80 	movw   $0x0,-0x7fefcc3e(%eax)
801004dd:	00 00 
801004df:	c6 80 c4 33 10 80 00 	movb   $0x0,-0x7fefcc3c(%eax)
801004e6:	c6 80 c5 33 10 80 92 	movb   $0x92,-0x7fefcc3b(%eax)
801004ed:	c6 80 c6 33 10 80 cf 	movb   $0xcf,-0x7fefcc3a(%eax)
801004f4:	c6 80 c7 33 10 80 00 	movb   $0x0,-0x7fefcc39(%eax)
    c->gdt[SEG_SELECTOR_UCODE] = SEG(STA_X | STA_R, 0, 0xffffffff, DPL_USER);
801004fb:	66 c7 80 c8 33 10 80 	movw   $0xffff,-0x7fefcc38(%eax)
80100502:	ff ff 
80100504:	66 c7 80 ca 33 10 80 	movw   $0x0,-0x7fefcc36(%eax)
8010050b:	00 00 
8010050d:	c6 80 cc 33 10 80 00 	movb   $0x0,-0x7fefcc34(%eax)
80100514:	c6 80 cd 33 10 80 fa 	movb   $0xfa,-0x7fefcc33(%eax)
8010051b:	c6 80 ce 33 10 80 cf 	movb   $0xcf,-0x7fefcc32(%eax)
80100522:	c6 80 cf 33 10 80 00 	movb   $0x0,-0x7fefcc31(%eax)
    c->gdt[SEG_SELECTOR_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80100529:	66 c7 80 d0 33 10 80 	movw   $0xffff,-0x7fefcc30(%eax)
80100530:	ff ff 
80100532:	66 c7 80 d2 33 10 80 	movw   $0x0,-0x7fefcc2e(%eax)
80100539:	00 00 
8010053b:	c6 80 d4 33 10 80 00 	movb   $0x0,-0x7fefcc2c(%eax)
80100542:	c6 80 d5 33 10 80 f2 	movb   $0xf2,-0x7fefcc2b(%eax)
80100549:	c6 80 d6 33 10 80 cf 	movb   $0xcf,-0x7fefcc2a(%eax)
80100550:	c6 80 d7 33 10 80 00 	movb   $0x0,-0x7fefcc29(%eax)
    lgdt(c->gdt, sizeof(c->gdt));
80100557:	05 b0 33 10 80       	add    $0x801033b0,%eax
    pd[0] = size - 1;
8010055c:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
    pd[1] = (uint32_t)p;
80100562:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
    pd[2] = (uint32_t)p >> 16;
80100566:	c1 e8 10             	shr    $0x10,%eax
80100569:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
    asm volatile("lgdt (%0)"
8010056d:	8d 45 f2             	lea    -0xe(%ebp),%eax
80100570:	0f 01 10             	lgdtl  (%eax)
}
80100573:	c9                   	leave  
80100574:	c3                   	ret    

80100575 <mcpu_init>:

void mcpu_init(void)
{
80100575:	55                   	push   %ebp
80100576:	89 e5                	mov    %esp,%ebp
80100578:	57                   	push   %edi
80100579:	56                   	push   %esi
8010057a:	53                   	push   %ebx
8010057b:	83 ec 1c             	sub    $0x1c,%esp
    if ((p = ((bda[0x0F] << 8) | bda[0x0E]) << 4)) {
8010057e:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80100585:	c1 e0 08             	shl    $0x8,%eax
80100588:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
8010058f:	09 d0                	or     %edx,%eax
80100591:	c1 e0 04             	shl    $0x4,%eax
80100594:	0f 84 c1 00 00 00    	je     8010065b <mcpu_init+0xe6>
        if ((mp = mpsearch1(p, 1024)))
8010059a:	ba 00 04 00 00       	mov    $0x400,%edx
8010059f:	e8 0c fe ff ff       	call   801003b0 <mpsearch1>
801005a4:	89 c3                	mov    %eax,%ebx
801005a6:	85 c0                	test   %eax,%eax
801005a8:	75 19                	jne    801005c3 <mcpu_init+0x4e>
    return mpsearch1(0xF0000, 0x10000);
801005aa:	ba 00 00 01 00       	mov    $0x10000,%edx
801005af:	b8 00 00 0f 00       	mov    $0xf0000,%eax
801005b4:	e8 f7 fd ff ff       	call   801003b0 <mpsearch1>
801005b9:	89 c3                	mov    %eax,%ebx
    if ((mp = mpsearch()) == 0 || mp->physaddr == 0)
801005bb:	85 c0                	test   %eax,%eax
801005bd:	0f 84 cc 00 00 00    	je     8010068f <mcpu_init+0x11a>
801005c3:	8b 7b 04             	mov    0x4(%ebx),%edi
801005c6:	85 ff                	test   %edi,%edi
801005c8:	0f 84 c5 00 00 00    	je     80100693 <mcpu_init+0x11e>
    conf = (struct mpconf*)K_P2V((uint32_t)mp->physaddr);
801005ce:	8d b7 00 00 00 80    	lea    -0x80000000(%edi),%esi
    if (memcmp(conf, "PCMP", 4) != 0)
801005d4:	83 ec 04             	sub    $0x4,%esp
801005d7:	6a 04                	push   $0x4
801005d9:	68 97 10 10 80       	push   $0x80101097
801005de:	56                   	push   %esi
801005df:	e8 0a 02 00 00       	call   801007ee <memcmp>
801005e4:	89 c2                	mov    %eax,%edx
801005e6:	83 c4 10             	add    $0x10,%esp
801005e9:	85 c0                	test   %eax,%eax
801005eb:	0f 85 a6 00 00 00    	jne    80100697 <mcpu_init+0x122>
    if (conf->version != 1 && conf->version != 4)
801005f1:	0f b6 87 06 00 00 80 	movzbl -0x7ffffffa(%edi),%eax
801005f8:	3c 01                	cmp    $0x1,%al
801005fa:	74 08                	je     80100604 <mcpu_init+0x8f>
801005fc:	3c 04                	cmp    $0x4,%al
801005fe:	0f 85 9a 00 00 00    	jne    8010069e <mcpu_init+0x129>
    if (sum((uint8_t*)conf, conf->length) != 0)
80100604:	0f b7 8f 04 00 00 80 	movzwl -0x7ffffffc(%edi),%ecx
    for (i = 0; i < len; i++)
8010060b:	66 85 c9             	test   %cx,%cx
8010060e:	0f 84 91 00 00 00    	je     801006a5 <mcpu_init+0x130>
80100614:	89 f8                	mov    %edi,%eax
80100616:	0f b7 c9             	movzwl %cx,%ecx
80100619:	01 cf                	add    %ecx,%edi
        sum += addr[i];
8010061b:	0f b6 88 00 00 00 80 	movzbl -0x80000000(%eax),%ecx
80100622:	01 ca                	add    %ecx,%edx
    for (i = 0; i < len; i++)
80100624:	83 c0 01             	add    $0x1,%eax
80100627:	39 f8                	cmp    %edi,%eax
80100629:	75 f0                	jne    8010061b <mcpu_init+0xa6>
        return 0;
8010062b:	84 d2                	test   %dl,%dl
8010062d:	b8 00 00 00 00       	mov    $0x0,%eax
80100632:	0f 45 f0             	cmovne %eax,%esi
80100635:	0f 45 d8             	cmovne %eax,%ebx
80100638:	89 5d e0             	mov    %ebx,-0x20(%ebp)
    struct mpproc* proc;
    struct mpioapic* ioapic;

    conf = mpconfig(&mp);
    ismp = 1;
    lapic = (uint32_t*)conf->lapicaddr;
8010063b:	8b 46 24             	mov    0x24(%esi),%eax
8010063e:	a3 c0 38 10 80       	mov    %eax,0x801038c0
    for (p = (uint8_t*)(conf + 1), e = (uint8_t*)conf + conf->length; p < e;) {
80100643:	8d 46 2c             	lea    0x2c(%esi),%eax
80100646:	0f b7 56 04          	movzwl 0x4(%esi),%edx
8010064a:	01 f2                	add    %esi,%edx
    ismp = 1;
8010064c:	bb 01 00 00 00       	mov    $0x1,%ebx
        switch (*p) {
80100651:	be 00 00 00 00       	mov    $0x0,%esi
80100656:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
    for (p = (uint8_t*)(conf + 1), e = (uint8_t*)conf + conf->length; p < e;) {
80100659:	eb 5a                	jmp    801006b5 <mcpu_init+0x140>
        p = ((bda[0x14] << 8) | bda[0x13]) * 1024;
8010065b:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80100662:	c1 e0 08             	shl    $0x8,%eax
80100665:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
8010066c:	09 d0                	or     %edx,%eax
8010066e:	c1 e0 0a             	shl    $0xa,%eax
        if ((mp = mpsearch1(p - 1024, 1024)))
80100671:	2d 00 04 00 00       	sub    $0x400,%eax
80100676:	ba 00 04 00 00       	mov    $0x400,%edx
8010067b:	e8 30 fd ff ff       	call   801003b0 <mpsearch1>
80100680:	89 c3                	mov    %eax,%ebx
80100682:	85 c0                	test   %eax,%eax
80100684:	0f 85 39 ff ff ff    	jne    801005c3 <mcpu_init+0x4e>
8010068a:	e9 1b ff ff ff       	jmp    801005aa <mcpu_init+0x35>
        return 0;
8010068f:	89 c6                	mov    %eax,%esi
80100691:	eb a8                	jmp    8010063b <mcpu_init+0xc6>
80100693:	89 fe                	mov    %edi,%esi
80100695:	eb a4                	jmp    8010063b <mcpu_init+0xc6>
        return 0;
80100697:	be 00 00 00 00       	mov    $0x0,%esi
8010069c:	eb 9d                	jmp    8010063b <mcpu_init+0xc6>
        return 0;
8010069e:	be 00 00 00 00       	mov    $0x0,%esi
801006a3:	eb 96                	jmp    8010063b <mcpu_init+0xc6>
    for (i = 0; i < len; i++)
801006a5:	89 5d e0             	mov    %ebx,-0x20(%ebp)
801006a8:	eb 91                	jmp    8010063b <mcpu_init+0xc6>
        switch (*p) {
801006aa:	83 e9 03             	sub    $0x3,%ecx
801006ad:	80 f9 01             	cmp    $0x1,%cl
801006b0:	76 15                	jbe    801006c7 <mcpu_init+0x152>
801006b2:	89 75 e4             	mov    %esi,-0x1c(%ebp)
    for (p = (uint8_t*)(conf + 1), e = (uint8_t*)conf + conf->length; p < e;) {
801006b5:	39 d0                	cmp    %edx,%eax
801006b7:	73 4b                	jae    80100704 <mcpu_init+0x18f>
        switch (*p) {
801006b9:	0f b6 08             	movzbl (%eax),%ecx
801006bc:	80 f9 02             	cmp    $0x2,%cl
801006bf:	74 34                	je     801006f5 <mcpu_init+0x180>
801006c1:	77 e7                	ja     801006aa <mcpu_init+0x135>
801006c3:	84 c9                	test   %cl,%cl
801006c5:	74 05                	je     801006cc <mcpu_init+0x157>
            p += sizeof(struct mpioapic);
            continue;
        case MPBUS:
        case MPIOINTR:
        case MPLINTR:
            p += 8;
801006c7:	83 c0 08             	add    $0x8,%eax
            continue;
801006ca:	eb e9                	jmp    801006b5 <mcpu_init+0x140>
            if (num_cpu < MAX_CPU) {
801006cc:	8b 0d 24 33 10 80    	mov    0x80103324,%ecx
801006d2:	83 f9 07             	cmp    $0x7,%ecx
801006d5:	7f 19                	jg     801006f0 <mcpu_init+0x17b>
                cpus[num_cpu].apicid = proc->apicid; // apicid may differ from num_cpu
801006d7:	69 f9 b0 00 00 00    	imul   $0xb0,%ecx,%edi
801006dd:	0f b6 58 01          	movzbl 0x1(%eax),%ebx
801006e1:	88 9f 40 33 10 80    	mov    %bl,-0x7fefccc0(%edi)
                num_cpu++;
801006e7:	83 c1 01             	add    $0x1,%ecx
801006ea:	89 0d 24 33 10 80    	mov    %ecx,0x80103324
            p += sizeof(struct mpproc);
801006f0:	83 c0 14             	add    $0x14,%eax
            continue;
801006f3:	eb c0                	jmp    801006b5 <mcpu_init+0x140>
            ioapicid = ioapic->apicno;
801006f5:	0f b6 48 01          	movzbl 0x1(%eax),%ecx
801006f9:	88 0d 20 33 10 80    	mov    %cl,0x80103320
            p += sizeof(struct mpioapic);
801006ff:	83 c0 08             	add    $0x8,%eax
            continue;
80100702:	eb b1                	jmp    801006b5 <mcpu_init+0x140>
        default:
            ismp = 0;
            break;
        }
    }
    if (!ismp) {
80100704:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80100707:	85 db                	test   %ebx,%ebx
80100709:	74 2b                	je     80100736 <mcpu_init+0x1c1>
        cprintf("Didn't find a suitable machine");
        hlt();
    }

    if (mp->imcrp) {
8010070b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010070e:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80100712:	74 15                	je     80100729 <mcpu_init+0x1b4>
    asm volatile("outb %0,%w1"
80100714:	b8 70 00 00 00       	mov    $0x70,%eax
80100719:	ba 22 00 00 00       	mov    $0x22,%edx
8010071e:	ee                   	out    %al,(%dx)
    asm volatile("inb %w1,%0"
8010071f:	ba 23 00 00 00       	mov    $0x23,%edx
80100724:	ec                   	in     (%dx),%al
        // Bochs doesn't support IMCR, so this doesn't run on Bochs.
        // But it would on real hardware.
        outb(0x22, 0x70); // Select IMCR
        outb(0x23, inb(0x23) | 1); // Mask external interrupts.
80100725:	83 c8 01             	or     $0x1,%eax
    asm volatile("outb %0,%w1"
80100728:	ee                   	out    %al,(%dx)
    }
    seginit();
80100729:	e8 60 fd ff ff       	call   8010048e <seginit>
8010072e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100731:	5b                   	pop    %ebx
80100732:	5e                   	pop    %esi
80100733:	5f                   	pop    %edi
80100734:	5d                   	pop    %ebp
80100735:	c3                   	ret    
        cprintf("Didn't find a suitable machine");
80100736:	83 ec 0c             	sub    $0xc,%esp
80100739:	68 c4 10 10 80       	push   $0x801010c4
8010073e:	e8 62 05 00 00       	call   80100ca5 <cprintf>
    asm volatile("hlt");
80100743:	f4                   	hlt    
}
80100744:	83 c4 10             	add    $0x10,%esp
80100747:	eb c2                	jmp    8010070b <mcpu_init+0x196>

80100749 <lapicid>:

extern volatile uint32_t* lapic;

int lapicid(void)
{
    if (!lapic)
80100749:	a1 c0 38 10 80       	mov    0x801038c0,%eax
8010074e:	85 c0                	test   %eax,%eax
80100750:	74 07                	je     80100759 <lapicid+0x10>
        return 0;
    return lapic[ID] >> 24;
80100752:	8b 40 20             	mov    0x20(%eax),%eax
80100755:	c1 e8 18             	shr    $0x18,%eax
80100758:	c3                   	ret    
        return 0;
80100759:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010075e:	c3                   	ret    

8010075f <serial_proc_data>:
    asm volatile("inb %w1,%0"
8010075f:	ba fd 03 00 00       	mov    $0x3fd,%edx
80100764:	ec                   	in     (%dx),%al
static bool serial_exists;

static int
serial_proc_data(void)
{
    if (!(inb(COM1 + COM_LSR) & COM_LSR_DATA))
80100765:	a8 01                	test   $0x1,%al
80100767:	74 0a                	je     80100773 <serial_proc_data+0x14>
80100769:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010076e:	ec                   	in     (%dx),%al
        return -1;
    return inb(COM1 + COM_RX);
8010076f:	0f b6 c0             	movzbl %al,%eax
80100772:	c3                   	ret    
        return -1;
80100773:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100778:	c3                   	ret    

80100779 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
80100779:	55                   	push   %ebp
8010077a:	89 e5                	mov    %esp,%ebp
8010077c:	53                   	push   %ebx
8010077d:	83 ec 04             	sub    $0x4,%esp
80100780:	89 c3                	mov    %eax,%ebx
    int c;

    while ((c = (*proc)()) != -1) {
80100782:	eb 23                	jmp    801007a7 <cons_intr+0x2e>
        if (c == 0)
            continue;
        cons.buf[cons.wpos++] = c;
80100784:	8b 0d 04 3b 10 80    	mov    0x80103b04,%ecx
8010078a:	8d 51 01             	lea    0x1(%ecx),%edx
8010078d:	88 81 00 39 10 80    	mov    %al,-0x7fefc700(%ecx)
        if (cons.wpos == CONSBUFSIZE)
80100793:	81 fa 00 02 00 00    	cmp    $0x200,%edx
            cons.wpos = 0;
80100799:	b8 00 00 00 00       	mov    $0x0,%eax
8010079e:	0f 44 d0             	cmove  %eax,%edx
801007a1:	89 15 04 3b 10 80    	mov    %edx,0x80103b04
    while ((c = (*proc)()) != -1) {
801007a7:	ff d3                	call   *%ebx
801007a9:	83 f8 ff             	cmp    $0xffffffff,%eax
801007ac:	74 06                	je     801007b4 <cons_intr+0x3b>
        if (c == 0)
801007ae:	85 c0                	test   %eax,%eax
801007b0:	75 d2                	jne    80100784 <cons_intr+0xb>
801007b2:	eb f3                	jmp    801007a7 <cons_intr+0x2e>
    }
}
801007b4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801007b7:	c9                   	leave  
801007b8:	c3                   	ret    

801007b9 <memset>:
{
801007b9:	55                   	push   %ebp
801007ba:	89 e5                	mov    %esp,%ebp
801007bc:	57                   	push   %edi
801007bd:	8b 55 08             	mov    0x8(%ebp),%edx
801007c0:	8b 4d 10             	mov    0x10(%ebp),%ecx
    if ((int)dst % 4 == 0 && n % 4 == 0) {
801007c3:	89 d0                	mov    %edx,%eax
801007c5:	09 c8                	or     %ecx,%eax
801007c7:	a8 03                	test   $0x3,%al
801007c9:	75 14                	jne    801007df <memset+0x26>
        stosl(dst, (c << 24) | (c << 16) | (c << 8) | c, n / 4);
801007cb:	c1 e9 02             	shr    $0x2,%ecx
        c &= 0xFF;
801007ce:	0f b6 45 0c          	movzbl 0xc(%ebp),%eax
        stosl(dst, (c << 24) | (c << 16) | (c << 8) | c, n / 4);
801007d2:	69 c0 01 01 01 01    	imul   $0x1010101,%eax,%eax
    asm volatile("cld; rep stosl"
801007d8:	89 d7                	mov    %edx,%edi
801007da:	fc                   	cld    
801007db:	f3 ab                	rep stos %eax,%es:(%edi)
}
801007dd:	eb 08                	jmp    801007e7 <memset+0x2e>
    asm volatile("cld; rep stosb"
801007df:	89 d7                	mov    %edx,%edi
801007e1:	8b 45 0c             	mov    0xc(%ebp),%eax
801007e4:	fc                   	cld    
801007e5:	f3 aa                	rep stos %al,%es:(%edi)
}
801007e7:	89 d0                	mov    %edx,%eax
801007e9:	8b 7d fc             	mov    -0x4(%ebp),%edi
801007ec:	c9                   	leave  
801007ed:	c3                   	ret    

801007ee <memcmp>:
{
801007ee:	55                   	push   %ebp
801007ef:	89 e5                	mov    %esp,%ebp
801007f1:	56                   	push   %esi
801007f2:	53                   	push   %ebx
801007f3:	8b 45 08             	mov    0x8(%ebp),%eax
801007f6:	8b 55 0c             	mov    0xc(%ebp),%edx
801007f9:	8b 75 10             	mov    0x10(%ebp),%esi
    while (n-- > 0) {
801007fc:	85 f6                	test   %esi,%esi
801007fe:	74 29                	je     80100829 <memcmp+0x3b>
80100800:	01 c6                	add    %eax,%esi
        if (*s1 != *s2)
80100802:	0f b6 08             	movzbl (%eax),%ecx
80100805:	0f b6 1a             	movzbl (%edx),%ebx
80100808:	38 d9                	cmp    %bl,%cl
8010080a:	75 11                	jne    8010081d <memcmp+0x2f>
        s1++, s2++;
8010080c:	83 c0 01             	add    $0x1,%eax
8010080f:	83 c2 01             	add    $0x1,%edx
    while (n-- > 0) {
80100812:	39 c6                	cmp    %eax,%esi
80100814:	75 ec                	jne    80100802 <memcmp+0x14>
    return 0;
80100816:	b8 00 00 00 00       	mov    $0x0,%eax
8010081b:	eb 08                	jmp    80100825 <memcmp+0x37>
            return *s1 - *s2;
8010081d:	0f b6 c1             	movzbl %cl,%eax
80100820:	0f b6 db             	movzbl %bl,%ebx
80100823:	29 d8                	sub    %ebx,%eax
}
80100825:	5b                   	pop    %ebx
80100826:	5e                   	pop    %esi
80100827:	5d                   	pop    %ebp
80100828:	c3                   	ret    
    return 0;
80100829:	b8 00 00 00 00       	mov    $0x0,%eax
8010082e:	eb f5                	jmp    80100825 <memcmp+0x37>

80100830 <memmove>:
{
80100830:	55                   	push   %ebp
80100831:	89 e5                	mov    %esp,%ebp
80100833:	56                   	push   %esi
80100834:	53                   	push   %ebx
80100835:	8b 75 08             	mov    0x8(%ebp),%esi
80100838:	8b 45 0c             	mov    0xc(%ebp),%eax
8010083b:	8b 4d 10             	mov    0x10(%ebp),%ecx
    if (s < d && s + n > d) {
8010083e:	39 f0                	cmp    %esi,%eax
80100840:	72 20                	jb     80100862 <memmove+0x32>
        while (n-- > 0)
80100842:	8d 1c 08             	lea    (%eax,%ecx,1),%ebx
80100845:	89 f2                	mov    %esi,%edx
80100847:	85 c9                	test   %ecx,%ecx
80100849:	74 11                	je     8010085c <memmove+0x2c>
            *d++ = *s++;
8010084b:	83 c0 01             	add    $0x1,%eax
8010084e:	83 c2 01             	add    $0x1,%edx
80100851:	0f b6 48 ff          	movzbl -0x1(%eax),%ecx
80100855:	88 4a ff             	mov    %cl,-0x1(%edx)
        while (n-- > 0)
80100858:	39 d8                	cmp    %ebx,%eax
8010085a:	75 ef                	jne    8010084b <memmove+0x1b>
}
8010085c:	89 f0                	mov    %esi,%eax
8010085e:	5b                   	pop    %ebx
8010085f:	5e                   	pop    %esi
80100860:	5d                   	pop    %ebp
80100861:	c3                   	ret    
    if (s < d && s + n > d) {
80100862:	8d 14 08             	lea    (%eax,%ecx,1),%edx
80100865:	39 d6                	cmp    %edx,%esi
80100867:	73 d9                	jae    80100842 <memmove+0x12>
        while (n-- > 0)
80100869:	8d 51 ff             	lea    -0x1(%ecx),%edx
8010086c:	85 c9                	test   %ecx,%ecx
8010086e:	74 ec                	je     8010085c <memmove+0x2c>
            *--d = *--s;
80100870:	0f b6 0c 10          	movzbl (%eax,%edx,1),%ecx
80100874:	88 0c 16             	mov    %cl,(%esi,%edx,1)
        while (n-- > 0)
80100877:	83 ea 01             	sub    $0x1,%edx
8010087a:	83 fa ff             	cmp    $0xffffffff,%edx
8010087d:	75 f1                	jne    80100870 <memmove+0x40>
8010087f:	eb db                	jmp    8010085c <memmove+0x2c>

80100881 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
80100881:	55                   	push   %ebp
80100882:	89 e5                	mov    %esp,%ebp
80100884:	57                   	push   %edi
80100885:	56                   	push   %esi
80100886:	53                   	push   %ebx
80100887:	83 ec 1c             	sub    $0x1c,%esp
8010088a:	89 c7                	mov    %eax,%edi
    asm volatile("inb %w1,%0"
8010088c:	ba fd 03 00 00       	mov    $0x3fd,%edx
80100891:	ec                   	in     (%dx),%al
         !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
80100892:	a8 20                	test   $0x20,%al
80100894:	75 27                	jne    801008bd <cons_putc+0x3c>
    for (i = 0;
80100896:	bb 00 00 00 00       	mov    $0x0,%ebx
8010089b:	b9 84 00 00 00       	mov    $0x84,%ecx
801008a0:	be fd 03 00 00       	mov    $0x3fd,%esi
801008a5:	89 ca                	mov    %ecx,%edx
801008a7:	ec                   	in     (%dx),%al
801008a8:	ec                   	in     (%dx),%al
801008a9:	ec                   	in     (%dx),%al
801008aa:	ec                   	in     (%dx),%al
         i++)
801008ab:	83 c3 01             	add    $0x1,%ebx
801008ae:	89 f2                	mov    %esi,%edx
801008b0:	ec                   	in     (%dx),%al
         !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
801008b1:	a8 20                	test   $0x20,%al
801008b3:	75 08                	jne    801008bd <cons_putc+0x3c>
801008b5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
801008bb:	7e e8                	jle    801008a5 <cons_putc+0x24>
    outb(COM1 + COM_TX, c);
801008bd:	89 f8                	mov    %edi,%eax
801008bf:	88 45 e7             	mov    %al,-0x19(%ebp)
    asm volatile("outb %0,%w1"
801008c2:	ba f8 03 00 00       	mov    $0x3f8,%edx
801008c7:	ee                   	out    %al,(%dx)
    asm volatile("inb %w1,%0"
801008c8:	ba 79 03 00 00       	mov    $0x379,%edx
801008cd:	ec                   	in     (%dx),%al
    for (i = 0; !(inb(0x378 + 1) & 0x80) && i < 12800; i++)
801008ce:	84 c0                	test   %al,%al
801008d0:	78 27                	js     801008f9 <cons_putc+0x78>
801008d2:	bb 00 00 00 00       	mov    $0x0,%ebx
801008d7:	b9 84 00 00 00       	mov    $0x84,%ecx
801008dc:	be 79 03 00 00       	mov    $0x379,%esi
801008e1:	89 ca                	mov    %ecx,%edx
801008e3:	ec                   	in     (%dx),%al
801008e4:	ec                   	in     (%dx),%al
801008e5:	ec                   	in     (%dx),%al
801008e6:	ec                   	in     (%dx),%al
801008e7:	83 c3 01             	add    $0x1,%ebx
801008ea:	89 f2                	mov    %esi,%edx
801008ec:	ec                   	in     (%dx),%al
801008ed:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
801008f3:	7f 04                	jg     801008f9 <cons_putc+0x78>
801008f5:	84 c0                	test   %al,%al
801008f7:	79 e8                	jns    801008e1 <cons_putc+0x60>
    asm volatile("outb %0,%w1"
801008f9:	ba 78 03 00 00       	mov    $0x378,%edx
801008fe:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
80100902:	ee                   	out    %al,(%dx)
80100903:	ba 7a 03 00 00       	mov    $0x37a,%edx
80100908:	b8 0d 00 00 00       	mov    $0xd,%eax
8010090d:	ee                   	out    %al,(%dx)
8010090e:	b8 08 00 00 00       	mov    $0x8,%eax
80100913:	ee                   	out    %al,(%dx)
        c |= 0x0700;
80100914:	89 f8                	mov    %edi,%eax
80100916:	80 cc 07             	or     $0x7,%ah
80100919:	81 ff 00 01 00 00    	cmp    $0x100,%edi
8010091f:	0f 42 f8             	cmovb  %eax,%edi
    switch (c & 0xff) {
80100922:	89 f8                	mov    %edi,%eax
80100924:	0f b6 c0             	movzbl %al,%eax
80100927:	89 fb                	mov    %edi,%ebx
80100929:	80 fb 0a             	cmp    $0xa,%bl
8010092c:	0f 84 e4 00 00 00    	je     80100a16 <cons_putc+0x195>
80100932:	83 f8 0a             	cmp    $0xa,%eax
80100935:	7f 46                	jg     8010097d <cons_putc+0xfc>
80100937:	83 f8 08             	cmp    $0x8,%eax
8010093a:	0f 84 aa 00 00 00    	je     801009ea <cons_putc+0x169>
80100940:	83 f8 09             	cmp    $0x9,%eax
80100943:	0f 85 da 00 00 00    	jne    80100a23 <cons_putc+0x1a2>
        cons_putc(' ');
80100949:	b8 20 00 00 00       	mov    $0x20,%eax
8010094e:	e8 2e ff ff ff       	call   80100881 <cons_putc>
        cons_putc(' ');
80100953:	b8 20 00 00 00       	mov    $0x20,%eax
80100958:	e8 24 ff ff ff       	call   80100881 <cons_putc>
        cons_putc(' ');
8010095d:	b8 20 00 00 00       	mov    $0x20,%eax
80100962:	e8 1a ff ff ff       	call   80100881 <cons_putc>
        cons_putc(' ');
80100967:	b8 20 00 00 00       	mov    $0x20,%eax
8010096c:	e8 10 ff ff ff       	call   80100881 <cons_putc>
        cons_putc(' ');
80100971:	b8 20 00 00 00       	mov    $0x20,%eax
80100976:	e8 06 ff ff ff       	call   80100881 <cons_putc>
        break;
8010097b:	eb 25                	jmp    801009a2 <cons_putc+0x121>
    switch (c & 0xff) {
8010097d:	83 f8 0d             	cmp    $0xd,%eax
80100980:	0f 85 9d 00 00 00    	jne    80100a23 <cons_putc+0x1a2>
        crt_pos -= (crt_pos % CRT_COLS);
80100986:	0f b7 05 08 3b 10 80 	movzwl 0x80103b08,%eax
8010098d:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
80100993:	c1 e8 16             	shr    $0x16,%eax
80100996:	8d 04 80             	lea    (%eax,%eax,4),%eax
80100999:	c1 e0 04             	shl    $0x4,%eax
8010099c:	66 a3 08 3b 10 80    	mov    %ax,0x80103b08
    if (crt_pos >= CRT_SIZE) // 当输出字符超过终端范围
801009a2:	0f b7 1d 08 3b 10 80 	movzwl 0x80103b08,%ebx
801009a9:	66 81 fb cf 07       	cmp    $0x7cf,%bx
801009ae:	0f 87 92 00 00 00    	ja     80100a46 <cons_putc+0x1c5>
    outb(addr_6845, 14);
801009b4:	8b 0d 10 3b 10 80    	mov    0x80103b10,%ecx
801009ba:	b8 0e 00 00 00       	mov    $0xe,%eax
801009bf:	89 ca                	mov    %ecx,%edx
801009c1:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos >> 8);
801009c2:	0f b7 1d 08 3b 10 80 	movzwl 0x80103b08,%ebx
801009c9:	8d 71 01             	lea    0x1(%ecx),%esi
801009cc:	89 d8                	mov    %ebx,%eax
801009ce:	66 c1 e8 08          	shr    $0x8,%ax
801009d2:	89 f2                	mov    %esi,%edx
801009d4:	ee                   	out    %al,(%dx)
801009d5:	b8 0f 00 00 00       	mov    $0xf,%eax
801009da:	89 ca                	mov    %ecx,%edx
801009dc:	ee                   	out    %al,(%dx)
801009dd:	89 d8                	mov    %ebx,%eax
801009df:	89 f2                	mov    %esi,%edx
801009e1:	ee                   	out    %al,(%dx)
    serial_putc(c); // 向串口输出
    lpt_putc(c);
    cga_putc(c); // 向控制台输出字符
}
801009e2:	8d 65 f4             	lea    -0xc(%ebp),%esp
801009e5:	5b                   	pop    %ebx
801009e6:	5e                   	pop    %esi
801009e7:	5f                   	pop    %edi
801009e8:	5d                   	pop    %ebp
801009e9:	c3                   	ret    
        if (crt_pos > 0) {
801009ea:	0f b7 05 08 3b 10 80 	movzwl 0x80103b08,%eax
801009f1:	66 85 c0             	test   %ax,%ax
801009f4:	74 be                	je     801009b4 <cons_putc+0x133>
            crt_pos--;
801009f6:	83 e8 01             	sub    $0x1,%eax
801009f9:	66 a3 08 3b 10 80    	mov    %ax,0x80103b08
            crt_buf[crt_pos] = (c & ~0xff) | ' ';
801009ff:	0f b7 c0             	movzwl %ax,%eax
80100a02:	66 81 e7 00 ff       	and    $0xff00,%di
80100a07:	83 cf 20             	or     $0x20,%edi
80100a0a:	8b 15 0c 3b 10 80    	mov    0x80103b0c,%edx
80100a10:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
80100a14:	eb 8c                	jmp    801009a2 <cons_putc+0x121>
        crt_pos += CRT_COLS;
80100a16:	66 83 05 08 3b 10 80 	addw   $0x50,0x80103b08
80100a1d:	50 
80100a1e:	e9 63 ff ff ff       	jmp    80100986 <cons_putc+0x105>
        crt_buf[crt_pos++] = c; /* write the character */
80100a23:	0f b7 05 08 3b 10 80 	movzwl 0x80103b08,%eax
80100a2a:	8d 50 01             	lea    0x1(%eax),%edx
80100a2d:	66 89 15 08 3b 10 80 	mov    %dx,0x80103b08
80100a34:	0f b7 c0             	movzwl %ax,%eax
80100a37:	8b 15 0c 3b 10 80    	mov    0x80103b0c,%edx
80100a3d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
        break;
80100a41:	e9 5c ff ff ff       	jmp    801009a2 <cons_putc+0x121>
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t)); // 已有字符往上移动一行
80100a46:	8b 35 0c 3b 10 80    	mov    0x80103b0c,%esi
80100a4c:	83 ec 04             	sub    $0x4,%esp
80100a4f:	68 00 0f 00 00       	push   $0xf00
80100a54:	8d 86 a0 00 00 00    	lea    0xa0(%esi),%eax
80100a5a:	50                   	push   %eax
80100a5b:	56                   	push   %esi
80100a5c:	e8 cf fd ff ff       	call   80100830 <memmove>
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++) // 清零最后一行
80100a61:	8d 86 00 0f 00 00    	lea    0xf00(%esi),%eax
80100a67:	8d 96 a0 0f 00 00    	lea    0xfa0(%esi),%edx
80100a6d:	83 c4 10             	add    $0x10,%esp
            crt_buf[i] = 0x0700 | ' ';
80100a70:	66 c7 00 20 07       	movw   $0x720,(%eax)
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++) // 清零最后一行
80100a75:	83 c0 02             	add    $0x2,%eax
80100a78:	39 d0                	cmp    %edx,%eax
80100a7a:	75 f4                	jne    80100a70 <cons_putc+0x1ef>
        crt_pos -= CRT_COLS; // 索引向前移动，即从最后一行的开头写入
80100a7c:	83 eb 50             	sub    $0x50,%ebx
80100a7f:	66 89 1d 08 3b 10 80 	mov    %bx,0x80103b08
80100a86:	e9 29 ff ff ff       	jmp    801009b4 <cons_putc+0x133>

80100a8b <printint>:
    return 1;
}

static void
printint(int xx, int base, int sign)
{
80100a8b:	55                   	push   %ebp
80100a8c:	89 e5                	mov    %esp,%ebp
80100a8e:	57                   	push   %edi
80100a8f:	56                   	push   %esi
80100a90:	53                   	push   %ebx
80100a91:	83 ec 2c             	sub    $0x2c,%esp
80100a94:	89 d3                	mov    %edx,%ebx
    static char digits[] = "0123456789abcdef";
    char buf[16];
    int i;
    uint32_t x;

    if (sign && (sign = xx < 0))
80100a96:	85 c9                	test   %ecx,%ecx
80100a98:	74 04                	je     80100a9e <printint+0x13>
80100a9a:	85 c0                	test   %eax,%eax
80100a9c:	78 61                	js     80100aff <printint+0x74>
        x = -xx;
    else
        x = xx;
80100a9e:	89 c1                	mov    %eax,%ecx
80100aa0:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

    i = 0;
80100aa7:	bf 00 00 00 00       	mov    $0x0,%edi
    do {
        buf[i++] = digits[x % base];
80100aac:	89 fe                	mov    %edi,%esi
80100aae:	83 c7 01             	add    $0x1,%edi
80100ab1:	89 c8                	mov    %ecx,%eax
80100ab3:	ba 00 00 00 00       	mov    $0x0,%edx
80100ab8:	f7 f3                	div    %ebx
80100aba:	0f b6 92 20 11 10 80 	movzbl -0x7fefeee0(%edx),%edx
80100ac1:	88 54 3d d7          	mov    %dl,-0x29(%ebp,%edi,1)
    } while ((x /= base) != 0);
80100ac5:	89 ca                	mov    %ecx,%edx
80100ac7:	89 c1                	mov    %eax,%ecx
80100ac9:	39 da                	cmp    %ebx,%edx
80100acb:	73 df                	jae    80100aac <printint+0x21>

    if (sign)
80100acd:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100ad1:	74 08                	je     80100adb <printint+0x50>
        buf[i++] = '-';
80100ad3:	c6 44 3d d8 2d       	movb   $0x2d,-0x28(%ebp,%edi,1)
80100ad8:	8d 7e 02             	lea    0x2(%esi),%edi

    while (--i >= 0)
80100adb:	85 ff                	test   %edi,%edi
80100add:	7e 18                	jle    80100af7 <printint+0x6c>
80100adf:	8d 75 d8             	lea    -0x28(%ebp),%esi
80100ae2:	8d 5c 3d d7          	lea    -0x29(%ebp,%edi,1),%ebx
        cons_putc(buf[i]);
80100ae6:	0f be 03             	movsbl (%ebx),%eax
80100ae9:	e8 93 fd ff ff       	call   80100881 <cons_putc>
    while (--i >= 0)
80100aee:	89 d8                	mov    %ebx,%eax
80100af0:	83 eb 01             	sub    $0x1,%ebx
80100af3:	39 f0                	cmp    %esi,%eax
80100af5:	75 ef                	jne    80100ae6 <printint+0x5b>
}
80100af7:	83 c4 2c             	add    $0x2c,%esp
80100afa:	5b                   	pop    %ebx
80100afb:	5e                   	pop    %esi
80100afc:	5f                   	pop    %edi
80100afd:	5d                   	pop    %ebp
80100afe:	c3                   	ret    
        x = -xx;
80100aff:	f7 d8                	neg    %eax
80100b01:	89 c1                	mov    %eax,%ecx
    if (sign && (sign = xx < 0))
80100b03:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
        x = -xx;
80100b0a:	eb 9b                	jmp    80100aa7 <printint+0x1c>

80100b0c <memcpy>:
{
80100b0c:	55                   	push   %ebp
80100b0d:	89 e5                	mov    %esp,%ebp
80100b0f:	83 ec 0c             	sub    $0xc,%esp
    return memmove(dst, src, n);
80100b12:	ff 75 10             	push   0x10(%ebp)
80100b15:	ff 75 0c             	push   0xc(%ebp)
80100b18:	ff 75 08             	push   0x8(%ebp)
80100b1b:	e8 10 fd ff ff       	call   80100830 <memmove>
}
80100b20:	c9                   	leave  
80100b21:	c3                   	ret    

80100b22 <strncmp>:
{
80100b22:	55                   	push   %ebp
80100b23:	89 e5                	mov    %esp,%ebp
80100b25:	53                   	push   %ebx
80100b26:	8b 55 08             	mov    0x8(%ebp),%edx
80100b29:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80100b2c:	8b 45 10             	mov    0x10(%ebp),%eax
    while (n > 0 && *p && *p == *q)
80100b2f:	85 c0                	test   %eax,%eax
80100b31:	74 29                	je     80100b5c <strncmp+0x3a>
80100b33:	0f b6 1a             	movzbl (%edx),%ebx
80100b36:	84 db                	test   %bl,%bl
80100b38:	74 16                	je     80100b50 <strncmp+0x2e>
80100b3a:	3a 19                	cmp    (%ecx),%bl
80100b3c:	75 12                	jne    80100b50 <strncmp+0x2e>
        n--, p++, q++;
80100b3e:	83 c2 01             	add    $0x1,%edx
80100b41:	83 c1 01             	add    $0x1,%ecx
    while (n > 0 && *p && *p == *q)
80100b44:	83 e8 01             	sub    $0x1,%eax
80100b47:	75 ea                	jne    80100b33 <strncmp+0x11>
        return 0;
80100b49:	b8 00 00 00 00       	mov    $0x0,%eax
80100b4e:	eb 0c                	jmp    80100b5c <strncmp+0x3a>
    if (n == 0)
80100b50:	85 c0                	test   %eax,%eax
80100b52:	74 0d                	je     80100b61 <strncmp+0x3f>
    return (uint8_t)*p - (uint8_t)*q;
80100b54:	0f b6 02             	movzbl (%edx),%eax
80100b57:	0f b6 11             	movzbl (%ecx),%edx
80100b5a:	29 d0                	sub    %edx,%eax
}
80100b5c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100b5f:	c9                   	leave  
80100b60:	c3                   	ret    
        return 0;
80100b61:	b8 00 00 00 00       	mov    $0x0,%eax
80100b66:	eb f4                	jmp    80100b5c <strncmp+0x3a>

80100b68 <strncpy>:
{
80100b68:	55                   	push   %ebp
80100b69:	89 e5                	mov    %esp,%ebp
80100b6b:	57                   	push   %edi
80100b6c:	56                   	push   %esi
80100b6d:	53                   	push   %ebx
80100b6e:	8b 75 08             	mov    0x8(%ebp),%esi
80100b71:	8b 55 10             	mov    0x10(%ebp),%edx
    while (n-- > 0 && (*s++ = *t++) != 0)
80100b74:	89 f1                	mov    %esi,%ecx
80100b76:	89 d3                	mov    %edx,%ebx
80100b78:	83 ea 01             	sub    $0x1,%edx
80100b7b:	85 db                	test   %ebx,%ebx
80100b7d:	7e 17                	jle    80100b96 <strncpy+0x2e>
80100b7f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80100b83:	83 c1 01             	add    $0x1,%ecx
80100b86:	8b 45 0c             	mov    0xc(%ebp),%eax
80100b89:	0f b6 78 ff          	movzbl -0x1(%eax),%edi
80100b8d:	89 f8                	mov    %edi,%eax
80100b8f:	88 41 ff             	mov    %al,-0x1(%ecx)
80100b92:	84 c0                	test   %al,%al
80100b94:	75 e0                	jne    80100b76 <strncpy+0xe>
    while (n-- > 0)
80100b96:	89 c8                	mov    %ecx,%eax
80100b98:	8d 4c 19 ff          	lea    -0x1(%ecx,%ebx,1),%ecx
80100b9c:	85 d2                	test   %edx,%edx
80100b9e:	7e 0f                	jle    80100baf <strncpy+0x47>
        *s++ = 0;
80100ba0:	83 c0 01             	add    $0x1,%eax
80100ba3:	c6 40 ff 00          	movb   $0x0,-0x1(%eax)
    while (n-- > 0)
80100ba7:	89 ca                	mov    %ecx,%edx
80100ba9:	29 c2                	sub    %eax,%edx
80100bab:	85 d2                	test   %edx,%edx
80100bad:	7f f1                	jg     80100ba0 <strncpy+0x38>
}
80100baf:	89 f0                	mov    %esi,%eax
80100bb1:	5b                   	pop    %ebx
80100bb2:	5e                   	pop    %esi
80100bb3:	5f                   	pop    %edi
80100bb4:	5d                   	pop    %ebp
80100bb5:	c3                   	ret    

80100bb6 <safestrcpy>:
{
80100bb6:	55                   	push   %ebp
80100bb7:	89 e5                	mov    %esp,%ebp
80100bb9:	56                   	push   %esi
80100bba:	53                   	push   %ebx
80100bbb:	8b 75 08             	mov    0x8(%ebp),%esi
80100bbe:	8b 45 0c             	mov    0xc(%ebp),%eax
80100bc1:	8b 55 10             	mov    0x10(%ebp),%edx
    if (n <= 0)
80100bc4:	85 d2                	test   %edx,%edx
80100bc6:	7e 1e                	jle    80100be6 <safestrcpy+0x30>
80100bc8:	8d 5c 10 ff          	lea    -0x1(%eax,%edx,1),%ebx
80100bcc:	89 f2                	mov    %esi,%edx
    while (--n > 0 && (*s++ = *t++) != 0)
80100bce:	39 d8                	cmp    %ebx,%eax
80100bd0:	74 11                	je     80100be3 <safestrcpy+0x2d>
80100bd2:	83 c0 01             	add    $0x1,%eax
80100bd5:	83 c2 01             	add    $0x1,%edx
80100bd8:	0f b6 48 ff          	movzbl -0x1(%eax),%ecx
80100bdc:	88 4a ff             	mov    %cl,-0x1(%edx)
80100bdf:	84 c9                	test   %cl,%cl
80100be1:	75 eb                	jne    80100bce <safestrcpy+0x18>
    *s = 0;
80100be3:	c6 02 00             	movb   $0x0,(%edx)
}
80100be6:	89 f0                	mov    %esi,%eax
80100be8:	5b                   	pop    %ebx
80100be9:	5e                   	pop    %esi
80100bea:	5d                   	pop    %ebp
80100beb:	c3                   	ret    

80100bec <strlen>:
{
80100bec:	55                   	push   %ebp
80100bed:	89 e5                	mov    %esp,%ebp
80100bef:	8b 55 08             	mov    0x8(%ebp),%edx
    for (n = 0; s[n]; n++)
80100bf2:	80 3a 00             	cmpb   $0x0,(%edx)
80100bf5:	74 10                	je     80100c07 <strlen+0x1b>
80100bf7:	b8 00 00 00 00       	mov    $0x0,%eax
80100bfc:	83 c0 01             	add    $0x1,%eax
80100bff:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80100c03:	75 f7                	jne    80100bfc <strlen+0x10>
}
80100c05:	5d                   	pop    %ebp
80100c06:	c3                   	ret    
    for (n = 0; s[n]; n++)
80100c07:	b8 00 00 00 00       	mov    $0x0,%eax
    return n;
80100c0c:	eb f7                	jmp    80100c05 <strlen+0x19>

80100c0e <serial_intr>:
    if (serial_exists)
80100c0e:	80 3d 14 3b 10 80 00 	cmpb   $0x0,0x80103b14
80100c15:	75 01                	jne    80100c18 <serial_intr+0xa>
80100c17:	c3                   	ret    
{
80100c18:	55                   	push   %ebp
80100c19:	89 e5                	mov    %esp,%ebp
80100c1b:	83 ec 08             	sub    $0x8,%esp
        cons_intr(serial_proc_data);
80100c1e:	b8 5f 07 10 80       	mov    $0x8010075f,%eax
80100c23:	e8 51 fb ff ff       	call   80100779 <cons_intr>
}
80100c28:	c9                   	leave  
80100c29:	c3                   	ret    

80100c2a <kbd_intr>:
{
80100c2a:	55                   	push   %ebp
80100c2b:	89 e5                	mov    %esp,%ebp
80100c2d:	83 ec 08             	sub    $0x8,%esp
    cons_intr(kbd_proc_data);
80100c30:	b8 c0 0d 10 80       	mov    $0x80100dc0,%eax
80100c35:	e8 3f fb ff ff       	call   80100779 <cons_intr>
}
80100c3a:	c9                   	leave  
80100c3b:	c3                   	ret    

80100c3c <cons_getc>:
{
80100c3c:	55                   	push   %ebp
80100c3d:	89 e5                	mov    %esp,%ebp
80100c3f:	83 ec 08             	sub    $0x8,%esp
    serial_intr();
80100c42:	e8 c7 ff ff ff       	call   80100c0e <serial_intr>
    kbd_intr();
80100c47:	e8 de ff ff ff       	call   80100c2a <kbd_intr>
    if (cons.rpos != cons.wpos) {
80100c4c:	a1 00 3b 10 80       	mov    0x80103b00,%eax
    return 0;
80100c51:	ba 00 00 00 00       	mov    $0x0,%edx
    if (cons.rpos != cons.wpos) {
80100c56:	3b 05 04 3b 10 80    	cmp    0x80103b04,%eax
80100c5c:	74 1c                	je     80100c7a <cons_getc+0x3e>
        c = cons.buf[cons.rpos++];
80100c5e:	8d 48 01             	lea    0x1(%eax),%ecx
80100c61:	0f b6 90 00 39 10 80 	movzbl -0x7fefc700(%eax),%edx
            cons.rpos = 0;
80100c68:	3d ff 01 00 00       	cmp    $0x1ff,%eax
80100c6d:	b8 00 00 00 00       	mov    $0x0,%eax
80100c72:	0f 45 c1             	cmovne %ecx,%eax
80100c75:	a3 00 3b 10 80       	mov    %eax,0x80103b00
}
80100c7a:	89 d0                	mov    %edx,%eax
80100c7c:	c9                   	leave  
80100c7d:	c3                   	ret    

80100c7e <cputchar>:
{
80100c7e:	55                   	push   %ebp
80100c7f:	89 e5                	mov    %esp,%ebp
80100c81:	83 ec 08             	sub    $0x8,%esp
    cons_putc(c);
80100c84:	8b 45 08             	mov    0x8(%ebp),%eax
80100c87:	e8 f5 fb ff ff       	call   80100881 <cons_putc>
}
80100c8c:	c9                   	leave  
80100c8d:	c3                   	ret    

80100c8e <getchar>:
{
80100c8e:	55                   	push   %ebp
80100c8f:	89 e5                	mov    %esp,%ebp
80100c91:	83 ec 08             	sub    $0x8,%esp
    while ((c = cons_getc()) == 0)
80100c94:	e8 a3 ff ff ff       	call   80100c3c <cons_getc>
80100c99:	85 c0                	test   %eax,%eax
80100c9b:	74 f7                	je     80100c94 <getchar+0x6>
}
80100c9d:	c9                   	leave  
80100c9e:	c3                   	ret    

80100c9f <iscons>:
}
80100c9f:	b8 01 00 00 00       	mov    $0x1,%eax
80100ca4:	c3                   	ret    

80100ca5 <cprintf>:

void cprintf(char* fmt, ...)
{
80100ca5:	55                   	push   %ebp
80100ca6:	89 e5                	mov    %esp,%ebp
80100ca8:	57                   	push   %edi
80100ca9:	56                   	push   %esi
80100caa:	53                   	push   %ebx
80100cab:	83 ec 1c             	sub    $0x1c,%esp

    // if (fmt == 0)
    //     panic("null fmt");

    argp = (uint32_t*)(void*)(&fmt + 1);
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++) {
80100cae:	8b 7d 08             	mov    0x8(%ebp),%edi
80100cb1:	0f b6 07             	movzbl (%edi),%eax
80100cb4:	85 c0                	test   %eax,%eax
80100cb6:	0f 84 fc 00 00 00    	je     80100db8 <cprintf+0x113>
    argp = (uint32_t*)(void*)(&fmt + 1);
80100cbc:	8d 4d 0c             	lea    0xc(%ebp),%ecx
80100cbf:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++) {
80100cc2:	be 00 00 00 00       	mov    $0x0,%esi
80100cc7:	eb 14                	jmp    80100cdd <cprintf+0x38>
        if (c != '%') {
            cons_putc(c);
80100cc9:	e8 b3 fb ff ff       	call   80100881 <cons_putc>
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++) {
80100cce:	83 c6 01             	add    $0x1,%esi
80100cd1:	0f b6 04 37          	movzbl (%edi,%esi,1),%eax
80100cd5:	85 c0                	test   %eax,%eax
80100cd7:	0f 84 db 00 00 00    	je     80100db8 <cprintf+0x113>
        if (c != '%') {
80100cdd:	83 f8 25             	cmp    $0x25,%eax
80100ce0:	75 e7                	jne    80100cc9 <cprintf+0x24>
            continue;
        }
        c = fmt[++i] & 0xff;
80100ce2:	83 c6 01             	add    $0x1,%esi
80100ce5:	0f b6 1c 37          	movzbl (%edi,%esi,1),%ebx
        if (c == 0)
80100ce9:	85 db                	test   %ebx,%ebx
80100ceb:	0f 84 c7 00 00 00    	je     80100db8 <cprintf+0x113>
            break;
        switch (c) {
80100cf1:	83 fb 70             	cmp    $0x70,%ebx
80100cf4:	74 3a                	je     80100d30 <cprintf+0x8b>
80100cf6:	7f 2e                	jg     80100d26 <cprintf+0x81>
80100cf8:	83 fb 25             	cmp    $0x25,%ebx
80100cfb:	0f 84 92 00 00 00    	je     80100d93 <cprintf+0xee>
80100d01:	83 fb 64             	cmp    $0x64,%ebx
80100d04:	0f 85 98 00 00 00    	jne    80100da2 <cprintf+0xfd>
        case 'd':
            printint(*argp++, 10, 1);
80100d0a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d0d:	8d 58 04             	lea    0x4(%eax),%ebx
80100d10:	8b 00                	mov    (%eax),%eax
80100d12:	b9 01 00 00 00       	mov    $0x1,%ecx
80100d17:	ba 0a 00 00 00       	mov    $0xa,%edx
80100d1c:	e8 6a fd ff ff       	call   80100a8b <printint>
80100d21:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
            break;
80100d24:	eb a8                	jmp    80100cce <cprintf+0x29>
        switch (c) {
80100d26:	83 fb 73             	cmp    $0x73,%ebx
80100d29:	74 21                	je     80100d4c <cprintf+0xa7>
80100d2b:	83 fb 78             	cmp    $0x78,%ebx
80100d2e:	75 72                	jne    80100da2 <cprintf+0xfd>
        case 'x':
        case 'p':
            printint(*argp++, 16, 0);
80100d30:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d33:	8d 58 04             	lea    0x4(%eax),%ebx
80100d36:	8b 00                	mov    (%eax),%eax
80100d38:	b9 00 00 00 00       	mov    $0x0,%ecx
80100d3d:	ba 10 00 00 00       	mov    $0x10,%edx
80100d42:	e8 44 fd ff ff       	call   80100a8b <printint>
80100d47:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
            break;
80100d4a:	eb 82                	jmp    80100cce <cprintf+0x29>
        case 's':
            if ((s = (char*)*argp++) == 0)
80100d4c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d4f:	8d 50 04             	lea    0x4(%eax),%edx
80100d52:	89 55 e0             	mov    %edx,-0x20(%ebp)
80100d55:	8b 00                	mov    (%eax),%eax
80100d57:	85 c0                	test   %eax,%eax
80100d59:	74 11                	je     80100d6c <cprintf+0xc7>
80100d5b:	89 c3                	mov    %eax,%ebx
                s = "(null)";
            for (; *s; s++)
80100d5d:	0f b6 00             	movzbl (%eax),%eax
            if ((s = (char*)*argp++) == 0)
80100d60:	89 55 e4             	mov    %edx,-0x1c(%ebp)
            for (; *s; s++)
80100d63:	84 c0                	test   %al,%al
80100d65:	75 0f                	jne    80100d76 <cprintf+0xd1>
80100d67:	e9 62 ff ff ff       	jmp    80100cce <cprintf+0x29>
                s = "(null)";
80100d6c:	bb e3 10 10 80       	mov    $0x801010e3,%ebx
            for (; *s; s++)
80100d71:	b8 28 00 00 00       	mov    $0x28,%eax
                cons_putc(*s);
80100d76:	0f be c0             	movsbl %al,%eax
80100d79:	e8 03 fb ff ff       	call   80100881 <cons_putc>
            for (; *s; s++)
80100d7e:	83 c3 01             	add    $0x1,%ebx
80100d81:	0f b6 03             	movzbl (%ebx),%eax
80100d84:	84 c0                	test   %al,%al
80100d86:	75 ee                	jne    80100d76 <cprintf+0xd1>
            if ((s = (char*)*argp++) == 0)
80100d88:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d8b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80100d8e:	e9 3b ff ff ff       	jmp    80100cce <cprintf+0x29>
            break;
        case '%':
            cons_putc('%');
80100d93:	b8 25 00 00 00       	mov    $0x25,%eax
80100d98:	e8 e4 fa ff ff       	call   80100881 <cons_putc>
            break;
80100d9d:	e9 2c ff ff ff       	jmp    80100cce <cprintf+0x29>
        default:
            // Print unknown % sequence to draw attention.
            cons_putc('%');
80100da2:	b8 25 00 00 00       	mov    $0x25,%eax
80100da7:	e8 d5 fa ff ff       	call   80100881 <cons_putc>
            cons_putc(c);
80100dac:	89 d8                	mov    %ebx,%eax
80100dae:	e8 ce fa ff ff       	call   80100881 <cons_putc>
            break;
80100db3:	e9 16 ff ff ff       	jmp    80100cce <cprintf+0x29>
        }
    }

    // if (locking)
    //     release(&cons.lock);
}
80100db8:	83 c4 1c             	add    $0x1c,%esp
80100dbb:	5b                   	pop    %ebx
80100dbc:	5e                   	pop    %esi
80100dbd:	5f                   	pop    %edi
80100dbe:	5d                   	pop    %ebp
80100dbf:	c3                   	ret    

80100dc0 <kbd_proc_data>:
{
80100dc0:	55                   	push   %ebp
80100dc1:	89 e5                	mov    %esp,%ebp
80100dc3:	53                   	push   %ebx
80100dc4:	83 ec 04             	sub    $0x4,%esp
    asm volatile("inb %w1,%0"
80100dc7:	ba 64 00 00 00       	mov    $0x64,%edx
80100dcc:	ec                   	in     (%dx),%al
    if ((stat & KBS_DIB) == 0)
80100dcd:	a8 01                	test   $0x1,%al
80100dcf:	0f 84 ee 00 00 00    	je     80100ec3 <kbd_proc_data+0x103>
    if (stat & KBS_TERR)
80100dd5:	a8 20                	test   $0x20,%al
80100dd7:	0f 85 ed 00 00 00    	jne    80100eca <kbd_proc_data+0x10a>
80100ddd:	ba 60 00 00 00       	mov    $0x60,%edx
80100de2:	ec                   	in     (%dx),%al
80100de3:	89 c2                	mov    %eax,%edx
    if (data == 0xE0) {
80100de5:	3c e0                	cmp    $0xe0,%al
80100de7:	74 61                	je     80100e4a <kbd_proc_data+0x8a>
    } else if (data & 0x80) {
80100de9:	84 c0                	test   %al,%al
80100deb:	78 70                	js     80100e5d <kbd_proc_data+0x9d>
    } else if (shift & E0ESC) {
80100ded:	8b 0d e0 38 10 80    	mov    0x801038e0,%ecx
80100df3:	f6 c1 40             	test   $0x40,%cl
80100df6:	74 0e                	je     80100e06 <kbd_proc_data+0x46>
        data |= 0x80;
80100df8:	83 c8 80             	or     $0xffffff80,%eax
80100dfb:	89 c2                	mov    %eax,%edx
        shift &= ~E0ESC;
80100dfd:	83 e1 bf             	and    $0xffffffbf,%ecx
80100e00:	89 0d e0 38 10 80    	mov    %ecx,0x801038e0
    shift |= shiftcode[data];
80100e06:	0f b6 d2             	movzbl %dl,%edx
80100e09:	0f b6 82 60 12 10 80 	movzbl -0x7fefeda0(%edx),%eax
80100e10:	0b 05 e0 38 10 80    	or     0x801038e0,%eax
    shift ^= togglecode[data];
80100e16:	0f b6 8a 60 11 10 80 	movzbl -0x7fefeea0(%edx),%ecx
80100e1d:	31 c8                	xor    %ecx,%eax
80100e1f:	a3 e0 38 10 80       	mov    %eax,0x801038e0
    c = charcode[shift & (CTL | SHIFT)][data];
80100e24:	89 c1                	mov    %eax,%ecx
80100e26:	83 e1 03             	and    $0x3,%ecx
80100e29:	8b 0c 8d 34 11 10 80 	mov    -0x7fefeecc(,%ecx,4),%ecx
80100e30:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
80100e34:	0f b6 da             	movzbl %dl,%ebx
    if (shift & CAPSLOCK) {
80100e37:	a8 08                	test   $0x8,%al
80100e39:	74 5d                	je     80100e98 <kbd_proc_data+0xd8>
        if ('a' <= c && c <= 'z')
80100e3b:	89 da                	mov    %ebx,%edx
80100e3d:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
80100e40:	83 f9 19             	cmp    $0x19,%ecx
80100e43:	77 47                	ja     80100e8c <kbd_proc_data+0xcc>
            c += 'A' - 'a';
80100e45:	83 eb 20             	sub    $0x20,%ebx
    if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
80100e48:	eb 0c                	jmp    80100e56 <kbd_proc_data+0x96>
        shift |= E0ESC;
80100e4a:	83 0d e0 38 10 80 40 	orl    $0x40,0x801038e0
        return 0;
80100e51:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80100e56:	89 d8                	mov    %ebx,%eax
80100e58:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100e5b:	c9                   	leave  
80100e5c:	c3                   	ret    
        data = (shift & E0ESC ? data : data & 0x7F);
80100e5d:	8b 0d e0 38 10 80    	mov    0x801038e0,%ecx
80100e63:	83 e0 7f             	and    $0x7f,%eax
80100e66:	f6 c1 40             	test   $0x40,%cl
80100e69:	0f 44 d0             	cmove  %eax,%edx
        shift &= ~(shiftcode[data] | E0ESC);
80100e6c:	0f b6 d2             	movzbl %dl,%edx
80100e6f:	0f b6 82 60 12 10 80 	movzbl -0x7fefeda0(%edx),%eax
80100e76:	83 c8 40             	or     $0x40,%eax
80100e79:	0f b6 c0             	movzbl %al,%eax
80100e7c:	f7 d0                	not    %eax
80100e7e:	21 c8                	and    %ecx,%eax
80100e80:	a3 e0 38 10 80       	mov    %eax,0x801038e0
        return 0;
80100e85:	bb 00 00 00 00       	mov    $0x0,%ebx
80100e8a:	eb ca                	jmp    80100e56 <kbd_proc_data+0x96>
        else if ('A' <= c && c <= 'Z')
80100e8c:	83 ea 41             	sub    $0x41,%edx
            c += 'a' - 'A';
80100e8f:	8d 4b 20             	lea    0x20(%ebx),%ecx
80100e92:	83 fa 1a             	cmp    $0x1a,%edx
80100e95:	0f 42 d9             	cmovb  %ecx,%ebx
    if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
80100e98:	f7 d0                	not    %eax
80100e9a:	a8 06                	test   $0x6,%al
80100e9c:	75 b8                	jne    80100e56 <kbd_proc_data+0x96>
80100e9e:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
80100ea4:	75 b0                	jne    80100e56 <kbd_proc_data+0x96>
        cprintf("Rebooting!\n");
80100ea6:	83 ec 0c             	sub    $0xc,%esp
80100ea9:	68 ea 10 10 80       	push   $0x801010ea
80100eae:	e8 f2 fd ff ff       	call   80100ca5 <cprintf>
    asm volatile("outb %0,%w1"
80100eb3:	b8 03 00 00 00       	mov    $0x3,%eax
80100eb8:	ba 92 00 00 00       	mov    $0x92,%edx
80100ebd:	ee                   	out    %al,(%dx)
}
80100ebe:	83 c4 10             	add    $0x10,%esp
80100ec1:	eb 93                	jmp    80100e56 <kbd_proc_data+0x96>
        return -1;
80100ec3:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80100ec8:	eb 8c                	jmp    80100e56 <kbd_proc_data+0x96>
        return -1;
80100eca:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80100ecf:	eb 85                	jmp    80100e56 <kbd_proc_data+0x96>

80100ed1 <cons_init>:
{
80100ed1:	55                   	push   %ebp
80100ed2:	89 e5                	mov    %esp,%ebp
80100ed4:	57                   	push   %edi
80100ed5:	56                   	push   %esi
80100ed6:	53                   	push   %ebx
80100ed7:	83 ec 0c             	sub    $0xc,%esp
    was = *cp;
80100eda:	0f b7 15 00 80 0b 80 	movzwl 0x800b8000,%edx
    *cp = (uint16_t)0xA55A;
80100ee1:	66 c7 05 00 80 0b 80 	movw   $0xa55a,0x800b8000
80100ee8:	5a a5 
    if (*cp != 0xA55A) {
80100eea:	0f b7 05 00 80 0b 80 	movzwl 0x800b8000,%eax
80100ef1:	bb b4 03 00 00       	mov    $0x3b4,%ebx
        cp = (uint16_t*)(K_ADDR_BASE + MONO_BUF);
80100ef6:	be 00 00 0b 80       	mov    $0x800b0000,%esi
    if (*cp != 0xA55A) {
80100efb:	66 3d 5a a5          	cmp    $0xa55a,%ax
80100eff:	0f 84 ab 00 00 00    	je     80100fb0 <cons_init+0xdf>
        addr_6845 = MONO_BASE;
80100f05:	89 1d 10 3b 10 80    	mov    %ebx,0x80103b10
    asm volatile("outb %0,%w1"
80100f0b:	b8 0e 00 00 00       	mov    $0xe,%eax
80100f10:	89 da                	mov    %ebx,%edx
80100f12:	ee                   	out    %al,(%dx)
    pos = inb(addr_6845 + 1) << 8;
80100f13:	8d 7b 01             	lea    0x1(%ebx),%edi
    asm volatile("inb %w1,%0"
80100f16:	89 fa                	mov    %edi,%edx
80100f18:	ec                   	in     (%dx),%al
80100f19:	0f b6 c8             	movzbl %al,%ecx
80100f1c:	c1 e1 08             	shl    $0x8,%ecx
    asm volatile("outb %0,%w1"
80100f1f:	b8 0f 00 00 00       	mov    $0xf,%eax
80100f24:	89 da                	mov    %ebx,%edx
80100f26:	ee                   	out    %al,(%dx)
    asm volatile("inb %w1,%0"
80100f27:	89 fa                	mov    %edi,%edx
80100f29:	ec                   	in     (%dx),%al
    crt_buf = (uint16_t*)cp;
80100f2a:	89 35 0c 3b 10 80    	mov    %esi,0x80103b0c
    pos |= inb(addr_6845 + 1);
80100f30:	0f b6 c0             	movzbl %al,%eax
80100f33:	09 c8                	or     %ecx,%eax
    crt_pos = pos;
80100f35:	66 a3 08 3b 10 80    	mov    %ax,0x80103b08
    kbd_intr();
80100f3b:	e8 ea fc ff ff       	call   80100c2a <kbd_intr>
    asm volatile("outb %0,%w1"
80100f40:	b9 00 00 00 00       	mov    $0x0,%ecx
80100f45:	bb fa 03 00 00       	mov    $0x3fa,%ebx
80100f4a:	89 c8                	mov    %ecx,%eax
80100f4c:	89 da                	mov    %ebx,%edx
80100f4e:	ee                   	out    %al,(%dx)
80100f4f:	bf fb 03 00 00       	mov    $0x3fb,%edi
80100f54:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
80100f59:	89 fa                	mov    %edi,%edx
80100f5b:	ee                   	out    %al,(%dx)
80100f5c:	b8 0c 00 00 00       	mov    $0xc,%eax
80100f61:	ba f8 03 00 00       	mov    $0x3f8,%edx
80100f66:	ee                   	out    %al,(%dx)
80100f67:	be f9 03 00 00       	mov    $0x3f9,%esi
80100f6c:	89 c8                	mov    %ecx,%eax
80100f6e:	89 f2                	mov    %esi,%edx
80100f70:	ee                   	out    %al,(%dx)
80100f71:	b8 03 00 00 00       	mov    $0x3,%eax
80100f76:	89 fa                	mov    %edi,%edx
80100f78:	ee                   	out    %al,(%dx)
80100f79:	ba fc 03 00 00       	mov    $0x3fc,%edx
80100f7e:	89 c8                	mov    %ecx,%eax
80100f80:	ee                   	out    %al,(%dx)
80100f81:	b8 01 00 00 00       	mov    $0x1,%eax
80100f86:	89 f2                	mov    %esi,%edx
80100f88:	ee                   	out    %al,(%dx)
    asm volatile("inb %w1,%0"
80100f89:	ba fd 03 00 00       	mov    $0x3fd,%edx
80100f8e:	ec                   	in     (%dx),%al
80100f8f:	89 c1                	mov    %eax,%ecx
    serial_exists = (inb(COM1 + COM_LSR) != 0xFF);
80100f91:	3c ff                	cmp    $0xff,%al
80100f93:	0f 95 05 14 3b 10 80 	setne  0x80103b14
80100f9a:	89 da                	mov    %ebx,%edx
80100f9c:	ec                   	in     (%dx),%al
80100f9d:	ba f8 03 00 00       	mov    $0x3f8,%edx
80100fa2:	ec                   	in     (%dx),%al
    if (!serial_exists)
80100fa3:	80 f9 ff             	cmp    $0xff,%cl
80100fa6:	74 1e                	je     80100fc6 <cons_init+0xf5>
}
80100fa8:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100fab:	5b                   	pop    %ebx
80100fac:	5e                   	pop    %esi
80100fad:	5f                   	pop    %edi
80100fae:	5d                   	pop    %ebp
80100faf:	c3                   	ret    
        *cp = was;
80100fb0:	66 89 15 00 80 0b 80 	mov    %dx,0x800b8000
80100fb7:	bb d4 03 00 00       	mov    $0x3d4,%ebx
    cp = (uint16_t*)(K_ADDR_BASE + CGA_BUF);
80100fbc:	be 00 80 0b 80       	mov    $0x800b8000,%esi
80100fc1:	e9 3f ff ff ff       	jmp    80100f05 <cons_init+0x34>
        cprintf("Serial port does not exist!\n");
80100fc6:	83 ec 0c             	sub    $0xc,%esp
80100fc9:	68 f6 10 10 80       	push   $0x801010f6
80100fce:	e8 d2 fc ff ff       	call   80100ca5 <cprintf>
80100fd3:	83 c4 10             	add    $0x10,%esp
}
80100fd6:	eb d0                	jmp    80100fa8 <cons_init+0xd7>
