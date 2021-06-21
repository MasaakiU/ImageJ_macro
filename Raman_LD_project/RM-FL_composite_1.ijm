print("START");
run("Set Measurements...", "area mean min integrated redirect=None decimal=3");
run("Options...", "iterations=1 count=1 black do=Nothing");

setBatchMode(true);

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
//
function get_dirname(path){
	name_list = split(path, "/");
	return name_list[name_list.length - 1];
}
//
function get_basename(path){
	path_name = "/";
	name_list = split(path, "/");
	for(i=0; i<name_list.length-2; i++){
		path_name += name_list[i] + "/";
	}
	return path_name;
}
//
function is_containing_RM_FL(dir_path){
	dir_name = get_dirname(dir_path);
	is_contain_RM = false;
	is_contain_FL = false;
	child_name_list = getFileList(dir_path);
	for(i=0; i<child_name_list.length; i++){
		child_name = child_name_list[i];
		tmp_name = dir_name + "_RM/";
		if (child_name == tmp_name){
			is_contain_RM = true;
		}
		tmp_name_1 = dir_name + "_FL/";
		tmp_name_2 = dir_name + "_FL_2/";
		if ((child_name == tmp_name_1) || (child_name == tmp_name_2)){
			is_contain_FL = true;
		}
	}
	return is_contain_RM && is_contain_FL;
}
//
function split_ext(file_name, return_val){
	tmp_list = split(file_name, ".");
	if(return_val == "ext"){
		return tmp_list[1];
	}else{
		return tmp_list[0];
	}
}
//
function get_common_name(name1, name2){
	name1 = split(name1, "_");
	name2 = split(name2, "_");
	len1 = name1.length;
	len2 = name2.length;
	common_len = minOf(len1, len2);
	common_name = "";
	for (i=0; i<common_len; i++) {
		if (name1[i] == name2[i]){
			common_name += name1[i] + "_";
		}
	}
	return common_name;
}
//
function RG_composite(R_path, G_path, new_path){
	open(R_path);
	R_ID = getImageID();
	R_name = getInfo("image.filename");
	open(G_path);
	G_ID = getImageID();
	G_name = getInfo("image.filename");
	run("Merge Channels...", "c1=" + R_name + " c2=" + G_name + " create");
	common_name = get_common_name(R_name, G_name);
	R_name_wo_ext = split_ext(R_name, "name");
	G_name_wo_ext = split_ext(G_name, "name");
	save_name = R_name_wo_ext + "_" + G_name_wo_ext + ".tif";
	save_path = new_path + save_name;
	rename(save_name);
	saveAs("Tiff", save_path);
	close();
}
//
function RM_FL_merge(dir_path){
	dir_name = get_dirname(dir_path);
	RM_folder_path = dir_path + dir_name + "_RM/";
	FL_folder_path = dir_path + dir_name + "_FL_2/";
	if (File.exists(FL_folder_path)) {
		FL_folder_path = FL_folder_path;
	}else{
		FL_folder_path = dir_path + dir_name + "_FL/";
	}
	// if FL folder contains more than 1 tiff file, error;
	FL_files = getFileList(FL_folder_path);
	N_tiff = 0;
	for (i=0; i<FL_files.length; i++) {
		if (endsWith(FL_files[i], ".tif") ) {
			pre_FL_path = FL_folder_path + FL_files[i];
			open(pre_FL_path);
			if (bitDepth() == 16){
				N_tiff += 1;
				FL_path = pre_FL_path;
			}
			close();
		}
	}
	if (N_tiff != 1) {
		exit("Exactly 1 tiff file should be in \n" + FL_folder_path);
	}
	// get RM images
	RM_files = getFileList(RM_folder_path);
	RM_path_list = newArray();
	for (i=0; i<RM_files.length; i++) {
		if (endsWith(RM_files[i], ".tif") ) {
			RM_path = RM_folder_path + RM_files[i];
			open(RM_path);
			if (bitDepth() == 16){
				RM_path_list = Array.concat(RM_path_list, RM_path);
			}
			close();
		}
	}
	// create composite images
	for (i=0; i<RM_path_list.length; i++) {
		RM_path = RM_path_list[i];
		RG_composite(RM_path, FL_path, dir_path);
	}
}

dir_path = getDirectory("select folder");
results_list = get_folders_recursively(dir_path);
for (i=0; i<results_list.length; i++){
	dir_path = results_list[i];
	is_contain = is_containing_RM_FL(dir_path);
	if(is_contain){
		print(dir_path);
		RM_FL_merge(dir_path);
	}
	run("Collect Garbage");
}


exit("Finished!!!d(^o^)b");










