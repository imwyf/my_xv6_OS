
bootloader.out:     file format elf32-i386


Disassembly of section .text:

00007c00 <_start>:
    7c00:	fa                   	cli    
    7c01:	fc                   	cld    
    7c02:	31 c0                	xor    %eax,%eax
    7c04:	8e d8                	mov    %eax,%ds
    7c06:	8e c0                	mov    %eax,%es
    7c08:	8e d0                	mov    %eax,%ss

00007c0a <seta20_1>:
    7c0a:	e4 64                	in     $0x64,%al
    7c0c:	a8 02                	test   $0x2,%al
    7c0e:	75 fa                	jne    7c0a <seta20_1>
    7c10:	b0 d1                	mov    $0xd1,%al
    7c12:	e6 64                	out    %al,$0x64

00007c14 <seta20_2>:
    7c14:	e4 64                	in     $0x64,%al
    7c16:	a8 02                	test   $0x2,%al
    7c18:	75 fa                	jne    7c14 <seta20_2>
    7c1a:	b0 df                	mov    $0xdf,%al
    7c1c:	e6 60                	out    %al,$0x60
    7c1e:	0f 01 16             	lgdtl  (%esi)
    7c21:	18 7e 0f             	sbb    %bh,0xf(%esi)
    7c24:	20 c0                	and    %al,%al
    7c26:	66 83 c8 01          	or     $0x1,%ax
    7c2a:	0f 22 c0             	mov    %eax,%cr0
    7c2d:	ea 32 7c 08 00   	ljmp   $0xb866,$0x87c32

00007c32 <boot32>:
    7c32:	66 b8 10 00          	mov    $0x10,%ax
    7c36:	8e d8                	mov    %eax,%ds
    7c38:	8e c0                	mov    %eax,%es
    7c3a:	8e e0                	mov    %eax,%fs
    7c3c:	8e e8                	mov    %eax,%gs
    7c3e:	8e d0                	mov    %eax,%ss
    7c40:	bc 00 7c 00 00       	mov    $0x7c00,%esp
    7c45:	e8 d4 01 00 00       	call   7e1e <loader>

00007c4a <boot_fail_loop>:
    7c4a:	eb fe                	jmp    7c4a <boot_fail_loop>
	...
    7dfc:	00 00                	add    %al,(%eax)
    7dfe:	55                   	push   %ebp
    7dff:	aa                   	stos   %al,%es:(%edi)

00007e00 <gdt>:
	...
    7e08:	ff                   	(bad)  
    7e09:	ff 00                	incl   (%eax)
    7e0b:	00 00                	add    %al,(%eax)
    7e0d:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
    7e14:	00 92 cf 00      	add    %dl,0x1700cf(%edx)

00007e18 <gdtr>:
    7e18:	17                   	pop    %ss
    7e19:	00 00                	add    %al,(%eax)
    7e1b:	7e 00                	jle    7e1d <gdtr+0x5>
	...

00007e1e <loader>:
    7e1e:	eb fe                	jmp    7e1e <loader>

Disassembly of section .eh_frame:

00007e20 <__bss_start-0x2c>:
    7e20:	14 00                	adc    $0x0,%al
    7e22:	00 00                	add    %al,(%eax)
    7e24:	00 00                	add    %al,(%eax)
    7e26:	00 00                	add    %al,(%eax)
    7e28:	01 7a 52             	add    %edi,0x52(%edx)
    7e2b:	00 01                	add    %al,(%ecx)
    7e2d:	7c 08                	jl     7e37 <loader+0x19>
    7e2f:	01 1b                	add    %ebx,(%ebx)
    7e31:	0c 04                	or     $0x4,%al
    7e33:	04 88                	add    $0x88,%al
    7e35:	01 00                	add    %eax,(%eax)
    7e37:	00 10                	add    %dl,(%eax)
    7e39:	00 00                	add    %al,(%eax)
    7e3b:	00 1c 00             	add    %bl,(%eax,%eax,1)
    7e3e:	00 00                	add    %al,(%eax)
    7e40:	de ff                	fdivrp %st,%st(7)
    7e42:	ff                   	(bad)  
    7e43:	ff 02                	incl   (%edx)
    7e45:	00 00                	add    %al,(%eax)
    7e47:	00 00                	add    %al,(%eax)
    7e49:	00 00                	add    %al,(%eax)
	...

Disassembly of section .stab:

