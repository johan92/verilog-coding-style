module reverse_counter #(
  parameter CNT_WIDTH = 32 
) (

  input                        clk_i,
  input                        rst_i,
  
  input                        reverse_i,
  
  input        [CNT_WIDTH-1:0] set_value_data_i,
  input                        set_value_en_i,

  output logic [CNT_WIDTH-1:0] cnt_o 

); 

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    cnt_o <= 'd0;
  else
    if( set_value_en_i )
      cnt_o <= set_value_data_i;
    else
      if( reverse_i )
        cnt_o <= cnt_o - 1'd1;
      else
        cnt_o <= cnt_o + 1'd1;

endmodule
