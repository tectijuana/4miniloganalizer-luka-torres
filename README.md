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

[![asciicast](https://asciinema.org/a/ElmAgqrItiHRsv5g.svg)](https://asciinema.org/a/ElmAgqrItiHRsv5g)

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

## Ejecución por dataset

```bash
cat data/logs_A.txt | ./analyzer
# Codigo mas frecuente: 200 veces: 2

cat data/logs_B.txt | ./analyzer
# Codigo mas frecuente: 404 veces: 5

cat data/logs_C.txt | ./analyzer
# Codigo mas frecuente: 200 veces: 3

cat data/logs_D.txt | ./analyzer
# Codigo mas frecuente: 200 veces: 2

cat data/logs_E.txt | ./analyzer
# Codigo mas frecuente: 200 veces: 4
```

---

## Pruebas automáticas

```bash
make test
```

---

## Material proporcionado

Se entregará un repositorio preconfigurado que contiene:

* plantilla base en ARM64
* archivo `Makefile`
* script Bash de ejecución
* archivo de datos (`logs.txt`)
* pruebas iniciales
* secciones marcadas con `TODO`

El estudiante deberá completar la lógica correspondiente.

---
## Entregables

Cada estudiante deberá entregar en su repositorio:

* archivo fuente ARM64 funcional
* solución implementada
* README explicando diseño y lógica utilizada
* evidencia de ejecución
* commits realizados en GitHub Classroom

---

## Criterios de evaluación

| Criterio                    | Ponderación |
| --------------------------- | ----------- |
| Compilación correcta        | 20%         |
| Correctitud de la solución  | 35%         |
| Uso adecuado de ARM64       | 25%         |
| Documentación y comentarios | 10%         |
| Evidencia de pruebas        | 10%         |

---
