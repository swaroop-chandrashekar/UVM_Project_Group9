// File : async_fifo.sv 
// Top level Module

module ASYNC_FIFO #( parameter DATA_SIZE = 12, ADDR_SIZE = 12) ( winc, wclk, wrst,  rinc, rclk, rrst,  wData, rData, wFull, rEmpty);

input  logic winc, wclk, wrst;
input  logic rinc, rclk, rrst;
input  logic [DATA_SIZE-1:0] wData;

output logic [DATA_SIZE-1:0] rData;
output logic wFull;
output logic rEmpty;

logic [ADDR_SIZE-1:0] waddr, raddr;
logic [ADDR_SIZE:0] wptr, rptr, rptr_s, wptr_s;

synchronizer_w2r                 	synchronizer_w2r_inst (.*); // write pointer to read clock domain
synchronizer_r2w                 	synchronizer_r2w_inst (.*); // Read pointer to write clock domain

fifo_mem #(DATA_SIZE, ADDR_SIZE, DEPTH) fifo_mem_inst         (.*);
rptr_handler #(ADDR_SIZE)       	    rptr_handler_inst     (.*);
wptr_handler #(ADDR_SIZE)       	    wptr_handler_inst     (.*);

endmodule

