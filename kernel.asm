
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
  movl    $(K_V2P_WO(entry_pgdir)), %eax
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
c010002e:	e8 02 04 00 00       	call   c0100435 <kmem_init>
}
c0100033:	b8 00 00 00 00       	mov    $0x0,%eax
c0100038:	c9                   	leave  
c0100039:	c3                   	ret    

c010003a <next_power_of_2>:
    //     panic("pa2page called with invalid pa");
    return &pages[PGNUM(pa)];
}

static size_t next_power_of_2(size_t size)
{
c010003a:	89 c2                	mov    %eax,%edx
    size |= size >> 1;
c010003c:	d1 e8                	shr    %eax
c010003e:	09 d0                	or     %edx,%eax
    size |= size >> 2;
c0100040:	89 c2                	mov    %eax,%edx
c0100042:	c1 ea 02             	shr    $0x2,%edx
c0100045:	09 c2                	or     %eax,%edx
    size |= size >> 4;
c0100047:	89 d0                	mov    %edx,%eax
c0100049:	c1 e8 04             	shr    $0x4,%eax
c010004c:	09 d0                	or     %edx,%eax
    size |= size >> 8;
c010004e:	89 c2                	mov    %eax,%edx
c0100050:	c1 ea 08             	shr    $0x8,%edx
c0100053:	09 c2                	or     %eax,%edx
    size |= size >> 16;
c0100055:	89 d0                	mov    %edx,%eax
c0100057:	c1 e8 10             	shr    $0x10,%eax
c010005a:	09 d0                	or     %edx,%eax
    return size + 1;
c010005c:	83 c0 01             	add    $0x1,%eax
}
c010005f:	c3                   	ret    

c0100060 <tmp_alloc>:
tmp_alloc(uint32_t n)
{
    static char* nextfree; // static意味着nextfree不会随着函数返回被重置，是静态变量
    char* result;

    if (!nextfree) // nextfree初始化，只有第一次运行会执行
c0100060:	83 3d 0c 20 10 c0 00 	cmpl   $0x0,0xc010200c
c0100067:	74 2b                	je     c0100094 <tmp_alloc+0x34>
        nextfree = ROUNDUP((char*)end, PGSIZE); // 内核使用的第一块内存必须远离内核代码结尾
    }

    if (n == 0) // 不分配内存，直接返回
    {
        return nextfree;
c0100069:	8b 15 0c 20 10 c0    	mov    0xc010200c,%edx
    if (n == 0) // 不分配内存，直接返回
c010006f:	85 c0                	test   %eax,%eax
c0100071:	74 1e                	je     c0100091 <tmp_alloc+0x31>
    }

    // n是无符号数，不考虑<0情形
    result = nextfree; // 将更新前的nextfree赋给result
c0100073:	8b 15 0c 20 10 c0    	mov    0xc010200c,%edx
    nextfree += ROUNDUP(n, PGSIZE); // +=:在原来的基础上再分配
c0100079:	05 ff 0f 00 00       	add    $0xfff,%eax
c010007e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0100083:	01 d0                	add    %edx,%eax
c0100085:	a3 0c 20 10 c0       	mov    %eax,0xc010200c

    // 如果内存不足，boot_alloc应该会死机
    if (nextfree > (char*)0xC0400000) // >4MB
c010008a:	3d 00 00 40 c0       	cmp    $0xc0400000,%eax
c010008f:	77 1d                	ja     c01000ae <tmp_alloc+0x4e>
        // panic("out of memory(4MB) : boot_alloc() in pmap.c \n"); // 调用预先定义的assert
        nextfree = result; // 分配失败，回调nextfree
        return NULL;
    }
    return result;
}
c0100091:	89 d0                	mov    %edx,%eax
c0100093:	c3                   	ret    
        nextfree = ROUNDUP((char*)end, PGSIZE); // 内核使用的第一块内存必须远离内核代码结尾
c0100094:	8b 0d 10 30 10 c0    	mov    0xc0103010,%ecx
c010009a:	8d 91 ff 0f 00 00    	lea    0xfff(%ecx),%edx
c01000a0:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
c01000a6:	89 15 0c 20 10 c0    	mov    %edx,0xc010200c
c01000ac:	eb bb                	jmp    c0100069 <tmp_alloc+0x9>
        nextfree = result; // 分配失败，回调nextfree
