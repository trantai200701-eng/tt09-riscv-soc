/*
 * Tiny Tapeout RISC-V SoC
 * Module: SPI XIP Controller (Phase Corrected)
 */
module spi_xip (
    input  wire        clk,        
    input  wire        rst_n,      
    input  wire        req,        
    input  wire [23:0] addr,       
    output reg         ack,        
    output reg  [31:0] data_out,   
    output reg         spi_cs_n,   
    output wire        spi_sck,    
    output reg         spi_mosi,   
    input  wire        spi_miso    
);
    localparam S_IDLE=0, S_SEND_CMD=1, S_SEND_ADDR=2, S_READ_DATA=3, S_DONE=4;
    reg [2:0] state, next_state;
    reg [5:0] bit_cnt;
    reg [31:0] shift_reg;

    always @(posedge clk or negedge rst_n) if (!rst_n) state <= S_IDLE; else state <= next_state;

    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:      if (req) next_state = S_SEND_CMD;
            S_SEND_CMD:  if (bit_cnt == 0) next_state = S_SEND_ADDR;
            S_SEND_ADDR: if (bit_cnt == 0) next_state = S_READ_DATA;
            S_READ_DATA: if (bit_cnt == 0) next_state = S_DONE;
            S_DONE:      next_state = S_IDLE;
            default:     next_state = S_IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_cs_n <= 1'b1; spi_mosi <= 1'b0; ack <= 1'b0;
            bit_cnt <= 0; shift_reg <= 0; data_out <= 0;
        end else begin
            ack <= 1'b0;
            case (state)
                S_IDLE: begin
                    spi_cs_n <= 1'b1;
                    if (req) begin
                        spi_cs_n <= 1'b0; bit_cnt <= 7; shift_reg <= 32'h03000000; 
                    end
                end
                S_SEND_CMD, S_SEND_ADDR: begin
                    spi_mosi <= shift_reg[31];
                    shift_reg <= {shift_reg[30:0], 1'b0};
                    if (bit_cnt == 0) begin
                        bit_cnt <= (state == S_SEND_CMD) ? 23 : 31;
                        shift_reg <= (state == S_SEND_CMD) ? {addr, 8'h00} : 0;
                    end else bit_cnt <= bit_cnt - 1;
                end
                S_READ_DATA: begin
                    spi_mosi <= 1'b0;
                    shift_reg <= {shift_reg[30:0], spi_miso};
                    if (bit_cnt != 0) bit_cnt <= bit_cnt - 1;
                end
                S_DONE: begin
                    spi_cs_n <= 1'b1; ack <= 1'b1; data_out <= shift_reg; 
                end
            endcase
        end
    end
    // FIX: Clock phase alignment
    assign spi_sck = (state == S_SEND_CMD || state == S_SEND_ADDR || state == S_READ_DATA) ? clk : 1'b0;
endmodule
