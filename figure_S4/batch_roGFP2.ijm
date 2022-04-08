input_Directory = getDirectory("Choose an input directory");

setBatchMode(true);

list =	getFileList(input_Directory);
for (i = 0; i < list.length; i++) {
	filename = list[i];
	if (endsWith(filename,"signal.nd2")) {
		MeasureRatio(list[i]);
	}
}

function MeasureRatio(filename){
	open(input_Directory + filename);
	ImageID = getImageID();
	savingname = getTitle();
	
	run("Gaussian Blur...", "sigma=2 stack");
	run("Split Channels");
	selectImage(ImageID-1);
	bluePicture = getTitle();
	selectImage(ImageID-2);
	greenPicture = getTitle();

	run("Duplicate...", " ");
	setAutoThreshold("Default dark ignore_white");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Divide...", "value=255"); //mask is 255 normally
	selectImage(ImageID-3);
	mask = getTitle();
	
	imageCalculator("Multiply create 32-bit", bluePicture, mask);
	selectImage(ImageID-4);
	maskedBluePicture = getTitle();

	imageCalculator("Multiply create 32-bit", greenPicture, mask);
	selectImage(ImageID-5);
	maskedGreenPicture = getTitle();

	imageCalculator("Divide create 32-bit", maskedBluePicture, maskedGreenPicture);
	selectImage(ImageID-6);
	ratioPicture = getTitle();

	run("Fire");
	close("\\Others");
	savingstring = input_Directory + "output/" + savingname;
	saveAs("tiff", savingstring);
	
}

setBatchMode(false);
print("finished");