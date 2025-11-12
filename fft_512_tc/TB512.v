//----------------------------------------------------------------------
//	TB512: FFT512 Testbench
//----------------------------------------------------------------------
`timescale	1ns/1ns
module TB512 #(
	parameter	N = 512,
	parameter   CLK_PERIOD = 10
);

localparam		NN = log2(N);	//	Count Bit Width of FFT Point

//	log2 constant function
function integer log2;
	input integer x;
	integer value;
	begin
		value = x-1;
		for (log2=0; value>0; log2=log2+1)
			value = value>>1;
	end
endfunction

//	Internal Regs and Nets
reg			clock;
reg			reset;
reg			di_en;
reg	[15:0]	di_re;
reg	[15:0]	di_im;
wire		do_en;
wire[15:0]	do_re;
wire[15:0]	do_im;
wire[9:0]   fft_cnt;
reg	[15:0]	imem[0:2*N-1];
reg	[15:0]	omem[0:2*N-1];

//----------------------------------------------------------------------
//	Clock and Reset
//----------------------------------------------------------------------
initial begin
    clock = 1'b0;
    forever #(CLK_PERIOD / 2) 
    clock = ~clock;
end

initial begin
	clock = 0;
	reset = 0; #20;
	reset = 1; #100;
	reset = 0;
end

//----------------------------------------------------------------------
//	Functional Blocks
//----------------------------------------------------------------------

//	Input Control Initialize
initial begin
	wait (reset == 1);
	di_en = 0;
end

//	Output Data Capture
initial begin : OCAP
	integer		n;
	forever begin
		n = 0;
		while (do_en !== 1) @(negedge clock);
		while ((do_en == 1) && (n < N)) begin
			omem[2*n  ] = do_re;
			omem[2*n+1] = do_im;
			n = n + 1;
			@(negedge clock);
		end
	end
end

//----------------------------------------------------------------------
//	Tasks
//----------------------------------------------------------------------
task LoadInputData;
	input[80*8:1]	filename;
begin
	$readmemh(filename, imem);
end
endtask

task GenerateInputWave;
	integer	n;
begin
	di_en <= 1;
	for (n = 0; n < N; n = n + 1) begin
		di_re <= imem[2*n];
		di_im <= imem[2*n+1];
		@(posedge clock);
	end
	di_en <= 0;
	di_re <= 'bx;
	di_im <= 'bx;
end
endtask

task SaveOutputData;
	input[80*8:1]	filename;
	integer			fp, n, m, i;
begin
	fp = $fopen(filename);
	m = 0;
	for (n = 0; n < N; n = n + 1) begin
		for (i = 0; i < NN; i = i + 1) m[NN-1-i] = n[i];
		$fdisplay(fp, "%h  %h  // %d", omem[2*m], omem[2*m+1], n[NN-1:0]);
	end
	$fclose(fp);
end
endtask

//----------------------------------------------------------------------
//	Module Instances
//----------------------------------------------------------------------
FFT512 FFT (
	.clock	(clock	),	//	i
	.reset	(reset	),	//	i
	.di_en	(di_en	),	//	i
	.di_re	(di_re	),	//	i
	.di_im	(di_im	),	//	i
	.do_en	(do_en	),	//	o
	.do_re	(do_re	),	//	o
	.do_im	(do_im	),	//	o
	.fft_cnt(fft_cnt)
);

//----------------------------------------------------------------------
//	Include Stimuli
//----------------------------------------------------------------------
`include "stim512.v"

endmodule
