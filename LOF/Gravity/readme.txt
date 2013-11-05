LOF usage: lof.pl k inputfile

example:   lof.pl 15 cluster20.txt
	   lof.exe 15 cluster20.txt (lof.exe is the executive version for Windows.)


INPUT
k:	k nearest neighbors, k>=1, k is an integer. 
	If the query point is a point of the original data file, the 1st nearest point is the query point itself.
	
	K is the minimum number of objects a "cluster" has to contain. 
	K is the maximum number of "close by" objects than can potentially be local outliers.
	The LOF paper suggests k is between 10 and 20.
	
InputFile: Each line is a point. Attributes are seperated by a space ' '. 


OUTPUT
lof.txt: Each line is a point's lof value for the input file. The higher the LOF value, the stronger the outlier.	


lof.pl uses KD.pm module and KD.pm uses Heap::Simple::Perl module. Please make sure these package are installed.
If you use Unix or Linux, please change to your perl location.



PACKAGE
lof.pl:			LOF source code
KD.pm:			KD tree module.
cluster20.txt:		2-dim example file
cluster20lof.txt:	"lof.pl 15 cluster20.txt" experiment results.
breunig00lof.pdf:	LOF paper
readme:			this file.




Ying Liu
Start at June 2004

liuyi@cis.uab.edu
Department of Computer & Information Sciences
The University of Alabama at Birmingham
