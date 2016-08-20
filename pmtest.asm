;==========================================
;pmtest.asm
;编译方法: nasm pmtest.asm -o pmtest.bin
;==========================================

%include	"pm.inc"	;常量，宏，以及一些说明

org	0100h
	jmp	LABEL_BEGIN

[SECTION .gdt]
;GDT
;					段基址		段界限			属性
LABEL_GDT:		Descriptor	0,		0,			0		;空描述符
LABEL_DESC_NORMAL:	Descriptor	0,		0FFFFh,			DA_DRW		;Normal描述符
LABEL_DESC_CODE32:	Descriptor	0,		SegCode32Len - 1,	DA_C + DA_32	;非一致代码段，32位
LABEL_DESC_CODE16:	Descriptor	0,		0FFFFh,			DA_C		;非一致代码段，16位
LABEL_DESC_CODE_DEST:	Descriptor	0,		SegCodeDestLen - 1,	DA_C + DA_32	;非一致代码段，32位
LABEL_DESC_CODE_RING3:	Descriptor	0,		SegCodeRing3Len - 1,	DA_C + DA_32 + DA_DPL3
LABEL_DESC_DATA:	Descriptor	0,		DataLen - 1,		DA_DRW		;数据段
LABEL_DESC_STACK:	Descriptor	0,		TopOfStack,		DA_DRWA + DA_32	;栈，32位
LABEL_DESC_STACK3:	Descriptor	0,		TopOfStack3,		DA_DRWA + DA_32 + DA_DPL3
LABEL_DESC_LDT:		Descriptor	0,		LDTLen - 1,		DA_LDT		;LDT
LABEL_DESC_TSS:		Descriptor	0,		TSSLen - 1,		DA_386TSS
LABEL_DESC_VIDEO:	Descriptor	0B8000h,	0FFFFh,			DA_DRW + DA_DPL3;显存首地址

;门------------------------目标选择子		偏移	DCount	属性
LABEL_CALL_GATE_TEST: Gate SelectorCodeDest,	0,	0,	DA_386CG + DA_DPL3

;GDT结束

GdtLen		equ	$ - LABEL_GDT	;GDT长度
GdtPtr		dw	GdtLen - 1	;GDT界限
		dd	0		;GDT基地址

;GDT选择子
SelectorNormal		equ	LABEL_DESC_NORMAL - LABEL_GDT
SelectorCode32		equ	LABEL_DESC_CODE32 - LABEL_GDT
SelectorCode16		equ	LABEL_DESC_CODE16 - LABEL_GDT
SelectorCodeDest	equ	LABEL_DESC_CODE_DEST - LABEL_GDT
SelectorCodeRing3	equ	LABEL_DESC_CODE_RING3 - LABEL_GDT + SA_RPL3
SelectorData		equ	LABEL_DESC_DATA - LABEL_GDT
SelectorStack		equ	LABEL_DESC_STACK - LABEL_GDT
SelectorStack3		equ	LABEL_DESC_STACK3 - LABEL_GDT + SA_RPL3
SelectorTSS		equ	LABEL_DESC_TSS - LABEL_GDT
SelectorLDT		equ	LABEL_DESC_LDT - LABEL_GDT
SelectorVideo		equ	LABEL_DESC_VIDEO - LABEL_GDT

SelectorCallGateTest	equ	LABEL_CALL_GATE_TEST - LABEL_GDT + SA_RPL3
;END of [SECTION .gdt]

[SECTION .data1]	;数据段
ALIGN 32		;数据对齐
[BITS 32]		;指定目标处理器模式为32位
LABEL_DATA:
SPValueInRealMode	dw 0
;字符串
PMMessage:		db "In Protect Mode now.",0		;在保护模式中显示
OffsetPMMessage		equ PMMessage - $$
StrTest:		db "Test LDT and I hate ASM.",0
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

;堆栈段ring3
[SECTION .s3]
ALIGN 32
[BITS 32]
LABEL_STACK3:
	times 512 db 0
TopOfStack3	equ	$ - LABEL_STACK3 - 1
;END of [SECTION .s3]

;TSS
[SECTION .tss]
ALIGN 32
[BITS 32]
LABEL_TSS:
	DD	0			;Back
	DD	TopOfStack		;0级堆栈
	DD	SelectorStack		;
	DD	0			;1级堆栈
	DD	0			;
	DD	0			;2级堆栈
	DD	0			;
	DD	0			;CR3
	DD	0			;EIP
	DD	0			;EFLAGS
	DD	0			;EAX
	DD	0			;ECS
	DD	0			;EDX
	DD	0			;EBX
	DD	0			;ESP
	DD	0			;EBP
	DD	0			;ESI
	DD	0			;EDI
	DD	0			;ES
	DD	0			;CS
	DD	0			;SS
	DD	0			;DS
	DD	0			;FS
	DD	0			;GS
	DD	0			;LDT
	DW	0		;调试陷阱标志
	DW	$ - LABEL_TSS + 2	;I/O位图基址
	DB	0FFh			;I/O位图结束标志
