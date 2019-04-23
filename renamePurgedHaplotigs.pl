#!/usr/bin/perl -w

####################################################################################################
#
#		Sarah B. Kingan
#		Pacific Biosciences
#		22 January 2019
#
#		Title: renamePurgedHaplotigs.pl
#
#		Project: FALCON-Phase
#	
#		Input: curated primary and haplotigs from purge haplotigs
#
#		Output: new haplotig file, log to stout
#			
#
####################################################################################################

use strict;
use warnings;

my $usage = "renamePurgedHaplotigs.pl curated.fasta curated.haplotigs.fasta cns_h_ctg.fasta\n";


###################
### INPUT FILES ###
###################

my $cur_p_fasta = shift(@ARGV) or die $usage;
my $cur_h_fasta = shift(@ARGV) or die $usage;
my $orig_h_fasta = shift(@ARGV) or die $usage;

# index files
my $cur_h_fai = $cur_h_fasta.".fai";
my $orig_h_fai = $orig_h_fasta.".fai";

####################
### OUTPUT FILES ###
####################
my $cur_rename_h_fasta = "curated.haplotigs.renamed.fasta";

# index fasta files if .fai files don't exist
unless (-e $orig_h_fasta.".fai") {
	`samtools faidx $orig_h_fasta`;
}
unless (-e $cur_h_fasta.".fai") {
	`samtools faidx $cur_h_fasta`;
}

# make array of original haplotig IDs, needed to rename new haplotigs
my @orig_haplotigs;
open (OGH, $orig_h_fai) or die "Could not open file '$cur_h_fai'";
while (my $line = <OGH>) {
	chomp $line;
	my @line_array = split("\t", $line);
	$line_array[0] =~ s/\|arrow//g; # strip arrow suffix
	push @orig_haplotigs, $line_array[0]; 
}
my @s = split("_", $orig_haplotigs[0]);
my $haplotig_suffix_digits = length($s[1]);
close OGH;


# compile hash with new curated haplotig IDs grouped by primary
my %new_haplotigs;
# key = $p
# value = string of $h
open (CHF, $cur_h_fasta) or die "Could not open file '$cur_p_fasta'";
while (my $line = <CHF>) {
	if ($line =~ /^>/) {
		my $p=0;
		my $h=0;
		if ($line =~ />([0-9]{6}F) HAPLOTIG.*([0-9]{6}F)_PRIMARY/) {
			$h = $1;
			$p = $2;

# add new haplotig to list for primary contig
			if (exists $new_haplotigs{$p}) {
				$new_haplotigs{$p} .= ",".$h;
			}
			else {
				$new_haplotigs{$p} = $h;
			}
		}
	}
}
close CHF;


# compile list of original haplotigs for primary contig
# these arrays are for renaming
my @cur_hap_id = ();
my @unzip_style_id = ();
foreach my $p (sort keys %new_haplotigs) {

	# haplotigs identified by purge haplotigs
	my @new_h = split(",", $new_haplotigs{$p});
	push(@cur_hap_id, @new_h);
	my $n = scalar(@new_h);

	# list of haplotigs for that primary contig, original unzip output
	# this is needed to rename newly assigned haplotigs
	my @old_h = ();
	foreach my $h (@orig_haplotigs) {
		if ($h =~ $p) {
			push(@old_h, $h);
		}
	}

# set max suffix, can be "0" if no haplotigs are present
	my $suffix = 0;
	if (scalar @old_h > 0) {
		 $suffix = get_max_suffix(@old_h);
	}
	
	my $ref = get_next_haplotig_ids($suffix, $n, $p, $haplotig_suffix_digits);
	push(@unzip_style_id, @$ref);
}


# print fasta file with original haplotigs plus renamed curated haplotigs, repeats omitted
`cat $orig_h_fasta | sed 's/|arrow//g' > $cur_rename_h_fasta`;
open (RHF, '>>', $cur_rename_h_fasta) or die "Could not open file '$cur_rename_h_fasta'";
open (CHF, $cur_h_fasta) or die "Could not open file '$cur_h_fasta'";
my $repeat = 0;
while (my $line = <CHF>) {
	if ($line =~ /^>/) {
		if ($line =~ />([0-9]{6}F) HAPLOTIG.*([0-9]{6}F)_PRIMARY/) {
			$repeat = 0;
			my $old = $1;
			for (my $i = 0; $i < scalar(@cur_hap_id); $i++) {
				if ($cur_hap_id[$i] eq $old) {
					print RHF ">", $unzip_style_id[$i], "\n";
					print "renaming $cur_hap_id[$i] as $unzip_style_id[$i]\n";
				}
			}
		}
		else {
			$repeat = 1;
			chomp $line;
			print "excluding $line from output\n";
		}
	}
	elsif ($repeat == 0) {
		print RHF $line;
	}
}
close RHF;
close CHF;

sub get_max_suffix {
	my @haplotigs = @_;
	my @sorted_haplotigs = sort @haplotigs;
	my $max_haplotig = pop @sorted_haplotigs;
	my @name = split("_", $max_haplotig);
	return $name[1];
}


sub get_next_haplotig_ids {
	my ($suffix, $n, $p, $d) = (@_);
	my @next_ids = ();
	my $f = "%"."0".$d."d";
	for (my $i = 0; $i < $n; $i++) {
		my $s = sprintf($f, $suffix + $i + 1);
		push(@next_ids, ($p."_".$s));
	}
	return \@next_ids;
}


exit;


