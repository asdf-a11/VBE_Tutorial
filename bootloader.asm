[bits 16]
[org 0x7c00]
NUMBER_OF_SECTOR_TO_LOAD equ 4
jmp start
;something
TIMES 3-($-$$) DB 0x90   ; Support 2 or 3 byte encoded JMPs before BPB.
; Dos 4.0 EBPB 1.44MB floppy
OEMname: db    "mkfs.fat"  ; mkfs.fat is what OEMname mkdosfs uses
bytesPerSector:    dw    512
sectPerCluster:    db    1
reservedSectors:   dw    1
numFAT:            db    2
numRootDirEntries: dw    224
numSectors:        dw    2880
mediaType:         db    0xf0
numFATsectors:     dw    9
sectorsPerTrack:   dw    18
numHeads:          dw    2
numHiddenSectors:  dd    0
numSectorsHuge:    dd    0
driveNum:          db    0
reserved:          db    0
signature:         db    0x29
volumeID:          dd    0x2d7e5a1a
volumeLabel:       db    "NO NAME    "
fileSysType:       db    "FAT12   "

;data section
diskNumber: db 0

;code
MoveCursor:;cl is move count
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
PrintChar:;al is char
	pushad
	mov cx, 1		
	;print character
	mov ah, 0xA
	mov bh, 0
	int 0x10
	;update cursor
	call MoveCursor
	popad
	ret
PrintChar_times:; cx is times
	pushad
	;print character
	mov ah, 0xA
	mov bh, 0
	int 0x10
	;update cursor position
	call MoveCursor
	popad
	ret
LoadSegment:;dl is sector al is how many to load si is position
	pushad
	mov ah, 0x2
	mov ch, 0
	mov cl, dl
	mov dh, 0
	mov dl, byte[diskNumber]
	mov bx, si
	int 0x13
	jnc .suc
		mov al, 'F'
		call PrintChar
		jmp $
	.suc:
	;print . for number of sectors loaded
	mov cl, al
	mov al, '$'
	call PrintChar_times
	popad
	ret
start:
	;set all segment registers to 0
	mov ax, 0
	mov es, ax
	mov ss, ax
	mov ds, ax
	;clear direction flag for string operations
	cld
	;Create the stack
	mov esp, 0x7c00
	mov ebp, esp
	;Save device booted from
	mov byte[diskNumber], dl
	;Load rest of code into memory
	mov dl, 2 ; sector id (1 indexed i.e 1=bootloader sector)
	mov al, NUMBER_OF_SECTOR_TO_LOAD ; number of sectors to load, must match amount of padding in extend.asm
	mov si, 0x7e00 ; where to place the sectors
	call LoadSegment	

	jmp nextSectorStart

;padds rest of bootloader
times 510-($-$$) db 0
;adds special boot code
dw 0xaa55

nextSectorStart:
	mov ax, 0x4F02
	mov bx, 0x11B
	int 0x10
	;fill video mode block
	mov ax, 0x4F01       ; VBE function 01h
	mov cx, 0x105        ; VBE mode 105h (1600x1200x256)
	mov di, video_info  ; pointer to mode information block
	int 0x10             ; call BIOS interrupt to get mode information
	;enable A20 line I hope the PC supports Fast A20
	in al, 0x92
	or al, 2
	out 0x92, al	

	;call drawPixel
	;call drawImage
	mov edi, 20
	mov esi, 30
	mov eax, 0x00ff0000
	call drawSquare

	;mov edi, dword

	jmp $ ; infinate loop

pixelSize equ 20
yCounter: dd 0
xCounter: dd 0
colour: db 0,0,0
drawSquare:; edi = x, esi = y eax = colour
	pushad
	mov ecx, eax
	mov byte[colour], cl
	shr ecx, 8
	mov byte[colour+1], cl
	mov byte[colour+2], ch
	;ax = blue green
	mov ecx, esi
	movzx ebx, word[video_x_res]
	imul ebx, 3
	imul ecx, ebx
	imul ebx, edi, 3
	add ecx, ebx	
	add ecx, dword[video_address]
	mov dword[yCounter], 0
	.yLoop:
		mov dword[xCounter], 0
		.xLoop:
			;push ebx
			;clobber ebx
				mov bl, byte[colour]
				mov byte[ecx], bl
				inc ecx
				mov bl, byte[colour+1]
				mov byte[ecx], bl
				inc ecx
				mov bl, byte[colour+2]
				mov byte[ecx], bl
				inc ecx
			;pop ebx
			inc dword[xCounter]
			cmp dword[xCounter], pixelSize
			jle .xLoop
		add ecx, (1280-pixelSize-1)*3
		inc dword[yCounter]
		cmp dword[yCounter], pixelSize
		jle .yLoop
	;add esp, 5
	popad
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
	video_x_res: dw 0h             ; XResolution
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

image:
;incbin "img.bin"

;specifies amount of padding
;512*3 => 3 sectors but includes bootloader so extended program is 2 sectors long max
times (512*(NUMBER_OF_SECTOR_TO_LOAD+1))-($-$$) db 0