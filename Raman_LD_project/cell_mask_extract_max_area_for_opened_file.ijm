print("START");
run("Set Measurements...", "area mean min integrated redirect=None decimal=3");
run("Options...", "iterations=1 count=1 black do=Nothing");
roiManager("Show All with labels");
run("Colors...", "foreground=white background=black selection=yellow");



	run("Analyze Particles...", "display clear add in_situ");
	max_area_idx = 0;
	max_area_val = 0;
	for(idx=0; idx<nResults; idx++){
		area_val = getResult("Area", idx);
		if(area_val > max_area_val){
			max_area_idx = idx;
			max_area_val = area_val;
		}
	}
	roiManager("Select", max_area_idx);
	for(idx=0; idx<nResults; idx++){
		if(idx != max_area_idx){
			roiManager("Select", idx);
			run("Subtract...", "value=255");
		}
	}
	roiManager("Delete");
	run("Remove Overlay");

run("Colors...", "foreground=black background=black selection=yellow");


//exit("Finished!!!d(^o^)b");



