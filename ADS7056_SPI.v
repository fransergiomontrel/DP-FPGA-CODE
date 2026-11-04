module spi_adc_7056 (

    input  wire        clk,
    input  wire        rst,       // reset síncrono
    output reg         sclk,
    output reg         ncs,
    input wire         miso,      // PINO DE INPUT DO MESTRE
    output reg [13:0]  data_reg

);

     reg miso_reg;
     reg [6:0]  bit_cnt;
     reg [1:0]  div_sclk;
     reg [2:0]  delay;


    // Definição dos estados (Verilog clássico)
    localparam IDLE = 3'b000;
    localparam CHIP_SELECTED = 3'b001;
    localparam DELAY_CSCK = 3'b010;
    localparam AWAIT_SCLK_FALL = 3'b011;
    localparam AWAIT_SCLK_RISE = 3'b100;
    localparam DELAY_CKCS = 3'b101;

    reg [2:0] current__state;

    always @(posedge clk) begin

    miso_reg <= miso;
    if (rst) begin

      sclk <= 1'b1;
      ncs <= 1'b1;
		
	   div_sclk <= 2'd0;
	   delay <= 3'd0;
	   bit_cnt <= 7'd0;
	   

	   current_mosi_state <= IDLE;

    end

         else begin

         case (current_mosi_state)

        NO_MOSI_DATA:

                           begin

									
		                               if (config_reg == 16'h0000) begin
                                             current_mosi_state <= NO_MOSI_DATA;
                end
                                         else begin
                          current_mosi_state <= CHIP_SELECTED;
                                                  ncs <= 1'b0;          
                end
                                         
                                end

                  CHIP_SELECTED:

                           begin

                               current_mosi_state <= DELAY_CSSC_MOSI;
                                         shift_reg <= config_reg;
                                         old_config_reg <= config_reg;

                      end

                        DELAY_CSSC_MOSI:

                           begin

                               delay  <= delay + 5'd1;
                                         //200 ns to satisfy delay between nCS falling and first SCLK rising
                                         if (delay == 5'd20) begin
                                             delay <= 5'd0;
                                                  current_mosi_state <= AWAIT_SCLK_FALL_MOSI;
                                                  mosi <= shift_reg[15];
                                                  sclk <= 1'b1;
                                         end   
                               else begin
                                             current_mosi_state <= DELAY_CSSC_MOSI;

                                         end   
                      end
								
								                AWAIT_SCLK_FALL_MOSI:

                          begin

                                        div_sclk  <= div_sclk + 6'd1;
                                        //await 0,5 us to low sclk based on fsclk = 1 MHz
                                        if (div_sclk == 6'd49) begin

                                            div_sclk <= 6'd0;
                                                 sclk <= 1'b0;

                                                 if (bit_cnt > 5'd0) begin
                                                     shift_reg <= shift_reg << 1;
                                                     bit_cnt <= bit_cnt - 1;
                                                          current_mosi_state <= AWAIT_SCLK_RISE_MOSI;
                                                 end

                                                 else if (bit_cnt == 5'd0) begin
                                                     current_mosi_state <= DELAY_SCCS_MOSI;
                                                          bit_cnt <= 5'd15;
                                                 end
                                                  
                                        end

                                        else begin
                                            current_mosi_state <= AWAIT_SCLK_FALL_MOSI;
                                        end
                                        
                      end

							   AWAIT_SCLK_RISE_MOSI:

                          begin

                                        div_sclk  <= div_sclk + 6'd1;
                                        //await 0,5 us to low sclk based on fsclk = 1 MHz
                                        if (div_sclk == 6'd49) begin
                                            sclk <= 1'b1;
                                                 div_sclk <= 6'd0;
                                                 mosi <= shift_reg[15];
                                                 current_mosi_state <= AWAIT_SCLK_FALL_MOSI;
                                        end
                                        else begin
                                            current_mosi_state <= AWAIT_SCLK_RISE_MOSI;
                                        end
                                        
                     end

							
							              DELAY_SCCS_MOSI:

                         begin

                             delay  <= delay + 5'd1;
                                  //200 ns to satisfy delay between SCLK falling and nCS rising
                                  if (delay == 5'd20) begin
                                           delay <= 5'd0;
                                                ncs <= 1'b1;
                                                mosi <= 1'b0;
                                                miso_enable <= 1'b1;
                                                current_mosi_state <= IDLE_MOSI;

                                  end

                             else begin

                                           current_mosi_state <= DELAY_SCCS_MOSI;

                                  end   
                    end         

                IDLE_MOSI:

                         begin

                             if (config_reg == old_config_reg) begin
                                      current_mosi_state <= IDLE_MOSI;

                                  end
                                  else begin
                                           current_mosi_state <= NO_MOSI_DATA;
                                                
                                  end

                                        
                      end

									
			