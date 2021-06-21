print("START");
run("Set Measurements...", "area mean min integrated redirect=None decimal=3");
run("Options...", "iterations=1 count=1 black do=Nothing");

adjust = true;
regular_expression = "^(?!masked_).*_by_.*tif";
suffix = "masked";

//compound_order = newArray("≡OA", "d14aLA", "d8AA", "d5EPA")
//compound_order = newArray("BrPA", "d14aLA", "d8AA", "d5EPA");
//compound_order = newArray("d2PA", "d5aLA", "d8AA");
//compound_order = newArray("d8AA", "d11LA");
//compound_order = newArray("d11LA", "d8AA");
compound_order = newArray("d2PA", "d14aLA", "d8AA", "d5DHA");

margin_px = 2;
LUT_width = 15;
font_size = 16;
percentile = 0.02;
setFont("Courier New", font_size, "Plain antialiased");
setJustification("left");
newImage("Montage.tif", "32-bit black", 1, 1, 1);
font_height = getValue("font.height");
txt_width = getStringWidth("0.000");
setColor("white");
close();
N_compounds = compound_order.length;

/////
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
// 配列中の index を求める
function get_index(array, item){
	idx = -1;
	for(i=0; i<array.length; i++){
		if(array[i] == item){
			idx = i;
		}
	}
	return idx;	
}
//与えられた輝度値のピクセル数をカウント
function count_pixels_equals_to(value){
	w = getWidth();
	h = getHeight();
	count = 0;
	for (x=0; x<w; x++){
		for(y=0; y<h; y++){
			v = getPixel(x, y);
			if (v == value){
				count++;
			}
		}
	}
	return count;
}
//与えられた輝度値のピクセル数をカウント
function count_pixels_bigger_than(value){
	w = getWidth();
	h = getHeight();
	count = 0;
	for (x=0; x<w; x++){
		for(y=0; y<h; y++){
			v = getPixel(x, y);
			if (v > value){
				count++;
			}
		}
	}
	return count;
}
function count_pixels_NaN(){
	w = getWidth();
	h = getHeight();
	count = 0;
	for (x=0; x<w; x++){
		for(y=0; y<h; y++){
			v = getPixel(x, y);
			if (isNaN(v)){
				count++;
			}
		}
	}
	return count;
}
// パーセンタイル
function set_percentile(per){
	w = getWidth();
	h = getHeight();
	nPixels = count_pixels_bigger_than(0);
	nZeroPixels = w * h - nPixels;
	N_NaN = count_pixels_NaN();
	high_limit = nPixels * per;
	low_limit = nZeroPixels + high_limit - N_NaN;
	nBins = 256;
	getHistogram(values, histA, nBins);
	
	// min val 求める
	i = -1;
	counts = 0;
	continue_ = true;
	do{
		counts += histA[++i];
		if(counts > low_limit){
			continue_ = false;
		}
	}while(continue_ && (i < histA.length-1))
	min_val = values[i];
	// max val 求める
	i = histA.length;
	counts = 0;
	continue_ = true;
	do{
		counts += histA[--i];
		if (counts > high_limit){
			continue_ = false;
		}
	}while (continue_ && (i > 0))
	max_val = values[i];
	setMinAndMax(min_val, max_val);
}
/*
// Brightness & Contrast のコマンドの、GUIに対応したバージョン
function AutoBC(){
	AUTO_THRESHOLD = 5000;
	getRawStatistics(nPixels);
	limit = nPixels/10;
	threshold = nPixels/AUTO_THRESHOLD;
	nBins = 256;
	getHistogram(values, histA, nBins);
	i = -1;
	found = false;
	do{
		counts = histA[++i];
		if(counts > limit) counts = 0; 
		found = counts > threshold; 
	}while((!found) && (i < histA.length-1))
	hmin = values[i];
	i = histA.length;
	do{
		counts = histA[--i];
		if (counts > limit) counts = 0;
		found = counts > threshold;
	}while ((!found) && (i > 0))
	hmax = values[i];
	
	setMinAndMax(hmin, hmax);
		//print(hmin, hmax);
	//run("Apply LUT");
}
*/

//
function count_suffix(folder_path, suffix){
	count = 0;
	child_file_list = getFileList(folder_path);
	for(i=0; i<child_file_list.length; i++){
		child_file_name = child_file_list[i];
		if(startsWith(child_file_name, suffix)){
			count += 1;
		}
	}
	return count;
}
function count_match(folder_path, regexp){
	count = 0;
	child_file_list = getFileList(folder_path);
	for(i=0; i<child_file_list.length; i++){
		child_file_name = child_file_list[i];
		if(matches(child_file_name, regexp)){
			count += 1;
		}
	}
	print(count);
	return count;
}

// draw LUT
function drawLUT(start_x, start_y, LUT_width, LUT_height){
	// LUT
	for(y_idx=0; y_idx<LUT_height; y_idx++){
		for(x_idx=0; x_idx<LUT_width; x_idx++){
			value = 255 * (LUT_height- 1 - y_idx) / (LUT_height - 1);
			setPixel(start_x + x_idx, start_y + y_idx, value);
		}
	}
	// frame
	for(y_idx=0; y_idx<LUT_height; y_idx++){
		setPixel(start_x - 1, start_y + y_idx, 255);
		setPixel(start_x + LUT_width, start_y + y_idx, 255);
	}
	for(x_idx=0; x_idx<LUT_width + 2; x_idx++){
		setPixel(start_x + x_idx - 1, start_y - 1, 255);
		setPixel(start_x + x_idx - 1, start_y + LUT_height, 255);
	}
}

