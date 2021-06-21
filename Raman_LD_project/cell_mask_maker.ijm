rolling_ball_radius = 100
threshold = 5


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

function make_cell_mask(file_path){
	open(file_path);
	file_name_wo_ext = File.nameWithoutExtension;
	dir_path = File.directory;
	run("Median...", "radius=3");
	run("Subtract Background...", "rolling=" + rolling_ball_radius + " sliding disable");
	//exit("stoped");
	run("Subtract...", "value=" + threshold);
	setMinAndMax(0, 1);
	run("8-bit");
	run("Multiply...", "value=255");
	saveAs("Tiff", dir_path + file_name_wo_ext + "_mask.tif");
	close();
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
	run("Select None");
	saveAs("Tiff", dir_path + file_name_wo_ext + ".tif");
	close();
}



dir_path = getDirectory("select folder");
results_list = get_files_recursively(dir_path);

for(i=0; i<results_list.length; i++){
	file_path = results_list[i];
	if(endsWith(file_path, "_signal_intensity_2950_0-65535.tif")){
	//if(endsWith(file_path, "_signal_to_h_baseline_990-1010_0-65535.tif")){
		print(file_path);
		make_cell_mask(file_path);
		file_path = split(file_path, ".");
		//file_path = file_path[0] + "_mask.tif";
		//extract_max_area(file_path);
	}
}

exit("Finished!!!d(^o^)b");





