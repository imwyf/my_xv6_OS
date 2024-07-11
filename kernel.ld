OUTPUT_FORMAT("elf32-i386", "elf32-i386", "elf32-i386")
OUTPUT_ARCH(i386)
ENTRY(_start)

SECTIONS
{
	/* 内核期望自身被加载到 0xC0100000 的虚拟地址处，因此这里设置 ld 应该链接的地址为 0xC0100000，相当于指定 e_entry = 0xC0100000 */
	. = 0xC0100000;

	.text : AT(0x100000) { /* AT指令指示 ld 将 text 段链接到 0x100000 的物理地址处 */
		*(.text .stub .text.* .gnu.linkonce.t.*)
	}

	/* PROVIDE 指令向外部文件（.c .S 等）提供该标志，可被当作地址使用 */
	/* etext标志：文本段末尾 */
	PROVIDE(etext = .);	

	.rodata : {
		*(.rodata .rodata.* .gnu.linkonce.r.*)
	}

	/* stab段：调试信息 */
	.stab : {
		PROVIDE(__STAB_BEGIN__ = .);
		*(.stab);
		PROVIDE(__STAB_END__ = .);
	}
	/* stabstr段：调试信息 */
	.stabstr : {
		PROVIDE(__STABSTR_BEGIN__ = .);
		*(.stabstr);
		PROVIDE(__STABSTR_END__ = .);
	}

	/* 将数据段对齐到下一页（即使其另起一页） */
	. = ALIGN(0x1000);

	/* 数据段开始标志 */
	PROVIDE(data = .);

	.data : {
		*(.data)
	}

	/* 数据段结束标志 */
	PROVIDE(edata = .);

	.bss : {
		*(.bss)
	}

	/* bss结束标志，也即 ELF 结束标志，因为其他不需要的段被下一个指令丢弃了 */
	PROVIDE(end = .);

	/DISCARD/ : {
		*(.eh_frame .note.GNU-stack)
	}
}
