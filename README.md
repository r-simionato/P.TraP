# PlumeTraP (Plume Tracking and Parametrization) - v2.1.0
DOI: 10.5281/zenodo.6406008 - (https://github.com/r-simionato/PlumeTraP)
Copyright (C) 2024 Riccardo Simionato (University of Geneva)
May 2024

PlumeTraP is a MATLAB-based code that semi-automatically tracks volcanic
plumes from visible-wavelenghts videos and is also capable of automatically
calculating the geometric parameters of the plume.

Detection and parameterization of volcanic plumes in visible videos.
Starting from a video, frames are saved, segmented through a specific
technique and basilar parameters of the plume through time are extracted.

Tested up to MATLAB R2023b and Image Processing Toolbox 23.2

Two versions of PlumeTraP are available:
- APP version (PlumeTraP.mlapp)
- script version (PlumeTraP_script.m)

## Documentation
The general workflow of PlumeTraP is presented in the user's manual 
(https://github.com/r-simionato/PlumeTraP). 
For further information see "Simionato R., Jarvis P.A., Rossi E.,
Bonadonna C., 2022 - PlumeTraP: a new MATLAB-based algorithm to detect and
parametrize volcanic plumes from visible-wavelength images" or contact the 
authors. For specific functioning or setting up the user may refer to the 
MATLAB scripts, which are appropriately documented.

## Citation
PlumeTraP was published in "Simionato, R.; Jarvis, P.A.; Rossi, E.; 
Bonadonna, C. PlumeTraP: A New MATLAB-Based Algorithm to Detect and 
Parametrize Volcanic Plumes from Visible-Wavelength Images. Remote Sens. 
2022, 14, 1766. https://doi.org/10.3390/rs14071766". Citation of specific 
versions may be added, following the citation section in Zenodo 
(https://doi.org/10.5281/zenodo.6406008).

## Updates included in this version:
- new code structure
- modified wind correction
- minor improvements and bugs solved

## License
This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU General Public License as published by the 
Free Software Foundation, either version 3 of the License, or (at your 
option) any later version.
This program is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details 
(https://www.gnu.org/licenses/gpl-3.0.html).