usage:	TestTreeKD.pl k inputfile outputfile

example:   TestTreeKD.pl 7 cluster20.txt 7nncluster20.txt
	   

INPUT
k:	k nearest neighbors, k>=1, k is an integer. 
	If the query point is a point of the original data file, the 1st nearest point is the query point itself.
		
InputFile: Each line is a point. Attributes are seperated by a space ' '. 


KD.pm uses Heap::Simple::Perl module. Please make sure these package is installed.
If you use Unix or Linux, please change to your perl location.



PACKAGE
KD.pm:			KD Tree 
TestTreeKD.pl		test file for KD.pm
cluster20.txt		2-dim data points
7nncluster20.txt	"TestTreeKD.pl 7 cluster20.txt 7nncluster20.txt" experiment result
readme:			this file.




Ying Liu
Start at December 2005

liuyi@cis.uab.edu
Department of Computer & Information Sciences
The University of Alabama at Birmingham
