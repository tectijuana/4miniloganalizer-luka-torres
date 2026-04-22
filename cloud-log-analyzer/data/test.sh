#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║   (≧ω≦)ノ 🌸 ANIME DEV ARC: ASM QUEST 🌸 ヽ(≧ω≦)                     ║
# ╠══════════════════════════════════════════════════════════════════════╣
# ║  Asignatura : Lenguajes de Interfaz en TECNM Campus ITT              ║
# ║  Autor      : Torres Sanchez Luka Leonardo Jesus                     ║
# ║  Fecha      : 2026/04/21                                             ║
# ║  Hora       : 04:00 pm                                               ║
# ║                                                                      ║
# ║  Descripción:                                                        ║
# ║  Script de pruebas para Práctica 4.2 - ARM64 Log Analyzer            ║
# ║  Variante B: Determinar el código de estado más frecuente.           ║
# ║                                                                      ║
# ╠══════════════════════════════════════════════════════════════════════╣
# ║     ⚔️  Bash (control) + ASM (poder oculto) + Make (invocación) ⚔️   ║
# ║                                                                      ║
# ║     (づ◡﹏◡)づ  "Ejecuta analyzer y muestra el campeón de los logs"   ║
# ║                                                                      ║
# ║     ✨ Nivel 4.2: Práctica ARM64 - Análisis de Logs ✨                ║
# ╚══════════════════════════════════════════════════════════════════════╝

# Pruebas automáticas para Variante B (código HTTP más frecuente).

# PSEUDOCÓDIGO
# ----------------------------------------------------------------------------
# 1) Verificar que el binario ./analyzer existe y es ejecutable.
#    1.1) Si no existe, ejecutar make para compilarlo.
#
# 2) Definir función run_analyzer(archivo):
#    2.1) Si el host es ARM64 (aarch64):
#         - Ejecutar: cat archivo | ./analyzer
#    2.2) Si no es ARM64 pero existe qemu-aarch64:
#         - Ejecutar: cat archivo | qemu-aarch64 ./analyzer
#    2.3) Si ninguna condición aplica:
#         - Imprimir advertencia y retornar código 99 (pruebas omitidas).
#
# 3) Definir función expected_output(nombre_archivo):
#    3.1) Según el nombre del archivo, retornar la salida esperada:
#         - logs_A.txt => código más frecuente es 200 con 2 apariciones
#         - logs_B.txt => código más frecuente es 404 con 5 apariciones
#         - logs_C.txt => código más frecuente es 200 con 3 apariciones
#         - logs_D.txt => código más frecuente es 200 con 2 apariciones
#         - logs_E.txt => código más frecuente es 200 con 4 apariciones
#
# 4) Para cada archivo data/logs_*.txt:
#    4.1) Ejecutar run_analyzer(archivo) y capturar su salida.
#    4.2) Si rc == 99: salir sin fallo (entorno no compatible).
#    4.3) Si rc != 0:  marcar prueba como FAIL (el binario falló).
#    4.4) Obtener salida esperada con expected_output(archivo).
#    4.5) Comparar salida obtenida vs esperada:
#         - Si son iguales: imprimir [OK].
#         - Si difieren:    imprimir [FAIL] con ambas salidas para depurar.
#
# 5) Al finalizar todos los archivos:
#    5.1) Si todas pasaron: imprimir "Todas las pruebas pasaron." y salir 0.
#    5.2) Si alguna falló:  imprimir "Hay pruebas fallidas."     y salir 1.
# ----------------------------------------------------------------------------

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -x ./analyzer ]]; then
  echo "[INFO] Compilando binario..."
  make
fi

run_analyzer() {
  local input_file="$1"

  if [[ $(uname -m) == "aarch64" ]]; then
    cat "$input_file" | ./analyzer
  elif command -v qemu-aarch64 >/dev/null 2>&1; then
    cat "$input_file" | qemu-aarch64 ./analyzer
  else
    echo "[WARN] Host no ARM64 y qemu-aarch64 no disponible; pruebas omitidas." >&2
    return 99
  fi
}

expected_output() {
  local key="$1"
  case "$key" in
    logs_A.txt)
      cat <<'TXT'
=== Mini Cloud Log Analyzer ===
Codigo mas frecuente: 200 veces: 2
TXT
      ;;
    logs_B.txt)
      cat <<'TXT'
=== Mini Cloud Log Analyzer ===
Codigo mas frecuente: 404 veces: 5
TXT
      ;;
    logs_C.txt)
      cat <<'TXT'
=== Mini Cloud Log Analyzer ===
Codigo mas frecuente: 200 veces: 3
TXT
      ;;
    logs_D.txt)
      cat <<'TXT'
=== Mini Cloud Log Analyzer ===
Codigo mas frecuente: 200 veces: 2
TXT
      ;;
    logs_E.txt)
      cat <<'TXT'
=== Mini Cloud Log Analyzer ===
Codigo mas frecuente: 200 veces: 4
TXT
      ;;
    *)
      echo "Caso no definido: $key" >&2
      return 1
      ;;
  esac
}

status=0
for f in data/logs_*.txt; do
  base="$(basename "$f")"
  echo "[TEST] Validando $base"

  set +e
  output="$(run_analyzer "$f")"
  rc=$?
  set -e

  if [[ $rc -eq 99 ]]; then
    exit 0
  elif [[ $rc -ne 0 ]]; then
    echo "[FAIL] Falló la ejecución para $base (rc=$rc)"
    status=1
    continue
  fi

  expected="$(expected_output "$base")"

  if [[ "$output" == "$expected" ]]; then
    echo "[OK] $base"
  else
    echo "[FAIL] $base"
    echo "--- Esperado ---"
    echo "$expected"
    echo "--- Obtenido ---"
    echo "$output"
    status=1
  fi
  echo
done

if [[ $status -eq 0 ]]; then
  echo "[RESULTADO] Todas las pruebas pasaron."
else
  echo "[RESULTADO] Hay pruebas fallidas."
fi

exit $status

