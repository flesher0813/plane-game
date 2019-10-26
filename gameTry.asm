include Irvine16.inc
mode_06 = 6 ;640 * 200, 2color
mode_0d = 0dh ;320 * 200, 16color
mode_0e = 0eh ;640 * 200, 16color
mode_0f = 0fh ;640 * 350, 2color
mode_10 = 10h ;640 * 350, 16color
mode_11 = 11h ;640 * 480, 2color
mode_12 = 12h ;640 * 480, 2color
mode_13 = 13h ;320 * 200, 2color
mode_6a = 6ah ;800 * 600, 2color


.data
	savepage byte ?
	gamestring byte "G A M E"

	normal_word_segment word ?
	video_segment = 0a000h
	output_port = 3c8h
	input_port = 3c9h
	xval word ?
	yval word ?
	setcolorback_index = 2
	color_index = 1

	mybulletmax = 20
	mybullets dword mybulletmax dup('$$')

.code
	assume cs:@code,ds:@data
	setmodel proto modeltype:byte
	drawline proto myred:byte,mygreen:byte,myblue:byte,search_port:byte,x:word,y:word

	main proc
		mov ax,@data
		mov ds,ax

		invoke setmodel,mode_13
		call setbackground

		mov xval,160
		mov yval,100

		call waitforstart
		exit
	main endp

	setmodel proc modeltype:byte
		mov ah,0fh
		int 10h
		mov savepage,al

		mov ah,0
		mov al,modeltype
		int 10h

		;mov normal_word_segment,es
		push video_segment;super important
		pop es

		ret
	setmodel endp

	setbackground proc
		mov dx,output_port
		mov al,0
		out dx,al

		mov dx,input_port
		mov al,0
		out dx,al
		mov al,0
		out dx,al
		mov al,35
		out dx,al
		ret
	setbackground endp

	drawline proc myred:byte,mygreen:byte,myblue:byte,search_port:byte,x:word,y:word
		mov dx,output_port
		mov al,search_port
		out dx,al

		mov dx,input_port
		mov al,myred
		out dx,al
		mov al,mygreen
		out dx,al
		mov al,myblue
		out dx,al

		mov ax,320
		mul y
		add ax,x

		mov cx,10
		mov di,ax
		mov al,search_port
	DP1:
		mov byte ptr es:[di],al
		add di,320
		loop DP1

		ret
	drawline endp

	shoot proc
		push bp
		mov bp,sp

		mov si,offset mybullets
		mov cx,mybulletmax
		s0:
			cmp word ptr [si],'$$'
			jz gotposition
			jmp nextposition

			gotposition:
				mov bx,xval
				mov word ptr [si],bx
				mov bx,yval
				mov word ptr [si + 2],bx
				sub word ptr [si + 2],15
				jmp squit

			nextposition:
				add si,type mybullets
				loop s0
	squit:
		invoke drawline,63,63,63,color_index,word ptr [si],word ptr [si + 2]
		mov sp,bp
		pop bp
		ret
	shoot endp

	move proc
		push bp
		mov bp,sp

		mov si,offset mybullets
		mov cx,mybulletmax
	L1:
		push cx
		cmp word ptr [si],'$$'
		jz again
		
		L2:
			invoke drawline,0,0,35,setcolorback_index,word ptr [si],word ptr [si + 2]
			sub word ptr [si + 2],5
			invoke drawline,63,63,63,color_index,word ptr [si],word ptr [si + 2]

			cmp word ptr [si + 2],10
			jb changebullet
			jmp again

		changebullet:
			invoke drawline,0,0,35,setcolorback_index,word ptr [si],word ptr [si + 2]
			mov word ptr [si],'$$'
			mov word ptr [si + 2],'$$'

		again:
			add si,4
			pop cx
			loop L1

		mov sp,bp
		pop bp
		ret
	move endp

	checkthekey proc
		mov dl,al

		.if dl == 77h || dl == 57h;w
			jmp gotw

		.elseif dl == 73h || dl == 53h;s
			jmp gots

		.elseif dl == 61h || dl == 41h;a
			jmp gota

		.elseif dl == 64h || dl == 44h;d
			jmp gotd

		.elseif dl == 20h
			jmp shootnow

		.else
			jmp quit
		.endif

		gotw:
			invoke drawline,0,0,35,setcolorback_index,xval,yval
			sub yval,5
			jmp gotnewposition
		
		gots:
			invoke drawline,0,0,35,setcolorback_index,xval,yval
			add yval,5
			jmp gotnewposition

		gota:
			invoke drawline,0,0,35,setcolorback_index,xval,yval
			sub xval,5
			jmp gotnewposition

		gotd:
			invoke drawline,0,0,35,setcolorback_index,xval,yval
			add xval,5
			
		gotnewposition:
			invoke drawline,63,63,63,color_index,xval,yval
			jmp quit

		shootnow:
			call shoot

		quit:
			ret
		
	checkthekey endp

	waitforstart proc
		invoke drawline,63,63,63,color_index,xval,yval

		mov ah,3
		mov al,5
		mov bh,0
		int 16h
		L0:
			mov eax,150
			call delay
			mov ah,11h
			int 16h
			jz nokeypressed
			mov ah,10h
			int 16h
			mov dl,al
				.if dl == 27 ;esc
					mov ah,0
					mov al,savepage
					int 10h
					ret
				.endif
				call checkthekey
			nokeypressed:
				call move
				jmp L0

	waitforstart endp

	end main