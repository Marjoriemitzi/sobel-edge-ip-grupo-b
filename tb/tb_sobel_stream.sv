`timescale 1ns/1ps

module tb_sobel_stream;
    localparam int W = 16;
    localparam int H = 8;
    localparam int N_PIX = W * H;

    logic        clk = 0;
    logic        rst_n = 0;
    logic        valid_in = 0;
    logic [7:0]  pixel_in = 0;
    logic [10:0] threshold = 11'd100;

    logic        win_valid;
    logic [7:0]  p00, p01, p02, p10, p11, p12, p20, p21, p22;
    logic        valid_out;
    logic [11:0] grad_mag;
    logic        edge_out;

    logic [7:0]  img_mem [0:N_PIX-1];
    int          edge_count = 0;
    int          valid_out_count = 0;

    always #5 clk = ~clk;

    line_buffer_3x3 #(.IMG_WIDTH(W), .IMG_HEIGHT(H)) u_lb (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .pixel_in(pixel_in),
        .win_valid(win_valid),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22)
    );

    sobel_core u_core (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(win_valid),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .threshold(threshold),
        .valid_out(valid_out),
        .grad_mag(grad_mag),
        .edge_out(edge_out)
    );

    initial begin
        $readmemh("input_pixels.hex", img_mem);
        #20 rst_n = 1;

        for (int i = 0; i < N_PIX; i++) begin
            @(negedge clk);
            valid_in = 1'b1;
            pixel_in = img_mem[i];
        end

        @(negedge clk);
        valid_in = 1'b0;
        pixel_in = 8'd0;

        repeat (12) @(posedge clk);

        $display("==================================================");
        $display("RESUMO SIMULACAO SOBEL STREAMING (%0dx%0d)", W, H);
        $display("Total de pixels de entrada : %0d", N_PIX);
        $display("Total de saidas validas    : %0d", valid_out_count);
        $display("Pixels com borda (edge=1)  : %0d (threshold=%0d)", edge_count, threshold);
        $display("==================================================");
        $finish;
    end

    always @(posedge clk) begin
        if (valid_out) begin
            valid_out_count++;
            if (edge_out) begin
                edge_count++;
                $display("t=%0t ps | out#%0d | mag=%0d | edge=1",
                         $time, valid_out_count, grad_mag);
            end
        end
    end
endmodule
