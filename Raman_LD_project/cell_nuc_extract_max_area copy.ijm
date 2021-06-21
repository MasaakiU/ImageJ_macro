print("START");
run("Set Measurements...", "area mean min integrated redirect=None decimal=3");
run("Options...", "iterations=1 count=1 black do=Nothing");
roiManager("Show All with labels");
run("Colors...", "foreground=white background=black selection=yellow");

target_effix = "_signal_to_baseline_1560-1590_0-65535_nuc.tif";

function get_files_recursively(dir_path){
	results_list = newArray();
	child_file_list = getFileList(dir_path);
	for(i=0; i<child_file_list.length; i++){
		file_name = child_file_list[i];
		if(endsWith(file_name, ".tif")){
			results_list = Array.concat(results_list, dir_path + file_name);
		}
		if(endsWith(file_name, "/")){
			new_results_list = get_files_recursively(dir_path + file_name);
			results_list = Array.concat(results_list, new_results_list);
		}
	}
	return results_list;
}

function extract_max_area(file_path){
	open(file_path);
	file_name_wo_ext = File.nameWithoutExtension;
	dir_path = File.directory;
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
	saveAs("Tiff", dir_path + file_name_wo_ext + ".tif");
	close();
}


dir_path = getDirectory("select folder");
results_list = get_files_recursively(dir_path);

for(i=0; i<results_list.length; i++){
	file_path = results_list[i];
	if(endsWith(file_path, target_effix)){
		print(file_path);
		extract_max_area(file_path);
	}
}


exit("Finished!!!d(^o^)b");



