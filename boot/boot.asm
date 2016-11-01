;-------------------------------------------------------------------------
;Boot sector
;-------------------------------------------------------------------------
org     0x7c00                      ;Boot状态, BIOS 将把 Boot Sector 加载到 0:7c00 处并开始执行
;-------------------------------------------------------------------------
base_of_stack       equ     0x7c00      ;栈基地址
base_of_loader      equ     0x9000      ;loader.bin 被加载到的位置 - 段地址
offset_of_loader    equ     0x0100      ;loader.bin 被加载到的位置 - 偏移地址
sects_of_root_dir   equ     14          ;根目录占用扇区数
sectno_of_root_dir  equ     19          ;根目录第一个扇区号
sectno_of_fat1      equ     1           ;FAT1 的首个扇区号
delta_sect_no       equ     17          ;用于计算簇号 x 真正的扇区号, 17 = 19 - 2 (减2是因为簇号2对应数据取第1个扇区)
;-------------------------------------------------------------------------
jmp     short   start               ;Start to boot.
nop
;-------------------------------------------------------------------------
%include "fat12hdr.inc"             ;FAT12 磁盘头
;-------------------------------------------------------------------------
start:
    mov     ax,cs
    mov     ds,ax
    mov     es,ax
    mov     ss,ax
    mov     sp,base_of_stack
;text mode, 80*25, 16 colors ---------------------------------------------
    mov     ah,0x00
    mov     al,0x03
    int     0x10
;软驱复位-----------------------------------------------------------------
    xor     ah,ah
    xor     dl,dl
    int     0x13
;在 A 盘根目录寻找 loader.bin --------------------------------------------
    mov     word[temp_read_sectno],sectno_of_root_dir
;-------------------------------------------------------------------------
search_in_root:
    cmp     word[temp_sects_of_root],0              ;判断根目录是否已经读完
    jz      loader_not_found                        ;如果读完表示没找到 loader.bin
    dec     word[temp_sects_of_root]
    mov     ax,base_of_loader
    mov     es,ax
    mov     bx,offset_of_loader                 ;存放的位置 es:bx
    mov     ax,[temp_read_sectno]               ;要读取的扇区
    mov     cl,1                                ;读一个扇区
    call    read_sector
    mov     si,loader_filename                  ;ds:si -> "LOADER  BIN"
    mov     di,offset_of_loader                 ;es:di -> base_of_loader : offset_of_loader
    cld
    mov     dx,0x10                             ;0x0200 / 0x20 = 0x10, 即每个扇区需要读 16 次 大小位 32 字节的条目
;-----------------------------------------------------
search_loader:
    cmp     dx,0                                ;判断是否已经比较完 16 个条目
    jz      next_sector                         ;下一个扇区
    dec     dx
    mov     cx,11
;---------------------------------
cmp_filename:
    cmp     cx,0
    jz      loader_found                        ;已经比较完 11 个 字符, 说明找到了 loader.bin
    dec     cx
    lodsb                                       ;ds:si -> al
    cmp     al,byte[es:di]                      ;被加载到 es:di 的文件的文件名
    jz      cmp_next_char
    jmp     different_name
;---------------------------------
cmp_next_char:
    inc     di                                  ;指向下一个字符
    jmp     cmp_filename
;-----------------------------------------------------
different_name:
    and     di,0xffe0                           ;指向本条目开头
    add     di,0x20                             ;下一条目
    mov     si,loader_filename                  ;重新指向 LOADER  BIN 头部
    jmp     search_loader                       ;
;-----------------------------------------------------
next_sector:
    add     word[temp_read_sectno],1
    jmp     search_in_root
;-------------------------------------------------------------------------
loader_not_found:
    mov     si,msg_loader_not_found
    call    print16
    jmp     $                                   ;找不到 loader.bin, 暂且死循环在此
;找到loader---------------------------------------------------------------
loader_found:
    mov     si,msg_loader_found
    call    print16
    mov     si,msg_booting
    call    print16
    and     di,0xffe0               ;di -> 当前条目的开头
    add     di,0x1a                 ;di -> 此条目对应的开始簇号, 偏移 0x1a
    mov     cx,word[es:di]          ;cx <- 此条目对应的开始簇号
    push    cx                      ;保存该簇号
    add     cx,sects_of_root_dir    ;簇号+14
    add     cx,delta_sect_no        ;簇号+17, 至此得到当前条目的起始扇区号
    mov     ax,base_of_loader
    mov     es,ax                   ;es <- base_of_loader
    mov     bx,offset_of_loader     ;bx <- offset_of_loader
    mov     ax,cx                   ;ax <- loader.bin 起始扇区号
