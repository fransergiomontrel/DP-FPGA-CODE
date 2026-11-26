module ram_ctl_module (
    input  wire clk,
    input  wire reset,
    input  reg  [15:0] data_from_ram_in,
	 output wire we_n_out,
	 output wire oe_n_out,
	 output wire cs_n_out,
    output wire addr_inc_read_out,
	 output wire addr_inc_write_out,
	 output wire write_enable_out,
	 output wire data_bus_out,
	 output wire addr_clr_out,
    output reg [15:0] data_to_ram_out
);
    //Registers
    reg we_n_reg;
	 reg oe_n_reg;
	 reg cs_n_reg;
	 reg write_enable_reg;
	 reg data_bus_reg;
	 reg addr_inc_read_reg;
	 reg addr_inc_write_reg;
	 reg addr_clr_reg;
	 reg en_new_random;
	 //Connection between registers out and output signals
	 assign we_n_out = we_n_reg;
	 assign oe_n_out = oe_n_reg;
	 assign cs_n_out = cs_n_reg;
	 assign addr_inc_read_out = addr_inc_read_reg;
	 assign addr_inc_write_out = addr_inc_write_reg;
	 assign write_enable_out = write_enable_reg;
	 assign data_bus_out = data_bus_reg;
	
	// Definição dos estados (Verilog clássico)
    localparam IDLE = 3'b0000;
    localparam NEW_RANDOM = 3'b0001;
    localparam START_WRITE = 3'b0010;
    localparam AWAIT_WRITE_1 = 3'b0011;
	 localparam AWAIT_WRITE_2 = 3'b0100;
	 localparam AWAIT_WRITE_3 = 3'b0101;
	
	 reg [3:0] ram_ctl_state;
	
	 wire [15:0] random_bus;
    random_16bit u_random_16bit (
    clk(clk),
    reset(reset),
    enable(en_new_random),
    random_out(random_bus)
); 

    always @(posedge clk or posedge reset) begin
	 
        if (reset)
		  
            we_n_reg <= 1'b1;
				oe_n_reg <= 1'b1;
				cs_n_reg <= 1'b1;
				write_enable_reg <= 1'b1;
			   data_bus_reg <= 1'b1;
				addr_inc_read_reg <= 1'b0;
				addr_inc_write_reg <= 1'b0;
				addr_clr_reg <= 1'b0;
				en_new_random <= 1'b0;
				data_to_ram_out <= 16'h0000;
				ram_ctl_state <= IDLE;
				
        else
		 
		 
		 case (ram_ctl_state)
		  
	    IDLE:
		  
       begin
		 
           en_new_random <= 1'b1;
		     ram_ctl_state <= NEW_RANDOM; 
		  
	    end
		 
		 NEW_RANDOM:
		  
       begin
        
		      en_new_random <= 1'b0;
				ram_ctl_state <= START_WRITE;
		  
	    end
		 
		 START_WRITE:
		  
       begin
        
				we_n_reg <= 1'b0;
				cs_n_reg <= 1'b0;
				data_to_ram_out <= random_bus;
				ram_ctl_state <= AWAIT_WRITE_1;
		  
	    end
		 
		 AWAIT_WRITE_1:
		  
       begin
		 
				ram_ctl_state <= AWAIT_WRITE_2;
		  
	    end
		 
		 AWAIT_WRITE_2:
		  
       begin
		 
				ram_ctl_state <= AWAIT_WRITE_3;
		  
	    end
		 
		 AWAIT_WRITE_3:
		  
       begin
		      
				data_bus_reg <= 1'b0;
				write_enable_reg <= 1'b0;
		      we_n_reg <= 1'b1;
				we_n_reg <= 1'b0;
				ram_ctl_state <= AWAIT_WRITE_2;
		  
	    end
		 
		 endcase
		 
		 
		   
            
    end

endmodule