c01000ae:	89 15 0c 20 10 c0    	mov    %edx,0xc010200c
        return NULL;
c01000b4:	ba 00 00 00 00       	mov    $0x0,%edx
c01000b9:	eb d6                	jmp    c0100091 <tmp_alloc+0x31>

c01000bb <memset>:

#include "inc/x86.h"

void* memset(void* dst, int c, uint32_t n)
{
c01000bb:	55                   	push   %ebp
c01000bc:	89 e5                	mov    %esp,%ebp
c01000be:	57                   	push   %edi
c01000bf:	8b 55 08             	mov    0x8(%ebp),%edx
c01000c2:	8b 4d 10             	mov    0x10(%ebp),%ecx
    if ((int)dst % 4 == 0 && n % 4 == 0) {
c01000c5:	89 d0                	mov    %edx,%eax
c01000c7:	09 c8                	or     %ecx,%eax
c01000c9:	a8 03                	test   $0x3,%al
c01000cb:	75 14                	jne    c01000e1 <memset+0x26>
        c &= 0xFF;
        stosl(dst, (c << 24) | (c << 16) | (c << 8) | c, n / 4);
c01000cd:	c1 e9 02             	shr    $0x2,%ecx
        c &= 0xFF;
c01000d0:	0f b6 45 0c          	movzbl 0xc(%ebp),%eax
        stosl(dst, (c << 24) | (c << 16) | (c << 8) | c, n / 4);
c01000d4:	69 c0 01 01 01 01    	imul   $0x1010101,%eax,%eax
}

static inline void
stosl(void* addr, int data, int cnt)
{
    asm volatile("cld; rep stosl"
c01000da:	89 d7                	mov    %edx,%edi
c01000dc:	fc                   	cld    
c01000dd:	f3 ab                	rep stos %eax,%es:(%edi)
                 : "=D"(addr), "=c"(cnt)
                 : "0"(addr), "1"(cnt), "a"(data)
                 : "memory", "cc");
}
c01000df:	eb 08                	jmp    c01000e9 <memset+0x2e>
    asm volatile("cld; rep stosb"
c01000e1:	89 d7                	mov    %edx,%edi
c01000e3:	8b 45 0c             	mov    0xc(%ebp),%eax
c01000e6:	fc                   	cld    
c01000e7:	f3 aa                	rep stos %al,%es:(%edi)
    } else
        stosb(dst, c, n);
    return dst;
}
c01000e9:	89 d0                	mov    %edx,%eax
c01000eb:	8b 7d fc             	mov    -0x4(%ebp),%edi
c01000ee:	c9                   	leave  
c01000ef:	c3                   	ret    

c01000f0 <memcmp>:

