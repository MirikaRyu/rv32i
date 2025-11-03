module RegisterFile
    (input wire clk,
     input wire rst,

     /* Interface rs1 */
     input wire [4 : 0] rs1Addr_In,
     output reg [31 : 0] rs1_Out,
     input wire rs1Enable_In,

     /* Interface rs2 */
     input wire [4 : 0] rs2Addr_In,
     output reg [31 : 0] rs2_Out,
     input wire rs2Enable_In,

     /* Interface rd */
     input wire [4 : 0] rdAddr_In,
     input wire [31 : 0] rd_In,
     input wire rdEnable_In);

    /* Registers declaration */
    reg [31 : 0] reg_x1;
    reg [31 : 0] reg_x2;
    reg [31 : 0] reg_x3;
    reg [31 : 0] reg_x4;
    reg [31 : 0] reg_x5;
    reg [31 : 0] reg_x6;
    reg [31 : 0] reg_x7;
    reg [31 : 0] reg_x8;
    reg [31 : 0] reg_x9;
    reg [31 : 0] reg_x10;
    reg [31 : 0] reg_x11;
    reg [31 : 0] reg_x12;
    reg [31 : 0] reg_x13;
    reg [31 : 0] reg_x14;
    reg [31 : 0] reg_x15;
    reg [31 : 0] reg_x16;
    reg [31 : 0] reg_x17;
    reg [31 : 0] reg_x18;
    reg [31 : 0] reg_x19;
    reg [31 : 0] reg_x20;
    reg [31 : 0] reg_x21;
    reg [31 : 0] reg_x22;
    reg [31 : 0] reg_x23;
    reg [31 : 0] reg_x24;
    reg [31 : 0] reg_x25;
    reg [31 : 0] reg_x26;
    reg [31 : 0] reg_x27;
    reg [31 : 0] reg_x28;
    reg [31 : 0] reg_x29;
    reg [31 : 0] reg_x30;
    reg [31 : 0] reg_x31;

    /* Combinational read */
    always @(*)
    begin
        if (rs1Enable_In)
            case (rs1Addr_In)
                5'd0:
                    rs1_Out = 0;
                5'd1:
                    rs1_Out = reg_x1;
                5'd2:
                    rs1_Out = reg_x2;
                5'd3:
                    rs1_Out = reg_x3;
                5'd4:
                    rs1_Out = reg_x4;
                5'd5:
                    rs1_Out = reg_x5;
                5'd6:
                    rs1_Out = reg_x6;
                5'd7:
                    rs1_Out = reg_x7;
                5'd8:
                    rs1_Out = reg_x8;
                5'd9:
                    rs1_Out = reg_x9;
                5'd10:
                    rs1_Out = reg_x10;
                5'd11:
                    rs1_Out = reg_x11;
                5'd12:
                    rs1_Out = reg_x12;
                5'd13:
                    rs1_Out = reg_x13;
                5'd14:
                    rs1_Out = reg_x14;
                5'd15:
                    rs1_Out = reg_x15;
                5'd16:
                    rs1_Out = reg_x16;
                5'd17:
                    rs1_Out = reg_x17;
                5'd18:
                    rs1_Out = reg_x18;
                5'd19:
                    rs1_Out = reg_x19;
                5'd20:
                    rs1_Out = reg_x20;
                5'd21:
                    rs1_Out = reg_x21;
                5'd22:
                    rs1_Out = reg_x22;
                5'd23:
                    rs1_Out = reg_x23;
                5'd24:
                    rs1_Out = reg_x24;
                5'd25:
                    rs1_Out = reg_x25;
                5'd26:
                    rs1_Out = reg_x26;
                5'd27:
                    rs1_Out = reg_x27;
                5'd28:
                    rs1_Out = reg_x28;
                5'd29:
                    rs1_Out = reg_x29;
                5'd30:
                    rs1_Out = reg_x30;
                5'd31:
                    rs1_Out = reg_x31;
            endcase
        else
            rs1_Out = 0;
    end

    always @(*)
    begin
        if (rs2Enable_In)
            case (rs2Addr_In)
                5'd0:
                    rs2_Out = 0;
                5'd1:
                    rs2_Out = reg_x1;
                5'd2:
                    rs2_Out = reg_x2;
                5'd3:
                    rs2_Out = reg_x3;
                5'd4:
                    rs2_Out = reg_x4;
                5'd5:
                    rs2_Out = reg_x5;
                5'd6:
                    rs2_Out = reg_x6;
                5'd7:
                    rs2_Out = reg_x7;
                5'd8:
                    rs2_Out = reg_x8;
                5'd9:
                    rs2_Out = reg_x9;
                5'd10:
                    rs2_Out = reg_x10;
                5'd11:
                    rs2_Out = reg_x11;
                5'd12:
                    rs2_Out = reg_x12;
                5'd13:
                    rs2_Out = reg_x13;
                5'd14:
                    rs2_Out = reg_x14;
                5'd15:
                    rs2_Out = reg_x15;
                5'd16:
                    rs2_Out = reg_x16;
                5'd17:
                    rs2_Out = reg_x17;
                5'd18:
                    rs2_Out = reg_x18;
                5'd19:
                    rs2_Out = reg_x19;
                5'd20:
                    rs2_Out = reg_x20;
                5'd21:
                    rs2_Out = reg_x21;
                5'd22:
                    rs2_Out = reg_x22;
                5'd23:
                    rs2_Out = reg_x23;
                5'd24:
                    rs2_Out = reg_x24;
                5'd25:
                    rs2_Out = reg_x25;
                5'd26:
                    rs2_Out = reg_x26;
                5'd27:
                    rs2_Out = reg_x27;
                5'd28:
                    rs2_Out = reg_x28;
                5'd29:
                    rs2_Out = reg_x29;
                5'd30:
                    rs2_Out = reg_x30;
                5'd31:
                    rs2_Out = reg_x31;
            endcase
        else
            rs2_Out = 0;
    end

    /* Synchronous write */
    always @(posedge clk)
    begin
        if (rst)
        begin
            reg_x1 <= 0;
            reg_x2 <= 0;
            reg_x3 <= 0;
            reg_x4 <= 0;
            reg_x5 <= 0;
            reg_x6 <= 0;
            reg_x7 <= 0;
            reg_x8 <= 0;
            reg_x9 <= 0;
            reg_x10 <= 0;
            reg_x11 <= 0;
            reg_x12 <= 0;
            reg_x13 <= 0;
            reg_x14 <= 0;
            reg_x15 <= 0;
            reg_x16 <= 0;
            reg_x17 <= 0;
            reg_x18 <= 0;
            reg_x19 <= 0;
            reg_x20 <= 0;
            reg_x21 <= 0;
            reg_x22 <= 0;
            reg_x23 <= 0;
            reg_x24 <= 0;
            reg_x25 <= 0;
            reg_x26 <= 0;
            reg_x27 <= 0;
            reg_x28 <= 0;
            reg_x29 <= 0;
            reg_x30 <= 0;
            reg_x31 <= 0;
        end
        else if (rdEnable_In)
        begin
            case (rdAddr_In)
                5'd0:
                    ;
                5'd1:
                    reg_x1 <= rd_In;
                5'd2:
                    reg_x2 <= rd_In;
                5'd3:
                    reg_x3 <= rd_In;
                5'd4:
                    reg_x4 <= rd_In;
                5'd5:
                    reg_x5 <= rd_In;
                5'd6:
                    reg_x6 <= rd_In;
                5'd7:
                    reg_x7 <= rd_In;
                5'd8:
                    reg_x8 <= rd_In;
                5'd9:
                    reg_x9 <= rd_In;
                5'd10:
                    reg_x10 <= rd_In;
                5'd11:
                    reg_x11 <= rd_In;
                5'd12:
                    reg_x12 <= rd_In;
                5'd13:
                    reg_x13 <= rd_In;
                5'd14:
                    reg_x14 <= rd_In;
                5'd15:
                    reg_x15 <= rd_In;
                5'd16:
                    reg_x16 <= rd_In;
                5'd17:
                    reg_x17 <= rd_In;
                5'd18:
                    reg_x18 <= rd_In;
                5'd19:
                    reg_x19 <= rd_In;
                5'd20:
                    reg_x20 <= rd_In;
                5'd21:
                    reg_x21 <= rd_In;
                5'd22:
                    reg_x22 <= rd_In;
                5'd23:
                    reg_x23 <= rd_In;
                5'd24:
                    reg_x24 <= rd_In;
                5'd25:
                    reg_x25 <= rd_In;
                5'd26:
                    reg_x26 <= rd_In;
                5'd27:
                    reg_x27 <= rd_In;
                5'd28:
                    reg_x28 <= rd_In;
                5'd29:
                    reg_x29 <= rd_In;
                5'd30:
                    reg_x30 <= rd_In;
                5'd31:
                    reg_x31 <= rd_In;
            endcase
        end
    end
endmodule