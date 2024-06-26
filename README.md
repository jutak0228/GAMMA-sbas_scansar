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

Pre-processing: satellite(i.e. Sentinel-1) *.zip data, /OPOD/*.EOF files, and "*.tif" dem data into "input_files_orig" dir.

Note: it should be processed orderly from the top (part_00).

**It needs to change the mark "off" to "on" when processing**. 

- prep_01a="off" # [1-a] iws slc data extraction bf edit
- prep_01b="off" # [1-b] iws slc data extraction af edit
- prep_02="off" # [2] Prepare DEM and geocode reference
- prep_03="off"	# [3] coregister data
- prep_04="off"	# [4] Deramp the data, oversample the data in range direction, and remove margin
- part_01="off" # [1] Generation of MLI images and geocoding
- part_02="off"	# [2] Selection of pairs for the multi-reference stack
- part_03="off"	# [3] Generation of differential interferograms, filtering and spatial unwrapping
- please check diff/*.diff0.adf3.bmp
- part_04="off"	# [4] Definition of a mask for the subsidence area
- part_05="off"	# [5] Estimation of linear phase ramps
- part_06="off"	# [6] Checking of phase unwrapping consistency using mb with gamma = 0
- part_07="off"	# [7] Estimation and subtraction of very long-range atmospheric component
- part_08="off"	# [8] Update estimation and subtraction of atmospheric component
- part_09="off"	# [9] Rerun mb to get quality measure, mask low quality part of result and finalize the result
- part_10="off"	# [10] Geocoding and visualization of the result
- dem_aux="off"	# [option] dem support file export (ls_map, incidence angle, local resolution, offnadir angle)
