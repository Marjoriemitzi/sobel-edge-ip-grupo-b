# Sobel Edge Detection IP — Grupo B

Implementação em **SystemVerilog** de um núcleo detector de bordas **Sobel** com interface **AXI-Stream**, projetado como etapa intermediária do pipeline **Viola-Jones → Sobel → Hough** (com meta de referência de sistema em torno de **~15 FPS**).

## Características da Arquitetura
- **Sem multiplicadores:** cálculo dos gradientes $G_x$ e $G_y$ usando deslocamentos (`<< 1` para peso 2) e somadores/subtratores.
- **Sem cálculo de ângulo:** magnitude aproximada via $\vert{}G_x\vert{} + \vert{}G_y\vert{}$.
- **Limiarização (`threshold`):** geração de saída binária (`0xFF` para borda / `0x00` caso contrário) a partir de um limiar configurável.
- **Pipeline de 3 estágios + Line Buffers 3×3:** 2 buffers de linha (`y-1` e `y-2`) + registradores de deslocamento horizontal formando a janela `p00..p22` em streaming.

## Estrutura do Repositório
```text
.
├── docs/
│   └── HLD_sobel.md          # High-Level Design, registradores e plano de trade-offs
├── golden/
│   └── golden_sobel.py       # Golden Model bit-accurate em Python gerador de vetores .hex
├── rtl/
│   ├── line_buffer_3x3.sv    # Buffer de 2 linhas e janela deslizante 3x3
│   ├── sobel_core.sv         # Núcleo Sobel com pipeline de 3 estágios e threshold
│   └── sobel_axis.sv         # Wrapper AXI-Stream (s_axis / m_axis, tlast, backpressure)
├── tb/
│   ├── tb_sobel_core.sv      # Teste unitário inicial do núcleo
│   ├── tb_sobel_golden.sv    # Validação automática bit-a-bit vs. Golden Model
│   ├── tb_sobel_stream.sv    # Simulação integrada de streaming (line buffer + core)
│   └── tb_sobel_axis.sv      # Simulação do wrapper AXI-Stream
└── README.md

