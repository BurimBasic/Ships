.intel_syntax noprefix
.code16
.arch i8086
.section .text
.global _start
_start:
    jmp start

# 8086 real mode; all coordinates are integer pixels except player 1/8 px fixed-point.
.equ WIDTH, 256
.equ HEIGHT, 192
.equ MAX_ENEMIES, 4
.equ EN_SIZE, 12
.equ SHOT_SIZE, 8

banner: .ascii "SHIPS v0.1  XT/CGA\r\n$"
test_pass: .ascii "SHIPS /TEST PASS\r\n$"
map_art:
 .ascii "....R.....R....."
 .ascii "..L......R......"
 .ascii "....R..R....L..."
 .ascii "...........R...."
 .ascii ".R....LL........"
 .ascii ".....R.....L...."
 .ascii "...L.....R......"
 .ascii "....R..........."
 .ascii "............R..."
 .ascii "................"
 .ascii "......L........."
 .ascii "........H......."
# up/right/down/left ship masks, 8 bytes each
ship_gfx:
 .byte 0x18,0x18,0x3c,0x3c,0x7e,0xff,0xdb,0x7e
 .byte 0x10,0x1c,0xfe,0xff,0xfe,0x1c,0x10,0x00
 .byte 0x7e,0xdb,0xff,0x7e,0x3c,0x3c,0x18,0x18
 .byte 0x08,0x38,0x7f,0xff,0x7f,0x38,0x08,0x00
sub_gfx: .byte 0x00,0x18,0x24,0x18,0x18,0x24,0x18,0x00
mine_gfx: .byte 0x00,0x24,0x18,0x7e,0x7e,0x18,0x24,0x00
shot_gfx: .byte 0x00,0x00,0x18,0x3c,0x3c,0x18,0x00,0x00
torp_gfx: .byte 0x00,0x24,0x00,0x18,0x18,0x00,0x24,0x00
hud_title: .asciz "SHIPS"
hud_lv: .asciz "LEVEL"
hud_kill: .asciz "SUNK"
hud_life: .asciz "LIVES"
hud_speed: .asciz "ENGINE"
hud_mine: .asciz "MINE"
hud_help1: .asciz "WASD"
hud_help2: .asciz "SHIFT"
hud_help3: .asciz "CTRL"
hud_help4: .asciz "P/R/M"
msg_loss: .asciz "GAME OVER"
msg_win: .asciz "HARBOR SAFE"
msg_pause: .asciz "PAUSED"
msg_harbor: .asciz "HARBOR LOST"

key_state: .space 128
old_int09_off: .word 0
old_int09_seg: .word 0
last_tick: .word 0
tick_count: .word 0
rng: .word 0x7a53
pause_latch: .byte 0
restart_latch: .byte 0
paused: .byte 0
sound_on: .byte 1
speaker_ticks: .byte 0
speaker_music: .byte 0
screen_state: .byte 0       # 0 playing; 1 lost; 2 won
level: .byte 1
score: .byte 0
lives: .byte 3
wave_total: .byte 0
next_spawn: .byte 30
player_fx: .word 1088       # 136*8
player_fy: .word 1216       # 152*8
player_x: .word 136
player_y: .word 152
player_vx: .word 0
player_vy: .word 0
player_dir: .byte 0
player_invul: .byte 0
player_bullet: .byte 0
player_bx: .word 0
player_by: .word 0
player_bdir: .byte 0
player_brng: .byte 0
mine_on: .byte 0
mine_x: .word 0
mine_y: .word 0
mine_arm: .byte 0
# EN_SIZE each: active byte, class byte, x word, y word, dir byte,
# cooldown byte, stuck byte, last x byte, last y byte, spare byte
ship_enemies: .space MAX_ENEMIES*EN_SIZE
# SHOT_SIZE: active, type, x word, y word, dir, range
ship_shots: .space MAX_ENEMIES*SHOT_SIZE
map_tiles: .space 192
# scratch globals for graphics and routines; no reentrancy outside keyboard IRQ
sprite_x: .word 0
sprite_y: .word 0
sprite_ptr: .word 0
sprite_row: .byte 0
sprite_col: .byte 0
sprite_mask: .byte 0
sprite_color: .byte 0
box_x: .word 0
box_y: .word 0
box_row: .word 0
tile_x: .byte 0
tile_y: .byte 0
tile_kind: .byte 0
tile_index: .word 0
check_x: .word 0
check_y: .word 0
check_result: .byte 0
impact_x: .word 0
impact_y: .word 0
impact_is_harbor: .byte 0
tmpx: .word 0
tmpy: .word 0
temp: .word 0
ship_ptr: .word 0
bullet_ptr: .word 0
sound_pitch: .word 1700
hud_row: .byte 0
hud_col: .byte 0
bg_buf: .space 16384

start:
    push cs
    pop ds
    cld
    mov dx, offset banner
    mov ah,0x09
    int 0x21
    cmp byte ptr [0x82], '/'
    jne live_start
    mov al,[0x83]
    and al,0xdf
    cmp al,'T'
    jne live_start
    call tests_run
    mov dx,offset test_pass
    mov ah,9
    int 0x21
    mov ax,0x4c00
    int 0x21
