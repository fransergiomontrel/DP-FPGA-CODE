module reg_set_module (

    input wire clk,
    input wire rst,
	 input wire [0:35] minus_occurrence,
	 input wire [0:35] plus_occurrence,
	 input wire [0:31] dp_result,
	 output wire [4607:0] payload

);

reg [31:0] count_plus[0:35];
reg [31:0] dp_plus[0:35];
reg [31:0] count_minus[0:35];
reg [31:0] dp_minus[0:35]; 

integer i;

genvar k;

generate
    for (k = 0; k < 36; k = k + 1) begin : gen_payload

        assign payload[(k*32)       +: 32] = count_plus[k];
        assign payload[(1152+k*32)  +: 32] = dp_plus[k];
        assign payload[(2304+k*32)  +: 32] = count_minus[k];
        assign payload[(3456+k*32)  +: 32] = dp_minus[k];

    end
endgenerate
 
always @(posedge clk) begin

    
    if (rst) begin

	     for (i = 0; i < 36; i = i + 1)
		  
            count_plus[i] <= 32'd0;
				count_minus[i] <= 32'd0;
				dp_plus[i] <= 32'd0;
				dp_minus[i] <= 32'd0;
	 
    end

    else begin
	 
        for (i = 0; i < 36; i = i + 1)
		  
            if(minus_occurrence[i] == 1'b1) begin
				
				    count_minus[i] <= count_minus[i] + 32'd1;
					 dp_minus[i] <= dp_result + dp_minus[i];  
					 
				end
				
				else if(plus_occurrence[i] == 1'b1) begin
				
				    count_plus[i] <= count_plus[i] + 32'd1;
					 dp_plus[i] <= dp_result + dp_plus[i];
				
				end
	 
	 end
	 end

endmodule