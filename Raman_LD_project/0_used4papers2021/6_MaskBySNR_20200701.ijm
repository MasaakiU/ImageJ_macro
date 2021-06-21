print("START");
run("Set Measurements...", "area mean min integrated redirect=None decimal=3");
run("Options...", "iterations=1 count=1 black do=Nothing");
roiManager("Show All with labels");
run("Colors...", "foreground=white background=black selection=yellow");

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
function search_target_files_from_substring(tif_file_names, target_file_substrings){
	target_file_names = newArray();
	// is_all_found_str = true;
	for (i=0; i<target_file_substrings.length; i++) {
		target_file_substring = target_file_substrings[i];
		for(j=0; j<tif_file_names.length; j++){
			substring_idx = indexOf(tif_file_names[j], target_file_substring);
			if (substring_idx != -1){
				substring_idx = i;
				break
			}
		}
		if (substring_idx == -1){
			target_file_names = Array.concat(target_file_names, "");
			// is_all_found = false;
		}else{
			target_file_names = Array.concat(target_file_names, tif_file_names[j]);
		}
	}
	return target_file_names;
}
//
function make_new_folder(Dir, Dir_name, suffix) { 
	New_dir_name = Dir_name + suffix;
	copyNum = 1;
	while(File.exists(Dir + New_dir_name + "_" + copyNum + "/")){
	    copyNum = copyNum + 1;
	}
	New_dir_name = New_dir_name + "_" + copyNum + "/";
	New_dir_path = Dir + New_dir_name;
	File.makeDirectory(New_dir_path);
	return New_dir_path;
}
//
function open_files(Dir, file_name_list) { 
	id_list = newArray();
	for (i=0; i<file_name_list.length; i++) {
		file_name = file_name_list[i];
		open(Dir + file_name);
		id = getImageID();
		id_list = Array.concat(id_list, id);
	}
	return id_list;
}
//
function save_files(Dir, window_id_list, file_names) { 
	save_path_list = newArray();
	for (i=0; i<window_id_list.length; i++){
		window_id = window_id_list[i];
		selectImage(window_id);
		if(file_names.length != 0){
			window_title = file_names[i];
		}else{
			window_title = getTitle();
		}
		save_path = Dir + window_title;
		save_path_list = Array.concat(save_path_list, save_path);
		saveAs("Tiff", save_path);
	}
	return save_path_list;
}
//
function make_montage(path_list, row, col) { 
	N_images = path_list.length;
	// pre search
	id_list = newArray();
	max_w = 0;
	max_h = 0;
	for (i = 0; i < N_images; i++) {
		path = path_list[i];
		open(path);
		id = getImageID();
		id_list = Array.concat(id_list, id);
		getDimensions(w, h, c, s, f);
		if (max_w < w){
			max_w = w;
		}
		if (max_h < h){
			max_h = h;
		}
	}
	max_w += 1;
	max_h += 1;	
	getMinAndMax(min_int, max_int);
	getLut(reds, greens, blues);
	// make montage
	newImage("montage", "32-bit black", max_w*col, max_h*row, 1);
	run("Select All");
	run("Add...", "value=65535");	// should be enough
	montage_id = getImageID();
	for (i = 0; i < N_images; i++) {
		cur_col = i % col;
		cur_row = (i - cur_col)/col;
		selectImage(id_list[i]);
		getDimensions(w, h, c, s, f);
		run("Select All");
		run("Copy");
		selectImage(montage_id);
		makeRectangle(max_w*cur_col, max_h*cur_row, w, h);
		run("Paste");
		selectImage(id_list[i]);
		close();
	}
	// display settings
	setMinAndMax(min_int, max_int);
	setLut(reds, greens, blues);
	return montage_id;
}