;-------------------------------------------------------------------------
go_on_loading:
    mov     si,msg_dot
    call    print16                 ;每读一个扇区就在"Booting"后面打一个点
;------------------------------------------------------
    mov     cl,1                    ;读取一个扇区
    call    read_sector             ;根据 ax, 读取扇区
    pop     ax                      ;取出此扇区对应的 FAT 中的簇号
    call    get_fat_entry           ;由簇号得到对应 FAT 项内容, 保存于 ax
    cmp     ax,0x0fff               ;是否 loader.bin 最后一个扇区
    jz      loader_loaded
    push    ax                      ;保存 FAT 内容
    add     ax,sects_of_root_dir    ;+14
    add     ax,delta_sect_no        ;+17
    add     bx,[BPB_BytsPerSec]     ;bx + 512
    jmp     go_on_loading
;-------------------------------------------------------------------------
loader_loaded:
    mov     si,msg_loader_loaded
    call    print16
;跳转到 loader.bin--------------------------------------------------------
    jmp     base_of_loader:offset_of_loader
;打印字符串---------------------------------------------------------------
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
;加载文件到内存-----------------------------------------------------------
read_sector:
    push    bp
    mov     bp,sp
    sub     esp,2                   ;两个字节的空间用于保存要读取的扇区数
    mov     byte[bp-2],cl
    push    bx
    mov     bl,[BPB_SecPerTrk]
    div     bl                      ;商存在 al, 余数存在 ah
    inc     ah                      ;得到起始扇区号
    mov     cl,ah                   ;cl <- 起始扇区号
    mov     dh,al                   ;保存商
    shr     al,1                    ;得到柱面号
    mov     ch,al                   ;ch <- 柱面号
    and     dh,1                    ;dh <- 磁头号
    pop     bx
    mov     dl,[BS_DrvNum]          ;驱动器号 0
retry:
    mov     ah,2
    mov     al,byte[bp-2]
    int     0x13
    jc      retry                   ;如果读取出错, 重新读取
    add     esp,2                   ;读取成功, 恢复栈
    pop     bp
    ret
;找到 ax 对应的 FAT 项, 结果放在 ax --------------------------------------
get_fat_entry:
    push    es
    push    bx
    push    ax
    mov     ax,base_of_loader
    sub     ax,0x0100               ;在 base_of_loader 后面开辟出 4K 空间
    mov     es,ax
;---------------------------------------------------
    pop     ax
    mov     byte[is_odd],0
    mov     bx,3
    mul     bx                      ;dx:ax = ax * 3
    mov     bx,2
    div     bx                      ;dx:ax / 2 => ax <- 商, dx <- 余
    cmp     dx,0
    jz      even
    mov     byte[is_odd],1
;至此, ax 内容是 FAT 项簇号在 FAT 中的偏移量--------
even:
    xor     dx,dx
    mov     bx,[BPB_BytsPerSec]
    div     bx                      ;ax 为相对于 FAT 扇区的扇区号, dx 为偏移
    push    dx                      ;保存偏移
    mov     bx,0
    add     ax,sectno_of_fat1       ;ax 为 FAT 项扇区号
    mov     cl,2
    call    read_sector             ;一次读 2 扇区, 防止 FAT 项跨扇区
    pop     dx
    add     bx,dx                   ;es:bx -> FAT 项内容
    mov     ax,[es:bx]              ;ax 即为函数输出
;---------------------------------------------------
    cmp     byte[is_odd],1
    jnz     even_still
    shr     ax,4
even_still:
    and     ax,0x0fff
;---------------------------------------------------
get_fat_entry_ok:
    pop     bx
    pop     es
    ret
;变量---------------------------------------------------------------------
temp_sects_of_root  dw  sects_of_root_dir   ;根目录占用扇区数
temp_read_sectno    dw  0                   ;要读取的扇区号
loader_filename     db  "LOADER  BIN",0     ;loader.bin 的 DIR_NAME
is_odd              db  0                   ;是否奇数
;字符串-------------------------------------------------------------------
msg_loader_not_found:
    db "Loader not found.",13,10,0
msg_loader_found:
    db "Loader found.",13,10,0
msg_booting:
    db "Booting",0
msg_dot:
    db ".",0
msg_loader_loaded:
    db 13,10,"Loader loaded.",13,10,0
;-------------------------------------------------------------------------
times   510-($-$$)  db  0           ;填充剩余空间
dw      0xaa55                      ;boot sector 标志
