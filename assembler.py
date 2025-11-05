import re
import tkinter as tk
from tkinter import filedialog

# ----------------------------
# Tabla de registros ABI -> números
# ----------------------------
registros = {
    "zero": 0, "ra": 1, "sp": 2, "gp": 3, "tp": 4,
    "t0": 5, "t1": 6, "t2": 7,
    "s0": 8, "fp": 8, "s1": 9,
    "a0": 10, "a1": 11, "a2": 12, "a3": 13,
    "a4": 14, "a5": 15, "a6": 16, "a7": 17,
    "s2": 18, "s3": 19, "s4": 20, "s5": 21, "s6": 22, "s7": 23,
    "s8": 24, "s9": 25, "s10": 26, "s11": 27,
    "t3": 28, "t4": 29, "t5": 30, "t6": 31
}

# ----------------------------
# Diccionario completo de instrucciones RV32I
# ----------------------------
instrucciones = {
    # R-TYPE
    "add":  {"opcode": "0110011", "funct3": "000", "funct7": "0000000"},
    "sub":  {"opcode": "0110011", "funct3": "000", "funct7": "0100000"},
    "sll":  {"opcode": "0110011", "funct3": "001", "funct7": "0000000"},
    "slt":  {"opcode": "0110011", "funct3": "010", "funct7": "0000000"},
    "sltu": {"opcode": "0110011", "funct3": "011", "funct7": "0000000"},
    "xor":  {"opcode": "0110011", "funct3": "100", "funct7": "0000000"},
    "srl":  {"opcode": "0110011", "funct3": "101", "funct7": "0000000"},
    "sra":  {"opcode": "0110011", "funct3": "101", "funct7": "0100000"},
    "or":   {"opcode": "0110011", "funct3": "110", "funct7": "0000000"},
    "and":  {"opcode": "0110011", "funct3": "111", "funct7": "0000000"},

    # I-TYPE (arith + shifts + loads + jalr)
    "addi": {"opcode": "0010011", "funct3": "000", "funct7": "---"},
    "slti": {"opcode": "0010011", "funct3": "010", "funct7": "---"},
    "sltiu":{"opcode": "0010011", "funct3": "011", "funct7": "---"},
    "xori": {"opcode": "0010011", "funct3": "100", "funct7": "---"},
    "ori":  {"opcode": "0010011", "funct3": "110", "funct7": "---"},
    "andi": {"opcode": "0010011", "funct3": "111", "funct7": "---"},
    "slli": {"opcode": "0010011", "funct3": "001", "funct7": "0000000"},
    "srli": {"opcode": "0010011", "funct3": "101", "funct7": "0000000"},
    "srai": {"opcode": "0010011", "funct3": "101", "funct7": "0100000"},
    "lb":   {"opcode": "0000011", "funct3": "000", "funct7": "---"},
    "lh":   {"opcode": "0000011", "funct3": "001", "funct7": "---"},
    "lw":   {"opcode": "0000011", "funct3": "010", "funct7": "---"},
    "lbu":  {"opcode": "0000011", "funct3": "100", "funct7": "---"},
    "lhu":  {"opcode": "0000011", "funct3": "101", "funct7": "---"},
    "jalr": {"opcode": "1100111", "funct3": "000", "funct7": "---"},

    # S-TYPE
    "sb":   {"opcode": "0100011", "funct3": "000", "funct7": "---"},
    "sh":   {"opcode": "0100011", "funct3": "001", "funct7": "---"},
    "sw":   {"opcode": "0100011", "funct3": "010", "funct7": "---"},

    # B-TYPE
    "beq":  {"opcode": "1100011", "funct3": "000", "funct7": "---"},
    "bne":  {"opcode": "1100011", "funct3": "001", "funct7": "---"},
    "blt":  {"opcode": "1100011", "funct3": "100", "funct7": "---"},
    "bge":  {"opcode": "1100011", "funct3": "101", "funct7": "---"},
    "bltu": {"opcode": "1100011", "funct3": "110", "funct7": "---"},
    "bgeu": {"opcode": "1100011", "funct3": "111", "funct7": "---"},

    # U-TYPE
    "lui":  {"opcode": "0110111", "funct3": "---", "funct7": "---"},
    "auipc":{"opcode": "0010111", "funct3": "---", "funct7": "---"},

    # J-TYPE
    "jal":  {"opcode": "1101111", "funct3": "---", "funct7": "---"},
}

