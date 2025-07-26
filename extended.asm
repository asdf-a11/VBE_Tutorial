[bits 16]
[org 0x7e00]





kernal_start_label:

kernal_sector_size: dd 0xffffffff ; set by external script
kernal_offset:
jmp start

TM equ 0xb8000
failed_to_get_VESA_info: db "Failed to fill es:di with SuperVGA(VBE).", 10, 0
failed_to_set_VESA: db "Failed to find VESA video setting that works.", 10, 0
booted_to_kernal_msg: db "Kernal starting." ,10 ,0
enable_A20_line_msg: db "Enabled A20 line.", 10, 0

BIOS_MoveCursor:;cl is move count
	pushad
	;get cursor position
	push cx
	mov bh, 0
	mov ah, 0x3
	int 0x10
	pop cx
	;set new position
	mov ah, 0x2
	add dl, cl
	int 0x10
	popad
	ret
BIOS_Print:; al as character
	pushad
	mov cx, 1		
	;print character
	mov ah, 0xA
	mov bh, 0
	int 0x10
	;update cursor
	call BIOS_MoveCursor
	popad
	ret
BIOS_PrintString:;di is string ptr
	pushad
	.loop:
		mov al, byte[di]
		cmp al, 0
		je .endLoop		
		call BIOS_Print		
		inc di
		jmp .loop	
	.endLoop:
	popad
	ret
remap_pic:
	;page 156 of 539 kernal
	mov al, 0x11
	out 0x20, al;sent init command to pic master
	out 0xa0, al;send init command to pic slave
	
	mov al, 32
	out 0x21, al; iqr start at 32 in pic master
	
	mov al, 40
	out 0xa1, al; iqr start at 40 in pic slave
	
	mov al, 0x4; tells pic master where pic slave is connected
	out 0x21, al
	
	mov al, 0x2; tells pic slave where pic master is connected
	out 0xa1, al
	
	mov al, 1	
	out 0x21, al; pic master mode is x86
	out 0xa1, al; pic slave mode is x86
	
	mov al, 0
	out 0x21, al;tell pic master enable all iqr
	out 0xa1, al;tell pic slave enable all iqr
	
	ret
EnableVESA:
	pushad
	jmp .video1024; dont know why
	.video1280:
		mov	ax, 0x4f02
		mov	bx, 0x411b
		int	0x10
		cmp	ax, 0x004f
		je	.videodone
	.video1024:
		mov	ax, 0x4f02
		mov	bx, 0x4118
		int	0x10
		cmp	ax, 0x004f
		je	.videodone
	.video800:
		mov	ax, 0x4f02
		mov	bx, 0x4115
		int	0x10
		cmp	ax, 0x004f
		je	.videodone
	.video640:
		mov	ax, 0x4f02
		mov	bx, 0x4112
		int	0x10
		cmp	ax, 0x004f
		je	.videodone
	.video640_lowcolor:
		mov	ax, 0x4f02
		mov	bx, 0x4111
		int	0x10
		cmp	ax, 0x004f
		je	.videodone
	.videofailed:
		mov di, failed_to_set_VESA
		call BIOS_Print
		jmp	$
	.videodone:
	;gets superVGA mode infomation
	xor ax, ax
	mov es, ax
	mov	di, video_info
	;outdated function
	mov	ax, 0x4f01
	mov	cx, bx; superVGA mode still stored in bx
	int	0x10; es:di points to 256 byte buffer for mode infomation
	;check that the buffer was filled succesfully
	cmp ah, 0
	je .succ
		mov di, failed_to_get_VESA_info
		call BIOS_PrintString
		jmp $
	.succ:
	;
	popad
	ret
SetVideoMode:
	pushad
	mov ax, 4f02h
	mov bx, 105h
	int 10h
	popad
	ret
Reboot:
	cli
	xor ax, ax
	mov ds, ax
	lidt [idtr_invalid]	
	int	0x1

start:
	;resets the disk to stop it makeing noise i think
	;mov ah, 0
	;int 0x13
	;
	;call EnableVESA	
	mov ax, 0x4F02
	mov bx, 0x11B;0x105
	int 0x10
	;fill video mode block
	mov ax, 0x4F01       ; VBE function 01h
	mov cx, 0x105        ; VBE mode 105h (1600x1200x256)
	mov di, video_info  ; pointer to mode information block
	int 0x10             ; call BIOS interrupt to get mode information
	;enable A20 line i hope the PC supports Fast A20
	in al, 0x92
	or al, 2
	out 0x92, al	
	;
	;call SetVideoMode

	;	mov edi, dword[video_address];get ptr to buffer
	;	add edi, 5;100 * 1600 + 100 ; calculate offset of pixel
	;	;mov edi, ecx
	;	mov al, 0x04     ; set pixel color to red
	;	mov byte[edi], al     ; write color to video memory
	;jmp $


	mov ecx, dword[video_address]
	;set this to the number of pixles for your chosen video mode
	mov edx, 1280*1024*3 
	add edx, ecx	
	.loopHead:
		mov edi, ecx
		mov al, cl
		mov byte[edi], al
		cmp ecx, edx
		jge .loopEnd
		add ecx, 3 ; number of byte per pixel
		jmp .loopHead
	.loopEnd:
	jmp $ ; infinate loop

	;jmp $
	;add di, word[video_bytesPerScanLine]
	;add di, word[video_bytesPerScanLine]
	;mov al, 0x05     ; set pixel color to red
	;mov byte[edi], al     ; write color to video memory
	jmp $
	;load gdt
	cli	
	lgdt [gdtr]
	;enter protected mode
	mov eax, cr0
	or eax, 1
	mov cr0, eax
	;
	call remap_pic
	;load idt
	lidt [idtr];ds is = 0

	;jmp $

	jmp 8:init_pm

