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
	gamestring byte "                    ***************************************",13,10,13,10,
"                    *               WELCOME               *",13,10,13,10,
"                    *         1 GRAVITY PLANE Mode        *",13,10,13,10,
"                    *         2 ESCAPE  PLANE Mode        *",13,10,13,10,
"                    ENTER A NUMBER TO CHOOSE YOUR GAME MODE",13,10,13,10,
"                    ***************************************$";35个*

	difficultystring byte "                    ***************************************",13,10,13,10,
"                    *                1 EASY               *",13,10,13,10,
"                    *                2 NORMAL             *",13,10,13,10,
"                    *                3 HARD               *",13,10,13,10,
"                    ***************************************$"

endstring byte "                    ***************************************",13,10,13,10,
               "                                    GAME OVER              ",13,10,13,10,
			   "                                 Your Score:$"
stringend byte 13,10,13,10,"                    ***************************************$"

	game_mode byte ?
	game_difficulty byte ?

	normal_word_segment word ?
	video_segment = 0a000h
	output_port = 3c8h
	input_port = 3c9h
	enemy_aimed = 4
	enemy_index = 3
	setcolorback_index = 2
	color_index = 1

	xval word ?
	yval word ?
	score word ?
	scorestring byte "Score:",0

	lifestring byte "Life:",0
	life_num word ?

	enemy_easy = 5
	enemy_max = 64
	enemy_num_max word ?
	enemy_num_left_max word ?
	enemies dword enemy_max dup('$$')
	enemies_left dword enemy_max dup('$$')
	enemy_flags dword enemy_max dup(0)	;莫名放大，其实byte够用，或可改
	enemy_flags_left dword enemy_max dup(0)
	enemy_bullets_up dword enemy_max dup('$$')
	enemy_bullets_left dword enemy_max dup('$$')

	enemy_time word 0

	enemystring byte "Enemy:",0

	enemy_total word ?
	enemy_num word ?
	enemy_num_left word ?
	enemy_on_screen word ?
	enemy_speed word ?
	enemy_birth_time word ?

	mybulletmax = 20
	mybullets dword mybulletmax dup('$$')

