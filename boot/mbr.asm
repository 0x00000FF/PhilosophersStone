; 16bit Realmode MBR bootloader for PhilosohersStone, x86
; P.Knowledge (knowledge@patche.me)
;
; This bootloader is used for legacy MBR to call PSBoot Application
; UEFI system with GPT partitions doesn't use it
;

%define    CODE_SEG    0x07C0
%define    VIDEO_SEG   0xB800
%define    LDR_SEG     0x1000
%define    STACK_BEGIN 0xFFFF

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
    mov  word [ es:si ], 0x0A00
    add              si, 2
    
    cmp              si, 80 * 25 * 2    
    jl               _CLEAR_SCREEN_LOOP
    
    pop  si
    pop  es
    ret

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

    ; teletype service, with light red color
    mov  ah, 0xE
    xor  bx, bx
    xor  cx, cx
    mov  bl, 0xC
 
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

; subroutine: IDENTIFY_DISK
; identifies disk containing currently runing mbr code
IDENTIFY_DISK:
    ret

; subroutine: RESET_DISK
; reset the given disk
RESET_DISK:
    push ax
    push dx

    xor  ax, ax
    xor  bx, bx
    xor  dx, dx
    mov  bl, 0xC
    int  0x13
    
    jc   SUB_ERR_RESET_DISK

    pop  dx
    pop  ax
    ret

    SUB_ERR_RESET_DISK:
        push DISK_RESET_ERROR
        call PRINT_SCREEN
        call ERROR_HALT

; subroutine: READ_BOOTLOADER
;
READ_BOOTLOADER:
    
    ret

    SUB_ERR_READ_BOOTLOADER:
        push DISK_READ_ERROR
        call PRINT_SCREEN
        call ERROR_HALT

MBR_START:
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

    ; identify disk status and reset
    call IDENTIFY_DISK
    call RESET_DISK 

    ; read bootloader file from the disk
    call READ_BOOTLOADER

    ; start primary system bootloader
    jmp  LDR_SEG:0x0000

    ; variables    
    NUM_SECTOR:      dw 0x0000
    NUM_HEAD:        dw 0x0000
    NUM_TRACK:       dw 0x0000

    ; constants
    DISK_RESET_ERROR: db "disk reset error", 0x00
    DISK_READ_ERROR:  db "disk read error", 0x00



; MBR formatting
; This should not be written except 0x55, 0xAA at 511 byte to preserve
; existing partition tables 

times (510 - ($ - $$))       db 0x00
dw    0xAA55                 ;little endian 0x55 0xAA
