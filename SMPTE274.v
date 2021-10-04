//////////////////////////////////////////////////////////////////////////////////
// Engineer:    Konstantin
// 
// Design Name: 
// Module Name: SMPTE274
// Project Name: HD-SDI
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: crc calculated in crcSMPTE.v
// Additional Comments: Tested in simulation only
// Encoding: Windows-1251 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 100ps

`define LINE_LENGTH            	 2200 - 1
`define pixel_EAV0               1920 - 1
`define pixel_SAV0               2196 - 1

module SMPTE274(
  //  VERSION 1080p @30 
  input 	      i_CLK_74m25,    	//  serial clock 
  input 	      i_RST,          	//  hight for reset
  input           i_EN,             //  system i_ENable
  //  Y or Cb Cr data                    
  input  [ 9 : 0] i_data_Y,         //  data in
  input  [ 9 : 0] i_data_C,         //  Cb / Cr component
  
  output [11 : 0] PIX_CNT_o,        //  pix count
  output [10 : 0] LINE_CNT_o,       //  Line count | max value = 1125
  //  output          F_o,            //  odd/evi_EN field indicator
  output          VSYNC_o,          //  vertical synchronization
  output          HSYNC_o,          //  horizontal synchronization 
  output          DATA_RQ_o,        //  active area 
  //  output          SDI_o,          //  SDI serial output 
  output [ 9 : 0] Y_data_o,
  output [ 9 : 0] C_data_o          //  parallel output     
  );


reg  [11 : 0] pix_cnt;              //  2200 per line
reg  [10 : 0] line_cnt;             //  1125 per frame

wire [11 : 0] pix_cnt_end;          //  pixel end signal 1-2200
wire [10 : 0] line_cnt_end;         //  line end signal (frame) 1-1125

reg           i_EN_d;

reg           F; 
reg           V;
reg           H;
reg           line_data_rq; 
// EAV / SAV
reg           line_EAV0; 
reg           line_EAV1;
reg           line_EAV2;
reg           line_EAV3;
reg           line_LN0;
reg           line_LN1;
reg           line_CRC0;
reg           line_CRC1;
reg           line_BLANK;

//-----------------------------------------------  go state 
assign go_vb1    = (i_EN ^ i_EN_d) | line_cnt_end; 
//assign go_vb1  = line_cnt_1 | line_cnt_end;
assign go_frame  = line_cnt_42; 
assign go_vb2    = line_cnt_1122;   
//  state machine  
localparam    S_IDLE  = 2'b00; 
localparam    S_VB1   = 2'b01; 
localparam    S_FRAME = 2'b10; 
localparam    S_VB2   = 2'b11; 
reg  [ 1 : 0] state;

reg           vsync;
reg           hsync;
 
/////////////////////////////////////////////////////////////////  state machine  
//  state machine  
/////////////////////////////////////////////////////////////////    
always @(posedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
		state <= S_IDLE; 
	else 
		case (state) 
			S_IDLE : 
				if (go_vb1)
					state <= S_VB1; 
				else 
					state <= S_IDLE;  
			S_VB1 : 
				if (go_frame) 
					state <= S_FRAME;
				else 
					state <= S_VB1; 
			S_FRAME: 
				if (go_vb2) 
					state <= S_VB2;
				else 
					state <= S_FRAME; 
			S_VB2 : 
				if (go_vb1) 
					state <= S_VB1;
				else 
					state <= S_VB2;
			default : 
				state <= S_IDLE;    
		endcase 					 								
end


//-----------------------------------------------  
assign line_cnt_1      = line_cnt == 1    - 1;     // first blanking zone 
assign line_cnt_42     = line_cnt == 42   - 1;     // frame
assign line_cnt_1122   = line_cnt == 1122 - 1;     // last blanking zone  
//-----------------------------------------------
assign pix_EAV0 = pix_cnt == `pixel_EAV0;
assign pix_EAV1 = pix_cnt == `pixel_EAV0 + 1;      // do not change
assign pix_EAV2 = pix_cnt == `pixel_EAV0 + 2;      // do not change
assign pix_EAV3 = pix_cnt == `pixel_EAV0 + 3;      // do not change
assign pix_LN0  = pix_cnt == `pixel_EAV0 + 4;      // do not change
assign pix_LN1  = pix_cnt == `pixel_EAV0 + 5;      // do not change
assign pix_CRC0 = pix_cnt == `pixel_EAV0 + 6;      // do not change
assign pix_CRC1 = pix_cnt == `pixel_EAV0 + 7;      // do not change
assign pix_BLANK = (pix_cnt > `pixel_EAV0 + 7) && (pix_cnt < `pixel_SAV0);  

assign pix_SAV0 = pix_cnt == `pixel_SAV0;
assign pix_SAV1 = pix_cnt == `pixel_SAV0 + 1;      // do not change
assign pix_SAV2 = pix_cnt == `pixel_SAV0 + 2;      // do not change
assign pix_SAV3 = pix_cnt == `pixel_SAV0 + 3;      // do not change

//-----------------------------------------------  line_cnt_end 
assign line_cnt_end = line_cnt == 1125; 
//-----------------------------------------------  pix_cnt_end 
assign pix_cnt_end = pix_cnt == `LINE_LENGTH;
    
//-----------------------------------------------  pix_cnt 
//  pix_cnt
//-----------------------------------------------  
always @(negedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
		pix_cnt <= 0; 
	else 
		if (pix_cnt_end)
			pix_cnt <= 0;  
		else if (state != S_IDLE) 
			pix_cnt <= pix_cnt + 1'b1;	 				
end   

//-----------------------------------------------  line_cnt 
//  line_cnt  
//-----------------------------------------------
always @(posedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
		line_cnt <= 0; 
	else 
		if (line_cnt_end) //  return to 0 
			line_cnt <= 0;
		else if (pix_cnt_end) 
			line_cnt <= line_cnt + 1'b1; 				
end 

//-----------------------------------------------  i_EN_d 
always @(posedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
		i_EN_d <= 0; 
	else 
		i_EN_d <= i_EN;	 				
end

 
//-----------------------------------------------  F 
always @(posedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
		F <= 0; 
	else 
    //  for progressive scan always 0
    F <= 0;

end

//-----------------------------------------------  line_data_rq 
//
//-----------------------------------------------   
always @(posedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
		line_data_rq <= 0; 
	else 
		if (pix_cnt < `pixel_EAV0 && state == S_FRAME)  
			line_data_rq <= 1'b1;
		else 
			line_data_rq <= 1'b0; 				
end

 
//-----------------------------------------------  V  
always @(posedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
		V <= 0; 
	else 
		V <= ~(state == S_FRAME);    // hight when blanking (low when frame)				
end

//-----------------------------------------------  H  
always @(posedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
		H <= 0; 
	else 
		if ((pix_cnt < 1920) | (pix_cnt > 2196))       // when data H = 0	
		  H <= 0;
		else
		  H <= 1;
				
end

//-----------------------------------------------  vsync  
always @(posedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
		vsync <= 0; 
	else 
        if (V) 
            vsync <= 1;
        else
            vsync <= 0;
	

end

//-----------------------------------------------  hsync  
always @(posedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
		hsync <= 0; 
	else 
		if (line_EAV3 & ~H) 
			hsync <= 1'b0;  //  data active 	
		else if (line_EAV0) 
			hsync <= 1'b1;		
end



// breaking the start / stop word into 4 parts
//-----------------------------------------------  line_EAV0 
always @(posedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
		line_EAV0 <= 0; 
	else     
	   if (state != S_IDLE && (pix_EAV0 || pix_SAV0)) 
	       line_EAV0 <= 1'b1;
	   else 
	       line_EAV0 <= 1'b0; 				
end
//-----------------------------------------------  line_EAV1 
always @(posedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
        line_EAV1 <= 0; 
	else
        if (pix_EAV1 || pix_SAV1) 
			line_EAV1 <= 1'b1;
		else 
			line_EAV1 <= 1'b0; 				
end
//-----------------------------------------------  line_EAV2 
always @(posedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
        line_EAV2 <= 0; 
	else
        if (pix_EAV2 || pix_SAV2) 
			line_EAV2 <= 1'b1;
		else 
			line_EAV2 <= 1'b0; 				
end
//-----------------------------------------------  line_EAV3 
always @(posedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
        line_EAV3 <= 0; 
	else
        if (pix_EAV3 || pix_SAV3) 
			line_EAV3 <= 1'b1;
		else 
			line_EAV3 <= 1'b0; 				
end

//-----------------------------------------------  line_LN0
always @(posedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
        line_LN0 <= 0; 
	else	
        if (pix_LN0) 
			line_LN0 <= 1'b1;
		else 
			line_LN0 <= 1'b0; 				
end
//-----------------------------------------------  line_LN1
always @(posedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
        line_LN1 <= 0; 
	else
        if (pix_LN1) 
			line_LN1 <= 1'b1;
		else 
			line_LN1 <= 1'b0; 				
end
//-----------------------------------------------  line_CRC0
always @(posedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
        line_CRC0 <= 0; 
	else	
        if (pix_CRC0) 
			line_CRC0 <= 1'b1;
		else 
			line_CRC0 <= 1'b0; 				
end

//-----------------------------------------------  line_CRC1
always @(posedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
        line_CRC1 <= 0; 
	else
        if (pix_CRC1) 
			line_CRC1 <= 1'b1;
		else 
			line_CRC1 <= 1'b0; 				
end

//-----------------------------------------------  line_BLANK  
always @(posedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
		line_BLANK <= 0; 
	else 
		if (pix_BLANK) 
			line_BLANK <= 1'b1;
		else 
			line_BLANK <= 1'b0; 				
end

//************* CRC CODE *************
reg  [17:0] crcIn_Y, crcIn_C;
wire [17:0] crcOut_Y, crcOut_C;
reg  [9:0]  CRC0_Y, CRC1_Y, CRC0_C, CRC1_C;   
crcSMPTE CRC_Y (
    .crcIn        (crcIn_Y),
    .data         (pdata_Y),
    .crcOut       (crcOut_Y)
);

crcSMPTE CRC_C (
    .crcIn        (crcIn_C),
    .data         (pdata_C),
    .crcOut       (crcOut_C)
);

always @(posedge i_CLK_74m25 or posedge i_RST) 
begin
    if (i_RST)
        begin
           crcIn_Y <= 10'h000;
           CRC0_Y  <= 10'h000;
           CRC1_Y  <= 10'h000;
           CRC0_C  <= 10'h000;
           CRC1_C  <= 10'h000;
        end	    
	else 
	   if (pix_cnt == 0)
           begin
               crcIn_Y <= 10'h000;
               CRC0_Y  <= 10'h000;
               CRC1_Y  <= 10'h000;
               
               crcIn_C <= 10'h000;
               CRC0_C  <= 10'h000;
               CRC1_C  <= 10'h000;
           end
       else
           begin
               crcIn_Y <= crcOut_Y;
               crcIn_C <= crcOut_C;
               
               CRC0_Y  <= {~crcOut_Y[8] , crcOut_Y[8 :0]};
               CRC1_Y  <= {~crcOut_Y[17], crcOut_Y[17:9]};
                 
               CRC0_C  <= {~crcOut_C[8] , crcOut_C[8 :0]};
               CRC1_C  <= {~crcOut_C[17], crcOut_C[17:9]};
       end
    end
//************* end CRC CODE *************

reg  [ 9 : 0] pdata_Y, pdata_C; 
//  WE FORM CURRENT DATA DEPENDING ON THE CURRENT PIXEL NUMBER
//-----------------------------------------------  pdata 
always @(posedge i_CLK_74m25 or posedge i_RST) 
begin 
	if (i_RST)
	begin
		pdata_Y <= 0;
		pdata_C <= 0;  
	end
	else
    if (line_EAV0)
      begin 
        pdata_Y <= 10'h3ff; 
        pdata_C <= 10'h3ff;
      end
    else if (line_EAV1)
      begin
        pdata_Y <= 10'h000;
        pdata_C <= 10'h000;
      end
    else if (line_EAV2) 
      begin
        pdata_Y <= 10'h000;	
        pdata_C <= 10'h000;
      end
    else if (line_EAV3)
      begin
        //          fix , F, V, H, P3 , P2 ,  P1, P0   ,fix , fix                                                  
        pdata_Y <= {1'b1, F, V, H, V^H, F^H, F^V, F^V^H,1'b0, 1'b0 };
        pdata_C <= {1'b1, F, V, H, V^H, F^H, F^V, F^V^H,1'b0, 1'b0 };
      end
    else if (line_LN0)
      begin 
        //          not b8        , L6-L0          , fix, fix 
        pdata_Y <= {~LINE_CNT_o[6], LINE_CNT_o[6:0],1'b0,1'b0};
        pdata_C <= {~LINE_CNT_o[6], LINE_CNT_o[6:0],1'b0,1'b0};
      end
    else if (line_LN1) 
      begin
        //          not b8,fix ,fix ,fix ,  L10-L7        ,fix , fix 
        pdata_Y <= {1'b1  ,1'b0,1'b0,1'b0,LINE_CNT_o[10:7],1'b0, 1'b0};
        pdata_C <= {1'b1  ,1'b0,1'b0,1'b0,LINE_CNT_o[10:7],1'b0, 1'b0}; 
      end
    else if (line_CRC0)
      begin
        pdata_Y <= CRC0_Y;
        pdata_C <= CRC0_C;
      end
    else if (line_CRC1)
      begin
        pdata_Y <= CRC1_Y;
        pdata_C <= CRC1_C;
      end	            	 	 		
    else if (line_BLANK) 
      begin  
        // not sure about byte values
        pdata_Y <= 10'h040;
        pdata_C <= 10'h200;	
      end
    else
      begin  
        pdata_Y <= i_data_Y;
        pdata_C <= i_data_C;
      end						
end 

//OUTPUTS
assign PIX_CNT_o  = pix_cnt; 
assign LINE_CNT_o = line_cnt;
assign Y_data_o   = pdata_Y;
assign C_data_o   = pdata_C;
assign VSYNC_o    = vsync;
assign HSYNC_o    = hsync;
assign DATA_RQ_o  = line_data_rq;
    
endmodule