live_start:
    mov ax,0x3509
    int 0x21
    mov [old_int09_off],bx
    mov [old_int09_seg],es
    mov dx,offset keyboard_irq
    mov ax,0x2509
    int 0x21
    mov ax,0x0004
    int 0x10
    mov dx,0x3d9
    mov al,0x20
    out dx,al
    call init_game
    call init_draw
    call read_bios_tick
    mov [last_tick],ax
main_loop:
    cmp byte ptr [key_state+1],0
    jne game_exit
    call read_bios_tick
    cmp ax,[last_tick]
    je main_loop
    mov [last_tick],ax
    call sound_tick
    call handle_controls
    cmp byte ptr [paused],0
    jne main_loop
    cmp byte ptr [screen_state],0
    jne main_loop
    call erase_objects
    call physics_tick
    call draw_objects
    inc word ptr [tick_count]
    mov ax,[tick_count]
    and al,7
    jnz main_loop
    call hud_update
    jmp main_loop

game_exit:
    call sound_off
    push ds
    mov dx,[old_int09_off]
    mov ax,[old_int09_seg]
    mov ds,ax
    mov ax,0x2509
    int 0x21
    pop ds
    mov ax,0x0003
    int 0x10
    mov ax,0x4c00
    int 0x21

keyboard_irq:
    push ax
    push bx
    push ds
    push cs
    pop ds
    in al,0x60
    mov bl,al
    and bx,0x007f
    test al,0x80
    jz key_make
    mov byte ptr [key_state+bx],0
    jmp key_ack
key_make:
    mov byte ptr [key_state+bx],1
key_ack:
    in al,0x61
    mov ah,al
    or al,0x80
    out 0x61,al
    mov al,ah
    out 0x61,al
    mov al,0x20
    out 0x20,al
    pop ds
    pop bx
    pop ax
    iret

read_bios_tick:
    push es
    mov ax,0x40
    mov es,ax
    mov ax,es:[0x6c]
    pop es
    ret

init_game:
    push si
    push di
    push cx
    push es
    push ds
    pop es
    mov si,offset map_art
    mov di,offset map_tiles
    mov cx,192
    rep movsb
    pop es
    pop cx
    pop di
    pop si
    mov byte ptr [screen_state],0
    mov byte ptr [paused],0
    mov byte ptr [score],0
    mov byte ptr [lives],3
    mov byte ptr [wave_total],0
    mov byte ptr [next_spawn],28
    mov byte ptr [mine_on],0
    mov byte ptr [player_bullet],0
    mov byte ptr [player_invul],28
    mov word ptr [player_fx],1088
    mov word ptr [player_fy],1216
    mov word ptr [player_x],136
    mov word ptr [player_y],152
    mov word ptr [player_vx],0
    mov word ptr [player_vy],0
    mov byte ptr [player_dir],0
    push es
    push ds
    pop es
    mov di,offset ship_enemies
    mov cx,MAX_ENEMIES*EN_SIZE+MAX_ENEMIES*SHOT_SIZE
    xor al,al
    rep stosb
    pop es
    ret

# Stage init uses a DS:DI fill; ES may be video on call. wrapper in entry.
init_draw:
    call build_background
    call screen_blit
    call hud_static
    call hud_update
    call draw_objects
    ret

build_background:
    push es
    push di
    push ax
    push cx
    push ds
    pop es
    mov di,offset bg_buf
    mov ax,0x5555
    mov cx,8192
    rep stosw
    mov byte ptr [tile_y],0
bg_rows:
    mov byte ptr [tile_x],0
bg_cols:
    xor bx,bx
    mov bl,[tile_y]
    shl bx,1
    shl bx,1
    shl bx,1
    shl bx,1
    xor ax,ax
    mov al,[tile_x]
    add bx,ax
    mov al,[map_tiles+bx]
    cmp al,'.'
    je bg_next
    mov [tile_kind],al
    call paint_bg_tile
bg_next:
    inc byte ptr [tile_x]
    cmp byte ptr [tile_x],16
    jb bg_cols
    inc byte ptr [tile_y]
    cmp byte ptr [tile_y],12
    jb bg_rows
    pop cx
    pop ax
    pop di
    pop es
    ret

# Draw one background tile from tile_x,tile_y, tile_kind.
paint_bg_tile:
    push ax
    push bx
    push cx
    push dx
    push di
    mov bl,[tile_x]
    xor bh,bh
    shl bx,1
    shl bx,1
    mov dx,0
    mov dl,[tile_y]
    shl dx,1
    shl dx,1
    shl dx,1
    shl dx,1
    mov cx,16
bg_tile_row:
    mov ax,dx
    shr ax,1
    mov di,ax
    shl ax,1
    shl ax,1
    shl ax,1
    shl ax,1
    shl di,1
    shl di,1
    shl di,1
    shl di,1
    shl di,1
    shl di,1
    add di,ax
    test dl,1
    jz bg_even
    add di,8192
bg_even:
    add di,bx
    add di,offset bg_buf
    mov al,[tile_kind]
    cmp al,'R'
    je bg_rock
    cmp al,'L'
    je bg_land
    cmp al,'H'
    je bg_harbor
    mov ax,0x5555
    jmp bg_store
bg_rock:
    mov ax,0xaaaa
    test dl,3
    jnz bg_store
    mov ax,0xeaae
    jmp bg_store
bg_land:
    mov ax,0xffff
    test dl,3
    jnz bg_store
    mov ax,0xeffe
    jmp bg_store
