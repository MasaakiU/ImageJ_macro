print("START");
run("Set Measurements...", "area mean min integrated redirect=None decimal=3");
run("Options...", "iterations=1 count=1 black do=Nothing");
roiManager("Show All with labels");
run("Colors...", "foreground=white background=black selection=yellow");


minimum_intensity_to_use = 10;  //25
median_filter_size = 3;
ld_margin = 2;

/////////////////////////

//d_FA_list = newArray("pseudo", "≡OA", "d14aLA", "d8AA", "d5EPA");
d_FA_list = newArray("pseudo", "d2PA", "d14aLA", "d8AA", "d5DHA");
//d_FA_list = newArray("pseudo", "d14PtA", "d4LA", "d5aLA", "");
//d_FA_list = newArray("pseudo", "d14aLA", "d8AA", "d6EPA", "");
//d_FA_list = newArray("pseudo", "d2PA", "d4LA", "", "");
//d_FA_list = newArray("pseudo", "d2PA", "d5DHA", "", "");
//d_FA_list = newArray("pseudo", "d2PA", "d8AA", "", "");
//d_FA_list = newArray("pseudo", "d2PA", "d14aLA", "", "");
//d_FA_list = newArray("pseudo", "d2PA", "d17OA", "", "");
//d_FA_list = newArray("pseudo", "d17OA", "d4LA", "", "");
//d_FA_list = newArray("pseudo", "d17OA", "d5DHA", "", "");
//d_FA_list = newArray("pseudo", "d17OA", "d8AA", "", "");
//d_FA_list = newArray("pseudo", "d17OA", "d14aLA", "", "");
//d_FA_list = newArray("pseudo", "d4LA", "d5DHA", "", "");
//d_FA_list = newArray("pseudo", "d4LA", "d11AA", "", "");
//d_FA_list = newArray("pseudo", "d4LA", "d14aLA", "", "");
//d_FA_list = newArray("pseudo", "d14aLA", "d5DHA", "", "");
//d_FA_list = newArray("pseudo", "d14aLA", "d8AA", "", "");
//d_FA_list = newArray("pseudo", "d8AA", "d5DHA", "", "");
//d_FA_list = newArray("pseudo", "d11LA", "d8AA", "", "");

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

// make_mask -> create "Cell_mask_woExt + _common2.tif", "Cell_mask_woExt + _sumLD.tif" images
function MakeMask(Dir, New_dir, Cell_mask, target_file_names, target_file_nicknames, min_int_threshold){
	// cell_mask
	open(Dir + Cell_mask);
	Cell_mask_woExt = File.nameWithoutExtension();
	getDimensions(width, height, channels, slices, frames);
	run("Duplicate...", "title=" + Cell_mask_woExt + "_common.tif");	
	// concatenate arg
	concatenate_arg = "";
	// for LD area, sum up all images
	newImage(Cell_mask_woExt + "_sumLD.tif", "16-bit blak", width, height, 1);
	// make_mask
	for(i=0; i<target_file_names.length; i++){
		file_name = target_file_names[i];
		open(Dir + file_name);
		// for LD area
		imageCalculator("Add", Cell_mask_woExt + "_sumLD.tif", file_name);
		selectWindow(file_name);
		run("Subtract...", "value=" + min_int_threshold);
		setMinAndMax(0, 1);
		run("8-bit");
		run("Multiply...", "value=255");
		// calculate common part
		imageCalculator("Multiply", Cell_mask_woExt + "_common.tif", file_name);
		// concatenate args
		concatenate_arg += " image" + i+3 + "=" + file_name;
	}
	selectWindow(Cell_mask_woExt + "_common.tif");
	run("Duplicate...", "title=" + Cell_mask_woExt + "_common2.tif");	
	// create a stack image of masks
	concatenate_arg = "title=" + Cell_mask_woExt + "_masks.tif" + "open image1=" + Cell_mask_woExt + "_common.tif image2=" + Cell_mask + concatenate_arg;
	print(concatenate_arg);
	run("Concatenate...", concatenate_arg);

	for(i=0; i<target_file_nicknames.length+2; i++){
		setSlice(i+1);
		if(i==0){
			run("Set Label...", "label=reliable_mask");
		}
		if(i==1){
			run("Set Label...", "label=cell_mask");
		}
		if(i>1){
			run("Set Label...", "label=" + target_file_nicknames[i-2]);
		}
	}
	saveAs("Tiff", New_dir + Cell_mask_woExt + "_masks.tif");
	close();
	return Cell_mask_woExt;
}

