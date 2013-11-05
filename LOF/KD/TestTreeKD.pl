use strict;
use KD;

my ($k, $input,$output);
if (@ARGV!=3)
{
	print "Usage:\n";
	print "\tTestTreeKD.pl k inputfile outputfile\n\n";
	print "\twhere:\n";
	print "\tk		number of nearest neighbors per query\n";
	print "\tinputfile	data points file\n";
	print "\toutputfile	results file\n";
	
	
	exit;
}
else
{
	if ($ARGV[0]=~/[1-9]+/)
	{
		$k = $ARGV[0];		
	}
	else
	{
		print "k nearest neighbors is an integer.\n";
		exit;
	}
	
	$input = $ARGV[1];
	open (INPUT, "<$input") || die ("cannot open \"$input\": $!");		
	
	$output = $ARGV[2];
	open (OUTPUT, ">$output") || die ("cannot open \"$output\": $!")
	
}

print "Hello, KD Tree.\n";

my $start_user = time();

# Default bucketSize is 7, bucketSize can be set when it is created. 
# Default infinity is 1e10. The farest distance should be less than infinity.
# my $kdTree = new Tree::KD bucketSize=>5;
my $kdTree = new Tree::KD;

# insert points into the kd tree $kdTree.
my $numPoints = 0;
my @points;
# each line is a point, and attributes are seperated by a space ' '.
while (my $line = <INPUT>) 
{
	chomp ($line);
	@{$points[$numPoints]} = split(' ', $line);
	
	$kdTree->insert($numPoints,\@{$points[$numPoints]});
	$numPoints++;
}

close INPUT;

# search k nearest neighbors of each point
my %knn;
for(my $i=0;$i<$numPoints;$i++)
{
	# The return value $neighbors of nearest() method is an array reference. 
	# The last of the array is the 1st nearest neighbor.
	# The first the array is the kth nearest neighbor.
	my $neighbors = $kdTree->nearest($points[$i], $k);
		
	for(my $j=$k;$j>0;$j--)
	{
		my $nnb = pop @$neighbors;
		my $index = $nnb->[1];
		my $dist = sqrt($nnb->[0]);
		push (@{$knn{$i}},[$index,$dist]); 
	}	
}

my $end_user = time();
my $time = $end_user - $start_user;
printf "KD tree took %.2f seconds user time.\n\n", $time;

for(my $i=0;$i<$numPoints;$i++)
{
	printf OUTPUT "Query point: (@{$points[$i]})\n";
	printf OUTPUT "\tNN\tIndex\tDistance\n";
	
	for(my $j=1;$j<=$k;$j++)
	{
		my $index = $knn{$i}->[$j-1]->[0];
		my $dist = $knn{$i}->[$j-1]->[1];
		printf OUTPUT "\t$j\t$index\t%.5f\n", $dist;	
	}	
}

close OUTPUT;