bg_harbor:
    mov ax,0x0000
    test dl,3
    jnz bg_store
    mov ax,0xffff
bg_store:
    mov [di],ax
    mov [di+2],ax
    inc dx
    loop bg_tile_row
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

screen_blit:
    push ds
    push es
    push si
    push di
    push cx
    mov ax,0xb800
    mov es,ax
    mov si,offset bg_buf
    xor di,di
    mov cx,8192
    rep movsw
    pop cx
    pop di
    pop si
    pop es
    pop ds
    ret

# Restore a 16x16 aligned region behind an entity at AX,BX center.
restore_box:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push es
    sub ax,7
    jns rb_xpos
    xor ax,ax
rb_xpos:
    and ax,0xfffc
    cmp ax,240
    jbe rb_xok
    mov ax,240
rb_xok:
    shr ax,1
    shr ax,1
    mov [box_x],ax
    sub bx,7
    jns rb_ypos
    xor bx,bx
rb_ypos:
    cmp bx,176
    jbe rb_yok
    mov bx,176
rb_yok:
    mov [box_y],bx
    mov ax,0xb800
    mov es,ax
    mov bp,16
rb_row:
    mov bx,[box_y]
    mov ax,bx
    shr ax,1
    mov di,ax
    shl ax,1
    shl ax,1
    shl ax,1
    shl ax,1
    shl di,1
    shl di,1
    shl di,1
    shl di,1
    shl di,1
    shl di,1
    add di,ax
    test bl,1
    jz rb_even
    add di,8192
rb_even:
    add di,[box_x]
    lea si,[di+bg_buf]
    mov cx,2
    rep movsw
    inc word ptr [box_y]
    dec bp
    jnz rb_row
    pop es
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

# put_pixel: CX=x (0..319), DX=y (0..199), AL=color (0..3)
put_pixel:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    mov si,ax
    mov ax,0xb800
    mov es,ax
    mov bx,dx
    shr bx,1
    mov di,bx
    shl bx,1
    shl bx,1
    shl bx,1
    shl bx,1
    shl di,1
    shl di,1
    shl di,1
    shl di,1
    shl di,1
    shl di,1
    add di,bx
    test dl,1
    jz pp_even
    add di,8192
pp_even:
    mov bx,cx
    shr bx,1
    shr bx,1
    add di,bx
    mov ax,cx
    and ax,3
    shl al,1
    mov cl,6
    sub cl,al
    mov al,3
    shl al,cl
    not al
    and es:[di],al
    mov ax,si
    and al,3
    shl al,cl
    or es:[di],al
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

# sprite_x/y, ptr and color are globals. pixel coordinates x/y are centers.
draw_sprite:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    mov byte ptr [sprite_row],0
ds_row:
    mov si,[sprite_ptr]
    xor bx,bx
    mov bl,[sprite_row]
    mov al,[si+bx]
    mov [sprite_mask],al
    mov byte ptr [sprite_col],0
ds_col:
    shl byte ptr [sprite_mask],1
    jnc ds_skip
    mov cx,[sprite_x]
    sub cx,4
    xor bx,bx
    mov bl,[sprite_col]
    add cx,bx
    mov dx,[sprite_y]
    sub dx,4
    xor bx,bx
    mov bl,[sprite_row]
    add dx,bx
    mov al,[sprite_color]
    call put_pixel
ds_skip:
    inc byte ptr [sprite_col]
    cmp byte ptr [sprite_col],8
    jb ds_col
    inc byte ptr [sprite_row]
    cmp byte ptr [sprite_row],8
    jb ds_row
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

# BIOS teletype graphics HUD helper; DS:SI null-terminated ASCII, DL=x character, DH=y.
hud_string:
    push ax
    push bx
    push cx
    push dx
    push si
    mov ah,2
    mov bh,0
    int 0x10
hs_next:
    lodsb
    test al,al
    jz hs_done
    mov ah,0x0e
    mov bx,0x0003
    int 0x10
    jmp hs_next
hs_done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

hud_static:
    mov si,offset hud_title
    mov dx,0x0021
    call hud_string
    mov si,offset hud_lv
    mov dx,0x0221
    call hud_string
    mov si,offset hud_kill
    mov dx,0x0521
    call hud_string
    mov si,offset hud_life
    mov dx,0x0821
    call hud_string
    mov si,offset hud_speed
    mov dx,0x0b21
    call hud_string
    mov si,offset hud_mine
    mov dx,0x0e21
    call hud_string
    mov si,offset hud_help1
    mov dx,0x1221
    call hud_string
    mov si,offset hud_help2
    mov dx,0x1321
    call hud_string
    mov si,offset hud_help3
    mov dx,0x1421
    call hud_string
    mov si,offset hud_help4
    mov dx,0x1721
    call hud_string
    ret

# display 0..99 as 2 digit chars, AX=value DX=cursor coordinate
hud_number:
    push ax
    push bx
    push cx
    push dx
    mov ah,2
    mov bh,0
    int 0x10
    xor ah,ah
    mov bl,10
    div bl
    mov [temp],ax
    add al,'0'
    mov ah,0x0e
    mov bx,0x0003
    int 0x10
    mov ax,[temp]
    mov al,ah
    add al,'0'
    mov ah,0x0e
    mov bx,0x0003
    int 0x10
    pop dx
    pop cx
    pop bx
    pop ax
    ret

