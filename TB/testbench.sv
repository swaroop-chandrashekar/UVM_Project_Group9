
module async_fifo_TB;

parameter DATA_SIZE = 12;
parameter NUM_OF_ITERATIONS = 10;
parameter ADDR_SIZE = 12;

logic  [DATA_SIZE-1:0] rData;
logic wFull;
logic rEmpty;
logic rHalf_empty;
logic wHalf_full;
logic [DATA_SIZE-1:0] wData;
logic winc, wclk, wrst;
logic rinc, rclk, rrst;


// Model a queue for checking data
  logic [DATA_SIZE-1:0] verif_data_q[$];
  logic[DATA_SIZE-1:0] verif_wdata;

ASYNC_FIFO  #(DATA_SIZE, ADDR_SIZE) DUT (.*);

initial 
begin
	wclk = 1'b0;
    rclk = 1'b0;
	repeat(50000)begin
		#10ns wclk = ~wclk;
      	#35ns rclk = ~rclk;
	end
end
  
initial 
begin
    winc = 1'b0;
    wData = '0;
    wrst = 1'b0;
    repeat(5) @(posedge wclk);
    wrst = 1'b1;
    	for (int i=0; i<4100; i++) 
      	begin
        	@(posedge wclk iff !wFull);
        	winc = (i%2 == 0)? 1'b1 : 1'b0;
			$display("%d",i);
        	if (winc) 
		begin
          		wData = $urandom;
          		verif_data_q.push_front(wData);
        	end
        end

end


initial 
begin
	$monitor(" \n\n Time =%t, wrst = %b, rrst = %b, winc = %d, rinc = %d, wData = %h, rData= %h,  wFull = %d, rEmpty = %d, rHalf_empty = %d, wHalf_full = %d ", $time, wrst , rrst, winc, rinc, wData, rData,  wFull, rEmpty, rHalf_empty, wHalf_full);	
end

initial begin
	rinc = 1'b0;
    	rrst = 1'b0;
    	repeat(8) @(posedge rclk);
    	rrst = 1'b1;
      		for (int i=0; i<2050; i++) 
			begin
        		@(posedge rclk iff !rEmpty)
        		rinc = (i%2 == 0)? 1'b1 : 1'b0;
        		if (rinc) 
					begin
          				verif_wdata = verif_data_q.pop_back();
          			// Check the rdata against modeled wdata
	  					wait(rData)
	  					assert(rData === verif_wdata) 
	  	 				$display(" \n\n Checking PASSED: expected wdata = %h, rdata = %h", verif_wdata, rData);
	  				else 
		  			$error(" \n\n Checking failed: expected wdata = %h, rdata = %h", verif_wdata, rData);
	  			$display("---------------------------------------------------------------------------------------------------------------------");
       			 end
      		end
      $finish();
end
endmodule
  
