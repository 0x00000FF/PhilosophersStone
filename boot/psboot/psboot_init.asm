; psboot initializer program
; 
; this program enabled protected/IA-32e mode 
; and loads 64bit system directly
;

%define INITIALIZER_BEGIN   0x10000
%define SEGMENT_DATA        0x08
%define SEGMENT_CODE        0x10

[ORG  0x00]
[BITS   16]

SECTION .text
    ; convert and set 0x10000 as segment address
    mov ax, 0x1000  
    mov ds, ax 
    mov es, ax

    ; no more bios interrupt
    cli
    lgdt [GDTR]
    
    ; enter protected mode
    ; no paging, no cache, internal fpu, disable align check
    mov eax, 0x4000003B
    mov cr0, eax         ; set flags to cr0 from eax 

    ; set code segment and jump to protected mode code
    jmp dword SEGMENT_CODE: ( PROTECTED_ENTRY - $$ + INITIALIZER_BEGIN )


[BITS 32]
PROTECTED_ENTRY:
    ; set data segment
    mov ax, SEGMENT_DATA
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; set 64KB stack 
    mov ss, ax
    mov esp, 0xFFFF
    mov ebp, 0xFFFF

    jmp $


GDTR:
    dw GDT_END - GDT - 1                   ; total size of GDT
    dd ( GDT - $$ + INITIALIZER_BEGIN )    ; start address of GDT

GDT:
    ; NULL descriptor
    GDT_NULL:
        dw 0x0000
        dw 0x0000
        db 0x00
        db 0x00
        db 0x00
        db 0x00

    ; data segment descriptor
    ; for protected mode kernel
    GDT_PROTECTED_DATA:
        dw 0xFFFF    ; size [15:0 ]
        dw 0x0000    ; base [15:0 ]
        db 0x00      ; base [23:16]
        db 0x92      ; P=1 DPL=0 DS  Exec/Read
        db 0xCF      ; G=1 D  =1 L=0 size[19:16]
        db 0x00      ; base [31:24] 

    ; code segment descriptor
    ; for protected mode kernel
    GDT_PROTECTED_CODE:
        dw 0xFFFF    ; size [15:0 ]
        dw 0x0000    ; base [15:0 ]
        db 0x00      ; base [23:16]
        db 0x9A      ; P=1 DPL=0 CS  Exec/Read
        db 0xCF      ; G=1 D  =1 L=0 size[19:16]
        db 0x00      ; base [31:24] 

GDT_END:

; align initializer size to 512 bytes
times ( 512 - ($ - $$)) db 0x00