hud_update:
    xor ah,ah
    mov al,[level]
    mov dx,0x0321
    call hud_number
    xor ah,ah
    mov al,[score]
    mov dx,0x0621
    call hud_number
    xor ah,ah
    mov al,[lives]
    mov dx,0x0921
    call hud_number
    mov ax,[player_vx]
    test ax,ax
    jns hud_vxpositive
    neg ax
hud_vxpositive:
    mov bx,[player_vy]
    test bx,bx
    jns hud_vypositive
    neg bx
hud_vypositive:
    cmp ax,bx
    jae hud_choose
    mov ax,bx
hud_choose:
    mov dl,'1'
    cmp ax,11
    jbe hud_speed_print
    mov dl,'2'
    cmp ax,20
    jbe hud_speed_print
    mov dl,'3'
hud_speed_print:
    mov [temp],dx
    mov dx,0x0c21
    mov ah,2
    mov bh,0
    int 0x10
    mov dx,[temp]
    mov al,dl
    mov ah,0x0e
    mov bx,3
    int 0x10
    mov dx,0x0f21
    mov ah,2
    mov bh,0
    int 0x10
    mov al,'-'
    cmp byte ptr [mine_on],0
    je hud_minedraw
    mov al,'*'
hud_minedraw:
    mov ah,0x0e
    mov bx,3
    int 0x10
    ret

# Core update: every BIOS clock tick. Ordering is stable: old screen restore, motion, impact, draw.
physics_tick:
    call player_physics
    call player_shot_tick
    call enemy_spawn_tick
    call enemies_tick
    call enemy_shots_tick
    call mine_tick
    call player_collision_tick
    cmp byte ptr [player_invul],0
    je pt_done
    dec byte ptr [player_invul]
pt_done:
    ret

# Accelerate automatically by 1/8 px/tick while input is held.
# On release, friction reduces velocity by 1/8 px/tick giving a 1-3 tile coast.
player_physics:
    xor bx,bx       # desired x sign: FF,0,1
    xor cx,cx       # desired y sign
    cmp byte ptr [key_state+0x11],0
    je pf_no_w
    mov cx,-1
    mov byte ptr [player_dir],0
pf_no_w:
    cmp byte ptr [key_state+0x20],0
    je pf_no_d
    mov bx,1
    mov byte ptr [player_dir],1
pf_no_d:
    cmp byte ptr [key_state+0x1f],0
    je pf_no_s
    mov cx,1
    mov byte ptr [player_dir],2
pf_no_s:
    cmp byte ptr [key_state+0x1e],0
    je pf_no_a
    mov bx,-1
    mov byte ptr [player_dir],3
pf_no_a:
    mov ax,[player_vx]
    call approach_vx
    mov ax,[player_vy]
    xchg bx,cx
    call approach_vy
    mov ax,[player_fx]
    add ax,[player_vx]
    mov [tmpx],ax
    shr ax,1
    shr ax,1
    shr ax,1
    mov [check_x],ax
    mov ax,[player_y]
    mov [check_y],ax
    call check_water
    cmp byte ptr [check_result],0
    jne pf_blockx
    mov ax,[tmpx]
    mov [player_fx],ax
    shr ax,1
    shr ax,1
    shr ax,1
    mov [player_x],ax
    jmp pf_y
pf_blockx:
    mov word ptr [player_vx],0
pf_y:
    mov ax,[player_fy]
    add ax,[player_vy]
    mov [tmpy],ax
    shr ax,1
    shr ax,1
    shr ax,1
    mov [check_y],ax
    mov ax,[player_x]
    mov [check_x],ax
    call check_water
    cmp byte ptr [check_result],0
    jne pf_blocky
    mov ax,[tmpy]
    mov [player_fy],ax
    shr ax,1
    shr ax,1
    shr ax,1
    mov [player_y],ax
    ret
pf_blocky:
    mov word ptr [player_vy],0
    ret

# Input sign in BX, value in AX. modifies AX only; 8086 instructions.
approach_vx:
    cmp bx,0
    je pf_fricx
    js pf_negx
    cmp ax,28
    jge pf_storex
    inc ax
    jmp pf_storex
pf_negx:
    cmp ax,-28
    jle pf_storex
    dec ax
    jmp pf_storex
pf_fricx:
    test ax,ax
    jz pf_storex
    js pf_n0x
    dec ax
    jmp pf_storex
pf_n0x:
    inc ax
pf_storex:
    mov [player_vx],ax
    ret
approach_vy:
    cmp bx,0
    je pf_fricy
    js pf_negy
    cmp ax,28
    jge pf_storey
    inc ax
    jmp pf_storey
pf_negy:
    cmp ax,-28
    jle pf_storey
    dec ax
    jmp pf_storey
pf_fricy:
    test ax,ax
    jz pf_storey
    js pf_n0y
    dec ax
    jmp pf_storey
pf_n0y:
    inc ax
pf_storey:
    mov [player_vy],ax
    ret

# Center coordinate water check (also checks four ship corners). check_result 0=water, 1=solid.
check_water:
    push ax
    push bx
    push cx
    push dx
    mov byte ptr [check_result],0
    mov ax,[check_x]
    cmp ax,8
    jb cw_block
    cmp ax,247
    ja cw_block
    mov ax,[check_y]
    cmp ax,8
    jb cw_block
    cmp ax,183
    ja cw_block
    mov cx,0
