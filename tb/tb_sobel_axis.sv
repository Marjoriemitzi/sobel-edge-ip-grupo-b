`timescale 1ns/1ps

module tb_sobel_axis;
    localparam int W = 16;
    localparam int H = 8;
    localparam int N_PIX = W * H;

    logic        aclk = 0;
    logic        aresetn = 0;

    logic [7:0]  s_axis_tdata = 0;
    logic        s_axis_tvalid = 0;
    logic        s_axis_tready;
    logic        s_axis_tlast = 0;

    logic [7:0]  m_axis_tdata;
    logic        m_axis_tvalid;
    logic        m_axis_tready = 1;
    logic        m_axis_tlast;

    logic [10:0] threshold = 11'd100;
    logic [7:0]  img_mem [0:N_PIX-1];

    int tx_out_cnt = 0;
    int edge_out_cnt = 0;
    int tlast_out_cnt = 0;

    always #5 aclk = ~aclk;

    sobel_axis #(.IMG_WIDTH(W), .IMG_HEIGHT(H)) dut (.*);

    initial begin
        $readmemh("input_pixels.hex", img_mem);
        #20 aresetn = 1;

        for (int i = 0; i < N_PIX; i++) begin
            @(negedge aclk);
            s_axis_tvalid = 1'b1;
            s_axis_tdata  = img_mem[i];
            s_axis_tlast  = ((i % W) == (W - 1)) ? 1'b1 : 1'b0;
            @(posedge aclk);
            while (!s_axis_tready) @(posedge aclk);
        end

        @(negedge aclk);
        s_axis_tvalid = 1'b0;
        s_axis_tdata  = 8'h00;
        s_axis_tlast  = 1'b0;

        repeat (15) @(posedge aclk);

        $display("==================================================");
        $display("RESUMO WRAPPER AXI-STREAM SOBEL (%0dx%0d)", W, H);
        $display("Transferencias AXI saida : %0d", tx_out_cnt);
        $display("Pixels borda (0xFF)      : %0d", edge_out_cnt);
        $display("Pulsos m_axis_tlast      : %0d", tlast_out_cnt);
        $display("==================================================");
        $finish;
    end

    always @(posedge aclk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            tx_out_cnt++;
            if (m_axis_tdata == 8'hFF) edge_out_cnt++;
            if (m_axis_tlast) tlast_out_cnt++;
        end
    end
endmodule
