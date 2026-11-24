module rx_serial_8 (

    input  wire        clk,
    input  wire        rst,       
    input  wire        rx,             
    output reg         done_rx,     
	 output reg [7:0]   rx_reg,
	 output error_out

);    


wire rx_start;

nedge_detector u_nedge_detector(
    .current_read_pulse(rx),
    .clk(clk),
    .falling_edge(rx_start),
    .reset(rst)
);
    localparam OK = 8'h00;
	 localparam FAILURE = 8'h06;
	 reg error_frame_byte;
	 assign error_out = error_frame_byte;
	 //8 bits size register to count 8 bits of data
    reg [3:0]  bit_cnt; 
	 //10 bits size register to count period of boud between bits
	 reg [10:0]  bit_time_cnt;
	 //States definition for states machine of UART 8N1 for 1 byte
	
	 localparam START = 3'b001;//
    localparam START_BIT = 3'b010;//
	 localparam DATA_BITS = 3'b011;//
	 localparam STOP_BIT = 3'b100;//
	 
	 reg [2:0] state_uart_rx;
	 
    always @(posedge clk) begin
	 
        if (rst) begin
            done_rx <= 1'b0;
				bit_time_cnt  <= 11'd0;
				bit_cnt <= 4'd0;
				rx_reg <= 8'd0;
				error_frame_byte <= OK;
				state_uart_rx <= START;
        end
		  
		  else begin
		  
		  done_rx <= 1'b0;
		  error_frame_byte <= OK;
		  
		  case (state_uart_rx)	
		 
		  START:
		  begin
		  
				if (rx_start == 1'd1) begin
				
				    state_uart_rx <= START_BIT;
					 bit_time_cnt  <= bit_time_cnt + 11'd1;
					 
				end
		      
		  end
		  
		  START_BIT:
		  begin
		  
		      bit_time_cnt  <= bit_time_cnt + 11'd1;
				//Count bit time
				if (bit_time_cnt == 11'd1302) begin 
				
                bit_time_cnt  <= 11'd0;
					 rx_reg[bit_cnt] <= rx;
					 bit_cnt <= bit_cnt + 4'd1;
					 state_uart_rx <= DATA_BITS;
					
		      end
		  
		  end
		  
		  DATA_BITS:
		  begin
		  
		      bit_time_cnt  <= bit_time_cnt + 11'd1;
				
				//Count bit time
				if (bit_time_cnt == 11'd868) begin 
                bit_time_cnt  <= 11'd0;
					 rx_reg[bit_cnt] <= rx;
					 bit_cnt <= bit_cnt + 4'd1;
					 if (bit_cnt == 4'd7) begin 
								
							bit_cnt <= 4'd0;
							state_uart_rx <= STOP_BIT;
							   									 						      
					end
					 
		      end
		  
		  end
		  
		  STOP_BIT:
		  begin
		  
		      bit_time_cnt  <= bit_time_cnt + 11'd1;
						
				if (bit_time_cnt == 11'd868) begin 
				
				    //Stop bit not detected
				    if (rx == 1'b0) begin
					     error_frame_byte <= FAILURE;
					 end
				
                bit_time_cnt  <= 11'd0;
					 done_rx <= 1'b1;
					 state_uart_rx <= START;
					 
		      end
		  end
		  
  endcase

end  
				
end
	 
endmodule

		