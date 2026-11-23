module sobel_core (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        en,
    input  logic        valid_in,
    input  logic [7:0]  p00, p01, p02,
    input  logic [7:0]  p10, p11, p12,
    input  logic [7:0]  p20, p21, p22,
    input  logic [10:0] threshold,
    output logic        valid_out,
    output logic [11:0] grad_mag,
    output logic        edge_out
);

    // Estagio 1: termos ponderados para Gx e Gy (sem multiplicadores; p11 tem peso 0)
    logic signed [10:0] s1_gx_r_term, s1_gx_c_term, s1_gx_l_term;
    logic signed [10:0] s1_gy_b_term, s1_gy_c_term, s1_gy_t_term;
    logic [10:0]        s1_thresh;
    logic               s1_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_gx_r_term <= '0; s1_gx_c_term <= '0; s1_gx_l_term <= '0;
            s1_gy_b_term <= '0; s1_gy_c_term <= '0; s1_gy_t_term <= '0;
            s1_thresh    <= '0;
            s1_valid     <= 1'b0;
        end else if (en) begin
            s1_gx_r_term <= $signed({3'b0, p02});
            s1_gx_c_term <= $signed({2'b0, p12, 1'b0}) - $signed({2'b0, p10, 1'b0});
            s1_gx_l_term <= -$signed({3'b0, p00}) + $signed({3'b0, p22}) - $signed({3'b0, p20});

            s1_gy_b_term <= $signed({3'b0, p20}) + $signed({3'b0, p22});
            s1_gy_c_term <= $signed({2'b0, p21, 1'b0}) - $signed({2'b0, p01, 1'b0});
            s1_gy_t_term <= -$signed({3'b0, p00}) - $signed({3'b0, p02});

            s1_thresh    <= threshold;
            s1_valid     <= valid_in;
        end
    end

    // Estagio 2: somas parciais
    logic signed [11:0] s2_gx;
    logic signed [11:0] s2_gy;
    logic [10:0]        s2_thresh;
    logic               s2_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s2_gx     <= '0;
            s2_gy     <= '0;
            s2_thresh <= '0;
            s2_valid  <= 1'b0;
        end else if (en) begin
            s2_gx     <= $signed(s1_gx_r_term) + $signed(s1_gx_c_term) + $signed(s1_gx_l_term);
            s2_gy     <= $signed(s1_gy_b_term) + $signed(s1_gy_c_term) + $signed(s1_gy_t_term);
            s2_thresh <= s1_thresh;
            s2_valid  <= s1_valid;
        end
    end

    // Estagio 3: |Gx| + |Gy| e limiarizacao
    logic [11:0] abs_gx, abs_gy, sum_mag;
    always_comb begin
        abs_gx  = s2_gx[11] ? (~s2_gx + 12'd1) : s2_gx;
        abs_gy  = s2_gy[11] ? (~s2_gy + 12'd1) : s2_gy;
        sum_mag = abs_gx + abs_gy;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grad_mag  <= '0;
            edge_out  <= 1'b0;
            valid_out <= 1'b0;
        end else if (en) begin
            grad_mag  <= sum_mag;
            edge_out  <= (sum_mag >= {1'b0, s2_thresh});
            valid_out <= s2_valid;
        end
    end

endmodule
