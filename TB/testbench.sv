module async_fifo_TB;

parameter DATA_SIZE = 12;
parameter NUM_OF_ITERATIONS = 10;

logic  [DATA_SIZE-1:0] rData;
logic wFull;
logic rEmpty;
logic [DATA_SIZE-1:0] wData;
logic winc, wclk, wrst;
logic rinc, rclk, rrst;


// Queue to push wData
logic [DATA_SIZE-1:0] wdata_q[$], wdata;

ASYNC_FIFO DUT (.*);

always #10ns wclk = ~wclk;
always #35ns rclk = ~rclk;
  
initial 
begin
	wclk = 1'b0; wrst = 1'b0;
    	winc = 1'b0;
    	wData = 0;
    
	repeat(10) @(posedge wclk);
    	wrst = 1'b1;

    	repeat(2) 
	begin
      		for (int i=0; i<NUM_OF_ITERATIONS; i++) 
		begin
        		@(posedge wclk iff !wFull);
        		winc = (i%2 == 0)? 1'b1 : 1'b0;
        		if (winc) 
			begin
          			wData = $urandom;
          			wdata_q.push_back(wData);
        		end
      		end
      		#50;
    	end
end

initial 
begin
	rclk = 1'b0; rrst = 1'b0;
    	rinc = 1'b0;

    	repeat(20) @(posedge rclk);
    	rrst = 1'b1;

    	repeat(2) 
	begin
      		for (int i=0; i<NUM_OF_ITERATIONS; i++) 
		begin
        		@(posedge rclk iff !rEmpty);
        		rinc = (i%2 == 0)? 1'b1 : 1'b0;
        		if (rinc) 
			begin
          			wdata = wdata_q.pop_front();
          			if(rData !== wdata) 
					$error("Time = %0t: Comparison Failed: expected wr_data = %h, rd_data = %h", $time, wdata, rData);
          			else 
					$display("Time = %0t: Comparison Passed: wr_data = %h and rd_data = %h",$time, wdata, rData);
        		end
     		 end
      		#50;
    	end

    	$finish;
end
  
endmodule
  
