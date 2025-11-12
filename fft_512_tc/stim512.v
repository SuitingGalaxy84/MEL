//----------------------------------------------------------------------
//	Test Stimuli for FFT512
//----------------------------------------------------------------------

initial begin : STIM
	wait (reset == 1);
	wait (reset == 0);
	repeat(10) @(posedge clock);

	fork
		begin
//			LoadInputData("D:\\Desktop\\PG Repo\\MEL\\fft_512_tc\\input1.txt");
//			GenerateInputWave;
		//	@(posedge clock);
			LoadInputData("D:\\Desktop\\PG Repo\\MEL\\fft_512_tc\\input2.txt");
			GenerateInputWave;
		end
		begin
//			wait (do_en == 1);
//			repeat(N) @(posedge clock);
//			SaveOutputData("D:\\Desktop\\PG Repo\\MEL\\fft_512_tc\\output1.txt");
//			@(negedge clock);
			wait (do_en == 1);
			repeat(N) @(posedge clock);
			SaveOutputData("D:\\Desktop\\PG Repo\\MEL\\fft_512_tc\\output2.txt");
		end
	join

	repeat(10) @(posedge clock);
	$finish;
end
initial begin : TIMEOUT
	repeat(5000) #20;	//  5000 Clock Cycle Time (increased for 512-point FFT)
	$display("[FAILED] Simulation timed out.");
	$finish;
end