// define LD area
function DefineLD_Area(New_dir, Cell_mask_woExt, Med_filter_size, Threshold_metric, LD_margin){
	selectWindow(Cell_mask_woExt + "_sumLD.tif");
	// extract LD_area
	run("Duplicate...", "title=" + Cell_mask_woExt + "_medianBG.tif");	
	run("Median...", "radius=" + Med_filter_size);
	imageCalculator("Subtract", Cell_mask_woExt + "_sumLD.tif", Cell_mask_woExt + "_medianBG.tif");
	selectWindow(Cell_mask_woExt + "_medianBG.tif");
	close();
	selectWindow(Cell_mask_woExt + "_sumLD.tif");
	saveAs("Tiff", New_dir + Cell_mask_woExt + "_sumLD.tif");
	setAutoThreshold(Threshold_metric);
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Invert");
	// mask with mask_common2
	imageCalculator("Multiply", Cell_mask_woExt + "_sumLD.tif", Cell_mask_woExt + "_common2.tif");
	rename(Cell_mask_woExt + "_LDarea.tif");
	saveAs("Tiff", New_dir + Cell_mask_woExt + "_LDarea.tif");
	// CytoArea
	selectWindow(Cell_mask_woExt + "_LDarea.tif");
	run("Duplicate...", "title=" + Cell_mask_woExt + "_enlargedLD.tif");	
	run("Maximum...", "radius=" + LD_margin);
	run("Invert");
	imageCalculator("Multiply", Cell_mask_woExt + "_enlargedLD.tif", Cell_mask_woExt + "_common2.tif");
	rename(Cell_mask_woExt + "_CytoArea.tif");
	saveAs("Tiff", New_dir + Cell_mask_woExt + "_CytoArea.tif");
	// convert to 0or1 image, 32-bit
	selectWindow(Cell_mask_woExt + "_CytoArea.tif");
	run("Divide...", "value=255");
	run("32-bit");
	selectWindow(Cell_mask_woExt + "_LDarea.tif");
	run("Divide...", "value=255");
	run("32-bit");
	selectWindow(Cell_mask_woExt + "_common2.tif");
	run("Divide...", "value=255");
	run("32-bit");
}

