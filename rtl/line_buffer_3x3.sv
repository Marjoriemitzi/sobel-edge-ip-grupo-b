module line_buffer_3x3 #(
    parameter int IMG_WIDTH  = 16,
    parameter int IMG_HEIGHT = 8
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       en,
    input  logic       valid_in,
    input  logic [7:0] pixel_in,
    output logic       win_valid,
    output logic       win_last,
    output logic [7:0] p00, p01, p02,
    output logic [7:0] p10, p11, p12,
    output logic [7:0] p20, p21, p22
);

    logic [7:0] line1 [0:IMG_WIDTH-1];
    logic [7:0] line2 [0:IMG_WIDTH-1];

    logic [7:0] r0_c0, r0_c1, r0_c2;
    logic [7:0] r1_c0, r1_c1, r1_c2;
    logic [7:0] r2_c0, r2_c1, r2_c2;

    logic [$clog2(IMG_WIDTH):0]  col_cnt;
    logic [$clog2(IMG_HEIGHT):0] row_cnt;
    logic                        v_d1;
    logic                        last_win_d1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_cnt     <= '0;
            row_cnt     <= '0;
            v_d1        <= 1'b0;
            last_win_d1 <= 1'b0;
            r0_c0 <= '0; r0_c1 <= '0; r0_c2 <= '0;
            r1_c0 <= '0; r1_c1 <= '0; r1_c2 <= '0;
            r2_c0 <= '0; r2_c1 <= '0; r2_c2 <= '0;
            for (int i = 0; i < IMG_WIDTH; i++) begin
                line1[i] <= '0;
                line2[i] <= '0;
            end
        end else if (en) begin
            v_d1 <= valid_in;

            if (valid_in) begin
                logic [7:0] l1_val, l2_val;
                l1_val = line1[col_cnt];
                l2_val = line2[col_cnt];

                line2[col_cnt] <= l1_val;
                line1[col_cnt] <= pixel_in;

                r0_c2 <= l2_val;
                r0_c1 <= r0_c2;
                r0_c0 <= r0_c1;

                r1_c2 <= l1_val;
                r1_c1 <= r1_c2;
                r1_c0 <= r1_c1;

                r2_c2 <= pixel_in;
                r2_c1 <= r2_c2;
                r2_c0 <= r2_c1;

                last_win_d1 <= (row_cnt >= 2) && (col_cnt == IMG_WIDTH - 1);

                if (col_cnt == IMG_WIDTH - 1) begin
                    col_cnt <= '0;
                    if (row_cnt == IMG_HEIGHT - 1)
                        row_cnt <= '0;
                    else
                        row_cnt <= row_cnt + 1'b1;
                end else begin
                    col_cnt <= col_cnt + 1'b1;
                end
            end else begin
                last_win_d1 <= 1'b0;
            end
        end
    end

    always_comb begin
        p00 = r0_c0; p01 = r0_c1; p02 = r0_c2;
        p10 = r1_c0; p11 = r1_c1; p12 = r1_c2;
        p20 = r2_c0; p21 = r2_c1; p22 = r2_c2;

        win_valid = v_d1 && (row_cnt >= 2) && ((col_cnt >= 3) || (col_cnt == 0));
        win_last  = win_valid && last_win_d1;
    end

endmodule
