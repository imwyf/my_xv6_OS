
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
80100009:	b8 00 10 10 00       	mov    $0x101000,%eax
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
8010001c:	bc 60 35 10 80       	mov    $0x80103560,%esp

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
80100039:	e8 df 0a 00 00       	call   80100b1d <cons_init>
    cprintf("\n");
8010003e:	83 ec 0c             	sub    $0xc,%esp
80100041:	68 83 0c 10 80       	push   $0x80100c83
80100046:	e8 a6 08 00 00       	call   801008f1 <cprintf>
    cprintf("------> Hello, OS World!\n");
8010004b:	c7 04 24 40 0c 10 80 	movl   $0x80100c40,(%esp)
80100052:	e8 9a 08 00 00       	call   801008f1 <cprintf>
    kmem_init(); // 内存管理初始化
80100057:	e8 c0 02 00 00       	call   8010031c <kmem_init>
    cprintf("------> kmem_init() finish!\n");
8010005c:	c7 04 24 5a 0c 10 80 	movl   $0x80100c5a,(%esp)
80100063:	e8 89 08 00 00       	call   801008f1 <cprintf>
#include "types.h"

static inline void
hlt(void)
{
    asm volatile("hlt");
80100068:	f4                   	hlt    
    hlt();
}
80100069:	b8 00 00 00 00       	mov    $0x0,%eax
8010006e:	8b 4d fc             	mov    -0x4(%ebp),%ecx
80100071:	c9                   	leave  
80100072:	8d 61 fc             	lea    -0x4(%ecx),%esp
80100075:	c3                   	ret    

80100076 <kmem_free>:

/**
 *  释放虚拟地址v指向的内存
 */
void kmem_free(char* vaddr)
{
80100076:	55                   	push   %ebp
80100077:	89 e5                	mov    %esp,%ebp
80100079:	53                   	push   %ebx
8010007a:	83 ec 04             	sub    $0x4,%esp
8010007d:	8b 5d 08             	mov    0x8(%ebp),%ebx
    if ((vaddr_t)vaddr % PGSIZE || vaddr < end || K_V2P(vaddr) >= P_ADDR_PHYSTOP)
80100080:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80100086:	75 15                	jne    8010009d <kmem_free+0x27>
80100088:	81 fb 60 35 10 80    	cmp    $0x80103560,%ebx
8010008e:	72 0d                	jb     8010009d <kmem_free+0x27>
80100090:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80100096:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
8010009b:	76 10                	jbe    801000ad <kmem_free+0x37>
        cprintf("kfree error \n");
8010009d:	83 ec 0c             	sub    $0xc,%esp
801000a0:	68 77 0c 10 80       	push   $0x80100c77
801000a5:	e8 47 08 00 00       	call   801008f1 <cprintf>
801000aa:	83 c4 10             	add    $0x10,%esp

    memset(vaddr, 1, PGSIZE); // 清空该页内存
801000ad:	83 ec 04             	sub    $0x4,%esp
801000b0:	68 00 10 00 00       	push   $0x1000
801000b5:	6a 01                	push   $0x1
801000b7:	53                   	push   %ebx
801000b8:	e8 3a 03 00 00       	call   801003f7 <memset>

    // if (kmem.use_lock)
    //     acquire(&kmem.lock);
    struct list_node* node = (struct list_node*)vaddr;
    node->next = kmem.freelist;
801000bd:	a1 00 23 10 80       	mov    0x80102300,%eax
801000c2:	89 03                	mov    %eax,(%ebx)
    kmem.freelist = node;
801000c4:	89 1d 00 23 10 80    	mov    %ebx,0x80102300
    // if (kmem.use_lock)
    //     release(&kmem.lock);
}
801000ca:	83 c4 10             	add    $0x10,%esp
801000cd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801000d0:	c9                   	leave  
801000d1:	c3                   	ret    