// maximum value is 255 in 32 bit image
function make_montage(image_path_list, N_col, N_row){
	open(image_path_list[0]);
	dir_path = File.directory;
	dir_name = File.getName(dir_path);
	getDimensions(width, height, channels, slices, frames);
	grand_width_unit = width + margin_px + LUT_width + margin_px + txt_width + margin_px;
	grand_height_unit = height + margin_px;
	title_zone = font_height + margin_px;
	close();
	newImage("Montage.tif", "32-bit black", title_zone + (grand_width_unit)*N_col-margin_px-txt_width/4+2, title_zone + grand_height_unit*N_row-margin_px, 1);
	results_image_ID = getImageID();
	// LUT
	for(c=0; c<N_col; c++){
		for(r=0; r<N_row; r++){
			start_x = (title_zone + grand_width_unit * c + width + margin_px + 1);
			start_y = (title_zone + grand_height_unit * r + 1);
			drawLUT(start_x, start_y, LUT_width, height - 2);	// "-2" for frame
		}
	}
	run("Fire");
	setMinAndMax(0, 255);
	// Image and Text
	for(i=0; i<image_path_list.length; i++){
		open(image_path_list[i]);
		file_name_wo_ext = File.nameWithoutExtension;
		image_ID = getImageID();
		// check if it is "all 1 image"	
		run("Select All");
		run("Measure");
		raw_int_den1 = getResult("RawIntDen", nResults-1);
		pixels_equals_to_1 = count_pixels_equals_to(1);
		// change intensity and copy
		selectImage(image_ID);
		if(raw_int_den1 == pixels_equals_to_1){
			run("Duplicate...", " ");
			run("Multiply...", "value=" + 127.5);
			run("Select All");
			run("Copy");
			close();
			low_th = 0;
			high_th = 2;
			low_th_txt = "0.00";
			high_th_txt = "2.00";
		}else{
			if(adjust){
				set_percentile(percentile);
			}
			getMinAndMax(low_th, high_th);
			run("Duplicate...", " ");
			run("8-bit");
			run("Select All");
			run("Copy");
			close();
			resetMinAndMax();
			if(high_th >= 10){
				high_th_txt = toString(round(high_th * 10)/10);
			}else{
				high_th_txt = toString(round(high_th * 100)/100);
			}
			if(low_th >= 10){
				low_th_txt = toString(round(low_th * 10)/10);
			}else{
				low_th_txt = toString(round(low_th * 100)/100);
			}
		}
		// get compound_idx
		splitted_file_name_wo_ext = split(file_name_wo_ext, "_");
		r_idx = get_index(compound_order, splitted_file_name_wo_ext[1]);
		c_idx = get_index(compound_order, splitted_file_name_wo_ext[3]);
		// paste
		start_x = grand_width_unit * c_idx;
		start_y = grand_height_unit * r_idx;
		selectImage(results_image_ID);
		makeRectangle(title_zone + start_x, title_zone + start_y, width, height);
		run("Paste");
		selectImage(image_ID);
		setMinAndMax(low_th, high_th);
		run("Save");
		close();
		//テキスト
		text_start_x = start_x + width + margin_px + LUT_width + margin_px;
		text_start_y1 = start_y + font_height;
		text_start_y2 = start_y + height;
		//drawString(high_th_txt, title_zone + text_start_x, title_zone + text_start_y1);
		//drawString(low_th_txt, title_zone + text_start_x, title_zone + text_start_y2);
		Overlay.drawString(high_th_txt, title_zone + text_start_x, title_zone + text_start_y1);
		Overlay.drawString(low_th_txt, title_zone + text_start_x, title_zone + text_start_y2);

	}
	run("Select None");
	// タイトルラベル
	for(i=0; i<compound_order.length; i++){
		compound_name = compound_order[i];
		//drawString(compound_name, title_zone + text_start_x, title_zone + text_start_y1);
		name_width = getStringWidth(compound_name);
		Overlay.drawString(compound_name, title_zone + grand_width_unit * i + (width-name_width)/2, font_height, 0);
		Overlay.drawString(compound_name, font_height-5, title_zone + grand_height_unit * i + (height + name_width)/2, 90);	//バグ？ 調整のため 5 を引いた。
		Overlay.show;
	}
	run("Flatten");
	run("Select None");
	run("Save", "save=[" + dir_path + dir_name + "_" + suffix + "Montage.tif]");
	selectImage(results_image_ID);
	close();
}



// MAIN
dir_path = getDirectory("select folder");
results_list = get_folders_recursively(dir_path);

//setBatchMode(true);

for(i=0; i<results_list.length; i++){
	folder_path = results_list[i];
	//count = count_suffix(folder_path, "masked_");
	count = count_suffix(folder_path, suffix);
	if(count != 0){
		//
		unique_N_compounds = sqrt(count);
		if(unique_N_compounds != N_compounds){
			exit("some error!");
		}
		//
		child_file_list = getFileList(folder_path);
		masked_image_path_list = newArray();
		for(j=0; j<child_file_list.length; j++){
			child_file_name = child_file_list[j];
			if(startsWith(child_file_name, suffix)){
				masked_image_path_list = Array.concat(masked_image_path_list,folder_path + child_file_name);
			}
		}
		make_montage(masked_image_path_list, N_compounds, N_compounds);
//		close();
	}
	run("Collect Garbage");
}

exit("Finished!!!d(^o^)b");










