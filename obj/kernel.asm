
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
80100039:	e8 9f 0e 00 00       	call   80100edd <cons_init>
    cprintf("\n");
8010003e:	83 ec 0c             	sub    $0xc,%esp
80100041:	68 7c 10 10 80       	push   $0x8010107c
80100046:	e8 66 0c 00 00       	call   80100cb1 <cprintf>
    cprintf("------> Hello, OS World!\n");
8010004b:	c7 04 24 00 10 10 80 	movl   $0x80101000,(%esp)
80100052:	e8 5a 0c 00 00       	call   80100cb1 <cprintf>
    kmem_init(); // 内存管理初始化
80100057:	e8 e4 02 00 00       	call   80100340 <kmem_init>
    cprintf("------> kmem_init() finish!\n");
8010005c:	c7 04 24 1a 10 10 80 	movl   $0x8010101a,(%esp)
80100063:	e8 49 0c 00 00       	call   80100cb1 <cprintf>
    mcpu_init();
80100068:	e8 19 05 00 00       	call   80100586 <mcpu_init>
    cprintf("------> mcpu_init() finish!\n");
8010006d:	c7 04 24 37 10 10 80 	movl   $0x80101037,(%esp)
80100074:	e8 38 0c 00 00       	call   80100cb1 <cprintf>
    gdt_init();
80100079:	e8 43 03 00 00       	call   801003c1 <gdt_init>
    cprintf("------> gdt_init() finish!\n");
8010007e:	c7 04 24 54 10 10 80 	movl   $0x80101054,(%esp)
80100085:	e8 27 0c 00 00       	call   80100cb1 <cprintf>
#include "types.h"

static inline void
hlt(void)
{
    asm volatile("hlt");
8010008a:	f4                   	hlt    
    hlt();
}
8010008b:	b8 00 00 00 00       	mov    $0x0,%eax
80100090:	8b 4d fc             	mov    -0x4(%ebp),%ecx
80100093:	c9                   	leave  
80100094:	8d 61 fc             	lea    -0x4(%ecx),%esp
80100097:	c3                   	ret    

80100098 <kmem_free>:

/**
 *  释放虚拟地址v指向的内存
 */
void kmem_free(char* vaddr)
{
80100098:	55                   	push   %ebp
80100099:	89 e5                	mov    %esp,%ebp
8010009b:	53                   	push   %ebx
8010009c:	83 ec 04             	sub    $0x4,%esp
8010009f:	8b 5d 08             	mov    0x8(%ebp),%ebx
    if ((vaddr_t)vaddr % PGSIZE || vaddr < end || K_V2P(vaddr) >= P_ADDR_PHYSTOP)
801000a2:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
801000a8:	75 15                	jne    801000bf <kmem_free+0x27>
801000aa:	81 fb 20 4b 10 80    	cmp    $0x80104b20,%ebx
801000b0:	72 0d                	jb     801000bf <kmem_free+0x27>
801000b2:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801000b8:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
801000bd:	76 10                	jbe    801000cf <kmem_free+0x37>
        cprintf("kfree error \n");
801000bf:	83 ec 0c             	sub    $0xc,%esp
801000c2:	68 70 10 10 80       	push   $0x80101070
801000c7:	e8 e5 0b 00 00       	call   80100cb1 <cprintf>
801000cc:	83 c4 10             	add    $0x10,%esp

    memset(vaddr, 1, PGSIZE); // 清空该页内存
801000cf:	83 ec 04             	sub    $0x4,%esp
801000d2:	68 00 10 00 00       	push   $0x1000
801000d7:	6a 01                	push   $0x1
801000d9:	53                   	push   %ebx
801000da:	e8 e6 06 00 00       	call   801007c5 <memset>

    // if (kmem.use_lock)
    //     acquire(&kmem.lock);
    struct list_node* node = (struct list_node*)vaddr;
    node->next = kmem.freelist;
801000df:	a1 00 33 10 80       	mov    0x80103300,%eax
801000e4:	89 03                	mov    %eax,(%ebx)
    kmem.freelist = node;
801000e6:	89 1d 00 33 10 80    	mov    %ebx,0x80103300
    // if (kmem.use_lock)
    //     release(&kmem.lock);
}
801000ec:	83 c4 10             	add    $0x10,%esp
801000ef:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801000f2:	c9                   	leave  
801000f3:	c3                   	ret    

801000f4 <kmem_free_pages>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	56                   	push   %esi
801000f8:	53                   	push   %ebx
801000f9:	8b 75 0c             	mov    0xc(%ebp),%esi
    p = (char*)PGROUNDUP((vaddr_t)start);
