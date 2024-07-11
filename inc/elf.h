#ifndef _ELF_H_
#define _ELF_H_

#include "types.h"

#define EI_NIDENT (16)

typedef struct
{
    unsigned char e_ident[EI_NIDENT]; /* Magic number and other info */
    uint16_t e_type; /* Object file type */
    uint16_t e_machine; /* Architecture */
    uint32_t e_version; /* Object file version */
    uint32_t e_entry; /* Entry point virtual address */
    uint32_t e_phoff; /* Program header table file offset */
    uint32_t e_shoff; /* Section header table file offset */
    uint32_t e_flags; /* Processor-specific flags */
    uint16_t e_ehsize; /* ELF header size in bytes */
    uint16_t e_phentsize; /* Program header table entry size */
    uint16_t e_phnum; /* Program header table entry count */
    uint16_t e_shentsize; /* Section header table entry size */
    uint16_t e_shnum; /* Section header table entry count */
    uint16_t e_shstrndx; /* Section header string table index */
} Elf32_Ehdr;

typedef struct
{
    uint32_t p_type; /* Segment type */
    uint32_t p_offset; /* Segment file offset */
    uint32_t p_vaddr; /* Segment virtual address */
    uint32_t p_paddr; /* Segment physical address */
    uint32_t p_filesz; /* Segment size in file */
    uint32_t p_memsz; /* Segment size in memory */
    uint32_t p_flags; /* Segment flags */
    uint32_t p_align; /* Segment alignment */
} Elf32_Phdr;

typedef struct
{
    uint32_t sh_name; /* Section name (string tbl index) */
    uint32_t sh_type; /* Section type */
    uint32_t sh_flags; /* Section flags */
    uint32_t sh_addr; /* Section virtual addr at execution */
    uint32_t sh_offset; /* Section file offset */
    uint32_t sh_size; /* Section size in bytes */
    uint32_t sh_link; /* Link to another section */
    uint32_t sh_info; /* Additional section information */
    uint32_t sh_addralign; /* Section alignment */
    uint32_t sh_entsize; /* Entry size if section holds table */
} Elf32_Shdr;

// Values for Proghdr::p_type
#define ELF_PROG_LOAD 1

// Flag bits for Proghdr::p_flags
#define ELF_PROG_FLAG_EXEC 1
#define ELF_PROG_FLAG_WRITE 2
#define ELF_PROG_FLAG_READ 4

// Values for Secthdr::sh_type
#define ELF_SHT_NULL 0
#define ELF_SHT_PROGBITS 1
#define ELF_SHT_SYMTAB 2
#define ELF_SHT_STRTAB 3

// Values for Secthdr::sh_name
#define ELF_SHN_UNDEF 0

#endif /* !_ELF_H_ */
