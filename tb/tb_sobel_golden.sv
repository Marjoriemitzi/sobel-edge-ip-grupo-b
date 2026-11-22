`timescale 1ns/1ps

module tb_sobel_golden;
    localparam int N_VEC = 84; // (16-2) * (8-2) = 14 * 6 = 84 janelas

    logic        clk = 0;
    logic        rst_n = 0;
    logic        valid_in = 0;
    logic [7:0]  p00, p01, p02, p10, p11, p12, p20, p21, p22;
    logic [10:0] threshold = 11'd100;
    logic        valid_out;
    logic [11:0] grad_mag;
    logic        edge_out;

    logic [71:0] win_mem  [0:N_VEC-1];
    logic [11:0] exp_mag  [0:N_VEC-1];
    logic        exp_edge [0:N_VEC-1];

    always #5 clk = ~clk;

    sobel_core dut (.*);

    int errors = 0;
    int out_idx = 0;

    initial begin
        $readmemh("windows_3x3.hex", win_mem);
        $readmemh("expected_mag.hex", exp_mag);
        $readmemh("expected_edge.hex", exp_edge);

        {p00,p01,p02,p10,p11,p12,p20,p21,p22} = '0;
        #20 rst_n = 1;

        for (int i = 0; i < N_VEC; i++) begin
            @(negedge clk);
            valid_in = 1'b1;
            {p00,p01,p02,p10,p11,p12,p20,p21,p22} = win_mem[i];
        end

        @(negedge clk);
        valid_in = 1'b0;
        {p00,p01,p02,p10,p11,p12,p20,p21,p22} = '0;

        repeat (10) @(posedge clk);

        if (out_idx != N_VEC) begin
            $display("AVISO: esperadas %0d saidas validas, recebidas %0d", N_VEC, out_idx);
            errors++;
        end

        if (errors == 0)
            $display("SUCESSO! Todas as %0d saidas bateram bit-a-bit com o Golden Model.", out_idx);
        else
            $display("FALHA: %0d erro(s) encontrado(s).", errors);

        $finish;
    end

    always @(posedge clk) begin
        if (valid_out) begin
            if (grad_mag !== exp_mag[out_idx] || edge_out !== exp_edge[out_idx]) begin
                $display("ERRO idx=%0d | RTL mag=%0d edge=%0b || EXP mag=%0d edge=%0b",
                         out_idx, grad_mag, edge_out, exp_mag[out_idx], exp_edge[out_idx]);
                errors++;
            end
            out_idx++;
        end
    end
endmodule
