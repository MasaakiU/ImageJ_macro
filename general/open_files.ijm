print("START");
run("Set Measurements...", "area mean min integrated redirect=None decimal=3");
run("Options...", "iterations=1 count=1 black do=Nothing");
roiManager("Show All with labels");
run("Colors...", "foreground=white background=black selection=yellow");



BrFA_list = newArray("pseudo", "BrPA");
//
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

/////////////////////////
/////////////////////////

ori_Dir = getDirectory("Select an Input Folder containing Folders you are interested in");
Dir_list = get_folders_recursively(ori_Dir);
for(dir_idx=0; dir_idx<Dir_list.length; dir_idx++){
	Dir = Dir_list[dir_idx];
	//Dir_name = File.getName(Dir);
	print("Master Directory: " + Dir);			//Master Dir
	file_names = getFileList(Dir);
	for(i=0; i<file_names.length; i++){
		file_name = file_names[i];
		if(endsWith(file_name, "_polyfit2_2095.0-2120.0_0-0.tif")){
			open(Dir + "/" + file_name);
		}
	}

}

exit("Finished!!!d(^o^)b");


















