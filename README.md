# odCalculationsMelbourne
Calculating trip time and distance using the r5r package


## Instructions

1. Copy all files from the [JIBE Sharepoint](https://rmiteduau.sharepoint.com/:f:/r/sites/JIBEUKAUS/Shared%20Documents/WP%203/odCalculationsMelbourne?csf=1&web=1&e=KptoAU) into this directory.
2. Run 1_prep_data.R to process the origin and destination points. Note: this is currently hardcoded to Alan's sharepoint folder. THE OUTPUT OF THIS STEP CANNOT LEAVE THE PROTECTED SHAREPOINT.
3. Run 2_run_OD_analysis.R to calculate the trip time and distance using r5r. PT_walk and PT_drive take a long time to process, so we save outputs in chunks of 100 trips. These are all merged at the end of this step.