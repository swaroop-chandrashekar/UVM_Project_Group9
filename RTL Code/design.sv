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
rptr_handler #(ADDR_SIZE)       	rptr_handler_inst     (.*);
wptr_handler #(ADDR_SIZE)       	wptr_handler_inst     (.*);

endmodule

//////////********* Synchronizer write to read module*********////////////


module synchronizer_w2r #(parameter ADDR_SIZE = 12)(rclk, rrst, wptr, wptr_s);

input rclk, rrst
input [ADDR_SIZE:0] wptr;
output logic [ADDR_SIZE:0] wptr_s;
     
logic [ADDR_SIZE:0] r1_wptr;

always_ff @(posedge rclk or negedge rrst) 
begin
	if (!rrst) 
	begin
        	{wptr_s, r1_wptr} <= 0;
    	end
    	else 
	begin
      		{wptr_s, r1_wptr} <= {r1_wptr, wptr};
    	end
end

endmodule

//////////*********rptr handler module**********///////////

module rptr_handler #(parameter ADDR_SIZE = 12)( rinc, rclk, rrst, wptr_s, rEmpty, raddr, rptr);

input  logic rinc, rclk , rrst;
input  logic [ADDR_SIZE :0] wptr_s;
output logic rEmpty;
output logic [ADDR_SIZE-1:0] raddr;
output logic [ADDR_SIZE :0] rptr;

logic [ADDR_SIZE:0] rbin;                                                 //register for read pointer in binary
logic rEmpty_reg;                                                         //register whether fifo empty or not
logic [ADDR_SIZE:0] rgraynext;                                            //next read pointer in gray code
logic [ADDR_SIZE:0] rbinnext;                                             //next read pointer in binary form

always_ff @(posedge rclk or negedge rrst)
begin
       	if (!rrst) 
	begin
          	{rbin, rptr} <= 0;
        end
       	else 
	begin
            	{rbin, rptr} <= {rbinnext, rgraynext};             //when reset is low it will set to 0 otherwise point to next location
        end
end

assign raddr = rbin[ADDR_SIZE-1:0];                                       //read address of the fifo

always_comb 
begin                                                                     //read pointer logic
	rbinnext = rbin + (rinc & ~rEmpty);                               //updated when rinc is high and fifo is not empty
  rgraynext = (rbinnext>>1) ^ rbinnext;                             //binary to gray code conversion 
end 

assign rEmpty_reg = (rgraynext == wptr_s);                                //empty generation logic

always_ff @(posedge rclk or negedge rrst)                      
begin
        if (!rrst)
       		rEmpty <= 1'b1;
       	else 
       		rEmpty <= rEmpty_reg;
end

endmodule


//////*********wptr handler module*************///////

module wptr_handler #(parameter ADDR_SIZE = 12)(winc, wclk, wrst, rptr_s, wFull, waddr, wptr);

input logic winc, wclk, wrst;
input logic [ADDR_SIZE :0] rptr_s;
output logic wFull;
output logic [ADDR_SIZE-1:0] waddr;
output logic [ADDR_SIZE :0] wptr;

logic wFull_reg;                                                                    		     //register whether fifo full or not
logic [ADDR_SIZE:0] wbin;                                                           		     //register for write pointer in binary
logic [ADDR_SIZE:0] wgraynext;                                                      		     //next write pointer in gray code
logic [ADDR_SIZE:0] wbinnext;                                                       		     //next write pointer in binary

always_ff @(posedge wclk or negedge wrst)
begin
	if (!wrst) 
	begin
        	{wbin, wptr} <= 0;
    	end
    	else 
	begin                                                                     	 	     //when reset is low it will set to 0 otherwise point to next write location
        	{wbin, wptr} <= {wbinnext, wgraynext};
    	end
end

assign waddr = wbin[ADDR_SIZE-1:0];                                                 	             //write address is assigned the address bits from wbin - binary

always_comb 
begin                                                                   		             //write pointer logic
	wbinnext = wbin + (winc & ~wFull);                                                           //updated when write increment is high and fifo is not full
    	wgraynext = (wbinnext>>1) ^ wbinnext;                                                        //calculated by converting binary to gray code
end

assign wFull_reg = (wgraynext=={~rptr_s[ADDR_SIZE : ADDR_SIZE-1], rptr_s[ADDR_SIZE-2:0]});           //it is set to 1 if next write pointer matches rptr_s indicating fifo is full

always_ff @(posedge wclk or negedge wrst)
begin
	if (!wrst) 
	begin
        	wFull <= 1'b0;
    	end
    	else 
	begin
        	wFull <= wFull_reg;
    	end
end

endmodule



