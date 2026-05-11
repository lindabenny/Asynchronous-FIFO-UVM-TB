// Code your testbench here
// or browse Examples

`include "uvm_macros.svh"
import uvm_pkg::*;

class config_db extends uvm_object;
  `uvm_object_utils(config_db)
  
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  
  
  function new(string path = "Config");
    super.new(path);
  endfunction
  
endclass 

////////////////////////////////////////////////////////////////////////////////////

class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction)
  
  function new(string path = "Trans");
    super.new(path);
  endfunction
  
  rand bit wr_en;
  rand bit rd_en;
  bit rst_n;
  rand bit [7:0] wr_data;
  bit full;
  bit empty;
  bit [7:0] rd_data;
  
  constraint valid_en {
    wr_en dist { 1 := 70 , 0 := 30};
    rd_en dist { 1 := 70 , 0 := 30};
    
    !(wr_en == 0 && rd_en == 0);
  }
  
  constraint valid_data {
    wr_data inside {[100:200]};
  }
  
endclass

////////////////////////////////////////////////////////////////////////////////////

class seq1 extends uvm_sequence#(transaction);
  `uvm_object_utils(seq1)
  
  transaction tr;
  
  function new(string path = "Seq1");
    super.new(path);
    
  endfunction

  virtual task body();
    
    repeat(10)begin
      tr = transaction::type_id::create("TR");
        start_item(tr);
        assert(tr.randomize()) else `uvm_error("seq1", "Randomization failed");
      
      `uvm_info("SEQ1", $sformatf("wr_en = %0d, wr_data = %0d, rd_en = %0d, rd_data = %0d", tr.wr_en, tr.wr_data, tr.rd_en, tr.rd_data), UVM_LOW);
        finish_item(tr);
        
      end
    
  endtask
  
endclass

////////////////////////////////////////////////////////////////////////////////

class seq2 extends uvm_sequence#(transaction);
  `uvm_object_utils(seq2)
  
  transaction tr;
  integer i;
  
  function new(string path = "Seq2");
    super.new(path);
    
  endfunction

  virtual task body();
    for(i = 0; i<16;i++)
    begin
      tr = transaction::type_id::create("TR");
      start_item(tr);
      assert(tr.randomize()) else `uvm_error("seq2", "Randomization failed");
      tr.constraint_mode(0);
      tr.wr_en = 1'b1;
      tr.rd_en = 1'b0;
      
      `uvm_info("SEQ2", $sformatf("wr_en = %0d, wr_data = %0d, rd_en = %0d, rd_data = %0d", tr.wr_en, tr.wr_data, tr.rd_en, tr.rd_data), UVM_LOW);
        finish_item(tr);
        
      end
    
  endtask
  
endclass

////////////////////////////////////////////////////////////////////////////////

