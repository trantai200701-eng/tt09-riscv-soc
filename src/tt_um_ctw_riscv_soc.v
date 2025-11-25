/*
 * Tiny Tapeout RISC-V SoC (CTW Edition)
 * Top Level Module: Integrates CPU, SPI XIP, RAM, and UART
 * UPDATE: Reduced RAM to 64 Bytes to fit in 2x2 Tiles
 */

`default_nettype none

module tt_um_ctw_riscv_soc (
    input  wire [7:0] ui_in,    
    output wire [7:0] uo_out,   
    input  wire [7:0] uio_in,   
    output wire [7:0] uio_out,  
    output wire [7:0] uio_oe,   
    input  wire       ena,      
    input  wire       clk,      
    input  wire       rst_n     
);

    // CPU Signals
    wire [23:0] cpu_i_addr;
    wire        cpu_i_req;
    wire        cpu_i_ack;
    wire [31:0] cpu_i_inst;
    
    wire [31:0] cpu_d_addr;
    wire [31:0] cpu_d_wdata;
    wire        cpu_d_wen;
    reg  [31:0] cpu_d_rdata;

    // SPI Signals
    wire spi_cs_n, spi_sck, spi_mosi;
    wire spi_miso;

    // Pin Mapping
    assign uo_out[0] = spi_mosi;
    assign uo_out[1] = spi_cs_n;
    assign uo_out[2] = spi_sck;
    assign spi_miso  = ui_in[0];

    // UART & GPIO
    wire uart_tx;
    assign uo_out[3] = uart_tx;

    reg [3:0] gpio_out_reg;
    assign uo_out[7:4] = gpio_out_reg;
    wire [6:0] gpio_in = ui_in[7:1];

    assign uio_out = 0;
    assign uio_oe  = 0;

    // --- INSTANCE: SPI XIP CONTROLLER ---
    spi_xip xip_inst (
        .clk(clk), .rst_n(rst_n),
        .req(cpu_i_req), .addr(cpu_i_addr), .ack(cpu_i_ack), .data_out(cpu_i_inst),
        .spi_cs_n(spi_cs_n), .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_miso(spi_miso)
    );

    // --- INSTANCE: SIMPLE RISC-V CPU ---
    simple_cpu cpu_inst (
        .clk(clk), .rst_n(rst_n),
        .i_addr(cpu_i_addr), .i_req(cpu_i_req), .i_ack(cpu_i_ack), .i_inst(cpu_i_inst),
        .d_addr(cpu_d_addr), .d_wdata(cpu_d_wdata), .d_wen(cpu_d_wen), .d_rdata(cpu_d_rdata)
    );

    // --- INTERNAL RAM (REDUCED to 64 Bytes = 16 Words) ---
    // Address range: 0x2000_0000 to 0x2000_003F
    reg [31:0] ram [0:15]; // Reduced size
    
    // RAM Write Logic
    always @(posedge clk) begin
        if (cpu_d_wen && cpu_d_addr[29] && !cpu_d_addr[30]) begin
            // Use addr[5:2] for 16 words index
            ram[cpu_d_addr[5:2]] <= cpu_d_wdata;
        end
    end

    // --- PERIPHERALS & READ MUX ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_out_reg <= 0;
        end else begin
            if (cpu_d_wen && cpu_d_addr[30]) begin 
                if (cpu_d_addr[3:0] == 4'h0) gpio_out_reg <= cpu_d_wdata[3:0];
            end
        end
    end
    
    assign uart_tx = gpio_out_reg[3]; 

    // Read Data Mux
    always @(*) begin
        cpu_d_rdata = 0;
        // Internal RAM Read
        if (cpu_d_addr[29]) begin
            cpu_d_rdata = ram[cpu_d_addr[5:2]];
        end
        // Peripheral Read
        else if (cpu_d_addr[30]) begin
            if (cpu_d_addr[3:0] == 4'h4) begin
                cpu_d_rdata = {25'b0, gpio_in};
            end
        end
    end

endmodule
`default_nettype wire
