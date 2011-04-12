#!/usr/bin/perl -w
use Carp qw| cluck :DEFAULT |;
use File::Temp qw||;
use Scalar::Util qw||;
#use strict; # please

# lkajan: careful with the assignments here because the BEGIN block is executed /before/ the assignment as so we could overwrite the value that comes from the cmd line when the assignment takes place
our $debug ||= 0;
my $infile; # input file
my $psicfile; # if defined, final psic output is copied there
our $quiet ||= 0;
my $run ||= 0; #whether we ran this before
my $use_blastfile;
my $workDir; # psic output directory

my $blastdata_uniref;
my $blastpgp_seg_filter ||= 'F';
my $blastpgp_processors ||= 1;
my $min_seqlen ||= 50;
my $psic_matrix;

BEGIN {
	use Config::IniFiles;
	use Getopt::Long;
	use Pod::Usage;
	my $help = 0;
	my $man = 0;

	my @buf = @ARGV;

	if( !Getopt::Long::GetOptionsFromArray( \@buf,
		'infile=s' => \$infile,
		'workDir=s' => \$workDir,
		'run=i' => \$run,
		'psicfile=s' => \$psicfile,
		'debug!' => \$debug,
		'help!' => \$help,
		'man!' => \$man,
		'min-seqlen=i' => \$min_seqlen,
		'quiet!' => \$quiet,
		'use-blastfile=s' => \$use_blastfile,
		#
		'blastdata_uniref=s' => \$blastdata_uniref,
		'blastpgp_seg_filter=s' => \$blastpgp_seg_filter,
		'blastpgp_processors|blastpgp-processors=i' => \$blastpgp_processors,
		'psic_matrix=s' => \$psic_matrix
	) )
	{
		warn("invalid options\n"); sleep 2;
		pod2usage(-exitval => 1, -verbose => 2);
	}

	if( $help ) { pod2usage(0); }
	if( $man ) { pod2usage(-exitval => 0, -verbose => 2); }
}

# STDERR was meant for this purpose, use warn() and die()
#select STDOUT; $| = 1;

#August 2, 2005
#This file will transform the blast files into form needed for PSIC predictions
#blast files need to be flag m-6 (blunt ends, no identities)

#it will also eliminate any sequences with sequence identity not in range of 30 to 94
#and with less than $min_seqlen residues aligning

$blastdata_uniref || die('no [blast]uniref');
if( $blastpgp_seg_filter !~ /^([FT])$/o ){ confess("value '$blastpgp_seg_filter is not valid for blastpgp_seg_filter'"); } $blastpgp_seg_filter = $1;
if( !Scalar::Util::looks_like_number( $blastpgp_processors ) ) { confess("value '$blastpgp_processors' is not valid for blastpgp_processors'"); }
if( !$psic_matrix || !-e $psic_matrix ){ die("no psic matrix"); }

$name = $infile;
$name =~ s/(.+\/)*//g;
$name =~ s/\.\d+\./\./;

$name =~ s/\.fasta//o;
$f_name = $name;
$blastfile = $name.".blast";
$clustal_file = $name.".clustal";
$psicinfile = $name.".psicin";
$psicout = $name.".psicout";
$finalpsic = $name.".out";

if (!(-e "$infile")){ die("No $infile found"); }

#first check that we have at least $min_seqlen residues to align
open (IN, "$infile");
@data = <IN>;
close IN;
my $file = uc("@data");
$file =~ s/\>.+\n//o;
$file =~ s/[^A-Z]//g;
my $seq = $file;
my %seq;
if($debug){ cluck($seq); }
my $number = length($seq);
if($debug){ cluck( "seqlen = $number" ); }
if( $number < $min_seqlen ){
	if( !$quiet ){ warn("Error: sequence is less than $min_seqlen aa in length: $number"); }
	exit(254);
}

if( !$workDir && !$psicfile ){ die("Error: no --workDir and no --psicfile specified - results would be lost.".( $debug ? '' : "\n" )); }
$workDir ||= File::Temp::tempdir( CLEANUP => !$debug );

if( $use_blastfile ){ my @cmd = ( 'cp', $use_blastfile, "$workDir/$blastfile" ); system( @cmd ) && confess( "@cmd failed");  }

