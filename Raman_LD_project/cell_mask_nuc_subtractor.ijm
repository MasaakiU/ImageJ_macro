print("START");
run("Set Measurements...", "area mean min integrated redirect=None decimal=3");
run("Options...", "iterations=1 count=1 black do=Nothing");
roiManager("Show All with labels");
run("Colors...", "foreground=white background=black selection=yellow");

function get_folders_recursively(dir_path){
	results_list = newArray();
	results_list = Array.concat(results_list, dir_path);
	child_file_list = getFileList(dir_path);
	for(i=0; i<child_file_list.length; i++){
		file_name = child_file_list[i];
		if(endsWith(file_name, "/")){
			new_results_list = get_folders_recursively(dir_path + file_name);
			results_list = Array.concat(results_list, new_results_list);
		}
	}
	return results_list;
}

function subtract_mask_nuc(mask_path, nuc_path){
	open(nuc_path);
	nuc_id = getImageID();
	nuc_name_wo_ext = File.nameWithoutExtension;
	if(is("binary") != true){
		run("8-bit");
		run("Invert");
		run("Subtract...", "value=100");
		run("Multiply...", "value=255.000");	
	}
	open(mask_path);
	mask_id = getImageID();
	mask_name_wo_ext = File.nameWithoutExtension;
	name_splitted = split(mask_name_wo_ext, "_");
	print(name_splitted.length);
	name_wo_ext = "";
	for(i=0; i<name_splitted.length-1; i++){
		name_wo_ext = name_wo_ext + name_splitted[i] + "_";
	}

	dir_path = File.directory;
	imageCalculator("Subtract create", mask_id, nuc_id);
	saveAs("Tiff", dir_path + name_wo_ext + "cyto.tif");
	
	close();
	selectWindow(mask_name_wo_ext + ".tif");
	close();
	selectWindow(nuc_name_wo_ext + ".tif");
	close();
}

function isInFolder_effix(folder_path, effix){
	result_name = "";
	child_file_list = getFileList(folder_path);
	for(i=0; i<child_file_list.length; i++){
		child_file_name = child_file_list[i];
		if(endsWith(child_file_name, effix)){
			result_name = child_file_name;
		}
	}
	return result_name;
}

dir_path = getDirectory("select folder");
results_list = get_folders_recursively(dir_path);

for(i=0; i<results_list.length; i++){
	folder_path = results_list[i];
	mask_name = isInFolder_effix(folder_path, "_mask.tif");
	nuc_name = isInFolder_effix(folder_path, "_nuc.tif");
	print(mask_name);
	if((mask_name != "")&&(nuc_name != "")){
		subtract_mask_nuc(folder_path + mask_name, folder_path + nuc_name);
	}
}


exit("Finished!!!d(^o^)b");



