[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/EbtZGzoI)
[![Open in Codespaces](https://classroom.github.com/assets/launch-codespace-2972f46106e565e64193e422d61a12cf1da4916b45550586e14ef0a7c637dd04.svg)](https://classroom.github.com/open-in-codespaces?assignment_repo_id=23668560)

# Práctica 4.2 

## Implementación de un Mini Cloud Log Analyzer en ARM64

**Modalidad:** Individual
**Entorno de trabajo:** AWS Ubuntu ARM64 + GitHub Classroom
**Lenguaje:** ARM64 Assembly (GNU Assembler) + Bash + GNU Make

---

## Datos del estudiante

| Campo       | Valor                          |
|-------------|-------------------------------|
| Autor       | Torres Sanchez Luka Leonardo Jesus |
| Asignatura  | Lenguajes de Interfaz          |
| Fecha       | 2026/04/22                     |
| Hora       | 04:00pm                     |
| Variante    | B — Código HTTP más frecuente  |
| Entorno     | AWS Ubuntu 24 ARM64            |

---

## Introducción

Los sistemas modernos de cómputo en la nube generan continuamente registros (*logs*) que permiten monitorear el estado de servicios, detectar fallas y activar alertas ante eventos críticos.

En esta práctica se desarrollará un módulo simplificado de análisis de logs, implementado en **ARM64 Assembly**, inspirado en tareas reales de monitoreo utilizadas en sistemas cloud, observabilidad y administración de infraestructura.

El programa procesará códigos de estado HTTP suministrados mediante entrada estándar (stdin):

```bash id="y1gcmc"
cat logs.txt | ./analyzer
```

---

## Objetivo general

Diseñar e implementar, en lenguaje ensamblador ARM64, una solución para procesar registros de eventos y detectar condiciones definidas según la variante asignada.

---

## Objetivos específicos

El estudiante aplicará:

* programación en ARM64 bajo Linux
* manejo de registros
* direccionamiento y acceso a memoria
* instrucciones de comparación
* estructuras iterativas en ensamblador
* saltos condicionales
* uso de syscalls Linux
* compilación con GNU Make
* control de versiones con GitHub Classroom

Estos temas se alinean con contenidos clásicos de flujo de control, herramientas GNU, manejo de datos y convenciones de programación en ensamblador.   

---

## Diseño y lógica utilizada

### Estructura de datos

Se utiliza una **tabla de frecuencias** almacenada en la sección `.bss`. Cada entrada ocupa 16 bytes organizados así:
La tabla soporta hasta 64 códigos distintos (1024 bytes en total). El contador de entradas activas se guarda en la variable `num_entradas` también en `.bss`, lo que evita corrupción de registros entre llamadas a funciones.

---
### Pseudocódigo

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

---

## Evidencia de ejecución

[![asciicast](https://asciinema.org/a/n4W2SfH4GOSXCrkc.svg)](https://asciinema.org/a/n4W2SfH4GOSXCrkc)
---

### Funciones implementadas

| Función            | Descripción                                                    |
|--------------------|----------------------------------------------------------------|
| `registrar_codigo` | Busca el código en la tabla y actualiza o agrega su conteo     |
| `buscar_maximo`    | Recorre la tabla y encuentra la entrada con mayor conteo       |
| `write_cstr`       | Imprime una cadena terminada en `\0` via syscall write         |
| `print_uint`       | Convierte un entero sin signo a ASCII e imprime                |

### Syscalls utilizadas

| Syscall | Número | Uso                    |
|---------|--------|------------------------|
| `read`  | 63     | Leer bytes de stdin    |
| `write` | 64     | Escribir en stdout     |
| `exit`  | 93     | Terminar el proceso    |

### Registros principales

| Registro | Rol                                                            |
|----------|----------------------------------------------------------------|
| `x19`    | Número actual en construcción (parser)                         |
| `x20`    | Flag: indica si se leyó al menos un dígito                     |
| `x21`    | Cantidad de entradas en la tabla (leído desde memoria)         |
| `x22`    | Índice de iteración dentro del bloque o la tabla               |
| `x23`    | Total de bytes leídos en el bloque actual                      |
| `x26`    | Código HTTP ganador (más frecuente)                            |
| `x27`    | Conteo máximo encontrado                                       |
| `x28`    | Índice de iteración en `buscar_maximo`                         |
| `x29`    | Código a registrar (dentro de `registrar_codigo`)              |
| `x6`     | Puntero a `num_entradas` en memoria                            |

---

## Compilación

```bash
make clean
make
```

---

---
## Prueba con dataset grande — MOCK_DATA.csv

Se incluyó un dataset de **1000 códigos HTTP reales** para validar el programa bajo carga mayor:

```bash
cat data/MOCK_DATA.csv | ./analyzer
```

---
El código `200 OK` fue el más frecuente con **181 apariciones** de 1000 registros, lo cual es consistente con el comportamiento real de servidores web donde la mayoría de peticiones son exitosas.

## Pruebas automáticas

```bash
make test
```

# Codigo Completo analyzer.s
```asm
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
```
---
