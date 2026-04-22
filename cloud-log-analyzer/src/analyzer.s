// ╔══════════════════════════════════════════════════════════════════════╗
// ║   (≧ω≦)ノ 🌸 ANIME DEV ARC: ASM QUEST 🌸 ヽ(≧ω≦)                     ║
// ╠══════════════════════════════════════════════════════════════════════╣
// ║  Asignatura : Lenguajes de Interfaz en TECNM Campus ITT              ║
// ║  Autor      : Torres Sanchez Luka Leonardo Jesus                     ║
// ║  Fecha      : 2026/04/21                                             ║
// ║  Hora       : 04:00 pm                                               ║
// ║                                                                      ║
// ║  Descripción:                                                        ║
// ║  Práctica 4.2 - Mini Cloud Log Analyzer en ARM64 Assembly            ║
// ║  Variante B: Determinar el código de estado más frecuente.           ║
// ║                                                                      ║
// ╠══════════════════════════════════════════════════════════════════════╣
// ║     ⚔️  ASM (poder oculto) + Bash (control) + Make (invocación) ⚔️   ║
// ║                                                                      ║
// ║     (づ◡﹏◡)づ  "Lee logs, cuenta ocurrencias y revela el campeón"    ║
// ║                                                                      ║
// ║     ✨ Nivel 4.2: Práctica ARM64 - Análisis de Logs ✨                ║
// ╚══════════════════════════════════════════════════════════════════════╝

/*
PSEUDOCÓDIGO - Variante B
1) Inicializar tabla de frecuencias vacía (arreglo de pares código/conteo).
2) Mientras haya bytes en stdin:
   2.1) Leer bloque con syscall read.
   2.2) Recorrer byte a byte.
   2.3) Si es dígito, acumular numero_actual = numero_actual * 10 + dígito.
   2.4) Si es '\n', buscar el código en la tabla:
        - Si existe, incrementar su conteo.
        - Si no existe, agregar nueva entrada con conteo 1.
3) Al terminar, recorrer la tabla y encontrar la entrada con mayor conteo.
4) Imprimir el código más frecuente y cuántas veces apareció.
5) Salir con código 0.
*/

.equ SYS_read,    63
.equ SYS_write,   64
.equ SYS_exit,    93
.equ STDIN_FD,     0
.equ STDOUT_FD,    1
.equ MAX_CODIGOS,  64

.section .bss
    .align 8
buffer:        .skip 4096
num_buf:       .skip 32
tabla_codigos: .skip 1024
num_entradas:  .skip 8

.section .data
msg_titulo:  .asciz "=== Mini Cloud Log Analyzer ===\n"
msg_freq:    .asciz "Codigo mas frecuente: "
msg_veces:   .asciz " veces: "
msg_nl:      .asciz "\n"

.section .text
.global _start

_start:
    adrp x0, num_entradas
    add  x0, x0, :lo12:num_entradas
    str  xzr, [x0]
    mov  x19, #0
    mov  x20, #0

leer_bloque:
    mov  x0, #STDIN_FD
    adrp x1, buffer
    add  x1, x1, :lo12:buffer
    mov  x2, #4096
    mov  x8, #SYS_read
    svc  #0
    cmp  x0, #0
    beq  fin_lectura
    blt  salida_error
    mov  x22, #0
    mov  x23, x0

procesar_byte:
    cmp  x22, x23
    b.ge leer_bloque
    adrp x1, buffer
    add  x1, x1, :lo12:buffer
    ldrb w24, [x1, x22]
    add  x22, x22, #1
    cmp  w24, #10
    b.eq fin_numero
    cmp  w24, #48
    b.lt procesar_byte
    cmp  w24, #57
    b.gt procesar_byte
    mov  x25, #10
    mul  x19, x19, x25
    sub  w24, w24, #48
    uxtw x24, w24
    add  x19, x19, x24
    mov  x20, #1
    b    procesar_byte

fin_numero:
    cbz  x20, reiniciar_num
    mov  x0, x19
    bl   registrar_codigo

reiniciar_num:
    mov  x19, #0
    mov  x20, #0
    b    procesar_byte

fin_lectura:
    cbz  x20, buscar_maximo
    mov  x0, x19
    bl   registrar_codigo

