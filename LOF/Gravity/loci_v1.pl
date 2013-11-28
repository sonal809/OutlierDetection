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
	print "\tloci.pl k inputfile\n\n";
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

print "Hello, LOCI!\n";

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
my %mdef_per_r;
my %dev_per_r;
my %knn;
my %k_dist;
printf "searching k nearest neighbors...\n";

for(my $i=0;$i<$numPoints;$i++)
{
        printf "for point $points[$i][0]\n";

        my $neighbors = $kdTree->nearest($points[$i], $k);
	#print join(", ", $neighbors);
	#print "$neighbors";
	#pop @$neighbors; # the nearest point is itself
	
	for(my $j=@$neighbors;$j>0;$j--)
	{
	    
		my $nnb = pop @$neighbors;
		print "$points[$nnb->[1]][0], $nnb->[0] \n";
		my $index = $nnb->[1];
		my $dist = sqrt($nnb->[0]);
		#$dist = 0.01 if $dist==0;
		$knn{$i}->{$index} = $dist; 	
		$k_dist{$i}=$dist if $j==1;	# k distance of an object $query is the biggest k nn of $query.
	}	
}


my $eps =  25;
my $alpha = 0.5;

my $min_pt = 1;


for(my $r=24;$r<$eps;$r++){

#    for(my $a=1;$a<$eps;$a++){

    

	#print "$r: $a\n"

    
    

   
	my %new_neighbors;
	my $is_accepted = 1;
	my %alpha_neighbors;

	    foreach my $point (keys %knn)
	         {

		     my $count = 0;
		     
		     foreach my $neighbor (keys %{$knn{$point}})
		     {
	
			 my $dist=$knn{$point}->{$neighbor};
	
			 #printf "old dist : $dist\n";

			 if($dist <= $r){
			     
			     #printf "choosen neighbor $neighbor of point $point \n";
	 
			     $count = $count + 1;
			     $new_neighbors{$point}->{$neighbor} = $dist;
			     
			     
			 }

			 if($dist <= $alpha*$r){
			     
			     $alpha_neighbors{$point}->{$neighbor} = $dist;


			 }


		     }

		     if($count < $min_pt){

			# print  "Not Enough Min_pts" ;
                         $is_accepted = 0; 
			 last;

		     }

		 }


	         if($is_accepted == 0){

		     print "Not enough Min Points for r value : $r";
			 next;
		 }else{

		     printf "Got Enough Values for r:  $r \n"

		 }
	          

	print "\n local_desnsity:  \n";
	     my %local_density; 

     		  foreach my $point (keys %knn){

		      my $counter = 0;
		     
		      foreach my $newneighbors (keys %{$new_neighbors{$point}}){
			 #my $local_density{$point}->
			 $counter =  $counter + 1;
			 #printf " point : $point , newneighbor: $newneighbors";
			 my $dist= $new_neighbors{$point}->{$newneighbors};
			 
                         printf "new dist : $dist\n";
			 
		     }
		      
		      
		      print "$points[$point][0] : $counter\n";
		      $local_density{$point} = $counter;
		     

	      }

	print "\n alpha_density:  \n";

	   my %alpha_density;
	   

	             foreach my $point (keys %knn){

			 
			 my $counter = 0;
			 foreach my $alphaneighbors (keys %{$alpha_neighbors{$point}}){
                         
			    
			     
			     $counter = $counter + 1;
			     #my $dist= $alpha_neighbors{$point}->{$alphaneighbors};
			     
			     
			 }
			 
			 print "$points[$point][0] : $counter\n";
			 $alpha_density{$point} = $counter;


		     }

	     my %average_local_density;

	
	        foreach my $point (keys %knn){
	           
                      my $counter = 0; 

	              foreach my $newneighbors (keys %{$new_neighbors{$point}}){


			  $counter = $counter + $alpha_density{$newneighbors};


		      }

		      $average_local_density{$point} = $counter / $local_density{$point};
		      print "average_local_density of a point :  $points[$point][0] is : $average_local_density{$point} \n";
		      
		}



        	my %mdef;

	         foreach my $point (keys %knn){

		     $mdef{$point} =  1 - ($alpha_density{$point}/$average_local_density{$point});
	             print "mdef of point: $points[$point][0] is : $mdef{$point} \n";
	
		 }

	      
	
	        my %stand_deviation_density;

	         foreach my $point(keys %knn){

		     my $dev = 0;

		     foreach my $newneighbors (keys %{$new_neighbors{$point}}){

			 $dev = $dev + ($alpha_density{$newneighbors} - $average_local_density{$point}) * ($alpha_density{$newneighbors} - $average_local_density{$point});


		     }
		     
		     $dev = $dev /$local_density{$point};
		     $dev = sqrt($dev);

		     print "stand_density of point: $points[$point][0]  is : $dev \n";
		     $stand_deviation_density{$point} = $dev;

	         }
	
	        my %mdef_stand_deviation;

	        foreach my $point(keys %knn){

		    $mdef_stand_deviation{$point} = $stand_deviation_density{$point}/$average_local_density{$point};
		    my $temp = 3*$mdef_stand_deviation{$point};
		    print "mdef standard deviation of a point : $points[$point][0] is $mdef_stand_deviation{$point} and threshold is $temp\n";

		}

	        foreach my $point(keys %knn){

		    my $temp = 3*$mdef_stand_deviation{$point};
	
#		    my $rounded_mdef = int($mdef{$point} + $float/abs($float*2));

		    #return sprintf("%.${dp}g", $A) eq sprintf("%.${dp}g", $B);
	#	   my  $rounded_mdef = sprintf("%.4f", $mdef{$point});
	#	    my $rounded_deviation =  sprintf("%.4f", $temp);

	#	    if($rounded_mdef >= $rounded_deviation ){
	#		print "This Point $points[$point][0] is an Outlier \n";
	#	    }

		    
                    if($mdef{$point} > 0){
			if (($temp - $mdef{$point}) < 0.00001){
                    #if($mdef{$point} ge $temp ){
			    print "This Point $points[$point][0] is an Outlier \n";
			}
                    }



	        }


	foreach my $point (keys %knn){

            #print $point;
	    $mdef_per_r{$points[$point][0]}->{$r} = $mdef{$point};
	    $dev_per_r{$points[$point][0]}->{$r}= 3*$mdef_stand_deviation{$point};
        }



#	      print "\n MDEF :"

		  #my %

	

		
# }
}

for(my $r=2;$r<$eps;$r++){

    print " For point $points[9][0] for r $r is $mdef_per_r{$points[9][0]}->{$r} and threshold is $dev_per_r{$points[9][0]}->{$r}\n";

}


# reachability distance of an object p w.r.t. object o.

=for comment

printf "LOF......\n";
my %reach_dist;
foreach my $point (keys %knn)
{
	foreach my $neighbor (keys %{$knn{$point}})
	{
		my $dist=$knn{$point}->{$neighbor};
		#$reach_dist{$point}->{$neighbor} = max($k_dist{$neighbor},$dist);
		$reach_dist{$point}->{$neighbor} = $dist;
	}
}
=cut
# local reachability density of an object p


=for comment
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




