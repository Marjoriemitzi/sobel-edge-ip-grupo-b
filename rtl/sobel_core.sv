module sobel_core (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        valid_in,
    input  logic [7:0]  p00, p01, p02,
    input  logic [7:0]  p10, p11, p12, // p11 não entra na conta (peso 0)
    input  logic [7:0]  p20, p21, p22,
    input  logic [10:0] threshold,
    output logic        valid_out,
    output logic [11:0] grad_mag,
    output logic        edge_out
);

    // Estágio 1: Pares de entrada com shifts (x1, x-1, x2, x-2)
    logic signed [10:0] gx_s1_a, gx_s1_b, gx_s1_c;
    logic signed [10:0] gy_s1_a, gy_s1_b, gy_s1_c;
    logic               v_s1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gx_s1_a <= '0; gx_s1_b <= '0; gx_s1_c <= '0;
            gy_s1_a <= '0; gy_s1_b <= '0; gy_s1_c <= '0;
            v_s1    <= 1'b0;
        end else begin
            // Kernel Gx: [-1 0 +1; -2 0 +2; -1 0 +1]
            gx_s1_a <= $signed({3'b0, p02}) - $signed({3'b0, p00});
            gx_s1_b <= $signed({2'b0, p12, 1'b0}) - $signed({2'b0, p10, 1'b0}); // << 1
            gx_s1_c <= $signed({3'b0, p22}) - $signed({3'b0, p20});

            // Kernel Gy: [-1 -2 -1; 0 0 0; +1 +2 +1]
            gy_s1_a <= $signed({3'b0, p20}) - $signed({3'b0, p00});
            gy_s1_b <= $signed({2'b0, p21, 1'b0}) - $signed({2'b0, p01, 1'b0}); // << 1
            gy_s1_c <= $signed({3'b0, p22}) - $signed({3'b0, p02});

            v_s1    <= valid_in;
        end
    end

    // Estágio 2: Soma parcial (b + c) e registrador de balanceamento para (a)
    logic signed [11:0] gx_s2_a_dly, gx_s2_bc;
    logic signed [11:0] gy_s2_a_dly, gy_s2_bc;
    logic               v_s2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gx_s2_a_dly <= '0; gx_s2_bc <= '0;
            gy_s2_a_dly <= '0; gy_s2_bc <= '0;
            v_s2        <= 1'b0;
        end else begin
            gx_s2_a_dly <= gx_s1_a;
            gx_s2_bc    <= gx_s1_b + gx_s1_c;

            gy_s2_a_dly <= gy_s1_a;
            gy_s2_bc    <= gy_s1_b + gy_s1_c;

            v_s2        <= v_s1;
        end
    end

    // Estágio 3: Soma final, magnitude |Gx| + |Gy| e limiarização (3ª batida do clock)
    logic signed [11:0] gx_final, gy_final;
    logic        [11:0] abs_gx, abs_gy, mag_comb;

    always_comb begin
        gx_final = gx_s2_a_dly + gx_s2_bc;
        gy_final = gy_s2_a_dly + gy_s2_bc;
        abs_gx   = (gx_final < 0) ? -gx_final : gx_final;
        abs_gy   = (gy_final < 0) ? -gy_final : gy_final;
        mag_comb = abs_gx + abs_gy;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grad_mag  <= '0;
            edge_out  <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            grad_mag  <= mag_comb;
            edge_out  <= (mag_comb >= threshold);
            valid_out <= v_s2;
        end
    end

endmodule