TSSLen	equ	$ - LABEL_TSS

[SECTION .s16]
[BITS 16]		;指定目标处理器模式位16位
LABEL_BEGIN:
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	mov	ss,ax
	mov	sp,0100h

	mov	[LABEL_GO_BACK_TO_REAL + 3],ax
	mov	[SPValueInRealMode],sp

	;初始化16位代码段描述符
	mov	ax,cs
	movzx	eax,ax
	shl	eax,4
	add	eax,LABEL_SEG_CODE16
	mov	word[LABEL_DESC_CODE16 + 2],ax
	shr	eax,16
	mov	byte[LABEL_DESC_CODE16 + 4],al
	mov	byte[LABEL_DESC_CODE16 + 7],ah

	;初始化32位代码段描述符，填充段基址，即2，3，4，7这4个字节
	xor	eax,eax
	mov	ax,cs
	shl	eax,4
	add	eax,LABEL_SEG_CODE32
	mov	word[LABEL_DESC_CODE32 + 2],ax
	shr	eax,16
	mov	byte[LABEL_DESC_CODE32 + 4],al
	mov	byte[LABEL_DESC_CODE32 + 7],ah
	
	;初始化测试调用门的代码段描述符
	xor	eax,eax
	mov	ax,cs
	shl	eax,4
	add	eax,LABEL_SEG_CODE_DEST
	mov	word[LABEL_DESC_CODE_DEST + 2],ax
	shr	eax,16
	mov	byte[LABEL_DESC_CODE_DEST + 4],al
	mov	byte[LABEL_DESC_CODE_DEST + 7],ah

	;初始化数据段描述符
	xor	eax,eax
	mov	ax,ds
	shl	eax,4
	add	eax,LABEL_DATA
	mov	word[LABEL_DESC_DATA + 2],ax
	shr	eax,16
	mov	byte[LABEL_DESC_DATA + 4],al
	mov	byte[LABEL_DESC_DATA + 7],ah

	;初始化堆栈段描述符
	xor	eax,eax
	mov	ax,ds
	shl	eax,4
	add	eax,LABEL_STACK
	mov	word [LABEL_DESC_STACK + 2],ax
	shr	eax,16
	mov	byte[LABEL_DESC_STACK + 4],al
	mov	byte[LABEL_DESC_STACK + 7],ah

	;初始化堆栈段描述符Ring3
	xor	eax,eax
	mov	ax,ds
	shl	eax,4
	add	eax,LABEL_STACK3
	mov	word[LABEL_DESC_STACK3 + 2],ax
	shr	eax,16
	mov	byte[LABEL_DESC_STACK3 + 4],al
	mov	byte[LABEL_DESC_STACK3 + 7],ah

	;初始化LDT在GDT中的描述符
	xor	eax,eax
	mov	ax,ds
	shl	eax,4
	add	eax,LABEL_LDT
	mov	word[LABEL_DESC_LDT + 2],ax
	shr	eax,16
	mov	byte[LABEL_DESC_LDT + 4],al
	mov	byte[LABEL_DESC_LDT + 7],ah

	;初始化LDT中的描述符
	xor	eax,eax
	mov	ax,ds
	shl	eax,4
	add	eax,LABEL_CODE_A
	mov	word[LABEL_LDT_DESC_CODEA + 2],ax
	shr	eax,16
	mov	byte[LABEL_LDT_DESC_CODEA + 4],al
	mov	byte[LABEL_LDT_DESC_CODEA + 7],ah
	
	;初始化Ring3描述符
	xor	eax,eax
	mov	ax,ds
	shl	eax,4
	add	eax,LABEL_CODE_RING3
	mov	word[LABEL_DESC_CODE_RING3 + 2],ax
	shr	eax,16
	mov	byte[LABEL_DESC_CODE_RING3 + 4],al
	mov	byte[LABEL_DESC_CODE_RING3 + 7],ah

	;初始化TSS描述符
	xor	eax,eax
	mov	ax,ds
	shl	eax,4
	add	eax,LABEL_TSS
	mov	word[LABEL_DESC_TSS + 2],ax
	shr	eax,16
	mov	byte[LABEL_DESC_TSS + 4],al
	mov	byte[LABEL_DESC_TSS + 7],ah

	;为加载GDTR作准备
	xor	eax,eax
	mov	ax,ds
	shl	eax,4
	add	eax,LABEL_GDT				;eax<-GDT基地址
	mov	dword[GdtPtr + 2],eax			;[GdtPtr + 2]<-GDT基地址

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
;--------------------------------------------------------并跳转到 SelectorCode32:0 处

LABEL_REAL_ENTRY:					;从保护模式跳回到这里
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	mov	ss,ax

	mov	sp,[SPValueInRealMode]

	in	al,92h
	and	al,11111101b
	out	92h,al

	sti

	mov	ax,4C00h
	int	21h
;END of [SECTION .s16]

