#!/bin/perl
use strict;
use KD;


=pod

=head1 NAME

lof.pl - Perl implemention for the LOF(Local Outlier Factor) algorithm.

=head1 SYNOPSIS

lof.pl k InputFile

INPUT
k:	k nearest neighbors, k>=1, k is an integer. 
	If the query point is a point of the original data file, the 1st nearest point is the query point itself.
	
	K is the minimum number of objects a "cluster" has to contain. 
	K is the maximum number of "close by" objects than can potentially be local outliers.
	The LOF paper suggests k is between 10 and 20.
	
InputFile: Each line is a point. Attributes are seperated by a space ' '. 


OUTPUT
lof.txt: Each line is a point's lof value for the input file. The higher the LOF value, the stronger the outlier.	

=head1 DESCRIPTION

LOF is a density-based outlier detection algorithm. To run lof.pl, you need the KD.pm module.

=head2 EXPORT

None by default.

=head1 REFERENCES 

(1) M.M.Breunig, H.Kriegel, R.T.Ng, and J.Sander. 
    LOF: Identifying Density-Based Local Outliers. 
    in Proc. ACM SIGMOD 2000 Int. Conf. On Management of Data. 2000.
	
=head1 AUTHOR

Ying Liu  yliu at uab.edu 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Ying Liu
The University of Alabama at Birmingham (UAB)

This is a free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut


my ($k, $input);
if (@ARGV!=2)
{
	print "Usage:\n";
	print "\tlof.pl k inputfile\n\n";
	print "\twhere:\n";
	print "\tk		k nearest neighbors (MinPts)\n";
	print "\tinputfile	data points file\n";

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
		print "k nearest neighbors (MinPts) is an integer.\n";
		exit;
	}
	
	$input = $ARGV[1];
	open (INPUT, "<$input") || die ("cannot open \"$input\": $!");		
}

print "Hello, LOF!\n";

my $start_user = time();
# insert the original points into the kd tree
my $kdTree = new Tree::KD;
my @points;
my $numPoints=0;
print "inserting kd tree...\n";
while (my $line = <INPUT>)
{
	chomp ($line);
	@{$points[$numPoints]} = split(' ', $line);	
	$kdTree->insert($numPoints,\@{$points[$numPoints]});
	$numPoints++;
}
close INPUT;

# search k nearest neighbors
my %knn;
my %k_dist;
printf "searching k nearest neighbors...\n";
for(my $i=0;$i<$numPoints;$i++)
{
	my $neighbors = $kdTree->nearest($points[$i], $k);
	#print join(", ", $neighbors);
	#print "$neighbors";
	pop @$neighbors; # the nearest point is itself
	
	for(my $j=@$neighbors;$j>0;$j--)
	{
	    
		my $nnb = pop @$neighbors;
		#print "$nnb->[1], $nnb->[0] \n";
		my $index = $nnb->[1];
		my $dist = sqrt($nnb->[0]);
		$dist = 0.001 if $dist ==0;
		$knn{$i}->{$index} = $dist; 	
		$k_dist{$i}=$dist if $j==1;	# k distance of an object $query is the biggest k nn of $query.
		#printf "$i kdist: $k_dist{$i} \n";
	}	
}


print "Gravity Based ... \n";

my %force;
foreach my $point (keys %knn)
{
    #printf "\nPoint: $point \n";
    
    my $g=10;
    my $m1=1;
    my $m2=1;
    my $total_force;
    foreach my $neighbor (keys %{$knn{$point}})
    {
	my $dist=$knn{$point}->{$neighbor};
	#print "\n ($g * $m1 * $m2 )/( $dist * $dist)";
        
        $total_force += ($g * $m1 * $m2)/($dist * $dist);
        #$reach_dist{$point}->{$neighbor} = max($k_dist{$neighbor},$dist);
	#print "\n ::  $total_force";
    }
    print "\n :: Total Force For Point : $point is $total_force";
    $force{$point}=$total_force;


}



#printf "Gravity took %.2f seconds user time.\n\n", $time;

my $kdlog = 'gravity.txt';
open (LOFLOG, ">$kdlog") || die ("cannot open \"$kdlog\": $!");

for(my $i=0;$i<$numPoints;$i++)
{
    printf LOFLOG "%.5f\n",$force{$i};
}
close LOFLOG;


=forcomment

my %force_factor;
foreach my $point (keys %knn)
{
    #printf "\nPoint: $point \n";

    my $neighbor_force_sum;
    foreach my $neighbor (keys %{$knn{$point}})
    {
        $neighbor_force_sum += $force{$neighbor};
	print "\n$force{$neighbor}";

    }
    
    print "\n  Sum :::: $neighbor_force_sum";    
    print "\n Force :::: $force{$point}";

    $force_factor{$point}= ($force{$point}* ($k - 1) ) /$neighbor_force_sum;

    print "\n force factor:  $force_factor{$point}";   
}

my $end_user = time();
my $time = $end_user - $start_user;
printf "Gravity took %.2f seconds user time.\n\n", $time;

my $kdlog = 'gravity.txt';
open (LOFLOG, ">$kdlog") || die ("cannot open \"$kdlog\": $!");

for(my $i=0;$i<$numPoints;$i++)
{
    printf LOFLOG "%.5f\n",$force_factor{$i};
}
close LOFLOG;

=cut

=for comment


# reachability distance of an object p w.r.t. object o.

printf "LOF......\n";
my %reach_dist;
foreach my $point (keys %knn)
{
    #printf "\nPoint: $point \n";
	foreach my $neighbor (keys %{$knn{$point}})
	{
	    print "$point ,$neighbor,$knn{$point}->{$neighbor} Max: $k_dist{$neighbor} \n" if $point==0;
		my $dist=$knn{$point}->{$neighbor};
		$reach_dist{$point}->{$neighbor} = max($k_dist{$neighbor},$dist);
	}
}

# local reachability density of an object p
my %lrd_p;
foreach my $point (keys %reach_dist)
{
	my $total=0;
	foreach my $neighbor (keys %{$reach_dist{$point}})
	{
		$total += $reach_dist{$point}->{$neighbor};
	}
	$lrd_p{$point}=$k/$total;
}

# local outlier factor of an object p
my %lof;
foreach my $point (keys %reach_dist)
{
	my $total=0;
	foreach my $neighbor (keys %{$reach_dist{$point}})
	{
		$total += $lrd_p{$neighbor}/$lrd_p{$point};
	}
	$lof{$point}=$total/$k;
}

my $end_user = time();
my $time = $end_user - $start_user;
printf "LOF took %.2f seconds user time.\n\n", $time;

my $kdlog = 'lof.txt'; 
open (LOFLOG, ">$kdlog") || die ("cannot open \"$kdlog\": $!");

for(my $i=0;$i<$numPoints;$i++)
{
	printf LOFLOG "%.5f\n",$lof{$i};
}
close LOFLOG;

sub max 
{
	my ($x, $y) = @_;
	return $x>$y ? $x : $y; 
}
=cut

__END__