.code
	assume cs:@code,ds:@data
	setmodel proto modeltype:byte
	drawline proto myred:byte,mygreen:byte,myblue:byte,search_port:byte,x:word,y:word

	main proc
		mov ax,@data
		mov ds,ax
		mov bp,sp

		call startpage

		invoke setmodel,mode_13
		call setbackground

		mov xval,160
		mov yval,100
		.if game_mode =='1'
			call waitforstart
		.else
			call waitforescape
		.endif
		call end_page
		exit
	main endp

	startpage proc
		call Clrscr

		mov ah,2
		mov dh,5
		mov dl,0
		int 10h

		mov ah,9
		mov dx,offset gamestring
		int 21h

		get_game_mode:
			mov ah,10h
			int 16h
			.if al != '1' && al != '2' && al != '3'
				jmp get_game_mode
			.endif

		mov game_mode,al
		call Clrscr

		mov ah,2
		mov dh,5
		mov dl,0
		int 10h

		mov ah,9
		mov dx,offset difficultystring
		int 21h

		get_difficulty:
			mov ah,10h
			int 16h
			.if al != '1' && al != '2' && al != '3'
				jmp get_difficulty
			.endif
		mov game_difficulty,al
		call Clrscr
		ret
	startpage endp

	end_page proc
		call Clrscr

		mov ah,0
		mov al,savepage
		int 10h

		mov ah,2
		mov dh,5
		mov dl,0
		int 10h

		mov ah,9
		mov dx,offset endstring
		int 21h

		movzx eax,score
		call writeint

		mov ah,9
		mov dx,offset stringend
		int 21h

		mov ah,10h
		int 16h
		exit
	end_page endp

	setmodel proc modeltype:byte

		mov ah,0fh
		int 10h
		mov savepage,al

		mov ah,0
		mov al,modeltype
		int 10h

		;mov normal_word_segment,es

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

	drawset proc myred:byte,mygreen:byte,myblue:byte,search_port:byte
		push dx
		push ax


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
		
		pop ax
		pop dx
		ret
	drawset endp

	drawplane proc search_port:byte,x:word,y:word
		push di
		push bx
		push ax
		push cx

		mov bl,search_port

		mov ax,320
		mul y
		add ax,x

		mov cx,16
		mov di,ax
		sub di,8
	DP0:
		mov byte ptr es:[di],bl
		add di,1
		loop DP0

		mov cx,10
		mov di,ax
	DP00:
		mov byte ptr es:[di],bl
		sub di,320
		loop DP00

		mov cx,5
		mov di,ax
	DP000:
		mov byte ptr es:[di],bl
		add di,320
		loop DP000

		mov cx,8
		sub di,4
	DP0000:
		mov byte ptr es:[di],bl
		add di,1
		loop DP0000

		pop cx
		pop ax
		pop bx
		pop di
		ret
	drawplane endp

	drawbullet proc search_port:byte,x:word,y:word
		push di
		push ax
		push cx

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

		pop cx
		pop ax
		pop di
		ret
	drawbullet endp

	drawenemy proc search_port:byte,x:word,y:word
		push di
		push ax
		push cx

		mov ax,320
		mul y
		add ax,x
		
		mov cx,10
		mov di,ax
		mov al,search_port
	DP2:
		push cx
		push di

		mov cx,10
		DP22:
			mov byte ptr es:[di],al
			inc di
			loop DP22

		pop di
		add di,320
		pop cx
		loop DP2

		pop cx
		pop ax
		pop di
		ret
	drawenemy endp

	drawenemies proc search_port:byte,enemys:ptr dword,num:word
		push si
		push cx
		push eax

		mov si,enemys
		mov cx,num
	E0:
		cmp word ptr [si],'$$'
		je new_a_enemy
		jmp next_enemy

	new_a_enemy:
		push cx
		mov eax,310;x
		call randomrange
		mov word ptr [si],ax

		mov eax,160;y
		call randomrange
		mov word ptr [si + 2],ax
		
		invoke drawenemy,search_port,word ptr [si],word ptr [si + 2]

		pop cx

	next_enemy:
		add si,4
		loop E0

		pop eax
		pop cx
		pop si
		ret
	drawenemies endp

	shoot proc
		push si
		push cx
		push bx


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
				sub word ptr [si + 2],20
				jmp squit

			nextposition:
				add si,type mybullets
				loop s0
	squit:
		invoke drawbullet,color_index,word ptr [si],word ptr [si + 2]

		pop bx
		pop cx
		pop si
		ret
	shoot endp

	move_bullet proc
		push si
		push cx

		mov si,offset mybullets
		mov cx,mybulletmax
	L1:
		push cx
		cmp word ptr [si],'$$'
		jz again
		
		L2:
			invoke drawbullet,setcolorback_index,word ptr [si],word ptr [si + 2]
			sub word ptr [si + 2],5
			invoke drawbullet,color_index,word ptr [si],word ptr [si + 2]

			cmp word ptr [si + 2],10
			jb changebullet
			jmp again

		changebullet:
			invoke drawbullet,setcolorback_index,word ptr [si],word ptr [si + 2]
			mov word ptr [si],'$$'
			mov word ptr [si + 2],'$$'

		again:
			add si,4
			pop cx
			loop L1

		pop cx
		pop si
		ret
	move_bullet endp

	move_enemy proc
		push si
		push cx
		
		mov si,offset enemies
		mov cx,enemy_max ;移动enemy的个数，如果扩大敌数怎么写?
				;直接和最大数值对比
		E1:
		push cx
		cmp word ptr [si],'$$'
		jz next
		
		E2:
			invoke drawenemy,setcolorback_index,word ptr [si],word ptr [si + 2]
			add word ptr [si + 2],1
			invoke drawenemy,enemy_index,word ptr [si],word ptr [si + 2]

			cmp word ptr [si + 2],190
			ja changeenemy
			jmp next

		changeenemy:
			dec enemy_on_screen ;超过屏幕后显示的敌机减少，但不代表被消灭
			invoke drawenemy,setcolorback_index,word ptr [si],word ptr [si + 2]
			mov word ptr [si],'$$'
			mov word ptr [si + 2],'$$'

		next:
			add si,4
			pop cx
			loop E1

		pop cx
		pop si
		ret
	move_enemy endp

	checkthekey proc
		push dx

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
			invoke drawplane,setcolorback_index,xval,yval
			sub yval,5
			jmp gotnewposition
		
		gots:
			invoke drawplane,setcolorback_index,xval,yval
			add yval,5
			jmp gotnewposition

		gota:
			invoke drawplane,setcolorback_index,xval,yval
			sub xval,5
			jmp gotnewposition

		gotd:
			invoke drawplane,setcolorback_index,xval,yval
			add xval,5
			
		gotnewposition:
			invoke drawplane,color_index,xval,yval
			jmp quit

		shootnow:
			call shoot

		quit:
			pop dx
			ret	
	checkthekey endp

	checkaim proc enemys:ptr dword,num:word
		push si
		push cx
		push di

		mov si,offset mybullets
		mov cx,mybulletmax
		CA0:
			cmp word ptr [si],'$$'
			push cx
			jz nextbullet
			mov cx,enemy_max;同样的改变敌人数量后怎么写
			mov di,enemys
			CA1:
				
				cmp word ptr [di],'$$'
				jz nextenemy

				;检查敌人和子弹的横坐标距离
				mov ax,word ptr [si]
				sub ax,word ptr [di]
				cmp ax,10
				jnb nextenemy

				;检查敌人和子弹的纵坐标距离
				mov ax,word ptr [si + 2]
				sub ax,word ptr [di + 2]
				cmp ax,10
				jnb nextenemy


				;确认击中，删除子弹和敌人

				invoke drawenemy,setcolorback_index,word ptr [di],word ptr [di + 2]
				mov word ptr [di],'$$'
				mov word ptr [di + 2],'$$'

				invoke drawbullet,setcolorback_index,word ptr [si],word ptr [si + 2]
				mov word ptr [si],'$$'
				mov word ptr [si + 2],'$$'

				inc score ;增分
				dec num ;敌人数量减少
				dec enemy_on_screen ;屏幕上的敌人减少
				dec enemy_total ;剩余的敌人总数减少
				call renew_data
				jmp nextbullet
			nextenemy:
				add di,4
				loop CA1

			nextbullet:
				pop cx
				add si,type mybullets
				loop CA0

		pop di
		pop cx
		pop si
		ret
	checkaim endp

	check_gravity_living proc enemys:ptr dword
		push si
		push cx
		push ax

		mov si,enemys
		mov cx,enemy_max;改变敌人数
		CGL0:
			;检测enemy是否存在
			cmp word ptr [si],'$$'
			jz next_check
			;检测enemy的横坐标和飞机的横坐标的关系

			mov ax,xval
			sub ax,word ptr [si]
			.if ax < 10 && ax > 0
					mov ax,yval
					sub ax,word ptr [si + 2]
			;检测enemy的纵坐标和飞机的纵坐标的关系
					.if ax < 10 && ax > 0
						;invoke drawplane,enemy_aimed,xval,yval
						dec life_num
						;飞机死后回到起始位置
						invoke drawplane,setcolorback_index,xval,yval
						mov xval,160
						mov yval,160
						invoke drawplane,color_index,xval,yval
						;检测生命值是否有剩，有的话返回，没有进入终止界面
						cmp life_num,0
						jnz CGL_back
						call end_page
					.endif
			.endif
		
			next_check:
				add si,4
				loop CGL0
	CGL_back:
		pop ax
		pop cx
		pop si
		call renew_data
		ret
	check_gravity_living endp

	renew_temple proc string: ptr byte,num:word
	 
		mov dx,string
		call writestring
		mov ax,num
		call writeint

		ret
	renew_temple endp

	renew_data proc
		push es
		push ax
		push dx
		mov es,normal_word_segment
		;更新score
		mov ah,2
		mov dh,0
		mov dl,0
		int 10h
		invoke renew_temple,addr scorestring,score

		;更新enemy
		mov ah,2
		mov dh,0
		mov dl,30
		int 10h
		invoke renew_temple,addr enemystring,enemy_total

		;更新生命值
		mov ah,2
		mov dh,0
		mov dl,15
		int 10h
		invoke renew_temple,addr lifestring,life_num

		pop dx
		pop ax
		pop es
		ret
	renew_data endp

	gravity_barrier_easy proc
		push eax
		push bx
		push dx

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
					exit
				.endif
				call checkthekey
			nokeypressed:
				call move_bullet
				invoke checkaim,addr enemies,enemy_num
				invoke check_gravity_living,addr enemies
				inc enemy_time
				mov ax,enemy_speed
				cmp enemy_time,ax
				jnz enemy_not_ready
			enemy_ready_move:
				call move_enemy
				mov enemy_time,0
			enemy_not_ready:
				cmp enemy_total,0
				jz gravity_back
				cmp enemy_num,0
				jz gravity_enemies
				cmp enemy_on_screen,0
				jz renew_enemy_screen
				jmp L0
			renew_enemy_screen:
				mov ax,enemy_num
				mov enemy_on_screen,ax
				invoke drawenemies,enemy_index,addr enemies,enemy_num
				jmp L0
			gravity_enemies:
				mov eax,6
				call randomrange
				.if ax > enemy_total
					mov ax,enemy_total
				.endif
				mov enemy_on_screen,ax
				mov enemy_num,ax
				invoke drawenemies,enemy_index,addr enemies,enemy_num
				jmp L0

		gravity_back:
			pop dx
			pop bx
			pop eax
			ret
	gravity_barrier_easy endp

	move_enemy_normal proc
		push si
		push di
		push cx

		mov si,offset enemies
		mov di,offset enemy_flags
		mov cx,enemy_max
		MEN0:
			cmp word ptr [si],'$$'
			jz next_enemy

			invoke drawenemy,setcolorback_index,word ptr [si],word ptr [si + 2]
			.if	word ptr [si + 2] > 190	;下降得太下面就往上
				mov dword ptr [di],1
			.elseif word ptr [si + 2] < 10	;上升得太上面就往下
				mov dword ptr [di],0
			.endif
			.if dword ptr [di] == 0	;下降可行
				add word ptr [si + 2],1
			.else	;应当上升
				sub word ptr [si + 2],1
			.endif
			invoke drawenemy,enemy_index,word ptr [si],word ptr [si + 2]
			;因为不会触底消失，所以不应该更改敌人的各项数值
		next_enemy:
			add si,4
			add di,4
			loop MEN0


	MEN_quit:
		pop cx
		pop di
		pop si
		ret
	move_enemy_normal endp

	gravity_barrier_normal proc
		push eax
		push bx
		push dx

		mov enemy_birth_time,100	;产生新敌人的速度,5过快了

		mov ah,3
		mov al,5
		mov bh,0
		int 16h
		L0:
			mov eax,150	;反应时间，和键盘灵敏度，下落速度相关
			call delay
			mov ah,11h
			int 16h
			jz nokeypressed ;键盘无按动时，enemy也需要下降
			mov ah,10h
			int 16h
			mov dl,al
				.if dl == 27 ;esc退出游戏
					mov ah,0
					mov al,savepage
					int 10h
					exit
				.endif
				call checkthekey ;检查是否为有效按键
			nokeypressed:
				call move_bullet ;射出的子弹移动
				invoke checkaim,addr enemies,enemy_num ;查看是否命中敌人
				invoke check_gravity_living,addr enemies ;此函数或可不变,实质上是检测是否碰撞
				dec enemy_birth_time ;减少敌人出现的时间
				inc enemy_time ;用来区分我移动和敌人移动，数值越小，敌我移动速度的插件越小
				mov ax,enemy_speed
				cmp enemy_time,ax
				jnz enemy_not_ready
			enemy_ready_move:	;当达到可以移动的条件时移动敌人，move_enemy必须改变
				call move_enemy_normal
				mov enemy_time,0
			enemy_not_ready:
				cmp enemy_total,0	;查看是否消灭所有敌人
				jz gravity_back
				cmp enemy_num,0	;查看是否消灭当前敌人，不需要查看是否消灭屏幕上的敌人，因为触底不消失
				jz gravity_enemies
				cmp enemy_birth_time,0
				jz gravity_enemies
				jmp L0
			gravity_enemies:	;调用此段是产生新的敌人,按时间产生
				mov ax,enemy_total
				cmp enemy_num,ax
				jz gravity_back	;如果敌人数目和总数一致则不再继续加人
				mov eax,5
				call randomrange
				inc eax	;加一到五人
				add ax,enemy_num
				.if ax > enemy_total
					mov ax,enemy_total
				.endif
				mov enemy_on_screen,ax
				mov enemy_num,ax
				mov enemy_birth_time,100
				invoke drawenemies,enemy_index,addr enemies,enemy_num
				jmp L0

		gravity_back:
			pop dx
			pop bx
			pop eax
			ret
	gravity_barrier_normal endp

	move_up_and_down proc
		invoke drawenemy,setcolorback_index,word ptr [si],word ptr [si + 2]
			.if	word ptr [si + 2] > 190	;下降得太下面就往上
				mov dword ptr [di],1
			.elseif word ptr [si + 2] < 10	;上升得太上面就往下
				mov dword ptr [di],0
			.endif
			.if dword ptr [di] == 0	;下降可行
				add word ptr [si + 2],1
			.else	;应当上升
				sub word ptr [si + 2],1
			.endif
		invoke drawenemy,enemy_index,word ptr [si],word ptr [si + 2]
		ret
	move_up_and_down endp

	move_left_and_right proc
		invoke drawenemy,setcolorback_index,word ptr [si],word ptr [si + 2]
			.if	word ptr [si] > 310	;右得太右就往左
				mov dword ptr [di],1
			.elseif word ptr [si] < 10	;左升得太左就往右
				mov dword ptr [di],0
			.endif
			.if dword ptr [di] == 0	;右行
				add word ptr [si],1
			.else	;应当左
				sub word ptr [si],1
			.endif
		invoke drawenemy,enemy_index,word ptr [si],word ptr [si + 2]
		ret
	move_left_and_right endp

	move_enemy_hard proc
		push si
		push di
		push cx
		push eax

		mov si,offset enemies
		mov di,offset enemy_flags
		mov cx,enemy_max
		MEH0:
			cmp word ptr [si],'$$'
			jz next_enemy0
			call move_up_and_down
		next_enemy0:
			add si,4
			add di,4
			loop MEH0

		mov si,offset enemies_left
		mov di,offset enemy_flags_left
		mov cx,enemy_max
		MEH1:
			cmp word ptr [si],'$$'
			jz next_enemy1
			call move_left_and_right
		next_enemy1:
			add si,4
			add di,4
			loop MEH1

	MEH_quit:
		pop eax
		pop cx
		pop di
		pop si
		ret
	move_enemy_hard endp

	gravity_barrier_hard proc
		push eax
		push bx
		push dx

		mov enemy_birth_time,80	;产生新敌人的速度,5过快了

		mov ah,3
		mov al,5
		mov bh,0
		int 16h
		L0:
			mov eax,100	;反应时间，和键盘灵敏度，下落速度相关
			call delay
			mov ah,11h
			int 16h
			jz nokeypressed ;键盘无按动时，enemy也需要下降
			mov ah,10h
			int 16h
			mov dl,al
				.if dl == 27 ;esc退出游戏
					mov ah,0
					mov al,savepage
					int 10h
					exit
				.endif
				call checkthekey ;检查是否为有效按键
			nokeypressed:
				call move_bullet ;射出的子弹移动
				invoke checkaim,addr enemies,enemy_num_max ;查看是否命中敌人
				invoke checkaim,addr enemies_left,enemy_num_left_max
				invoke check_gravity_living,addr enemies ;此函数或可不变,实质上是检测是否碰撞
				invoke check_gravity_living,addr enemies_left
				dec enemy_birth_time ;减少敌人出现的时间
				inc enemy_time ;用来区分我移动和敌人移动，数值越小，敌我移动速度的插件越小
				mov ax,enemy_speed
				cmp enemy_time,ax
				jnz enemy_not_ready
			enemy_ready_move:	;当达到可以移动的条件时移动敌人，move_enemy必须改变
				call move_enemy_hard
				mov enemy_time,0
			enemy_not_ready:
				cmp enemy_total,0	;查看是否消灭所有敌人
				jz gravity_back
				cmp enemy_num,0	;查看是否消灭当前敌人，不需要查看是否消灭屏幕上的敌人，因为触底不消失
				jz gravity_enemies
				cmp enemy_birth_time,0
				jz gravity_enemies
				jmp L0
			gravity_enemies:	;调用此段是产生新的敌人,按时间产生
				mov eax,2
				call randomrange
				.if ax == 0
					mov ax,enemy_num_max
					cmp enemy_num,ax
					jz gravity_back	;如果敌人数目和总数一致则不再继续加人
					mov eax,5
					call randomrange
					inc eax	;加一到五人
					add ax,enemy_num
					.if ax > enemy_num_max
						mov ax,enemy_num_max
					.endif
					mov enemy_num,ax
					mov enemy_birth_time,100
					invoke drawenemies,enemy_index,addr enemies,enemy_num
				.else
					mov ax,enemy_num_left_max
					cmp enemy_num_left,ax
					jz gravity_back	;如果敌人数目和总数一致则不再继续加人
					mov eax,5
					call randomrange
					inc eax	;加一到五人
					add ax,enemy_num_left
					.if ax > enemy_num_left_max
						mov ax,enemy_num_left_max
					.endif
					mov enemy_num_left,ax
					mov enemy_birth_time,100
					invoke drawenemies,enemy_index,addr enemies_left,enemy_num_left
				.endif
				jmp L0

		gravity_back:
			pop dx
			pop bx
			pop eax
			ret
	gravity_barrier_hard endp

	waitforstart proc
			invoke drawset,63,63,63,color_index
			invoke drawset,0,0,35,setcolorback_index
			invoke drawset,63,35,35,enemy_index
			invoke drawset,63,0,0,enemy_aimed

		.if game_difficulty == '1'
			mov enemy_speed,2
			mov score,0
			mov enemy_total,32
			mov enemy_num,enemy_easy
			mov enemy_on_screen,enemy_easy
			mov life_num,3
			call renew_data

			mov normal_word_segment,es
			push es
			push video_segment;super important
			pop es

			invoke drawplane,color_index,xval,yval
			invoke drawenemies,enemy_index,addr enemies,enemy_num
			mov ah,3
			mov al,5
			mov bh,0
			int 16h
			call gravity_barrier_easy
			call end_page
		.elseif game_difficulty == '2'
			mov enemy_speed,1
			mov score,0
			mov enemy_total,64
			mov enemy_num,enemy_easy
			mov enemy_on_screen,enemy_easy
			mov life_num,3
			call renew_data

			mov normal_word_segment,es
			push es
			push video_segment;super important
			pop es

			invoke drawplane,color_index,xval,yval
			invoke drawenemies,enemy_index,addr enemies,enemy_num
			mov ah,3
			mov al,5
			mov bh,0
			int 16h
			call gravity_barrier_normal
			call end_page

		.else
			mov enemy_speed,1
			mov score,0
			mov enemy_total,128
			mov enemy_num,enemy_easy
			mov enemy_num_left,0
			mov enemy_on_screen,enemy_easy
			mov life_num,3
			mov enemy_num_max,enemy_max
			mov enemy_num_left_max,enemy_max
			call renew_data

			mov normal_word_segment,es
			push es
			push video_segment;super important
			pop es

			invoke drawplane,color_index,xval,yval
			invoke drawenemies,enemy_index,addr enemies,enemy_num
			mov ah,3
			mov al,5
			mov bh,0
			int 16h
			call gravity_barrier_hard
			call end_page

		.endif
	
	waitforstart endp

	move_enemy_bullets_down proc
		push si
		push cx

		mov si,offset enemy_bullets_up
		mov cx,enemy_max
		MEBD0:
			cmp word ptr [si],'$$'
			jz next_enemy_bullet
			invoke drawbullet,setcolorback_index,word ptr [si],word ptr [si + 2]
			.if word ptr [si + 2] < 190
				add word ptr [si + 2],2
				invoke drawbullet,enemy_index,word ptr [si],word ptr [si + 2]
			.else
				mov word ptr [si],'$$'
				mov word ptr [si + 2],'$$'
				dec enemy_num
				inc score
			.endif
			next_enemy_bullet:
				add si,4
				loop MEBD0

		pop cx
		pop si
		ret
	move_enemy_bullets_down endp

	draw_enemy_bullets_up proc search_port:byte,enemys_bullets:ptr dword,num:word
		push cx
		push si
		push eax

		mov cx,num
		mov si,enemys_bullets
		DEBU0:
			cmp word ptr [si],'$$'
			jnz next_bullet

			mov eax,320
			call randomrange
			mov word ptr [si + 2],0
			mov word ptr [si],ax
			invoke drawbullet,search_port,word ptr [si],word ptr [si + 2]

			next_bullet:
				add si,4
				loop DEBU0
		pop eax
		pop si
		pop cx
		ret
	draw_enemy_bullets_up endp 

	check_be_aimed_up proc enemy_bullets:ptr dword
		push si
		push cx
		push ax

		mov si,enemy_bullets
		mov cx,enemy_max
		CBAU0:
			cmp word ptr [si],'$$'
			jz next_bullet
			mov ax,word ptr [si]
			sub ax,xval
			.if ax > 0 && ax < 10
				mov ax,yval
				sub ax,word ptr [si + 2]
				.if ax > 0 && ax < 10
					dec life_num
						;飞机死后回到起始位置
						invoke drawplane,setcolorback_index,xval,yval
						mov xval,160
						mov yval,160
						invoke drawplane,color_index,xval,yval
						;检测生命值是否有剩，有的话返回，没有进入终止界面
						cmp life_num,0
						jnz CBAU_back
						call end_page
				.endif
			.endif
			next_bullet:
				add si,4
				loop CBAU0
	CBAU_back:
		pop ax
		pop cx
		pop si
		ret
	check_be_aimed_up endp

	renew_data_escape proc
		push es
		push ax
		push dx
		mov es,normal_word_segment
		;更新score
		mov ah,2
		mov dh,0
		mov dl,0
		int 10h
		invoke renew_temple,addr scorestring,score

		;更新生命值
		mov ah,2
		mov dh,0
		mov dl,15
		int 10h
		invoke renew_temple,addr lifestring,life_num

		pop dx
		pop ax
		pop es
		ret
	renew_data_escape endp

	escape_barrier_easy proc
		push eax
		push bx
		push dx
		mov enemy_time,40	;设置产生敌人子弹的时间
		L0:
			mov eax,150	;反应时间，和键盘灵敏度，下落速度相关
			call delay
			mov ah,11h
			int 16h
			jz nokeypressed ;键盘无按动时，enemy也需要下降
			mov ah,10h
			int 16h
			mov dl,al
				.if dl == 27 ;esc退出游戏
					mov ah,0
					mov al,savepage
					int 10h
					exit
				.endif
				call checkthekey ;检查是否为有效按键
			nokeypressed:
				call move_bullet ;射出的子弹移动
				call move_enemy_bullets_down
				call renew_data_escape
				invoke check_be_aimed_up,addr enemy_bullets_up
				dec enemy_time	;距敌人子弹射出的时间减少
				cmp enemy_time,0
				jnz next_turn
				mov eax,5
				call randomrange
				inc ax
				add ax,enemy_num
				.if ax > enemy_max
					mov ax,enemy_max
				.endif
				mov enemy_num,ax
				invoke draw_enemy_bullets_up,enemy_index,addr enemy_bullets_up,enemy_num
				mov enemy_time,40
				next_turn:
					jmp L0

		pop dx
		pop bx
		pop eax
		ret
	escape_barrier_easy endp

	;enemy_flags
	move_enemy_bullets_up_and_down proc
		push si
		push cx
		push di
		push eax

		mov si,offset enemy_bullets_up
		mov di,offset enemy_flags
		mov cx,enemy_max
		MEBUD0:
			cmp word ptr [si],'$$'
			jz next_enemy_bullet
			invoke drawbullet,setcolorback_index,word ptr [si],word ptr [si + 2]

			mov eax,dword ptr [di]
			and eax,1

			.if word ptr [si + 2] > 190 && ax == 0
				inc dword ptr [di]
				inc ax
			.elseif word ptr [si + 2] < 10 && ax == 1
				inc dword ptr [di]
				dec ax
			.elseif dword ptr [di] == 3
				mov word ptr [si],'$$'
				mov word ptr [si + 2],'$$'
				mov dword ptr [di],0
				inc score
				jmp next_enemy_bullet
			.endif

			.if ax == 0
				add word ptr [si + 2],2
				invoke drawbullet,enemy_index,word ptr [si],word ptr [si + 2]
			.else
				sub word ptr [si + 2],2
				invoke drawbullet,enemy_index,word ptr [si],word ptr [si + 2]
			.endif

			next_enemy_bullet:
				add si,4
				add di,4
				loop MEBUD0

		pop eax
		pop di
		pop cx
		pop si
		ret
	move_enemy_bullets_up_and_down endp

	escape_barrier_normal proc
		push eax
		push bx
		push dx
		mov enemy_time,40	;设置产生敌人子弹的时间
		L0:
			mov eax,150	;反应时间，和键盘灵敏度，下落速度相关
			call delay
			mov ah,11h
			int 16h
			jz nokeypressed ;键盘无按动时，enemy也需要下降
			mov ah,10h
			int 16h
			mov dl,al
				.if dl == 27 ;esc退出游戏
					mov ah,0
					mov al,savepage
					int 10h
					exit
				.endif
				call checkthekey ;检查是否为有效按键
			nokeypressed:
				call move_bullet ;射出的子弹移动
				call move_enemy_bullets_up_and_down
				call renew_data_escape
				invoke check_be_aimed_up,addr enemy_bullets_up
				dec enemy_time	;距敌人子弹射出的时间减少
				cmp enemy_time,0
				jnz next_turn
				mov eax,5
				call randomrange
				inc ax
				add ax,enemy_num
				.if ax > enemy_max
					mov ax,enemy_max
				.endif
				mov enemy_num,ax
				invoke draw_enemy_bullets_up,enemy_index,addr enemy_bullets_up,enemy_num
				mov enemy_time,40
				next_turn:
					jmp L0

		pop dx
		pop bx
		pop eax
		ret
	escape_barrier_normal endp

	draw_bullet_left proc search_port:byte,x:word,y:word
		push di
		push ax
		push cx

		mov ax,320
		mul y
		add ax,x
		
		mov cx,10
		mov di,ax
		mov al,search_port
	DP1:
		mov byte ptr es:[di],al
		add di,1
		loop DP1

		pop cx
		pop ax
		pop di
		ret
	draw_bullet_left endp

	draw_enemy_bullets_left proc search_port:byte,enemys_bullets:ptr dword,num:word
		push cx
		push si
		push eax

		mov cx,num
		mov si,enemys_bullets
		DEBL0:
			cmp word ptr [si],'$$'
			jnz next_bullet

			mov eax,160
			call randomrange
			mov word ptr [si],0
			mov word ptr [si + 2],ax
			invoke draw_bullet_left,search_port,word ptr [si],word ptr [si + 2]

			next_bullet:
				add si,4
				loop DEBL0
		pop eax
		pop si
		pop cx
		ret
	draw_enemy_bullets_left endp

	move_enemy_bullets_left_and_right proc
		push si
		push cx
		push di
		push eax

		mov si,offset enemy_bullets_left
		mov di,offset enemy_flags_left
		mov cx,enemy_max
		MEBLR0:
			cmp word ptr [si],'$$'
			jz next_enemy_bullet
			invoke draw_bullet_left,setcolorback_index,word ptr [si],word ptr [si + 2]

			mov eax,dword ptr [di]
			and eax,1

			.if word ptr [si] > 310 && ax == 0
				inc dword ptr [di]
				inc ax
			.elseif word ptr [si] < 10 && ax == 1
				inc dword ptr [di]
				dec ax
			.elseif dword ptr [di] == 3
				mov word ptr [si],'$$'
				mov word ptr [si + 2],'$$'
				inc score
				mov dword ptr [di],0
				jmp next_enemy_bullet
			.endif

			.if ax == 0
				add word ptr [si],2
				invoke draw_bullet_left,enemy_index,word ptr [si],word ptr [si + 2]
			.else
				sub word ptr [si],2
				invoke draw_bullet_left,enemy_index,word ptr [si],word ptr [si + 2]
			.endif

			next_enemy_bullet:
				add si,4
				add di,4
				loop MEBLR0

		pop eax
		pop di
		pop cx
		pop si
		ret
	move_enemy_bullets_left_and_right endp

	check_be_aimed_left proc enemy_bullets:ptr dword
		push si
		push cx
		push ax

		mov si,enemy_bullets
		mov cx,enemy_max
		CBAL0:
			cmp word ptr [si],'$$'
			jz next_bullet
			mov ax,xval
			sub ax,word ptr [si]
			.if ax > 0 && ax < 10
				mov ax,yval
				sub ax,word ptr [si + 2]
				.if ax > 0 && ax < 10
					dec life_num
						;飞机死后回到起始位置
						invoke drawplane,setcolorback_index,xval,yval
						mov xval,160
						mov yval,160
						invoke drawplane,color_index,xval,yval
						;检测生命值是否有剩，有的话返回，没有进入终止界面
						cmp life_num,0
						jnz CBAL_back
						call end_page
				.endif
			.endif
			next_bullet:
				add si,4
				loop CBAL0
		CBAL_back:
			pop ax
			pop cx
			pop si
			ret
	check_be_aimed_left endp

	escape_barrier_hard proc
		push eax
		push bx
		push dx
		mov enemy_time,30	;设置产生敌人子弹的时间
		L0:
			mov eax,150	;反应时间，和键盘灵敏度，下落速度相关
			call delay
			mov ah,11h
			int 16h
			jz nokeypressed ;键盘无按动时，enemy也需要下降
			mov ah,10h
			int 16h
			mov dl,al
				.if dl == 27 ;esc退出游戏
					mov ah,0
					mov al,savepage
					int 10h
					exit
				.endif
				call checkthekey ;检查是否为有效按键
			nokeypressed:
				call move_bullet ;射出的子弹移动
				call move_enemy_bullets_up_and_down
				call move_enemy_bullets_left_and_right
				call renew_data_escape
				invoke check_be_aimed_up,addr enemy_bullets_up
				invoke check_be_aimed_left,addr enemy_bullets_left
				dec enemy_time	;距敌人子弹射出的时间减少
				cmp enemy_time,0
				jnz next_turn
				mov eax,2
				call randomrange
				.if ax == 0
					mov eax,5
					call randomrange
					inc ax
					add ax,enemy_num
					.if ax > enemy_max
						mov ax,enemy_max
					.endif
					mov enemy_num,ax
					invoke draw_enemy_bullets_up,enemy_index,addr enemy_bullets_up,enemy_num
				.else
					mov eax,5
					call randomrange
					inc ax
					add ax,enemy_num_left
					.if ax > enemy_max
						mov ax,enemy_max
					.endif
					mov enemy_num_left,ax
					invoke draw_enemy_bullets_left,enemy_index,addr enemy_bullets_left,enemy_num_left
				.endif
					mov enemy_time,30
				next_turn:
					jmp L0

		pop dx
		pop bx
		pop eax
		ret
	escape_barrier_hard endp

	waitforescape proc
		push ax
		push bx

		invoke drawset,63,63,63,color_index
		invoke drawset,0,0,35,setcolorback_index
		invoke drawset,63,35,35,enemy_index
		invoke drawset,63,0,0,enemy_aimed
		.if game_difficulty == '1'
			mov score,0
			mov life_num,3
			mov enemy_num,enemy_easy

			mov normal_word_segment,es
			push es
			push video_segment;super important
			pop es

			invoke drawplane,color_index,xval,yval
			invoke draw_enemy_bullets_up ,enemy_index,addr enemy_bullets_up,enemy_num
			
			call escape_barrier_easy

		.elseif game_difficulty == '2'
			mov score,0
			mov life_num,3
			mov enemy_num,enemy_easy

			mov normal_word_segment,es
			push es
			push video_segment;super important
			pop es

			invoke drawplane,color_index,xval,yval
			invoke draw_enemy_bullets_up ,enemy_index,addr enemy_bullets_up,enemy_num
			
			call escape_barrier_normal
		.else
			mov score,0
			mov life_num,3
			mov enemy_num,enemy_easy

			mov normal_word_segment,es
			push es
			push video_segment;super important
			pop es

			invoke drawplane,color_index,xval,yval
			invoke draw_enemy_bullets_up ,enemy_index,addr enemy_bullets_up,enemy_num
			
			call escape_barrier_hard
		.endif

		pop bx
		pop ax
		ret
	waitforescape endp

	end main