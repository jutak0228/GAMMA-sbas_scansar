# GAMMA-sbas_scansar
This GAMMA RS script is for SBAS analysis with ScanSAR mode observation mode datasets

## Requirements
GAMMA Software Modules:
The GAMMA software is grouped into four main modules:
- Modular SAR Processor (MSP)
- Interferometry, Differential Interferometry and Geocoding (ISP/DIFF&GEO)
- Land Application Tools (LAT)
- Interferometric Point Target Analysis (IPTA)

The user need to install the GAMMA Remote Sensing software beforehand depending on your OS.

For more information: https://gamma-rs.ch/uploads/media/GAMMA_Software_information.pdf

## Process step

Pre-processing: please copy rslc/ and DEM_prep/ the processing directory.

Note: it should be processed orderly from the top (part_00).

**It needs to change the mark "off" to "on" when processing**.

- part_00="off" # [0] preprocessing (remove polar name from rslc files)
- part_01="off" # [1] Generation of MLI images and geocoding
- part_02="off"	# [2] Selection of pairs for the multi-reference stack
- part_03="off"	# [3] Generation of differential interferograms, filtering and spatial unwrapping
- please check diff/*.diff0.adf3.bmp
- part_04="off" # [4] Definition of a mask for the subsidence area
- part_05="off" # [5] Estimation of linear phase ramps
- part_06="off"	# [6] Checking of phase unwrapping consistency using mb with gamma = 0
- part_07="off"	# [7] Estimation and subtraction of very long-range atmospheric component
- part_08="off"	# [8] Update estimation and subtraction of atmospheric component
- part_09="off"	# [9] Rerun mb to get quality measure, mask low quality part of result and finalize the result
- part_10="off"	# [10] Geocoding and visualization of the result