class seq3 extends uvm_sequence#(transaction);
  `uvm_object_utils(seq3)
  
  transaction tr;
  integer i;
  
  function new(string path = "Seq3");
    super.new(path);
    
  endfunction

  virtual task body();
    for(i = 0; i<16;i++)
    begin
      tr = transaction::type_id::create("TR");
      start_item(tr);
      //assert(tr.randomize()) else `uvm_error("seq3", "Randomization failed");
      tr.constraint_mode(0);
      tr.wr_en = 1'b0;
      tr.rd_en = 1'b1;
      
      `uvm_info("SEQ3", $sformatf("wr_en = %0d, wr_data = %0d, rd_en = %0d, rd_data = %0d", tr.wr_en, tr.wr_data, tr.rd_en, tr.rd_data), UVM_LOW);
        finish_item(tr);
        
      end
    
  endtask
  
endclass

///////////////////////////////////////////////////////////////////////////////////////

class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver)
  
  transaction tr;
  virtual async_if vif;
  
  function new(string path = "Driver", uvm_component parent = null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if(!uvm_config_db#(virtual async_if)::get(this,"","vif",vif))
      `uvm_error("DRV", "Interface is not connected")
    
    tr = transaction::type_id::create("TR",this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    
    wait(vif.rst_n);
    
    forever begin
      seq_item_port.get_next_item(tr);
      `uvm_info("DRV", $sformatf("wr_en = %0d, wr_data = %0d, rd_en = %0d, rd_data = %0d", tr.wr_en, tr.wr_data, tr.rd_en, tr.rd_data), UVM_LOW);
      fork 
        
        begin
          @(negedge vif.wr_clk);
          begin
            vif.wr_en <= tr.wr_en;
            vif.wr_data <= tr.wr_data;
          end
          @(negedge vif.wr_clk);
          vif.wr_en <= 1'b0;
        end
        
      
        begin
          @(negedge vif.rd_clk);
          
            vif.rd_en <= tr.rd_en;
         
          @(negedge vif.rd_clk);
          
          vif.rd_en <= 1'b0;
        end
    
      join
      
      seq_item_port.item_done();
    end
  endtask
  
endclass

//////////////////////////////////////////////////////////////////////////////////////////////




class wr_monitor extends uvm_monitor;
  `uvm_component_utils(wr_monitor)
  
  virtual async_if vif;
  transaction tr;
  
  uvm_analysis_port#(transaction) send_wr;
  
  function new(string path = "Wr_Mon", uvm_component parent = null);
    super.new(path, parent);
    
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    send_wr = new("Send_wr", this);
    
    if(!uvm_config_db#(virtual async_if)::get(this,"","vif",vif))
      `uvm_error("MON_WRITE", "Interface cannot be connected");
      
  endfunction   
  
  virtual task run_phase(uvm_phase phase);
   
    wait(vif.rst_n);
    
    forever begin
       @(posedge vif.wr_clk);
      #1;
      tr = transaction::type_id::create("TR", this);
      if(vif.wr_en && !vif.full)
      	begin
      		
      		tr.wr_en = vif.wr_en;
     		tr.wr_data = vif.wr_data;
      		tr.full = vif.full;
      
      `uvm_info("MON_WRITE", $sformatf("wr_en = %0d, wr_data = %0d, Full = %0d", tr.wr_en, tr.wr_data, tr.full), UVM_LOW);
      send_wr.write(tr);
          
   		end
       else if(vif.full)
        begin
      		
      		tr.wr_en = vif.wr_en;
     		tr.wr_data = vif.wr_data;
      		tr.full = vif.full;
      
      `uvm_info("MON_WRITE", $sformatf("wr_en = %0d, wr_data = %0d, Full = %0d", tr.wr_en, tr.wr_data, tr.full), UVM_LOW);
      send_wr.write(tr);
        end
       
    end

  endtask
  
endclass

//////////////////////////////////////////////////////////////////////////////////////////////



class rd_monitor extends uvm_monitor;
  `uvm_component_utils(rd_monitor)
  
  virtual async_if vif;
  transaction tr;
  
  uvm_analysis_port#(transaction) send_rd;
  
  function new(string path = "Rd_Mon", uvm_component parent = null);
    super.new(path, parent);
    
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    send_rd = new("send_rd", this);
    
    if(!uvm_config_db#(virtual async_if)::get(this,"","vif",vif))
      `uvm_error("MON_READ", "Interface cannot be connected");
      
  endfunction   
  
  
  virtual task run_phase(uvm_phase phase);
    
    wait(vif.rst_n);
    
    forever begin
      
       @(posedge vif.rd_clk);
      #1;
      	
        if(vif.rd_en && !vif.empty)
       		 begin
                tr = transaction::type_id::create("TR", this);
                tr.rd_en = vif.rd_en;  
      			tr.empty = vif.empty;
      			tr.rd_data = vif.rd_data;
                  
               `uvm_info("MON_READ", $sformatf("rd_en = %0d, rd_data = %0d, Empty = %0d", tr.rd_en, tr.rd_data, tr.empty), UVM_LOW);
                   
      			send_rd.write(tr);
         
             end
    	end
    
  endtask
  
endclass

///////////////////////////////////////////////////////////////////////////////////////////

  
`uvm_analysis_imp_decl(_wr)
 `uvm_analysis_imp_decl(_rd)


class sco extends uvm_scoreboard;
  `uvm_component_utils(sco)
  
  

  
  uvm_analysis_imp_wr#(transaction, sco) recv_wr;
  uvm_analysis_imp_rd#(transaction, sco) recv_rd;
  
  bit[7:0] fifo_queue[$];
  bit[7:0] expected_data;
  
  function new(string path = "Sco", uvm_component parent = null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    recv_wr = new("recv_wr", this);
    recv_rd = new("recv_rd", this);
    
  endfunction
  
  virtual function void write_wr(transaction tr);
    
    if(tr.wr_en && !tr.full) begin
      fifo_queue.push_back(tr.wr_data);
      `uvm_info("SCO_WRITE", $sformatf("Write Expected data = %0d", tr.wr_data), UVM_LOW)
    end
    else if(tr.wr_en && tr.full)
      `uvm_info("SCO_WRITE", $sformatf("FIFO FULL = %0b", tr.full), UVM_LOW)
      
  endfunction
  
  virtual function void write_rd(transaction tr);
    if(tr.rd_en && !tr.empty) begin
      if(fifo_queue.size() == 0) begin
        `uvm_error("SCO", "Read done but the queue is empty")
      end
      else 
        begin
        expected_data = fifo_queue.pop_front();
          `uvm_info("SCO_READ", $sformatf("Read Expected data = %0d", expected_data), UVM_LOW)

      if(expected_data != tr.rd_data) begin
        `uvm_error("SCO",$sformatf("DATA MISMATCH Expected data = %0d, Actual data = %0d", expected_data, tr.rd_data))
        end 
      else begin
        `uvm_info("SCO", $sformatf("DATA MATCH Expected data = %0d, Actual data = %0d", expected_data, tr.rd_data), UVM_NONE)
          
          
        end
        end
      `uvm_info("SCO", "-------------------------------------",UVM_NONE);
    end
  
    endfunction
  
endclass


////////////////////////////////////////////////////////////////////////////////////////////////


class agent extends uvm_agent;
  `uvm_component_utils(agent)
  
  driver d;
  wr_monitor wm;
  rd_monitor rm;
  uvm_sequencer#(transaction) seqr;
  
  config_db cfg;
  
  function new(string path = "Agent", uvm_component parent = null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    wm = wr_monitor::type_id::create("wm",this);
    rm = rd_monitor::type_id::create("rm",this);
    cfg = config_db::type_id::create("cfg");
    
    if(!uvm_config_db#(config_db)::get(this,"","cfg",cfg))
      `uvm_error("AGNT", "Cannot access the Config");

    if(cfg.is_active == UVM_ACTIVE)
      begin
        d = driver::type_id::create("d",this);
   		seqr = uvm_sequencer#(transaction)::type_id::create("seqr", this);
      end
    

  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(cfg.is_active == UVM_ACTIVE)
       begin
    		d.seq_item_port.connect(seqr.seq_item_export);
       end
    
  endfunction
  
endclass

/////////////////////////////////////////////////////////////////////////////////////


class env extends uvm_env;
  `uvm_component_utils(env)
 
  agent a;
  sco s;
  
  config_db cfg;
  
  function new(string path = "Env", uvm_component parent = null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    a = agent::type_id::create("a", this);
    s = sco::type_id::create("s",this);
    
    cfg = config_db::type_id::create("cfg");
    
    uvm_config_db#(config_db)::set(this,"a","cfg",cfg);
    
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    a.wm.send_wr.connect(s.recv_wr);
    a.rm.send_rd.connect(s.recv_rd);
    
  endfunction
  
endclass

/////////////////////////////////////////////////////////////////////////////////////////

class test extends uvm_test;
  `uvm_component_utils(test)
  
  env e;
  seq1 s1;
  seq2 s2;
  seq3 s3;
  
  function new(string path = "test", uvm_component parent = null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    e = env::type_id::create("e",this);
    s1 = seq1::type_id::create("s1");
    s2 = seq2::type_id::create("s2");
    s3 = seq3::type_id::create("s3");
    
  endfunction
  
  
  virtual task run_phase(uvm_phase phase);
    
    phase.raise_objection(this);
    
    s2.start(e.a.seqr);
    
    #10;
    
   // @(posedge e.a.rm.vif.rd_clk);
    
    s3.start(e.a.seqr);
    
    repeat(10) @(posedge e.a.rm.vif.rd_clk);
    
    /*
    s1.start(e.a.seqr);
    repeat(10) @(posedge e.a.rm.vif.rd_clk);
    */
    phase.drop_objection(this);
    
  endtask
  
endclass

///////////////////////////////////////////////////////////////////////////////////////////////

module tb_top;
  
  parameter DATA_WIDTH = 8;
  parameter ADDR_WIDTH = 4;
  
  async_if aif();
  
  asyn_fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) dut (.wr_clk(aif.wr_clk), .wr_en(aif.wr_en), .rst_n(aif.rst_n), .wr_data(aif.wr_data), .rd_clk(aif.rd_clk), .rd_en(aif.rd_en),.full(aif.full), .empty(aif.empty), .rd_data(aif.rd_data));
  
  initial begin 
    aif.wr_clk = 0;
  end
  
  always #5 aif.wr_clk = ~aif.wr_clk;
  
  initial begin 
    aif.rd_clk = 0;
  end
  
  always #7 aif.rd_clk = ~aif.rd_clk;
 
  initial begin
    aif.rst_n = 0;
    aif.wr_en = 0;
    aif.rd_en = 0;
    aif.wr_data = 0;

    #10;
    aif.rst_n = 1;
    
	`uvm_info("TOP", $sformatf("rst_n = %0b, wr_en = %0d, wr_data = %0d, rd_en = %0d, rd_data = %0d", aif.rst_n, aif.wr_en, aif.wr_data, aif.rd_en, aif.rd_data), UVM_LOW);
    
    `uvm_info("TOP", "RESET DONE", UVM_LOW);
  end

  
  initial begin
    
    uvm_config_db#(virtual async_if)::set(null,"*","vif", aif);
    run_test("test");
  end
  
  initial begin 
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
endmodule
