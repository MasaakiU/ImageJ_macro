print("START");
run("Set Measurements...", "area mean min integrated redirect=None decimal=3");
run("Options...", "iterations=1 count=1 black do=Nothing");
roiManager("Show All with labels");
run("Colors...", "foreground=white background=black selection=yellow");
ThresholdMetric = newArray("Default", "Huang", "Intermodes", "IsoData", "Li", "MaxEntropy", "Mean", "MinError", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Triangle", "Yen");


// variables variables variables variables variables
// variables variables variables variables variables
// variables variables variables variables variables

classification_names = newArray("65535.tif", "_mask.tif", "_nuc.tif");
// convoluted background subtruction
CBS_size = 3
threshold_value = 30
// functions functions functions functions functions
// functions functions functions functions functions
// functions functions functions functions functions

function classify_files(file_names, suffixes){
	classification_array = newArray();
	for(i=0; i<file_names.length; i++){
		file_name = file_names[i];
		pre_length = classification_array.length;
		for(j=0; j<suffixes.length; j++){
			if(endsWith(file_name, suffixes[j])){
				classification_array = Array.concat(classification_array, suffixes[j]);
			}
		}
		post_length = classification_array.length;
		if(pre_length == post_length){
			classification_array = Array.concat(classification_array, "");
		}
	}
	return classification_array;
}


function make_new_folder(Dir, suffix){
	Dir_name = File.getName(Dir);
	New_dir_name = Dir_name + "_" + suffix;
	copyNum = 1;
	while(File.exists(Dir + New_dir_name + "-" + copyNum + "/")){
	    copyNum = copyNum + 1;
	}
	New_dir_name = New_dir_name + "-" + copyNum + "/";
	New_dir = Dir + New_dir_name;
	File.makeDirectory(New_dir);
	return New_dir_name;
}

function printArray(array){
	for(j=0; j<array.length; j++){
		print(array[j]);
	}
}



// special_funcs special_funcs special_funcs special_funcs special_funcs
// special_funcs special_funcs special_funcs special_funcs special_funcs
// special_funcs special_funcs special_funcs special_funcs special_funcs

function LD2950mask(file_path, New_dir_path, CBS_size, threshold_value){
	open(file_path);
	file_name = File.getName(file_path);
	file_name_woExt = File.nameWithoutExtension();
	resetMinAndMax();
	run("8-bit");
	run("Convoluted Background Subtraction", "convolution=Median radius=" + CBS_size);
	//setAutoThreshold("Default");
	setThreshold(0, threshold_value);
	run("Convert to Mask");
	run("Invert");
	saveAs("Tiff", New_dir_path + file_name_woExt + "_LD2950mask.tif");
	//close();
}


// main main main main main
// main main main main main
// main main main main main

//setBatchMode(true);

Dir = getDirectory("Select an Input Folder containing Folders you are interested in");
Dir_name = File.getName(Dir);
print("Master Directory: " + Dir);			//Master Dir
file_names = getFileList(Dir);

//Making new folder
New_dir_name = make_new_folder(Dir, "LD2950mask");
New_dir_path = Dir + New_dir_name;
// select target files
classification_array = classify_files(file_names, classification_names);

//process
for(i=0; i<file_names.length; i++){
	if(classification_array[i] == "65535.tif"){
		file_path = Dir + file_names[i];
		LD2950mask(file_path, New_dir_path, CBS_size, threshold_value);
	}
}

exit("Finished!!!d(^o^)b");


















