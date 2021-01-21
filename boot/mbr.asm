; MBR bootloader for PhilosohersStone
; P.Knowledge (knowledge@patche.me)
;
; This bootloader is used for legacy MBR to call PSBoot Application
; UEFI system with GPT partitions doesn't use it
;


; MBR formatting
times 510 - ($$ - $)        db 0x00
dw 0x55AA