// ######
// ndarray functions // A[0]=dim, A[1,2]=x,y (if dim==2), A[3:]=data
// ######
function AA_empty(shape){ 
	ndim = shape.length;
	whole_size = 1;
	for (i=0; i<shape.length; i++) {
		whole_size *= shape[i];
	}
	A_data = newArray(whole_size);
	A = Array.concat(ndim, shape);
	A = Array.concat(A, A_data);
	return A;
}
function AA_arange(shape){ 
	ndim = shape.length;
	whole_size = 1;
	for (i=0; i<shape.length; i++) {
		whole_size *= shape[i];
	}
	A_data = newArray();
	for (i = 0; i < whole_size; i++) {
		A_data = Array.concat(A_data, i);
	}
	A = Array.concat(ndim, shape);
	A = Array.concat(A, A_data);
	return A;
}
function AA_asarray(shape, A_data){ 
	ndim = shape.length;
	whole_size = 1;
	for (i=0; i<shape.length; i++) {
		whole_size *= shape[i];
	}
	if (whole_size != A_data.length){
		exit("size unmatch");
	}
	A = Array.concat(ndim, shape);
	A = Array.concat(A, A_data);
	return A;
}
function AA_ndim(A){ 
	return A[0];
}
function AA_shape(A){ 
	ndim = A[0];
	shape = newArray();
	for (i=0; i<ndim; i++) {
		shape = Array.concat(shape, A[1 + i]);
	}
	return shape;
}
function AA_2list(A){ 
	return Array.slice(A,2);
}
function AA_unraval_index(A, indices){ 
	ndim = A[0];
	shape = AA_shape(A);
	unraveled_coords = newArray();
	for (i = 0; i < ndim; i++) {
		remainder = indices % shape[ndim-i-1];
		indices = (indices - remainder) / shape[ndim-i-1];
		unraveled_coords = Array.concat(unraveled_coords, remainder);
	}
	unraveled_coords = Array.reverse(unraveled_coords);
	return unraveled_coords;
}
function AA_raval_index(A, loc){ 
	ndim = A[0];
	shape = AA_shape(A);
	if (ndim != loc.length){
		exit("dimension unmatch: " + toString(ndim) + " & "+ toString(loc.length));
	}
	indices = 0;
	for (i = 0; i < loc.length; i++) {
		step_size = 1;
		for (j = 0; j < shape.length-1-i; j++) {
			step_size *= shape[ndim-1-j];
		}
		indices += loc[i] * step_size;			
	}
	return indices;
}
function AA_loc(A, loc) { 	// accepts slice index: A[1, 2:] equals to A[1, 2.5]	
	ndim = A[0];
	shape = AA_shape(A);
	A_data = Array.slice(A, ndim+1);
	indlude_slice = false;
	for (i = 0; i < ndim; i++) {
		if (floor(loc[i]) != loc[i]){
			indlude_slice += true;
		}
	}
	// just loc -> return float or int
	if (indlude_slice == false){
		indices = AA_raval_index(A, loc);
		return A_data[indices];
	}
	// include slice -> return ndarray
	new_s_idxes = newArray();
	new_e_idxes = newArray();
	new_shape = newArray();
	new_dim = 0;
	whole_size = 1;
	for (i = 0; i < ndim; i++) {
		// not slice
		if (loc[i] == floor(loc[i])){
			new_s_idxes = Array.concat(new_s_idxes, loc[i]);
			new_e_idxes = Array.concat(new_e_idxes, loc[i] + 1);
		}else{	// slices
			new_s_idxes = Array.concat(new_s_idxes, floor(loc[i]));
			new_e_idxes = Array.concat(new_e_idxes, shape[i]);
			new_shape = Array.concat(new_shape, new_e_idxes[i] - new_s_idxes[i]);
			new_dim += 1;
		}
		size = new_e_idxes[i] - new_s_idxes[i];
		whole_size *= size;
	}
	new_A_data = newArray();
	pseudo_new_A = AA_arange(array_calc(new_e_idxes, new_s_idxes, "subtract"));
	for (i = 0; i < whole_size; i++) {
		relative_loc = AA_unraval_index(pseudo_new_A, i);
		cur_loc = array_calc(relative_loc, new_s_idxes, "add");
		value = AA_loc(A, cur_loc);
		new_A_data = Array.concat(new_A_data, value);
	}
	new_A = Array.concat(new_dim, new_shape);
	new_A = Array.concat(new_A, new_A_data);
	return new_A;
}
function array_calc(a1, a2, method) { 
	N = a1.length;
	if (a2.length != N){
		exit("length unmatch");
	}
	a3 = newArray();
	for (i = 0; i < N; i++) {
		if (method == "subtract"){
			a3 = Array.concat(a3, a1[i] - a2[i]);
		}
		if (method == "add"){
			a3 = Array.concat(a3, a1[i] + a2[i]);
		}
	}
	return a3;
}
function AA_print(A) { 
	ndim = A[0];
	shape = AA_shape(A);
	// ndim == 1
	if (ndim == 1) {
		Array.show("0 (row numbers)", Array.slice(A, 2));
		return;
	}
	// ndim == 2
	if (ndim == 2) {
		Table.create("[:,:]");
		Table.showRowIndexes(true);
		for (i = 0; i < shape[0]; i++) {
			for (j = 0; j < shape[1]; j++) {
				loc = newArray(i, j);
				val = AA_loc(A, loc);
				Table.set(j, i, val);
			}
		}
		return;
	}
	// ndim >= 3
	A_data = Array.slice(A, 1+ndim);
	size2dim = 1;
	step2dim = shape[ndim-2] * shape[ndim-1];
	shape2dim_1 = Array.slice(shape, 0, ndim-2);
	shape2dim_2 = Array.slice(shape, ndim-2);
	pseudo_A2dim_1 = AA_arange(shape2dim_1);
	for (i = 0; i < ndim-2; i++) {
		size2dim *= shape[i];
	}
	print(size2dim);
	for (i = 0; i < size2dim; i++) {
		A2dim_data = Array.slice(A_data, step2dim*i, step2dim*(i+1));
		A2dim = Array.concat(2, shape2dim_2);
		A2dim = Array.concat(A2dim, A2dim_data);
		AA_print(A2dim);
		// title
		loc_1 = AA_unraval_index(pseudo_A2dim_1, i);
		print("i");
		Array.print(loc_1);
		txt = "";
		for (j = 0; j < loc_1.length; j++) {
			txt += toString(loc_1[j]) + ",";
		}
		print(txt);
		Table.rename("[:,:]", "[" + txt + ":,:]");
	}
}