# ----------------------------
# Funciones auxiliares
# ----------------------------
def reg(x):
    """Convierte un nombre de registro ABI o xN en número (entero)."""
    x = x.strip()
    if x in registros:
        return registros[x]
    if x.startswith("x") and x[1:].isdigit():
        return int(x[1:])
    raise ValueError(f"Registro no reconocido: {x}")

def resolver_inmediato(imm, etiquetas, memoria):
    """Resuelve inmediatos, etiquetas y %hi/%lo."""
    if not isinstance(imm, str):
        return int(imm)
    imm = imm.strip()
    # %hi(label)
    if imm.startswith("%hi(") and imm.endswith(")"):
        sym = imm[4:-1]
        addr = etiquetas.get(sym, memoria.get(sym, (0, 0))[0])
        return addr >> 12
    # %lo(label)
    if imm.startswith("%lo(") and imm.endswith(")"):
        sym = imm[4:-1]
        addr = etiquetas.get(sym, memoria.get(sym, (0, 0))[0])
        return addr & 0xfff
    # etiqueta directa
    if imm in etiquetas:
        return etiquetas[imm]
    if imm in memoria:
        return memoria[imm][0]
    # hex
    if imm.startswith("0x") or imm.startswith("-0x"):
        return int(imm, 16)
    # decimal (acepta signo)
    try:
        return int(imm, 0)
    except ValueError:
        raise ValueError(f"Inmediato no válido: {imm}")

def to_bin(value, bits):
    return format(value & ((1 << bits) - 1), f"0{bits}b")

def to_hex(value, width=8):
    """Devuelve solo los 8 dígitos hexadecimales (sin '0x')."""
    return format(value & ((1 << (width*4)) - 1), f"0{width}x")


# ----------------------------
# Helpers de codificación por formato
# ----------------------------
def encode_r(rd, rs1, rs2, funct3, funct7, opcode):
    return int(funct7 + to_bin(rs2,5) + to_bin(rs1,5) + funct3 + to_bin(rd,5) + opcode, 2)

def encode_i(rd, rs1, imm, funct3, opcode):
    imm12 = to_bin(imm, 12)
    return int(imm12 + to_bin(rs1,5) + funct3 + to_bin(rd,5) + opcode, 2)

def encode_s(rs1, rs2, imm, funct3, opcode):
    imm12 = to_bin(imm, 12)
    imm_hi = imm12[:7]
    imm_lo = imm12[7:]
    return int(imm_hi + to_bin(rs2,5) + to_bin(rs1,5) + funct3 + imm_lo + opcode, 2)

def encode_b(rs1, rs2, imm, funct3, opcode):
    # imm es offset en bytes desde PC; debe ser múltiplo de 2
    if imm % 2 != 0:
        raise ValueError("Offset de branch no alineado (debe ser múltiplo de 2).")
    imm_r = imm >> 1  # descartamos el bit 0
    imm13 = to_bin(imm_r, 13)  # 13 bits (12..0)
    # orden: imm[12] imm[10:5] rs2 rs1 funct3 imm[4:1] imm[11] opcode
    imm_12 = imm13[0]
    imm_10_5 = imm13[2:8]
    imm_4_1 = imm13[8:12]
    imm_11 = imm13[1]
    binstr = imm_12 + imm_10_5 + to_bin(rs2,5) + to_bin(rs1,5) + funct3 + imm_4_1 + imm_11 + opcode
    return int(binstr, 2)

def encode_u(rd, imm, opcode):
    imm20 = to_bin(imm, 20)
    return int(imm20 + to_bin(rd,5) + opcode, 2)

def encode_j(rd, imm, opcode):
    # imm is byte offset; must be multiple of 2
    if imm % 2 != 0:
        raise ValueError("Offset de JAL no alineado (debe ser múltiplo de 2).")
    imm_r = imm >> 1
    imm21 = to_bin(imm_r, 21)  # 21 bits (20..0)
    # imm[20] imm[10:1] imm[11] imm[19:12]
    imm_20 = imm21[0]
    imm_10_1 = imm21[10:20]
    imm_11 = imm21[9]
    imm_19_12 = imm21[1:9]
    binstr = imm_20 + imm_10_1 + imm_11 + imm_19_12 + to_bin(rd,5) + opcode
    return int(binstr, 2)

