module sobel_axis #(
    parameter int IMG_WIDTH  = 16,
    parameter int IMG_HEIGHT = 8
) (
    input  logic        aclk,
    input  logic        aresetn,

    input  logic [7:0]  s_axis_tdata,
    input  logic        s_axis_tvalid,
    output logic        s_axis_tready,
    input  logic        s_axis_tlast,

    output logic [7:0]  m_axis_tdata,
    output logic        m_axis_tvalid,
    input  logic        m_axis_tready,
    output logic        m_axis_tlast,

    input  logic [10:0] threshold
);

    logic        win_valid;
    logic        win_last;
    logic [7:0]  p00, p01, p02, p10, p11, p12, p20, p21, p22;

    logic        core_valid_out;
    logic [11:0] grad_mag;
    logic        edge_out;

    wire pipe_ready = m_axis_tready || !m_axis_tvalid;
    wire s_fire     = s_axis_tvalid && s_axis_tready;

    assign s_axis_tready = pipe_ready;

    line_buffer_3x3 #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT)
    ) u_line_buf (
        .clk(aclk),
        .rst_n(aresetn),
        .valid_in(s_fire),
        .pixel_in(s_axis_tdata),
        .win_valid(win_valid),
        .win_last(win_last),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22)
    );

    sobel_core u_sobel_core (
        .clk(aclk),
        .rst_n(aresetn),
        .valid_in(win_valid && pipe_ready),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .threshold(threshold),
        .valid_out(core_valid_out),
        .grad_mag(grad_mag),
        .edge_out(edge_out)
    );

    // 3 ciclos dentro do sobel_core: entra no ciclo 0, sai de core_valid_out no ciclo 3
    logic [2:0] last_in_core;
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            last_in_core <= 3'b0;
        end else if (pipe_ready) begin
            last_in_core <= {last_in_core[1:0], (win_valid && pipe_ready && win_last)};
        end
    end

    // Registrador de saida AXI-Stream (1 ciclo apos core_valid_out)
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata  <= 8'h00;
            m_axis_tlast  <= 1'b0;
        end else if (pipe_ready) begin
            m_axis_tvalid <= core_valid_out;
            m_axis_tdata  <= edge_out ? 8'hFF : 8'h00;
            m_axis_tlast  <= core_valid_out ? last_in_core[2] : 1'b0;
        end
    end

endmodule