00000000 <.stab>:
   0:	01 00                	add    %eax,(%eax)
   2:	00 00                	add    %al,(%eax)
   4:	00 00                	add    %al,(%eax)
   6:	28 00                	sub    %al,(%eax)
   8:	76 00                	jbe    a <CODE_SEG_SELECTOR+0x2>
   a:	00 00                	add    %al,(%eax)
   c:	01 00                	add    %eax,(%eax)
   e:	00 00                	add    %al,(%eax)
  10:	64 00 00             	add    %al,%fs:(%eax)
  13:	00 00                	add    %al,(%eax)
  15:	7c 00                	jl     17 <DATA_SEG_SELECTOR+0x7>
  17:	00 11                	add    %dl,(%ecx)
  19:	00 00                	add    %al,(%eax)
  1b:	00 84 00 00 00 00 7c 	add    %al,0x7c000000(%eax,%eax,1)
  22:	00 00                	add    %al,(%eax)
  24:	00 00                	add    %al,(%eax)
  26:	00 00                	add    %al,(%eax)
  28:	44                   	inc    %esp
  29:	00 10                	add    %dl,(%eax)
  2b:	00 00                	add    %al,(%eax)
  2d:	7c 00                	jl     2f <DATA_SEG_SELECTOR+0x1f>
  2f:	00 00                	add    %al,(%eax)
  31:	00 00                	add    %al,(%eax)
  33:	00 44 00 11          	add    %al,0x11(%eax,%eax,1)
  37:	00 01                	add    %al,(%ecx)
  39:	7c 00                	jl     3b <DATA_SEG_SELECTOR+0x2b>
  3b:	00 00                	add    %al,(%eax)
  3d:	00 00                	add    %al,(%eax)
  3f:	00 44 00 13          	add    %al,0x13(%eax,%eax,1)
  43:	00 02                	add    %al,(%edx)
  45:	7c 00                	jl     47 <DATA_SEG_SELECTOR+0x37>
  47:	00 00                	add    %al,(%eax)
  49:	00 00                	add    %al,(%eax)
  4b:	00 44 00 16          	add    %al,0x16(%eax,%eax,1)
  4f:	00 04 7c             	add    %al,(%esp,%edi,2)
  52:	00 00                	add    %al,(%eax)
  54:	00 00                	add    %al,(%eax)
  56:	00 00                	add    %al,(%eax)
  58:	44                   	inc    %esp
  59:	00 17                	add    %dl,(%edi)
  5b:	00 06                	add    %al,(%esi)
  5d:	7c 00                	jl     5f <DATA_SEG_SELECTOR+0x4f>
  5f:	00 00                	add    %al,(%eax)
  61:	00 00                	add    %al,(%eax)
  63:	00 44 00 18          	add    %al,0x18(%eax,%eax,1)
  67:	00 08                	add    %cl,(%eax)
  69:	7c 00                	jl     6b <DATA_SEG_SELECTOR+0x5b>
  6b:	00 00                	add    %al,(%eax)
  6d:	00 00                	add    %al,(%eax)
  6f:	00 44 00 1c          	add    %al,0x1c(%eax,%eax,1)
  73:	00 0a                	add    %cl,(%edx)
  75:	7c 00                	jl     77 <DATA_SEG_SELECTOR+0x67>
  77:	00 00                	add    %al,(%eax)
  79:	00 00                	add    %al,(%eax)
  7b:	00 44 00 1d          	add    %al,0x1d(%eax,%eax,1)
  7f:	00 0c 7c             	add    %cl,(%esp,%edi,2)
  82:	00 00                	add    %al,(%eax)
  84:	00 00                	add    %al,(%eax)
  86:	00 00                	add    %al,(%eax)
  88:	44                   	inc    %esp
  89:	00 1e                	add    %bl,(%esi)
  8b:	00 0e                	add    %cl,(%esi)
  8d:	7c 00                	jl     8f <DATA_SEG_SELECTOR+0x7f>
  8f:	00 00                	add    %al,(%eax)
  91:	00 00                	add    %al,(%eax)
  93:	00 44 00 20          	add    %al,0x20(%eax,%eax,1)
  97:	00 10                	add    %dl,(%eax)
  99:	7c 00                	jl     9b <DATA_SEG_SELECTOR+0x8b>
  9b:	00 00                	add    %al,(%eax)
  9d:	00 00                	add    %al,(%eax)
  9f:	00 44 00 21          	add    %al,0x21(%eax,%eax,1)
  a3:	00 12                	add    %dl,(%edx)
  a5:	7c 00                	jl     a7 <DATA_SEG_SELECTOR+0x97>
  a7:	00 00                	add    %al,(%eax)
  a9:	00 00                	add    %al,(%eax)
  ab:	00 44 00 24          	add    %al,0x24(%eax,%eax,1)
  af:	00 14 7c             	add    %dl,(%esp,%edi,2)
  b2:	00 00                	add    %al,(%eax)
  b4:	00 00                	add    %al,(%eax)
  b6:	00 00                	add    %al,(%eax)
  b8:	44                   	inc    %esp
  b9:	00 25 00 16 7c 00    	add    %ah,0x7c1600
  bf:	00 00                	add    %al,(%eax)
  c1:	00 00                	add    %al,(%eax)
  c3:	00 44 00 26          	add    %al,0x26(%eax,%eax,1)
  c7:	00 18                	add    %bl,(%eax)
  c9:	7c 00                	jl     cb <DATA_SEG_SELECTOR+0xbb>
  cb:	00 00                	add    %al,(%eax)
  cd:	00 00                	add    %al,(%eax)
  cf:	00 44 00 28          	add    %al,0x28(%eax,%eax,1)
  d3:	00 1a                	add    %bl,(%edx)
  d5:	7c 00                	jl     d7 <DATA_SEG_SELECTOR+0xc7>
  d7:	00 00                	add    %al,(%eax)
  d9:	00 00                	add    %al,(%eax)
  db:	00 44 00 29          	add    %al,0x29(%eax,%eax,1)
  df:	00 1c 7c             	add    %bl,(%esp,%edi,2)
  e2:	00 00                	add    %al,(%eax)
  e4:	00 00                	add    %al,(%eax)
  e6:	00 00                	add    %al,(%eax)
  e8:	44                   	inc    %esp
  e9:	00 2e                	add    %ch,(%esi)
  eb:	00 1e                	add    %bl,(%esi)
  ed:	7c 00                	jl     ef <DATA_SEG_SELECTOR+0xdf>
  ef:	00 00                	add    %al,(%eax)
  f1:	00 00                	add    %al,(%eax)
  f3:	00 44 00 2f          	add    %al,0x2f(%eax,%eax,1)
  f7:	00 23                	add    %ah,(%ebx)
  f9:	7c 00                	jl     fb <DATA_SEG_SELECTOR+0xeb>
  fb:	00 00                	add    %al,(%eax)
  fd:	00 00                	add    %al,(%eax)
  ff:	00 44 00 30          	add    %al,0x30(%eax,%eax,1)
 103:	00 26                	add    %ah,(%esi)
 105:	7c 00                	jl     107 <DATA_SEG_SELECTOR+0xf7>
 107:	00 00                	add    %al,(%eax)
 109:	00 00                	add    %al,(%eax)
 10b:	00 44 00 31          	add    %al,0x31(%eax,%eax,1)
 10f:	00 2a                	add    %ch,(%edx)
 111:	7c 00                	jl     113 <DATA_SEG_SELECTOR+0x103>
 113:	00 00                	add    %al,(%eax)
 115:	00 00                	add    %al,(%eax)
 117:	00 44 00 32          	add    %al,0x32(%eax,%eax,1)
 11b:	00 2d 7c 00 00 00    	add    %ch,0x7c
 121:	00 00                	add    %al,(%eax)
 123:	00 44 00 37          	add    %al,0x37(%eax,%eax,1)
 127:	00 32                	add    %dh,(%edx)
 129:	7c 00                	jl     12b <DATA_SEG_SELECTOR+0x11b>
 12b:	00 00                	add    %al,(%eax)
 12d:	00 00                	add    %al,(%eax)
 12f:	00 44 00 38          	add    %al,0x38(%eax,%eax,1)
 133:	00 36                	add    %dh,(%esi)
 135:	7c 00                	jl     137 <DATA_SEG_SELECTOR+0x127>
 137:	00 00                	add    %al,(%eax)
 139:	00 00                	add    %al,(%eax)
 13b:	00 44 00 39          	add    %al,0x39(%eax,%eax,1)
 13f:	00 38                	add    %bh,(%eax)
 141:	7c 00                	jl     143 <DATA_SEG_SELECTOR+0x133>
 143:	00 00                	add    %al,(%eax)
 145:	00 00                	add    %al,(%eax)
 147:	00 44 00 3a          	add    %al,0x3a(%eax,%eax,1)
 14b:	00 3a                	add    %bh,(%edx)
 14d:	7c 00                	jl     14f <DATA_SEG_SELECTOR+0x13f>
 14f:	00 00                	add    %al,(%eax)
 151:	00 00                	add    %al,(%eax)
 153:	00 44 00 3b          	add    %al,0x3b(%eax,%eax,1)
 157:	00 3c 7c             	add    %bh,(%esp,%edi,2)
 15a:	00 00                	add    %al,(%eax)
 15c:	00 00                	add    %al,(%eax)
 15e:	00 00                	add    %al,(%eax)
 160:	44                   	inc    %esp
 161:	00 3c 00             	add    %bh,(%eax,%eax,1)
 164:	3e 7c 00             	jl,pt  167 <DATA_SEG_SELECTOR+0x157>
 167:	00 00                	add    %al,(%eax)
 169:	00 00                	add    %al,(%eax)
 16b:	00 44 00 3f          	add    %al,0x3f(%eax,%eax,1)
 16f:	00 40 7c             	add    %al,0x7c(%eax)
 172:	00 00                	add    %al,(%eax)
 174:	00 00                	add    %al,(%eax)
 176:	00 00                	add    %al,(%eax)
 178:	44                   	inc    %esp
 179:	00 40 00             	add    %al,0x0(%eax)
 17c:	45                   	inc    %ebp
 17d:	7c 00                	jl     17f <DATA_SEG_SELECTOR+0x16f>
 17f:	00 00                	add    %al,(%eax)
 181:	00 00                	add    %al,(%eax)
 183:	00 44 00 44          	add    %al,0x44(%eax,%eax,1)
 187:	00 4a 7c             	add    %cl,0x7c(%edx)
 18a:	00 00                	add    %al,(%eax)
 18c:	18 00                	sbb    %al,(%eax)
 18e:	00 00                	add    %al,(%eax)
 190:	64 00 02             	add    %al,%fs:(%edx)
 193:	00 1e                	add    %bl,(%esi)
 195:	7e 00                	jle    197 <DATA_SEG_SELECTOR+0x187>
 197:	00 3e                	add    %bh,(%esi)
 199:	00 00                	add    %al,(%eax)
 19b:	00 64 00 02          	add    %ah,0x2(%eax,%eax,1)
 19f:	00 1e                	add    %bl,(%esi)
 1a1:	7e 00                	jle    1a3 <DATA_SEG_SELECTOR+0x193>
 1a3:	00 47 00             	add    %al,0x0(%edi)
 1a6:	00 00                	add    %al,(%eax)
 1a8:	3c 00                	cmp    $0x0,%al
 1aa:	00 00                	add    %al,(%eax)
 1ac:	00 00                	add    %al,(%eax)
 1ae:	00 00                	add    %al,(%eax)
 1b0:	56                   	push   %esi
 1b1:	00 00                	add    %al,(%eax)
 1b3:	00 24 00             	add    %ah,(%eax,%eax,1)
 1b6:	06                   	push   %es
 1b7:	00 1e                	add    %bl,(%esi)
 1b9:	7e 00                	jle    1bb <DATA_SEG_SELECTOR+0x1ab>
 1bb:	00 6a 00             	add    %ch,0x0(%edx)
 1be:	00 00                	add    %al,(%eax)
 1c0:	80 00 00             	addb   $0x0,(%eax)
	...
 1cb:	00 44 00 07          	add    %al,0x7(%eax,%eax,1)
	...
 1d7:	00 24 00             	add    %ah,(%eax,%eax,1)
 1da:	00 00                	add    %al,(%eax)
 1dc:	02 00                	add    (%eax),%al
 1de:	00 00                	add    %al,(%eax)
 1e0:	00 00                	add    %al,(%eax)
 1e2:	00 00                	add    %al,(%eax)
 1e4:	64 00 00             	add    %al,%fs:(%eax)
 1e7:	00 20                	add    %ah,(%eax)
 1e9:	7e 00                	jle    1eb <DATA_SEG_SELECTOR+0x1db>
	...