801000d2 <kmem_free_pages>:
{
801000d2:	55                   	push   %ebp
801000d3:	89 e5                	mov    %esp,%ebp
801000d5:	56                   	push   %esi
801000d6:	53                   	push   %ebx
801000d7:	8b 75 0c             	mov    0xc(%ebp),%esi
    p = (char*)PGROUNDUP((vaddr_t)start);
801000da:	8b 45 08             	mov    0x8(%ebp),%eax
801000dd:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801000e3:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
    for (; p + PGSIZE <= (char*)end; p += PGSIZE) {
801000e9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801000ef:	39 de                	cmp    %ebx,%esi
801000f1:	72 1c                	jb     8010010f <kmem_free_pages+0x3d>
        kmem_free(p);
801000f3:	83 ec 0c             	sub    $0xc,%esp
801000f6:	8d 83 00 f0 ff ff    	lea    -0x1000(%ebx),%eax
801000fc:	50                   	push   %eax
801000fd:	e8 74 ff ff ff       	call   80100076 <kmem_free>
    for (; p + PGSIZE <= (char*)end; p += PGSIZE) {
80100102:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80100108:	83 c4 10             	add    $0x10,%esp
8010010b:	39 f3                	cmp    %esi,%ebx
8010010d:	76 e4                	jbe    801000f3 <kmem_free_pages+0x21>
}
8010010f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100112:	5b                   	pop    %ebx
80100113:	5e                   	pop    %esi
80100114:	5d                   	pop    %ebp
80100115:	c3                   	ret    

80100116 <kmem_alloc>:
{
    struct list_node* node = NULL;

    // if (kmem.use_lock)
    //     acquire(&kmem.lock);
    node = kmem.freelist;
80100116:	a1 00 23 10 80       	mov    0x80102300,%eax
    if (node)
8010011b:	85 c0                	test   %eax,%eax
8010011d:	74 08                	je     80100127 <kmem_alloc+0x11>
        kmem.freelist = node->next;
8010011f:	8b 10                	mov    (%eax),%edx
80100121:	89 15 00 23 10 80    	mov    %edx,0x80102300
    // if (kmem.use_lock)
    //     release(&kmem.lock);
    return (char*)node;
}
80100127:	c3                   	ret    

80100128 <kmmap>:

/**
 * 在页表 pgdir 中进行虚拟内存到物理内存的映射：虚拟地址 vaddr -> 物理地址 paddr，映射长度为 size，权限为 perm，成功返回0，不成功返回-1
 */
static int kmmap(pde_t* pgdir, void* vaddr, uint32_t size, paddr_t paddr, int perm)
{
80100128:	55                   	push   %ebp
80100129:	89 e5                	mov    %esp,%ebp
8010012b:	57                   	push   %edi
8010012c:	56                   	push   %esi
8010012d:	53                   	push   %ebx
8010012e:	83 ec 2c             	sub    $0x2c,%esp
80100131:	89 45 dc             	mov    %eax,-0x24(%ebp)
    char *va_start, *va_end;
    pte_t* pte;

    if (size == 0) {
80100134:	85 c9                	test   %ecx,%ecx
80100136:	74 20                	je     80100158 <kmmap+0x30>
80100138:	89 d0                	mov    %edx,%eax
        cprintf("kmmap() error: size = 0, it should be > 0\n");
        return -1;
    }

    /* 先对齐，并求出需要映射的虚拟地址范围 */
    va_start = (char*)PGROUNDDOWN((vaddr_t)vaddr);
8010013a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
80100140:	89 d7                	mov    %edx,%edi
    va_end = (char*)PGROUNDDOWN(((vaddr_t)vaddr) + size - 1);
80100142:	8d 44 08 ff          	lea    -0x1(%eax,%ecx,1),%eax
80100146:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010014b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
8010014e:	8b 45 08             	mov    0x8(%ebp),%eax
80100151:	29 d0                	sub    %edx,%eax
80100153:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100156:	eb 58                	jmp    801001b0 <kmmap+0x88>
        cprintf("kmmap() error: size = 0, it should be > 0\n");
80100158:	83 ec 0c             	sub    $0xc,%esp
8010015b:	68 88 0c 10 80       	push   $0x80100c88
80100160:	e8 8c 07 00 00       	call   801008f1 <cprintf>
        return -1;
80100165:	83 c4 10             	add    $0x10,%esp
80100168:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010016d:	e9 b8 00 00 00       	jmp    8010022a <kmmap+0x102>
    pde_t* pde; // 页目录项（一级）
    pte_t* pte; // 页表项（二级）

    pde = &pgdir[PDX(vaddr)]; // 根据 vaddr 获取对应的页目录项
    if (*pde & PTE_P) { // 页目录项存在
        pte = (pte_t*)K_P2V(PTE_ADDR(*pde)); // 取出 PPN 所对应的二级页表（即 pte 数组）的地址
80100172:	25 00 f0 ff ff       	and    $0xfffff000,%eax
            return NULL;

        memset(pte, 0, PGSIZE);
        *pde = K_V2P(pte) | perm | PTE_P; // 将二级页表的物理地址写入页目录项
    }
    return &pte[PTX(vaddr)]; // 从二级页表中取出对应的页表项
80100177:	89 fa                	mov    %edi,%edx
80100179:	c1 ea 0a             	shr    $0xa,%edx
8010017c:	81 e2 fc 0f 00 00    	and    $0xffc,%edx
80100182:	8d 9c 10 00 00 00 80 	lea    -0x80000000(%eax,%edx,1),%ebx
        if ((pte = get_pte(pgdir, va_start, 1, perm)) == NULL) // 找到 pte
80100189:	85 db                	test   %ebx,%ebx
8010018b:	0f 84 8d 00 00 00    	je     8010021e <kmmap+0xf6>
        if (*pte & PTE_P) {
80100191:	f6 03 01             	testb  $0x1,(%ebx)
80100194:	75 71                	jne    80100207 <kmmap+0xdf>
        *pte = paddr | perm | PTE_P; // 填写 pte
80100196:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100199:	0b 45 0c             	or     0xc(%ebp),%eax
8010019c:	83 c8 01             	or     $0x1,%eax
8010019f:	89 03                	mov    %eax,(%ebx)
        if (va_start == va_end) // 映射完成
801001a1:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
801001a4:	0f 84 88 00 00 00    	je     80100232 <kmmap+0x10a>
        va_start += PGSIZE;
801001aa:	81 c7 00 10 00 00    	add    $0x1000,%edi
    while (1) {
801001b0:	89 7d e0             	mov    %edi,-0x20(%ebp)
801001b3:	8b 45 d8             	mov    -0x28(%ebp),%eax
801001b6:	01 f8                	add    %edi,%eax
801001b8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    pde = &pgdir[PDX(vaddr)]; // 根据 vaddr 获取对应的页目录项
801001bb:	89 f8                	mov    %edi,%eax
801001bd:	c1 e8 16             	shr    $0x16,%eax
801001c0:	8b 4d dc             	mov    -0x24(%ebp),%ecx
801001c3:	8d 34 81             	lea    (%ecx,%eax,4),%esi
    if (*pde & PTE_P) { // 页目录项存在
801001c6:	8b 06                	mov    (%esi),%eax
801001c8:	a8 01                	test   $0x1,%al
801001ca:	75 a6                	jne    80100172 <kmmap+0x4a>
        if (!need_alloc || (pte = (pte_t*)kmem_alloc()) == NULL) // 不需要分配或分配失败
801001cc:	e8 45 ff ff ff       	call   80100116 <kmem_alloc>
801001d1:	89 c3                	mov    %eax,%ebx
801001d3:	85 c0                	test   %eax,%eax
801001d5:	74 4e                	je     80100225 <kmmap+0xfd>
        memset(pte, 0, PGSIZE);
801001d7:	83 ec 04             	sub    $0x4,%esp
801001da:	68 00 10 00 00       	push   $0x1000
801001df:	6a 00                	push   $0x0
801001e1:	50                   	push   %eax
801001e2:	e8 10 02 00 00       	call   801003f7 <memset>
        *pde = K_V2P(pte) | perm | PTE_P; // 将二级页表的物理地址写入页目录项
801001e7:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801001ed:	0b 45 0c             	or     0xc(%ebp),%eax
801001f0:	83 c8 01             	or     $0x1,%eax
801001f3:	89 06                	mov    %eax,(%esi)
    return &pte[PTX(vaddr)]; // 从二级页表中取出对应的页表项
801001f5:	8b 45 e0             	mov    -0x20(%ebp),%eax
801001f8:	c1 e8 0a             	shr    $0xa,%eax
801001fb:	25 fc 0f 00 00       	and    $0xffc,%eax
80100200:	01 c3                	add    %eax,%ebx
80100202:	83 c4 10             	add    $0x10,%esp
80100205:	eb 8a                	jmp    80100191 <kmmap+0x69>
            cprintf("kmmap error: pte already present\n");
80100207:	83 ec 0c             	sub    $0xc,%esp
8010020a:	68 b4 0c 10 80       	push   $0x80100cb4
8010020f:	e8 dd 06 00 00       	call   801008f1 <cprintf>
            return -1;
80100214:	83 c4 10             	add    $0x10,%esp
80100217:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010021c:	eb 0c                	jmp    8010022a <kmmap+0x102>
            return -1;
8010021e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100223:	eb 05                	jmp    8010022a <kmmap+0x102>
80100225:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010022a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010022d:	5b                   	pop    %ebx
8010022e:	5e                   	pop    %esi
8010022f:	5f                   	pop    %edi
80100230:	5d                   	pop    %ebp
80100231:	c3                   	ret    
    return 0;
80100232:	b8 00 00 00 00       	mov    $0x0,%eax
80100237:	eb f1                	jmp    8010022a <kmmap+0x102>

80100239 <set_kernel_pgdir>:
{
80100239:	55                   	push   %ebp
8010023a:	89 e5                	mov    %esp,%ebp
8010023c:	53                   	push   %ebx
8010023d:	83 ec 04             	sub    $0x4,%esp
    if ((kernel_pgdir = (pde_t*)kmem_alloc()) == 0) // 分配一页内存作为一级页表页（即页目录）
80100240:	e8 d1 fe ff ff       	call   80100116 <kmem_alloc>
80100245:	89 c3                	mov    %eax,%ebx
80100247:	85 c0                	test   %eax,%eax
80100249:	0f 84 ac 00 00 00    	je     801002fb <set_kernel_pgdir+0xc2>
    memset(kernel_pgdir, 0, PGSIZE);
8010024f:	83 ec 04             	sub    $0x4,%esp
80100252:	68 00 10 00 00       	push   $0x1000
80100257:	6a 00                	push   $0x0
80100259:	50                   	push   %eax
8010025a:	e8 98 01 00 00       	call   801003f7 <memset>
    if (kmmap(kernel_pgdir, (void*)K_ADDR_BASE, P_ADDR_EXTMEM - 0, (paddr_t)0, PTE_W) < 0) { // 映射低1MB内存
8010025f:	83 c4 08             	add    $0x8,%esp
80100262:	6a 02                	push   $0x2
80100264:	6a 00                	push   $0x0
80100266:	b9 00 00 10 00       	mov    $0x100000,%ecx
8010026b:	ba 00 00 00 80       	mov    $0x80000000,%edx
80100270:	89 d8                	mov    %ebx,%eax
80100272:	e8 b1 fe ff ff       	call   80100128 <kmmap>
80100277:	83 c4 10             	add    $0x10,%esp
8010027a:	85 c0                	test   %eax,%eax
8010027c:	78 6c                	js     801002ea <set_kernel_pgdir+0xb1>
    if (kmmap(kernel_pgdir, (void*)K_ADDR_LOAD, K_V2P(data) - K_V2P(K_ADDR_LOAD), K_V2P(K_ADDR_LOAD), 0) < 0) { // 映射内核代码段和数据段占据的内存
8010027e:	83 ec 08             	sub    $0x8,%esp
80100281:	6a 00                	push   $0x0
80100283:	68 00 00 10 00       	push   $0x100000
80100288:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010028d:	ba 00 00 10 80       	mov    $0x80100000,%edx
80100292:	89 d8                	mov    %ebx,%eax
80100294:	e8 8f fe ff ff       	call   80100128 <kmmap>
80100299:	83 c4 10             	add    $0x10,%esp
8010029c:	85 c0                	test   %eax,%eax
8010029e:	78 4a                	js     801002ea <set_kernel_pgdir+0xb1>
    if (kmmap(kernel_pgdir, (void*)data, P_ADDR_PHYSTOP - K_V2P(data), K_V2P(data), PTE_W) < 0) { // 映射内核数据段后面的内存
801002a0:	b9 00 00 00 8e       	mov    $0x8e000000,%ecx
801002a5:	81 e9 00 10 10 80    	sub    $0x80101000,%ecx
801002ab:	83 ec 08             	sub    $0x8,%esp
801002ae:	6a 02                	push   $0x2
801002b0:	68 00 10 10 00       	push   $0x101000
801002b5:	ba 00 10 10 80       	mov    $0x80101000,%edx
801002ba:	89 d8                	mov    %ebx,%eax
801002bc:	e8 67 fe ff ff       	call   80100128 <kmmap>
801002c1:	83 c4 10             	add    $0x10,%esp
801002c4:	85 c0                	test   %eax,%eax
801002c6:	78 22                	js     801002ea <set_kernel_pgdir+0xb1>
    if (kmmap(kernel_pgdir, (void*)P_ADDR_DEVSPACE, 0 - P_ADDR_DEVSPACE, (paddr_t)P_ADDR_DEVSPACE, PTE_W) < 0) { // 映射设备内存（直接映射）
801002c8:	83 ec 08             	sub    $0x8,%esp
801002cb:	6a 02                	push   $0x2
801002cd:	68 00 00 00 fe       	push   $0xfe000000
801002d2:	b9 00 00 00 02       	mov    $0x2000000,%ecx
801002d7:	ba 00 00 00 fe       	mov    $0xfe000000,%edx
801002dc:	89 d8                	mov    %ebx,%eax
801002de:	e8 45 fe ff ff       	call   80100128 <kmmap>
801002e3:	83 c4 10             	add    $0x10,%esp
801002e6:	85 c0                	test   %eax,%eax
801002e8:	79 11                	jns    801002fb <set_kernel_pgdir+0xc2>
    kmem_free((char*)kernel_pgdir);
801002ea:	83 ec 0c             	sub    $0xc,%esp
801002ed:	53                   	push   %ebx
801002ee:	e8 83 fd ff ff       	call   80100076 <kmem_free>
    return 0;
801002f3:	83 c4 10             	add    $0x10,%esp
801002f6:	bb 00 00 00 00       	mov    $0x0,%ebx
}
801002fb:	89 d8                	mov    %ebx,%eax
801002fd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100300:	c9                   	leave  
80100301:	c3                   	ret    

80100302 <switch_pgdir>:
{
80100302:	55                   	push   %ebp
80100303:	89 e5                	mov    %esp,%ebp
    if (p == NULL) {
80100305:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80100309:	74 02                	je     8010030d <switch_pgdir+0xb>
}
8010030b:	5d                   	pop    %ebp
8010030c:	c3                   	ret    
        lcr3(K_V2P(kernel_pgdir));
8010030d:	a1 04 23 10 80       	mov    0x80102304,%eax
80100312:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint32_t val)
{
    asm volatile("movl %0,%%cr3"
80100317:	0f 22 d8             	mov    %eax,%cr3
}
8010031a:	eb ef                	jmp    8010030b <switch_pgdir+0x9>

8010031c <kmem_init>:
{
8010031c:	55                   	push   %ebp
8010031d:	89 e5                	mov    %esp,%ebp
8010031f:	83 ec 10             	sub    $0x10,%esp
    kmem_free_pages(end, K_P2V(P_ADDR_LOWMEM)); // 释放[end, 4MB]部分给新的内核页表使用
80100322:	68 00 00 40 80       	push   $0x80400000
80100327:	68 60 35 10 80       	push   $0x80103560
8010032c:	e8 a1 fd ff ff       	call   801000d2 <kmem_free_pages>
    kernel_pgdir = set_kernel_pgdir(); // 设置内核页表
80100331:	e8 03 ff ff ff       	call   80100239 <set_kernel_pgdir>
80100336:	a3 04 23 10 80       	mov    %eax,0x80102304
    switch_pgdir(NULL); // NULL 代表切换为内核页表
8010033b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80100342:	e8 bb ff ff ff       	call   80100302 <switch_pgdir>
}
80100347:	83 c4 10             	add    $0x10,%esp
8010034a:	c9                   	leave  
8010034b:	c3                   	ret    

8010034c <free_pgdir>:
{
8010034c:	55                   	push   %ebp
8010034d:	89 e5                	mov    %esp,%ebp
8010034f:	56                   	push   %esi
80100350:	53                   	push   %ebx
80100351:	8b 75 08             	mov    0x8(%ebp),%esi
80100354:	bb 00 00 00 00       	mov    $0x0,%ebx
80100359:	eb 0b                	jmp    80100366 <free_pgdir+0x1a>
    for (int i = 0; i < NPDENTRIES; i++) {
8010035b:	83 c3 04             	add    $0x4,%ebx
8010035e:	81 fb 00 10 00 00    	cmp    $0x1000,%ebx
80100364:	74 22                	je     80100388 <free_pgdir+0x3c>
        if (p->pgdir[i] & PTE_P) {
80100366:	8b 46 04             	mov    0x4(%esi),%eax
80100369:	8b 04 18             	mov    (%eax,%ebx,1),%eax
8010036c:	a8 01                	test   $0x1,%al
8010036e:	74 eb                	je     8010035b <free_pgdir+0xf>
            kmem_free(v);
80100370:	83 ec 0c             	sub    $0xc,%esp
            char* v = K_P2V(PTE_ADDR(p->pgdir[i]));
80100373:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100378:	05 00 00 00 80       	add    $0x80000000,%eax
            kmem_free(v);
8010037d:	50                   	push   %eax
8010037e:	e8 f3 fc ff ff       	call   80100076 <kmem_free>
80100383:	83 c4 10             	add    $0x10,%esp
80100386:	eb d3                	jmp    8010035b <free_pgdir+0xf>
    kmem_free((char*)p->pgdir); // 释放页目录
80100388:	83 ec 0c             	sub    $0xc,%esp
8010038b:	ff 76 04             	push   0x4(%esi)
8010038e:	e8 e3 fc ff ff       	call   80100076 <kmem_free>
}
80100393:	83 c4 10             	add    $0x10,%esp
80100396:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100399:	5b                   	pop    %ebx
8010039a:	5e                   	pop    %esi
8010039b:	5d                   	pop    %ebp
8010039c:	c3                   	ret    

8010039d <serial_proc_data>:
    asm volatile("inb %w1,%0"
8010039d:	ba fd 03 00 00       	mov    $0x3fd,%edx
801003a2:	ec                   	in     (%dx),%al
static bool serial_exists;

static int
serial_proc_data(void)
{
    if (!(inb(COM1 + COM_LSR) & COM_LSR_DATA))
801003a3:	a8 01                	test   $0x1,%al
801003a5:	74 0a                	je     801003b1 <serial_proc_data+0x14>
801003a7:	ba f8 03 00 00       	mov    $0x3f8,%edx
801003ac:	ec                   	in     (%dx),%al
        return -1;
    return inb(COM1 + COM_RX);
801003ad:	0f b6 c0             	movzbl %al,%eax
801003b0:	c3                   	ret    
        return -1;
801003b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801003b6:	c3                   	ret    

801003b7 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
801003b7:	55                   	push   %ebp
801003b8:	89 e5                	mov    %esp,%ebp
801003ba:	53                   	push   %ebx
801003bb:	83 ec 04             	sub    $0x4,%esp
801003be:	89 c3                	mov    %eax,%ebx
    int c;

    while ((c = (*proc)()) != -1) {
801003c0:	eb 23                	jmp    801003e5 <cons_intr+0x2e>
        if (c == 0)
            continue;
        cons.buf[cons.wpos++] = c;
801003c2:	8b 0d 44 25 10 80    	mov    0x80102544,%ecx
801003c8:	8d 51 01             	lea    0x1(%ecx),%edx
801003cb:	88 81 40 23 10 80    	mov    %al,-0x7fefdcc0(%ecx)
        if (cons.wpos == CONSBUFSIZE)
801003d1:	81 fa 00 02 00 00    	cmp    $0x200,%edx
            cons.wpos = 0;
801003d7:	b8 00 00 00 00       	mov    $0x0,%eax
801003dc:	0f 44 d0             	cmove  %eax,%edx
801003df:	89 15 44 25 10 80    	mov    %edx,0x80102544
    while ((c = (*proc)()) != -1) {
801003e5:	ff d3                	call   *%ebx
801003e7:	83 f8 ff             	cmp    $0xffffffff,%eax
801003ea:	74 06                	je     801003f2 <cons_intr+0x3b>
        if (c == 0)
801003ec:	85 c0                	test   %eax,%eax
801003ee:	75 d2                	jne    801003c2 <cons_intr+0xb>
801003f0:	eb f3                	jmp    801003e5 <cons_intr+0x2e>
    }
}
801003f2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801003f5:	c9                   	leave  
801003f6:	c3                   	ret    

801003f7 <memset>:
{
801003f7:	55                   	push   %ebp
801003f8:	89 e5                	mov    %esp,%ebp
801003fa:	57                   	push   %edi
801003fb:	53                   	push   %ebx
801003fc:	8b 55 08             	mov    0x8(%ebp),%edx
801003ff:	8b 45 0c             	mov    0xc(%ebp),%eax
80100402:	8b 4d 10             	mov    0x10(%ebp),%ecx
    if ((int)dst % 4 == 0 && n % 4 == 0) {
80100405:	89 d7                	mov    %edx,%edi
80100407:	09 cf                	or     %ecx,%edi
80100409:	f7 c7 03 00 00 00    	test   $0x3,%edi
8010040f:	75 1e                	jne    8010042f <memset+0x38>
        c &= 0xFF;
80100411:	0f b6 f8             	movzbl %al,%edi
        stosl(dst, (c << 24) | (c << 16) | (c << 8) | c, n / 4);
80100414:	c1 e9 02             	shr    $0x2,%ecx
80100417:	c1 e0 18             	shl    $0x18,%eax
8010041a:	89 fb                	mov    %edi,%ebx
8010041c:	c1 e3 10             	shl    $0x10,%ebx
8010041f:	09 d8                	or     %ebx,%eax
80100421:	09 f8                	or     %edi,%eax
80100423:	c1 e7 08             	shl    $0x8,%edi
80100426:	09 f8                	or     %edi,%eax
    asm volatile("cld; rep stosl"
80100428:	89 d7                	mov    %edx,%edi
8010042a:	fc                   	cld    
8010042b:	f3 ab                	rep stos %eax,%es:(%edi)
}
8010042d:	eb 05                	jmp    80100434 <memset+0x3d>
    asm volatile("cld; rep stosb"
8010042f:	89 d7                	mov    %edx,%edi
80100431:	fc                   	cld    
80100432:	f3 aa                	rep stos %al,%es:(%edi)
}
80100434:	89 d0                	mov    %edx,%eax
80100436:	5b                   	pop    %ebx
80100437:	5f                   	pop    %edi
80100438:	5d                   	pop    %ebp
80100439:	c3                   	ret    

8010043a <memcmp>:
{
8010043a:	55                   	push   %ebp
8010043b:	89 e5                	mov    %esp,%ebp
8010043d:	56                   	push   %esi
8010043e:	53                   	push   %ebx
8010043f:	8b 45 08             	mov    0x8(%ebp),%eax
80100442:	8b 55 0c             	mov    0xc(%ebp),%edx
80100445:	8b 75 10             	mov    0x10(%ebp),%esi
    while (n-- > 0) {
80100448:	85 f6                	test   %esi,%esi
8010044a:	74 29                	je     80100475 <memcmp+0x3b>
8010044c:	01 c6                	add    %eax,%esi
        if (*s1 != *s2)
8010044e:	0f b6 08             	movzbl (%eax),%ecx
80100451:	0f b6 1a             	movzbl (%edx),%ebx
80100454:	38 d9                	cmp    %bl,%cl
80100456:	75 11                	jne    80100469 <memcmp+0x2f>
        s1++, s2++;
80100458:	83 c0 01             	add    $0x1,%eax
8010045b:	83 c2 01             	add    $0x1,%edx
    while (n-- > 0) {
8010045e:	39 c6                	cmp    %eax,%esi
80100460:	75 ec                	jne    8010044e <memcmp+0x14>
    return 0;
80100462:	b8 00 00 00 00       	mov    $0x0,%eax
80100467:	eb 08                	jmp    80100471 <memcmp+0x37>
            return *s1 - *s2;
80100469:	0f b6 c1             	movzbl %cl,%eax
8010046c:	0f b6 db             	movzbl %bl,%ebx
8010046f:	29 d8                	sub    %ebx,%eax
}
80100471:	5b                   	pop    %ebx
80100472:	5e                   	pop    %esi
80100473:	5d                   	pop    %ebp
80100474:	c3                   	ret    
    return 0;
80100475:	b8 00 00 00 00       	mov    $0x0,%eax
8010047a:	eb f5                	jmp    80100471 <memcmp+0x37>

8010047c <memmove>:
{
8010047c:	55                   	push   %ebp
8010047d:	89 e5                	mov    %esp,%ebp
8010047f:	56                   	push   %esi
80100480:	53                   	push   %ebx
80100481:	8b 75 08             	mov    0x8(%ebp),%esi
80100484:	8b 45 0c             	mov    0xc(%ebp),%eax
80100487:	8b 4d 10             	mov    0x10(%ebp),%ecx
    if (s < d && s + n > d) {
8010048a:	39 f0                	cmp    %esi,%eax
8010048c:	72 20                	jb     801004ae <memmove+0x32>
        while (n-- > 0)
8010048e:	8d 1c 08             	lea    (%eax,%ecx,1),%ebx
80100491:	89 f2                	mov    %esi,%edx
80100493:	85 c9                	test   %ecx,%ecx
80100495:	74 11                	je     801004a8 <memmove+0x2c>
            *d++ = *s++;
80100497:	83 c0 01             	add    $0x1,%eax
8010049a:	83 c2 01             	add    $0x1,%edx
8010049d:	0f b6 48 ff          	movzbl -0x1(%eax),%ecx
801004a1:	88 4a ff             	mov    %cl,-0x1(%edx)
        while (n-- > 0)
801004a4:	39 d8                	cmp    %ebx,%eax
801004a6:	75 ef                	jne    80100497 <memmove+0x1b>
}
801004a8:	89 f0                	mov    %esi,%eax
801004aa:	5b                   	pop    %ebx
801004ab:	5e                   	pop    %esi
801004ac:	5d                   	pop    %ebp
801004ad:	c3                   	ret    
    if (s < d && s + n > d) {
801004ae:	8d 14 08             	lea    (%eax,%ecx,1),%edx
801004b1:	39 d6                	cmp    %edx,%esi
801004b3:	73 d9                	jae    8010048e <memmove+0x12>
        while (n-- > 0)
801004b5:	8d 51 ff             	lea    -0x1(%ecx),%edx
801004b8:	85 c9                	test   %ecx,%ecx
801004ba:	74 ec                	je     801004a8 <memmove+0x2c>
            *--d = *--s;
801004bc:	0f b6 0c 10          	movzbl (%eax,%edx,1),%ecx
801004c0:	88 0c 16             	mov    %cl,(%esi,%edx,1)
        while (n-- > 0)
801004c3:	83 ea 01             	sub    $0x1,%edx
801004c6:	83 fa ff             	cmp    $0xffffffff,%edx
801004c9:	75 f1                	jne    801004bc <memmove+0x40>
801004cb:	eb db                	jmp    801004a8 <memmove+0x2c>

801004cd <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
801004cd:	55                   	push   %ebp
801004ce:	89 e5                	mov    %esp,%ebp
801004d0:	57                   	push   %edi
801004d1:	56                   	push   %esi
801004d2:	53                   	push   %ebx
801004d3:	83 ec 1c             	sub    $0x1c,%esp
801004d6:	89 c7                	mov    %eax,%edi
    asm volatile("inb %w1,%0"
801004d8:	ba fd 03 00 00       	mov    $0x3fd,%edx
801004dd:	ec                   	in     (%dx),%al
         !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
801004de:	a8 20                	test   $0x20,%al
801004e0:	75 27                	jne    80100509 <cons_putc+0x3c>
    for (i = 0;
801004e2:	bb 00 00 00 00       	mov    $0x0,%ebx
801004e7:	b9 84 00 00 00       	mov    $0x84,%ecx
801004ec:	be fd 03 00 00       	mov    $0x3fd,%esi
801004f1:	89 ca                	mov    %ecx,%edx
801004f3:	ec                   	in     (%dx),%al
801004f4:	ec                   	in     (%dx),%al
801004f5:	ec                   	in     (%dx),%al
801004f6:	ec                   	in     (%dx),%al
         i++)
801004f7:	83 c3 01             	add    $0x1,%ebx
801004fa:	89 f2                	mov    %esi,%edx
801004fc:	ec                   	in     (%dx),%al
         !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
801004fd:	a8 20                	test   $0x20,%al
801004ff:	75 08                	jne    80100509 <cons_putc+0x3c>
80100501:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
80100507:	7e e8                	jle    801004f1 <cons_putc+0x24>
    outb(COM1 + COM_TX, c);
80100509:	89 f8                	mov    %edi,%eax
8010050b:	88 45 e7             	mov    %al,-0x19(%ebp)
    asm volatile("outb %0,%w1"
8010050e:	ba f8 03 00 00       	mov    $0x3f8,%edx
80100513:	ee                   	out    %al,(%dx)
    asm volatile("inb %w1,%0"
80100514:	ba 79 03 00 00       	mov    $0x379,%edx
80100519:	ec                   	in     (%dx),%al
    for (i = 0; !(inb(0x378 + 1) & 0x80) && i < 12800; i++)
8010051a:	84 c0                	test   %al,%al
8010051c:	78 27                	js     80100545 <cons_putc+0x78>
8010051e:	bb 00 00 00 00       	mov    $0x0,%ebx
80100523:	b9 84 00 00 00       	mov    $0x84,%ecx
80100528:	be 79 03 00 00       	mov    $0x379,%esi
8010052d:	89 ca                	mov    %ecx,%edx
8010052f:	ec                   	in     (%dx),%al
80100530:	ec                   	in     (%dx),%al
80100531:	ec                   	in     (%dx),%al
80100532:	ec                   	in     (%dx),%al
80100533:	83 c3 01             	add    $0x1,%ebx
80100536:	89 f2                	mov    %esi,%edx
80100538:	ec                   	in     (%dx),%al
80100539:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
8010053f:	7f 04                	jg     80100545 <cons_putc+0x78>
80100541:	84 c0                	test   %al,%al
80100543:	79 e8                	jns    8010052d <cons_putc+0x60>
    asm volatile("outb %0,%w1"
80100545:	ba 78 03 00 00       	mov    $0x378,%edx
8010054a:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
8010054e:	ee                   	out    %al,(%dx)
8010054f:	ba 7a 03 00 00       	mov    $0x37a,%edx
80100554:	b8 0d 00 00 00       	mov    $0xd,%eax
80100559:	ee                   	out    %al,(%dx)
8010055a:	b8 08 00 00 00       	mov    $0x8,%eax
8010055f:	ee                   	out    %al,(%dx)
        c |= 0x0700;
80100560:	89 f8                	mov    %edi,%eax
80100562:	80 cc 07             	or     $0x7,%ah
80100565:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
8010056b:	0f 44 f8             	cmove  %eax,%edi
    switch (c & 0xff) {
8010056e:	89 f8                	mov    %edi,%eax
80100570:	0f b6 c0             	movzbl %al,%eax
80100573:	89 fb                	mov    %edi,%ebx
80100575:	80 fb 0a             	cmp    $0xa,%bl
80100578:	0f 84 e4 00 00 00    	je     80100662 <cons_putc+0x195>
8010057e:	83 f8 0a             	cmp    $0xa,%eax
80100581:	7f 46                	jg     801005c9 <cons_putc+0xfc>
80100583:	83 f8 08             	cmp    $0x8,%eax
80100586:	0f 84 aa 00 00 00    	je     80100636 <cons_putc+0x169>
8010058c:	83 f8 09             	cmp    $0x9,%eax
8010058f:	0f 85 da 00 00 00    	jne    8010066f <cons_putc+0x1a2>
        cons_putc(' ');
80100595:	b8 20 00 00 00       	mov    $0x20,%eax
8010059a:	e8 2e ff ff ff       	call   801004cd <cons_putc>
        cons_putc(' ');
8010059f:	b8 20 00 00 00       	mov    $0x20,%eax
801005a4:	e8 24 ff ff ff       	call   801004cd <cons_putc>
        cons_putc(' ');
801005a9:	b8 20 00 00 00       	mov    $0x20,%eax
801005ae:	e8 1a ff ff ff       	call   801004cd <cons_putc>
        cons_putc(' ');
801005b3:	b8 20 00 00 00       	mov    $0x20,%eax
801005b8:	e8 10 ff ff ff       	call   801004cd <cons_putc>
        cons_putc(' ');
801005bd:	b8 20 00 00 00       	mov    $0x20,%eax
801005c2:	e8 06 ff ff ff       	call   801004cd <cons_putc>
        break;
801005c7:	eb 25                	jmp    801005ee <cons_putc+0x121>
    switch (c & 0xff) {
801005c9:	83 f8 0d             	cmp    $0xd,%eax
801005cc:	0f 85 9d 00 00 00    	jne    8010066f <cons_putc+0x1a2>
        crt_pos -= (crt_pos % CRT_COLS);
801005d2:	0f b7 05 48 25 10 80 	movzwl 0x80102548,%eax
801005d9:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
801005df:	c1 e8 16             	shr    $0x16,%eax
801005e2:	8d 04 80             	lea    (%eax,%eax,4),%eax
801005e5:	c1 e0 04             	shl    $0x4,%eax
801005e8:	66 a3 48 25 10 80    	mov    %ax,0x80102548
    if (crt_pos >= CRT_SIZE) // 当输出字符超过终端范围
801005ee:	0f b7 1d 48 25 10 80 	movzwl 0x80102548,%ebx
801005f5:	66 81 fb cf 07       	cmp    $0x7cf,%bx
801005fa:	0f 87 92 00 00 00    	ja     80100692 <cons_putc+0x1c5>
    outb(addr_6845, 14);
80100600:	8b 0d 50 25 10 80    	mov    0x80102550,%ecx
80100606:	b8 0e 00 00 00       	mov    $0xe,%eax
8010060b:	89 ca                	mov    %ecx,%edx
8010060d:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos >> 8);
8010060e:	0f b7 1d 48 25 10 80 	movzwl 0x80102548,%ebx
80100615:	8d 71 01             	lea    0x1(%ecx),%esi
80100618:	89 d8                	mov    %ebx,%eax
8010061a:	66 c1 e8 08          	shr    $0x8,%ax
8010061e:	89 f2                	mov    %esi,%edx
80100620:	ee                   	out    %al,(%dx)
80100621:	b8 0f 00 00 00       	mov    $0xf,%eax
80100626:	89 ca                	mov    %ecx,%edx
80100628:	ee                   	out    %al,(%dx)
80100629:	89 d8                	mov    %ebx,%eax
8010062b:	89 f2                	mov    %esi,%edx
8010062d:	ee                   	out    %al,(%dx)
    serial_putc(c); // 向串口输出
    lpt_putc(c);
    cga_putc(c); // 向控制台输出字符
}
8010062e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100631:	5b                   	pop    %ebx
80100632:	5e                   	pop    %esi
80100633:	5f                   	pop    %edi
80100634:	5d                   	pop    %ebp
80100635:	c3                   	ret    
        if (crt_pos > 0) {
80100636:	0f b7 05 48 25 10 80 	movzwl 0x80102548,%eax
8010063d:	66 85 c0             	test   %ax,%ax
80100640:	74 be                	je     80100600 <cons_putc+0x133>
            crt_pos--;
80100642:	83 e8 01             	sub    $0x1,%eax
80100645:	66 a3 48 25 10 80    	mov    %ax,0x80102548
            crt_buf[crt_pos] = (c & ~0xff) | ' ';
8010064b:	0f b7 c0             	movzwl %ax,%eax
8010064e:	66 81 e7 00 ff       	and    $0xff00,%di
80100653:	83 cf 20             	or     $0x20,%edi
80100656:	8b 15 4c 25 10 80    	mov    0x8010254c,%edx
8010065c:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
80100660:	eb 8c                	jmp    801005ee <cons_putc+0x121>
        crt_pos += CRT_COLS;
80100662:	66 83 05 48 25 10 80 	addw   $0x50,0x80102548
80100669:	50 
8010066a:	e9 63 ff ff ff       	jmp    801005d2 <cons_putc+0x105>
        crt_buf[crt_pos++] = c; /* write the character */
8010066f:	0f b7 05 48 25 10 80 	movzwl 0x80102548,%eax
80100676:	8d 50 01             	lea    0x1(%eax),%edx
80100679:	66 89 15 48 25 10 80 	mov    %dx,0x80102548
80100680:	0f b7 c0             	movzwl %ax,%eax
80100683:	8b 15 4c 25 10 80    	mov    0x8010254c,%edx
80100689:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
        break;
8010068d:	e9 5c ff ff ff       	jmp    801005ee <cons_putc+0x121>
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t)); // 已有字符往上移动一行
80100692:	8b 35 4c 25 10 80    	mov    0x8010254c,%esi
80100698:	83 ec 04             	sub    $0x4,%esp
8010069b:	68 00 0f 00 00       	push   $0xf00
801006a0:	8d 86 a0 00 00 00    	lea    0xa0(%esi),%eax
801006a6:	50                   	push   %eax
801006a7:	56                   	push   %esi
801006a8:	e8 cf fd ff ff       	call   8010047c <memmove>
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++) // 清零最后一行
801006ad:	8d 86 00 0f 00 00    	lea    0xf00(%esi),%eax
801006b3:	8d 96 a0 0f 00 00    	lea    0xfa0(%esi),%edx
801006b9:	83 c4 10             	add    $0x10,%esp
            crt_buf[i] = 0x0700 | ' ';
801006bc:	66 c7 00 20 07       	movw   $0x720,(%eax)
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++) // 清零最后一行
801006c1:	83 c0 02             	add    $0x2,%eax
801006c4:	39 d0                	cmp    %edx,%eax
801006c6:	75 f4                	jne    801006bc <cons_putc+0x1ef>
        crt_pos -= CRT_COLS; // 索引向前移动，即从最后一行的开头写入
801006c8:	83 eb 50             	sub    $0x50,%ebx
801006cb:	66 89 1d 48 25 10 80 	mov    %bx,0x80102548
801006d2:	e9 29 ff ff ff       	jmp    80100600 <cons_putc+0x133>

801006d7 <printint>:
    return 1;
}

static void
printint(int xx, int base, int sign)
{
801006d7:	55                   	push   %ebp
801006d8:	89 e5                	mov    %esp,%ebp
801006da:	57                   	push   %edi
801006db:	56                   	push   %esi
801006dc:	53                   	push   %ebx
801006dd:	83 ec 2c             	sub    $0x2c,%esp
801006e0:	89 d6                	mov    %edx,%esi
    static char digits[] = "0123456789abcdef";
    char buf[16];
    int i;
    uint32_t x;

    if (sign && (sign = xx < 0))
801006e2:	85 c9                	test   %ecx,%ecx
801006e4:	74 04                	je     801006ea <printint+0x13>
801006e6:	85 c0                	test   %eax,%eax
801006e8:	78 61                	js     8010074b <printint+0x74>
        x = -xx;
    else
        x = xx;
801006ea:	89 c1                	mov    %eax,%ecx
801006ec:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

    i = 0;
801006f3:	bb 00 00 00 00       	mov    $0x0,%ebx
    do {
        buf[i++] = digits[x % base];
801006f8:	89 df                	mov    %ebx,%edi
801006fa:	83 c3 01             	add    $0x1,%ebx
801006fd:	89 c8                	mov    %ecx,%eax
801006ff:	ba 00 00 00 00       	mov    $0x0,%edx
80100704:	f7 f6                	div    %esi
80100706:	0f b6 92 20 0d 10 80 	movzbl -0x7feff2e0(%edx),%edx
8010070d:	88 54 1d d7          	mov    %dl,-0x29(%ebp,%ebx,1)
    } while ((x /= base) != 0);
80100711:	89 ca                	mov    %ecx,%edx
80100713:	89 c1                	mov    %eax,%ecx
80100715:	39 d6                	cmp    %edx,%esi
80100717:	76 df                	jbe    801006f8 <printint+0x21>

    if (sign)
80100719:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
8010071d:	74 08                	je     80100727 <printint+0x50>
        buf[i++] = '-';
8010071f:	c6 44 1d d8 2d       	movb   $0x2d,-0x28(%ebp,%ebx,1)
80100724:	8d 5f 02             	lea    0x2(%edi),%ebx

    while (--i >= 0)
80100727:	85 db                	test   %ebx,%ebx
80100729:	7e 18                	jle    80100743 <printint+0x6c>
8010072b:	8d 75 d8             	lea    -0x28(%ebp),%esi
8010072e:	8d 5c 1d d7          	lea    -0x29(%ebp,%ebx,1),%ebx
        cons_putc(buf[i]);
80100732:	0f be 03             	movsbl (%ebx),%eax
80100735:	e8 93 fd ff ff       	call   801004cd <cons_putc>
    while (--i >= 0)
8010073a:	89 d8                	mov    %ebx,%eax
8010073c:	83 eb 01             	sub    $0x1,%ebx
8010073f:	39 f0                	cmp    %esi,%eax
80100741:	75 ef                	jne    80100732 <printint+0x5b>
}
80100743:	83 c4 2c             	add    $0x2c,%esp
80100746:	5b                   	pop    %ebx
80100747:	5e                   	pop    %esi
80100748:	5f                   	pop    %edi
80100749:	5d                   	pop    %ebp
8010074a:	c3                   	ret    
        x = -xx;
8010074b:	f7 d8                	neg    %eax
8010074d:	89 c1                	mov    %eax,%ecx
    if (sign && (sign = xx < 0))
8010074f:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
        x = -xx;
80100756:	eb 9b                	jmp    801006f3 <printint+0x1c>

80100758 <memcpy>:
{
80100758:	55                   	push   %ebp
80100759:	89 e5                	mov    %esp,%ebp
8010075b:	83 ec 0c             	sub    $0xc,%esp
    return memmove(dst, src, n);
8010075e:	ff 75 10             	push   0x10(%ebp)
80100761:	ff 75 0c             	push   0xc(%ebp)
80100764:	ff 75 08             	push   0x8(%ebp)
80100767:	e8 10 fd ff ff       	call   8010047c <memmove>
}
8010076c:	c9                   	leave  
8010076d:	c3                   	ret    

8010076e <strncmp>:
{
8010076e:	55                   	push   %ebp
8010076f:	89 e5                	mov    %esp,%ebp
80100771:	53                   	push   %ebx
80100772:	8b 55 08             	mov    0x8(%ebp),%edx
80100775:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80100778:	8b 45 10             	mov    0x10(%ebp),%eax
    while (n > 0 && *p && *p == *q)
8010077b:	85 c0                	test   %eax,%eax
8010077d:	74 29                	je     801007a8 <strncmp+0x3a>
8010077f:	0f b6 1a             	movzbl (%edx),%ebx
80100782:	84 db                	test   %bl,%bl
80100784:	74 16                	je     8010079c <strncmp+0x2e>
80100786:	3a 19                	cmp    (%ecx),%bl
80100788:	75 12                	jne    8010079c <strncmp+0x2e>
        n--, p++, q++;
8010078a:	83 c2 01             	add    $0x1,%edx
8010078d:	83 c1 01             	add    $0x1,%ecx
    while (n > 0 && *p && *p == *q)
80100790:	83 e8 01             	sub    $0x1,%eax
80100793:	75 ea                	jne    8010077f <strncmp+0x11>
        return 0;
80100795:	b8 00 00 00 00       	mov    $0x0,%eax
8010079a:	eb 0c                	jmp    801007a8 <strncmp+0x3a>
    if (n == 0)
8010079c:	85 c0                	test   %eax,%eax
8010079e:	74 0d                	je     801007ad <strncmp+0x3f>
    return (uint8_t)*p - (uint8_t)*q;
801007a0:	0f b6 02             	movzbl (%edx),%eax
801007a3:	0f b6 11             	movzbl (%ecx),%edx
801007a6:	29 d0                	sub    %edx,%eax
}
801007a8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801007ab:	c9                   	leave  
801007ac:	c3                   	ret    
        return 0;
801007ad:	b8 00 00 00 00       	mov    $0x0,%eax
801007b2:	eb f4                	jmp    801007a8 <strncmp+0x3a>

801007b4 <strncpy>:
{
801007b4:	55                   	push   %ebp
801007b5:	89 e5                	mov    %esp,%ebp
801007b7:	57                   	push   %edi
801007b8:	56                   	push   %esi
801007b9:	53                   	push   %ebx
801007ba:	8b 75 08             	mov    0x8(%ebp),%esi
801007bd:	8b 4d 10             	mov    0x10(%ebp),%ecx
    while (n-- > 0 && (*s++ = *t++) != 0)
801007c0:	89 f0                	mov    %esi,%eax
801007c2:	89 cb                	mov    %ecx,%ebx
801007c4:	83 e9 01             	sub    $0x1,%ecx
801007c7:	85 db                	test   %ebx,%ebx
801007c9:	7e 17                	jle    801007e2 <strncpy+0x2e>
801007cb:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
801007cf:	83 c0 01             	add    $0x1,%eax
801007d2:	8b 7d 0c             	mov    0xc(%ebp),%edi
801007d5:	0f b6 7f ff          	movzbl -0x1(%edi),%edi
801007d9:	89 fa                	mov    %edi,%edx
801007db:	88 50 ff             	mov    %dl,-0x1(%eax)
801007de:	84 d2                	test   %dl,%dl
801007e0:	75 e0                	jne    801007c2 <strncpy+0xe>
    while (n-- > 0)
801007e2:	89 c2                	mov    %eax,%edx
801007e4:	85 c9                	test   %ecx,%ecx
801007e6:	7e 13                	jle    801007fb <strncpy+0x47>
        *s++ = 0;
801007e8:	83 c2 01             	add    $0x1,%edx
801007eb:	c6 42 ff 00          	movb   $0x0,-0x1(%edx)
    while (n-- > 0)
801007ef:	89 d9                	mov    %ebx,%ecx
801007f1:	29 d1                	sub    %edx,%ecx
801007f3:	8d 4c 08 ff          	lea    -0x1(%eax,%ecx,1),%ecx
801007f7:	85 c9                	test   %ecx,%ecx
801007f9:	7f ed                	jg     801007e8 <strncpy+0x34>
}
801007fb:	89 f0                	mov    %esi,%eax
801007fd:	5b                   	pop    %ebx
801007fe:	5e                   	pop    %esi
801007ff:	5f                   	pop    %edi
80100800:	5d                   	pop    %ebp
80100801:	c3                   	ret    

80100802 <safestrcpy>:
{
80100802:	55                   	push   %ebp
80100803:	89 e5                	mov    %esp,%ebp
80100805:	56                   	push   %esi
80100806:	53                   	push   %ebx
80100807:	8b 75 08             	mov    0x8(%ebp),%esi
8010080a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010080d:	8b 55 10             	mov    0x10(%ebp),%edx
    if (n <= 0)
80100810:	85 d2                	test   %edx,%edx
80100812:	7e 1e                	jle    80100832 <safestrcpy+0x30>
80100814:	8d 5c 10 ff          	lea    -0x1(%eax,%edx,1),%ebx
80100818:	89 f2                	mov    %esi,%edx
    while (--n > 0 && (*s++ = *t++) != 0)
8010081a:	39 d8                	cmp    %ebx,%eax
8010081c:	74 11                	je     8010082f <safestrcpy+0x2d>
8010081e:	83 c0 01             	add    $0x1,%eax
80100821:	83 c2 01             	add    $0x1,%edx
80100824:	0f b6 48 ff          	movzbl -0x1(%eax),%ecx
80100828:	88 4a ff             	mov    %cl,-0x1(%edx)
8010082b:	84 c9                	test   %cl,%cl
8010082d:	75 eb                	jne    8010081a <safestrcpy+0x18>
    *s = 0;
8010082f:	c6 02 00             	movb   $0x0,(%edx)
}
80100832:	89 f0                	mov    %esi,%eax
80100834:	5b                   	pop    %ebx
80100835:	5e                   	pop    %esi
80100836:	5d                   	pop    %ebp
80100837:	c3                   	ret    

80100838 <strlen>:
{
80100838:	55                   	push   %ebp
80100839:	89 e5                	mov    %esp,%ebp
8010083b:	8b 55 08             	mov    0x8(%ebp),%edx
    for (n = 0; s[n]; n++)
8010083e:	80 3a 00             	cmpb   $0x0,(%edx)
80100841:	74 10                	je     80100853 <strlen+0x1b>
80100843:	b8 00 00 00 00       	mov    $0x0,%eax
80100848:	83 c0 01             	add    $0x1,%eax
8010084b:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
8010084f:	75 f7                	jne    80100848 <strlen+0x10>
}
80100851:	5d                   	pop    %ebp
80100852:	c3                   	ret    
    for (n = 0; s[n]; n++)
80100853:	b8 00 00 00 00       	mov    $0x0,%eax
    return n;
80100858:	eb f7                	jmp    80100851 <strlen+0x19>

8010085a <serial_intr>:
    if (serial_exists)
8010085a:	80 3d 54 25 10 80 00 	cmpb   $0x0,0x80102554
80100861:	75 01                	jne    80100864 <serial_intr+0xa>
80100863:	c3                   	ret    
{
80100864:	55                   	push   %ebp
80100865:	89 e5                	mov    %esp,%ebp
80100867:	83 ec 08             	sub    $0x8,%esp
        cons_intr(serial_proc_data);
8010086a:	b8 9d 03 10 80       	mov    $0x8010039d,%eax
8010086f:	e8 43 fb ff ff       	call   801003b7 <cons_intr>
}
80100874:	c9                   	leave  
80100875:	c3                   	ret    

80100876 <kbd_intr>:
{
80100876:	55                   	push   %ebp
80100877:	89 e5                	mov    %esp,%ebp
80100879:	83 ec 08             	sub    $0x8,%esp
    cons_intr(kbd_proc_data);
8010087c:	b8 0c 0a 10 80       	mov    $0x80100a0c,%eax
80100881:	e8 31 fb ff ff       	call   801003b7 <cons_intr>
}
80100886:	c9                   	leave  
80100887:	c3                   	ret    

80100888 <cons_getc>:
{
80100888:	55                   	push   %ebp
80100889:	89 e5                	mov    %esp,%ebp
8010088b:	83 ec 08             	sub    $0x8,%esp
    serial_intr();
8010088e:	e8 c7 ff ff ff       	call   8010085a <serial_intr>
    kbd_intr();
80100893:	e8 de ff ff ff       	call   80100876 <kbd_intr>
    if (cons.rpos != cons.wpos) {
80100898:	a1 40 25 10 80       	mov    0x80102540,%eax
    return 0;
8010089d:	ba 00 00 00 00       	mov    $0x0,%edx
    if (cons.rpos != cons.wpos) {
801008a2:	3b 05 44 25 10 80    	cmp    0x80102544,%eax
801008a8:	74 1c                	je     801008c6 <cons_getc+0x3e>
        c = cons.buf[cons.rpos++];
801008aa:	8d 48 01             	lea    0x1(%eax),%ecx
801008ad:	0f b6 90 40 23 10 80 	movzbl -0x7fefdcc0(%eax),%edx
            cons.rpos = 0;
801008b4:	3d ff 01 00 00       	cmp    $0x1ff,%eax
801008b9:	b8 00 00 00 00       	mov    $0x0,%eax
801008be:	0f 45 c1             	cmovne %ecx,%eax
801008c1:	a3 40 25 10 80       	mov    %eax,0x80102540
}
801008c6:	89 d0                	mov    %edx,%eax
801008c8:	c9                   	leave  
801008c9:	c3                   	ret    

801008ca <cputchar>:
{
801008ca:	55                   	push   %ebp
801008cb:	89 e5                	mov    %esp,%ebp
801008cd:	83 ec 08             	sub    $0x8,%esp
    cons_putc(c);
801008d0:	8b 45 08             	mov    0x8(%ebp),%eax
801008d3:	e8 f5 fb ff ff       	call   801004cd <cons_putc>
}
801008d8:	c9                   	leave  
801008d9:	c3                   	ret    

801008da <getchar>:
{
801008da:	55                   	push   %ebp
801008db:	89 e5                	mov    %esp,%ebp
801008dd:	83 ec 08             	sub    $0x8,%esp
    while ((c = cons_getc()) == 0)
801008e0:	e8 a3 ff ff ff       	call   80100888 <cons_getc>
801008e5:	85 c0                	test   %eax,%eax
801008e7:	74 f7                	je     801008e0 <getchar+0x6>
}
801008e9:	c9                   	leave  
801008ea:	c3                   	ret    

801008eb <iscons>:
}
801008eb:	b8 01 00 00 00       	mov    $0x1,%eax
801008f0:	c3                   	ret    

801008f1 <cprintf>:

void cprintf(char* fmt, ...)
{
801008f1:	55                   	push   %ebp
801008f2:	89 e5                	mov    %esp,%ebp
801008f4:	57                   	push   %edi
801008f5:	56                   	push   %esi
801008f6:	53                   	push   %ebx
801008f7:	83 ec 1c             	sub    $0x1c,%esp

    // if (fmt == 0)
    //     panic("null fmt");

    argp = (uint32_t*)(void*)(&fmt + 1);
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++) {
801008fa:	8b 7d 08             	mov    0x8(%ebp),%edi
801008fd:	0f b6 07             	movzbl (%edi),%eax
80100900:	85 c0                	test   %eax,%eax
80100902:	0f 84 fc 00 00 00    	je     80100a04 <cprintf+0x113>
    argp = (uint32_t*)(void*)(&fmt + 1);
80100908:	8d 4d 0c             	lea    0xc(%ebp),%ecx
8010090b:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++) {
8010090e:	bb 00 00 00 00       	mov    $0x0,%ebx
80100913:	eb 14                	jmp    80100929 <cprintf+0x38>
        if (c != '%') {
            cons_putc(c);
80100915:	e8 b3 fb ff ff       	call   801004cd <cons_putc>
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++) {
8010091a:	83 c3 01             	add    $0x1,%ebx
8010091d:	0f b6 04 1f          	movzbl (%edi,%ebx,1),%eax
80100921:	85 c0                	test   %eax,%eax
80100923:	0f 84 db 00 00 00    	je     80100a04 <cprintf+0x113>
        if (c != '%') {
80100929:	83 f8 25             	cmp    $0x25,%eax
8010092c:	75 e7                	jne    80100915 <cprintf+0x24>
            continue;
        }
        c = fmt[++i] & 0xff;
8010092e:	83 c3 01             	add    $0x1,%ebx
80100931:	0f b6 34 1f          	movzbl (%edi,%ebx,1),%esi
        if (c == 0)
80100935:	85 f6                	test   %esi,%esi
80100937:	0f 84 c7 00 00 00    	je     80100a04 <cprintf+0x113>
            break;
        switch (c) {
8010093d:	83 fe 70             	cmp    $0x70,%esi
80100940:	74 3a                	je     8010097c <cprintf+0x8b>
80100942:	7f 2e                	jg     80100972 <cprintf+0x81>
80100944:	83 fe 25             	cmp    $0x25,%esi
80100947:	0f 84 92 00 00 00    	je     801009df <cprintf+0xee>
8010094d:	83 fe 64             	cmp    $0x64,%esi
80100950:	0f 85 98 00 00 00    	jne    801009ee <cprintf+0xfd>
        case 'd':
            printint(*argp++, 10, 1);
80100956:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100959:	8d 70 04             	lea    0x4(%eax),%esi
8010095c:	b9 01 00 00 00       	mov    $0x1,%ecx
80100961:	ba 0a 00 00 00       	mov    $0xa,%edx
80100966:	8b 00                	mov    (%eax),%eax
80100968:	e8 6a fd ff ff       	call   801006d7 <printint>
8010096d:	89 75 e4             	mov    %esi,-0x1c(%ebp)
            break;
80100970:	eb a8                	jmp    8010091a <cprintf+0x29>
        switch (c) {
80100972:	83 fe 73             	cmp    $0x73,%esi
80100975:	74 21                	je     80100998 <cprintf+0xa7>
80100977:	83 fe 78             	cmp    $0x78,%esi
8010097a:	75 72                	jne    801009ee <cprintf+0xfd>
        case 'x':
        case 'p':
            printint(*argp++, 16, 0);
8010097c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010097f:	8d 70 04             	lea    0x4(%eax),%esi
80100982:	b9 00 00 00 00       	mov    $0x0,%ecx
80100987:	ba 10 00 00 00       	mov    $0x10,%edx
8010098c:	8b 00                	mov    (%eax),%eax
8010098e:	e8 44 fd ff ff       	call   801006d7 <printint>
80100993:	89 75 e4             	mov    %esi,-0x1c(%ebp)
            break;
80100996:	eb 82                	jmp    8010091a <cprintf+0x29>
        case 's':
            if ((s = (char*)*argp++) == 0)
80100998:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010099b:	8d 50 04             	lea    0x4(%eax),%edx
8010099e:	89 55 e0             	mov    %edx,-0x20(%ebp)
801009a1:	8b 00                	mov    (%eax),%eax
801009a3:	85 c0                	test   %eax,%eax
801009a5:	74 11                	je     801009b8 <cprintf+0xc7>
801009a7:	89 c6                	mov    %eax,%esi
                s = "(null)";
            for (; *s; s++)
801009a9:	0f b6 00             	movzbl (%eax),%eax
            if ((s = (char*)*argp++) == 0)
801009ac:	89 55 e4             	mov    %edx,-0x1c(%ebp)
            for (; *s; s++)
801009af:	84 c0                	test   %al,%al
801009b1:	75 0f                	jne    801009c2 <cprintf+0xd1>
801009b3:	e9 62 ff ff ff       	jmp    8010091a <cprintf+0x29>
                s = "(null)";
801009b8:	be d6 0c 10 80       	mov    $0x80100cd6,%esi
            for (; *s; s++)
801009bd:	b8 28 00 00 00       	mov    $0x28,%eax
                cons_putc(*s);
801009c2:	0f be c0             	movsbl %al,%eax
801009c5:	e8 03 fb ff ff       	call   801004cd <cons_putc>
            for (; *s; s++)
801009ca:	83 c6 01             	add    $0x1,%esi
801009cd:	0f b6 06             	movzbl (%esi),%eax
801009d0:	84 c0                	test   %al,%al
801009d2:	75 ee                	jne    801009c2 <cprintf+0xd1>
            if ((s = (char*)*argp++) == 0)
801009d4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801009d7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801009da:	e9 3b ff ff ff       	jmp    8010091a <cprintf+0x29>
            break;
        case '%':
            cons_putc('%');
801009df:	b8 25 00 00 00       	mov    $0x25,%eax
801009e4:	e8 e4 fa ff ff       	call   801004cd <cons_putc>
            break;
801009e9:	e9 2c ff ff ff       	jmp    8010091a <cprintf+0x29>
        default:
            // Print unknown % sequence to draw attention.
            cons_putc('%');
801009ee:	b8 25 00 00 00       	mov    $0x25,%eax
801009f3:	e8 d5 fa ff ff       	call   801004cd <cons_putc>
            cons_putc(c);
801009f8:	89 f0                	mov    %esi,%eax
801009fa:	e8 ce fa ff ff       	call   801004cd <cons_putc>
            break;
801009ff:	e9 16 ff ff ff       	jmp    8010091a <cprintf+0x29>
        }
    }

    // if (locking)
    //     release(&cons.lock);
}
80100a04:	83 c4 1c             	add    $0x1c,%esp
80100a07:	5b                   	pop    %ebx
80100a08:	5e                   	pop    %esi
80100a09:	5f                   	pop    %edi
80100a0a:	5d                   	pop    %ebp
80100a0b:	c3                   	ret    

80100a0c <kbd_proc_data>:
{
80100a0c:	55                   	push   %ebp
80100a0d:	89 e5                	mov    %esp,%ebp
80100a0f:	53                   	push   %ebx
80100a10:	83 ec 04             	sub    $0x4,%esp
    asm volatile("inb %w1,%0"
80100a13:	ba 64 00 00 00       	mov    $0x64,%edx
80100a18:	ec                   	in     (%dx),%al
    if ((stat & KBS_DIB) == 0)
80100a19:	a8 01                	test   $0x1,%al
80100a1b:	0f 84 ee 00 00 00    	je     80100b0f <kbd_proc_data+0x103>
    if (stat & KBS_TERR)
80100a21:	a8 20                	test   $0x20,%al
80100a23:	0f 85 ed 00 00 00    	jne    80100b16 <kbd_proc_data+0x10a>
80100a29:	ba 60 00 00 00       	mov    $0x60,%edx
80100a2e:	ec                   	in     (%dx),%al
80100a2f:	89 c2                	mov    %eax,%edx
    if (data == 0xE0) {
80100a31:	3c e0                	cmp    $0xe0,%al
80100a33:	74 61                	je     80100a96 <kbd_proc_data+0x8a>
    } else if (data & 0x80) {
80100a35:	84 c0                	test   %al,%al
80100a37:	78 70                	js     80100aa9 <kbd_proc_data+0x9d>
    } else if (shift & E0ESC) {
80100a39:	8b 0d 20 23 10 80    	mov    0x80102320,%ecx
80100a3f:	f6 c1 40             	test   $0x40,%cl
80100a42:	74 0e                	je     80100a52 <kbd_proc_data+0x46>
        data |= 0x80;
80100a44:	83 c8 80             	or     $0xffffff80,%eax
80100a47:	89 c2                	mov    %eax,%edx
        shift &= ~E0ESC;
80100a49:	83 e1 bf             	and    $0xffffffbf,%ecx
80100a4c:	89 0d 20 23 10 80    	mov    %ecx,0x80102320
    shift |= shiftcode[data];
80100a52:	0f b6 d2             	movzbl %dl,%edx
80100a55:	0f b6 82 60 0e 10 80 	movzbl -0x7feff1a0(%edx),%eax
80100a5c:	0b 05 20 23 10 80    	or     0x80102320,%eax
    shift ^= togglecode[data];
80100a62:	0f b6 8a 60 0d 10 80 	movzbl -0x7feff2a0(%edx),%ecx
80100a69:	31 c8                	xor    %ecx,%eax
80100a6b:	a3 20 23 10 80       	mov    %eax,0x80102320
    c = charcode[shift & (CTL | SHIFT)][data];
80100a70:	89 c1                	mov    %eax,%ecx
80100a72:	83 e1 03             	and    $0x3,%ecx
80100a75:	8b 0c 8d 34 0d 10 80 	mov    -0x7feff2cc(,%ecx,4),%ecx
80100a7c:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
80100a80:	0f b6 da             	movzbl %dl,%ebx
    if (shift & CAPSLOCK) {
80100a83:	a8 08                	test   $0x8,%al
80100a85:	74 5d                	je     80100ae4 <kbd_proc_data+0xd8>
        if ('a' <= c && c <= 'z')
80100a87:	89 da                	mov    %ebx,%edx
80100a89:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
80100a8c:	83 f9 19             	cmp    $0x19,%ecx
80100a8f:	77 47                	ja     80100ad8 <kbd_proc_data+0xcc>
            c += 'A' - 'a';
80100a91:	83 eb 20             	sub    $0x20,%ebx
    if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
80100a94:	eb 0c                	jmp    80100aa2 <kbd_proc_data+0x96>
        shift |= E0ESC;
80100a96:	83 0d 20 23 10 80 40 	orl    $0x40,0x80102320
        return 0;
80100a9d:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80100aa2:	89 d8                	mov    %ebx,%eax
80100aa4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100aa7:	c9                   	leave  
80100aa8:	c3                   	ret    
        data = (shift & E0ESC ? data : data & 0x7F);
80100aa9:	8b 0d 20 23 10 80    	mov    0x80102320,%ecx
80100aaf:	83 e0 7f             	and    $0x7f,%eax
80100ab2:	f6 c1 40             	test   $0x40,%cl
80100ab5:	0f 44 d0             	cmove  %eax,%edx
        shift &= ~(shiftcode[data] | E0ESC);
80100ab8:	0f b6 d2             	movzbl %dl,%edx
80100abb:	0f b6 82 60 0e 10 80 	movzbl -0x7feff1a0(%edx),%eax
80100ac2:	83 c8 40             	or     $0x40,%eax
80100ac5:	0f b6 c0             	movzbl %al,%eax
80100ac8:	f7 d0                	not    %eax
80100aca:	21 c8                	and    %ecx,%eax
80100acc:	a3 20 23 10 80       	mov    %eax,0x80102320
        return 0;
80100ad1:	bb 00 00 00 00       	mov    $0x0,%ebx
80100ad6:	eb ca                	jmp    80100aa2 <kbd_proc_data+0x96>
        else if ('A' <= c && c <= 'Z')
80100ad8:	83 ea 41             	sub    $0x41,%edx
            c += 'a' - 'A';
80100adb:	8d 4b 20             	lea    0x20(%ebx),%ecx
80100ade:	83 fa 1a             	cmp    $0x1a,%edx
80100ae1:	0f 42 d9             	cmovb  %ecx,%ebx
    if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
80100ae4:	f7 d0                	not    %eax
80100ae6:	a8 06                	test   $0x6,%al
80100ae8:	75 b8                	jne    80100aa2 <kbd_proc_data+0x96>
80100aea:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
80100af0:	75 b0                	jne    80100aa2 <kbd_proc_data+0x96>
        cprintf("Rebooting!\n");
80100af2:	83 ec 0c             	sub    $0xc,%esp
80100af5:	68 dd 0c 10 80       	push   $0x80100cdd
80100afa:	e8 f2 fd ff ff       	call   801008f1 <cprintf>
    asm volatile("outb %0,%w1"
80100aff:	b8 03 00 00 00       	mov    $0x3,%eax
80100b04:	ba 92 00 00 00       	mov    $0x92,%edx
80100b09:	ee                   	out    %al,(%dx)
}
80100b0a:	83 c4 10             	add    $0x10,%esp
80100b0d:	eb 93                	jmp    80100aa2 <kbd_proc_data+0x96>
        return -1;
80100b0f:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80100b14:	eb 8c                	jmp    80100aa2 <kbd_proc_data+0x96>
        return -1;
80100b16:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80100b1b:	eb 85                	jmp    80100aa2 <kbd_proc_data+0x96>

80100b1d <cons_init>:
{
80100b1d:	55                   	push   %ebp
80100b1e:	89 e5                	mov    %esp,%ebp
80100b20:	57                   	push   %edi
80100b21:	56                   	push   %esi
80100b22:	53                   	push   %ebx
80100b23:	83 ec 0c             	sub    $0xc,%esp
    was = *cp;
80100b26:	0f b7 15 00 80 0b 80 	movzwl 0x800b8000,%edx
    *cp = (uint16_t)0xA55A;
80100b2d:	66 c7 05 00 80 0b 80 	movw   $0xa55a,0x800b8000
80100b34:	5a a5 
    if (*cp != 0xA55A) {
80100b36:	0f b7 05 00 80 0b 80 	movzwl 0x800b8000,%eax
80100b3d:	bb b4 03 00 00       	mov    $0x3b4,%ebx
        cp = (uint16_t*)(K_ADDR_BASE + MONO_BUF);
80100b42:	be 00 00 0b 80       	mov    $0x800b0000,%esi
    if (*cp != 0xA55A) {
80100b47:	66 3d 5a a5          	cmp    $0xa55a,%ax
80100b4b:	0f 84 ab 00 00 00    	je     80100bfc <cons_init+0xdf>
        addr_6845 = MONO_BASE;
80100b51:	89 1d 50 25 10 80    	mov    %ebx,0x80102550
    asm volatile("outb %0,%w1"
80100b57:	b8 0e 00 00 00       	mov    $0xe,%eax
80100b5c:	89 da                	mov    %ebx,%edx
80100b5e:	ee                   	out    %al,(%dx)
    pos = inb(addr_6845 + 1) << 8;
80100b5f:	8d 7b 01             	lea    0x1(%ebx),%edi
    asm volatile("inb %w1,%0"
80100b62:	89 fa                	mov    %edi,%edx
80100b64:	ec                   	in     (%dx),%al
80100b65:	0f b6 c8             	movzbl %al,%ecx
80100b68:	c1 e1 08             	shl    $0x8,%ecx
    asm volatile("outb %0,%w1"
80100b6b:	b8 0f 00 00 00       	mov    $0xf,%eax
80100b70:	89 da                	mov    %ebx,%edx
80100b72:	ee                   	out    %al,(%dx)
    asm volatile("inb %w1,%0"
80100b73:	89 fa                	mov    %edi,%edx
80100b75:	ec                   	in     (%dx),%al
    crt_buf = (uint16_t*)cp;
80100b76:	89 35 4c 25 10 80    	mov    %esi,0x8010254c
    pos |= inb(addr_6845 + 1);
80100b7c:	0f b6 c0             	movzbl %al,%eax
80100b7f:	09 c8                	or     %ecx,%eax
    crt_pos = pos;
80100b81:	66 a3 48 25 10 80    	mov    %ax,0x80102548
    kbd_intr();
80100b87:	e8 ea fc ff ff       	call   80100876 <kbd_intr>
    asm volatile("outb %0,%w1"
80100b8c:	b9 00 00 00 00       	mov    $0x0,%ecx
80100b91:	bb fa 03 00 00       	mov    $0x3fa,%ebx
80100b96:	89 c8                	mov    %ecx,%eax
80100b98:	89 da                	mov    %ebx,%edx
80100b9a:	ee                   	out    %al,(%dx)
80100b9b:	bf fb 03 00 00       	mov    $0x3fb,%edi
80100ba0:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
80100ba5:	89 fa                	mov    %edi,%edx
80100ba7:	ee                   	out    %al,(%dx)
80100ba8:	b8 0c 00 00 00       	mov    $0xc,%eax
80100bad:	ba f8 03 00 00       	mov    $0x3f8,%edx
80100bb2:	ee                   	out    %al,(%dx)
80100bb3:	be f9 03 00 00       	mov    $0x3f9,%esi
80100bb8:	89 c8                	mov    %ecx,%eax
80100bba:	89 f2                	mov    %esi,%edx
80100bbc:	ee                   	out    %al,(%dx)
80100bbd:	b8 03 00 00 00       	mov    $0x3,%eax
80100bc2:	89 fa                	mov    %edi,%edx
80100bc4:	ee                   	out    %al,(%dx)
80100bc5:	ba fc 03 00 00       	mov    $0x3fc,%edx
80100bca:	89 c8                	mov    %ecx,%eax
80100bcc:	ee                   	out    %al,(%dx)
80100bcd:	b8 01 00 00 00       	mov    $0x1,%eax
80100bd2:	89 f2                	mov    %esi,%edx
80100bd4:	ee                   	out    %al,(%dx)
    asm volatile("inb %w1,%0"
80100bd5:	ba fd 03 00 00       	mov    $0x3fd,%edx
80100bda:	ec                   	in     (%dx),%al
80100bdb:	89 c1                	mov    %eax,%ecx
    serial_exists = (inb(COM1 + COM_LSR) != 0xFF);
80100bdd:	3c ff                	cmp    $0xff,%al
80100bdf:	0f 95 05 54 25 10 80 	setne  0x80102554
80100be6:	89 da                	mov    %ebx,%edx
80100be8:	ec                   	in     (%dx),%al
80100be9:	ba f8 03 00 00       	mov    $0x3f8,%edx
80100bee:	ec                   	in     (%dx),%al
    if (!serial_exists)
80100bef:	80 f9 ff             	cmp    $0xff,%cl
80100bf2:	74 1e                	je     80100c12 <cons_init+0xf5>
}
80100bf4:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100bf7:	5b                   	pop    %ebx
80100bf8:	5e                   	pop    %esi
80100bf9:	5f                   	pop    %edi
80100bfa:	5d                   	pop    %ebp
80100bfb:	c3                   	ret    
        *cp = was;
80100bfc:	66 89 15 00 80 0b 80 	mov    %dx,0x800b8000
80100c03:	bb d4 03 00 00       	mov    $0x3d4,%ebx
    cp = (uint16_t*)(K_ADDR_BASE + CGA_BUF);
80100c08:	be 00 80 0b 80       	mov    $0x800b8000,%esi
80100c0d:	e9 3f ff ff ff       	jmp    80100b51 <cons_init+0x34>
        cprintf("Serial port does not exist!\n");
80100c12:	83 ec 0c             	sub    $0xc,%esp
80100c15:	68 e9 0c 10 80       	push   $0x80100ce9
80100c1a:	e8 d2 fc ff ff       	call   801008f1 <cprintf>
80100c1f:	83 c4 10             	add    $0x10,%esp
}
80100c22:	eb d0                	jmp    80100bf4 <cons_init+0xd7>
