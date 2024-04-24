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
    rbinnext = rbin + (rinc & ~rEmpty);                 //updated when rinc is high and fifo is not empty
    rgraynext = (rbinnext>>1) ^ rbinnext;               //binary to gray code conversion 
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
