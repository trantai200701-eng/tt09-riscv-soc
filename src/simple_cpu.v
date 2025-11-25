/*
 * Tiny Tapeout RISC-V SoC
 * Module: Simple RV32E Core (Fixed & Debug Ready)
 */

module simple_cpu (
    input  wire        clk,
    input  wire        rst_n,

    // Instruction Interface
    output reg  [23:0] i_addr,     
    output reg         i_req,      
    input  wire        i_ack,      
    input  wire [31:0] i_inst,     

    // Data Memory Interface
    output reg  [31:0] d_addr,
    output reg  [31:0] d_wdata,
    output reg         d_wen,      
    input  wire [31:0] d_rdata     
);

    reg [31:0] regs [0:15]; 
    reg [31:0] pc;
    
    localparam S_FETCH   = 0;
    localparam S_DECODE  = 1;
    localparam S_MEM     = 3; 
    
    reg [1:0] state;
    reg [31:0] instr; 

    // Decoding Helpers
    wire [6:0] opcode = instr[6:0];
    wire [4:0] rd     = instr[11:7];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];
    wire [2:0] funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];

    // Read Registers
    wire [31:0] r1_val = (rs1 == 0) ? 0 : regs[rs1[3:0]]; 
    wire [31:0] r2_val = (rs2 == 0) ? 0 : regs[rs2[3:0]];

    // ALU Logic
    reg [31:0] alu_result;
    reg branch_take;
    
    // Immediate decoding (Inline inside always block to prevent binding errors)
    wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
    wire [31:0] imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};

    always @(*) begin
        alu_result = 0;
        branch_take = 0;
        case (opcode)
            7'b0110011: begin // R-Type
                case (funct3)
                    3'b000: alu_result = (funct7[5]) ? (r1_val - r2_val) : (r1_val + r2_val);
                    3'b100: alu_result = r1_val ^ r2_val;
                    3'b110: alu_result = r1_val | r2_val;
                    3'b111: alu_result = r1_val & r2_val;
                    3'b010: alu_result = ($signed(r1_val) < $signed(r2_val)) ? 1 : 0;
                    default: alu_result = 0;
                endcase
            end
            7'b0010011: begin // I-Type
                case (funct3)
                    3'b000: alu_result = r1_val + imm_i; 
                    3'b100: alu_result = r1_val ^ imm_i; 
                    3'b110: alu_result = r1_val | imm_i; 
                    3'b111: alu_result = r1_val & imm_i; 
                    default: alu_result = 0;
                endcase
            end
            7'b1100011: begin // Branch
                case (funct3)
                    3'b000: branch_take = (r1_val == r2_val);
                    3'b001: branch_take = (r1_val != r2_val);
                    default: branch_take = 0;
                endcase
            end
            default: alu_result = 0;
        endcase
    end

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_FETCH;
            pc    <= 0;
            i_req <= 0;
            d_wen <= 0;
            for (i=0; i<16; i=i+1) regs[i] <= 0;
        end else begin
            case (state)
                S_FETCH: begin
                    i_addr <= pc[23:0];
                    i_req  <= 1'b1; 
                    d_wen  <= 1'b0; 
                    
                    if (i_ack) begin
                        instr <= i_inst;
                        i_req <= 1'b0;
                        state <= S_DECODE;
                    end
                end

                S_DECODE: begin
                    pc <= pc + 4; 
                    state <= S_FETCH; 

                    // --- DIAGNOSTIC PRINT ---
                    // This will tell us EXACTLY what the CPU sees
                    $display("[CPU] PC=%h | RAW INSTR=%h | Opcode=%b", pc, instr, opcode);

                    case (opcode)
                        // LUI
                        7'b0110111: if (rd!=0) regs[rd[3:0]] <= {instr[31:12], 12'b0}; 
                        
                        // AUIPC
                        7'b0010111: if (rd!=0) regs[rd[3:0]] <= pc + {instr[31:12], 12'b0};
                        
                        // ALU Ops (R-Type, I-Type)
                        7'b0110011, 7'b0010011: begin
                            if (rd != 0) regs[rd[3:0]] <= alu_result;
                        end

                        // LOAD
                        7'b0000011: begin
                            d_addr <= r1_val + imm_i;
                            state  <= S_MEM; 
                        end

                        // STORE
                        7'b0100011: begin
                            d_addr  <= r1_val + imm_s;
                            d_wdata <= r2_val;
                            d_wen   <= 1'b1;
                            state   <= S_FETCH;
                            $display("!!! [CPU] STORE Attempt: Mem[%h] = %h !!!", r1_val + imm_s, r2_val);
                        end
                        
                        // JAL
                        7'b1101111: begin
                            if (rd != 0) regs[rd[3:0]] <= pc + 4;
                            // Decoding J-Immediate directly here to avoid wire binding errors
                            pc <= pc + {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
                        end
                        
                        // BRANCH
                        7'b1100011: begin
                            // Decoding B-Immediate directly here
                            if (branch_take) pc <= pc + {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
                        end
                    endcase
                end

                S_MEM: begin
                    if (rd != 0) regs[rd[3:0]] <= d_rdata;
                    state <= S_FETCH;
                end
            endcase
        end
    end
endmodule
