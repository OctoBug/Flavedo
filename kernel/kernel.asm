;-------------------------------------------------------------------------
[section .text]                     ;代码段
;-------------------------------------------------------------------------
global _start                       ;导出 _start
_start:                             ;
    mov     ax,cs
    mov     ds,ax
    mov     es,ax
    mov     ss,ax
    mov     si,msg_kernel
    call    print16
;-------------------------------------------------------------------------
print16:                            ;from @LastAvengers
    push    ax
    push    bx
disp:
    lodsb                           ;ds:si -> al
    or      al,al
    jz      done
    mov     ah,0x0e                 ;光标随着字符移动
    mov     bx,15                   ;白字
    int     0x10
    jmp     disp
done:
    pop     bx
    pop     ax
    ret
;-------------------------------------------------------------------------
msg_kernel:
    db "i'm kernel",13,10,0