//
function CalculateRatio(Dir, New_dir, target_file_names, target_file_nicknames, Cell_mask_woExt){
	// results
	LD_results = "bunshi\\bunbo";
	Cyto_results = "bunshi\\bunbo";
	// LD pix area
	selectWindow(Cell_mask_woExt + "_LDarea.tif");
	run("Select All");
	run("Measure");
	LD_pix_area = getResult("RawIntDen", nResults - 1);
	// Cyto pix area
	selectWindow(Cell_mask_woExt + "_CytoArea.tif");
	run("Select All");
	run("Measure");
	Cyto_pix_area = getResult("RawIntDen", nResults - 1);
	// reliable_area
	selectWindow(Cell_mask_woExt + "_common2.tif");
	run("Select All");
	run("Measure");
	Reliable_pix_area = getResult("RawIntDen", nResults - 1);
	// reliable_area
	open(Dir + Cell_mask_woExt + ".tif");
	run("Select All");
	run("Divide...", "value=255");
	run("Measure");
	Cell_pix_area = getResult("RawIntDen", nResults - 1);
	close();
	// open files
	for(i=0; i<target_file_names.length; i++){
		open(Dir + target_file_names[i]);
		LD_results += "\t" + target_file_nicknames[i];
		Cyto_results += "\t" + target_file_nicknames[i];
	}
	Each_results = "Name\tLD\tCyto";
	// make image combination
	for(i=0; i<target_file_names.length; i++){
		// bunshi
		i_file_name = target_file_names[i];
		i_nickname = target_file_nicknames[i];
		// LD, Cyto Results
		LD_results += "\n" + i_nickname;
		Cyto_results += "\n" + i_nickname;
		for(j=0; j<target_file_names.length; j++){
			// bunbo
			j_file_name = target_file_names[j];
			j_nickname = target_file_nicknames[j];
			// divide image_i by image_j
			imageCalculator("Divide create 32-bit", i_file_name, j_file_name);
			rename(i_nickname + "_by_" + j_nickname + ".tif");
			// LD
			imageCalculator("Multiply create", i_nickname + "_by_" + j_nickname + ".tif", Cell_mask_woExt + "_LDarea.tif");
			rename(i_nickname + "_by_" + j_nickname + "_LD.tif");
			run("Measure");
			close();
			LD_ratio_ave = getResult("RawIntDen", nResults - 1) / LD_pix_area;
			// Cyto
			imageCalculator("Multiply create", i_nickname + "_by_" + j_nickname + ".tif", Cell_mask_woExt + "_CytoArea.tif");
			rename(i_nickname + "_by_" + j_nickname + "_Cyto.tif");
			run("Measure");
			close();
			Cyto_ratio_ave = getResult("RawIntDen", nResults - 1) / Cyto_pix_area;
			// Results
			LD_results += "\t" + LD_ratio_ave;
			Cyto_results += "\t" + Cyto_ratio_ave;
			// save ratio images
			selectWindow(i_nickname + "_by_" + j_nickname + ".tif");
			setMinAndMax(0, 5);
			run("Fire");
			saveAs("Tiff", New_dir + "nonMasked_" + i_nickname + "_by_" + j_nickname + ".tif");
			imageCalculator("Multiply", "nonMasked_" + i_nickname + "_by_" + j_nickname + ".tif", Cell_mask_woExt + "_common2.tif");
			rename("masked_" + i_nickname + "_by_" + j_nickname + ".tif");
			setMinAndMax(0, 5);
			run("Fire");
			saveAs("Tiff", New_dir + "masked_" + i_nickname + "_by_" + j_nickname + ".tif");
			close();
		}
		// Each_ results
		imageCalculator("Multiply create", i_file_name, Cell_mask_woExt + "_LDarea.tif");
		rename(i_file_name + "_LD.tif");
		run("Measure");
		close();
		LD_int_ave = getResult("RawIntDen", nResults - 1) / LD_pix_area;
		imageCalculator("Multiply create", i_file_name, Cell_mask_woExt + "_CytoArea.tif");
		run("Measure");
		close();
		Cyto_int_ave = getResult("RawIntDen", nResults - 1) / Cyto_pix_area;
		Each_results += "\n" + i_nickname + "\t" + LD_int_ave + "\t" + Cyto_int_ave;
	}
	// close files
	for(i=0; i<target_file_names.length; i++){
		close(target_file_names[i]);
	}
	selectWindow(Cell_mask_woExt + "_common2.tif");
	close();
	selectWindow(Cell_mask_woExt + "_LDarea.tif");
	close();
	selectWindow(Cell_mask_woExt + "_CytoArea.tif");
	close();
	// results
	results = "PIXEL AREAS";
	results += "\n" + "CELL\t" + Cell_pix_area;
	results += "\n" + "RELIABLE AREA\t" + Reliable_pix_area;
	results += "\n" + "LD\t" + LD_pix_area;
	results += "\n" + "CYTO\t" + Cyto_pix_area;
	results += "\n\nMEAN LD RATIO\n" + LD_results + "\n\nMEAN CYTO RATIO\n" + Cyto_results + "\n\nEACH FA AVE. INTENSITY\n" + Each_results;
	return results;
}

/////////////////////////
/////////////////////////
/////////////////////////


