`timescale 1ns/1ps

module tb_sobel_core;
    logic        clk = 0;
    logic        rst_n = 0;
    logic        valid_in = 0;
    logic [7:0]  p00, p01, p02, p10, p11, p12, p20, p21, p22;
    logic [10:0] threshold = 11'd100;
    logic        valid_out;
    logic [11:0] grad_mag;
    logic        edge_out;

    always #5 clk = ~clk; // Clock de 100 MHz (período = 10 ns)

    sobel_core dut (.*);

    initial begin
        $dumpfile("sobel.vcd");
        $dumpvars(0, tb_sobel_core);

        // Reset
        {p00,p01,p02,p10,p11,p12,p20,p21,p22} = '0;
        #20 rst_n = 1;

        // Ciclo 1: Região uniforme (tudo 10) -> esperado |Gx|+|Gy| = 0
        @(negedge clk);
        valid_in = 1;
        {p00,p01,p02} = {8'd10, 8'd10, 8'd10};
        {p10,p11,p12} = {8'd10, 8'd10, 8'd10};
        {p20,p21,p22} = {8'd10, 8'd10, 8'd10};

        // Ciclo 2: Transição vertical (10 | 10 | 50) -> esperado Gx = +160, Gy = 0
        @(negedge clk);
        {p00,p01,p02} = {8'd10, 8'd10, 8'd50};
        {p10,p11,p12} = {8'd10, 8'd10, 8'd50};
        {p20,p21,p22} = {8'd10, 8'd10, 8'd50};

        // Ciclo 3: Encerra estímulos
        @(negedge clk);
        valid_in = 0;

        #60 $finish;
    end

    always @(posedge clk) begin
        if (valid_out)
            $display("t=%0t | mag=%0d | edge=%0b", $time, grad_mag, edge_out);
    end
endmodule
