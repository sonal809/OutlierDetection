package Tree::KD;

use strict;
use Heap::Simple::Perl;
require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.01';


=pod

=head1 NAME

Tree::KD - Perl implemention for the KD-tree data structure and algorithms

=head1 SYNOPSIS

use Tree::KD;

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
my $k = 7; # number of nearest neighbors per query
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
		push (@{$knn{$i}}, [$index,$dist]); 
	}	
}

=head1 DESCRIPTION

Kd-tree is a data structure for searching k nearest neighbors. Default bucket size is 7.  

=head2 EXPORT

None by default.

=head1 REFERENCES 

(1) David M. Mount
    ANN Programming Manual (ANN, Version 0.1).
(2) J.H.Friedman, J.L.Bentley and R.A.Finkel
    An Algorithm for Finding Best Matches in Logarithmic Expected Time.			
(3) Raphael Finkel
    kd.pm ftp://ftp//ftp.cs.uky.edu/cs/software/kd.pm

=head1 AUTHOR

Ying Liu,  yliu at uab.edu 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Ying Liu
The University of Alabama at Birmingham (UAB)

This is a free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut


sub new 
{
    my $package = shift;
    my %opt = @_;
    my $self = {};
    for my $k (keys %opt)
    {
		$self->{$k} = $opt{$k};
    }
    $self->{bucketSize} = 7 unless $self->{bucketSize};
    $self->{infinity} = 1e10 unless $self->{infinity}; # to initialize minimization computations
   	
    bless $self => (ref($package) or $package);
    return $self;
}

sub insert
{
	my ($self, $id, $newValue) = @_;
	my $bucketSize = $self->{bucketSize};
	
	if (!defined($self->{root})) 
	{	
		my @value1 = @$newValue;
		my @value2 = @$newValue;
		$self->{root} = [0,[[$id,@$newValue]]];
		push @{$self->{root}},\@value1,\@value2;
		
		my @value3 = @$newValue;
		my @value4 = @$newValue;
		push @{$self->{box}}, \@value3,\@value4;	# the low & high value of each dimension
													# of whole data	
	} 
	else
	{
		# update the box low and high value.
		for(my $i=0;$i<@$newValue;$i++)
		{
			my $current_low = $self->{box}->[0]->[$i];
			if($current_low>$newValue->[$i])
			{
				$self->{box}->[0]->[$i] = $newValue->[$i];
			}
			
			my $current_high = $self->{box}->[1]->[$i];
			if($current_high<$newValue->[$i])
			{
				$self->{box}->[1]->[$i] = $newValue->[$i];
			}			
		}
		
		my $tree = $self->insertBucket($id,$newValue);
		$self->splitBucket($tree) if (@{$tree->[1]}>$bucketSize)		
	}
}

sub insertBucket
{
	my ($self,$id,$newValue) = @_;
	
	my $tree = $self->{root};
	while ($tree->[0]==1) # search the internal node
	{
		if(defined($$newValue[$tree->[2]])and($$newValue[$tree->[2]]<$tree->[3])) 
	 	{
			$tree->[4]->[0] = $$newValue[$tree->[2]] if ($tree->[4]->[0]>$$newValue[$tree->[2]]);
			$tree = $tree->[1]->[0]; # the left		
			next;
		} 
		if(defined($$newValue[$tree->[2]])and($$newValue[$tree->[2]]>=$tree->[3]))  
		{
			$tree->[4]->[1] = $$newValue[$tree->[2]] if ($tree->[4]->[1]<$$newValue[$tree->[2]]);
			$tree = $tree->[1]->[1]; # the right
			next;
		}	
	}
	
	if ($tree->[0]==0)
	{
		push @{$tree->[1]},[$id,@$newValue];	# insert the bucket
		my $bnd_lo = @$tree->[2];
		my $bnd_hi = @$tree->[3];
		
		# update the bounds
		for (my $dimension=0;$dimension<@$newValue;$dimension++)
		{
			my $coordinate = $newValue->[$dimension];
			$bnd_lo->[$dimension] = $coordinate if $coordinate<$bnd_lo->[$dimension];
			$bnd_hi->[$dimension] = $coordinate if $coordinate>$bnd_hi->[$dimension];
		}			
		return $tree;
	}
}

