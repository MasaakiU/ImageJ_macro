print("START");
run("Set Measurements...", "area mean min integrated redirect=None decimal=3");
run("Options...", "iterations=1 count=1 black do=Nothing");
roiManager("Show All with labels");
run("Colors...", "foreground=white background=black selection=yellow");

/////////////////////////
//
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
//
function printArray(array){
	for(j=0; j<array.length; j++){
		print(array[j]);
	}
}
//
function saveText(string, save_path){
	selectWindow("Log");
	run("Close");
	print(string);
	selectWindow("Log");
	saveAs("Text", save_path);
}
//
function SubtractMasks(CellMask_path, CellNuc_path, NewDir_path){
	open(CellMask_path);
	CellMask_ID = getImageID();
	open(CellNuc_path);
	CellNuc_ID = getImageID();
	imageCalculator("Subtract create", CellMask_ID, CellNuc_ID);
	file_name_woExt = File.getName(NewDir_path);
	CytopMask_path = NewDir_path + file_name_woExt + "_CellMask.tif";
	saveAs("Tiff", CytopMask_path);
	close();
	selectImage(CellMask_ID);
	close();
	selectImage(CellNuc_ID);
	close();
	return CytopMask_path;
}
//
function MultiplyMasks(LD2950_path, CytopMask_path, NewDir_path){
	open(LD2950_path);
	LD2950_ID = getImageID();
	open(CytopMask_path);
	CytopMask_ID = getImageID();
	imageCalculator("Multiply create", LD2950_ID, CytopMask_ID);
	file_name_woExt = File.getName(NewDir_path);
	CytoLD2950_path = NewDir_path + file_name_woExt + "_CytoLD2950mask.tif";
	saveAs("Tiff", CytoLD2950_path);
	close();
	selectImage(LD2950_ID);
	close();
	selectImage(CytopMask_ID);
	close();
	return CytoLD2950_path;
}
//
function CalcMeanInt(target_file_path, Mask_path){
	// process mask
	open(Mask_path);
	Mask_ID = getImageID();
	run("Divide...", "value=255.000");
	run("Select All");
	run("Measure");
	pixel_area = getResult("RawIntDen", nResults-1);
	// process target
	open(target_file_path);
	target_ID = getImageID();
	imageCalculator("Multiply create", target_ID, Mask_ID);	
	run("Select All");
	run("Measure");
	sum_of_int = getResult("RawIntDen", nResults-1);
	close();
	selectImage(Mask_ID);
	close();
	selectImage(target_ID);
	close();
	return newArray(pixel_area, sum_of_int);
}
/////////////////////////
//
function MakeLD2950mask(file_path, NewDir_path, CBS_bg, Threshold_metric, Threshold_value){
	open(file_path);
	file_ID = getImageID();
	file_name_woExt = File.getName(NewDir_path);
	resetMinAndMax();
	run("8-bit");
	run("Convoluted Background Subtraction", "convolution=Median radius=" + CBS_bg);
	if(Threshold_metric == "Value"){
		setThreshold(0, Threshold_value);
	}else{
		setAutoThreshold(Threshold_metric);
	}
	run("Convert to Mask");
	run("Invert");
	LD2950_path = NewDir_path + file_name_woExt + "_LD2950mask.tif";
	saveAs("Tiff", LD2950_path);
	close();
	return LD2950_path;
}
/////////////////////////