int memcmp(const void* v1, const void* v2, uint32_t n)
{
c01000f0:	55                   	push   %ebp
c01000f1:	89 e5                	mov    %esp,%ebp
c01000f3:	56                   	push   %esi
c01000f4:	53                   	push   %ebx
c01000f5:	8b 45 08             	mov    0x8(%ebp),%eax
c01000f8:	8b 55 0c             	mov    0xc(%ebp),%edx
c01000fb:	8b 75 10             	mov    0x10(%ebp),%esi
    const uint8_t *s1, *s2;

    s1 = v1;
    s2 = v2;
    while (n-- > 0) {
c01000fe:	85 f6                	test   %esi,%esi
c0100100:	74 29                	je     c010012b <memcmp+0x3b>
c0100102:	01 c6                	add    %eax,%esi
        if (*s1 != *s2)
c0100104:	0f b6 08             	movzbl (%eax),%ecx
c0100107:	0f b6 1a             	movzbl (%edx),%ebx
c010010a:	38 d9                	cmp    %bl,%cl
c010010c:	75 11                	jne    c010011f <memcmp+0x2f>
            return *s1 - *s2;
        s1++, s2++;
c010010e:	83 c0 01             	add    $0x1,%eax
c0100111:	83 c2 01             	add    $0x1,%edx
    while (n-- > 0) {
c0100114:	39 c6                	cmp    %eax,%esi
c0100116:	75 ec                	jne    c0100104 <memcmp+0x14>
    }

    return 0;
c0100118:	b8 00 00 00 00       	mov    $0x0,%eax
c010011d:	eb 08                	jmp    c0100127 <memcmp+0x37>
            return *s1 - *s2;
c010011f:	0f b6 c1             	movzbl %cl,%eax
c0100122:	0f b6 db             	movzbl %bl,%ebx
c0100125:	29 d8                	sub    %ebx,%eax
}
c0100127:	5b                   	pop    %ebx
c0100128:	5e                   	pop    %esi
c0100129:	5d                   	pop    %ebp
c010012a:	c3                   	ret    
    return 0;
c010012b:	b8 00 00 00 00       	mov    $0x0,%eax
c0100130:	eb f5                	jmp    c0100127 <memcmp+0x37>

c0100132 <memmove>:

void* memmove(void* dst, const void* src, uint32_t n)
{
c0100132:	55                   	push   %ebp
c0100133:	89 e5                	mov    %esp,%ebp
c0100135:	56                   	push   %esi
c0100136:	53                   	push   %ebx
c0100137:	8b 75 08             	mov    0x8(%ebp),%esi
c010013a:	8b 45 0c             	mov    0xc(%ebp),%eax
c010013d:	8b 4d 10             	mov    0x10(%ebp),%ecx
    const char* s;
    char* d;

    s = src;
    d = dst;
    if (s < d && s + n > d) {
c0100140:	39 f0                	cmp    %esi,%eax
c0100142:	72 20                	jb     c0100164 <memmove+0x32>
        s += n;
        d += n;
        while (n-- > 0)
            *--d = *--s;
    } else
        while (n-- > 0)
c0100144:	8d 1c 08             	lea    (%eax,%ecx,1),%ebx
c0100147:	89 f2                	mov    %esi,%edx
c0100149:	85 c9                	test   %ecx,%ecx
c010014b:	74 11                	je     c010015e <memmove+0x2c>
            *d++ = *s++;
c010014d:	83 c0 01             	add    $0x1,%eax
c0100150:	83 c2 01             	add    $0x1,%edx
c0100153:	0f b6 48 ff          	movzbl -0x1(%eax),%ecx
c0100157:	88 4a ff             	mov    %cl,-0x1(%edx)
        while (n-- > 0)
c010015a:	39 d8                	cmp    %ebx,%eax
c010015c:	75 ef                	jne    c010014d <memmove+0x1b>

    return dst;
}
c010015e:	89 f0                	mov    %esi,%eax
c0100160:	5b                   	pop    %ebx
c0100161:	5e                   	pop    %esi
c0100162:	5d                   	pop    %ebp
c0100163:	c3                   	ret    
    if (s < d && s + n > d) {
c0100164:	8d 14 08             	lea    (%eax,%ecx,1),%edx
c0100167:	39 d6                	cmp    %edx,%esi
c0100169:	73 d9                	jae    c0100144 <memmove+0x12>
        while (n-- > 0)
c010016b:	8d 51 ff             	lea    -0x1(%ecx),%edx
c010016e:	85 c9                	test   %ecx,%ecx
c0100170:	74 ec                	je     c010015e <memmove+0x2c>
            *--d = *--s;
c0100172:	0f b6 0c 10          	movzbl (%eax,%edx,1),%ecx
c0100176:	88 0c 16             	mov    %cl,(%esi,%edx,1)
        while (n-- > 0)
c0100179:	83 ea 01             	sub    $0x1,%edx
c010017c:	83 fa ff             	cmp    $0xffffffff,%edx
c010017f:	75 f1                	jne    c0100172 <memmove+0x40>
c0100181:	eb db                	jmp    c010015e <memmove+0x2c>

c0100183 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void* memcpy(void* dst, const void* src, uint32_t n)
{
c0100183:	55                   	push   %ebp
c0100184:	89 e5                	mov    %esp,%ebp
c0100186:	83 ec 0c             	sub    $0xc,%esp
    return memmove(dst, src, n);
c0100189:	ff 75 10             	push   0x10(%ebp)
c010018c:	ff 75 0c             	push   0xc(%ebp)
c010018f:	ff 75 08             	push   0x8(%ebp)
c0100192:	e8 9b ff ff ff       	call   c0100132 <memmove>
}
c0100197:	c9                   	leave  
c0100198:	c3                   	ret    

c0100199 <strncmp>:

int strncmp(const char* p, const char* q, uint32_t n)
{
c0100199:	55                   	push   %ebp
c010019a:	89 e5                	mov    %esp,%ebp
c010019c:	53                   	push   %ebx
c010019d:	8b 55 08             	mov    0x8(%ebp),%edx
c01001a0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
c01001a3:	8b 45 10             	mov    0x10(%ebp),%eax
    while (n > 0 && *p && *p == *q)
c01001a6:	85 c0                	test   %eax,%eax
c01001a8:	74 29                	je     c01001d3 <strncmp+0x3a>
c01001aa:	0f b6 1a             	movzbl (%edx),%ebx
c01001ad:	84 db                	test   %bl,%bl
c01001af:	74 16                	je     c01001c7 <strncmp+0x2e>
c01001b1:	3a 19                	cmp    (%ecx),%bl
c01001b3:	75 12                	jne    c01001c7 <strncmp+0x2e>
        n--, p++, q++;
c01001b5:	83 c2 01             	add    $0x1,%edx
c01001b8:	83 c1 01             	add    $0x1,%ecx
    while (n > 0 && *p && *p == *q)
c01001bb:	83 e8 01             	sub    $0x1,%eax
c01001be:	75 ea                	jne    c01001aa <strncmp+0x11>
    if (n == 0)
        return 0;
c01001c0:	b8 00 00 00 00       	mov    $0x0,%eax
c01001c5:	eb 0c                	jmp    c01001d3 <strncmp+0x3a>
    if (n == 0)
c01001c7:	85 c0                	test   %eax,%eax
c01001c9:	74 0d                	je     c01001d8 <strncmp+0x3f>
    return (uint8_t)*p - (uint8_t)*q;
c01001cb:	0f b6 02             	movzbl (%edx),%eax
c01001ce:	0f b6 11             	movzbl (%ecx),%edx
c01001d1:	29 d0                	sub    %edx,%eax
}
c01001d3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
c01001d6:	c9                   	leave  
c01001d7:	c3                   	ret    
        return 0;
c01001d8:	b8 00 00 00 00       	mov    $0x0,%eax
c01001dd:	eb f4                	jmp    c01001d3 <strncmp+0x3a>

c01001df <strncpy>:

char* strncpy(char* s, const char* t, int n)
{
c01001df:	55                   	push   %ebp
c01001e0:	89 e5                	mov    %esp,%ebp
c01001e2:	57                   	push   %edi
c01001e3:	56                   	push   %esi
c01001e4:	53                   	push   %ebx
c01001e5:	8b 75 08             	mov    0x8(%ebp),%esi
c01001e8:	8b 55 10             	mov    0x10(%ebp),%edx
    char* os;

    os = s;
    while (n-- > 0 && (*s++ = *t++) != 0)
c01001eb:	89 f1                	mov    %esi,%ecx
c01001ed:	89 d3                	mov    %edx,%ebx
c01001ef:	83 ea 01             	sub    $0x1,%edx
c01001f2:	85 db                	test   %ebx,%ebx
c01001f4:	7e 17                	jle    c010020d <strncpy+0x2e>
c01001f6:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
c01001fa:	83 c1 01             	add    $0x1,%ecx
c01001fd:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100200:	0f b6 78 ff          	movzbl -0x1(%eax),%edi
c0100204:	89 f8                	mov    %edi,%eax
c0100206:	88 41 ff             	mov    %al,-0x1(%ecx)
c0100209:	84 c0                	test   %al,%al
c010020b:	75 e0                	jne    c01001ed <strncpy+0xe>
        ;
    while (n-- > 0)
c010020d:	89 c8                	mov    %ecx,%eax
c010020f:	8d 4c 19 ff          	lea    -0x1(%ecx,%ebx,1),%ecx
c0100213:	85 d2                	test   %edx,%edx
c0100215:	7e 0f                	jle    c0100226 <strncpy+0x47>
        *s++ = 0;
c0100217:	83 c0 01             	add    $0x1,%eax
c010021a:	c6 40 ff 00          	movb   $0x0,-0x1(%eax)
    while (n-- > 0)
c010021e:	89 ca                	mov    %ecx,%edx
c0100220:	29 c2                	sub    %eax,%edx
c0100222:	85 d2                	test   %edx,%edx
c0100224:	7f f1                	jg     c0100217 <strncpy+0x38>
    return os;
}
c0100226:	89 f0                	mov    %esi,%eax
c0100228:	5b                   	pop    %ebx
c0100229:	5e                   	pop    %esi
c010022a:	5f                   	pop    %edi
c010022b:	5d                   	pop    %ebp
c010022c:	c3                   	ret    

c010022d <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char* safestrcpy(char* s, const char* t, int n)
{
c010022d:	55                   	push   %ebp
c010022e:	89 e5                	mov    %esp,%ebp
c0100230:	56                   	push   %esi
c0100231:	53                   	push   %ebx
c0100232:	8b 75 08             	mov    0x8(%ebp),%esi
c0100235:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100238:	8b 55 10             	mov    0x10(%ebp),%edx
    char* os;

    os = s;
    if (n <= 0)
c010023b:	85 d2                	test   %edx,%edx
c010023d:	7e 1e                	jle    c010025d <safestrcpy+0x30>
c010023f:	8d 5c 10 ff          	lea    -0x1(%eax,%edx,1),%ebx
c0100243:	89 f2                	mov    %esi,%edx
        return os;
    while (--n > 0 && (*s++ = *t++) != 0)
c0100245:	39 d8                	cmp    %ebx,%eax
c0100247:	74 11                	je     c010025a <safestrcpy+0x2d>
c0100249:	83 c0 01             	add    $0x1,%eax
c010024c:	83 c2 01             	add    $0x1,%edx
c010024f:	0f b6 48 ff          	movzbl -0x1(%eax),%ecx
c0100253:	88 4a ff             	mov    %cl,-0x1(%edx)
c0100256:	84 c9                	test   %cl,%cl
c0100258:	75 eb                	jne    c0100245 <safestrcpy+0x18>
        ;
    *s = 0;
c010025a:	c6 02 00             	movb   $0x0,(%edx)
    return os;
}
c010025d:	89 f0                	mov    %esi,%eax
c010025f:	5b                   	pop    %ebx
c0100260:	5e                   	pop    %esi
c0100261:	5d                   	pop    %ebp
c0100262:	c3                   	ret    

c0100263 <strlen>:

int strlen(const char* s)
{
c0100263:	55                   	push   %ebp
c0100264:	89 e5                	mov    %esp,%ebp
c0100266:	8b 55 08             	mov    0x8(%ebp),%edx
    int n;

    for (n = 0; s[n]; n++)
c0100269:	80 3a 00             	cmpb   $0x0,(%edx)
c010026c:	74 10                	je     c010027e <strlen+0x1b>
c010026e:	b8 00 00 00 00       	mov    $0x0,%eax
c0100273:	83 c0 01             	add    $0x1,%eax
c0100276:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
c010027a:	75 f7                	jne    c0100273 <strlen+0x10>
        ;
    return n;
}
c010027c:	5d                   	pop    %ebp
c010027d:	c3                   	ret    
    for (n = 0; s[n]; n++)
c010027e:	b8 00 00 00 00       	mov    $0x0,%eax
    return n;
c0100283:	eb f7                	jmp    c010027c <strlen+0x19>

c0100285 <page_init>:
// char* alloc_page(char* vaddr)
// {
// }

void page_init()
{
c0100285:	55                   	push   %ebp
c0100286:	89 e5                	mov    %esp,%ebp
c0100288:	57                   	push   %edi
c0100289:	56                   	push   %esi
c010028a:	53                   	push   %ebx
c010028b:	83 ec 1c             	sub    $0x1c,%esp
    /* 先为 pages 分配空间，以便映射每一页物理内存 */
    pages = (struct Page*)tmp_alloc(n_pages * sizeof(struct Page));
c010028e:	b8 00 00 00 00       	mov    $0x0,%eax
c0100293:	e8 c8 fd ff ff       	call   c0100060 <tmp_alloc>
c0100298:	a3 08 20 10 c0       	mov    %eax,0xc0102008
    memset(pages, 0, n_pages * sizeof(struct Page));
c010029d:	83 ec 04             	sub    $0x4,%esp
c01002a0:	6a 00                	push   $0x0
c01002a2:	6a 00                	push   $0x0
c01002a4:	50                   	push   %eax
c01002a5:	e8 11 fe ff ff       	call   c01000bb <memset>
    for (int i = 0; i < n_pages; i++) {
        (pages + i)->reserved = true;
    }
    /* 伙伴系统初始化 */
    zone_mem_base = (struct Page*)tmp_alloc(0); // 可管理区域的起始地址
c01002aa:	b8 00 00 00 00       	mov    $0x0,%eax
c01002af:	e8 ac fd ff ff       	call   c0100060 <tmp_alloc>
c01002b4:	89 c3                	mov    %eax,%ebx
    struct buddy* buddy = &zone->free_lists[order++];
c01002b6:	a1 04 20 10 c0       	mov    0xc0102004,%eax
c01002bb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c01002be:	83 c0 01             	add    $0x1,%eax
c01002c1:	a3 04 20 10 c0       	mov    %eax,0xc0102004
    return (page - pages) << PGSHIFT;
c01002c6:	89 de                	mov    %ebx,%esi
c01002c8:	2b 35 08 20 10 c0    	sub    0xc0102008,%esi
c01002ce:	c1 fe 02             	sar    $0x2,%esi
c01002d1:	69 f6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%esi
    size_t n_page_allocable = n_pages - PGNUM(page2pa(zone_mem_base)); // 可分配的页数量
c01002d7:	89 f7                	mov    %esi,%edi
c01002d9:	81 e7 ff ff 0f 00    	and    $0xfffff,%edi
c01002df:	89 f8                	mov    %edi,%eax
c01002e1:	f7 d8                	neg    %eax
    size_t v_size = next_power_of_2(n_page_allocable);
c01002e3:	89 45 e0             	mov    %eax,-0x20(%ebp)
c01002e6:	e8 4f fd ff ff       	call   c010003a <next_power_of_2>
c01002eb:	89 c6                	mov    %eax,%esi
    size_t excess = v_size - n_page_allocable;
c01002ed:	8d 04 07             	lea    (%edi,%eax,1),%eax
    size_t v_alloced_size = next_power_of_2(excess);
c01002f0:	e8 45 fd ff ff       	call   c010003a <next_power_of_2>
c01002f5:	89 c7                	mov    %eax,%edi

    buddy->size = v_size;
c01002f7:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
c01002fa:	8d 0c 49             	lea    (%ecx,%ecx,2),%ecx
c01002fd:	c1 e1 03             	shl    $0x3,%ecx
c0100300:	89 31                	mov    %esi,(%ecx)
    buddy->free_size = v_size - v_alloced_size;
c0100302:	89 f2                	mov    %esi,%edx
c0100304:	29 c2                	sub    %eax,%edx
c0100306:	89 51 10             	mov    %edx,0x10(%ecx)
c0100309:	89 da                	mov    %ebx,%edx
c010030b:	2b 15 08 20 10 c0    	sub    0xc0102008,%edx
c0100311:	89 d0                	mov    %edx,%eax
c0100313:	c1 f8 02             	sar    $0x2,%eax
c0100316:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
c010031c:	c1 e0 0c             	shl    $0xc,%eax
    return K_P2V(page2pa(page));
c010031f:	2d 00 00 00 40       	sub    $0x40000000,%eax
    buddy->longest = page2kva(zone_mem_base);
c0100324:	89 41 04             	mov    %eax,0x4(%ecx)
    buddy->start = pa2page(K_V2P(ROUNDUP(buddy->longest + 2 * v_size * sizeof(uintptr_t), PGSIZE)));
c0100327:	89 f2                	mov    %esi,%edx
c0100329:	c1 e2 05             	shl    $0x5,%edx
c010032c:	8d 84 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%eax
c0100333:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0100338:	05 00 00 00 40       	add    $0x40000000,%eax
    return &pages[PGNUM(pa)];
c010033d:	89 c2                	mov    %eax,%edx
c010033f:	c1 ea 0c             	shr    $0xc,%edx
c0100342:	c1 e8 0b             	shr    $0xb,%eax
c0100345:	01 d0                	add    %edx,%eax
c0100347:	8b 15 08 20 10 c0    	mov    0xc0102008,%edx
c010034d:	8d 04 82             	lea    (%edx,%eax,4),%eax
c0100350:	89 41 14             	mov    %eax,0x14(%ecx)
    buddy->longest_num_page = buddy->start - zone_mem_base;
c0100353:	29 d8                	sub    %ebx,%eax
c0100355:	c1 f8 02             	sar    $0x2,%eax
c0100358:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
c010035e:	89 41 08             	mov    %eax,0x8(%ecx)
    buddy->total_num_page = n_page_allocable - buddy->longest_num_page;
c0100361:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0100364:	29 c2                	sub    %eax,%edx
c0100366:	89 51 0c             	mov    %edx,0xc(%ecx)

    size_t node_size = buddy->size * 2;
c0100369:	8d 14 36             	lea    (%esi,%esi,1),%edx
c010036c:	83 c4 10             	add    $0x10,%esp

    for (int i = 0; i < 2 * buddy->size - 1; i++) {
c010036f:	b8 00 00 00 00       	mov    $0x0,%eax
c0100374:	89 5d e0             	mov    %ebx,-0x20(%ebp)
        if (IS_POWER_OF_2(i + 1)) {
c0100377:	89 c6                	mov    %eax,%esi
c0100379:	83 c0 01             	add    $0x1,%eax
            node_size /= 2;
c010037c:	89 d3                	mov    %edx,%ebx
c010037e:	d1 eb                	shr    %ebx
c0100380:	85 f0                	test   %esi,%eax
c0100382:	0f 44 d3             	cmove  %ebx,%edx
        }
        buddy->longest[i] = node_size;
c0100385:	8b 59 04             	mov    0x4(%ecx),%ebx
c0100388:	89 54 83 fc          	mov    %edx,-0x4(%ebx,%eax,4)
    for (int i = 0; i < 2 * buddy->size - 1; i++) {
c010038c:	8b 19                	mov    (%ecx),%ebx
c010038e:	8d 5c 1b ff          	lea    -0x1(%ebx,%ebx,1),%ebx
c0100392:	39 d8                	cmp    %ebx,%eax
c0100394:	72 e1                	jb     c0100377 <page_init+0xf2>
    }

    int index = 0;
    while (1) {
        if (buddy->longest[index] == v_alloced_size) {
c0100396:	8b 5d e0             	mov    -0x20(%ebp),%ebx
c0100399:	8b 71 04             	mov    0x4(%ecx),%esi
c010039c:	39 3e                	cmp    %edi,(%esi)
c010039e:	0f 84 89 00 00 00    	je     c010042d <page_init+0x1a8>
    int index = 0;
c01003a4:	b8 00 00 00 00       	mov    $0x0,%eax
            buddy->longest[index] = 0;
            break;
        }
        index = RIGHT_LEAF(index);
c01003a9:	8d 50 01             	lea    0x1(%eax),%edx
c01003ac:	8d 04 12             	lea    (%edx,%edx,1),%eax
        if (buddy->longest[index] == v_alloced_size) {
c01003af:	8d 14 d6             	lea    (%esi,%edx,8),%edx
c01003b2:	39 3a                	cmp    %edi,(%edx)
c01003b4:	75 f3                	jne    c01003a9 <page_init+0x124>
            buddy->longest[index] = 0;
c01003b6:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
    }

    while (index) {
        index = PARENT(index);
c01003bc:	8d 50 01             	lea    0x1(%eax),%edx
c01003bf:	89 d0                	mov    %edx,%eax
c01003c1:	c1 e8 1f             	shr    $0x1f,%eax
c01003c4:	01 d0                	add    %edx,%eax
c01003c6:	d1 f8                	sar    %eax
c01003c8:	83 e8 01             	sub    $0x1,%eax
        buddy->longest[index] = MAX(buddy->longest[LEFT_LEAF(index)], buddy->longest[RIGHT_LEAF(index)]);
c01003cb:	8b 71 04             	mov    0x4(%ecx),%esi
c01003ce:	8b 54 c6 04          	mov    0x4(%esi,%eax,8),%edx
c01003d2:	8b 7c c6 08          	mov    0x8(%esi,%eax,8),%edi
c01003d6:	39 fa                	cmp    %edi,%edx
c01003d8:	0f 42 d7             	cmovb  %edi,%edx
c01003db:	89 14 86             	mov    %edx,(%esi,%eax,4)
    while (index) {
c01003de:	85 c0                	test   %eax,%eax
c01003e0:	75 da                	jne    c01003bc <page_init+0x137>
    }

    struct Page* p = buddy->start;
c01003e2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
c01003e5:	8d 14 3f             	lea    (%edi,%edi,1),%edx
c01003e8:	8d 04 3a             	lea    (%edx,%edi,1),%eax
c01003eb:	8b 04 c5 14 00 00 00 	mov    0x14(,%eax,8),%eax
    for (; p != zone_mem_base + buddy->free_size; p++) {
c01003f2:	01 fa                	add    %edi,%edx
c01003f4:	8b 14 d5 10 00 00 00 	mov    0x10(,%edx,8),%edx
c01003fb:	8d 14 52             	lea    (%edx,%edx,2),%edx
c01003fe:	8d 14 93             	lea    (%ebx,%edx,4),%edx
c0100401:	39 d0                	cmp    %edx,%eax
c0100403:	74 20                	je     c0100425 <page_init+0x1a0>
c0100405:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
c0100408:	c1 e1 03             	shl    $0x3,%ecx
        p->reserved = false;
c010040b:	c6 40 0a 00          	movb   $0x0,0xa(%eax)
        p->pg_ref = 0;
c010040f:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
    for (; p != zone_mem_base + buddy->free_size; p++) {
c0100415:	83 c0 0c             	add    $0xc,%eax
c0100418:	8b 51 10             	mov    0x10(%ecx),%edx
c010041b:	8d 14 52             	lea    (%edx,%edx,2),%edx
c010041e:	8d 14 93             	lea    (%ebx,%edx,4),%edx
c0100421:	39 d0                	cmp    %edx,%eax
c0100423:	75 e6                	jne    c010040b <page_init+0x186>
    }
c0100425:	8d 65 f4             	lea    -0xc(%ebp),%esp
c0100428:	5b                   	pop    %ebx
c0100429:	5e                   	pop    %esi
c010042a:	5f                   	pop    %edi
c010042b:	5d                   	pop    %ebp
c010042c:	c3                   	ret    
            buddy->longest[index] = 0;
c010042d:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
    while (index) {
c0100433:	eb ad                	jmp    c01003e2 <page_init+0x15d>

c0100435 <kmem_init>:
{
c0100435:	55                   	push   %ebp
c0100436:	89 e5                	mov    %esp,%ebp
c0100438:	83 ec 0c             	sub    $0xc,%esp
    memset(edata, 0, end - edata); // 先将bss段清零，确保所有静态/全局变量从零开始
c010043b:	8b 15 00 20 10 c0    	mov    0xc0102000,%edx
c0100441:	a1 10 30 10 c0       	mov    0xc0103010,%eax
c0100446:	29 d0                	sub    %edx,%eax
c0100448:	50                   	push   %eax
c0100449:	6a 00                	push   $0x0
c010044b:	52                   	push   %edx
c010044c:	e8 6a fc ff ff       	call   c01000bb <memset>
    memset(end, 0, K_P2V_WO(P_ADDR_LOWMEM)); // 由于只映射了低 4MB 内存，先初始化 [end, 4MB] 的空间来为新的页表腾出空间
c0100451:	83 c4 0c             	add    $0xc,%esp
c0100454:	68 00 00 40 c0       	push   $0xc0400000
c0100459:	6a 00                	push   $0x0
c010045b:	ff 35 10 30 10 c0    	push   0xc0103010
c0100461:	e8 55 fc ff ff       	call   c01000bb <memset>
    kernel_pgdir = (pde_t*)tmp_alloc(PGSIZE); // 分配一页内存作为页目录
c0100466:	b8 00 10 00 00       	mov    $0x1000,%eax
c010046b:	e8 f0 fb ff ff       	call   c0100060 <tmp_alloc>
c0100470:	a3 00 20 10 c0       	mov    %eax,0xc0102000
    page_init();
c0100475:	e8 0b fe ff ff       	call   c0100285 <page_init>
}
c010047a:	83 c4 10             	add    $0x10,%esp
c010047d:	c9                   	leave  
c010047e:	c3                   	ret    
