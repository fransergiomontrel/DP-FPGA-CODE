module uart_tx (
    input  wire        clk,
    input  wire        rst,       // reset síncrono
    input  wire        start,     // inicia transmissão
    input  wire [4607:0] data_in,   // dado paralelo
    output reg         tx,        // saída serial
    output reg         done       // pulso de fim	 

);    

	 //Bytes of protocol
    localparam START_BYTE = 8'h01;//Start of frame byte
	 localparam GET_RESULTS_BYTE = 8'h40;//Get results byte
	 localparam FRAME_SIZE = 8'd84;
	 localparam END_BYTE = 8'h04;//End of frame byte
	  
    // Checksum only: 72 bytes -> 18 groups -> 6 -> 2 -> total.
    // Four clock cycles of latency; data_in stays stable until transmission done.
    // The checksum is consumed only after the header and all payload bytes.
    
	  //To restart crc16 after one frame received
	 reg crc_restart;
	 reg [7:0] data_in_crc;
	 reg crc_en_reg;
	 wire [15:0] crc_result;
	 wire crc_global_reset;
	 assign crc_global_reset = rst || crc_restart;
	 
	 reg [7:0] crc_low_reg;
	 //Instance of crc16-CCITT False to calculate crc 16 bits data
    crc16 u_crc16(
		  
		  .data_in(data_in_crc),
        .crc_en(crc_en_reg),
        .crc_out(crc_result),
        .rst(crc_global_reset),
        .clk(clk)
		  
);
	 
	 reg start_8_ctl;
    reg [7:0] byte_to_send;
	 wire done_8_ctl;
	 wire tx_8;
	 
	  uart_tx_8 u_uart_tx_8(
	  
	  .clk(clk),
     .rst(rst),       
     .start(start_8_ctl),
	  .data_in(byte_to_send),
     .tx_out(tx_8),            
     .done_out(done_8_ctl)	  
	  
);

	 reg [9:0]  count_byte;
    reg [4607:0] shift_reg;
	 reg [4607:0] shift_reg_8;
	 
    reg [3:0]  bit_cnt; // precisa contar até 32
	 reg [9:0]  tx_freq_divider;// register to calculate boud rate = 100MHz/tx_freq_divider
	 
	 reg [7:0] reserved_1_reg;
	 reg [7:0] reserved_2_reg;
	 
	 //States definition for states machine of UART 8E1 for 60 bytes 
    localparam START_SM = 4'b0000;//
	 localparam BYTE_START_SM = 4'b0001;//
	 localparam BYTE_TYPE_SM = 4'b0010;//
	 localparam BYTE_LENGTH_SM = 4'b0011;//
	 localparam START_BIT_SM = 4'b0100;//
	 localparam DATA_BITS_SM = 4'b0101;//
	 localparam STOP_BIT_SM = 4'b0110;//
	 localparam RESERVED_1_SM = 4'b0111;
	 localparam RESERVED_2_SM = 4'b1000;
	 localparam BYTE_END_SM = 4'b1001;//
	 localparam CRC_READY = 4'b1010;//
	 localparam CRC_HIGH_SM = 4'b1011;//
	 localparam CRC_LOW_SM = 4'b1100;//
	 localparam AWAIT_TX_END_SM = 4'b1101;//
	 
	 reg [3:0] state_uart_tx;
	 
    always @(posedge clk) begin
        if (rst) begin
		  
            shift_reg <= 4608'd0;
				shift_reg_8 <= 4608'd0;
            bit_cnt   <= 4'd0;
            tx        <= 1'b1;
            done      <= 1'b0;
				count_byte <= 10'd0;
				tx_freq_divider <= 10'd0;
				byte_to_send <= 8'h00;
				start_8_ctl <= 1'b0;
				crc_restart <= 1'b1;
				crc_en_reg <= 1'b0;
	         crc_low_reg <= 8'h00;
				
				reserved_1_reg <= 8'h00;
	         reserved_2_reg <= 8'h00;
				
				state_uart_tx <= START_SM;
				
        end
		  
        else begin
		  
				done <= 1'b0;
				crc_restart <= 1'b0;
				crc_en_reg <= 1'b0;
				start_8_ctl <= 1'b0;
				
				case (state_uart_tx)			  
	
			   START_SM:
			  
			   begin
						 
				    if (start) begin                					 
					     
                    bit_cnt   <= 4'd8;
					     
					     tx_freq_divider  <= 10'd0;
				        shift_reg <= data_in;
						  shift_reg_8 <= data_in; 
						  byte_to_send <= START_BYTE;
					     start_8_ctl <= 1'b1;
						  
						  data_in_crc <= START_BYTE;
						  crc_en_reg <= 1'b1;
						  
					     state_uart_tx <= BYTE_START_SM;
					 
                end
						 
				end
				
				BYTE_START_SM:
			  
			   begin
				
				   tx <= tx_8;
					
					if (done_8_ctl == 1'b1) begin
					
						 byte_to_send <= GET_RESULTS_BYTE;
					    start_8_ctl <= 1'b1;
						 
						 data_in_crc <= GET_RESULTS_BYTE;
						 crc_en_reg <= 1'b1;
						 
					    state_uart_tx <= BYTE_TYPE_SM;
				       
					end
						 
				end
				
				BYTE_TYPE_SM:
			  
			   begin
				
				   tx <= tx_8;
					
					if (done_8_ctl == 1'b1) begin
					
						 byte_to_send <= FRAME_SIZE;
					    start_8_ctl <= 1'b1;
						 
						 data_in_crc <= FRAME_SIZE;
						 crc_en_reg <= 1'b1;
						 
					    state_uart_tx <= BYTE_LENGTH_SM;
				       
					end
						 
				end
				
				BYTE_LENGTH_SM:
			  
			   begin
				
				   tx <= tx_8;
					
					if (done_8_ctl == 1'b1) begin
					    
					    tx <= 1'b0;
					    state_uart_tx <= START_BIT_SM;
				       
					end
						 
				end
				
				START_BIT_SM:
			  
			   begin
						 
				    //Bit de start durante 868*(Tck)
				    tx_freq_divider  <= tx_freq_divider + 10'd1;
					 if (tx_freq_divider == 10'd868) begin
						  
						  tx_freq_divider  <= 10'd0;
						  tx <= shift_reg[0];
						  bit_cnt <= bit_cnt - 1;
						  state_uart_tx <= DATA_BITS_SM;
							  
					 end
						 
				end
				
				DATA_BITS_SM:
				
				begin
				
				    //Data transmitting goes on            
				    tx_freq_divider  <= tx_freq_divider + 10'd1;
					 tx <= shift_reg[0];        // envia LSB
					 					 
					 if (tx_freq_divider == 10'd868) begin //boud rate
					 
						  if (bit_cnt == 0) begin
								
						  		bit_cnt   <= 4'd8;
								shift_reg <= shift_reg >> 1;
								tx_freq_divider <= 10'd0;
								tx <= 1'b1;
								state_uart_tx <= STOP_BIT_SM;
								
						  end
						  
						  else begin
						  
								bit_cnt   <= bit_cnt - 1;
                        shift_reg <= shift_reg >> 1;
						      tx_freq_divider  <= 10'd0;
								state_uart_tx <= DATA_BITS_SM;
								
						  end
						  
					 end					 
					 								
				end
			    
				STOP_BIT_SM:
				
				begin
				
				    tx_freq_divider  <= tx_freq_divider + 10'd1;					 
					 if (tx_freq_divider == 10'd868) begin //boud rate
					 		  
						  tx_freq_divider  <= 10'd0;
						  
						  data_in_crc <= shift_reg_8[7:0];
						  crc_en_reg <= 1'b1;
						  
						  if (count_byte == 7'd575) begin
						  
						      count_byte <= 10'd0;
								byte_to_send <= reserved_1_reg;
								
					         start_8_ctl <= 1'b1;
								state_uart_tx <= RESERVED_1_SM;
								
						  end
						  else begin
						  
						      //New start bit
								count_byte <= count_byte + 10'd1;
								tx <= 1'b0;
								shift_reg_8 <= shift_reg_8 >> 8;
								state_uart_tx <= START_BIT_SM;
								
						  end
						 
					 end
				end

				RESERVED_1_SM:
			 
			   begin
				
				   tx <= tx_8;
					if (done_8_ctl == 1'b1) begin
					
						 data_in_crc <= reserved_1_reg;
						 crc_en_reg <= 1'b1;
						 
						 byte_to_send <= reserved_2_reg;
					    start_8_ctl <= 1'b1;
					
					    state_uart_tx <= RESERVED_2_SM;
				       
					end
						 
				end
				
				RESERVED_2_SM:
			 
			   begin
				
				   tx <= tx_8;
					if (done_8_ctl == 1'b1) begin
					
						 data_in_crc <= reserved_2_reg;
						 crc_en_reg <= 1'b1;
						 
						 byte_to_send <= END_BYTE;
					    start_8_ctl <= 1'b1;
					
					    state_uart_tx <= BYTE_END_SM;
				       
					end
						 
				end
				
				BYTE_END_SM:
			 
			   begin
				
				   tx <= tx_8;
					if (done_8_ctl == 1'b1) begin
					
						 data_in_crc <= END_BYTE;
						 crc_en_reg <= 1'b1;
					
					    state_uart_tx <= CRC_READY;
				       
					end
						 
				end
				
				CRC_READY:
			 
			   begin
					
					 state_uart_tx <= CRC_HIGH_SM;
				       
			   end
				
			   CRC_HIGH_SM:
			  
			   begin
				
				   tx <= tx_8;
					
					start_8_ctl <= 1'b1;
					byte_to_send <= crc_result[15:8];
					crc_low_reg <= crc_result[7:0];    
					state_uart_tx <= CRC_LOW_SM;
						 
				end
				
				CRC_LOW_SM:
			  
			   begin
				
				   tx <= tx_8;
					
					if (done_8_ctl == 1'b1) begin
					    //done <= 1'b1;
						 byte_to_send <= crc_low_reg;
						 start_8_ctl <= 1'b1;
					    state_uart_tx <= AWAIT_TX_END_SM;
				       
					end
						 
				end
				
				AWAIT_TX_END_SM:
			  
			   begin
				
				   tx <= tx_8;
					
					if (done_8_ctl == 1'b1) begin
					
					    done <= 1'b1;
						 crc_restart <= 1'b1;
					    state_uart_tx <= START_SM;
				       
					end
						 
				end
				
        endcase
		  
    end
end

endmodule