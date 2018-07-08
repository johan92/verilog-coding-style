`include "defs.vh"

module qstage #( 
  parameter A_WIDTH      = 4,
  parameter D_WIDTH      = 16,

  parameter STAGE_NUM    = 1,

  parameter OPT_LEVEL    = 0
) (

  input                                 clk_i,
  input                                 rst_i,

  qstage_ctrl_if                        ctrl_if,
  
  input                                 lookup_en_i,
  input              [A_WIDTH-1:0]      lookup_addr_i,
  input              [D_WIDTH-1:0]      lookup_data_i,
  
  output                                lookup_en_o,
  output             [A_WIDTH-1:0]      lookup_addr_o,
  output             [D_WIDTH-1:0]      lookup_data_o

);

localparam STAGE_A_WIDTH = ( STAGE_NUM == 0 ) ? ( 1 ) : ( 2*STAGE_NUM );
localparam MAX_DELAY     = ( OPT_LEVEL == 0 ) ? ( 4 ) : ( 5           );

ram_data_t                         rd_data_w;

logic [MAX_DELAY-1:1]              lookup_en_d;
logic [MAX_DELAY-1:1][A_WIDTH-1:0] lookup_addr_d;
logic [MAX_DELAY-1:1][D_WIDTH-1:0] lookup_data_d;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i ) begin
    for( int i = 1; i < MAX_DELAY; i++ ) begin
      lookup_en_d   [ i ] <= '0;
      lookup_addr_d [ i ] <= '0;
      lookup_data_d [ i ] <= '0;
    end
  end else begin
    lookup_en_d   [ 1 ] <= lookup_en_i;
    lookup_addr_d [ 1 ] <= lookup_addr_i;
    lookup_data_d [ 1 ] <= lookup_data_i;
    
    for( int i = 2; i < MAX_DELAY; i++ ) begin
      lookup_en_d   [ i ] <= lookup_en_d   [ i - 1 ];   
      lookup_addr_d [ i ] <= lookup_addr_d [ i - 1 ]; 
      lookup_data_d [ i ] <= lookup_data_d [ i - 1 ]; 
    end
  end


simple_ram #( 
  .DATA_WIDTH                             ( $bits( ram_data_t )                  ), 
  .ADDR_WIDTH                             ( STAGE_A_WIDTH                        )
) tr_ram (

  .clk                                    ( clk_i                                ),

  .write_addr                             ( ctrl_if.wr_addr[STAGE_A_WIDTH-1:0]   ),
  .data                                   ( ctrl_if.wr_data                      ),
  .we                                     ( ctrl_if.wr_en                        ),

  .read_addr                              ( lookup_addr_i[STAGE_A_WIDTH-1:0]     ),
  .q                                      ( rd_data_w                            )
);

// less or equal values l, m, r
logic le_l;
logic le_m;
logic le_r;

generate
  if( OPT_LEVEL == 0 ) begin : no_opt
    assign le_l = ( lookup_data_d[2] <= rd_data_w.l );
    assign le_m = ( lookup_data_d[2] <= rd_data_w.m );
    assign le_r = ( lookup_data_d[2] <= rd_data_w.r );
  end else begin : opt
    always_ff @( posedge clk_i ) begin
      le_l <= ( lookup_data_d[2] <= rd_data_w.l );
      le_m <= ( lookup_data_d[2] <= rd_data_w.m );
      le_r <= ( lookup_data_d[2] <= rd_data_w.r );
    end
  end
endgenerate

logic [1:0] next_addr_append;

always_ff @( posedge clk_i )
  begin
    casex( { le_l, le_m, le_r } )
      3'b01x:  next_addr_append <= 'd1;
      3'b001:  next_addr_append <= 'd2;
      3'b000:  next_addr_append <= 'd3;
      default: next_addr_append <= 'd0;
    endcase
  end

assign lookup_addr_o = ( STAGE_A_WIDTH == 1 ) ? (                                                  next_addr_append   ):
                                                ( { lookup_addr_d[MAX_DELAY-1][STAGE_A_WIDTH-1:0], next_addr_append } );

assign lookup_en_o   = lookup_en_d  [MAX_DELAY-1];
assign lookup_data_o = lookup_data_d[MAX_DELAY-1];

endmodule
