
color = getValue("color.foreground");
print(color);
if(color==255){
	color = "black";
}
if(color==0){
	color = "white";
}
print(color);
run("Colors...", "foreground=" + color + " background=black selection=yellow");


