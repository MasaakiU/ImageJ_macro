
ids=newArray(nImages);
for(i=0; i<nImages; i++){
	selectImage(i+1);
	run("glow_wo_saturation");
}
