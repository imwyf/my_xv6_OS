
kernel:     file format elf32-i386


Disassembly of section .text:

c0100000 <kernel_entry>:
# 我们还没有开启分页，而内核代码实际被存放在物理地址 0x00100000 处，因此手动将虚拟地址转换为其对应的物理地址：即 0x80100000 -> 0x00100000

.globl kernel_entry
kernel_entry:
# 固定页表大小 
  movl    %cr4, %eax
c0100000:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax                  # 4MB/页
c0100003:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
c0100006:	0f 22 e0             	mov    %eax,%cr4
  # 将 entry_pgdir 的物理地址载入 cr3 寄存器并开启分页
  movl    $(V2P_WO(entry_pgdir)), %eax
c0100009:	b8 00 10 10 00       	mov    $0x101000,%eax
  movl    %eax, %cr3
c010000e:	0f 22 d8             	mov    %eax,%cr3
  movl    %cr0, %eax
c0100011:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
c0100014:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
c0100019:	0f 22 c0             	mov    %eax,%cr0

# entrypgdir 直接将虚拟地址前4Mb映射到物理地址前4Mb

# 现在的栈是bootloader设置的不处在内核中，因此把栈设为内核栈
  movl $(stack + KSTACKSIZE), %esp
c010001c:	bc 10 30 10 c0       	mov    $0xc0103010,%esp

# 不能用 call，其使用的是相对寻址，所以 eip 仍然会在低地址处偏移来寻址，而此时 eip 指向的是低的虚拟地址，因此通过 jmp 重置 eip 以指向高地址处
  mov $main, %eax
c0100021:	b8 28 00 10 c0       	mov    $0xc0100028,%eax
  jmp *%eax
c0100026:	ff e0                	jmp    *%eax

c0100028 <main>:
#include "inc/kernel.h"
#include "inc/mmu.h"
#include "inc/types.h"

int main()
{
c0100028:	55                   	push   %ebp
c0100029:	89 e5                	mov    %esp,%ebp
c010002b:	83 e4 f0             	and    $0xfffffff0,%esp
    kmem_init();
c010002e:	e8 49 02 00 00       	call   c010027c <kmem_init>
}
c0100033:	b8 00 00 00 00       	mov    $0x0,%eax
c0100038:	c9                   	leave  
c0100039:	c3                   	ret    

c010003a <memset>:

#include "inc/x86.h"

void* memset(void* dst, int c, uint32_t n)
{
c010003a:	55                   	push   %ebp
c010003b:	89 e5                	mov    %esp,%ebp
c010003d:	57                   	push   %edi
c010003e:	53                   	push   %ebx
c010003f:	8b 55 08             	mov    0x8(%ebp),%edx
c0100042:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100045:	8b 4d 10             	mov    0x10(%ebp),%ecx
    if ((int)dst % 4 == 0 && n % 4 == 0) {
c0100048:	89 d7                	mov    %edx,%edi
c010004a:	09 cf                	or     %ecx,%edi
c010004c:	f7 c7 03 00 00 00    	test   $0x3,%edi
c0100052:	75 1e                	jne    c0100072 <memset+0x38>
        c &= 0xFF;
c0100054:	0f b6 f8             	movzbl %al,%edi
        stosl(dst, (c << 24) | (c << 16) | (c << 8) | c, n / 4);
c0100057:	c1 e9 02             	shr    $0x2,%ecx
c010005a:	c1 e0 18             	shl    $0x18,%eax
c010005d:	89 fb                	mov    %edi,%ebx
c010005f:	c1 e3 10             	shl    $0x10,%ebx
c0100062:	09 d8                	or     %ebx,%eax
c0100064:	09 f8                	or     %edi,%eax
c0100066:	c1 e7 08             	shl    $0x8,%edi
c0100069:	09 f8                	or     %edi,%eax
}

static inline void
stosl(void* addr, int data, int cnt)
{
    asm volatile("cld; rep stosl"
c010006b:	89 d7                	mov    %edx,%edi
c010006d:	fc                   	cld    
c010006e:	f3 ab                	rep stos %eax,%es:(%edi)
                 : "=D"(addr), "=c"(cnt)
                 : "0"(addr), "1"(cnt), "a"(data)
                 : "memory", "cc");
}
c0100070:	eb 05                	jmp    c0100077 <memset+0x3d>
    asm volatile("cld; rep stosb"
c0100072:	89 d7                	mov    %edx,%edi
c0100074:	fc                   	cld    
c0100075:	f3 aa                	rep stos %al,%es:(%edi)
    } else
        stosb(dst, c, n);
    return dst;
}
c0100077:	89 d0                	mov    %edx,%eax
c0100079:	5b                   	pop    %ebx
c010007a:	5f                   	pop    %edi
c010007b:	5d                   	pop    %ebp
c010007c:	c3                   	ret    

