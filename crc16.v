// Generator: http://outputlogic.com/?page_id=321
// Test: https://crccalc.com/


//-----------------------------------------------------------------------------
// Copyright (C) 2009 OutputLogic.com
// This source file may be used and distributed without restriction
// provided that this copyright statement is not removed from the file
// and that any derivative work contains the original copyright notice
// and the associated disclaimer.
//
// THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
// WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
//-----------------------------------------------------------------------------
// CRC module for data[7:0] ,   crc[15:0]=1+x^5+x^12+x^16;
//-----------------------------------------------------------------------------
  module crc16(
  
    input [7:0] data_in,
    input crc_en,
    output [15:0] crc_out,
    input rst,
    input clk
	 
);

  reg [15:0] lfsr_q,lfsr_c;
  

  assign crc_out = lfsr_q;

  always @(*) begin
  
    lfsr_c[0] = lfsr_q[8] ^ lfsr_q[12] ^ data_in[0] ^ data_in[4];
    lfsr_c[1] = lfsr_q[9] ^ lfsr_q[13] ^ data_in[1] ^ data_in[5];
    lfsr_c[2] = lfsr_q[10] ^ lfsr_q[14] ^ data_in[2] ^ data_in[6];
    lfsr_c[3] = lfsr_q[11] ^ lfsr_q[15] ^ data_in[3] ^ data_in[7];
    lfsr_c[4] = lfsr_q[12] ^ data_in[4];
    lfsr_c[5] = lfsr_q[8] ^ lfsr_q[12] ^ lfsr_q[13] ^ data_in[0] ^ data_in[4] ^ data_in[5];
    lfsr_c[6] = lfsr_q[9] ^ lfsr_q[13] ^ lfsr_q[14] ^ data_in[1] ^ data_in[5] ^ data_in[6];
    lfsr_c[7] = lfsr_q[10] ^ lfsr_q[14] ^ lfsr_q[15] ^ data_in[2] ^ data_in[6] ^ data_in[7];
    lfsr_c[8] = lfsr_q[0] ^ lfsr_q[11] ^ lfsr_q[15] ^ data_in[3] ^ data_in[7];
    lfsr_c[9] = lfsr_q[1] ^ lfsr_q[12] ^ data_in[4];
    lfsr_c[10] = lfsr_q[2] ^ lfsr_q[13] ^ data_in[5];
    lfsr_c[11] = lfsr_q[3] ^ lfsr_q[14] ^ data_in[6];
    lfsr_c[12] = lfsr_q[4] ^ lfsr_q[8] ^ lfsr_q[12] ^ lfsr_q[15] ^ data_in[0] ^ data_in[4] ^ data_in[7];
    lfsr_c[13] = lfsr_q[5] ^ lfsr_q[9] ^ lfsr_q[13] ^ data_in[1] ^ data_in[5];
    lfsr_c[14] = lfsr_q[6] ^ lfsr_q[10] ^ lfsr_q[14] ^ data_in[2] ^ data_in[6];
    lfsr_c[15] = lfsr_q[7] ^ lfsr_q[11] ^ lfsr_q[15] ^ data_in[3] ^ data_in[7];
	 
  end // always

  always @(posedge clk, posedge rst) begin
    if(rst) begin
	 
      lfsr_q <= {16{1'b1}};
		
    end
    else begin
	 
      lfsr_q <= crc_en ? lfsr_c : lfsr_q;
		
    end
  end // always
endmodule // crc


//#include <stdio.h>
//#include <stdint.h>
//
//uint16_t w_Crc;
//
//void crc16_init(){
//    w_Crc = 0xffff;
//}
//
//uint16_t crc16_data(uint8_t value){
//    uint8_t i;
//    w_Crc ^= value << 8;
//    for (i=0; i < 8; i++)
//        w_Crc = w_Crc & 0x8000 ? (w_Crc << 1) ^ 0x1021 : w_Crc << 1;
//    return w_Crc & 0xffff;
//}
//
//
//uint8_t data[42] = {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
//                    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
//                    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
//                    0x3F,0x05,0x00,0x00,0x00,0x00
//};
//
//int main()
//{
//    crc16_init();
//    printf("CRC-16/CCITT-FALSE -> %X\n", crc16_data(0x38));   
//    printf("CRC-16/CCITT-FALSE -> %X\n", crc16_data(0x39));   
//    printf("CRC-16/CCITT-FALSE -> %X\n", crc16_data(0x3A));
//    printf("CRC-16/CCITT-FALSE -> %X\n", crc16_data(0x3B));
//    
//    crc16_init();
//    uint16_t resp;
//    for (int x=0;x<sizeof(data);x++)
//        resp = crc16_data(data[x]);
//        
//    printf("CRC-16/CCITT-FALSE -> Resultado = %X\n", resp);
// 
//    return 0;
//}