# ----------------------------
# Primera pasada
# ----------------------------
def primera_pasada(lineas):
    etiquetas = {}
    memoria = {}
    seccion = None
    pc_text = 0
    pc_data = 0
    for linea in lineas:
        linea = linea.split("#")[0].strip()
        if not linea:
            continue
        if linea == ".text":
            seccion = "text"
            pc_text = 0
            continue
        if linea == ".data":
            seccion = "data"
            pc_data = 0
            continue
        if seccion == "data" and ":" in linea:
            nombre, resto = linea.split(":", 1)
            nombre = nombre.strip()
            partes = resto.strip().split()
            if partes and partes[0] == ".word":
                valor = int(partes[1], 0)
                memoria[nombre] = (pc_data, valor)
                etiquetas[nombre] = pc_data
                pc_data += 4
        elif seccion == "text":
            if ":" in linea:
                etiqueta = linea.split(":",1)[0].strip()
                etiquetas[etiqueta] = pc_text
                rest = linea.split(":",1)[1].strip()
                if rest:
                    pc_text += 4
            else:
                pc_text += 4
    return etiquetas, memoria

# ----------------------------
# Segunda pasada: generar encoding real para RV32I
# ----------------------------
def segunda_pasada(lineas, etiquetas, memoria):
    codigos = []
    pc = 0
    for linea in lineas:
        original = linea.rstrip("\n")
        linea = linea.split("#")[0].strip()
        if not linea or linea in (".text", ".data"):
            continue
        # Saltar etiquetas solas
    
        if ":" in linea:
            parts_after = linea.split(":",1)[1].strip()
            if not parts_after:
                # etiqueta sola, no es instrucción
                continue
            # ⚠ ignorar directivas como .word, .byte, etc.
            if parts_after.startswith("."):
                continue
            linea = parts_after


        partes = linea.replace(",", " ").split()
        if not partes:
            continue
        mnem = partes[0]

        if mnem not in instrucciones:
            print(f"⚠ Instrucción no implementada o desconocida: {mnem} (línea: {original.strip()})")
            pc += 4
            continue

        info = instrucciones[mnem]
        opcode = info["opcode"]
        funct3 = info.get("funct3", "---")
        funct7 = info.get("funct7", "---")

        try:
            # R-type
            if opcode == "0110011":
                # formato: mnem rd, rs1, rs2
                rd = reg(partes[1]); rs1 = reg(partes[2]); rs2 = reg(partes[3])
                binario = encode_r(rd, rs1, rs2, funct3, funct7, opcode)

            # I-type loads / arith / jalr
            elif opcode in ("0010011", "0000011", "1100111"):
                if mnem in ("lb","lh","lw","lbu","lhu"):
                    # lw rd, offset(rs1)
                    rd = reg(partes[1])
                    # parse offset(rs1)
                    m = re.match(r"(-?\w+)\((\w+)\)", partes[2])
                    if not m:
                        raise ValueError("Formato de load inválido, usar offset(register)")
                    offset_str, rs1s = m.group(1), m.group(2)
                    rs1n = reg(rs1s)
                    imm = resolver_inmediato(offset_str, etiquetas, memoria)
                    binario = encode_i(rd, rs1n, imm, funct3, opcode)
                elif mnem == "jalr":
                    # jalr rd, rs1, imm  OR jalr rs (pseudo) but here we expect standard
                    if len(partes) == 2:
                        # jalr rs -> jalr x0, rs, 0  (but usually 'jr rs' is pseudo)
                        rd = 0; rs1n = reg(partes[1]); imm = 0
                    else:
                        rd = reg(partes[1]); rs1n = reg(partes[2]); imm = resolver_inmediato(partes[3], etiquetas, memoria)
                    binario = encode_i(rd, rs1n, imm, funct3, opcode)
                else:
                    # arithmetic immediate: addi rd, rs1, imm ; shifts handled specially
                    rd = reg(partes[1]); rs1n = reg(partes[2]); imm_raw = partes[3]
                    if mnem in ("slli","srli","srai"):
                        shamt = resolver_inmediato(imm_raw, etiquetas, memoria)
                        # for slli/srli/srai imm is encoded in shamt (5 bits) and funct7 distinguishes srai
                        funct7_used = funct7 if funct7 != "---" else "0000000"
                        # build I-type with imm bits: funct7(7) + shamt(5) as top bits => total 12 bits immediate
                        imm12 = (int(funct7_used,2) << 5) | (shamt & 0x1f)
                        binario = encode_i(rd, rs1n, imm12, funct3, opcode)
                    else:
                        imm = resolver_inmediato(imm_raw, etiquetas, memoria)
                        binario = encode_i(rd, rs1n, imm, funct3, opcode)

            # S-type (stores): sw rs2, offset(rs1)
            elif opcode == "0100011":
                rs2 = reg(partes[1])
                m = re.match(r"(-?\w+)\((\w+)\)", partes[2])
                if not m:
                    raise ValueError("Formato de store inválido, usar rs2, offset(rs1)")
                offset_str, rs1s = m.group(1), m.group(2)
                rs1n = reg(rs1s)
                imm = resolver_inmediato(offset_str, etiquetas, memoria)
                binario = encode_s(rs1n, rs2, imm, funct3, opcode)

            # B-type (branches): beq rs1, rs2, label
            elif opcode == "1100011":
                rs1n = reg(partes[1]); rs2n = reg(partes[2])
                target = partes[3]
                target_addr = resolver_inmediato(target, etiquetas, memoria)
                offset = target_addr - pc
                binario = encode_b(rs1n, rs2n, offset, funct3, opcode)

            # U-type: lui, auipc
            elif opcode in ("0110111", "0010111"):
                rd = reg(partes[1])
                imm = resolver_inmediato(partes[2], etiquetas, memoria)
                binario = encode_u(rd, imm, opcode)

            # J-type: jal rd, label  (or jal label -> rd = ra)
            elif opcode == "1101111":
                if len(partes) == 2:
                    rd = 1  # ra by convention for 'jal label'
                    target = partes[1]
                else:
                    rd = reg(partes[1]); target = partes[2]
                target_addr = resolver_inmediato(target, etiquetas, memoria)
                offset = target_addr - pc
                binario = encode_j(rd, offset, opcode)

            else:
                raise ValueError(f"Opcode no manejado aún: {opcode}")

            codigos.append((pc, binario, original.strip(), mnem))
            pc += 4

        except Exception as e:
            print(f"ERROR en línea: {original.strip()} -> {e}")
            # Avanzamos PC aunque error para que la salida mantenga alineación
            pc += 4

    return codigos

