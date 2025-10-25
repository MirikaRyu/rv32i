/* Access the unified memory space */

`include "src/constants.v"

// Instruction ROM Address Space: [0, 1GiB)
// Accessible: [0, 64KiB)
module ROMAccess
    (input wire clk,
     input wire rst,

     input wire [31 : 0] addr_In,
     input wire inputValid_In,

     output wire [`EXCEPTION_LEN - 1 : 0] exception_Out,
     output wire [31 : 0] instr_Out,
     output wire outputValid_Out);

    assign exception_Out = (addr_In >= 16'hffff || |addr_In[1 : 0]) ? `EXCEP_INVALID_MEM_READ : `EXCEP_OK;

    InstrROM instr_rom(.clk(clk),
                       .rst(rst),

                       .addr_In(addr_In[15 : 0]),
                       .addrValid_In(inputValid_In),

                       .instr_Out(instr_Out),
                       .instrValid_Out(outputValid_Out));
endmodule

// Data RAM Address space: [1GiB, 4GiB)
// Accessible: [1GiB, 1GiB + 512MiB), [1GiB + 512MiB, 1GiB + 512MiB + 4B)
module RAMAccess
    (input wire clk,
     input wire rst,

     input wire [31 : 0] addr_In,
     input wire [31 : 0] data_In,
     input wire [1 : 0] dataWidth_In,
     input wire isRead_In,
     input wire inputValid_In,

     output reg [`EXCEPTION_LEN - 1 : 0] exception_Out,
     output reg [31 : 0] data_Out,
     output reg operationOK_Out);

    // Handle exceptions
    always @(*)
    begin
        exception_Out = isRead_In ? `EXCEP_INVALID_MEM_READ : `EXCEP_INVALID_MEM_WRITE;

        if (!inputValid_In)
            exception_Out = `EXCEP_OK;
        else if (32'h40000000 <= addr_In && addr_In < 32'h60000004)
            if (dataWidth_In == `MEM_WIDTH_BYTE)
                exception_Out = `EXCEP_OK;
            else if (dataWidth_In == `MEM_WIDTH_HALF && ~addr_In[0])
                exception_Out = `EXCEP_OK;
            else if (dataWidth_In == `MEM_WIDTH_WORD && ~|addr_In[1 : 0])
                exception_Out = `EXCEP_OK;
    end

    // RAM module
    reg data_ram_enable;
    wire [31 : 0] data_ram_out;
    wire data_ram_operation_ok;
    DataRAM data_ram(.clk(clk),
                     .rst(rst),

                     .addr_In(addr_In[28 : 0]),
                     .data_In(data_In),
                     .dataWidth_In(dataWidth_In),
                     .isRead_In(isRead_In),
                     .inputValid_In(data_ram_enable),

                     .data_Out(data_ram_out),
                     .operationOK_Out(data_ram_operation_ok));

    // IO module
    reg dev_write_ok;
    reg dev_read_ok;
    reg [31 : 0] dev_mask;
    reg [31 : 0] dev_value;
    wire [31 : 0] dev_state;
    IO io(.clk(clk),
          .rst(rst),

          .devMask_In(dev_mask),
          .devValue_In(dev_value),

          .devState_Out(dev_state));

    always @(posedge clk)
    begin
        if (rst)
            dev_write_ok <= 0;
        else
            dev_write_ok <= inputValid_In;
    end

    always @(posedge clk)
    begin
        if (rst)
            dev_read_ok <= 0;
        else
            dev_read_ok <= inputValid_In;
    end

    // Convert memory access to IO bit access
    reg [3 : 0] byte_enable;
    wire [31 : 0] mask = {{8{byte_enable[3]}}, {8{byte_enable[2]}}, {8{byte_enable[1]}}, {8{byte_enable[0]}}};

    wire [31 : 0] io_data_word = data_In;
    wire [31 : 0] io_data_half = {16'b0, data_In[15 : 0]} << (addr_In[1] << 4);
    wire [31 : 0] io_data_byte = {24'b0, data_In[7 : 0]} << (addr_In[1 : 0] << 3);

    reg [31 : 0] io_data_out;

    always @(*)
    begin
        case (dataWidth_In)
            `MEM_WIDTH_BYTE: begin
                byte_enable = 4'b0001 << addr_In[1 : 0];
                dev_value = io_data_byte;
                io_data_out = (dev_state & mask) >> (addr_In[1 : 0] << 3);
            end
            `MEM_WIDTH_HALF: begin
                byte_enable = addr_In[1] ? 4'b1100 : 4'b0011;
                dev_value = io_data_half;
                io_data_out = (dev_state & mask) >> (addr_In[1] << 4);
            end
            `MEM_WIDTH_WORD: begin
                byte_enable = 4'b1111;
                dev_value = io_data_word;
                io_data_out = dev_state;
            end
            default: begin
                byte_enable = 0;
                dev_value = 0;
                io_data_out = 0;
            end
        endcase
    end

    // Dispatch memory access requests
    always @(*)
    begin
        data_ram_enable = 0;

        dev_mask = 0;

        data_Out = 0;
        operationOK_Out = 0;

        if (addr_In < 32'h60000000) // Access RAM
        begin
            data_ram_enable = inputValid_In;

            data_Out = isRead_In ? data_ram_out : 0;
            operationOK_Out = data_ram_operation_ok;
        end
        else // Access IO
        begin
            dev_mask = mask;

            data_Out = io_data_out;
            operationOK_Out = isRead_In ? dev_read_ok : dev_write_ok;
        end
    end
endmodule