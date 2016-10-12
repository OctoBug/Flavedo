;-------------------------------------------------------------------------
;Boot sector
;-------------------------------------------------------------------------
org     0x7c00                      ;Boot状态, BIOS 将把 Boot Sector 加载到 0:7c00 处并开始执行

jmp     short   start               ;Start to boot.
nop

%include "fat12hdr.inc"             ;FAT12 磁盘头
;-------------------------------------------------------------------------
start:
    mov     ax,cs
    mov     ds,ax
    mov     es,ax
    
    ;text mode, 80*25, 16 colors
    mov     ah,0x00
    mov     al,0x03
    int     0x10

    mov     si,msg_boot
    call    print16
;-------------------------------------------------------------------------

print16:                            ;from @LastAvengers
disp:
    lodsb                           ;ds:si -> al
    or      al,al
    jz      done
    mov     ah,0x0e                 ;光标随着字符移动
    mov     bx,15                   ;白字
    int     0x10
    jmp     disp
done:
    ret

;-------------------------------------------------------------------------
msg_boot:
    db  "Boot Sector loaded.",13,10,0
;-------------------------------------------------------------------------
times   510-($-$$)  db  0           ;填充剩余空间
dw      0xaa55                      ;boot sector 标志