# ----------------------------
# Main
# ----------------------------
def main():
    root = tk.Tk()
    root.withdraw()
    archivo = filedialog.askopenfilename(
        title="Selecciona un archivo .asm",
        filetypes=(("Archivos ASM", "*.asm"), ("Todos los archivos", "*.*"))
    )
    if not archivo:
        print("No se seleccionó archivo.")
        return

    with open(archivo, "r") as f:
        lineas = f.readlines()

    etiquetas, memoria = primera_pasada(lineas)
    codigos = segunda_pasada(lineas, etiquetas, memoria)

    # Guardar salidas (TXT formateado, HEX y BIN)
    with open("program.txt", "w") as fout:
        fout.write("PC       | BINARIO (32b)                           | HEX        | OPCODE | FUNCT3 | FUNCT7 | Fuente\n")
        fout.write("----------------------------------------------------------------------------------------------------------\n")
        for pc, binario, fuente, mnem in codigos:
            bin_str = to_bin(binario, 32)
            bin_grouped = " ".join([bin_str[i:i+4] for i in range(0, 32, 4)])
            desc = instrucciones.get(mnem, {})
            fout.write(f"{pc:08x} | {bin_grouped} | {to_hex(binario)} | {desc.get('opcode','---')} | {desc.get('funct3','---')} | {desc.get('funct7','---')} | {fuente}\n")

    with open("program.hex", "w") as f_hex:
        for _, binario, _, _ in codigos:
            # Escribir solo los 8 dígitos hex (sin 0x)
            f_hex.write(f"{to_hex(binario)}\n")


    with open("program.bin", "w") as f_bin:
        for _, binario, _, _ in codigos:
            f_bin.write(to_bin(binario, 32) + "\n")

    print("\n✅ Ensamblado completado.")
    print("Archivos generados: program.txt, program.hex y program.bin")

if __name__ == "__main__":
    main()
