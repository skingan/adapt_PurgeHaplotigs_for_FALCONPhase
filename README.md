# adapt_PurgeHaplotigs_for_FALCONPhase
Convert output of purge haplotigs to format compatible with FALCON-Phase

# Scope
[Purge haplotigs](https://bitbucket.org/mroachawri/purge_haplotigs) is a method for identifying haplotigs in PacBio genome assemblies, such as those generated with [FALCON-Unzip](https://github.com/PacificBiosciences/pb-assembly). The method analyzes read coverage and sequence alignments to categorize primary contigs as haplotigs. Haplotytic primary contigs often occur when haplotype divergence is high (~5% or greater, depending on assembly parameters).

This script renames the haplotigs identified by purge haplotigs using the nomenclature of FALCON-Unzip. Repeat contigs are discarded.

This script makes the output of purge haplotigs compatible with [FALCON-Phase](https://github.com/PacificBiosciences/pb-falcon-phase).

# Usage
`renamePurgedHaplotigs.pl curated.fasta curated.haplotigs.fasta cns_h_ctg.fasta`

# Input
`curated.fasta` - curated primary contigs, output from purge haplotigs

`curated.haplotigs.fasta` - curated haplotigs, output from purge haplotigs, "new haplotigs"

`cns_h_ctg.fasta` - original haplotigs output from FALCON-Unzip

# Output
`curated.haplotigs.renamed.fasta` - curated haplotigs renamed in Unzip haplotig style (e.g. 000123F_001)

Log of original and new names plus omitted repeat contigs is printed to stdout.

# Dependencies
`perl`

`samtools`