ori_Dir = getDirectory("Select an Input Folder containing Folders you are interested in");
Dir_list = get_folders_recursively(ori_Dir);
for(dir_idx=0; dir_idx<Dir_list.length; dir_idx++){
	Dir = Dir_list[dir_idx];

//######


Dir_name = File.getName(Dir);
print("Master Directory: " + Dir);			//Master Dir

file_names = getFileList(Dir);
tif_file_names = newArray();
for(i=0; i<file_names.length; i++){
	file_name = file_names[i];
	if(endsWith(file_name, ".tif")){
		tif_file_names = Array.concat(tif_file_names, file_name);
	}
}
ThresholdMetric = newArray("Default", "Huang", "Intermodes", "IsoData", "Li", "MaxEntropy", "Mean", "MinError", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Triangle", "Yen");

// Dialog
file_idx = 1;
target_file_names = newArray();
target_file_nicknames = newArray();

// files to use
for(i=0; i<tif_file_names.length; i++){
// 名前を予め記入
	isCategolized = false;
	if(endsWith(tif_file_names[i], "_cyto.tif")){
		mask_candidate = tif_file_names[i];
		isCategolized = true;
	}
	if(endsWith(tif_file_names[i], "_unmixed_1900-2400_1_0-65535.tif")){
		target_file_names = Array.concat(target_file_names, tif_file_names[i]);
		target_file_nicknames = Array.concat(target_file_nicknames, d_FA_list[1]);
		isCategolized = true;
	}
	if(endsWith(tif_file_names[i], "_unmixed_1900-2400_2_0-65535.tif")){
		target_file_names = Array.concat(target_file_names, tif_file_names[i]);
		target_file_nicknames = Array.concat(target_file_nicknames, d_FA_list[2]);
		isCategolized = true;
	}
	if(endsWith(tif_file_names[i], "_unmixed_1900-2400_3_0-65535.tif")){
		target_file_names = Array.concat(target_file_names, tif_file_names[i]);
		target_file_nicknames = Array.concat(target_file_nicknames, d_FA_list[3]);
		isCategolized = true;
	}
	if(endsWith(tif_file_names[i], "_unmixed_1900-2400_4_0-65535.tif")){
		target_file_names = Array.concat(target_file_names, tif_file_names[i]);
		target_file_nicknames = Array.concat(target_file_nicknames, d_FA_list[4]);
		isCategolized = true;
		}
	if(endsWith(tif_file_names[i], "_unmixed_450-680_1_0-65535.tif")){
		target_file_names = Array.concat(target_file_names, tif_file_names[i]);
		target_file_nicknames = Array.concat(target_file_nicknames, d_FA_list[1]);
		isCategolized = true;
	}
	// どこにも所属しなかった場合
	if(!isCategolized){
		file_idx += 1;
	}
}


if(target_file_names.length == 0){
	skip = 1;
}else{
	skip = 0;
	target_file_names = Array.trim(target_file_names, d_FA_list.length);
	target_file_nicknames = Array.trim(target_file_nicknames, d_FA_list.length);
}


SKIP = skip;
BATCH = 1;
setBatchMode(BATCH);


if(SKIP){
	print("Skipped");
}else{

	Cell_mask = mask_candidate;
	min_int_threshold = minimum_intensity_to_use;
	Med_filter_size = median_filter_size;
	Threshold_metric = ThresholdMetric[0];
	LD_margin = ld_margin;

	//////////////////////////////////////////////////////////////////////////////////////////////

	//Making new folder
	New_dir_name = Dir_name + "_ratio";
	copyNum = 1;
	while(File.exists(Dir + New_dir_name + "-" + copyNum + "/")){
	    copyNum = copyNum + 1;
	}
	New_dir_name = New_dir_name + "-" + copyNum + "/";
	New_dir = Dir + New_dir_name;
	File.makeDirectory(New_dir);
	
	// processes: create "_common2.tif", "_sumLD.tif" images
	Cell_mask_woExt = MakeMask(Dir, New_dir, Cell_mask, target_file_names, target_file_nicknames, min_int_threshold);
	// make LD_area: "_common2.tif", "_sumLD.tif" images -> "_LDarea.tif", "_CytoArea.tif" (32-but with 0 or 1 values)
	DefineLD_Area(New_dir, Cell_mask_woExt, Med_filter_size, Threshold_metric, LD_margin);
	// calculate ratio
	results = CalculateRatio(Dir, New_dir, target_file_names, target_file_nicknames, Cell_mask_woExt);
	
	// Summary Results
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	summary = "SETTINGS" + "\t" + year + "/" + month + "/" + dayOfMonth + " " + hour + ":" + minute;
	summary += "\n" + "Mask File\t" + Cell_mask;
	summary += "\n" + "Minimum Intensity Used\t" + min_int_threshold;
	summary += "\n" + "Median Filter Size\t" + Med_filter_size;
	summary += "\n" + "LD Margin\t" + LD_margin;
	summary += "\n" + "Threshold Metric\t" + Threshold_metric;
	summary += "\n\n" + "NAME CORRESPONDENCE";
	
	for(i=0; i<target_file_names.length; i++){
		summary += "\n" + target_file_nicknames[i] + "\t" + target_file_names[i];
	}
	summary += "\n\n" + results;
	
	selectWindow("Log");
	run("Close");
	print(summary);
	selectWindow("Log");
	saveAs("Text", New_dir + Cell_mask_woExt + "_results.txt");
	run("Collect Garbage");

}
}

//######




exit("Finished!!!d(^o^)b");


