801000fc:	8b 45 08             	mov    0x8(%ebp),%eax
801000ff:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80100105:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
    for (; p + PGSIZE <= (char*)end; p += PGSIZE) {
8010010b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80100111:	39 de                	cmp    %ebx,%esi
80100113:	72 1c                	jb     80100131 <kmem_free_pages+0x3d>
        kmem_free(p);
80100115:	83 ec 0c             	sub    $0xc,%esp
80100118:	8d 83 00 f0 ff ff    	lea    -0x1000(%ebx),%eax
8010011e:	50                   	push   %eax
8010011f:	e8 74 ff ff ff       	call   80100098 <kmem_free>
    for (; p + PGSIZE <= (char*)end; p += PGSIZE) {
80100124:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010012a:	83 c4 10             	add    $0x10,%esp
8010012d:	39 de                	cmp    %ebx,%esi
8010012f:	73 e4                	jae    80100115 <kmem_free_pages+0x21>
}
80100131:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100134:	5b                   	pop    %ebx
80100135:	5e                   	pop    %esi
80100136:	5d                   	pop    %ebp
80100137:	c3                   	ret    

80100138 <kmem_alloc>:
{
    struct list_node* node = NULL;

    // if (kmem.use_lock)
    //     acquire(&kmem.lock);
    node = kmem.freelist;
80100138:	a1 00 33 10 80       	mov    0x80103300,%eax
    if (node)
8010013d:	85 c0                	test   %eax,%eax
8010013f:	74 08                	je     80100149 <kmem_alloc+0x11>
        kmem.freelist = node->next;
80100141:	8b 10                	mov    (%eax),%edx
80100143:	89 15 00 33 10 80    	mov    %edx,0x80103300
    // if (kmem.use_lock)
    //     release(&kmem.lock);
    return (char*)node;
}
80100149:	c3                   	ret    

8010014a <kmmap>:

/**
 * 在页表 pgdir 中进行虚拟内存到物理内存的映射：虚拟地址 vaddr -> 物理地址 paddr，映射长度为 size，权限为 perm，成功返回0，不成功返回-1
 */
static int kmmap(pde_t* pgdir, void* vaddr, uint32_t size, paddr_t paddr, int perm)
{
8010014a:	55                   	push   %ebp
8010014b:	89 e5                	mov    %esp,%ebp
8010014d:	57                   	push   %edi
8010014e:	56                   	push   %esi
8010014f:	53                   	push   %ebx
80100150:	83 ec 2c             	sub    $0x2c,%esp
80100153:	89 45 dc             	mov    %eax,-0x24(%ebp)
    char *va_start, *va_end;
    pte_t* pte;

    if (size == 0) {
80100156:	85 c9                	test   %ecx,%ecx
80100158:	74 20                	je     8010017a <kmmap+0x30>
8010015a:	89 d0                	mov    %edx,%eax
        cprintf("kmmap() error: size = 0, it should be > 0\n");
        return -1;
    }

    /* 先对齐，并求出需要映射的虚拟地址范围 */
    va_start = (char*)PGROUNDDOWN((vaddr_t)vaddr);
8010015c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
80100162:	89 d7                	mov    %edx,%edi
    va_end = (char*)PGROUNDDOWN(((vaddr_t)vaddr) + size - 1);
80100164:	8d 44 08 ff          	lea    -0x1(%eax,%ecx,1),%eax
80100168:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010016d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100170:	8b 45 08             	mov    0x8(%ebp),%eax
80100173:	29 d0                	sub    %edx,%eax
80100175:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100178:	eb 5a                	jmp    801001d4 <kmmap+0x8a>
        cprintf("kmmap() error: size = 0, it should be > 0\n");
8010017a:	83 ec 0c             	sub    $0xc,%esp
8010017d:	68 80 10 10 80       	push   $0x80101080
80100182:	e8 2a 0b 00 00       	call   80100cb1 <cprintf>
        return -1;
80100187:	83 c4 10             	add    $0x10,%esp
8010018a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010018f:	e9 ba 00 00 00       	jmp    8010024e <kmmap+0x104>
    pde_t* pde; // 页目录项（一级）
    pte_t* pte; // 页表项（二级）

    pde = &pgdir[PDX(vaddr)]; // 根据 vaddr 获取对应的页目录项
    if (*pde & PTE_P) { // 页目录项存在
        pte = (pte_t*)K_P2V(PTE_ADDR(*pde)); // 取出 PPN 所对应的二级页表（即 pte 数组）的地址
80100194:	25 00 f0 ff ff       	and    $0xfffff000,%eax
            return NULL;

        memset(pte, 0, PGSIZE);
        *pde = K_V2P(pte) | perm | PTE_P; // 将二级页表的物理地址写入页目录项
    }
    return &pte[PTX(vaddr)]; // 从二级页表中取出对应的页表项
80100199:	89 fa                	mov    %edi,%edx
8010019b:	c1 ea 0a             	shr    $0xa,%edx
8010019e:	81 e2 fc 0f 00 00    	and    $0xffc,%edx
801001a4:	8d 9c 10 00 00 00 80 	lea    -0x80000000(%eax,%edx,1),%ebx
        if ((pte = get_pte(pgdir, va_start, 1, perm)) == NULL) // 找到 pte
801001ab:	85 db                	test   %ebx,%ebx
801001ad:	0f 84 8f 00 00 00    	je     80100242 <kmmap+0xf8>
        if (*pte & PTE_P) {
801001b3:	f6 03 01             	testb  $0x1,(%ebx)
801001b6:	75 73                	jne    8010022b <kmmap+0xe1>
        *pte = paddr | perm | PTE_P; // 填写 pte
801001b8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801001bb:	0b 45 0c             	or     0xc(%ebp),%eax
801001be:	83 c8 01             	or     $0x1,%eax
801001c1:	89 03                	mov    %eax,(%ebx)
        if (va_start == va_end) // 映射完成
801001c3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801001c6:	39 c7                	cmp    %eax,%edi
801001c8:	0f 84 88 00 00 00    	je     80100256 <kmmap+0x10c>
        va_start += PGSIZE;
801001ce:	81 c7 00 10 00 00    	add    $0x1000,%edi
    while (1) {
801001d4:	89 7d e0             	mov    %edi,-0x20(%ebp)
801001d7:	8b 45 d8             	mov    -0x28(%ebp),%eax
801001da:	01 f8                	add    %edi,%eax
801001dc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    pde = &pgdir[PDX(vaddr)]; // 根据 vaddr 获取对应的页目录项
801001df:	89 f8                	mov    %edi,%eax
801001e1:	c1 e8 16             	shr    $0x16,%eax
801001e4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
801001e7:	8d 34 81             	lea    (%ecx,%eax,4),%esi
    if (*pde & PTE_P) { // 页目录项存在
801001ea:	8b 06                	mov    (%esi),%eax
801001ec:	a8 01                	test   $0x1,%al
801001ee:	75 a4                	jne    80100194 <kmmap+0x4a>
        if (!need_alloc || (pte = (pte_t*)kmem_alloc()) == NULL) // 不需要分配或分配失败
801001f0:	e8 43 ff ff ff       	call   80100138 <kmem_alloc>
801001f5:	89 c3                	mov    %eax,%ebx
801001f7:	85 c0                	test   %eax,%eax
801001f9:	74 4e                	je     80100249 <kmmap+0xff>
        memset(pte, 0, PGSIZE);
801001fb:	83 ec 04             	sub    $0x4,%esp
801001fe:	68 00 10 00 00       	push   $0x1000
80100203:	6a 00                	push   $0x0
80100205:	50                   	push   %eax
80100206:	e8 ba 05 00 00       	call   801007c5 <memset>
        *pde = K_V2P(pte) | perm | PTE_P; // 将二级页表的物理地址写入页目录项
8010020b:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80100211:	0b 45 0c             	or     0xc(%ebp),%eax
80100214:	83 c8 01             	or     $0x1,%eax
80100217:	89 06                	mov    %eax,(%esi)
    return &pte[PTX(vaddr)]; // 从二级页表中取出对应的页表项
80100219:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010021c:	c1 e8 0a             	shr    $0xa,%eax
8010021f:	25 fc 0f 00 00       	and    $0xffc,%eax
80100224:	01 c3                	add    %eax,%ebx
80100226:	83 c4 10             	add    $0x10,%esp
80100229:	eb 88                	jmp    801001b3 <kmmap+0x69>
            cprintf("kmmap error: pte already present\n");
8010022b:	83 ec 0c             	sub    $0xc,%esp
8010022e:	68 ac 10 10 80       	push   $0x801010ac
80100233:	e8 79 0a 00 00       	call   80100cb1 <cprintf>
            return -1;
80100238:	83 c4 10             	add    $0x10,%esp
8010023b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100240:	eb 0c                	jmp    8010024e <kmmap+0x104>
            return -1;
80100242:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100247:	eb 05                	jmp    8010024e <kmmap+0x104>
80100249:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010024e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100251:	5b                   	pop    %ebx
80100252:	5e                   	pop    %esi
80100253:	5f                   	pop    %edi
80100254:	5d                   	pop    %ebp
80100255:	c3                   	ret    
    return 0;
80100256:	b8 00 00 00 00       	mov    $0x0,%eax
8010025b:	eb f1                	jmp    8010024e <kmmap+0x104>

8010025d <set_kernel_pgdir>:
{
8010025d:	55                   	push   %ebp
8010025e:	89 e5                	mov    %esp,%ebp
80100260:	53                   	push   %ebx
80100261:	83 ec 04             	sub    $0x4,%esp
    if ((kernel_pgdir = (pde_t*)kmem_alloc()) == 0) // 分配一页内存作为一级页表页（即页目录）
80100264:	e8 cf fe ff ff       	call   80100138 <kmem_alloc>
80100269:	89 c3                	mov    %eax,%ebx
8010026b:	85 c0                	test   %eax,%eax
8010026d:	0f 84 ac 00 00 00    	je     8010031f <set_kernel_pgdir+0xc2>
    memset(kernel_pgdir, 0, PGSIZE);
80100273:	83 ec 04             	sub    $0x4,%esp
80100276:	68 00 10 00 00       	push   $0x1000
8010027b:	6a 00                	push   $0x0
8010027d:	50                   	push   %eax
8010027e:	e8 42 05 00 00       	call   801007c5 <memset>
    if (kmmap(kernel_pgdir, (void*)K_ADDR_BASE, P_ADDR_EXTMEM - 0, (paddr_t)0, PTE_W) < 0) { // 映射低1MB内存
80100283:	83 c4 08             	add    $0x8,%esp
80100286:	6a 02                	push   $0x2
80100288:	6a 00                	push   $0x0
8010028a:	b9 00 00 10 00       	mov    $0x100000,%ecx
8010028f:	ba 00 00 00 80       	mov    $0x80000000,%edx
80100294:	89 d8                	mov    %ebx,%eax
80100296:	e8 af fe ff ff       	call   8010014a <kmmap>
8010029b:	83 c4 10             	add    $0x10,%esp
8010029e:	85 c0                	test   %eax,%eax
801002a0:	78 6c                	js     8010030e <set_kernel_pgdir+0xb1>
    if (kmmap(kernel_pgdir, (void*)K_ADDR_LOAD, K_V2P(data) - K_V2P(K_ADDR_LOAD), K_V2P(K_ADDR_LOAD), 0) < 0) { // 映射内核代码段和数据段占据的内存
801002a2:	83 ec 08             	sub    $0x8,%esp
801002a5:	6a 00                	push   $0x0
801002a7:	68 00 00 10 00       	push   $0x100000
801002ac:	b9 00 20 00 00       	mov    $0x2000,%ecx
801002b1:	ba 00 00 10 80       	mov    $0x80100000,%edx
801002b6:	89 d8                	mov    %ebx,%eax
801002b8:	e8 8d fe ff ff       	call   8010014a <kmmap>
801002bd:	83 c4 10             	add    $0x10,%esp
801002c0:	85 c0                	test   %eax,%eax
801002c2:	78 4a                	js     8010030e <set_kernel_pgdir+0xb1>
    if (kmmap(kernel_pgdir, (void*)data, P_ADDR_PHYSTOP - K_V2P(data), K_V2P(data), PTE_W) < 0) { // 映射内核数据段后面的内存
801002c4:	b9 00 00 00 8e       	mov    $0x8e000000,%ecx
801002c9:	81 e9 00 20 10 80    	sub    $0x80102000,%ecx
801002cf:	83 ec 08             	sub    $0x8,%esp
801002d2:	6a 02                	push   $0x2
801002d4:	68 00 20 10 00       	push   $0x102000
801002d9:	ba 00 20 10 80       	mov    $0x80102000,%edx
801002de:	89 d8                	mov    %ebx,%eax
801002e0:	e8 65 fe ff ff       	call   8010014a <kmmap>
801002e5:	83 c4 10             	add    $0x10,%esp
801002e8:	85 c0                	test   %eax,%eax
801002ea:	78 22                	js     8010030e <set_kernel_pgdir+0xb1>
    if (kmmap(kernel_pgdir, (void*)P_ADDR_DEVSPACE, 0 - P_ADDR_DEVSPACE, (paddr_t)P_ADDR_DEVSPACE, PTE_W) < 0) { // 映射设备内存（直接映射）
801002ec:	83 ec 08             	sub    $0x8,%esp
801002ef:	6a 02                	push   $0x2
801002f1:	68 00 00 00 fe       	push   $0xfe000000
801002f6:	b9 00 00 00 02       	mov    $0x2000000,%ecx
801002fb:	ba 00 00 00 fe       	mov    $0xfe000000,%edx
80100300:	89 d8                	mov    %ebx,%eax
80100302:	e8 43 fe ff ff       	call   8010014a <kmmap>
80100307:	83 c4 10             	add    $0x10,%esp
8010030a:	85 c0                	test   %eax,%eax
8010030c:	79 11                	jns    8010031f <set_kernel_pgdir+0xc2>
    kmem_free((char*)kernel_pgdir);
8010030e:	83 ec 0c             	sub    $0xc,%esp
80100311:	53                   	push   %ebx
80100312:	e8 81 fd ff ff       	call   80100098 <kmem_free>
    return 0;
80100317:	83 c4 10             	add    $0x10,%esp
8010031a:	bb 00 00 00 00       	mov    $0x0,%ebx
}
8010031f:	89 d8                	mov    %ebx,%eax
80100321:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100324:	c9                   	leave  
80100325:	c3                   	ret    

80100326 <switch_pgdir>:
{
80100326:	55                   	push   %ebp
80100327:	89 e5                	mov    %esp,%ebp
    if (p == NULL) {
80100329:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010032d:	74 02                	je     80100331 <switch_pgdir+0xb>
}
8010032f:	5d                   	pop    %ebp
80100330:	c3                   	ret    
        lcr3(K_V2P(kernel_pgdir));
80100331:	a1 04 33 10 80       	mov    0x80103304,%eax
80100336:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint32_t val)
{
    asm volatile("movl %0,%%cr3"
8010033b:	0f 22 d8             	mov    %eax,%cr3
}
8010033e:	eb ef                	jmp    8010032f <switch_pgdir+0x9>

80100340 <kmem_init>:
{
80100340:	55                   	push   %ebp
80100341:	89 e5                	mov    %esp,%ebp
80100343:	83 ec 10             	sub    $0x10,%esp
    kmem_free_pages(end, K_P2V(P_ADDR_LOWMEM)); // 释放[end, 4MB]部分给新的内核页表使用
80100346:	68 00 00 40 80       	push   $0x80400000
8010034b:	68 20 4b 10 80       	push   $0x80104b20
80100350:	e8 9f fd ff ff       	call   801000f4 <kmem_free_pages>
    kernel_pgdir = set_kernel_pgdir(); // 设置内核页表
80100355:	e8 03 ff ff ff       	call   8010025d <set_kernel_pgdir>
8010035a:	a3 04 33 10 80       	mov    %eax,0x80103304
    switch_pgdir(NULL); // NULL 代表切换为内核页表
8010035f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80100366:	e8 bb ff ff ff       	call   80100326 <switch_pgdir>
}
8010036b:	83 c4 10             	add    $0x10,%esp
8010036e:	c9                   	leave  
8010036f:	c3                   	ret    

80100370 <free_pgdir>:
{
80100370:	55                   	push   %ebp
80100371:	89 e5                	mov    %esp,%ebp
80100373:	56                   	push   %esi
80100374:	53                   	push   %ebx
80100375:	8b 75 08             	mov    0x8(%ebp),%esi
80100378:	bb 00 00 00 00       	mov    $0x0,%ebx
8010037d:	eb 0b                	jmp    8010038a <free_pgdir+0x1a>
    for (int i = 0; i < NPDENTRIES; i++) {
8010037f:	83 c3 04             	add    $0x4,%ebx
80100382:	81 fb 00 10 00 00    	cmp    $0x1000,%ebx
80100388:	74 22                	je     801003ac <free_pgdir+0x3c>
        if (p->pgdir[i] & PTE_P) {
8010038a:	8b 46 04             	mov    0x4(%esi),%eax
8010038d:	8b 04 18             	mov    (%eax,%ebx,1),%eax
80100390:	a8 01                	test   $0x1,%al
80100392:	74 eb                	je     8010037f <free_pgdir+0xf>
            kmem_free(v);
80100394:	83 ec 0c             	sub    $0xc,%esp
            char* v = K_P2V(PTE_ADDR(p->pgdir[i]));
80100397:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010039c:	05 00 00 00 80       	add    $0x80000000,%eax
            kmem_free(v);
801003a1:	50                   	push   %eax
801003a2:	e8 f1 fc ff ff       	call   80100098 <kmem_free>
801003a7:	83 c4 10             	add    $0x10,%esp
801003aa:	eb d3                	jmp    8010037f <free_pgdir+0xf>
    kmem_free((char*)p->pgdir); // 释放页目录
801003ac:	83 ec 0c             	sub    $0xc,%esp
801003af:	ff 76 04             	push   0x4(%esi)
801003b2:	e8 e1 fc ff ff       	call   80100098 <kmem_free>
}
801003b7:	83 c4 10             	add    $0x10,%esp
801003ba:	8d 65 f8             	lea    -0x8(%ebp),%esp
801003bd:	5b                   	pop    %ebx
801003be:	5e                   	pop    %esi
801003bf:	5d                   	pop    %ebp
801003c0:	c3                   	ret    

801003c1 <gdt_init>:
}

void gdt_init(void)
{
801003c1:	55                   	push   %ebp
801003c2:	89 e5                	mov    %esp,%ebp
801003c4:	83 ec 18             	sub    $0x18,%esp

    // Map "logical" addresses to virtual addresses using identity map.
    // Cannot share a CODE descriptor for both kernel and user
    // because it would have to have DPL_USR, but the CPU forbids
    // an interrupt from CPL=0 to DPL=3.
    c = &cpus[cpuid()];
801003c7:	e8 9f 01 00 00       	call   8010056b <cpuid>
    c->gdt[SEG_SELECTOR_KCODE] = SEG(STA_X | STA_R, 0, 0xffffffff, 0);
801003cc:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
801003d2:	66 c7 80 b8 33 10 80 	movw   $0xffff,-0x7fefcc48(%eax)
801003d9:	ff ff 
801003db:	66 c7 80 ba 33 10 80 	movw   $0x0,-0x7fefcc46(%eax)
801003e2:	00 00 
801003e4:	c6 80 bc 33 10 80 00 	movb   $0x0,-0x7fefcc44(%eax)
801003eb:	c6 80 bd 33 10 80 9a 	movb   $0x9a,-0x7fefcc43(%eax)
801003f2:	c6 80 be 33 10 80 cf 	movb   $0xcf,-0x7fefcc42(%eax)
801003f9:	c6 80 bf 33 10 80 00 	movb   $0x0,-0x7fefcc41(%eax)
    c->gdt[SEG_SELECTOR_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80100400:	66 c7 80 c0 33 10 80 	movw   $0xffff,-0x7fefcc40(%eax)
80100407:	ff ff 
80100409:	66 c7 80 c2 33 10 80 	movw   $0x0,-0x7fefcc3e(%eax)
80100410:	00 00 
80100412:	c6 80 c4 33 10 80 00 	movb   $0x0,-0x7fefcc3c(%eax)
80100419:	c6 80 c5 33 10 80 92 	movb   $0x92,-0x7fefcc3b(%eax)
80100420:	c6 80 c6 33 10 80 cf 	movb   $0xcf,-0x7fefcc3a(%eax)
80100427:	c6 80 c7 33 10 80 00 	movb   $0x0,-0x7fefcc39(%eax)
    c->gdt[SEG_SELECTOR_UCODE] = SEG(STA_X | STA_R, 0, 0xffffffff, DPL_USER);
8010042e:	66 c7 80 c8 33 10 80 	movw   $0xffff,-0x7fefcc38(%eax)
80100435:	ff ff 
80100437:	66 c7 80 ca 33 10 80 	movw   $0x0,-0x7fefcc36(%eax)
8010043e:	00 00 
80100440:	c6 80 cc 33 10 80 00 	movb   $0x0,-0x7fefcc34(%eax)
80100447:	c6 80 cd 33 10 80 fa 	movb   $0xfa,-0x7fefcc33(%eax)
8010044e:	c6 80 ce 33 10 80 cf 	movb   $0xcf,-0x7fefcc32(%eax)
80100455:	c6 80 cf 33 10 80 00 	movb   $0x0,-0x7fefcc31(%eax)
    c->gdt[SEG_SELECTOR_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
8010045c:	66 c7 80 d0 33 10 80 	movw   $0xffff,-0x7fefcc30(%eax)
80100463:	ff ff 
80100465:	66 c7 80 d2 33 10 80 	movw   $0x0,-0x7fefcc2e(%eax)
8010046c:	00 00 
8010046e:	c6 80 d4 33 10 80 00 	movb   $0x0,-0x7fefcc2c(%eax)
80100475:	c6 80 d5 33 10 80 f2 	movb   $0xf2,-0x7fefcc2b(%eax)
8010047c:	c6 80 d6 33 10 80 cf 	movb   $0xcf,-0x7fefcc2a(%eax)
80100483:	c6 80 d7 33 10 80 00 	movb   $0x0,-0x7fefcc29(%eax)
    lgdt(c->gdt, sizeof(c->gdt));
8010048a:	05 b0 33 10 80       	add    $0x801033b0,%eax
    pd[0] = size - 1;
8010048f:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
    pd[1] = (uint32_t)p;
80100495:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
    pd[2] = (uint32_t)p >> 16;
80100499:	c1 e8 10             	shr    $0x10,%eax
8010049c:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
    asm volatile("lgdt (%0)"
801004a0:	8d 45 f2             	lea    -0xe(%ebp),%eax
801004a3:	0f 01 10             	lgdtl  (%eax)
}
801004a6:	c9                   	leave  
801004a7:	c3                   	ret    

801004a8 <mpsearch1>:
}

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint32_t a, int len)
{
801004a8:	55                   	push   %ebp
801004a9:	89 e5                	mov    %esp,%ebp
801004ab:	57                   	push   %edi
801004ac:	56                   	push   %esi
801004ad:	53                   	push   %ebx
801004ae:	83 ec 0c             	sub    $0xc,%esp
    uint8_t *e, *p, *addr;

    addr = K_P2V(a);
801004b1:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
    e = addr + len;
801004b7:	8d 3c 16             	lea    (%esi,%edx,1),%edi
    for (p = addr; p < e; p += sizeof(struct mp))
801004ba:	39 fe                	cmp    %edi,%esi
801004bc:	73 4c                	jae    8010050a <mpsearch1+0x62>
801004be:	8d 98 10 00 00 80    	lea    -0x7ffffff0(%eax),%ebx
801004c4:	eb 0e                	jmp    801004d4 <mpsearch1+0x2c>
        if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
801004c6:	84 c0                	test   %al,%al
801004c8:	74 36                	je     80100500 <mpsearch1+0x58>
    for (p = addr; p < e; p += sizeof(struct mp))
801004ca:	83 c6 10             	add    $0x10,%esi
801004cd:	83 c3 10             	add    $0x10,%ebx
801004d0:	39 fe                	cmp    %edi,%esi
801004d2:	73 27                	jae    801004fb <mpsearch1+0x53>
        if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
801004d4:	83 ec 04             	sub    $0x4,%esp
801004d7:	6a 04                	push   $0x4
801004d9:	68 ce 10 10 80       	push   $0x801010ce
801004de:	56                   	push   %esi
801004df:	e8 16 03 00 00       	call   801007fa <memcmp>
801004e4:	83 c4 10             	add    $0x10,%esp
801004e7:	85 c0                	test   %eax,%eax
801004e9:	75 df                	jne    801004ca <mpsearch1+0x22>
801004eb:	89 f2                	mov    %esi,%edx
        sum += addr[i];
801004ed:	0f b6 0a             	movzbl (%edx),%ecx
801004f0:	01 c8                	add    %ecx,%eax
    for (i = 0; i < len; i++)
801004f2:	83 c2 01             	add    $0x1,%edx
801004f5:	39 da                	cmp    %ebx,%edx
801004f7:	75 f4                	jne    801004ed <mpsearch1+0x45>
801004f9:	eb cb                	jmp    801004c6 <mpsearch1+0x1e>
            return (struct mp*)p;
    return 0;
801004fb:	be 00 00 00 00       	mov    $0x0,%esi
}
80100500:	89 f0                	mov    %esi,%eax
80100502:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100505:	5b                   	pop    %ebx
80100506:	5e                   	pop    %esi
80100507:	5f                   	pop    %edi
80100508:	5d                   	pop    %ebp
80100509:	c3                   	ret    
    return 0;
8010050a:	be 00 00 00 00       	mov    $0x0,%esi
8010050f:	eb ef                	jmp    80100500 <mpsearch1+0x58>

80100511 <mycpu>:
{
80100511:	55                   	push   %ebp
80100512:	89 e5                	mov    %esp,%ebp
80100514:	56                   	push   %esi
80100515:	53                   	push   %ebx

static inline uint32_t
read_eflags(void)
{
    uint32_t eflags;
    asm volatile("pushfl; popl %0"
80100516:	9c                   	pushf  
80100517:	58                   	pop    %eax
    if (read_eflags() & FL_IF) {
80100518:	f6 c4 02             	test   $0x2,%ah
8010051b:	75 2e                	jne    8010054b <mycpu+0x3a>
    apicid = lapicid();
8010051d:	e8 33 02 00 00       	call   80100755 <lapicid>
    for (i = 0; i < num_cpu; ++i) {
80100522:	8b 35 24 33 10 80    	mov    0x80103324,%esi
80100528:	85 f6                	test   %esi,%esi
8010052a:	7e 38                	jle    80100564 <mycpu+0x53>
8010052c:	ba 00 00 00 00       	mov    $0x0,%edx
        if (cpus[i].apicid == apicid)
80100531:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
80100537:	0f b6 99 40 33 10 80 	movzbl -0x7fefccc0(%ecx),%ebx
8010053e:	39 c3                	cmp    %eax,%ebx
80100540:	74 1c                	je     8010055e <mycpu+0x4d>
    for (i = 0; i < num_cpu; ++i) {
80100542:	83 c2 01             	add    $0x1,%edx
80100545:	39 f2                	cmp    %esi,%edx
80100547:	75 e8                	jne    80100531 <mycpu+0x20>
80100549:	eb 19                	jmp    80100564 <mycpu+0x53>
        cprintf("mycpu called with interrupts enabled\n");
8010054b:	83 ec 0c             	sub    $0xc,%esp
8010054e:	68 d8 10 10 80       	push   $0x801010d8
80100553:	e8 59 07 00 00       	call   80100cb1 <cprintf>
    asm volatile("hlt");
80100558:	f4                   	hlt    
}
80100559:	83 c4 10             	add    $0x10,%esp
8010055c:	eb bf                	jmp    8010051d <mycpu+0xc>
            return &cpus[i];
8010055e:	8d 81 40 33 10 80    	lea    -0x7fefccc0(%ecx),%eax
}
80100564:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100567:	5b                   	pop    %ebx
80100568:	5e                   	pop    %esi
80100569:	5d                   	pop    %ebp
8010056a:	c3                   	ret    

8010056b <cpuid>:
{
8010056b:	55                   	push   %ebp
8010056c:	89 e5                	mov    %esp,%ebp
8010056e:	83 ec 08             	sub    $0x8,%esp
    return mycpu() - cpus;
80100571:	e8 9b ff ff ff       	call   80100511 <mycpu>
80100576:	2d 40 33 10 80       	sub    $0x80103340,%eax
8010057b:	c1 f8 04             	sar    $0x4,%eax
8010057e:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
80100584:	c9                   	leave  
80100585:	c3                   	ret    

80100586 <mcpu_init>:
    *pmp = mp;
    return conf;
}

void mcpu_init(void)
{
80100586:	55                   	push   %ebp
80100587:	89 e5                	mov    %esp,%ebp
80100589:	57                   	push   %edi
8010058a:	56                   	push   %esi
8010058b:	53                   	push   %ebx
8010058c:	83 ec 1c             	sub    $0x1c,%esp
    if ((p = ((bda[0x0F] << 8) | bda[0x0E]) << 4)) {
8010058f:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80100596:	c1 e0 08             	shl    $0x8,%eax
80100599:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
801005a0:	09 d0                	or     %edx,%eax
801005a2:	c1 e0 04             	shl    $0x4,%eax
801005a5:	0f 84 c1 00 00 00    	je     8010066c <mcpu_init+0xe6>
        if ((mp = mpsearch1(p, 1024)))
801005ab:	ba 00 04 00 00       	mov    $0x400,%edx
801005b0:	e8 f3 fe ff ff       	call   801004a8 <mpsearch1>
801005b5:	89 c3                	mov    %eax,%ebx
801005b7:	85 c0                	test   %eax,%eax
801005b9:	75 19                	jne    801005d4 <mcpu_init+0x4e>
    return mpsearch1(0xF0000, 0x10000);
801005bb:	ba 00 00 01 00       	mov    $0x10000,%edx
801005c0:	b8 00 00 0f 00       	mov    $0xf0000,%eax
801005c5:	e8 de fe ff ff       	call   801004a8 <mpsearch1>
801005ca:	89 c3                	mov    %eax,%ebx
    if ((mp = mpsearch()) == 0 || mp->physaddr == 0)
801005cc:	85 c0                	test   %eax,%eax
801005ce:	0f 84 cc 00 00 00    	je     801006a0 <mcpu_init+0x11a>
801005d4:	8b 7b 04             	mov    0x4(%ebx),%edi
801005d7:	85 ff                	test   %edi,%edi
801005d9:	0f 84 c5 00 00 00    	je     801006a4 <mcpu_init+0x11e>
    conf = (struct mpconf*)K_P2V((uint32_t)mp->physaddr);
801005df:	8d b7 00 00 00 80    	lea    -0x80000000(%edi),%esi
    if (memcmp(conf, "PCMP", 4) != 0)
801005e5:	83 ec 04             	sub    $0x4,%esp
801005e8:	6a 04                	push   $0x4
801005ea:	68 d3 10 10 80       	push   $0x801010d3
801005ef:	56                   	push   %esi
801005f0:	e8 05 02 00 00       	call   801007fa <memcmp>
801005f5:	89 c2                	mov    %eax,%edx
801005f7:	83 c4 10             	add    $0x10,%esp
801005fa:	85 c0                	test   %eax,%eax
801005fc:	0f 85 a6 00 00 00    	jne    801006a8 <mcpu_init+0x122>
    if (conf->version != 1 && conf->version != 4)
80100602:	0f b6 87 06 00 00 80 	movzbl -0x7ffffffa(%edi),%eax
80100609:	3c 01                	cmp    $0x1,%al
8010060b:	74 08                	je     80100615 <mcpu_init+0x8f>
8010060d:	3c 04                	cmp    $0x4,%al
8010060f:	0f 85 9a 00 00 00    	jne    801006af <mcpu_init+0x129>
    if (sum((uint8_t*)conf, conf->length) != 0)
80100615:	0f b7 8f 04 00 00 80 	movzwl -0x7ffffffc(%edi),%ecx
    for (i = 0; i < len; i++)
8010061c:	66 85 c9             	test   %cx,%cx
8010061f:	0f 84 91 00 00 00    	je     801006b6 <mcpu_init+0x130>
80100625:	89 f8                	mov    %edi,%eax
80100627:	0f b7 c9             	movzwl %cx,%ecx
8010062a:	01 cf                	add    %ecx,%edi
        sum += addr[i];
8010062c:	0f b6 88 00 00 00 80 	movzbl -0x80000000(%eax),%ecx
80100633:	01 ca                	add    %ecx,%edx
    for (i = 0; i < len; i++)
80100635:	83 c0 01             	add    $0x1,%eax
80100638:	39 f8                	cmp    %edi,%eax
8010063a:	75 f0                	jne    8010062c <mcpu_init+0xa6>
        return 0;
8010063c:	84 d2                	test   %dl,%dl
8010063e:	b8 00 00 00 00       	mov    $0x0,%eax
80100643:	0f 45 f0             	cmovne %eax,%esi
80100646:	0f 45 d8             	cmovne %eax,%ebx
80100649:	89 5d e0             	mov    %ebx,-0x20(%ebp)
    struct mpproc* proc;
    struct mpioapic* ioapic;

    conf = mpconfig(&mp);
    ismp = 1;
    lapic = (uint32_t*)conf->lapicaddr;
8010064c:	8b 46 24             	mov    0x24(%esi),%eax
8010064f:	a3 c0 38 10 80       	mov    %eax,0x801038c0
    for (p = (uint8_t*)(conf + 1), e = (uint8_t*)conf + conf->length; p < e;) {
80100654:	8d 46 2c             	lea    0x2c(%esi),%eax
80100657:	0f b7 56 04          	movzwl 0x4(%esi),%edx
8010065b:	01 f2                	add    %esi,%edx
    ismp = 1;
8010065d:	bb 01 00 00 00       	mov    $0x1,%ebx
        switch (*p) {
80100662:	be 00 00 00 00       	mov    $0x0,%esi
80100667:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
    for (p = (uint8_t*)(conf + 1), e = (uint8_t*)conf + conf->length; p < e;) {
8010066a:	eb 5a                	jmp    801006c6 <mcpu_init+0x140>
        p = ((bda[0x14] << 8) | bda[0x13]) * 1024;
8010066c:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80100673:	c1 e0 08             	shl    $0x8,%eax
80100676:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
8010067d:	09 d0                	or     %edx,%eax
8010067f:	c1 e0 0a             	shl    $0xa,%eax
        if ((mp = mpsearch1(p - 1024, 1024)))
80100682:	2d 00 04 00 00       	sub    $0x400,%eax
80100687:	ba 00 04 00 00       	mov    $0x400,%edx
8010068c:	e8 17 fe ff ff       	call   801004a8 <mpsearch1>
80100691:	89 c3                	mov    %eax,%ebx
80100693:	85 c0                	test   %eax,%eax
80100695:	0f 85 39 ff ff ff    	jne    801005d4 <mcpu_init+0x4e>
8010069b:	e9 1b ff ff ff       	jmp    801005bb <mcpu_init+0x35>
        return 0;
801006a0:	89 c6                	mov    %eax,%esi
801006a2:	eb a8                	jmp    8010064c <mcpu_init+0xc6>
801006a4:	89 fe                	mov    %edi,%esi
801006a6:	eb a4                	jmp    8010064c <mcpu_init+0xc6>
        return 0;
801006a8:	be 00 00 00 00       	mov    $0x0,%esi
801006ad:	eb 9d                	jmp    8010064c <mcpu_init+0xc6>
        return 0;
801006af:	be 00 00 00 00       	mov    $0x0,%esi
801006b4:	eb 96                	jmp    8010064c <mcpu_init+0xc6>
    for (i = 0; i < len; i++)
801006b6:	89 5d e0             	mov    %ebx,-0x20(%ebp)
801006b9:	eb 91                	jmp    8010064c <mcpu_init+0xc6>
        switch (*p) {
801006bb:	83 e9 03             	sub    $0x3,%ecx
801006be:	80 f9 01             	cmp    $0x1,%cl
801006c1:	76 15                	jbe    801006d8 <mcpu_init+0x152>
801006c3:	89 75 e4             	mov    %esi,-0x1c(%ebp)
    for (p = (uint8_t*)(conf + 1), e = (uint8_t*)conf + conf->length; p < e;) {
801006c6:	39 d0                	cmp    %edx,%eax
801006c8:	73 4b                	jae    80100715 <mcpu_init+0x18f>
        switch (*p) {
801006ca:	0f b6 08             	movzbl (%eax),%ecx
801006cd:	80 f9 02             	cmp    $0x2,%cl
801006d0:	74 34                	je     80100706 <mcpu_init+0x180>
801006d2:	77 e7                	ja     801006bb <mcpu_init+0x135>
801006d4:	84 c9                	test   %cl,%cl
801006d6:	74 05                	je     801006dd <mcpu_init+0x157>
            p += sizeof(struct mpioapic);
            continue;
        case MPBUS:
        case MPIOINTR:
        case MPLINTR:
            p += 8;
801006d8:	83 c0 08             	add    $0x8,%eax
            continue;
801006db:	eb e9                	jmp    801006c6 <mcpu_init+0x140>
            if (num_cpu < MAX_CPU) {
801006dd:	8b 0d 24 33 10 80    	mov    0x80103324,%ecx
801006e3:	83 f9 07             	cmp    $0x7,%ecx
801006e6:	7f 19                	jg     80100701 <mcpu_init+0x17b>
                cpus[num_cpu].apicid = proc->apicid; // apicid may differ from num_cpu
801006e8:	69 f9 b0 00 00 00    	imul   $0xb0,%ecx,%edi
801006ee:	0f b6 58 01          	movzbl 0x1(%eax),%ebx
801006f2:	88 9f 40 33 10 80    	mov    %bl,-0x7fefccc0(%edi)
                num_cpu++;
801006f8:	83 c1 01             	add    $0x1,%ecx
801006fb:	89 0d 24 33 10 80    	mov    %ecx,0x80103324
            p += sizeof(struct mpproc);
80100701:	83 c0 14             	add    $0x14,%eax
            continue;
80100704:	eb c0                	jmp    801006c6 <mcpu_init+0x140>
            ioapicid = ioapic->apicno;
80100706:	0f b6 48 01          	movzbl 0x1(%eax),%ecx
8010070a:	88 0d 20 33 10 80    	mov    %cl,0x80103320
            p += sizeof(struct mpioapic);
80100710:	83 c0 08             	add    $0x8,%eax
            continue;
80100713:	eb b1                	jmp    801006c6 <mcpu_init+0x140>
        default:
            ismp = 0;
            break;
        }
    }
    if (!ismp) {
80100715:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80100718:	85 db                	test   %ebx,%ebx
8010071a:	74 26                	je     80100742 <mcpu_init+0x1bc>
        cprintf("Didn't find a suitable machine");
        hlt();
    }

    if (mp->imcrp) {
8010071c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010071f:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80100723:	74 15                	je     8010073a <mcpu_init+0x1b4>
    asm volatile("outb %0,%w1"
80100725:	b8 70 00 00 00       	mov    $0x70,%eax
8010072a:	ba 22 00 00 00       	mov    $0x22,%edx
8010072f:	ee                   	out    %al,(%dx)
    asm volatile("inb %w1,%0"
80100730:	ba 23 00 00 00       	mov    $0x23,%edx
80100735:	ec                   	in     (%dx),%al
        // Bochs doesn't support IMCR, so this doesn't run on Bochs.
        // But it would on real hardware.
        outb(0x22, 0x70); // Select IMCR
        outb(0x23, inb(0x23) | 1); // Mask external interrupts.
80100736:	83 c8 01             	or     $0x1,%eax
    asm volatile("outb %0,%w1"
80100739:	ee                   	out    %al,(%dx)
    }
8010073a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010073d:	5b                   	pop    %ebx
8010073e:	5e                   	pop    %esi
8010073f:	5f                   	pop    %edi
80100740:	5d                   	pop    %ebp
80100741:	c3                   	ret    
        cprintf("Didn't find a suitable machine");
80100742:	83 ec 0c             	sub    $0xc,%esp
80100745:	68 00 11 10 80       	push   $0x80101100
8010074a:	e8 62 05 00 00       	call   80100cb1 <cprintf>
    asm volatile("hlt");
8010074f:	f4                   	hlt    
}
80100750:	83 c4 10             	add    $0x10,%esp
80100753:	eb c7                	jmp    8010071c <mcpu_init+0x196>

80100755 <lapicid>:

extern volatile uint32_t* lapic;

int lapicid(void)
{
    if (!lapic)
80100755:	a1 c0 38 10 80       	mov    0x801038c0,%eax
8010075a:	85 c0                	test   %eax,%eax
8010075c:	74 07                	je     80100765 <lapicid+0x10>
        return 0;
    return lapic[ID] >> 24;
8010075e:	8b 40 20             	mov    0x20(%eax),%eax
80100761:	c1 e8 18             	shr    $0x18,%eax
80100764:	c3                   	ret    
        return 0;
80100765:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010076a:	c3                   	ret    

8010076b <serial_proc_data>:
    asm volatile("inb %w1,%0"
8010076b:	ba fd 03 00 00       	mov    $0x3fd,%edx
80100770:	ec                   	in     (%dx),%al
static bool serial_exists;

static int
serial_proc_data(void)
{
    if (!(inb(COM1 + COM_LSR) & COM_LSR_DATA))
80100771:	a8 01                	test   $0x1,%al
80100773:	74 0a                	je     8010077f <serial_proc_data+0x14>
80100775:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010077a:	ec                   	in     (%dx),%al
        return -1;
    return inb(COM1 + COM_RX);
8010077b:	0f b6 c0             	movzbl %al,%eax
8010077e:	c3                   	ret    
        return -1;
8010077f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100784:	c3                   	ret    

80100785 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
80100785:	55                   	push   %ebp
80100786:	89 e5                	mov    %esp,%ebp
80100788:	53                   	push   %ebx
80100789:	83 ec 04             	sub    $0x4,%esp
8010078c:	89 c3                	mov    %eax,%ebx
    int c;

    while ((c = (*proc)()) != -1) {
8010078e:	eb 23                	jmp    801007b3 <cons_intr+0x2e>
        if (c == 0)
            continue;
        cons.buf[cons.wpos++] = c;
80100790:	8b 0d 04 3b 10 80    	mov    0x80103b04,%ecx
80100796:	8d 51 01             	lea    0x1(%ecx),%edx
80100799:	88 81 00 39 10 80    	mov    %al,-0x7fefc700(%ecx)
        if (cons.wpos == CONSBUFSIZE)
8010079f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
            cons.wpos = 0;
801007a5:	b8 00 00 00 00       	mov    $0x0,%eax
801007aa:	0f 44 d0             	cmove  %eax,%edx
801007ad:	89 15 04 3b 10 80    	mov    %edx,0x80103b04
    while ((c = (*proc)()) != -1) {
801007b3:	ff d3                	call   *%ebx
801007b5:	83 f8 ff             	cmp    $0xffffffff,%eax
801007b8:	74 06                	je     801007c0 <cons_intr+0x3b>
        if (c == 0)
801007ba:	85 c0                	test   %eax,%eax
801007bc:	75 d2                	jne    80100790 <cons_intr+0xb>
801007be:	eb f3                	jmp    801007b3 <cons_intr+0x2e>
    }
}
801007c0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801007c3:	c9                   	leave  
801007c4:	c3                   	ret    

801007c5 <memset>:
{
801007c5:	55                   	push   %ebp
801007c6:	89 e5                	mov    %esp,%ebp
801007c8:	57                   	push   %edi
801007c9:	8b 55 08             	mov    0x8(%ebp),%edx
801007cc:	8b 4d 10             	mov    0x10(%ebp),%ecx
    if ((int)dst % 4 == 0 && n % 4 == 0) {
801007cf:	89 d0                	mov    %edx,%eax
801007d1:	09 c8                	or     %ecx,%eax
801007d3:	a8 03                	test   $0x3,%al
801007d5:	75 14                	jne    801007eb <memset+0x26>
        stosl(dst, (c << 24) | (c << 16) | (c << 8) | c, n / 4);
801007d7:	c1 e9 02             	shr    $0x2,%ecx
        c &= 0xFF;
801007da:	0f b6 45 0c          	movzbl 0xc(%ebp),%eax
        stosl(dst, (c << 24) | (c << 16) | (c << 8) | c, n / 4);
801007de:	69 c0 01 01 01 01    	imul   $0x1010101,%eax,%eax
    asm volatile("cld; rep stosl"
801007e4:	89 d7                	mov    %edx,%edi
801007e6:	fc                   	cld    
801007e7:	f3 ab                	rep stos %eax,%es:(%edi)
}
801007e9:	eb 08                	jmp    801007f3 <memset+0x2e>
    asm volatile("cld; rep stosb"
801007eb:	89 d7                	mov    %edx,%edi
801007ed:	8b 45 0c             	mov    0xc(%ebp),%eax
801007f0:	fc                   	cld    
801007f1:	f3 aa                	rep stos %al,%es:(%edi)
}
801007f3:	89 d0                	mov    %edx,%eax
801007f5:	8b 7d fc             	mov    -0x4(%ebp),%edi
801007f8:	c9                   	leave  
801007f9:	c3                   	ret    

801007fa <memcmp>:
{
801007fa:	55                   	push   %ebp
801007fb:	89 e5                	mov    %esp,%ebp
801007fd:	56                   	push   %esi
801007fe:	53                   	push   %ebx
801007ff:	8b 45 08             	mov    0x8(%ebp),%eax
80100802:	8b 55 0c             	mov    0xc(%ebp),%edx
80100805:	8b 75 10             	mov    0x10(%ebp),%esi
    while (n-- > 0) {
80100808:	85 f6                	test   %esi,%esi
8010080a:	74 29                	je     80100835 <memcmp+0x3b>
8010080c:	01 c6                	add    %eax,%esi
        if (*s1 != *s2)
8010080e:	0f b6 08             	movzbl (%eax),%ecx
80100811:	0f b6 1a             	movzbl (%edx),%ebx
80100814:	38 d9                	cmp    %bl,%cl
80100816:	75 11                	jne    80100829 <memcmp+0x2f>
        s1++, s2++;
80100818:	83 c0 01             	add    $0x1,%eax
8010081b:	83 c2 01             	add    $0x1,%edx
    while (n-- > 0) {
8010081e:	39 c6                	cmp    %eax,%esi
80100820:	75 ec                	jne    8010080e <memcmp+0x14>
    return 0;
80100822:	b8 00 00 00 00       	mov    $0x0,%eax
80100827:	eb 08                	jmp    80100831 <memcmp+0x37>
            return *s1 - *s2;
80100829:	0f b6 c1             	movzbl %cl,%eax
8010082c:	0f b6 db             	movzbl %bl,%ebx
8010082f:	29 d8                	sub    %ebx,%eax
}
80100831:	5b                   	pop    %ebx
80100832:	5e                   	pop    %esi
80100833:	5d                   	pop    %ebp
80100834:	c3                   	ret    
    return 0;
80100835:	b8 00 00 00 00       	mov    $0x0,%eax
8010083a:	eb f5                	jmp    80100831 <memcmp+0x37>

8010083c <memmove>:
{
8010083c:	55                   	push   %ebp
8010083d:	89 e5                	mov    %esp,%ebp
8010083f:	56                   	push   %esi
80100840:	53                   	push   %ebx
80100841:	8b 75 08             	mov    0x8(%ebp),%esi
80100844:	8b 45 0c             	mov    0xc(%ebp),%eax
80100847:	8b 4d 10             	mov    0x10(%ebp),%ecx
    if (s < d && s + n > d) {
8010084a:	39 f0                	cmp    %esi,%eax
8010084c:	72 20                	jb     8010086e <memmove+0x32>
        while (n-- > 0)
8010084e:	8d 1c 08             	lea    (%eax,%ecx,1),%ebx
80100851:	89 f2                	mov    %esi,%edx
80100853:	85 c9                	test   %ecx,%ecx
80100855:	74 11                	je     80100868 <memmove+0x2c>
            *d++ = *s++;
80100857:	83 c0 01             	add    $0x1,%eax
8010085a:	83 c2 01             	add    $0x1,%edx
8010085d:	0f b6 48 ff          	movzbl -0x1(%eax),%ecx
80100861:	88 4a ff             	mov    %cl,-0x1(%edx)
        while (n-- > 0)
80100864:	39 d8                	cmp    %ebx,%eax
80100866:	75 ef                	jne    80100857 <memmove+0x1b>
}
80100868:	89 f0                	mov    %esi,%eax
8010086a:	5b                   	pop    %ebx
8010086b:	5e                   	pop    %esi
8010086c:	5d                   	pop    %ebp
8010086d:	c3                   	ret    
    if (s < d && s + n > d) {
8010086e:	8d 14 08             	lea    (%eax,%ecx,1),%edx
80100871:	39 d6                	cmp    %edx,%esi
80100873:	73 d9                	jae    8010084e <memmove+0x12>
        while (n-- > 0)
80100875:	8d 51 ff             	lea    -0x1(%ecx),%edx
80100878:	85 c9                	test   %ecx,%ecx
8010087a:	74 ec                	je     80100868 <memmove+0x2c>
            *--d = *--s;
8010087c:	0f b6 0c 10          	movzbl (%eax,%edx,1),%ecx
80100880:	88 0c 16             	mov    %cl,(%esi,%edx,1)
        while (n-- > 0)
80100883:	83 ea 01             	sub    $0x1,%edx
80100886:	83 fa ff             	cmp    $0xffffffff,%edx
80100889:	75 f1                	jne    8010087c <memmove+0x40>
8010088b:	eb db                	jmp    80100868 <memmove+0x2c>

8010088d <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
8010088d:	55                   	push   %ebp
8010088e:	89 e5                	mov    %esp,%ebp
80100890:	57                   	push   %edi
80100891:	56                   	push   %esi
80100892:	53                   	push   %ebx
80100893:	83 ec 1c             	sub    $0x1c,%esp
80100896:	89 c7                	mov    %eax,%edi
    asm volatile("inb %w1,%0"
80100898:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010089d:	ec                   	in     (%dx),%al
         !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
8010089e:	a8 20                	test   $0x20,%al
801008a0:	75 27                	jne    801008c9 <cons_putc+0x3c>
    for (i = 0;
801008a2:	bb 00 00 00 00       	mov    $0x0,%ebx
801008a7:	b9 84 00 00 00       	mov    $0x84,%ecx
801008ac:	be fd 03 00 00       	mov    $0x3fd,%esi
801008b1:	89 ca                	mov    %ecx,%edx
801008b3:	ec                   	in     (%dx),%al
801008b4:	ec                   	in     (%dx),%al
801008b5:	ec                   	in     (%dx),%al
801008b6:	ec                   	in     (%dx),%al
         i++)
801008b7:	83 c3 01             	add    $0x1,%ebx
801008ba:	89 f2                	mov    %esi,%edx
801008bc:	ec                   	in     (%dx),%al
         !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
801008bd:	a8 20                	test   $0x20,%al
801008bf:	75 08                	jne    801008c9 <cons_putc+0x3c>
801008c1:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
801008c7:	7e e8                	jle    801008b1 <cons_putc+0x24>
    outb(COM1 + COM_TX, c);
801008c9:	89 f8                	mov    %edi,%eax
801008cb:	88 45 e7             	mov    %al,-0x19(%ebp)
    asm volatile("outb %0,%w1"
801008ce:	ba f8 03 00 00       	mov    $0x3f8,%edx
801008d3:	ee                   	out    %al,(%dx)
    asm volatile("inb %w1,%0"
801008d4:	ba 79 03 00 00       	mov    $0x379,%edx
801008d9:	ec                   	in     (%dx),%al
    for (i = 0; !(inb(0x378 + 1) & 0x80) && i < 12800; i++)
801008da:	84 c0                	test   %al,%al
801008dc:	78 27                	js     80100905 <cons_putc+0x78>
801008de:	bb 00 00 00 00       	mov    $0x0,%ebx
801008e3:	b9 84 00 00 00       	mov    $0x84,%ecx
801008e8:	be 79 03 00 00       	mov    $0x379,%esi
801008ed:	89 ca                	mov    %ecx,%edx
801008ef:	ec                   	in     (%dx),%al
801008f0:	ec                   	in     (%dx),%al
801008f1:	ec                   	in     (%dx),%al
801008f2:	ec                   	in     (%dx),%al
801008f3:	83 c3 01             	add    $0x1,%ebx
801008f6:	89 f2                	mov    %esi,%edx
801008f8:	ec                   	in     (%dx),%al
801008f9:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
801008ff:	7f 04                	jg     80100905 <cons_putc+0x78>
80100901:	84 c0                	test   %al,%al
80100903:	79 e8                	jns    801008ed <cons_putc+0x60>
    asm volatile("outb %0,%w1"
80100905:	ba 78 03 00 00       	mov    $0x378,%edx
8010090a:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
8010090e:	ee                   	out    %al,(%dx)
8010090f:	ba 7a 03 00 00       	mov    $0x37a,%edx
80100914:	b8 0d 00 00 00       	mov    $0xd,%eax
80100919:	ee                   	out    %al,(%dx)
8010091a:	b8 08 00 00 00       	mov    $0x8,%eax
8010091f:	ee                   	out    %al,(%dx)
        c |= 0x0700;
80100920:	89 f8                	mov    %edi,%eax
80100922:	80 cc 07             	or     $0x7,%ah
80100925:	81 ff 00 01 00 00    	cmp    $0x100,%edi
8010092b:	0f 42 f8             	cmovb  %eax,%edi
    switch (c & 0xff) {
8010092e:	89 f8                	mov    %edi,%eax
80100930:	0f b6 c0             	movzbl %al,%eax
80100933:	89 fb                	mov    %edi,%ebx
80100935:	80 fb 0a             	cmp    $0xa,%bl
80100938:	0f 84 e4 00 00 00    	je     80100a22 <cons_putc+0x195>
8010093e:	83 f8 0a             	cmp    $0xa,%eax
80100941:	7f 46                	jg     80100989 <cons_putc+0xfc>
80100943:	83 f8 08             	cmp    $0x8,%eax
80100946:	0f 84 aa 00 00 00    	je     801009f6 <cons_putc+0x169>
8010094c:	83 f8 09             	cmp    $0x9,%eax
8010094f:	0f 85 da 00 00 00    	jne    80100a2f <cons_putc+0x1a2>
        cons_putc(' ');
80100955:	b8 20 00 00 00       	mov    $0x20,%eax
8010095a:	e8 2e ff ff ff       	call   8010088d <cons_putc>
        cons_putc(' ');
8010095f:	b8 20 00 00 00       	mov    $0x20,%eax
80100964:	e8 24 ff ff ff       	call   8010088d <cons_putc>
        cons_putc(' ');
80100969:	b8 20 00 00 00       	mov    $0x20,%eax
8010096e:	e8 1a ff ff ff       	call   8010088d <cons_putc>
        cons_putc(' ');
80100973:	b8 20 00 00 00       	mov    $0x20,%eax
80100978:	e8 10 ff ff ff       	call   8010088d <cons_putc>
        cons_putc(' ');
8010097d:	b8 20 00 00 00       	mov    $0x20,%eax
80100982:	e8 06 ff ff ff       	call   8010088d <cons_putc>
        break;
80100987:	eb 25                	jmp    801009ae <cons_putc+0x121>
    switch (c & 0xff) {
80100989:	83 f8 0d             	cmp    $0xd,%eax
8010098c:	0f 85 9d 00 00 00    	jne    80100a2f <cons_putc+0x1a2>
        crt_pos -= (crt_pos % CRT_COLS);
80100992:	0f b7 05 08 3b 10 80 	movzwl 0x80103b08,%eax
80100999:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
8010099f:	c1 e8 16             	shr    $0x16,%eax
801009a2:	8d 04 80             	lea    (%eax,%eax,4),%eax
801009a5:	c1 e0 04             	shl    $0x4,%eax
801009a8:	66 a3 08 3b 10 80    	mov    %ax,0x80103b08
    if (crt_pos >= CRT_SIZE) // 当输出字符超过终端范围
801009ae:	0f b7 1d 08 3b 10 80 	movzwl 0x80103b08,%ebx
801009b5:	66 81 fb cf 07       	cmp    $0x7cf,%bx
801009ba:	0f 87 92 00 00 00    	ja     80100a52 <cons_putc+0x1c5>
    outb(addr_6845, 14);
801009c0:	8b 0d 10 3b 10 80    	mov    0x80103b10,%ecx
801009c6:	b8 0e 00 00 00       	mov    $0xe,%eax
801009cb:	89 ca                	mov    %ecx,%edx
801009cd:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos >> 8);
801009ce:	0f b7 1d 08 3b 10 80 	movzwl 0x80103b08,%ebx
801009d5:	8d 71 01             	lea    0x1(%ecx),%esi
801009d8:	89 d8                	mov    %ebx,%eax
801009da:	66 c1 e8 08          	shr    $0x8,%ax
801009de:	89 f2                	mov    %esi,%edx
801009e0:	ee                   	out    %al,(%dx)
801009e1:	b8 0f 00 00 00       	mov    $0xf,%eax
801009e6:	89 ca                	mov    %ecx,%edx
801009e8:	ee                   	out    %al,(%dx)
801009e9:	89 d8                	mov    %ebx,%eax
801009eb:	89 f2                	mov    %esi,%edx
801009ed:	ee                   	out    %al,(%dx)
    serial_putc(c); // 向串口输出
    lpt_putc(c);
    cga_putc(c); // 向控制台输出字符
}
801009ee:	8d 65 f4             	lea    -0xc(%ebp),%esp
801009f1:	5b                   	pop    %ebx
801009f2:	5e                   	pop    %esi
801009f3:	5f                   	pop    %edi
801009f4:	5d                   	pop    %ebp
801009f5:	c3                   	ret    
        if (crt_pos > 0) {
801009f6:	0f b7 05 08 3b 10 80 	movzwl 0x80103b08,%eax
801009fd:	66 85 c0             	test   %ax,%ax
80100a00:	74 be                	je     801009c0 <cons_putc+0x133>
            crt_pos--;
80100a02:	83 e8 01             	sub    $0x1,%eax
80100a05:	66 a3 08 3b 10 80    	mov    %ax,0x80103b08
            crt_buf[crt_pos] = (c & ~0xff) | ' ';
80100a0b:	0f b7 c0             	movzwl %ax,%eax
80100a0e:	66 81 e7 00 ff       	and    $0xff00,%di
80100a13:	83 cf 20             	or     $0x20,%edi
80100a16:	8b 15 0c 3b 10 80    	mov    0x80103b0c,%edx
80100a1c:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
80100a20:	eb 8c                	jmp    801009ae <cons_putc+0x121>
        crt_pos += CRT_COLS;
80100a22:	66 83 05 08 3b 10 80 	addw   $0x50,0x80103b08
80100a29:	50 
80100a2a:	e9 63 ff ff ff       	jmp    80100992 <cons_putc+0x105>
        crt_buf[crt_pos++] = c; /* write the character */
80100a2f:	0f b7 05 08 3b 10 80 	movzwl 0x80103b08,%eax
80100a36:	8d 50 01             	lea    0x1(%eax),%edx
80100a39:	66 89 15 08 3b 10 80 	mov    %dx,0x80103b08
80100a40:	0f b7 c0             	movzwl %ax,%eax
80100a43:	8b 15 0c 3b 10 80    	mov    0x80103b0c,%edx
80100a49:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
        break;
80100a4d:	e9 5c ff ff ff       	jmp    801009ae <cons_putc+0x121>
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t)); // 已有字符往上移动一行
80100a52:	8b 35 0c 3b 10 80    	mov    0x80103b0c,%esi
80100a58:	83 ec 04             	sub    $0x4,%esp
80100a5b:	68 00 0f 00 00       	push   $0xf00
80100a60:	8d 86 a0 00 00 00    	lea    0xa0(%esi),%eax
80100a66:	50                   	push   %eax
80100a67:	56                   	push   %esi
80100a68:	e8 cf fd ff ff       	call   8010083c <memmove>
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++) // 清零最后一行
80100a6d:	8d 86 00 0f 00 00    	lea    0xf00(%esi),%eax
80100a73:	8d 96 a0 0f 00 00    	lea    0xfa0(%esi),%edx
80100a79:	83 c4 10             	add    $0x10,%esp
            crt_buf[i] = 0x0700 | ' ';
80100a7c:	66 c7 00 20 07       	movw   $0x720,(%eax)
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++) // 清零最后一行
80100a81:	83 c0 02             	add    $0x2,%eax
80100a84:	39 d0                	cmp    %edx,%eax
80100a86:	75 f4                	jne    80100a7c <cons_putc+0x1ef>
        crt_pos -= CRT_COLS; // 索引向前移动，即从最后一行的开头写入
80100a88:	83 eb 50             	sub    $0x50,%ebx
80100a8b:	66 89 1d 08 3b 10 80 	mov    %bx,0x80103b08
80100a92:	e9 29 ff ff ff       	jmp    801009c0 <cons_putc+0x133>

80100a97 <printint>:
    return 1;
}

static void
printint(int xx, int base, int sign)
{
80100a97:	55                   	push   %ebp
80100a98:	89 e5                	mov    %esp,%ebp
80100a9a:	57                   	push   %edi
80100a9b:	56                   	push   %esi
80100a9c:	53                   	push   %ebx
80100a9d:	83 ec 2c             	sub    $0x2c,%esp
80100aa0:	89 d3                	mov    %edx,%ebx
    static char digits[] = "0123456789abcdef";
    char buf[16];
    int i;
    uint32_t x;

    if (sign && (sign = xx < 0))
80100aa2:	85 c9                	test   %ecx,%ecx
80100aa4:	74 04                	je     80100aaa <printint+0x13>
80100aa6:	85 c0                	test   %eax,%eax
80100aa8:	78 61                	js     80100b0b <printint+0x74>
        x = -xx;
    else
        x = xx;
80100aaa:	89 c1                	mov    %eax,%ecx
80100aac:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

    i = 0;
80100ab3:	bf 00 00 00 00       	mov    $0x0,%edi
    do {
        buf[i++] = digits[x % base];
80100ab8:	89 fe                	mov    %edi,%esi
80100aba:	83 c7 01             	add    $0x1,%edi
80100abd:	89 c8                	mov    %ecx,%eax
80100abf:	ba 00 00 00 00       	mov    $0x0,%edx
80100ac4:	f7 f3                	div    %ebx
80100ac6:	0f b6 92 60 11 10 80 	movzbl -0x7fefeea0(%edx),%edx
80100acd:	88 54 3d d7          	mov    %dl,-0x29(%ebp,%edi,1)
    } while ((x /= base) != 0);
80100ad1:	89 ca                	mov    %ecx,%edx
80100ad3:	89 c1                	mov    %eax,%ecx
80100ad5:	39 da                	cmp    %ebx,%edx
80100ad7:	73 df                	jae    80100ab8 <printint+0x21>

    if (sign)
80100ad9:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100add:	74 08                	je     80100ae7 <printint+0x50>
        buf[i++] = '-';
80100adf:	c6 44 3d d8 2d       	movb   $0x2d,-0x28(%ebp,%edi,1)
80100ae4:	8d 7e 02             	lea    0x2(%esi),%edi

    while (--i >= 0)
80100ae7:	85 ff                	test   %edi,%edi
80100ae9:	7e 18                	jle    80100b03 <printint+0x6c>
80100aeb:	8d 75 d8             	lea    -0x28(%ebp),%esi
80100aee:	8d 5c 3d d7          	lea    -0x29(%ebp,%edi,1),%ebx
        cons_putc(buf[i]);
80100af2:	0f be 03             	movsbl (%ebx),%eax
80100af5:	e8 93 fd ff ff       	call   8010088d <cons_putc>
    while (--i >= 0)
80100afa:	89 d8                	mov    %ebx,%eax
80100afc:	83 eb 01             	sub    $0x1,%ebx
80100aff:	39 f0                	cmp    %esi,%eax
80100b01:	75 ef                	jne    80100af2 <printint+0x5b>
}
80100b03:	83 c4 2c             	add    $0x2c,%esp
80100b06:	5b                   	pop    %ebx
80100b07:	5e                   	pop    %esi
80100b08:	5f                   	pop    %edi
80100b09:	5d                   	pop    %ebp
80100b0a:	c3                   	ret    
        x = -xx;
80100b0b:	f7 d8                	neg    %eax
80100b0d:	89 c1                	mov    %eax,%ecx
    if (sign && (sign = xx < 0))
80100b0f:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
        x = -xx;
80100b16:	eb 9b                	jmp    80100ab3 <printint+0x1c>

80100b18 <memcpy>:
{
80100b18:	55                   	push   %ebp
80100b19:	89 e5                	mov    %esp,%ebp
80100b1b:	83 ec 0c             	sub    $0xc,%esp
    return memmove(dst, src, n);
80100b1e:	ff 75 10             	push   0x10(%ebp)
80100b21:	ff 75 0c             	push   0xc(%ebp)
80100b24:	ff 75 08             	push   0x8(%ebp)
80100b27:	e8 10 fd ff ff       	call   8010083c <memmove>
}
80100b2c:	c9                   	leave  
80100b2d:	c3                   	ret    

80100b2e <strncmp>:
{
80100b2e:	55                   	push   %ebp
80100b2f:	89 e5                	mov    %esp,%ebp
80100b31:	53                   	push   %ebx
80100b32:	8b 55 08             	mov    0x8(%ebp),%edx
80100b35:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80100b38:	8b 45 10             	mov    0x10(%ebp),%eax
    while (n > 0 && *p && *p == *q)
80100b3b:	85 c0                	test   %eax,%eax
80100b3d:	74 29                	je     80100b68 <strncmp+0x3a>
80100b3f:	0f b6 1a             	movzbl (%edx),%ebx
80100b42:	84 db                	test   %bl,%bl
80100b44:	74 16                	je     80100b5c <strncmp+0x2e>
80100b46:	3a 19                	cmp    (%ecx),%bl
80100b48:	75 12                	jne    80100b5c <strncmp+0x2e>
        n--, p++, q++;
80100b4a:	83 c2 01             	add    $0x1,%edx
80100b4d:	83 c1 01             	add    $0x1,%ecx
    while (n > 0 && *p && *p == *q)
80100b50:	83 e8 01             	sub    $0x1,%eax
80100b53:	75 ea                	jne    80100b3f <strncmp+0x11>
        return 0;
80100b55:	b8 00 00 00 00       	mov    $0x0,%eax
80100b5a:	eb 0c                	jmp    80100b68 <strncmp+0x3a>
    if (n == 0)
80100b5c:	85 c0                	test   %eax,%eax
80100b5e:	74 0d                	je     80100b6d <strncmp+0x3f>
    return (uint8_t)*p - (uint8_t)*q;
80100b60:	0f b6 02             	movzbl (%edx),%eax
80100b63:	0f b6 11             	movzbl (%ecx),%edx
80100b66:	29 d0                	sub    %edx,%eax
}
80100b68:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100b6b:	c9                   	leave  
80100b6c:	c3                   	ret    
        return 0;
80100b6d:	b8 00 00 00 00       	mov    $0x0,%eax
80100b72:	eb f4                	jmp    80100b68 <strncmp+0x3a>

80100b74 <strncpy>:
{
80100b74:	55                   	push   %ebp
80100b75:	89 e5                	mov    %esp,%ebp
80100b77:	57                   	push   %edi
80100b78:	56                   	push   %esi
80100b79:	53                   	push   %ebx
80100b7a:	8b 75 08             	mov    0x8(%ebp),%esi
80100b7d:	8b 55 10             	mov    0x10(%ebp),%edx
    while (n-- > 0 && (*s++ = *t++) != 0)
80100b80:	89 f1                	mov    %esi,%ecx
80100b82:	89 d3                	mov    %edx,%ebx
80100b84:	83 ea 01             	sub    $0x1,%edx
80100b87:	85 db                	test   %ebx,%ebx
80100b89:	7e 17                	jle    80100ba2 <strncpy+0x2e>
80100b8b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80100b8f:	83 c1 01             	add    $0x1,%ecx
80100b92:	8b 45 0c             	mov    0xc(%ebp),%eax
80100b95:	0f b6 78 ff          	movzbl -0x1(%eax),%edi
80100b99:	89 f8                	mov    %edi,%eax
80100b9b:	88 41 ff             	mov    %al,-0x1(%ecx)
80100b9e:	84 c0                	test   %al,%al
80100ba0:	75 e0                	jne    80100b82 <strncpy+0xe>
    while (n-- > 0)
80100ba2:	89 c8                	mov    %ecx,%eax
80100ba4:	8d 4c 19 ff          	lea    -0x1(%ecx,%ebx,1),%ecx
80100ba8:	85 d2                	test   %edx,%edx
80100baa:	7e 0f                	jle    80100bbb <strncpy+0x47>
        *s++ = 0;
80100bac:	83 c0 01             	add    $0x1,%eax
80100baf:	c6 40 ff 00          	movb   $0x0,-0x1(%eax)
    while (n-- > 0)
80100bb3:	89 ca                	mov    %ecx,%edx
80100bb5:	29 c2                	sub    %eax,%edx
80100bb7:	85 d2                	test   %edx,%edx
80100bb9:	7f f1                	jg     80100bac <strncpy+0x38>
}
80100bbb:	89 f0                	mov    %esi,%eax
80100bbd:	5b                   	pop    %ebx
80100bbe:	5e                   	pop    %esi
80100bbf:	5f                   	pop    %edi
80100bc0:	5d                   	pop    %ebp
80100bc1:	c3                   	ret    

80100bc2 <safestrcpy>:
{
80100bc2:	55                   	push   %ebp
80100bc3:	89 e5                	mov    %esp,%ebp
80100bc5:	56                   	push   %esi
80100bc6:	53                   	push   %ebx
80100bc7:	8b 75 08             	mov    0x8(%ebp),%esi
80100bca:	8b 45 0c             	mov    0xc(%ebp),%eax
80100bcd:	8b 55 10             	mov    0x10(%ebp),%edx
    if (n <= 0)
80100bd0:	85 d2                	test   %edx,%edx
80100bd2:	7e 1e                	jle    80100bf2 <safestrcpy+0x30>
80100bd4:	8d 5c 10 ff          	lea    -0x1(%eax,%edx,1),%ebx
80100bd8:	89 f2                	mov    %esi,%edx
    while (--n > 0 && (*s++ = *t++) != 0)
80100bda:	39 d8                	cmp    %ebx,%eax
80100bdc:	74 11                	je     80100bef <safestrcpy+0x2d>
80100bde:	83 c0 01             	add    $0x1,%eax
80100be1:	83 c2 01             	add    $0x1,%edx
80100be4:	0f b6 48 ff          	movzbl -0x1(%eax),%ecx
80100be8:	88 4a ff             	mov    %cl,-0x1(%edx)
80100beb:	84 c9                	test   %cl,%cl
80100bed:	75 eb                	jne    80100bda <safestrcpy+0x18>
    *s = 0;
80100bef:	c6 02 00             	movb   $0x0,(%edx)
}
80100bf2:	89 f0                	mov    %esi,%eax
80100bf4:	5b                   	pop    %ebx
80100bf5:	5e                   	pop    %esi
80100bf6:	5d                   	pop    %ebp
80100bf7:	c3                   	ret    

80100bf8 <strlen>:
{
80100bf8:	55                   	push   %ebp
80100bf9:	89 e5                	mov    %esp,%ebp
80100bfb:	8b 55 08             	mov    0x8(%ebp),%edx
    for (n = 0; s[n]; n++)
80100bfe:	80 3a 00             	cmpb   $0x0,(%edx)
80100c01:	74 10                	je     80100c13 <strlen+0x1b>
80100c03:	b8 00 00 00 00       	mov    $0x0,%eax
80100c08:	83 c0 01             	add    $0x1,%eax
80100c0b:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80100c0f:	75 f7                	jne    80100c08 <strlen+0x10>
}
80100c11:	5d                   	pop    %ebp
80100c12:	c3                   	ret    
    for (n = 0; s[n]; n++)
80100c13:	b8 00 00 00 00       	mov    $0x0,%eax
    return n;
80100c18:	eb f7                	jmp    80100c11 <strlen+0x19>

80100c1a <serial_intr>:
    if (serial_exists)
80100c1a:	80 3d 14 3b 10 80 00 	cmpb   $0x0,0x80103b14
80100c21:	75 01                	jne    80100c24 <serial_intr+0xa>
80100c23:	c3                   	ret    
{
80100c24:	55                   	push   %ebp
80100c25:	89 e5                	mov    %esp,%ebp
80100c27:	83 ec 08             	sub    $0x8,%esp
        cons_intr(serial_proc_data);
80100c2a:	b8 6b 07 10 80       	mov    $0x8010076b,%eax
80100c2f:	e8 51 fb ff ff       	call   80100785 <cons_intr>
}
80100c34:	c9                   	leave  
80100c35:	c3                   	ret    

80100c36 <kbd_intr>:
{
80100c36:	55                   	push   %ebp
80100c37:	89 e5                	mov    %esp,%ebp
80100c39:	83 ec 08             	sub    $0x8,%esp
    cons_intr(kbd_proc_data);
80100c3c:	b8 cc 0d 10 80       	mov    $0x80100dcc,%eax
80100c41:	e8 3f fb ff ff       	call   80100785 <cons_intr>
}
80100c46:	c9                   	leave  
80100c47:	c3                   	ret    

80100c48 <cons_getc>:
{
80100c48:	55                   	push   %ebp
80100c49:	89 e5                	mov    %esp,%ebp
80100c4b:	83 ec 08             	sub    $0x8,%esp
    serial_intr();
80100c4e:	e8 c7 ff ff ff       	call   80100c1a <serial_intr>
    kbd_intr();
80100c53:	e8 de ff ff ff       	call   80100c36 <kbd_intr>
    if (cons.rpos != cons.wpos) {
80100c58:	a1 00 3b 10 80       	mov    0x80103b00,%eax
    return 0;
80100c5d:	ba 00 00 00 00       	mov    $0x0,%edx
    if (cons.rpos != cons.wpos) {
80100c62:	3b 05 04 3b 10 80    	cmp    0x80103b04,%eax
80100c68:	74 1c                	je     80100c86 <cons_getc+0x3e>
        c = cons.buf[cons.rpos++];
80100c6a:	8d 48 01             	lea    0x1(%eax),%ecx
80100c6d:	0f b6 90 00 39 10 80 	movzbl -0x7fefc700(%eax),%edx
            cons.rpos = 0;
80100c74:	3d ff 01 00 00       	cmp    $0x1ff,%eax
80100c79:	b8 00 00 00 00       	mov    $0x0,%eax
80100c7e:	0f 45 c1             	cmovne %ecx,%eax
80100c81:	a3 00 3b 10 80       	mov    %eax,0x80103b00
}
80100c86:	89 d0                	mov    %edx,%eax
80100c88:	c9                   	leave  
80100c89:	c3                   	ret    

80100c8a <cputchar>:
{
80100c8a:	55                   	push   %ebp
80100c8b:	89 e5                	mov    %esp,%ebp
80100c8d:	83 ec 08             	sub    $0x8,%esp
    cons_putc(c);
80100c90:	8b 45 08             	mov    0x8(%ebp),%eax
80100c93:	e8 f5 fb ff ff       	call   8010088d <cons_putc>
}
80100c98:	c9                   	leave  
80100c99:	c3                   	ret    

80100c9a <getchar>:
{
80100c9a:	55                   	push   %ebp
80100c9b:	89 e5                	mov    %esp,%ebp
80100c9d:	83 ec 08             	sub    $0x8,%esp
    while ((c = cons_getc()) == 0)
80100ca0:	e8 a3 ff ff ff       	call   80100c48 <cons_getc>
80100ca5:	85 c0                	test   %eax,%eax
80100ca7:	74 f7                	je     80100ca0 <getchar+0x6>
}
80100ca9:	c9                   	leave  
80100caa:	c3                   	ret    

80100cab <iscons>:
}
80100cab:	b8 01 00 00 00       	mov    $0x1,%eax
80100cb0:	c3                   	ret    

80100cb1 <cprintf>:

void cprintf(char* fmt, ...)
{
80100cb1:	55                   	push   %ebp
80100cb2:	89 e5                	mov    %esp,%ebp
80100cb4:	57                   	push   %edi
80100cb5:	56                   	push   %esi
80100cb6:	53                   	push   %ebx
80100cb7:	83 ec 1c             	sub    $0x1c,%esp

    // if (fmt == 0)
    //     panic("null fmt");

    argp = (uint32_t*)(void*)(&fmt + 1);
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++) {
80100cba:	8b 7d 08             	mov    0x8(%ebp),%edi
80100cbd:	0f b6 07             	movzbl (%edi),%eax
80100cc0:	85 c0                	test   %eax,%eax
80100cc2:	0f 84 fc 00 00 00    	je     80100dc4 <cprintf+0x113>
    argp = (uint32_t*)(void*)(&fmt + 1);
80100cc8:	8d 4d 0c             	lea    0xc(%ebp),%ecx
80100ccb:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++) {
80100cce:	be 00 00 00 00       	mov    $0x0,%esi
80100cd3:	eb 14                	jmp    80100ce9 <cprintf+0x38>
        if (c != '%') {
            cons_putc(c);
80100cd5:	e8 b3 fb ff ff       	call   8010088d <cons_putc>
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++) {
80100cda:	83 c6 01             	add    $0x1,%esi
80100cdd:	0f b6 04 37          	movzbl (%edi,%esi,1),%eax
80100ce1:	85 c0                	test   %eax,%eax
80100ce3:	0f 84 db 00 00 00    	je     80100dc4 <cprintf+0x113>
        if (c != '%') {
80100ce9:	83 f8 25             	cmp    $0x25,%eax
80100cec:	75 e7                	jne    80100cd5 <cprintf+0x24>
            continue;
        }
        c = fmt[++i] & 0xff;
80100cee:	83 c6 01             	add    $0x1,%esi
80100cf1:	0f b6 1c 37          	movzbl (%edi,%esi,1),%ebx
        if (c == 0)
80100cf5:	85 db                	test   %ebx,%ebx
80100cf7:	0f 84 c7 00 00 00    	je     80100dc4 <cprintf+0x113>
            break;
        switch (c) {
80100cfd:	83 fb 70             	cmp    $0x70,%ebx
80100d00:	74 3a                	je     80100d3c <cprintf+0x8b>
80100d02:	7f 2e                	jg     80100d32 <cprintf+0x81>
80100d04:	83 fb 25             	cmp    $0x25,%ebx
80100d07:	0f 84 92 00 00 00    	je     80100d9f <cprintf+0xee>
80100d0d:	83 fb 64             	cmp    $0x64,%ebx
80100d10:	0f 85 98 00 00 00    	jne    80100dae <cprintf+0xfd>
        case 'd':
            printint(*argp++, 10, 1);
80100d16:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d19:	8d 58 04             	lea    0x4(%eax),%ebx
80100d1c:	8b 00                	mov    (%eax),%eax
80100d1e:	b9 01 00 00 00       	mov    $0x1,%ecx
80100d23:	ba 0a 00 00 00       	mov    $0xa,%edx
80100d28:	e8 6a fd ff ff       	call   80100a97 <printint>
80100d2d:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
            break;
80100d30:	eb a8                	jmp    80100cda <cprintf+0x29>
        switch (c) {
80100d32:	83 fb 73             	cmp    $0x73,%ebx
80100d35:	74 21                	je     80100d58 <cprintf+0xa7>
80100d37:	83 fb 78             	cmp    $0x78,%ebx
80100d3a:	75 72                	jne    80100dae <cprintf+0xfd>
        case 'x':
        case 'p':
            printint(*argp++, 16, 0);
80100d3c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d3f:	8d 58 04             	lea    0x4(%eax),%ebx
80100d42:	8b 00                	mov    (%eax),%eax
80100d44:	b9 00 00 00 00       	mov    $0x0,%ecx
80100d49:	ba 10 00 00 00       	mov    $0x10,%edx
80100d4e:	e8 44 fd ff ff       	call   80100a97 <printint>
80100d53:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
            break;
80100d56:	eb 82                	jmp    80100cda <cprintf+0x29>
        case 's':
            if ((s = (char*)*argp++) == 0)
80100d58:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d5b:	8d 50 04             	lea    0x4(%eax),%edx
80100d5e:	89 55 e0             	mov    %edx,-0x20(%ebp)
80100d61:	8b 00                	mov    (%eax),%eax
80100d63:	85 c0                	test   %eax,%eax
80100d65:	74 11                	je     80100d78 <cprintf+0xc7>
80100d67:	89 c3                	mov    %eax,%ebx
                s = "(null)";
            for (; *s; s++)
80100d69:	0f b6 00             	movzbl (%eax),%eax
            if ((s = (char*)*argp++) == 0)
80100d6c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
            for (; *s; s++)
80100d6f:	84 c0                	test   %al,%al
80100d71:	75 0f                	jne    80100d82 <cprintf+0xd1>
80100d73:	e9 62 ff ff ff       	jmp    80100cda <cprintf+0x29>
                s = "(null)";
80100d78:	bb 1f 11 10 80       	mov    $0x8010111f,%ebx
            for (; *s; s++)
80100d7d:	b8 28 00 00 00       	mov    $0x28,%eax
                cons_putc(*s);
80100d82:	0f be c0             	movsbl %al,%eax
80100d85:	e8 03 fb ff ff       	call   8010088d <cons_putc>
            for (; *s; s++)
80100d8a:	83 c3 01             	add    $0x1,%ebx
80100d8d:	0f b6 03             	movzbl (%ebx),%eax
80100d90:	84 c0                	test   %al,%al
80100d92:	75 ee                	jne    80100d82 <cprintf+0xd1>
            if ((s = (char*)*argp++) == 0)
80100d94:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d97:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80100d9a:	e9 3b ff ff ff       	jmp    80100cda <cprintf+0x29>
            break;
        case '%':
            cons_putc('%');
80100d9f:	b8 25 00 00 00       	mov    $0x25,%eax
80100da4:	e8 e4 fa ff ff       	call   8010088d <cons_putc>
            break;
80100da9:	e9 2c ff ff ff       	jmp    80100cda <cprintf+0x29>
        default:
            // Print unknown % sequence to draw attention.
            cons_putc('%');
80100dae:	b8 25 00 00 00       	mov    $0x25,%eax
80100db3:	e8 d5 fa ff ff       	call   8010088d <cons_putc>
            cons_putc(c);
80100db8:	89 d8                	mov    %ebx,%eax
80100dba:	e8 ce fa ff ff       	call   8010088d <cons_putc>
            break;
80100dbf:	e9 16 ff ff ff       	jmp    80100cda <cprintf+0x29>
        }
    }

    // if (locking)
    //     release(&cons.lock);
}
80100dc4:	83 c4 1c             	add    $0x1c,%esp
80100dc7:	5b                   	pop    %ebx
80100dc8:	5e                   	pop    %esi
80100dc9:	5f                   	pop    %edi
80100dca:	5d                   	pop    %ebp
80100dcb:	c3                   	ret    

80100dcc <kbd_proc_data>:
{
80100dcc:	55                   	push   %ebp
80100dcd:	89 e5                	mov    %esp,%ebp
80100dcf:	53                   	push   %ebx
80100dd0:	83 ec 04             	sub    $0x4,%esp
    asm volatile("inb %w1,%0"
80100dd3:	ba 64 00 00 00       	mov    $0x64,%edx
80100dd8:	ec                   	in     (%dx),%al
    if ((stat & KBS_DIB) == 0)
80100dd9:	a8 01                	test   $0x1,%al
80100ddb:	0f 84 ee 00 00 00    	je     80100ecf <kbd_proc_data+0x103>
    if (stat & KBS_TERR)
80100de1:	a8 20                	test   $0x20,%al
80100de3:	0f 85 ed 00 00 00    	jne    80100ed6 <kbd_proc_data+0x10a>
80100de9:	ba 60 00 00 00       	mov    $0x60,%edx
80100dee:	ec                   	in     (%dx),%al
80100def:	89 c2                	mov    %eax,%edx
    if (data == 0xE0) {
80100df1:	3c e0                	cmp    $0xe0,%al
80100df3:	74 61                	je     80100e56 <kbd_proc_data+0x8a>
    } else if (data & 0x80) {
80100df5:	84 c0                	test   %al,%al
80100df7:	78 70                	js     80100e69 <kbd_proc_data+0x9d>
    } else if (shift & E0ESC) {
80100df9:	8b 0d e0 38 10 80    	mov    0x801038e0,%ecx
80100dff:	f6 c1 40             	test   $0x40,%cl
80100e02:	74 0e                	je     80100e12 <kbd_proc_data+0x46>
        data |= 0x80;
80100e04:	83 c8 80             	or     $0xffffff80,%eax
80100e07:	89 c2                	mov    %eax,%edx
        shift &= ~E0ESC;
80100e09:	83 e1 bf             	and    $0xffffffbf,%ecx
80100e0c:	89 0d e0 38 10 80    	mov    %ecx,0x801038e0
    shift |= shiftcode[data];
80100e12:	0f b6 d2             	movzbl %dl,%edx
80100e15:	0f b6 82 a0 12 10 80 	movzbl -0x7fefed60(%edx),%eax
80100e1c:	0b 05 e0 38 10 80    	or     0x801038e0,%eax
    shift ^= togglecode[data];
80100e22:	0f b6 8a a0 11 10 80 	movzbl -0x7fefee60(%edx),%ecx
80100e29:	31 c8                	xor    %ecx,%eax
80100e2b:	a3 e0 38 10 80       	mov    %eax,0x801038e0
    c = charcode[shift & (CTL | SHIFT)][data];
80100e30:	89 c1                	mov    %eax,%ecx
80100e32:	83 e1 03             	and    $0x3,%ecx
80100e35:	8b 0c 8d 74 11 10 80 	mov    -0x7fefee8c(,%ecx,4),%ecx
80100e3c:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
80100e40:	0f b6 da             	movzbl %dl,%ebx
    if (shift & CAPSLOCK) {
80100e43:	a8 08                	test   $0x8,%al
80100e45:	74 5d                	je     80100ea4 <kbd_proc_data+0xd8>
        if ('a' <= c && c <= 'z')
80100e47:	89 da                	mov    %ebx,%edx
80100e49:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
80100e4c:	83 f9 19             	cmp    $0x19,%ecx
80100e4f:	77 47                	ja     80100e98 <kbd_proc_data+0xcc>
            c += 'A' - 'a';
80100e51:	83 eb 20             	sub    $0x20,%ebx
    if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
80100e54:	eb 0c                	jmp    80100e62 <kbd_proc_data+0x96>
        shift |= E0ESC;
80100e56:	83 0d e0 38 10 80 40 	orl    $0x40,0x801038e0
        return 0;
80100e5d:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80100e62:	89 d8                	mov    %ebx,%eax
80100e64:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100e67:	c9                   	leave  
80100e68:	c3                   	ret    
        data = (shift & E0ESC ? data : data & 0x7F);
80100e69:	8b 0d e0 38 10 80    	mov    0x801038e0,%ecx
80100e6f:	83 e0 7f             	and    $0x7f,%eax
80100e72:	f6 c1 40             	test   $0x40,%cl
80100e75:	0f 44 d0             	cmove  %eax,%edx
        shift &= ~(shiftcode[data] | E0ESC);
80100e78:	0f b6 d2             	movzbl %dl,%edx
80100e7b:	0f b6 82 a0 12 10 80 	movzbl -0x7fefed60(%edx),%eax
80100e82:	83 c8 40             	or     $0x40,%eax
80100e85:	0f b6 c0             	movzbl %al,%eax
80100e88:	f7 d0                	not    %eax
80100e8a:	21 c8                	and    %ecx,%eax
80100e8c:	a3 e0 38 10 80       	mov    %eax,0x801038e0
        return 0;
80100e91:	bb 00 00 00 00       	mov    $0x0,%ebx
80100e96:	eb ca                	jmp    80100e62 <kbd_proc_data+0x96>
        else if ('A' <= c && c <= 'Z')
80100e98:	83 ea 41             	sub    $0x41,%edx
            c += 'a' - 'A';
80100e9b:	8d 4b 20             	lea    0x20(%ebx),%ecx
80100e9e:	83 fa 1a             	cmp    $0x1a,%edx
80100ea1:	0f 42 d9             	cmovb  %ecx,%ebx
    if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
80100ea4:	f7 d0                	not    %eax
80100ea6:	a8 06                	test   $0x6,%al
80100ea8:	75 b8                	jne    80100e62 <kbd_proc_data+0x96>
80100eaa:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
80100eb0:	75 b0                	jne    80100e62 <kbd_proc_data+0x96>
        cprintf("Rebooting!\n");
80100eb2:	83 ec 0c             	sub    $0xc,%esp
80100eb5:	68 26 11 10 80       	push   $0x80101126
80100eba:	e8 f2 fd ff ff       	call   80100cb1 <cprintf>
    asm volatile("outb %0,%w1"
80100ebf:	b8 03 00 00 00       	mov    $0x3,%eax
80100ec4:	ba 92 00 00 00       	mov    $0x92,%edx
80100ec9:	ee                   	out    %al,(%dx)
}
80100eca:	83 c4 10             	add    $0x10,%esp
80100ecd:	eb 93                	jmp    80100e62 <kbd_proc_data+0x96>
        return -1;
80100ecf:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80100ed4:	eb 8c                	jmp    80100e62 <kbd_proc_data+0x96>
        return -1;
80100ed6:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80100edb:	eb 85                	jmp    80100e62 <kbd_proc_data+0x96>

80100edd <cons_init>:
{
80100edd:	55                   	push   %ebp
80100ede:	89 e5                	mov    %esp,%ebp
80100ee0:	57                   	push   %edi
80100ee1:	56                   	push   %esi
80100ee2:	53                   	push   %ebx
80100ee3:	83 ec 0c             	sub    $0xc,%esp
    was = *cp;
80100ee6:	0f b7 15 00 80 0b 80 	movzwl 0x800b8000,%edx
    *cp = (uint16_t)0xA55A;
80100eed:	66 c7 05 00 80 0b 80 	movw   $0xa55a,0x800b8000
80100ef4:	5a a5 
    if (*cp != 0xA55A) {
80100ef6:	0f b7 05 00 80 0b 80 	movzwl 0x800b8000,%eax
80100efd:	bb b4 03 00 00       	mov    $0x3b4,%ebx
        cp = (uint16_t*)(K_ADDR_BASE + MONO_BUF);
80100f02:	be 00 00 0b 80       	mov    $0x800b0000,%esi
    if (*cp != 0xA55A) {
80100f07:	66 3d 5a a5          	cmp    $0xa55a,%ax
80100f0b:	0f 84 ab 00 00 00    	je     80100fbc <cons_init+0xdf>
        addr_6845 = MONO_BASE;
80100f11:	89 1d 10 3b 10 80    	mov    %ebx,0x80103b10
    asm volatile("outb %0,%w1"
80100f17:	b8 0e 00 00 00       	mov    $0xe,%eax
80100f1c:	89 da                	mov    %ebx,%edx
80100f1e:	ee                   	out    %al,(%dx)
    pos = inb(addr_6845 + 1) << 8;
80100f1f:	8d 7b 01             	lea    0x1(%ebx),%edi
    asm volatile("inb %w1,%0"
80100f22:	89 fa                	mov    %edi,%edx
80100f24:	ec                   	in     (%dx),%al
80100f25:	0f b6 c8             	movzbl %al,%ecx
80100f28:	c1 e1 08             	shl    $0x8,%ecx
    asm volatile("outb %0,%w1"
80100f2b:	b8 0f 00 00 00       	mov    $0xf,%eax
80100f30:	89 da                	mov    %ebx,%edx
80100f32:	ee                   	out    %al,(%dx)
    asm volatile("inb %w1,%0"
80100f33:	89 fa                	mov    %edi,%edx
80100f35:	ec                   	in     (%dx),%al
    crt_buf = (uint16_t*)cp;
80100f36:	89 35 0c 3b 10 80    	mov    %esi,0x80103b0c
    pos |= inb(addr_6845 + 1);
80100f3c:	0f b6 c0             	movzbl %al,%eax
80100f3f:	09 c8                	or     %ecx,%eax
    crt_pos = pos;
80100f41:	66 a3 08 3b 10 80    	mov    %ax,0x80103b08
    kbd_intr();
80100f47:	e8 ea fc ff ff       	call   80100c36 <kbd_intr>
    asm volatile("outb %0,%w1"
80100f4c:	b9 00 00 00 00       	mov    $0x0,%ecx
80100f51:	bb fa 03 00 00       	mov    $0x3fa,%ebx
80100f56:	89 c8                	mov    %ecx,%eax
80100f58:	89 da                	mov    %ebx,%edx
80100f5a:	ee                   	out    %al,(%dx)
80100f5b:	bf fb 03 00 00       	mov    $0x3fb,%edi
80100f60:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
80100f65:	89 fa                	mov    %edi,%edx
80100f67:	ee                   	out    %al,(%dx)
80100f68:	b8 0c 00 00 00       	mov    $0xc,%eax
80100f6d:	ba f8 03 00 00       	mov    $0x3f8,%edx
80100f72:	ee                   	out    %al,(%dx)
80100f73:	be f9 03 00 00       	mov    $0x3f9,%esi
80100f78:	89 c8                	mov    %ecx,%eax
80100f7a:	89 f2                	mov    %esi,%edx
80100f7c:	ee                   	out    %al,(%dx)
80100f7d:	b8 03 00 00 00       	mov    $0x3,%eax
80100f82:	89 fa                	mov    %edi,%edx
80100f84:	ee                   	out    %al,(%dx)
80100f85:	ba fc 03 00 00       	mov    $0x3fc,%edx
80100f8a:	89 c8                	mov    %ecx,%eax
80100f8c:	ee                   	out    %al,(%dx)
80100f8d:	b8 01 00 00 00       	mov    $0x1,%eax
80100f92:	89 f2                	mov    %esi,%edx
80100f94:	ee                   	out    %al,(%dx)
    asm volatile("inb %w1,%0"
80100f95:	ba fd 03 00 00       	mov    $0x3fd,%edx
80100f9a:	ec                   	in     (%dx),%al
80100f9b:	89 c1                	mov    %eax,%ecx
    serial_exists = (inb(COM1 + COM_LSR) != 0xFF);
80100f9d:	3c ff                	cmp    $0xff,%al
80100f9f:	0f 95 05 14 3b 10 80 	setne  0x80103b14
80100fa6:	89 da                	mov    %ebx,%edx
80100fa8:	ec                   	in     (%dx),%al
80100fa9:	ba f8 03 00 00       	mov    $0x3f8,%edx
80100fae:	ec                   	in     (%dx),%al
    if (!serial_exists)
80100faf:	80 f9 ff             	cmp    $0xff,%cl
80100fb2:	74 1e                	je     80100fd2 <cons_init+0xf5>
}
80100fb4:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100fb7:	5b                   	pop    %ebx
80100fb8:	5e                   	pop    %esi
80100fb9:	5f                   	pop    %edi
80100fba:	5d                   	pop    %ebp
80100fbb:	c3                   	ret    
        *cp = was;
80100fbc:	66 89 15 00 80 0b 80 	mov    %dx,0x800b8000
80100fc3:	bb d4 03 00 00       	mov    $0x3d4,%ebx
    cp = (uint16_t*)(K_ADDR_BASE + CGA_BUF);
80100fc8:	be 00 80 0b 80       	mov    $0x800b8000,%esi
80100fcd:	e9 3f ff ff ff       	jmp    80100f11 <cons_init+0x34>
        cprintf("Serial port does not exist!\n");
80100fd2:	83 ec 0c             	sub    $0xc,%esp
80100fd5:	68 32 11 10 80       	push   $0x80101132
80100fda:	e8 d2 fc ff ff       	call   80100cb1 <cprintf>
80100fdf:	83 c4 10             	add    $0x10,%esp
}
80100fe2:	eb d0                	jmp    80100fb4 <cons_init+0xd7>
