`timescale 1ns/1ps

module tb_sobel_axis_64x48;
    localparam int W = 64;
    localparam int H = 48;
    localparam int N_PIX = W * H;
    localparam int N_EXP = (W - 2) * (H - 2); // 2852

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
    logic [7:0]  exp_mem [0:N_EXP-1];

    int tx_out_cnt = 0;
    int edge_out_cnt = 0;
    int tlast_out_cnt = 0;
    int mismatch_cnt = 0;
    int wait_cycles = 0;

    always #5 aclk = ~aclk;

    sobel_axis #(.IMG_WIDTH(W), .IMG_HEIGHT(H)) dut (.*);

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn)
            m_axis_tready <= 1'b1;
        else
            m_axis_tready <= (($urandom % 100) < 85);
    end

    initial begin
        $readmemh("build_img/input_pixels_64x48.hex", img_mem);
        $readmemh("build_img/expected_edges_64x48.hex", exp_mem);

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

        while ((tx_out_cnt < N_EXP) && (wait_cycles < 3000)) begin
            @(posedge aclk);
            wait_cycles++;
        end
        repeat (5) @(posedge aclk);

        $display("==================================================");
        $display("SIMULACAO AXI-STREAM SOBEL (%0dx%0d)", W, H);
        $display("Transferencias saida : %0d / %0d esperadas", tx_out_cnt, N_EXP);
        $display("Pixels borda (0xFF)  : %0d", edge_out_cnt);
        $display("Pulsos m_axis_tlast  : %0d", tlast_out_cnt);
        $display("Divergencias vs GM   : %0d", mismatch_cnt);
        $display("Status               : %s", ((tx_out_cnt == N_EXP) && (mismatch_cnt == 0)) ? "PASSOU" : "FALHOU");
        $display("==================================================");
        $finish;
    end

    always @(posedge aclk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            if (tx_out_cnt < N_EXP) begin
                if (m_axis_tdata !== exp_mem[tx_out_cnt]) begin
                    if (mismatch_cnt < 10)
                        $display("Mismatch idx=%0d: RTL=%h | Golden=%h", tx_out_cnt, m_axis_tdata, exp_mem[tx_out_cnt]);
                    mismatch_cnt++;
                end
            end
            tx_out_cnt++;
            if (m_axis_tdata == 8'hFF) edge_out_cnt++;
            if (m_axis_tlast) tlast_out_cnt++;
        end
    end
endmodule
