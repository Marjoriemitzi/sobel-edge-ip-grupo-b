import os
import sys


def load_pgm_or_make_image(pgm_path, width=64, height=48):
    """Le um arquivo PGM (P2 ou P5) redimensionando por vizinho mais proximo,
    ou gera uma imagem sintetica 64x48 em escala de cinza (0..255)."""
    if pgm_path:
        with open(pgm_path, "rb") as f:
            data = f.read()

        # Extrai tokens do cabecalho ignorando comentarios '#'
        tokens = []
        idx = 0
        n = len(data)
        while len(tokens) < 4 and idx < n:
            if data[idx:idx + 1] == b"#":
                while idx < n and data[idx:idx + 1] != b"\n":
                    idx += 1
            elif data[idx:idx + 1].isspace():
                idx += 1
            else:
                start = idx
                while idx < n and not data[idx:idx + 1].isspace() and data[idx:idx + 1] != b"#":
                    idx += 1
                tokens.append(data[start:idx].decode("ascii", errors="ignore"))

        magic = tokens[0]
        src_w = int(tokens[1])
        src_h = int(tokens[2])
        maxval = int(tokens[3])
        scale = 255.0 / maxval if maxval > 0 else 1.0

        if magic == "P5":
            # Avanca um unico caractere de espaco apos maxval
            if idx < n and data[idx:idx + 1] in (b"\r", b"\n", b" ", b"\t"):
                idx += 1
            raw = [int(b * scale) for b in data[idx:idx + src_w * src_h]]
        elif magic == "P2":
            rest = []
            while idx < n:
                if data[idx:idx + 1] == b"#":
                    while idx < n and data[idx:idx + 1] != b"\n":
                        idx += 1
                elif data[idx:idx + 1].isspace():
                    idx += 1
                else:
                    start = idx
                    while idx < n and not data[idx:idx + 1].isspace() and data[idx:idx + 1] != b"#":
                        idx += 1
                    rest.append(int(int(data[start:idx]) * scale))
            raw = rest[:src_w * src_h]
        else:
            raise ValueError("Formato PGM nao suportado: {}".format(magic))

        src_grid = [raw[r * src_w:(r + 1) * src_w] for r in range(src_h)]
        out = []
        for y in range(height):
            sy = min(src_h - 1, (y * src_h) // height)
            row = []
            for x in range(width):
                sx = min(src_w - 1, (x * src_w) // width)
                row.append(max(0, min(255, src_grid[sy][sx])))
            out.append(row)
        return out

    # Imagem sintetica 64x48 com fundo escuro, retangulo claro e diagonal
    img = []
    for y in range(height):
        row = []
        for x in range(width):
            val = 35
            if (width // 4) <= x <= (3 * width // 4) and (height // 4) <= y <= (3 * height // 4):
                val = 210
            if x == y or x == (width - 1 - y):
                val = 255
            row.append(max(0, min(255, val)))
        img.append(row)
    return img


def sobel_golden(img, threshold=100):
    height = len(img)
    width = len(img[0])
    expected = []

    for y in range(1, height - 1):
        for x in range(1, width - 1):
            p00, p01, p02 = img[y - 1][x - 1], img[y - 1][x], img[y - 1][x + 1]
            p10, _,   p12 = img[y][x - 1],     img[y][x],     img[y][x + 1]
            p20, p21, p22 = img[y + 1][x - 1], img[y + 1][x], img[y + 1][x + 1]

            gx = (p02 + 2 * p12 + p22) - (p00 + 2 * p10 + p20)
            gy = (p20 + 2 * p21 + p22) - (p00 + 2 * p01 + p02)
            mag = abs(gx) + abs(gy)
            expected.append(0xFF if mag >= threshold else 0x00)

    return expected


def main():
    width, height = 64, 48
    threshold = 100
    pgm_path = sys.argv[1] if len(sys.argv) > 1 else None

    img = load_pgm_or_make_image(pgm_path, width, height)
    expected = sobel_golden(img, threshold)

    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    out_dir = os.path.join(base_dir, "build_img")
    os.makedirs(out_dir, exist_ok=True)

    in_hex = os.path.join(out_dir, "input_pixels_64x48.hex")
    exp_hex = os.path.join(out_dir, "expected_edges_64x48.hex")
    prev_pgm = os.path.join(out_dir, "sobel_preview_64x48.pgm")

    with open(in_hex, "w", encoding="utf-8") as f:
        for row in img:
            for px in row:
                f.write("{:02x}\n".format(px))

    with open(exp_hex, "w", encoding="utf-8") as f:
        for val in expected:
            f.write("{:02x}\n".format(val))

    out_w = width - 2
    out_h = height - 2
    with open(prev_pgm, "wb") as f:
        header = "P5\n{} {}\n255\n".format(out_w, out_h).encode("ascii")
        f.write(header)
        f.write(bytes(expected))

    edges_cnt = sum(1 for v in expected if v == 0xFF)
    print("Fonte          : {}".format(pgm_path if pgm_path else "imagem sintetica 64x48"))
    print("Resolucao      : {}x{} ({} pixels)".format(width, height, width * height))
    print("Janelas validas: {} | Bordas (0xFF): {}".format(len(expected), edges_cnt))
    print("Gerados        : {}, {}, {}".format(in_hex, exp_hex, prev_pgm))


if __name__ == "__main__":
    main()