c010007d <memcmp>:

int memcmp(const void* v1, const void* v2, uint32_t n)
{
c010007d:	55                   	push   %ebp
c010007e:	89 e5                	mov    %esp,%ebp
c0100080:	56                   	push   %esi
c0100081:	53                   	push   %ebx
c0100082:	8b 45 08             	mov    0x8(%ebp),%eax
c0100085:	8b 55 0c             	mov    0xc(%ebp),%edx
c0100088:	8b 75 10             	mov    0x10(%ebp),%esi
    const uint8_t *s1, *s2;

    s1 = v1;
    s2 = v2;
    while (n-- > 0) {
c010008b:	85 f6                	test   %esi,%esi
c010008d:	74 29                	je     c01000b8 <memcmp+0x3b>
c010008f:	01 c6                	add    %eax,%esi
        if (*s1 != *s2)
c0100091:	0f b6 08             	movzbl (%eax),%ecx
c0100094:	0f b6 1a             	movzbl (%edx),%ebx
c0100097:	38 d9                	cmp    %bl,%cl
c0100099:	75 11                	jne    c01000ac <memcmp+0x2f>
            return *s1 - *s2;
        s1++, s2++;
c010009b:	83 c0 01             	add    $0x1,%eax
c010009e:	83 c2 01             	add    $0x1,%edx
    while (n-- > 0) {
c01000a1:	39 c6                	cmp    %eax,%esi
c01000a3:	75 ec                	jne    c0100091 <memcmp+0x14>
    }

    return 0;
c01000a5:	b8 00 00 00 00       	mov    $0x0,%eax
c01000aa:	eb 08                	jmp    c01000b4 <memcmp+0x37>
            return *s1 - *s2;
c01000ac:	0f b6 c1             	movzbl %cl,%eax
c01000af:	0f b6 db             	movzbl %bl,%ebx
c01000b2:	29 d8                	sub    %ebx,%eax
}
c01000b4:	5b                   	pop    %ebx
c01000b5:	5e                   	pop    %esi
c01000b6:	5d                   	pop    %ebp
c01000b7:	c3                   	ret    
    return 0;
c01000b8:	b8 00 00 00 00       	mov    $0x0,%eax
c01000bd:	eb f5                	jmp    c01000b4 <memcmp+0x37>

c01000bf <memmove>:

void* memmove(void* dst, const void* src, uint32_t n)
{
c01000bf:	55                   	push   %ebp
c01000c0:	89 e5                	mov    %esp,%ebp
c01000c2:	56                   	push   %esi
c01000c3:	53                   	push   %ebx
c01000c4:	8b 75 08             	mov    0x8(%ebp),%esi
c01000c7:	8b 45 0c             	mov    0xc(%ebp),%eax
c01000ca:	8b 4d 10             	mov    0x10(%ebp),%ecx
    const char* s;
    char* d;

    s = src;
    d = dst;
    if (s < d && s + n > d) {
c01000cd:	39 f0                	cmp    %esi,%eax
c01000cf:	72 20                	jb     c01000f1 <memmove+0x32>
        s += n;
        d += n;
        while (n-- > 0)
            *--d = *--s;
    } else
        while (n-- > 0)
c01000d1:	8d 1c 08             	lea    (%eax,%ecx,1),%ebx
c01000d4:	89 f2                	mov    %esi,%edx
c01000d6:	85 c9                	test   %ecx,%ecx
c01000d8:	74 11                	je     c01000eb <memmove+0x2c>
            *d++ = *s++;
c01000da:	83 c0 01             	add    $0x1,%eax
c01000dd:	83 c2 01             	add    $0x1,%edx
c01000e0:	0f b6 48 ff          	movzbl -0x1(%eax),%ecx
c01000e4:	88 4a ff             	mov    %cl,-0x1(%edx)
        while (n-- > 0)
c01000e7:	39 d8                	cmp    %ebx,%eax
c01000e9:	75 ef                	jne    c01000da <memmove+0x1b>

    return dst;
}
c01000eb:	89 f0                	mov    %esi,%eax
c01000ed:	5b                   	pop    %ebx
c01000ee:	5e                   	pop    %esi
c01000ef:	5d                   	pop    %ebp
c01000f0:	c3                   	ret    
    if (s < d && s + n > d) {
c01000f1:	8d 14 08             	lea    (%eax,%ecx,1),%edx
c01000f4:	39 d6                	cmp    %edx,%esi
c01000f6:	73 d9                	jae    c01000d1 <memmove+0x12>
        while (n-- > 0)
c01000f8:	8d 51 ff             	lea    -0x1(%ecx),%edx
c01000fb:	85 c9                	test   %ecx,%ecx
c01000fd:	74 ec                	je     c01000eb <memmove+0x2c>
            *--d = *--s;
c01000ff:	0f b6 0c 10          	movzbl (%eax,%edx,1),%ecx
c0100103:	88 0c 16             	mov    %cl,(%esi,%edx,1)
        while (n-- > 0)
c0100106:	83 ea 01             	sub    $0x1,%edx
c0100109:	83 fa ff             	cmp    $0xffffffff,%edx
c010010c:	75 f1                	jne    c01000ff <memmove+0x40>
c010010e:	eb db                	jmp    c01000eb <memmove+0x2c>

c0100110 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void* memcpy(void* dst, const void* src, uint32_t n)
{
c0100110:	55                   	push   %ebp
c0100111:	89 e5                	mov    %esp,%ebp
c0100113:	83 ec 0c             	sub    $0xc,%esp
    return memmove(dst, src, n);
c0100116:	ff 75 10             	push   0x10(%ebp)
c0100119:	ff 75 0c             	push   0xc(%ebp)
c010011c:	ff 75 08             	push   0x8(%ebp)
c010011f:	e8 9b ff ff ff       	call   c01000bf <memmove>
}
c0100124:	c9                   	leave  
c0100125:	c3                   	ret    

c0100126 <strncmp>:

int strncmp(const char* p, const char* q, uint32_t n)
{
c0100126:	55                   	push   %ebp
c0100127:	89 e5                	mov    %esp,%ebp
c0100129:	53                   	push   %ebx
c010012a:	8b 55 08             	mov    0x8(%ebp),%edx
c010012d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
c0100130:	8b 45 10             	mov    0x10(%ebp),%eax
    while (n > 0 && *p && *p == *q)
c0100133:	85 c0                	test   %eax,%eax
c0100135:	74 29                	je     c0100160 <strncmp+0x3a>
c0100137:	0f b6 1a             	movzbl (%edx),%ebx
c010013a:	84 db                	test   %bl,%bl
c010013c:	74 16                	je     c0100154 <strncmp+0x2e>
c010013e:	3a 19                	cmp    (%ecx),%bl
c0100140:	75 12                	jne    c0100154 <strncmp+0x2e>
        n--, p++, q++;
c0100142:	83 c2 01             	add    $0x1,%edx
c0100145:	83 c1 01             	add    $0x1,%ecx
    while (n > 0 && *p && *p == *q)
c0100148:	83 e8 01             	sub    $0x1,%eax
c010014b:	75 ea                	jne    c0100137 <strncmp+0x11>
    if (n == 0)
        return 0;
c010014d:	b8 00 00 00 00       	mov    $0x0,%eax
c0100152:	eb 0c                	jmp    c0100160 <strncmp+0x3a>
    if (n == 0)
c0100154:	85 c0                	test   %eax,%eax
c0100156:	74 0d                	je     c0100165 <strncmp+0x3f>
    return (uint8_t)*p - (uint8_t)*q;
c0100158:	0f b6 02             	movzbl (%edx),%eax
c010015b:	0f b6 11             	movzbl (%ecx),%edx
c010015e:	29 d0                	sub    %edx,%eax
}
c0100160:	8b 5d fc             	mov    -0x4(%ebp),%ebx
c0100163:	c9                   	leave  
c0100164:	c3                   	ret    
        return 0;
c0100165:	b8 00 00 00 00       	mov    $0x0,%eax
c010016a:	eb f4                	jmp    c0100160 <strncmp+0x3a>

c010016c <strncpy>:

char* strncpy(char* s, const char* t, int n)
{
c010016c:	55                   	push   %ebp
c010016d:	89 e5                	mov    %esp,%ebp
c010016f:	57                   	push   %edi
c0100170:	56                   	push   %esi
c0100171:	53                   	push   %ebx
c0100172:	8b 75 08             	mov    0x8(%ebp),%esi
c0100175:	8b 4d 10             	mov    0x10(%ebp),%ecx
    char* os;

    os = s;
    while (n-- > 0 && (*s++ = *t++) != 0)
c0100178:	89 f0                	mov    %esi,%eax
c010017a:	89 cb                	mov    %ecx,%ebx
c010017c:	83 e9 01             	sub    $0x1,%ecx
c010017f:	85 db                	test   %ebx,%ebx
c0100181:	7e 17                	jle    c010019a <strncpy+0x2e>
c0100183:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
c0100187:	83 c0 01             	add    $0x1,%eax
c010018a:	8b 7d 0c             	mov    0xc(%ebp),%edi
c010018d:	0f b6 7f ff          	movzbl -0x1(%edi),%edi
c0100191:	89 fa                	mov    %edi,%edx
c0100193:	88 50 ff             	mov    %dl,-0x1(%eax)
c0100196:	84 d2                	test   %dl,%dl
c0100198:	75 e0                	jne    c010017a <strncpy+0xe>
        ;
    while (n-- > 0)
c010019a:	89 c2                	mov    %eax,%edx
c010019c:	85 c9                	test   %ecx,%ecx
c010019e:	7e 13                	jle    c01001b3 <strncpy+0x47>
        *s++ = 0;
c01001a0:	83 c2 01             	add    $0x1,%edx
c01001a3:	c6 42 ff 00          	movb   $0x0,-0x1(%edx)
    while (n-- > 0)
c01001a7:	89 d9                	mov    %ebx,%ecx
c01001a9:	29 d1                	sub    %edx,%ecx
c01001ab:	8d 4c 08 ff          	lea    -0x1(%eax,%ecx,1),%ecx
c01001af:	85 c9                	test   %ecx,%ecx
c01001b1:	7f ed                	jg     c01001a0 <strncpy+0x34>
    return os;
}
c01001b3:	89 f0                	mov    %esi,%eax
c01001b5:	5b                   	pop    %ebx
c01001b6:	5e                   	pop    %esi
c01001b7:	5f                   	pop    %edi
c01001b8:	5d                   	pop    %ebp
c01001b9:	c3                   	ret    

c01001ba <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char* safestrcpy(char* s, const char* t, int n)
{
c01001ba:	55                   	push   %ebp
c01001bb:	89 e5                	mov    %esp,%ebp
c01001bd:	56                   	push   %esi
c01001be:	53                   	push   %ebx
c01001bf:	8b 75 08             	mov    0x8(%ebp),%esi
c01001c2:	8b 45 0c             	mov    0xc(%ebp),%eax
c01001c5:	8b 55 10             	mov    0x10(%ebp),%edx
    char* os;

    os = s;
    if (n <= 0)
c01001c8:	85 d2                	test   %edx,%edx
c01001ca:	7e 1e                	jle    c01001ea <safestrcpy+0x30>
c01001cc:	8d 5c 10 ff          	lea    -0x1(%eax,%edx,1),%ebx
c01001d0:	89 f2                	mov    %esi,%edx
        return os;
    while (--n > 0 && (*s++ = *t++) != 0)
c01001d2:	39 d8                	cmp    %ebx,%eax
c01001d4:	74 11                	je     c01001e7 <safestrcpy+0x2d>
c01001d6:	83 c0 01             	add    $0x1,%eax
c01001d9:	83 c2 01             	add    $0x1,%edx
c01001dc:	0f b6 48 ff          	movzbl -0x1(%eax),%ecx
c01001e0:	88 4a ff             	mov    %cl,-0x1(%edx)
c01001e3:	84 c9                	test   %cl,%cl
c01001e5:	75 eb                	jne    c01001d2 <safestrcpy+0x18>
        ;
    *s = 0;
c01001e7:	c6 02 00             	movb   $0x0,(%edx)
    return os;
}
c01001ea:	89 f0                	mov    %esi,%eax
c01001ec:	5b                   	pop    %ebx
c01001ed:	5e                   	pop    %esi
c01001ee:	5d                   	pop    %ebp
c01001ef:	c3                   	ret    

c01001f0 <strlen>:

int strlen(const char* s)
{
c01001f0:	55                   	push   %ebp
c01001f1:	89 e5                	mov    %esp,%ebp
c01001f3:	8b 55 08             	mov    0x8(%ebp),%edx
    int n;

    for (n = 0; s[n]; n++)
c01001f6:	80 3a 00             	cmpb   $0x0,(%edx)
c01001f9:	74 10                	je     c010020b <strlen+0x1b>
c01001fb:	b8 00 00 00 00       	mov    $0x0,%eax
c0100200:	83 c0 01             	add    $0x1,%eax
c0100203:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
c0100207:	75 f7                	jne    c0100200 <strlen+0x10>
        ;
    return n;
}
c0100209:	5d                   	pop    %ebp
c010020a:	c3                   	ret    
    for (n = 0; s[n]; n++)
c010020b:	b8 00 00 00 00       	mov    $0x0,%eax
    return n;
c0100210:	eb f7                	jmp    c0100209 <strlen+0x19>

c0100212 <free_onepage>:

/**
 * 释放一页内存（由 vaddr 指向），在 kernel_pgdir 建立之前只由 free_vmem()调用，在建立之后与 alloc_onepage() 配合使用
 */
void free_onepage(char* vaddr)
{
c0100212:	55                   	push   %ebp
c0100213:	89 e5                	mov    %esp,%ebp
c0100215:	53                   	push   %ebx
c0100216:	83 ec 08             	sub    $0x8,%esp
c0100219:	8b 5d 08             	mov    0x8(%ebp),%ebx
    if ((vaddr_t)vaddr % PGSIZE || vaddr < end || V2P(vaddr) >= PHYSTOP)
        ;
    // panic("kfree");

    // Fill with junk to catch dangling refs.
    memset(vaddr, 1, PGSIZE);
c010021c:	68 00 10 00 00       	push   $0x1000
c0100221:	6a 01                	push   $0x1
c0100223:	53                   	push   %ebx
c0100224:	e8 11 fe ff ff       	call   c010003a <memset>

    // if (kmem.use_lock)
    //     acquire(&kmem.lock);
    r = (struct run*)vaddr;
    r->next = kmem.freelist;
c0100229:	a1 04 20 10 c0       	mov    0xc0102004,%eax
c010022e:	89 03                	mov    %eax,(%ebx)
    kmem.freelist = r;
c0100230:	89 1d 04 20 10 c0    	mov    %ebx,0xc0102004
    // if (kmem.use_lock)
    //     release(&kmem.lock);
}
c0100236:	83 c4 10             	add    $0x10,%esp
c0100239:	8b 5d fc             	mov    -0x4(%ebp),%ebx
c010023c:	c9                   	leave  
c010023d:	c3                   	ret    

c010023e <free_vmem>:
{
c010023e:	55                   	push   %ebp
c010023f:	89 e5                	mov    %esp,%ebp
c0100241:	56                   	push   %esi
c0100242:	53                   	push   %ebx
    char* p_start = (char*)PGROUNDUP((vaddr_t)start); // 向上取整，确保起始地址是页对齐的
c0100243:	8b 45 08             	mov    0x8(%ebp),%eax
c0100246:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
c010024c:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
    char* p_end = (char*)PGROUNDDOWN((vaddr_t)end); // 向下取整，确保结束地址是页对齐的
c0100252:	8b 75 0c             	mov    0xc(%ebp),%esi
c0100255:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    for (; p_start < p_end; p_start += PGSIZE)
c010025b:	39 f3                	cmp    %esi,%ebx
c010025d:	73 16                	jae    c0100275 <free_vmem+0x37>
        free_onepage(p_start);
c010025f:	83 ec 0c             	sub    $0xc,%esp
c0100262:	53                   	push   %ebx
c0100263:	e8 aa ff ff ff       	call   c0100212 <free_onepage>
    for (; p_start < p_end; p_start += PGSIZE)
c0100268:	81 c3 00 10 00 00    	add    $0x1000,%ebx
c010026e:	83 c4 10             	add    $0x10,%esp
c0100271:	39 de                	cmp    %ebx,%esi
c0100273:	77 ea                	ja     c010025f <free_vmem+0x21>
}
c0100275:	8d 65 f8             	lea    -0x8(%ebp),%esp
c0100278:	5b                   	pop    %ebx
c0100279:	5e                   	pop    %esi
c010027a:	5d                   	pop    %ebp
c010027b:	c3                   	ret    

c010027c <kmem_init>:
{
c010027c:	55                   	push   %ebp
c010027d:	89 e5                	mov    %esp,%ebp
c010027f:	83 ec 0c             	sub    $0xc,%esp
    memset(edata, 0, end - edata); // 先将bss段清零，确保所有静态/全局变量从零开始
c0100282:	8b 15 00 20 10 c0    	mov    0xc0102000,%edx
c0100288:	a1 10 30 10 c0       	mov    0xc0103010,%eax
c010028d:	29 d0                	sub    %edx,%eax
c010028f:	50                   	push   %eax
c0100290:	6a 00                	push   $0x0
c0100292:	52                   	push   %edx
c0100293:	e8 a2 fd ff ff       	call   c010003a <memset>
    free_vmem(end, P2V(4 * 1024 * 1024)); // 由于只映射了低4MB内存，先初始化[end, 4MB]的空间来为新的页表腾出空间
c0100298:	83 c4 08             	add    $0x8,%esp
c010029b:	68 00 00 40 c0       	push   $0xc0400000
c01002a0:	ff 35 10 30 10 c0    	push   0xc0103010
c01002a6:	e8 93 ff ff ff       	call   c010023e <free_vmem>
}
c01002ab:	83 c4 10             	add    $0x10,%esp
c01002ae:	c9                   	leave  
c01002af:	c3                   	ret    

c01002b0 <alloc_onepage>:
{
    struct run* r;

    // if (kmem.use_lock)
    //     acquire(&kmem.lock);
    r = kmem.freelist;
c01002b0:	a1 04 20 10 c0       	mov    0xc0102004,%eax
    if (r)
c01002b5:	85 c0                	test   %eax,%eax
c01002b7:	74 08                	je     c01002c1 <alloc_onepage+0x11>
        kmem.freelist = r->next;
c01002b9:	8b 10                	mov    (%eax),%edx
c01002bb:	89 15 04 20 10 c0    	mov    %edx,0xc0102004
    // if (kmem.use_lock)
    //     release(&kmem.lock);
    return (char*)r;
c01002c1:	c3                   	ret    