cw_corner:
    mov ax,[check_x]
    mov bx,[check_y]
    test cl,1
    jz cw_l
    add ax,4
    jmp cw_lr
cw_l:
    sub ax,4
cw_lr:
    test cl,2
    jz cw_t
    add bx,4
    jmp cw_tb
cw_t:
    sub bx,4
cw_tb:
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr bx,1
    shr bx,1
    shr bx,1
    shr bx,1
    shl bx,1
    shl bx,1
    shl bx,1
    shl bx,1
    add bx,ax
    mov dl,[map_tiles+bx]
    cmp dl,'.'
    jne cw_block
    inc cl
    cmp cl,4
    jb cw_corner
    jmp cw_done
cw_block:
    mov byte ptr [check_result],1
cw_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

# bump audio, PC Speaker non-blocking, independent of graphics.
sound_tone:
    cmp byte ptr [sound_on],0
    je st_done
    push ax
    push bx
    push dx
    mov dx,0x43
    mov al,0xb6
    out dx,al
    mov bx,[sound_pitch]
    mov dx,0x42
    mov al,bl
    out dx,al
    mov al,bh
    out dx,al
    in al,0x61
    or al,3
    out 0x61,al
    mov byte ptr [speaker_ticks],2
    pop dx
    pop bx
    pop ax
st_done:
    ret
sound_off:
    push ax
    in al,0x61
    and al,0xfc
    out 0x61,al
    mov byte ptr [speaker_ticks],0
    pop ax
    ret
sound_tick:
    cmp byte ptr [speaker_ticks],0
    je sk_done
    dec byte ptr [speaker_ticks]
    jnz sk_done
    call sound_off
sk_done:
    ret

# Handle edge-triggered restart/pause, level transition, other keys.
handle_controls:
    cmp byte ptr [key_state+0x19],0
    je hc_pclear
    cmp byte ptr [pause_latch],0
    jne hc_restart
    mov byte ptr [pause_latch],1
    xor byte ptr [paused],1
    cmp byte ptr [paused],0
    je hc_repaint
    mov si,offset msg_pause
    call status_message
    jmp hc_restart
hc_pclear:
    mov byte ptr [pause_latch],0
hc_restart:
    cmp byte ptr [key_state+0x13],0
    je hc_rclear
    cmp byte ptr [restart_latch],0
    jne hc_next
    mov byte ptr [restart_latch],1
    mov byte ptr [level],1
    call init_game
    call init_draw
    jmp hc_next
hc_rclear:
    mov byte ptr [restart_latch],0
hc_next:
    cmp byte ptr [screen_state],2
    jne hc_done
    cmp byte ptr [key_state+0x39],0
    je hc_done
    inc byte ptr [level]
    call init_game
    call init_draw
    jmp hc_done
hc_repaint:
    call init_draw
hc_done:
    ret

status_message:
    push dx
    mov dx,0x0b10
    call hud_string
    pop dx
    ret

# Projectile direction updates AX=x,BX=y,DL=direction, step=3 px.
step_projectile:
    cmp dl,0
    jne sp_right
    sub bx,3
    ret
sp_right:
    cmp dl,1
    jne sp_down
    add ax,3
    ret
sp_down:
    cmp dl,2
    jne sp_left
    add bx,3
    ret
sp_left:
    sub ax,3
    ret

# collision projection: impact_x/y, classify and destroy rock. result AL=0 water, 1 rock/land, 2 harbor, 3 outside.
impact_tile:
    push bx
    push cx
    push dx
    mov ax,[impact_x]
    cmp ax,0
    jl impact_out
    cmp ax,255
    ja impact_out
    mov bx,[impact_y]
    cmp bx,0
    jl impact_out
    cmp bx,191
    ja impact_out
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr bx,1
    shr bx,1
    shr bx,1
    shr bx,1
    shl bx,1
    shl bx,1
    shl bx,1
    shl bx,1
    add bx,ax
    mov al,[map_tiles+bx]
    cmp al,'.'
    je impact_water
    cmp al,'H'
    je impact_harbor
    cmp al,'L'
    je impact_solid
    cmp al,'R'
    jne impact_solid
    mov byte ptr [map_tiles+bx],'.'
    push bx
    call patch_background_tile
    pop bx
impact_solid:
    mov al,1
    jmp impact_done
impact_harbor:
    mov al,2
    jmp impact_done
impact_water:
    xor ax,ax
    jmp impact_done
impact_out:
    mov al,3
impact_done:
    pop dx
    pop cx
    pop bx
    ret

# update a damaged rock in the cached background, and immediate visible screen.
patch_background_tile:
    push ax
    push bx
    push cx
    push dx
    mov ax,bx
    mov dl,al
    and dl,15
    mov [tile_x],dl
    mov ax,bx
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    mov [tile_y],al
    mov byte ptr [tile_kind],'.'
    call paint_bg_tile
    # screen tile copy from cached graphics for exact 16x16 region
    xor ax,ax
    mov al,[tile_x]
    shl ax,1
    shl ax,1
    shl ax,1
    shl ax,1
    mov bx,ax
    xor ax,ax
    mov al,[tile_y]
    shl ax,1
    shl ax,1
    shl ax,1
    shl ax,1
    xchg bx,ax
    # AX=x center of tile, BX=y center of tile
    add ax,7
    add bx,7
    call restore_box
    pop dx
    pop cx
    pop bx
    pop ax
    ret

