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

//////////*********rptr handler module**********///////////
module rptr_handler #(parameter ADDR_SIZE = 12)
    (rEmpty,
     raddr,
     rptr,
     wptr_s,
     rinc, 
     rclk, 
     rrst
    );

output logic rEmpty;
output logic [ADDR_SIZE-1:0] raddr;
output logic [ADDR_SIZE :0] rptr;
input logic [ADDR_SIZE :0] wptr_s;
input logic rinc;
input logic rclk;
input logic rrst;

logic [ADDR_SIZE:0] rbin;                                      //register for read pointer in binary
logic rEmpty_reg;                                              //register whether fifo empty or not
logic [ADDR_SIZE:0] rgraynext;                                 //next read pointer in gray code
logic [ADDR_SIZE:0] rbinnext;                                  //next read pointer in binary form

always_ff @(posedge rclk or negedge rrst)
    begin
        if (!rrst) begin
            {rbin, rptr} <= 0;
        end
        else begin
            {rbin, rptr} <= {rbinnext, rgraynext};             //when reset is low it will set to 0 otherwise point to next location
        end
    end

assign raddr = rbin[ADDR_SIZE-1:0];                            //read address of the fifo

always_comb begin                                              //read pointer logic
    rbinnext = rbin + (rinc & ~rEmpty);                        //updated when rinc is high and fifo is not empty
    rgraynext = (rbinnext>>1) ^ rbinnext;                      //binary to gray code conversion 
end

assign rEmpty_reg = (rgraynext == wptr_s);                     //empty generation logic

always_ff @(posedge rclk or negedge rrst)                      
    begin
        if (!rrst)
        rEmpty <= 1'b1;
        else 
        rEmpty <= rEmpty_reg;
    end

endmodule
