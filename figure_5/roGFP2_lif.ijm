//perform setup
close("*");
run("Clear Results");
setOption("BlackBackground", true);
run("Set Measurements...", "area mean standard display redirect=None decimal=3");
numberOfSeries = 0;

//select .lif file to process and output directory
inputPath = File.openDialog("Select a file for processing");
outputDirectory = getDirectory("Select an output directory");

//get details from user
Dialog.create("Options for processing");
Dialog.addCheckbox("Subtract autofluoresence", false);
Dialog.addCheckbox("Exclude overexposure", true);
Dialog.addCheckbox("Save fire images", true);
Dialog.addString("Prefix for analysis", "...");
Dialog.addCheckbox("Analyze channels seperate", false);
Dialog.show();
subtractAutofluoresence = Dialog.getCheckbox();
excludeOverexposure = Dialog.getCheckbox();
saveFireImages = Dialog.getCheckbox();
prefixForAnalysis = Dialog.getString();
seperateAnalysis = Dialog.getCheckbox();


//analyse images
run("Bio-Formats Macro Extensions");
Ext.setGroupFiles("false"); 
Ext.setId(inputPath);
Ext.getSeriesCount(numberOfSeries);
print("Opening" + inputPath + "...");

for (s = 0; s < numberOfSeries; s++) {
	Ext.setSeries(s);
	Ext.getSeriesName(imageName);
	Ext.getSizeC(numberOfChannels);

	//change this line for conditions on the series to process
	if (imageName.startsWith(prefixForAnalysis)) {
		showProgress(s/numberOfSeries);
		storagePath = outputDirectory + imageName;
	
		
		//open image
		_s = s+1;
		print("Processing " + imageName + " with " + numberOfChannels + " channels.");
		run("Bio-Formats Importer", "open=[" + inputPath +"] autoscale color_mode=Composite view=Hyperstack stack_order=XYCZT series_" + _s);
		currentImageID = getImageID();
		run("Gaussian Blur...", "sigma=2");

		//define each channel
		run("Split Channels");
		greenImage = currentImageID - 1;
		transPMTImage = currentImageID - 3;
		autoFluoresenceImage = currentImageID - 2;
		blueImage = currentImageID - 4;

		//generate green mask
		selectImage(greenImage);
		run("Duplicate...", " ");
		setAutoThreshold("Default dark ignore_white");
		run("Convert to Mask");
		run("Divide...", "value=255");
		greenMask = getImageID();
		
		selectImage(greenImage);
		run("Duplicate...", " ");
		if (excludeOverexposure){
			setThreshold(0, 254);
		} else {
			setThreshold(0, 255);
		}
		run("Convert to Mask");
		run("Divide...", "value=255");
		greenOverexposureMask = getImageID();

		imageCalculator("Multiply create 32-bit", greenMask, greenOverexposureMask);
		greenFinalMask = getImageID();

		//generate blue mask
		selectImage(blueImage);
		run("Duplicate...", " ");
		if (excludeOverexposure){
			setThreshold(0, 254);
		} else {
			setThreshold(0, 255);
		}
		run("Convert to Mask");
		run("Divide...", "value=255");
		blueFinalMask = getImageID();

		imageCalculator("Multiply create 32-bit", blueFinalMask, greenFinalMask);
		finalMask = getImageID();

		//generate autoflouresence mask
		if (subtractAutofluoresence) {
			selectImage(autoFluoresenceImage);
			run("Duplicate...", " ");
			setAutoThreshold("Default dark ignore_white");
			run("Convert to Mask");
			run("Invert"); //white spots should be excluded
			run("Divide...", "value=255");
			autoFluoresenceMask = getImageID();
			imageCalculator("Multiply create 32-bit", finalMask, autoFluoresenceMask);
			finalMask = getImageID();
		}

		//apply mask to green and blue image
		imageCalculator("Multiply create 32-bit", finalMask, greenImage);
		maskedGreenImage = getImageID();
		imageCalculator("Multiply create 32-bit", finalMask, blueImage);
		maskedBlueImage = getImageID();

		if (seperateAnalysis) {
			selectImage(maskedGreenImage);
			orig = getTitle();
			orig = "green"+orig;
			run("Rename...", "title=[" +orig + "]");
			run("Measure");
			
			selectImage(maskedBlueImage);
			orig = getTitle();
			orig = "blue"+orig;
			run("Rename...", "title=[" +orig + "]");
			run("Measure");
		}
		//calculate ratio
		imageCalculator("Divide create 32-bit", maskedBlueImage, maskedGreenImage);
		ratioImage = getImageID();
		run("Fire");
		run("Measure");
		if (saveFireImages) {
			selectImage(ratioImage);
			saveAs("tiff", storagePath);
		}

		close("\\Others");
	}
}
saveAs("Results", outputDirectory + "Results.csv");