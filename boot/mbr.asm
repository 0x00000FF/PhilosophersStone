; 16bit Realmode MBR bootloader for PhilosohersStone, x86
; P.Knowledge (knowledge@patche.me)
;
; This bootloader is used for legacy MBR to call PSBoot Application
; UEFI system with GPT partitions doesn't use it
;
; langauge: nasm (intel), i8086
; assemble: nasm mbr.asm
;           nasm -DDO_CLEAR_MBR mbr.asm  (if you need to clear MBR)
;

; segment macro
%define    CODE_SEG    0x07C0
%define    VIDEO_SEG   0xB800
%define    BOOT_SEG    0x1000
%define    STACK_BEGIN 0xFFFF

; macros for partition table
; partition number range is 0-3
%define    P_IS_BOOTABLE    0 
%define    P_CYLINDER       1
%define    P_HEAD           2
%define    P_SECTOR         3
%define    P_PARTITION_TYPE 4

[BITS   16]
[ORG  0x00]

SECTION .text
     sti
     jmp  CODE_SEG:MBR_START

; subroutine: ERROR_HALT
; stops machine when error occured
ERROR_HALT:
     hlt
     jmp ERROR_HALT

; subroutine: CLEAR_SCREEN
; fills the entire video buffer with zeros
CLEAR_SCREEN:
    call RESET_CURSOR    

    push es
    push si

    xor  si, si

_CLEAR_SCREEN_LOOP:
    mov  word [ es:si ], 0x0C00
    add              si, 2
    
    cmp              si, 80 * 25 * 2    
    jl               _CLEAR_SCREEN_LOOP
    
    pop  si
    pop  es
    ret

; subroutine: RESET_CURSOR
; reset cursor position to page 0, col 0, row 0
RESET_CURSOR:
    push ax
    push bx
    push dx

    mov  ax, 0x2
    xor  bx, bx
    xor  dx, dx
    int  0x10

    pop  dx
    pop  bx
    pop  ax
    ret

; subroutine: PRINT_SCREEN
; prints a given string
;
; arg1 : address to string terminated with 0x00
PRINT_SCREEN:
    push bp
    mov  bp, sp

    push ax
    push bx
    push cx
    push dx

    ; teletype service
    mov  ah, 0xE
    xor  bx, bx
    xor  cx, cx
 
    ; set address from arg1
    mov  si, word [bp + 4]

    ; start loop
_PRINT_SCREEN_LOOP:
    mov  dl, byte[si]
    cmp  dl, 0  
    je   _PRINT_SCREEN_END   

    mov  al, dl
    int  0x10
    
    inc  si
    jmp  _PRINT_SCREEN_LOOP

_PRINT_SCREEN_END:
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    pop  bp

    ret

; subroutine: RESET_DISK
; reset the booted disk
RESET_DISK:
    push ax
    push dx

    xor  ax, ax
    xor  dx, dx

    mov  bl, byte[DISK_ID]
    int  0x13
    
    jc   SUB_ERR_RESET_DISK

    pop  dx
    pop  ax
    ret

    SUB_ERR_RESET_DISK:
        push DISK_RESET_ERROR
        call PRINT_SCREEN
        call ERROR_HALT

; subroutine: READ_DISKINFO
; read sector, head, track count from disk
READ_DISKINFO:
    push ax
    push bx
    push cx
    push dx

    mov ah, 0x8
    mov dl, byte[DISK_ID]
    int 0x13

    jc  SUB_ERR_READ_DISKINFO

    ; store returned values to lower byte
    mov  byte  [NUM_TRACK], ch
    mov  byte [NUM_SECTOR], cl
    mov  byte   [NUM_HEAD], dh

    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret

    SUB_ERR_READ_DISKINFO:
        push DISK_READINFO_ERROR
        call PRINT_SCREEN
        call ERROR_HALT

; subroutine: FIND_BOOTSECTOR
; find bootsector to determine where to boot
FIND_BOOTSECTOR:
    ; TODO: iterate partition tables inside of MBR
    ;       determine the partition is bootable or not
    ;       get the first bootable bootsector
    ;       return CHS address of the bootsector

    ret

    SUB_ERR_NO_BOOTABLES:
        push NO_BOOTSECT_ERROR
        call PRINT_SCREEN
        call ERROR_HALT      

; subroutine: READ_BOOTLOADER
; read bootsector 
READ_BOOTLOADER:
    ; TODO: read bootsector into memory from determined CHS
    ;       at FIND_BOOTSECTOR    
    
    ret

    SUB_ERR_READ_BOOTLOADER:
        push DISK_READ_ERROR
        call PRINT_SCREEN
        call ERROR_HALT

; start loading os loader from disk
MBR_START:
    ; store disk identification
    ; BIOS returns disk ID to dl before executing MBR code
    mov byte[DISK_ID], dl

    ; set code and video buffer segments
    mov ax, CODE_SEG
    mov ds, ax
    mov ax, VIDEO_SEG
    mov es, ax

    ; create stack
    xor ax, ax
    mov ss, ax
    mov sp, STACK_BEGIN
    mov bp, STACK_BEGIN

    ; begin clear screen
    call CLEAR_SCREEN

    ; reset disk
    call RESET_DISK 

    ; find bootsector
    call FIND_BOOTSECTOR

    ; read bootloader file from the disk
    call READ_BOOTLOADER

    ; start primary system bootloader
    jmp  BOOT_SEG:0x0000

    ; variables
    DISK_ID:         db 0xFF
    
    NUM_SECTOR:      dw 0x0000
    NUM_HEAD:        dw 0x0000
    NUM_TRACK:       dw 0x0000

    ; constants
    NO_BOOTSECT_ERROR:    db "no bootable disk found", 0x00
    DISK_RESET_ERROR:     db "disk reset error", 0x00
    DISK_READINFO_ERROR:  db "disk read info error", 0x00 
    DISK_READ_ERROR:      db "disk read error", 0x00

; MBR formatting
; This should not be written except 0x55, 0xAA at 511 byte to preserve
; existing partition tables 

%ifdef DO_CLEAR_MBR

times (510 - ($ - $$))       db 0x00
dw    0xAA55                 ;little endian 0x55 0xAA

%endif
