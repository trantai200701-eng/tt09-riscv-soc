`default_nettype none
`timescale 1ns/1ps

module tb;
    reg clk, rst_n;
    reg [7:0] ui_in, uio_in;
    wire [7:0] uo_out, uio_out, uio_oe;

    tt_um_ctw_riscv_soc dut (
        .ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in),
        .uio_out(uio_out), .uio_oe(uio_oe), .ena(1'b1), .clk(clk), .rst_n(rst_n)
    );

    initial begin clk = 0; forever #10 clk = ~clk; end

    wire spi_cs_n = uo_out[1];
    wire spi_sck  = uo_out[2];
    reg  spi_miso;
    always @(*) ui_in[0] = spi_miso;

    reg [31:0] rom [0:15];
    initial begin
        rom[0] = 32'h00100093; // ADDI x1, x0, 1
        rom[1] = 32'h00000113; // ADDI x2, x0, 0
        rom[2] = 32'h00110133; // ADD  x2, x2, x1
        rom[3] = 32'h400001b7; // LUI x3, 0x40000
        rom[4] = 32'h0021a023; // SW x2, 0(x3)  <-- LED ON
        rom[5] = 32'hff9ff06f; // JAL x0, -8
        rom[6] = 32'h00000013; // NOP
    end

    integer bit_idx, word_idx;
    initial begin
        spi_miso = 0; word_idx = 0;
        wait(rst_n === 1'b1);
        forever begin
            @(negedge spi_cs_n);
            // FIX: Increased latency delay to match RTL
            repeat(33) @(posedge spi_sck); 
            
            if (word_idx > 6) word_idx = 5;
            $display("[%t] SPI Sending Word[%0d]: %h", $time, word_idx, rom[word_idx]);
            
            spi_miso = rom[word_idx][31];
            @(posedge spi_sck);
            for (bit_idx = 30; bit_idx >= 0; bit_idx = bit_idx - 1) begin
                @(negedge spi_sck); spi_miso = rom[word_idx][bit_idx];
            end
            @(posedge spi_cs_n); word_idx = word_idx + 1;
        end
    end

    initial begin
        $dumpfile("tb.vcd"); $dumpvars(0, tb);
        ui_in = 0; uio_in = 0; rst_n = 0;
        #200; rst_n = 1;
        #50000; $display("[%t] --- Timeout ---", $time); $finish;
    end
    
    always @(posedge clk) if (dut.cpu_d_wen && dut.cpu_d_addr[30]) 
        $display("\n!!! [%t] SUCCESS: GPIO WRITE DETECTED! Addr: %h, Data: %h (LEDs: %b)\n", 
                 $time, dut.cpu_d_addr, dut.cpu_d_wdata, uo_out[7:4]);
endmodule