Disassembly of section .stabstr:

00000000 <.stabstr>:
   0:	00 2f                	add    %ch,(%edi)
   2:	74 6d                	je     71 <DATA_SEG_SELECTOR+0x61>
   4:	70 2f                	jo     35 <DATA_SEG_SELECTOR+0x25>
   6:	63 63 57             	arpl   %sp,0x57(%ebx)
   9:	53                   	push   %ebx
   a:	35 35 45 49 2e       	xor    $0x2e494535,%eax
   f:	73 00                	jae    11 <DATA_SEG_SELECTOR+0x1>
  11:	62 6f 6f             	bound  %ebp,0x6f(%edi)
  14:	74 2e                	je     44 <DATA_SEG_SELECTOR+0x34>
  16:	53                   	push   %ebx
  17:	00 2f                	add    %ch,(%edi)
  19:	68 6f 6d 65 2f       	push   $0x2f656d6f
  1e:	69 6d 77 79 66 2f 6d 	imul   $0x6d2f6679,0x77(%ebp),%ebp
  25:	79 5f                	jns    86 <DATA_SEG_SELECTOR+0x76>
  27:	78 76                	js     9f <DATA_SEG_SELECTOR+0x8f>
  29:	36 5f                	ss pop %edi
  2b:	4f                   	dec    %edi
  2c:	53                   	push   %ebx
  2d:	2f                   	das    
  2e:	73 72                	jae    a2 <DATA_SEG_SELECTOR+0x92>
  30:	63 2f                	arpl   %bp,(%edi)
  32:	62 6f 6f             	bound  %ebp,0x6f(%edi)
  35:	74 6c                	je     a3 <DATA_SEG_SELECTOR+0x93>
  37:	6f                   	outsl  %ds:(%esi),(%dx)
  38:	61                   	popa   
  39:	64 65 72 2f          	fs gs jb 6c <DATA_SEG_SELECTOR+0x5c>
  3d:	00 6c 6f 61          	add    %ch,0x61(%edi,%ebp,2)
  41:	64 65 72 2e          	fs gs jb 73 <DATA_SEG_SELECTOR+0x63>
  45:	63 00                	arpl   %ax,(%eax)
  47:	67 63 63 32          	arpl   %sp,0x32(%bp,%di)
  4b:	5f                   	pop    %edi
  4c:	63 6f 6d             	arpl   %bp,0x6d(%edi)
  4f:	70 69                	jo     ba <DATA_SEG_SELECTOR+0xaa>
  51:	6c                   	insb   (%dx),%es:(%edi)
  52:	65 64 2e 00 6c 6f 61 	gs fs add %ch,%cs:0x61(%edi,%ebp,2)
  59:	64 65 72 3a          	fs gs jb 97 <DATA_SEG_SELECTOR+0x87>
  5d:	46                   	inc    %esi
  5e:	28 30                	sub    %dh,(%eax)
  60:	2c 31                	sub    $0x31,%al
  62:	29 3d 28 30 2c 31    	sub    %edi,0x312c3028
  68:	29 00                	sub    %eax,(%eax)
  6a:	76 6f                	jbe    db <DATA_SEG_SELECTOR+0xcb>
  6c:	69 64 3a 74 28 30 2c 	imul   $0x312c3028,0x74(%edx,%edi,1),%esp
  73:	31 
  74:	29 00                	sub    %eax,(%eax)