;align 4
;video_info:
;	video_signature: db 0,0,0,0;should be "VESA"
;	video_version: dw 0; 0x0102 = v1.2
;	video_OEM_ptr: dd 0
;	video_capability_falgs: dd 0
;	video_supportedModes: dd 0
;	video_totalVideoMemory: dw 0; 64k blocks
;	;VBE v1.x
;	;times 236 db 0
;	;VBE v2.0
;	video_OEM_softwareVersion: dw 0; high byte major low byte minor
;	video_vendorsName_ptr: dd 0
;	video_productName_ptr: dd 0
;	video_productRevisionString_ptr: dd 0
;	video_I_Dont_Know: dw 0
;	video_listOfAcceleratedVideoModes_ptr: dd 0
;	video_VBE_implimentation: 
;		times 216 db 0
;	video_OEM_scratchpad:
;		times 256 db 0
;align 4
;video_info:
;	dw 0; attributes;		// deprecated, only bit 7 should be of interest to you, and it indicates the mode supports a linear frame buffer.
;	db 0; window_a;			// deprecated
;	db 0; window_b;			// deprecated
;	dw 0; granularity;		// deprecated; used while calculating bank numbers
;	dw 0; window_size;
;	dw 0; segment_a;
;	dw 0; segment_b;
;	dd 0; win_func_ptr;		// deprecated; used to switch banks from protected mode without returning to real mode
;	video_pitch: dw 0; pitch;			// number of bytes per horizontal line
;	video_width: dw 0; width;			// width in pixels
;	video_height: dw 0; height;			// height in pixels
;	db 0; w_char;			// unused...
;	db 0; y_char;			// ...
;	db 0; planes;
;	db 0; bpp;			// bits per pixel in this mode
;	db 0; banks;			// deprecated; total number of banks in this mode
;	video_memoryModel: db 0; memory_model;
;	db 0; bank_size;		// deprecated; size of a bank, almost always 64 KB but may be 16 KB...
;	db 0; image_pages;
;	db 0; reserved0;
 ;
;	db 0; red_mask;
;	db 0; red_position;
;	db 0; green_mask;
;	db 0; green_position;
;	db 0; blue_mask;
;	db 0; blue_position;
;	db 0; reserved_mask;
;	db 0; reserved_position;
;	db 0; direct_color_attributes;
 ;
;	video_frameBuffer: dd 0; framebuffer;		// physical address of the linear frame buffer; write here to draw to the screen
;	dd 0; off_screen_mem_off;
;	video_off_screen_mem_size: dw 0; off_screen_mem_size;	// size of memory in the framebuffer but not being displayed on the screen
;	times 206 db 0xff; reserved1[206];

init_pm:

	mov ax, 16;point to new data segment
	mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
[bits 32]


	call kernal_main; was call kernal_main

cursorPos: dd 0
invalid_interupt: db "Invalid inturpt occured. ", 0


PrintKernal:; esi is string ptr
	pushad
	.loop:
		mov al, byte[esi]
		cmp al, 0
		je .endLoop
		
		mov ebx, dword[cursorPos]
		imul ebx, 2
		add ebx, TM		
		mov byte[ebx], al
		
		inc word[cursorPos]
		inc esi		
		jmp .loop
	.endLoop:
	popad
	ret
	


	
kernal_main:
	sti;re enable interupts	
	
	
	mov edi, dword[video_address];get ptr to buffer
	;add edi, 100 * 1600 + 100 ; calculate offset of pixel
	mov al, 0x04     ; set pixel color to red
	mov byte[edi], al     ; write color to video memory
	add di, word[video_bytesPerScanLine]
	add di, word[video_bytesPerScanLine]
	mov al, 0x05     ; set pixel color to red
	mov byte[edi], al     ; write color to video memory
	jmp $
interrupt_handler:

	ret	

video_info:
	dw 0h        ; ModeAttributes (bit 0 = linear frame buffer)
	db 0h             ; WinAAttributes
	db 0h             ; WinBAttributes
	dw 0h             ; WinGranularity
	dw 0h             ; WinSize
	dw 0h             ; WinASegment
	dw 0h             ; WinBSegment
	dd 0h             ; WinFuncPtr
	video_bytesPerScanLine: dw 0h ; BytesPerScanLine
	dw 0h             ; XResolution
	dw 0h             ; YResolution
	db 0h             ; XCharSize
	db 0h             ; YCharSize
	db 0h            ; NumberOfPlanes was 256 but that does not make sense
	db 0h              ; BitsPerPixel
	db 0h             ; NumberOfBanks
	db 0h             ; MemoryModel
	db 0h             ; BankSize
	db 0h             ; NumberOfImagePages
	db 0h             ; Reserved1
	db 0h             ; RedMaskSize
	db 0h             ; RedFieldPosition
	db 0h             ; GreenMaskSize
	db 0h             ; GreenFieldPosition
	db 0h             ; BlueMaskSize
	db 0h             ; BlueFieldPosition
	db 0h             ; RsvdMaskSize
	db 0h             ; RsvdFieldPosition
	db 0h             ; DirectColorModeInfo
	video_address: dd 0h             ; PhysBasePtr
	dd 0h             ; OffScreenMemOffset
	dw 0h             ; OffScreenMemSize
	times 206 db 0h
%include "idt.asm"
%include "gdt.asm"


	