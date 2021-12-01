# Vowel Region Detection
To detect Vowel Regions from an input speech signal by finding the Vowel Onset Points (VOPs) and Vowel End Points (VEPs) using Continuous Wavelet Transform (CWT) coefficients

## Steps
The steps involved in CWT based VR detection are: 
1. Compute mean-signal from the derived CWT coefficients of the speech signal. 
2. Divide mean-signal into 20 ms frames with 10 ms frame-shift. 
3. Calculate average absolute magnitude (AAM) for each frame of the mean-signal. 
4. Remove inconsistencies by performing mean-smoothing of window size 40 ms. 
5. Find all peaks in the smoothed signal. 
6. Remove unwanted peaks using a fixed threshold at 15% of maximum of AAM of a mean-signal. 
7. Further, when two or more than two successive peaks are found within 50 ms duration, keep the highest peak and remove remaining. 
8. These highest peaks in the smoothed AAM of the mean-signal provide the evidence of the VOPs.
9. Similarly, identify the VEPs by analyzing the CWT in the negative direction. That is, the valleys in the graph denote the VEPs.
10. Mark the region between two adjacent VOP and VEP as VR.

## References
1. K. Tripathi and K. S. Rao, “Robust vowel region detection method for multimode speech,” Multimed Tools Appl, vol. 80, pp. 13615–13637, 2021.