Disassembly of section .comment:

00000000 <.comment>:
   0:	47                   	inc    %edi
   1:	43                   	inc    %ebx
   2:	43                   	inc    %ebx
   3:	3a 20                	cmp    (%eax),%ah
   5:	28 55 62             	sub    %dl,0x62(%ebp)
   8:	75 6e                	jne    78 <DATA_SEG_SELECTOR+0x68>
   a:	74 75                	je     81 <DATA_SEG_SELECTOR+0x71>
   c:	20 31                	and    %dh,(%ecx)
   e:	31 2e                	xor    %ebp,(%esi)
  10:	34 2e                	xor    $0x2e,%al
  12:	30 2d 31 75 62 75    	xor    %ch,0x75627531
  18:	6e                   	outsb  %ds:(%esi),(%dx)
  19:	74 75                	je     90 <DATA_SEG_SELECTOR+0x80>
  1b:	31 7e 32             	xor    %edi,0x32(%esi)
  1e:	32 2e                	xor    (%esi),%ch
  20:	30 34 29             	xor    %dh,(%ecx,%ebp,1)
  23:	20 31                	and    %dh,(%ecx)
  25:	31 2e                	xor    %ebp,(%esi)
  27:	34 2e                	xor    $0x2e,%al
  29:	30 00                	xor    %al,(%eax)