# Split by median of the dimension of the largest span.
sub splitBucket 
{
	my ($self,$tree) = @_;
	my $values = $tree->[1];
	my $bucketSize = $self->{bucketSize};
	my $lowest = $tree->[2];
	my $highest = $tree->[3];
	
	my $bestDimension = -1; 
	my $biggestSpan = -1;
	for (my $dimension=0;$dimension<@$highest;$dimension++) 
	{
		my $span = $highest->[$dimension] - $lowest->[$dimension];
		if ($span > $biggestSpan) 
		{
			$bestDimension = $dimension;
			$biggestSpan = $span;
		}
	} 
	
	my ($leftTree, $rightTree, $medianValue);
	$leftTree->[0] = 0;
	$rightTree->[0] = 0;
	# use median to split the bucket
	my @sortedValues = 	sort {$$a[$bestDimension+1] <=> $$b[$bestDimension+1]} @$values;
	my $serial;
	my (@left_low,@left_high);
	for ($serial=0;$serial<=$bucketSize/2;$serial++) 
	{
		push @{$leftTree->[1]}, $sortedValues[$serial];
		
		for (my $dimension=0;$dimension<@$highest;$dimension++)
		{
			my $coordinate = $sortedValues[$serial]->[$dimension+1];
			
			if(!defined $left_low[$dimension])
			{
				$left_low[$dimension] = $coordinate;				
			}
			else
			{
				$left_low[$dimension] = $coordinate if $coordinate<$left_low[$dimension];
			}
			
			if(!defined $left_high[$dimension])
			{
				$left_high[$dimension] = $coordinate;				
			}
			else
			{
				$left_high[$dimension] = $coordinate if $coordinate>$left_high[$dimension];
			}
		}		
	}
	$leftTree->[2] = \@left_low;
	$leftTree->[3] = \@left_high;

	my (@right_low,@right_high);
	for (;$serial<@sortedValues;$serial++) 
	{
		push @{$rightTree->[1]}, $sortedValues[$serial];
				
		for (my $dimension=0;$dimension<@$highest;$dimension++)
		{
			my $coordinate = $sortedValues[$serial]->[$dimension+1];
			
			if(!defined $right_low[$dimension])
			{
				$right_low[$dimension] = $coordinate;				
			}
			else
			{
				$right_low[$dimension] = $coordinate if $coordinate<$right_low[$dimension];
			}
			
			if(!defined $right_high[$dimension])
			{
				$right_high[$dimension] = $coordinate;				
			}
			else
			{
				$right_high[$dimension] = $coordinate if $coordinate>$right_high[$dimension];
			}
		}				
	}
	$rightTree->[2] = \@right_low;
	$rightTree->[3] = \@right_high;
	
	$medianValue = $sortedValues[$bucketSize/2];
	
	$tree->[0] = 1;
	$tree->[1] = [$leftTree,$rightTree];
	$tree->[2] = $bestDimension;
	$tree->[3] = ${$medianValue}[$bestDimension+1];	
	$tree->[4] = [$sortedValues[0]->[$bestDimension+1],$sortedValues[$serial-1]->[$bestDimension+1]];
	
} # splitBucket

sub nearest
{
	my ($self, $query,$k) = @_;
	my $nnb_heap = Heap::Simple::Perl->new(order => ">", elements => [Array => 0]);
	my $box_heap = Heap::Simple::Perl->new(order => "<", elements => [Array => 0]); 
	 
	# initialize the k nearest neighbors array.
	my $max = $self->{infinity};
	for(my $i=0;$i<$k;$i++)
	{
		$nnb_heap->insert([$max, -1]); # '-1' is the initial index of the point
	}
	
	# if the point is outside the whole data set, compute the distance.
	my $low = $self->{box}->[0];
	my $high = $self->{box}->[1];
	my $box_dist = 0;
	for(my $i=0;$i<@$low;$i++)
	{
		if($query->[$i]<$low->[$i])
		{
			$box_dist += ($low->[$i]-$query->[$i])**2;
		}
		elsif($query->[$i]>$high->[$i])
		{
			$box_dist += ($query->[$i]-$high->[$i])**2;	
		}	
	}
		
		
	my $tree = $self->{root};
	$box_heap->insert([$box_dist, $tree]); # enqueue the root
	while ($box_heap->first)
	{
		my $top_box = $box_heap->extract_min;
		my $next_dist = $top_box->[0];
		
		my $top_nnb = $nnb_heap->top;
		my $nnb_dist = $top_nnb->[0];
		
		last if($nnb_dist<$next_dist);
				
		$tree = $top_box->[1];
		while($tree->[0]==1) # search the internal node
		{
			my $cut_dim = $tree->[2];
			my $cut_v = $tree->[3];
			my $cut_diff = $query->[$cut_dim]-$cut_v;
			if($cut_diff<0) # the left
	 		{
				my $box_diff = $tree->[4]->[0]-$query->[$cut_dim];
				$box_diff = 0 if($box_diff<0);
				my $new_dist = $box_dist+($cut_diff**2-$box_diff**2);
				my $high_side = $tree->[1]->[1];
				$box_heap->insert([$new_dist, $high_side]); # enqueue the high side
							
				$tree = $tree->[1]->[0]; # the left						
			} 		
			else # the right
	 		{
				my $box_diff = $query->[$cut_dim]-$tree->[4]->[1];
				$box_diff = 0 if($box_diff<0);
				my $new_dist = $box_dist+($cut_diff**2-$box_diff**2);
				my $low_side = $tree->[1]->[0];
				$box_heap->insert([$new_dist, $low_side]);  # enqueue the low side					
				
				$tree = $tree->[1]->[1]; # the right					
			} 	
		}
		
		if ($tree->[0]==0) # search the points in the bucket
		{			
			my $point = $tree->[1];	
			for(my $i=0;$i<@$point;$i++)
			{
				my $dist = 0;
				for(my $j=0;$j<@$query;$j++)
				{
					$dist += ($query->[$j]-$point->[$i]->[$j+1])**2;
					last if($dist>$nnb_heap->first->[0]);
				}		
				
					
				if($dist<$nnb_heap->first->[0])
				{
					$nnb_heap->extract_min;	# remove the bigger one.
					my $id = $point->[$i]->[0];
					$nnb_heap->insert([$dist,$id]); # add an smaller one to the list
				}
			}	
		} # end of search the bucket		
	} # end of search the tree
	
	my @k_nnb;
	for(my $j=$k;$j>0;$j--)
	{
		my $nnb = $nnb_heap->extract_top;
		push (@k_nnb,$nnb);
	}	
	
	return \@k_nnb;	
}

1;


__END__