[SECTION .s32]		;32位代码段，由实模式跳入
[BITS 32]

LABEL_SEG_CODE32:
	mov	ax,SelectorData
	mov	ds,ax					;数据段选择子
	mov	ax,SelectorVideo
	mov	gs,ax					;视频段选择子(目的)
	mov	ax,SelectorStack
	mov	ss,ax					;堆栈段选择子
	mov	esp,TopOfStack
	
	;下面显示一个字符串
	mov	ah,0Ch					;0000:黑底	1100:红字
	xor	esi,esi
	xor	edi,edi
	mov	esi,OffsetPMMessage			;源数据偏移地址
	mov	edi,(80 * 10 + 0) * 2			;目的数据偏移量。屏幕第10行，第0列。
	cld						;标志寄存器FLAGD方向标志位DF置0，字符串处理由前往后
.1:
	lodsb
	test	al,al
	jz	.2
	mov	[gs:edi],ax
	add	edi,2
	jmp	.1
.2:	;显示完毕
	
	call	DispReturn
	
	mov	ax,SelectorTSS
	ltr	ax			;装载任务状态段寄存器TR

	push	SelectorStack3
	push	TopOfStack3
	push	SelectorCodeRing3
	push	0
	retf

	ud2	;

	;调用测试门（无特权级变换），将打印字母'C'
	call	SelectorCallGateTest:0

	;Load LDT
	mov	ax,SelectorLDT
	lldt	ax

	jmp	SelectorLDTCodeA:0			;跳入局部任务

;---------------------------------------------------------------------------
DispReturn:				;将edi指向下一行
	push	eax
	push	ebx
	mov	eax,edi			
	mov	bl,160
	div	bl
	and	eax,0FFh		;保留后8位即al(商)
	inc	eax
	mov	bl,160
	mul	bl
	mov	edi,eax			;得到下一行地址
	pop	ebx
	pop	eax

	ret
;DispReturn结束--------------------------------------------------------------------------

SegCode32Len	equ	$ - LABEL_SEG_CODE32
;END of [SECTION .s32]

[SECTION .sdest]	;调用门目标段
[BITS 32]
LABEL_SEG_CODE_DEST:
	mov	ax,SelectorVideo
	mov	gs,ax

	mov	edi,(80 * 12 + 0) * 2
	mov	ah,0Ch
	mov	al,'C'
	mov	[gs:edi],ax
	
	;Load LDT
	mov	ax,SelectorLDT
	lldt	ax
	jmp	SelectorLDTCodeA:0	;跳入局部任务，打印字母'L'

SegCodeDestLen	equ	$ - LABEL_SEG_CODE_DEST
;END of [SECTION .sdest]


;16位代码段。由32位代码段跳入，跳出后到实模式
[SECTION .s16code]
ALIGN 32
[BITS 16]
LABEL_SEG_CODE16:
	mov	ax,SelectorNormal
	mov	ds,ax
	mov	es,ax
	mov	fs,ax
	mov	gs,ax
	mov	ss,ax

	mov	eax,cr0
	and	al,11111110b
	mov	cr0,eax

LABEL_GO_BACK_TO_REAL:
	jmp	0:LABEL_REAL_ENTRY		;段地址会在程序开始处被设置成正确的值

Code16Len	equ	$ - LABEL_SEG_CODE16

;END of [SECTION .s16code]

;LDT
[SECTION .ldt]
ALIGN 32
LABEL_LDT:
;					段基址	段界限		属性
LABEL_LDT_DESC_CODEA:	Descriptor	0,	CodeALen - 1,	DA_C + DA_32	;代码段，32位

LDTLen	equ	$ - LABEL_LDT

;LDT选择子
SelectorLDTCodeA	equ	LABEL_LDT_DESC_CODEA - LABEL_LDT + SA_TIL
;END of [SECTION .ldt]

;CodeA: LDT，32位代码段
[SECTION .la]
ALIGN 32
[BITS 32]
LABEL_CODE_A:
	mov	ax,SelectorVideo
	mov	gs,ax				;视频段选择子(目的)

	mov	edi,(80 * 13 + 0) * 2		;屏幕第10行，第0列
	mov	ah,0Ch				;0000:黑底	1100:红字
	mov	al,'L'
	mov	[gs:edi],ax

	;准备经由16位代码段跳回实模式
	jmp	SelectorCode16:0
CodeALen	equ	$ - LABEL_CODE_A
;END of [SECTION .la]

;CodeRing3
[SECTION .ring3]
ALIGN 32
[BITS 32]
LABEL_CODE_RING3:
	mov	ax,SelectorVideo
	mov	gs,ax

	mov	edi,(80 * 14 + 0) * 2
	mov	ah,0Ch
	mov	al,'3'
	mov	[gs:edi],ax
	
	call	SelectorCallGateTest:0

	jmp	$
SegCodeRing3Len	equ	$ - LABEL_CODE_RING3
;END of [SECTION .ring3]