buscar_maximo:
    adrp x5, num_entradas
    add  x5, x5, :lo12:num_entradas
    ldr  x21, [x5]
    mov  x26, #0
    mov  x27, #0
    mov  x28, #0
    cbz  x21, imprimir

loop_tabla:
    cmp  x28, x21
    b.ge imprimir
    adrp x0, tabla_codigos
    add  x0, x0, :lo12:tabla_codigos
    mov  x1, x28
    lsl  x1, x1, #4
    add  x0, x0, x1
    ldr  x2, [x0]
    ldr  x3, [x0, #8]
    cmp  x3, x27
    b.le no_actualizar
    mov  x26, x2
    mov  x27, x3

no_actualizar:
    add  x28, x28, #1
    b    loop_tabla

imprimir:
    adrp x0, msg_titulo
    add  x0, x0, :lo12:msg_titulo
    bl   write_cstr
    adrp x0, msg_freq
    add  x0, x0, :lo12:msg_freq
    bl   write_cstr
    mov  x0, x26
    bl   print_uint
    adrp x0, msg_veces
    add  x0, x0, :lo12:msg_veces
    bl   write_cstr
    mov  x0, x27
    bl   print_uint
    adrp x0, msg_nl
    add  x0, x0, :lo12:msg_nl
    bl   write_cstr

salida_ok:
    mov  x0, #0
    mov  x8, #SYS_exit
    svc  #0

salida_error:
    mov  x0, #1
    mov  x8, #SYS_exit
    svc  #0

registrar_codigo:
    stp  x29, x30, [sp, #-32]!
    stp  x22, x23, [sp, #16]
    mov  x29, x0
    adrp x6, num_entradas
    add  x6, x6, :lo12:num_entradas
    ldr  x21, [x6]
    mov  x22, #0

rc_buscar:
    cmp  x22, x21
    b.ge rc_agregar
    adrp x1, tabla_codigos
    add  x1, x1, :lo12:tabla_codigos
    mov  x2, x22
    lsl  x2, x2, #4
    add  x1, x1, x2
    ldr  x3, [x1]
    cmp  x3, x29
    b.ne rc_siguiente
    ldr  x4, [x1, #8]
    add  x4, x4, #1
    str  x4, [x1, #8]
    b    rc_fin

rc_siguiente:
    add  x22, x22, #1
    b    rc_buscar

rc_agregar:
    mov  x3, #MAX_CODIGOS
    cmp  x21, x3
    b.ge rc_fin
    adrp x1, tabla_codigos
    add  x1, x1, :lo12:tabla_codigos
    mov  x2, x21
    lsl  x2, x2, #4
    add  x1, x1, x2
    str  x29, [x1]
    mov  x3, #1
    str  x3,  [x1, #8]
    add  x21, x21, #1
    str  x21, [x6]

rc_fin:
    ldp  x22, x23, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret

write_cstr:
    mov  x9, x0
    mov  x10, #0
wc_loop:
    ldrb w11, [x9, x10]
    cbz  w11, wc_done
    add  x10, x10, #1
    b    wc_loop
wc_done:
    mov  x1, x9
    mov  x2, x10
    mov  x0, #STDOUT_FD
    mov  x8, #SYS_write
    svc  #0
    ret

print_uint:
    cbnz x0, pu_conv
    adrp x1, num_buf
    add  x1, x1, :lo12:num_buf
    mov  w2, #48
    strb w2, [x1]
    mov  x0, #STDOUT_FD
    mov  x2, #1
    mov  x8, #SYS_write
    svc  #0
    ret

pu_conv:
    adrp x12, num_buf
    add  x12, x12, :lo12:num_buf
    add  x12, x12, #31
    mov  w13, #0
    strb w13, [x12]
    mov  x14, #10
    mov  x15, #0

pu_loop:
    udiv x16, x0, x14
    msub x17, x16, x14, x0
    add  x17, x17, #48
    sub  x12, x12, #1
    strb w17, [x12]
    add  x15, x15, #1
    mov  x0, x16
    cbnz x0, pu_loop
    mov  x1, x12
    mov  x2, x15
    mov  x0, #STDOUT_FD
    mov  x8, #SYS_write
    svc  #0
    ret

