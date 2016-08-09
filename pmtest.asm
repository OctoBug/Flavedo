;==========================================
;pmtest.asm
;编译方法: nasm pmtest.asm -o pmtest.bin
;==========================================

%include	"pm.inc"	;常量，宏，以及一些说明

org	0100h
	jmp	LABEL_BEGIN

[SECTION .gdt]
;GDT
;					段基址		段界限		属性
LABEL_GDT:		Descriptor	0,		0,		0		;空描述符
LABEL_DESC_NORMAL:	Descriptor	0,		0FFFFh,		DA_DRW		;Normal描述符
LABEL_DESC_CODE32:	Descriptor	0,		SegCode32Len-1,	DA_C + DA_32	;非一致代码段，32位
LABEL_DESC_CODE16:	Descriptor	0,		0FFFFh,		DA_C		;非一致代码段，16位
LABEL_DESC_DATA:	Descriptor	0,		DataLen-1,	DA_DRW		;数据段
LABEL_DESC_STACK:	Descriptor	0,		TopOfStack,	DA_DRWA+DA_32	;栈，32位
LABEL_DESC_TEST:	Descriptor	0500000h,	0FFFFh,		DA_DRW		;测试段
LABEL_DESC_VIDEO:	Descriptor	0B8000h,	0FFFFh,		DA_DRW		;显存首地址
;GDT结束

GdtLen		equ	$ - LABEL_GDT	;GDT长度
GdtPtr		dw	GdtLen - 1	;GDT界限
		dd	0		;GDT基地址

;GDT选择子
SelectorNormal		equ	LABEL_DESC_NORMAL - LABEL_GDT
SelectorCode32		equ	LABEL_DESC_CODE32 - LABEL_GDT
SelectorCode16		equ	LABEL_DESC_CODE16 - LABEL_GDT
SelectorData		equ	LABEL_DESC_DATA - LABEL_GDT
SelectorStack		equ	LABEL_DESC_STACK - LABEL_GDT
SelectorTest		equ	LABEL_DESC_TEST - LABEL_GDT
SelectorVideo		equ	LABEL_DESC_VIDEO - LABEL_GDT
;END of [SECTION .gdt]

[SECTION .data1]	;数据段
ALIGN 32
[BITS 32]		;指定目标处理器模式为32位
LABEL_DATA:
SPValueInRealMode	dw 0
;字符串
PMMessage:		db "In Protect Mode now.",0		;在保护模式中显示
OffsetPMMessage		equ PMMessage - $$
StrTest:		db "ABCDEFGHIJKLMNOPQRSTUVWXYZ",0
OffsetStrTest		equ StrTest - $$
DataLen			equ $ - LABEL_DATA
;END of [SECTION .data1]

;全局堆栈段
[SECTION .gs]
ALIGN 32
[BITS 32]
LABEL_STACK:		times 512 db 0
TopOfStack		equ $ - LABEL_STACK - 1
;END of [SECTION .gs]

[SECTION .s16]
[BITS 16]		;指定目标处理器模式位16位
LABEL_BEGIN:
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	mov	ss,ax
	mov	sp,0100h

	;初始化32位代码段描述符，填充段基址，即2，3，4，7这4个字节
	xor	eax,eax
	mov	ax,cs
	shl	eax,4
	add	eax,LABEL_SEG_CODE32
	mov	word [LABEL_DESC_CODE32 + 2],ax
	shr	eax,16
	mov	byte [LABEL_DESC_CODE32 + 4],al
	mov	byte [LABEL_DESC_CODE32 + 7],ah

	;为加载GDTR作准备
	xor	eax,eax
	mov	ax,ds
	shl	eax,4
	add	eax,LABEL_GDT				;eax<-GDT基地址
	mov	dword [GdtPtr + 2],eax			;[GdtPtr + 2]<-GDT基地址

	;加载GDTR
	lgdt	[GdtPtr]

	;关中断
	cli

	;打开地址现A20
	in	al,92h
	or	al,00000010b
	out	92h,al

	;准备切换到保护模式
	mov	eax,cr0
	or	eax,1
	mov	cr0,eax

	;真正进入保护模式
	jmp	dword SelectorCode32:0			;执行这一句会把 SelectorCode32 装入cs,
							;并跳转到 SelectorCode32:0 处
;END of [SECTION .s16]

[SECTION .s32]		;32位代码段，由实模式跳入
[BITS 32]

LABEL_SEG_CODE32:
	mov	ax,SelectorVideo
	mov	gs,ax					;视频段选择子(目的)
	
	mov	edi,(80 * 11 + 79) * 2			;屏幕第11行，第79列
	mov	ah,0Ch
	mov	al,'P'
	mov	[gs:edi],ax

	;到此停止
	jmp	$

SegCode32Len	equ	$ - LABEL_SEG_CODE32
;END of [SECTION .s32]