player_shot_tick:
    cmp byte ptr [player_bullet],0
    jne ps_active
    cmp byte ptr [key_state+0x2a],0
    jne ps_fire
    cmp byte ptr [key_state+0x36],0
    je ps_done
ps_fire:
    mov byte ptr [player_bullet],1
    mov ax,[player_x]
    mov bx,[player_y]
    mov dl,[player_dir]
    # muzzle offset 7px (step_projectile moves 3)
    cmp dl,0
    jne ps_mright
    sub bx,7
    jmp ps_mset
ps_mright:
    cmp dl,1
    jne ps_mdown
    add ax,7
    jmp ps_mset
ps_mdown:
    cmp dl,2
    jne ps_mleft
    add bx,7
    jmp ps_mset
ps_mleft:
    sub ax,7
ps_mset:
    mov [player_bx],ax
    mov [player_by],bx
    mov [player_bdir],dl
    mov byte ptr [player_brng],96
    mov word ptr [sound_pitch],1300
    call sound_tone
    jmp ps_done
ps_active:
    mov ax,[player_bx]
    mov bx,[player_by]
    mov dl,[player_bdir]
    call step_projectile
    mov [player_bx],ax
    mov [player_by],bx
    mov [impact_x],ax
    mov [impact_y],bx
    sub byte ptr [player_brng],3
    jz ps_sink
    call impact_tile
    cmp al,0
    je ps_check_enemies
    cmp al,2
    je ps_hit_harbor
    jmp ps_sink
ps_check_enemies:
    mov si,offset ship_enemies
    mov cx,MAX_ENEMIES
ps_enemy_loop:
    cmp byte ptr [si],0
    je ps_next_e
    mov ax,[player_bx]
    mov bx,[si+2]
    call close6
    jnc ps_next_e
    mov ax,[player_by]
    mov bx,[si+4]
    call close6
    jnc ps_next_e
    mov byte ptr [si],0
    inc byte ptr [score]
    mov word ptr [sound_pitch],500
    call sound_tone
    cmp byte ptr [score],12
    jb ps_sink
    mov byte ptr [screen_state],2
    mov si,offset msg_win
    call status_message
    jmp ps_sink
ps_next_e:
    add si,EN_SIZE
    loop ps_enemy_loop
    jmp ps_done
ps_hit_harbor:
    call lose_harbor
ps_sink:
    mov byte ptr [player_bullet],0
ps_done:
    ret

# CF=1 if AX,BX within 6 pixels, else 0; preserves values.
close6:
    push ax
    sub ax,bx
    jns cl6_abs
    neg ax
cl6_abs:
    cmp ax,7
    pop ax
    ret

lose_harbor:
    mov byte ptr [screen_state],1
    mov si,offset msg_harbor
    call status_message
    mov word ptr [sound_pitch],260
    call sound_tone
    ret

# Spawn one enemy every ~2 seconds up to 12 total; max 4 concurrent.
enemy_spawn_tick:
    cmp byte ptr [wave_total],12
    jae esp_done
    dec byte ptr [next_spawn]
    jnz esp_done
    mov byte ptr [next_spawn],42
    mov si,offset ship_enemies
    mov cx,MAX_ENEMIES
esp_find:
    cmp byte ptr [si],0
    je esp_create
    add si,EN_SIZE
    loop esp_find
    ret
esp_create:
    mov byte ptr [si],1
    inc byte ptr [wave_total]
    xor ax,ax
    mov al,[wave_total]
    mov bl,3
    div bl
    mov bl,ah
    xor bh,bh
    shl bx,1
    shl bx,1
    shl bx,1
    shl bx,1
    shl bx,1
    mov dx,bx
    shl bx,1
    add bx,dx
    add bx,32
    mov [si+2],bx
    mov word ptr [si+4],12
    mov byte ptr [si+6],2
    mov byte ptr [si+7],30
    mov byte ptr [si+8],0
    mov byte ptr [si+9],0
    mov byte ptr [si+10],0
    mov byte ptr [si+11],0
    mov al,[wave_total]
    and al,3
    cmp al,0
    jne esp_destroyer
    mov byte ptr [si+1],1
    ret
esp_destroyer:
    mov byte ptr [si+1],0
esp_done:
    ret

# Enemy AI: moves one pixel every 2 (surface) or 3 (sub) ticks,
# targets port with occasional flanking, rotates away if blocked.
enemies_tick:
    mov si,offset ship_enemies
    mov cx,MAX_ENEMIES
et_loop:
    cmp byte ptr [si],0
    je et_next
    mov ax,[tick_count]
    and al,1
    jnz et_cool
    cmp byte ptr [si+1],0
    je et_move
    mov ax,[tick_count]
    and al,3
    jnz et_cool
et_move:
    call enemy_move
et_cool:
    cmp byte ptr [si+7],0
    je et_shoot
    dec byte ptr [si+7]
    jmp et_next
et_shoot:
    mov byte ptr [si+7],52
    call enemy_fire
et_next:
    add si,EN_SIZE
    loop et_loop
    ret

enemy_move:
    push ax
    push bx
    push cx
    push dx
    mov ax,[si+2]
    mov bx,[si+4]
    mov dl,[si+6]
    # Target port x136,y176. Prioritize horizontal if farther than 7px.
    cmp ax,126
    jb em_go_right
    cmp ax,145
    ja em_go_left
    mov dl,2
    jmp em_choose
