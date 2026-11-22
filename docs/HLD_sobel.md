# High-Level Design (HLD) — Detector de Bordas Sobel (Grupo B)

## 1. Visão Geral da Arquitetura e Integração
- **Papel no sistema:** etapa intermediária do pipeline (`Viola-Jones → Sobel → Hough`), recebendo frames/recortes em escala de cinza de 8 bits via **AXI-Stream** e entregando o mapa de bordas (`0xFF` / `0x00` ou magnitude) também em **AXI-Stream** para a próxima etapa.
- **Restrições e premissas:**
  - Sem multiplicadores dedicados (usa deslocamentos `<< 1` e somadores/subtratores).
  - Sem cálculo de ângulo do gradiente (usa magnitude aproximada $|G_x| + |G_y|$).
  - Limiarização (`threshold`) aplicada na saída para gerar bordas binárias.
  - Meta de referência de desempenho de sistema em torno de **~15 FPS**, exigindo fluxo contínuo sem gargalos de *handshake* (`tvalid`/`tready`).

## 2. Decomposição em Blocos RTL
1. **`line_buffer_3x3.sv`:**
   - Mantém **2 buffers de linha** (linhas `y-1` e `y-2`, com largura parametrizável `IMG_WIDTH`) mais registradores de deslocamento de 3 colunas (`r0_c0..r2_c2`) junto ao pixel atual (`y`).
   - Gera a janela `3×3` (`p00..p22`) em streaming e sinaliza `win_valid` / `win_last` quando a janela completa está formada.
2. **`sobel_core.sv` (Pipeline de 3 estágios):**
   - **Estágio 1:** cálculo de diferenças com deslocamento `<< 1` para os pesos `±2` nos kernels $G_x$ e $G_y$ (pixel central `p11` tem peso `0` e não entra na soma).
   - **Estágio 2:** soma parcial dos termos e registrador de balanceamento para manter os caminhos alinhados em latência.
   - **Estágio 3:** soma final de $G_x$ e $G_y$, cálculo de $|G_x| + |G_y|$ e comparação com `threshold` (`edge_out`).
3. **`sobel_axis.sv` (Wrapper AXI-Stream):**
   - Controla `s_axis_tready` / `m_axis_tvalid` com suporte a *backpressure* (`m_axis_tready`).
   - Propaga `m_axis_tlast` sincronizado com a latência do pipeline (`1` ciclo do line buffer + `3` estágios do core + `1` estágio de saída AXI).

## 3. Mapa de Registradores / Parâmetros de Configuração (base para AXI-Lite)
| Registrador / Parâmetro | Largura / Tipo | Função |
| :--- | :--- | :--- |
| `THRESHOLD` | `11 bits` (RW) | Limiar aplicado sobre $|G_x| + |G_y|$ para gerar `edge_out` (`mag >= threshold`). |
| `IMG_WIDTH` | Parâmetro / RW | Largura da imagem/região em pixels (ex.: `16` no teste unitário; escalável para a resolução de operação). |
| `IMG_HEIGHT` | Parâmetro / RW | Altura da imagem/região em linhas (ex.: `8` no teste unitário; escalável para a resolução de operação). |
| `CTRL / STATUS` (futuro) | RW / RO | Habilitação/reset suave e contadores de diagnóstico (frames/linhas/bordas processadas). |

## 4. Plano de Análise: Área vs. Desempenho e Próximas Etapas
- **Baseline atual:** 1 núcleo `sobel_core` em pipeline de 3 estágios, processando 1 janela por ciclo útil de streaming com área reduzida por evitar multiplicadores e cálculo de ângulo.
- **Comparações planejadas:**
  - Avaliar o *trade-off* entre manter 1 núcleo serial/pipelined (menor área de lógica e buffers) versus variantes com maior paralelismo ou *throughput* em síntese lógica.
  - Expandir o **Golden Model em Python** para testar imagens maiores/reais e validar casos com *backpressure* (`m_axis_tready` alternando) e `s_axis_tlast` explícito.