//shape = newArray(2, 3, 4, 5);
//A = AA_arange(shape);
//loc = newArray(0.5, 0.5, 0.5, 0.5);
//b = AA_loc(A, loc);
//AA_print(b);
//Array.print(b);


/////////////////////////
/////////////////////////
/////////////////////////
/////////////////////////
/////////////////////////

function main_func(Dir, master_name, rnorm_id, pow1_id, conc_id, SNR_threshold) {
	// set range
	selectImage(conc_id);
	run("Min...", "value=0");
	run("Max...", "value=8");
	// SNR image
	imageCalculator("Divide create 32-bit", pow1_id, rnorm_id);
	SNR_id = getImageID();
	rename(master_name + "_SNR.tiff");
	// mask image
	run("Duplicate...", "title=" + master_name + "_mask.tiff");
	mask_id = getImageID();
	setThreshold(100.0000, 1000000000000000000000000000000.0000);
	run("Convert to Mask");
	run("Duplicate...", " ");
	inverted_mask_id = getImageID();
	run("Invert");	
	run("Divide...", "value=255");
	selectImage(mask_id);
	run("Divide...", "value=255");
	setMinAndMax(0, 1);
	// masked image (return log2 image)
	imageCalculator("Multiply create 32-bit", conc_id, mask_id);
	masked_id = getImageID();
	imageCalculator("Subtract", masked_id, inverted_mask_id);
	rename(master_name + "_MaskedConc.tiff");
	// display settings
	run("glow wo saturation");
	setMinAndMax(-1.00, 8.00);	// for non-log
	return newArray(SNR_id, mask_id, masked_id);
}

/////////////////////////
/////////////////////////
/////////////////////////
/////////////////////////
/////////////////////////


ori_Dir = getDirectory("Select an Input Folder containing Folders you are interested in");
ori_Dir_splitted = split(ori_Dir, "/");
ori_Dir_name = ori_Dir_splitted[ori_Dir_splitted.length - 1];
Dir_list = get_folders_recursively(ori_Dir);
Valid_dir_list = newArray();
save_paths = newArray();
for(dir_idx=0; dir_idx<Dir_list.length; dir_idx++){

//###### BEGIN MAIN FOR LOOP ######

// get tiff files
Dir = Dir_list[dir_idx];
Dir_name = File.getName(Dir);
print("Master Directory: " + Dir);			//Master Dir
file_names = getFileList(Dir);
tif_file_names = newArray();
for(i=0; i<file_names.length; i++){
	file_name = file_names[i];
	if(endsWith(file_name, ".tif") | endsWith(file_name, ".tiff")){
		tif_file_names = Array.concat(tif_file_names, file_name);
	}
}
if (tif_file_names.length == 0){
	continue;
}

// search target files
target_file_substrings = newArray("#rnorm", "#1pow", "#conc");
target_file_names = search_target_files_from_substring(tif_file_names, target_file_substrings);
is_all_found = true;
for (i=0; i<target_file_names.length; i++) {
	if (target_file_names[i] == ""){
		is_all_found = false;
	}
}
if(is_all_found == false){
	continue;
}else{
	Valid_dir_list = Array.concat(Valid_dir_list, Dir);
}

// make new folder
New_dir_path = make_new_folder(Dir, Dir_name, "_SNR");

// open files
id_list = open_files(Dir, target_file_names);
rnorm_id = id_list[0];
pow1_id = id_list[1];
conc_id = id_list[2];

// process
SNR_threshold = 10;
window_id_list = main_func(Dir, Dir_name, rnorm_id, pow1_id, conc_id, SNR_threshold);

// save images
file_names = newArray();
save_path_list = save_files(New_dir_path, window_id_list, file_names);
save_paths = Array.concat(save_paths, save_path_list);
run("Close All");
run("Collect Garbage");

//###### END MAIN FOR LOOP ######
}

// summary
N_dir = Valid_dir_list.length
shape = newArray(N_dir, 3);
saved_paths = AA_asarray(shape, save_paths);
loc = newArray(0.5, 2);
MaskedConc_paths = AA_loc(saved_paths, loc);
MaskedConc_paths = AA_2list(MaskedConc_paths);
col = floor(sqrt(MaskedConc_paths.length));
row = -floor(- MaskedConc_paths.length / col);
montage_id = make_montage(MaskedConc_paths, row, col);
// save summary
id_list = newArray();
id_list =Array.concat(id_list, montage_id);
file_names = newArray(ori_Dir_name+"_Montage.tiff");
save_files(ori_Dir, id_list, file_names);

exit("Finished!!!d(^o^)b");



