Dir = getDirectory("Select an Input Folder containing Folders you are interested in");
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
ThresholdMetric = newArray("Value", "Default", "Huang", "Intermodes", "IsoData", "Li", "MaxEntropy", "Mean", "MinError", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Triangle", "Yen");

// Dialog
file_idx = 1;
mask_candidate = "";
nuc_candidate = "";
LD2950_candidate = "";
Dialog.create("Parameter Settings");
	// files to use
	Dialog.addMessage("=== files to use (leave empty for irrelevant files) ===");
	for(i=0; i<tif_file_names.length; i++){
		tif_file_name = tif_file_names[i];
		if (endsWith(tif_file_name, "_mask.tif") || endsWith(tif_file_name, "_nuc.tif") || endsWith(tif_file_name, "_2950_0-65535.tif")){
			if (endsWith(tif_file_name, "_mask.tif")){
				Dialog.addString(tif_file_name, "");
				mask_candidate = tif_file_name;
			}
			if (endsWith(tif_file_name, "_nuc.tif")){
				Dialog.addString(tif_file_name, "");
				nuc_candidate = tif_file_name;
			}
			if (endsWith(tif_file_name, "_2950_0-65535.tif")){
				Dialog.addString(tif_file_name, "LD2950");
				LD2950_candidate = tif_file_name;
			}
		}else{
			Dialog.addString(tif_file_name, "Name" + file_idx);
			file_idx += 1;
		}
	}
    Dialog.addMessage(" ");
	// mask definition settings
	Dialog.addMessage("=== Mask definition settings ===");
	Dialog.addChoice("Cell Mask", tif_file_names, mask_candidate);
	Dialog.addChoice("Nuc Mask", tif_file_names, nuc_candidate);
	Dialog.addChoice("LD2950", tif_file_names, LD2950_candidate);
    Dialog.addMessage(" ");
    // LD area definition settings
	Dialog.addMessage("=== LD definition settings ===");
    Dialog.addNumber("convoluted background subtruction", 3);
	Dialog.addChoice("Threshold Metric", ThresholdMetric);
    Dialog.addNumber("Threshold Value (only used when metric is 'Value')", 30);
    Dialog.addCheckbox("Batch mode", 1);
Dialog.show();

target_file_names = newArray();
target_file_nicknames = newArray();
for(i=0; i<tif_file_names.length; i++){
	nickname = Dialog.getString();
	if(nickname != ""){
		target_file_names = Array.concat(target_file_names, tif_file_names[i]);
		target_file_nicknames = Array.concat(target_file_nicknames, nickname);
	}
}

CellMask_name = Dialog.getChoice();
CellNuc_name = Dialog.getChoice();
LD2950_name = Dialog.getChoice();
CBS_size = Dialog.getNumber();
Threshold_metric = Dialog.getChoice();
Threshold_value = Dialog.getNumber();
BATCH = Dialog.getCheckbox();

setBatchMode(BATCH);

//////////////////////////////////////////////////////////////////////////////////////////////

//Making new folder
NewDir_name = make_new_folder(Dir, "LD2950vsCellWhole");
// Make LDMask
LD2950_path = MakeLD2950mask(Dir+LD2950_name, Dir+NewDir_name, CBS_size, Threshold_metric, Threshold_value);
// Make CellMask wo Nuc area
CytopMask_path =  SubtractMasks(Dir+CellMask_name, Dir+CellNuc_name, Dir+NewDir_name);
CytoLD2950_path = MultiplyMasks(LD2950_path, CytopMask_path, Dir+NewDir_name);
// CalculateArea
results = "Name\tCytop Area\tCytop IntDen\tLD2950 Area\tLD2950 IntDen";
for(i=0; i<target_file_names.length; i++){
	target_file_path = Dir + target_file_names[i];
	CytoLD2950_results = CalcMeanInt(target_file_path, CytoLD2950_path);
	target_results = CalcMeanInt(target_file_path, CytopMask_path);
	results += "\n" + target_file_nicknames[i] + "\t";
	results += toString(CytoLD2950_results[0]) + "\t" + toString(CytoLD2950_results[1]) + "\t";
	results += toString(target_results[0]) + "\t" + toString(target_results[1]);
}

// Summary Results
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
summary = "SETTINGS" + "\t" + year + "/" + month + "/" + dayOfMonth + " " + hour + ":" + minute;
summary += "\n" + "CellMask File\t" + CellMask_name;
summary += "\n" + "NucMask File\t" + CellNuc_name;
summary += "\n" + "Threshold metric\t" + Threshold_metric;
summary += "\n" + "Threshold value\t" + Threshold_value;
summary += "\n" + "Convoluted Background Subtractionl (radius)\t" + CBS_size;
summary += "\n" + "Threshold Metric\t" + Threshold_metric;
summary += "\n\n" + "NAME CORRESPONDENCE";

for(i=0; i<target_file_names.length; i++){
	summary += "\n" + target_file_nicknames[i] + "\t" + target_file_names[i];
}
summary += "\n\n" + results;
save_path = Dir + NewDir_name + File.getName(NewDir_name) + "_results.txt";
saveText(summary, save_path);

exit("Finished!!!d(^o^)b");


















