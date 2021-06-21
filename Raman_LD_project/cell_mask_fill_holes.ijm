print("START");
run("Set Measurements...", "area mean min integrated redirect=None decimal=3");
run("Options...", "iterations=1 count=1 black do=Nothing");
roiManager("Show All with labels");
run("Colors...", "foreground=white background=black selection=yellow");


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

function configure_cell_mask(file_path){
	open(file_path);
	file_name_wo_ext = File.nameWithoutExtension;
	dir_path = File.directory;

	run("Fill Holes");
	
	saveAs("Tiff", dir_path + file_name_wo_ext + ".tif");
	close();
}


dir_path = getDirectory("select folder");
results_list = get_files_recursively(dir_path);

for(i=0; i<results_list.length; i++){
	file_path = results_list[i];
	if(endsWith(file_path, "_signal_intensity_2950_0-65535_mask.tif")){
		print(file_path);
		configure_cell_mask(file_path);
	}
}


exit("Finished!!!d(^o^)b");



