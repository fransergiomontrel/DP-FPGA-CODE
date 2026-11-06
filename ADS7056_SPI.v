module spi_adc_7056 (

    input  wire        clk,
    input  wire        rst,       // reset síncrono
	 input  wire [1:0]  mode,
	 input wire         miso,      // PINO DE INPUT DO MESTRE
    output reg         sclk,
    output reg         ncs,
    output reg [13:0]  data_reg,
	 output wire new_sample_rdy_out

);

    wire clk_120mhz;
    wire pll_locked;

    pll_ip u_pll_ip (

    .inclk0 (clk),
    .areset (1'b0),
    .c0     (clk_120mhz),
    .locked (pll_locked)

); 

    reg new_sample_reg;
	 assign new_sample_rdy_out = new_sample_reg;
    reg [6:0]  bit_cnt;
    reg [3:0]  delay;
	 
    // Definição dos estados (Verilog clássico)
    localparam IDLE = 3'b000;
    localparam CHIP_SELECTED = 3'b001;
    localparam DELAY_CSCK = 3'b010;
    localparam SCLK_RISE = 3'b011;
    localparam SCLK_FALL = 3'b100;
    localparam ACQ = 3'b101;
	 
	 //Definiçao dos modos de operaçao do ADS7056
	 localparam OFFCALL_UP = 2'd1;
	 localparam CNV = 2'd2;
	 localparam OFFCAL = 2'd3;
	 
    reg [2:0] current_spi_state;

	 always @(posedge clk_120mhz) begin
    //always @(posedge clk) begin

    
    if (rst | ~pll_locked) begin

      sclk <= 1'b1;
      ncs <= 1'b1;
		
	   delay <= 4'd0;
	   bit_cnt <= 7'd0;
	   new_sample_reg <= 1'b0;
		
	   current_spi_state <= IDLE;

    end

    else begin

	 new_sample_reg <= 1'b0;
	 
    case (current_spi_state)

		  IDLE:
		  
        begin

		  if (mode == OFFCALL_UP) begin							
		  
		      bit_cnt <= 7'd24;
				current_spi_state <= CHIP_SELECTED;
		  
		  end
		  
		  else if (mode == CNV) begin							
		  
		      bit_cnt <= 7'd18;
				current_spi_state <= CHIP_SELECTED;
		  
		  end
		  
		  else if (mode == OFFCAL) begin							
		  
		      bit_cnt <= 7'd64;
				current_spi_state <= CHIP_SELECTED;
		  
		  end
		  
        end

        CHIP_SELECTED:

        begin

            ncs <= 1'b0;
            current_spi_state <= DELAY_CSCK;				

        end

		  //Setup time
        DELAY_CSCK:

        begin
            
				delay <= delay + 4'd1;
			   if (delay == 4'd1) begin
				    sclk <= 1'b0;
				    delay <= 4'd0;
					 current_spi_state <= SCLK_RISE;
			   end	
                              
        end
								
		  SCLK_RISE:

        begin

				
	
			   if (bit_cnt > 7'd0) begin
						  
					 if ((mode == CNV) && (bit_cnt < 7'd17) && (bit_cnt > 7'd2)) begin
					 
					     data_reg[bit_cnt - 3] <= miso;
						  
					 end
					 
					 else if ((mode == OFFCAL) && (bit_cnt < 7'd63) && (bit_cnt > 7'd48)) begin
					 
					     data_reg[bit_cnt - 49] <= miso;
						  
					 end
					 
					 sclk <= 1'b1;
					 current_spi_state <= SCLK_FALL;
					 
						  
				end
	
				else if (bit_cnt == 7'd0) begin
				 
					 current_spi_state <= ACQ;
						  
				end
											 
	     end
		  
		  SCLK_FALL:

        begin

				sclk <= 1'b0;
			   bit_cnt <= bit_cnt - 7'd1;
				current_spi_state <= SCLK_RISE;
	 
	     end
	
							
			ACQ:

         begin

			    delay <= delay + 4'd1;
				 if(delay == 4'd1) begin
				 
				     sclk <= 1'b1;
				 
				 end
				 //Hold time
				 else if(delay == 4'd2) begin
				     
					  ncs <= 1'b1;
					  
				 end
				 
				 else if(delay == 4'd11) begin
				 
				     new_sample_reg <= 1'b1;
					  
					  current_spi_state <= IDLE;
					  
				 end
			
         end         

      endcase
		end
		end
		endmodule

									
			