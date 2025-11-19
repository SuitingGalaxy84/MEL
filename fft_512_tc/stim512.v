//----------------------------------------------------------------------
//	Test Stimuli for FFT512
//----------------------------------------------------------------------

initial begin : STIM
	wait (reset == 1);
	wait (reset == 0);
	repeat(10) @(posedge clock);

	fork
		begin
			//D:\\Desktop\\PG Repo\\MEL\\fft_512_tc\\
			LoadInputData("input_iverilog/input1.txt");
			GenerateInputWave;
			@(posedge clock);
			LoadInputData("input_iverilog/input2.txt");
			GenerateInputWave;
			@(posedge clock);
			LoadInputData("input_iverilog/input3.txt");
			GenerateInputWave;
			@(posedge clock);
			LoadInputData("input_iverilog/input4.txt");
			GenerateInputWave;
			@(posedge clock);
			LoadInputData("input_iverilog/input5.txt");
			GenerateInputWave;
			@(posedge clock);
			LoadInputData("input_iverilog/input6.txt");
			GenerateInputWave;
			@(posedge clock);
			LoadInputData("input_iverilog/input7.txt");
			GenerateInputWave;
			@(posedge clock);
			LoadInputData("input_iverilog/input8.txt");
			GenerateInputWave;
		end
		begin
			wait (do_en == 1);
			repeat(N) @(posedge clock);
			SaveOutputData("output_iverilog/output1.txt");
			@(negedge clock);
			wait (do_en == 1);
			repeat(N) @(posedge clock);
			SaveOutputData("output_iverilog/output2.txt");
			@(negedge clock);
			wait (do_en == 1);
			repeat(N) @(posedge clock);
			SaveOutputData("output_iverilog/output3.txt");
			@(negedge clock);
			wait (do_en == 1);
			repeat(N) @(posedge clock);
			SaveOutputData("output_iverilog/output4.txt");
			@(negedge clock);
			wait (do_en == 1);
			repeat(N) @(posedge clock);
			SaveOutputData("output_iverilog/output5.txt");
			@(negedge clock);
			wait (do_en == 1);
			repeat(N) @(posedge clock);
			SaveOutputData("output_iverilog/output6.txt");
			@(negedge clock);
			wait (do_en == 1);
			repeat(N) @(posedge clock);
			SaveOutputData("output_iverilog/output7.txt");
			@(negedge clock);
			wait (do_en == 1);
			repeat(N) @(posedge clock);
			SaveOutputData("output_iverilog/output8.txt");
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
