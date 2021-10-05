`timescale 1ns / 1ps

module SMPTE274_tb();

reg               clk;
reg               RST;
reg               EN;
reg  [ 9 : 0]     i_data_Y, i_data_C;
wire [11 : 0]     PIX_CNT_o;
wire [10 : 0]     LINE_CNT_o;
wire [ 9 : 0]     Y_data_o, C_data_o ;
wire              VSYNC_o;
wire              HSYNC_o;
wire              DATA_RQ_o;


integer           data_file    ; // file handler
integer           scan_file    ; // file handler
reg  [ 9 : 0]     captured_data;
`define NULL      0 


SMPTE274 data(
  .CLK_74M                ( clk        ),
  .RST                    ( RST        ),
  .EN                     ( EN         ),
  .i_data_Y               ( i_data_Y   ),
  .i_data_C               ( i_data_C   ),
  .PIX_CNT_o              ( PIX_CNT_o  ),
  .LINE_CNT_o             ( LINE_CNT_o ),
  .Y_data_o               ( Y_data_o   ),
  .C_data_o               ( C_data_o   ),
  .VSYNC_o                ( VSYNC_o    ),
  .HSYNC_o                ( HSYNC_o    ),
  .DATA_RQ_o              ( DATA_RQ_o  )
);

initial
begin
  data_file = $fopen("out.dat", "r");
  if (data_file == `NULL)
  begin
      $display("data_file handle was NULL");
      $finish;
  end
  
  #1
  RST      <= 1;
  clk      <= 0;
  EN       <= 0;
  i_data_Y <= 10'h011;
  i_data_C <= 10'h0CC;
  #1 RST   <= 0; 
  EN       <= 1;   
end

always
begin
  #1 clk = !clk;
end

always @(posedge clk) 
begin
  if  (DATA_RQ_o)
    scan_file = $fscanf(data_file, "%d\n", captured_data);
  else
    captured_data <= 10'h000;     
  if (!$feof(data_file)) 
  begin
    i_data_Y <= captured_data;
  end
end

    
endmodule