if (-e  "$workDir/$finalpsic"){
#	`rm $workDir/$name.*`;
	warn( "$workDir/$finalpsic exists" );
	exit(0);
}
if (-e "$workDir/$psicout"){
	warn( "running with existing $workDir/$psicout\n" );
	$flag = 1;
}
elsif (-e "$workDir/$psicinfile"){
	warn( "running with existing $workDir/$psicinfile\n" );
	#$flag = 2;
	$flag = 3;
	#still need to get the sequence, otherwise all fails
}
elsif (-e "$workDir/$name.aln"){
	warn( "running with existing $workDir/$name.aln\n" );
	$flag = 3;
}
else{
	$flag = 4;
	#run blast
	# lkajan: attention, we may be calling ourselves recursively here, and we want to reuse the blast (with less stringent constraints) from the previous run!
	if( !-e "$workDir/$blastfile" ){
		#warn( "$workDir/$blastfile\n" );
		my $cmd = "blastpgp -F $blastpgp_seg_filter -a $blastpgp_processors -d $blastdata_uniref -i $infile -j 1 -e 0.001 -o $workDir/$blastfile -b 300 -v 0".( $quiet ? ' 2>/dev/null' : '' );
		if( $debug ) { warn( $cmd ); }
		system( $cmd ) && die( "'$cmd' failed: $!" );
	}
	else{
		if( !$quiet ){ warn( "Using existing Blast: $workDir/$blastfile\n" ); }
	}
	$size = 0;
	{
		my $cmd = "du -m '$workDir/$blastfile' 2>/dev/null";
		#1	conv_hssp2saf.pl
		$size = `$cmd` || die("'$cmd' failed");
	}
	$size =~ /^(\d+)/o; $size = $1;
	# lkajan 20110120: blast output bigger than 100MB - does that ever happen? - if it does, do we want to rerun blast only to get a small er file? - that certainly is the most expensive solution
	#if( $size and ($size > 100))
	#{
	#	$num = int(300*100/$size));
	#	warn( "Too big. Rerun $blastfile with $num aligns\n" );
	#	{
	#		my $cmd = "blastpgp -F $blastpgp_seg_filter -a $blastpgp_processors -d $blastdata_uniref -i $infile -j 1 -e 0.001 -o $workDir/$blastfile -b $num -v 0".( $quiet ? ' 2>/dev/null' : '' );
	#		if( $debug ) { warn( $cmd ); }
	#		system( $cmd ) && die( "'$cmd' failed: $!" );
	#	}
	#	$size = `du -m '$workDir/$blastfile' 2>/dev/null` || die("du failed");
	#	$size =~ /^(\d+)/o; $size = $1;
	#}
	open (IN, "<", "$workDir/$blastfile") || confess("failed to open '$workDir/$blastfile'");
	@data = <IN>;
	close IN;
	$file = "@data";
	$file_p = &checkBlast($file, $run, $blastdata_uniref, $infile, $workDir, $blastfile, $blastpgp_seg_filter, $blastpgp_processors );
	if ($file_p =~ /^failed/o ){
		if(!$quiet){ warn("Error: '$workDir/$blastfile': $file_p"); }
		exit(253);
	}		
	#if dealing with nonempty file
	if ($file =~ /\w/){
		if($debug){ warn( "processing blast" ); }
		@file = split (/\n >/o, $file_p);
		if( $debug ){ warn( (scalar(@file)-1)." hits found in '$workDir/$blastfile'"); }
		#now we need to get the sequences
		%seq = ();
		my $count = 1;
		open (CLUST, ">$workDir/$clustal_file") || confess( "failed to open '>$workDir/$clustal_file': $!" );
		$file[0] =~ s/(\d+)\s+letters//;
		$seq_length = $1;
		if (!($number == $seq_length)){
			confess( "Sequence length in blast $seq_length, doesn't agree with actual sequence length $number" );
		}
		$large = 0;
		print CLUST ">query\n".$seq."\n";
		foreach $l (1..@file-1){
			$line = $file[$l];
			# 
			if( $line !~ /\n  Identities = \d+\/(\d+) \((\d+)%\)/o ){ confess("no 'Identities' found in blast output"); }
			$id = $2;
			$length = $1;
			if (!$length){
				confess("line=$line id=$id");
			}
			if( $length < $min_seqlen ){
				#if($debug){ cluck("Alignment length shorter than $min_seqlen: $length"); }
				next;
			}
			if (($id > 94) or ($id < 30)){
				if ($id > 94){ $large++; }
				#if($debug){ warn("Seq %ID bad (>94 or <30): $id"); }
				next;
			}
			@sub = split (/Positives.+?\n/o, $line);
			$first = $sub[1];
			#get subject
			while( $first =~ /Sbjct\:\s+\d+\s+([A-Z\-]+)\s+\d+\s*?\n/o )
			{
				my $seqstr = $1;
				$first = substr($first, $+[0]); # $first = string after match
				if( defined( $seq{$count} )){ $seq{$count} .= $seqstr; } else { $seq{$count} = $seqstr; }
			}
			$seq{$count} =~ s/\-//go;
			print CLUST ">name$count\n".$seq{$count}."\n";
			$count++;			
			# lkajan: limit number of sequences that make into CLUST to 300 in this loop (to allow blast inputs with more in them but limit clustalw run times)
			if( $count > 300 ){ last; }
		}
	
		$total = keys %seq;
		if( $total != $count-1 ){ confess("total $total != count $count"); }
		if($debug){ cluck( "Total keys gotten = $total" ); }
		close CLUST;
		if( !$total ){
			# lkajan: we're here means hits are too short or are in the bad %identity range (too high or too low)
			unlink( "$workDir/$clustal_file" );
			if($debug){ cluck("No needed alignments exist for $clustal_file"); }
			if( !$run ){
				$return = &checkBlast('', 2, $blastdata_uniref, $infile, $workDir, $blastfile, $blastpgp_seg_filter, $blastpgp_processors );
				if ($return =~ /^failed/o){
					if(!$quiet){ warn("Error: '$workDir/$blastfile': $return"); }
					exit(253);
				}
				else
				{
					if($debug){ cluck( "rerunning using less stringent blast results in $workDir/$blastfile" ); }
					# lkajan: we have to reuse the blast results from the above checkBlast - so we have to pass down the workdir
					my @cmd = ( $0, @ARGV, '--run', 1, '--workDir', $workDir );
					if( $debug ) { warn("@cmd"); }
					exec( @cmd ) || die( "'@cmd' failed: $!");
				}
			}
			else{
				exit(253); # no blast hits
			}
		}
	}
}
if( $debug ) { warn("flag = $flag"); }
if ($flag >= 4){ 
	# clustalw is extremely talkative on STDOUT: "Sequences (182:819) Aligned. Score:  57"*
	my $infile = glob( "$workDir/$clustal_file" );
	my $cmd = qq|clustalw '-infile=$infile' >/dev/null|;
	if( $debug ) { warn( $cmd ); }
	system( $cmd ) && die( "'$cmd' failed: $!");
}
if( $flag >= 1 )
{
	%seq = ();
	open (IN, '<', "$workDir/$name.aln") || die "Can't open $workDir/$name.aln\n";
	foreach $line (<IN>){
		chomp($line);
		if ($line =~ /^CLUSTAL/o){ next; }
		if ($line ne ''){
			#|name215         ------------------------------------------TLAPNRTGPQCLEVSIPD|
			if( $line =~ /^(................)([A-Z-]+)$/o )
			{
				my( $name, $aln ) = ( $1, $2 );
				if( $name !~ /^(\S+)/o ){ confess("unexpected identified '$name'"); }
				$name = $1;
				if (exists $seq{$name}){ $seq{$name} .= $aln; }
				else{ $seq{$name} = $aln; }
			}
			#|                                    .:..  :::::* *  **.. *:** : : **    *   |
			elsif( $line !~ /^                /o ){ confess("unexpected line from clustalw '$line'"); }
		}
	}
	close IN;
}
if ($flag >= 3){
	open (OUT, ">$workDir/$psicinfile");
	print OUT "CLUSTAL\n\n";
	foreach $key (keys %seq)
	{
		print OUT '_' x (67-length($key)), $key, ' ', $seq{$key}, "\n";
	}
	close OUT;
}
if ($flag >=2){
	my @cmd = ( "psic", "$workDir/$psicinfile", $psic_matrix, "$workDir/$psicout" );
	if( $debug ) { warn("@cmd"); }
	system( @cmd ) && die( "'@cmd' failed: $!" );
}

