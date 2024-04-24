module wptr_handler #(parameter ADDR_SIZE = 12)
       (wFull,
        waddr,
        wptr,
        rptr_s,
        winc, 
        wclk, 
        wrst
       );
output logic wFull;
output logic [ADDR_SIZE-1:0] waddr;
output logic [ADDR_SIZE :0] wptr;
input logic [ADDR_SIZE :0] rptr_s;
input logic winc;
input logic wclk;
input logic wrst;

logic wFull_reg;                                                                    //register whether fifo full or not
logic [ADDR_SIZE:0] wbin;                                                           //register for write pointer in binary
logic [ADDR_SIZE:0] wgraynext;                                                      //next write pointer in gray code
logic [ADDR_SIZE:0] wbinnext;                                                       //next write pointer in binary

always_ff @(posedge wclk or negedge wrst)
    if (!wrst) begin
        {wbin, wptr} <= 0;
    end
    else begin                                                                      //when reset is low it will set to 0 otherwise point to next write location
        {wbin, wptr} <= {wbinnext, wgraynext};
    end

assign waddr = wbin[ADDR_SIZE-1:0];                                                 //write address is assigned the address bits from wbin - binary

always_comb begin                                                                   //write pointer logic
    wbinnext = wbin + (winc & ~wFull);                                              //updated when write increment is high and fifo is not full
    wgraynext = (wbinnext>>1) ^ wbinnext;                                           //calculated by converting binary to gray code
end

assign wFull_reg = (wgraynext=={~rptr_s[ADDR_SIZE : ADDR_SIZE-1], rptr_s[ADDR_SIZE-2:0]});           //it is set to 1 if next write pointer matches rptr_s indicating fifo is full

always_ff @(posedge wclk or negedge wrst)
    if (!wrst) begin
        wFull <= 1'b0;
    end
    else begin
        wFull <= wFull_reg;
    end

endmodule