em_go_right:
    mov dl,1
    jmp em_choose
em_go_left:
    mov dl,3
em_choose:
    cmp byte ptr [si+8],4
    jb em_regular
    mov dl,[si+6]
    inc dl
    and dl,3
    mov byte ptr [si+8],0
em_regular:
    mov [si+6],dl
    cmp dl,0
    jne em_r
    dec bx
    jmp em_try
em_r:
    cmp dl,1
    jne em_d
    inc ax
    jmp em_try
em_d:
    cmp dl,2
    jne em_l
    inc bx
    jmp em_try
em_l:
    dec ax
em_try:
    mov [check_x],ax
    mov [check_y],bx
    call check_water
    cmp byte ptr [check_result],0
    jne em_stuck
    mov [si+2],ax
    mov [si+4],bx
    mov byte ptr [si+8],0
    jmp em_done
em_stuck:
    inc byte ptr [si+8]
    # sidestep (no A-B-A-B oscillation): try lateral alternate for 4 ticks
    mov al,[si+6]
    inc al
    and al,3
    mov [si+6],al
em_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

# One projectile per enemy; a submarine uses a torpedo with bubbles.
enemy_fire:
    push ax
    push bx
    push cx
    push dx
    push di
    mov di,offset ship_shots
    mov bx,MAX_ENEMIES
 ef_find:
    cmp byte ptr [di],0
    je ef_create
    add di,SHOT_SIZE
    dec bx
    jnz ef_find
    jmp ef_done
ef_create:
    mov byte ptr [di],1
    mov al,[si+1]
    mov [di+1],al
    mov ax,[si+2]
    mov [di+2],ax
    mov ax,[si+4]
    mov [di+4],ax
    mov al,[si+6]
    mov [di+6],al
    mov byte ptr [di+7],96
ef_done:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

enemy_shots_tick:
    mov di,offset ship_shots
    mov cx,MAX_ENEMIES
est_loop:
    cmp byte ptr [di],0
    je est_next
    mov ax,[di+2]
    mov bx,[di+4]
    mov dl,[di+6]
    call step_projectile
    mov [di+2],ax
    mov [di+4],bx
    mov [impact_x],ax
    mov [impact_y],bx
    sub byte ptr [di+7],3
    jbe est_sink
    call impact_tile
    cmp al,2
    je est_hit_harbor
    test al,al
    jnz est_sink
    cmp byte ptr [player_invul],0
    jne est_next
    mov ax,[di+2]
    mov bx,[player_x]
    call close6
    jnc est_next
    mov ax,[di+4]
    mov bx,[player_y]
    call close6
    jnc est_next
    call player_death
    jmp est_sink
est_hit_harbor:
    call lose_harbor
est_sink:
    mov byte ptr [di],0
est_next:
    add di,SHOT_SIZE
    loop est_loop
    ret

player_collision_tick:
    cmp byte ptr [player_invul],0
    jne pct_done
    mov si,offset ship_enemies
    mov cx,MAX_ENEMIES
pct_loop:
    cmp byte ptr [si],0
    je pct_next
    mov ax,[si+2]
    mov bx,[player_x]
    call close6
    jnc pct_next
    mov ax,[si+4]
    mov bx,[player_y]
    call close6
    jnc pct_next
    mov byte ptr [si],0
    inc byte ptr [score]
    call player_death
    cmp byte ptr [score],12
    jb pct_done
    mov byte ptr [screen_state],2
    mov si,offset msg_win
    call status_message
    jmp pct_done
pct_next:
    add si,EN_SIZE
    loop pct_loop
pct_done:
    ret

player_death:
    dec byte ptr [lives]
    mov word ptr [sound_pitch],310
    call sound_tone
    cmp byte ptr [lives],0
    jne pd_respawn
    mov byte ptr [screen_state],1
    mov si,offset msg_loss
    call status_message
    ret
pd_respawn:
    mov word ptr [player_x],136
    mov word ptr [player_y],152
    mov word ptr [player_fx],1088
    mov word ptr [player_fy],1216
    mov word ptr [player_vx],0
    mov word ptr [player_vy],0
    mov byte ptr [player_invul],24
    ret

mine_tick:
    cmp byte ptr [key_state+0x1d],0
    je mt_check
    cmp byte ptr [mine_on],0
    jne mt_check
    mov byte ptr [mine_on],1
    mov ax,[player_x]
    mov [mine_x],ax
    mov ax,[player_y]
    mov [mine_y],ax
    mov byte ptr [mine_arm],14
    mov word ptr [sound_pitch],2050
    call sound_tone
mt_check:
    cmp byte ptr [mine_on],0
    je mt_done
    cmp byte ptr [mine_arm],0
    je mt_armed
    dec byte ptr [mine_arm]
    jmp mt_done
mt_armed:
    mov si,offset ship_enemies
    mov cx,MAX_ENEMIES
mt_loop:
    cmp byte ptr [si],0
    je mt_next
    mov ax,[si+2]
    mov bx,[mine_x]
    call close6
    jnc mt_next
    mov ax,[si+4]
    mov bx,[mine_y]
    call close6
    jnc mt_next
    mov byte ptr [si],0
    mov byte ptr [mine_on],0
    inc byte ptr [score]
    mov word ptr [sound_pitch],330
    call sound_tone
    cmp byte ptr [score],12
    jb mt_done
    mov byte ptr [screen_state],2
    mov si,offset msg_win
    call status_message
    jmp mt_done
mt_next:
    add si,EN_SIZE
    loop mt_loop
    mov ax,[player_x]
    mov bx,[mine_x]
    call close6
    jnc mt_done
    mov ax,[player_y]
    mov bx,[mine_y]
    call close6
    jnc mt_done
    mov byte ptr [mine_on],0
    call player_death
mt_done:
    ret

# erase all sprite bounds of the old frame before gameplay update.
erase_objects:
    mov ax,[player_x]
    mov bx,[player_y]
    call restore_box
    cmp byte ptr [player_bullet],0
    je eo_mine
    mov ax,[player_bx]
    mov bx,[player_by]
    call restore_box
eo_mine:
    cmp byte ptr [mine_on],0
    je eo_enemies
    mov ax,[mine_x]
    mov bx,[mine_y]
    call restore_box
eo_enemies:
    mov si,offset ship_enemies
    mov cx,MAX_ENEMIES
eo_enloop:
    cmp byte ptr [si],0
    je eo_enext
    mov ax,[si+2]
    mov bx,[si+4]
    call restore_box
eo_enext:
    add si,EN_SIZE
    loop eo_enloop
    mov si,offset ship_shots
    mov cx,MAX_ENEMIES
eo_shloop:
    cmp byte ptr [si],0
    je eo_snext
    mov ax,[si+2]
    mov bx,[si+4]
    call restore_box
eo_snext:
    add si,SHOT_SIZE
    loop eo_shloop
    ret

draw_objects:
    # Player flashes briefly after respawn
    mov ax,[tick_count]
    and al,2
    jz do_player
    cmp byte ptr [player_invul],0
    jne do_player_skip
do_player:
    mov ax,[player_x]
    mov [sprite_x],ax
    mov ax,[player_y]
    mov [sprite_y],ax
    mov al,[player_dir]
    xor ah,ah
    shl ax,1
    shl ax,1
    shl ax,1
    add ax,offset ship_gfx
    mov [sprite_ptr],ax
    mov byte ptr [sprite_color],3
    call draw_sprite
do_player_skip:
    cmp byte ptr [player_bullet],0
    je do_mine
    mov ax,[player_bx]
    mov [sprite_x],ax
    mov ax,[player_by]
    mov [sprite_y],ax
    mov word ptr [sprite_ptr],offset shot_gfx
    mov byte ptr [sprite_color],3
    call draw_sprite
do_mine:
    cmp byte ptr [mine_on],0
    je do_enemies
    mov ax,[mine_x]
    mov [sprite_x],ax
    mov ax,[mine_y]
    mov [sprite_y],ax
    mov word ptr [sprite_ptr],offset mine_gfx
    mov byte ptr [sprite_color],2
    call draw_sprite
do_enemies:
    mov si,offset ship_enemies
    mov cx,MAX_ENEMIES
do_enloop:
    cmp byte ptr [si],0
    je do_enext
    mov ax,[si+2]
    mov [sprite_x],ax
    mov ax,[si+4]
    mov [sprite_y],ax
    mov word ptr [sprite_ptr],offset sub_gfx
    mov byte ptr [sprite_color],3
    cmp byte ptr [si+1],0
    jne do_draw_enemy
    mov al,[si+6]
    xor ah,ah
    shl ax,1
    shl ax,1
    shl ax,1
    add ax,offset ship_gfx
    mov [sprite_ptr],ax
    mov byte ptr [sprite_color],2
do_draw_enemy:
    call draw_sprite
do_enext:
    add si,EN_SIZE
    loop do_enloop
    mov si,offset ship_shots
    mov cx,MAX_ENEMIES
do_shloop:
    cmp byte ptr [si],0
    je do_snext
    mov ax,[si+2]
    mov [sprite_x],ax
    mov ax,[si+4]
    mov [sprite_y],ax
    mov word ptr [sprite_ptr],offset shot_gfx
    cmp byte ptr [si+1],0
    je do_shell
    mov word ptr [sprite_ptr],offset torp_gfx
do_shell:
    mov byte ptr [sprite_color],3
    call draw_sprite
do_snext:
    add si,SHOT_SIZE
    loop do_shloop
    ret

# /TEST executes deterministic map/physics/shot invariants in DOS text mode.
tests_run:
    call init_game
    cmp byte ptr [map_tiles+184],'H'
    jne test_fail
    cmp byte ptr [map_tiles+4],'R'
    jne test_fail
    mov word ptr [player_vx],28
    xor bx,bx
    mov ax,[player_vx]
    call approach_vx
    cmp word ptr [player_vx],27
    jne test_fail
    mov word ptr [check_x],136
    mov word ptr [check_y],176
    call check_water
    cmp byte ptr [check_result],1
    jne test_fail
    mov word ptr [check_x],136
    mov word ptr [check_y],152
    call check_water
    cmp byte ptr [check_result],0
    jne test_fail
    mov ax,140
    mov bx,144
    call close6
    jnc test_fail
    mov ax,140
    mov bx,160
    call close6
    jc test_fail
    mov ax,25
    mov bx,55
    mov dl,2
    call step_projectile
    cmp bx,58
    jne test_fail
    ret
test_fail:
    mov ax,0x4c01
    int 0x21