open (IN, '<', "$workDir/$psicout") || die "File $workDir/$psicout doesn't exist\n";
open (OUT, ">", "$workDir/$finalpsic") || die "Can't open $workDir/$finalpsic\n";
my $count = 0;
my @query = split(//o, ( $seq{query} || confess("can not find query alignment line") ) );
$i = -2;

foreach $line (<IN>){
	if ($i == -2){
		$i++;
		next;
	}
	elsif ($i == -1){
		print OUT $line;
		$i++;
		next;
	}
	elsif ($query[$i] =~ /[A-Z]/o){ # non-gap
		$line =~ s/^\d+\s+//o;
		print OUT "$count $line";
		$count++;
		$i++;
	}
	else{ $i++; }
}
close IN;
close OUT;

$f_name =~ s/_query//o;

# lkajan: removed dependency on asci file for checking correct length of psic output - in order to make this script more usable in other work scenarios e.g. PP
if( $number != $count )
{
	confess( "wrong line length : sequence length $number vs psic $count" );
}
else{
	if( "$workDir/$finalpsic" ne "$workDir/$f_name.out" )
	{
		my @cmd = ( "mv", "$workDir/$finalpsic", "$workDir/$f_name.out" );
		if( $debug ){ warn("@cmd"); }
		system( @cmd ) && die( "'@cmd' failed: $!" );
	}
	if( $psicfile ){ system( 'cp', "$workDir/$f_name.out", $psicfile ) && confess("failed to cp '$workDir/$f_name.out' to '$psicfile'"); }
}

exit(0);

# END OF PROGRAM -------------------------------------------------------------

sub checkBlast{
	use strict;
	my( $file, $run, $__blastdata_uniref, $__infile, $__blastdir, $__blastfile, $__blastpgp_seg_filter, $__blastpgp_processors ) = @_;
	my $file_p;
	#check if there are hits
	if ($file =~ /No hits found/io){
		return "failed - no hits found";
	}
	elsif ( $file !~ /\w/ )
	{
		if ($run == 0){
			# lkajan: we get here if we get a badly formatted blast result - presumably from the command line. I think this should be lethal.
			confess( "Incorrect blast file: $__blastdir/$__blastfile" );
			#my $cmd = "blastpgp -F $__blastpgp_seg_filter -a $__blastpgp_processors -d $__blastdata_uniref -i $__infile -j 1 -e 0.001 -o $__blastdir/$__blastfile -b 100 -v 0".( $main::quiet ? ' 2>/dev/null' : '' );
			#if( $main::debug ) { warn($cmd); }
			#system( $cmd ) && die( "'$cmd' failed: $!" );
			#open (IN, "$__blastdir/$__blastfile");
			#my @data = <IN>;
			#close IN;
			#$file = "@data";
			#$file = &checkBlast($file, 1, $__blastdata_uniref, $__infile, $__blastdir, $__blastfile, $__blastpgp_seg_filter, $__blastpgp_processors );
		}
		elsif ($run == 2){ 	# lkajan: run=2 means no hits passed the length and %id thresholds - so we run blast letting more in
							# lkajan: in case this is successful this script re-runs itself in --run 1 mode
			if( !defined( $__blastdata_uniref ) ) { confess(); }
			my $cmd = "blastpgp -F $__blastpgp_seg_filter -a $__blastpgp_processors -d $__blastdata_uniref -i $__infile -j 2 -h 0.1 -e 0.1 -o $__blastdir/$__blastfile -b 500 -v 0".( $main::quiet ? ' 2>/dev/null' : '' );
			if( $main::debug ) { warn($cmd); }
			system( $cmd ) && die( "'$cmd' failed: $!" );
			open (IN, '<', "$__blastdir/$__blastfile");
			my @data = <IN>;
			close IN;
			$file = "@data";
			$file = &checkBlast($file, 1, $__blastdata_uniref, $__infile, $__blastdir, $__blastfile, $__blastpgp_seg_filter, $__blastpgp_processors );
		}
		else{
			return "failed";
		}
	}
	return $file;
}

__END__

=pod

=head1 NAME

runNewPSIC.pl

=head1 SYNOPSIS

runNewPSIC.pl [OPTION]

=head1 DESCRIPTION

runNewPSIC.pl - call psic with a clustalw alignment of sequences collected by blastpgp

 * blast hits with identity > 94% and < 30% are not used
 * hits shorter than --min-seqlen are not used

The remaining hits are used to construct an input file for clustalw.
psic is called with the clustalw alignment.
psic output is then reformatted I<leaving gaps out>.  Residue positions are numbered from I<0>.

=head1 OPTIONS

=over

=item --blastdata_uniref

=item --blastpgp-processors, --blastpgp_processors

=item --blastpgp_seg_filter

=item --debug

=item --help

=item --infile

=item --min-seqlen

Minimum input sequence length and minimum alignment length to retain blast hit.  Default: 50.

=item --psic_matrix

=item --psicfile

Final psic output is copied to this file if given

=item --quiet

No not print errors for ERRORS conditions below - exit value indicates type of problem. Redirect blast STDERR to /dev/null.

=item --run

Do not set - for internal use

=item --use-blastfile=I</path>

Use blast results from this file.  Blast is run automatically in case no file is given.  Default: unset.

=item --workDir

=back

=head1 ERRORS

=over

=item 253

Error: no blast hits

=item 254

Error: sequence length less than B<--min-seqlen>

=back

=cut

# vim:ai:ts=4:
