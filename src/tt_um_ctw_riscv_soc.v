/*
 * Tiny Tapeout RISC-V SoC (CTW Edition)
 * Top Level Module: Integrates CPU, SPI XIP, RAM, and UART
 */

`default_nettype none

module tt_um_ctw_riscv_soc (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // --- Wire Declarations ---
    // CPU Signals
    wire [23:0] cpu_i_addr;
    wire        cpu_i_req;
    wire        cpu_i_ack;
    wire [31:0] cpu_i_inst;
    
    wire [31:0] cpu_d_addr;
    wire [31:0] cpu_d_wdata;
    wire        cpu_d_wen;
    reg  [31:0] cpu_d_rdata;

    // SPI XIP Signals
    wire spi_cs_n, spi_sck, spi_mosi;
    wire spi_miso;

    // --- Pin Mapping ---
    // SPI Flash: uo_out[0]=MOSI, uo_out[1]=CS, uo_out[2]=SCK. ui_in[0]=MISO
    assign uo_out[0] = spi_mosi;
    assign uo_out[1] = spi_cs_n;
    assign uo_out[2] = spi_sck;
    assign spi_miso  = ui_in[0];

    // UART TX: uo_out[3]
    wire uart_tx;
    assign uo_out[3] = uart_tx;

    // GPIO Out (LEDs): uo_out[7:4]
    reg [3:0] gpio_out_reg;
    assign uo_out[7:4] = gpio_out_reg;

    // GPIO In (Switches): ui_in[7:1] (Skip bit 0 used for MISO)
    wire [6:0] gpio_in = ui_in[7:1];

    // Unused outputs
    assign uio_out = 0;
    assign uio_oe  = 0; // All bidirectional pins as inputs

    // --- 1. INSTANCE: SPI XIP CONTROLLER ---
    spi_xip xip_inst (
        .clk(clk), .rst_n(rst_n),
        .req(cpu_i_req), 
        .addr(cpu_i_addr), 
        .ack(cpu_i_ack), 
        .data_out(cpu_i_inst),
        .spi_cs_n(spi_cs_n), 
        .spi_sck(spi_sck), 
        .spi_mosi(spi_mosi), 
        .spi_miso(spi_miso)
    );

    // --- 2. INSTANCE: SIMPLE RISC-V CPU ---
    simple_cpu cpu_inst (
        .clk(clk), .rst_n(rst_n),
        .i_addr(cpu_i_addr), 
        .i_req(cpu_i_req), 
        .i_ack(cpu_i_ack), 
        .i_inst(cpu_i_inst),
        .d_addr(cpu_d_addr), 
        .d_wdata(cpu_d_wdata), 
        .d_wen(cpu_d_wen), 
        .d_rdata(cpu_d_rdata)
    );

    // --- 3. INTERNAL RAM (128 Bytes = 32 Words) ---
    // Address range: 0x2000_0000 to 0x2000_007F
    // Mapped simply by checking d_addr[29] (bit 29 is high for 0x20...)
    reg [31:0] ram [0:31];
    
    // RAM Write Logic
    always @(posedge clk) begin
        if (cpu_d_wen && cpu_d_addr[29] && !cpu_d_addr[30]) begin
            ram[cpu_d_addr[6:2]] <= cpu_d_wdata;
        end
    end

    // --- 4. PERIPHERALS & READ MUX ---
    // UART Logic (Minimal Bit-Bang Hardware Assist)
    // Address: 0x4000_0008
    reg [8:0] uart_shifter;
    reg [12:0] uart_div; // Baudrate divider
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_out_reg <= 0;
            uart_shifter <= 0;
            uart_div     <= 0;
        end else begin
            // GPIO Write (Addr: 0x4000_0000)
            if (cpu_d_wen && cpu_d_addr[30]) begin 
                if (cpu_d_addr[3:0] == 4'h0) gpio_out_reg <= cpu_d_wdata[3:0];
                
                // UART Write (Addr: 0x4000_0008) -> Starts transmission
                if (cpu_d_addr[3:0] == 4'h8) begin
                    uart_shifter <= {cpu_d_wdata[7:0], 1'b0}; // Load data + Start bit (0)
                    uart_div <= 0;
                end
            end
            
            // UART Shifting (Fixed baudrate approximation)
            // If shifter is not empty (has logic 0 start bit or data), shift it out.
            // When Idle, Line should be High. Here we inverse logic:
            // Let's keep it simple: We shift out. 
            // Better: Simple counter. If uart_shifter != 0 (wait, idle is 1...)
            // Let's implement a super dumb shifter: 
            // Write triggers a countdown.
            
            // NOTE: For simplicity in this constrained code, we will rely on
            // CPU delay loops for timing bit-banging if this HW is too complex.
            // BUT, let's try a simple shift register:
            if (uart_div == 100) begin // Arbitrary divider for simulation
                 // Shift out LSB. Default idle state should be 1.
                 // This requires a slightly more complex FSM.
                 // Let's revert to GPIO Bitbanging for SAFETY if area is tight.
                 // Just map GPIO[3] to UART_TX and let software do timing.
                 // REVISION: Map GPIO Out Bit 3 to UART TX pin directly.
            end
        end
    end
    
    // Simpler UART/GPIO Mapping:
    // uo_out[3] (UART) is just gpio_out_reg[3].
    // CPU software is responsible for timing (bit-banging).
    assign uart_tx = gpio_out_reg[3]; 

    // --- Read Data Mux ---
    always @(*) begin
        cpu_d_rdata = 0;
        
        // Internal RAM Read (0x2000_XXXX)
        if (cpu_d_addr[29]) begin
            cpu_d_rdata = ram[cpu_d_addr[6:2]];
        end
        // Peripheral Read (0x4000_XXXX)
        else if (cpu_d_addr[30]) begin
            // GPIO Input (Address 0x4000_0004)
            if (cpu_d_addr[3:0] == 4'h4) begin
                cpu_d_rdata = {25'b0, gpio_in};
            end
        end
    end

endmodule
`default_nettype wire
