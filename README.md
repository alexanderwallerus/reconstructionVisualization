# A simple and flexible visualization for .swc neuron reconstructions

Simply put a .swc file named reconst.swc in the data folder and run the code.

![example reconstruction visualization](/gitReadmeFiles/slice15_L11fromwww.neutracing.comslashdownload.png)
Slice15_L11 from https://www.neutracing.com/download/ partially reconstructed to show various features of the program

Neutube and ShuTu are great free programs to semiautomatically create .swc neuron reconstructions from scanned 3D volume data.

## Features:

* .swc files have a structure identifier for each vertex, usually 1=soma, 2=axon, 3=(basal) dendrite,... Each part of the reconstruction can be custom colored by its structure identifier by entering the desired RGB color into typeColors.txt
* multiple different neurons can be distinctly reconstructed by using different structure identifiers
* show varicosities/synapses/other points of interest (circles) by reconstrucing them with structure identifier 11
* use structure identifier 20 and upwards to reconstruct contours, i.e. to delineate different brain regions or layers
* boundary box, axis arrows, contours, points of interest can all be toggled visible/invisible
* toggle between perspective and orthographic projection
* the addCustomDrawing() function can be used to add additional custom drawing to be visualized, like a custom scale bar
* Yes, this code can keep up with large reconstructions, I was able to easily visualize a personally reconstructed neuron with more than 27300 vertices

## TODO

* It might be neat to have a 3D scalebar readily available at the 3 planes behind the reconstruction from the current point of view
* A small brain model with a position indicator in one corner of the window might be helpful for data presentation
* The reconstruction visualization could be combined with putBrainBackTogether to show a reconstruction placed inside the maximum projection 3D tissue.