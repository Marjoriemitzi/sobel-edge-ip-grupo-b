import random

WIDTH = 16
HEIGHT = 8
THRESHOLD = 100

def sobel_bit_accurate(img, thresh=THRESHOLD):
    h = len(img)
    w = len(img[0])
    out_mag = []
    out_edge = []

    # Varre janelas 3x3 válidas (bordas de 1 px ficam de fora neste teste unitário)
    for r in range(1, h - 1):
        for c in range(1, w - 1):
            p00, p01, p02 = img[r-1][c-1], img[r-1][c], img[r-1][c+1]
            p10, p11, p12 = img[r][c-1],   img[r][c],   img[r][c+1]
            p20, p21, p22 = img[r+1][c-1], img[r+1][c], img[r+1][c+1]

            # Estágio 1: diferenças com shift << 1 (peso 2)
            gx_a = p02 - p00
            gx_b = (p12 << 1) - (p10 << 1)
            gx_c = p22 - p20

            gy_a = p20 - p00
            gy_b = (p21 << 1) - (p01 << 1)
            gy_c = p22 - p02

            # Estágio 2 e 3: soma parcial + soma final
            gx = gx_a + (gx_b + gx_c)
            gy = gy_a + (gy_b + gy_c)

            mag = abs(gx) + abs(gy)
            edge = 1 if mag >= thresh else 0

            out_mag.append(mag)
            out_edge.append(edge)

    return out_mag, out_edge

def main():
    random.seed(42)
    # Cria uma imagem sintética 16x8 com fundo 10 e uma região clara 80 (borda clara)
    img = [[10 for _ in range(WIDTH)] for _ in range(HEIGHT)]
    for r in range(2, 6):
        for c in range(8, 14):
            img[r][c] = 80

    # Salva imagem completa em hex (8 bits)
    with open("input_pixels.hex", "w") as f:
        for r in range(HEIGHT):
            for c in range(WIDTH):
                f.write(f"{img[r][c]:02x}\n")

    # Salva janelas 3x3 (9 bytes por linha: p00..p22) e gabarito esperado
    windows = []
    for r in range(1, HEIGHT - 1):
        for c in range(1, WIDTH - 1):
            w_vals = [
                img[r-1][c-1], img[r-1][c], img[r-1][c+1],
                img[r][c-1],   img[r][c],   img[r][c+1],
                img[r+1][c-1], img[r+1][c], img[r+1][c+1],
            ]
            windows.append(w_vals)

    exp_mag, exp_edge = sobel_bit_accurate(img, THRESHOLD)

    with open("windows_3x3.hex", "w") as f:
        for w_vals in windows:
            # Empacota 9 bytes em 72 bits hex: p00 no MSB, p22 no LSB
            word = 0
            for val in w_vals:
                word = (word << 8) | (val & 0xFF)
            f.write(f"{word:018x}\n")

    with open("expected_mag.hex", "w") as f:
        for m in exp_mag:
            f.write(f"{m:03x}\n")

    with open("expected_edge.hex", "w") as f:
        for e in exp_edge:
            f.write(f"{e:01x}\n")

    print(f"Geradas {len(windows)} janelas 3x3 e {len(exp_mag)} saídas esperadas.")

if __name__ == "__main__":
    main()
