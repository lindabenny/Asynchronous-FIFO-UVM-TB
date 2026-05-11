// Code your design here

module asyn_fifo #(parameter DATA_WIDTH = 8,
                   parameter ADDR_WIDTH = 4)
  (input wr_clk, wr_en, rst_n,
   input rd_clk, rd_en,
   input [DATA_WIDTH-1:0] wr_data,
   output full, empty,
   output reg [DATA_WIDTH-1:0] rd_data);
  
  localparam DEPTH = 1<<ADDR_WIDTH;
  
  reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
  reg [ADDR_WIDTH:0] wr_ptr_bin, wr_ptr_gray;
  reg [ADDR_WIDTH:0] rd_ptr_bin, rd_ptr_gray;
  reg [ADDR_WIDTH:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
  reg [ADDR_WIDTH:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
  
  
  
  function automatic [ADDR_WIDTH:0] bin2gray (input [ADDR_WIDTH:0]bin);
    return (bin >> 1)^ bin;
  endfunction
  
  
  
  function automatic [ADDR_WIDTH:0] gray2bin (input [ADDR_WIDTH:0]gray);
    logic [ADDR_WIDTH:0] bin;
    integer i;
    bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
    for(i = ADDR_WIDTH -1; i>=0; i--)
      begin
        bin[i] = bin[i+1] ^ gray[i];
      end
    gray2bin = bin;
  endfunction
 
  
  always @(posedge wr_clk or negedge rst_n)
    begin
      if(!rst_n) begin
        wr_ptr_bin <= 0;
        wr_ptr_gray <= 0;
      end
      else if(wr_en && !full) begin
        mem [wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
      
        wr_ptr_bin <= wr_ptr_bin + 1;
        wr_ptr_gray <= bin2gray(wr_ptr_bin + 1);
      end  
    end
  
 
  always @(posedge rd_clk or negedge rst_n)
    begin
      if(!rst_n) begin
      rd_ptr_bin <= 0;
      rd_ptr_gray <= 0;
      rd_data <= 0;
      end
      else if(rd_en && !empty)
        begin
          rd_data <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
          rd_ptr_bin <= rd_ptr_bin +1;
          rd_ptr_gray <= bin2gray(rd_ptr_bin + 1);
        end
    end
  
  //Synchronizer
  
  always @(posedge wr_clk or negedge rst_n)
    begin
      if (!rst_n)
        begin
          rd_ptr_gray_sync1 <= 0;
          rd_ptr_gray_sync2 <= 0;
        end
      else
        begin
        rd_ptr_gray_sync1 <= rd_ptr_gray;
      	rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
    	end
    end
  
  always @(posedge rd_clk or negedge rst_n)
    begin
      if (!rst_n)
        begin
          wr_ptr_gray_sync1 <= 0;
          wr_ptr_gray_sync2 <= 0;
        end
      else
        begin
        wr_ptr_gray_sync1 <= wr_ptr_gray;
      	wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
    	end
    end
  
  
  assign empty = (rd_ptr_gray == wr_ptr_gray_sync2);
 
  
  assign full = (wr_ptr_gray == {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1],
                                 rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});


endmodule


interface async_if #(parameter DATA_WIDTH = 8);
  logic wr_clk;
  logic wr_en;
  logic rst_n;
  logic [DATA_WIDTH-1:0] wr_data;
  logic rd_clk;
  logic rd_en;
  logic full;
  logic empty;
  logic [DATA_WIDTH-1:0] rd_data;
  
  
endinterface

    
    
  
         
          
      