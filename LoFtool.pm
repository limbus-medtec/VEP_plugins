=head1 LICENSE
                                                                                                                     
 Copyright (c) 1999-2015 The European Bioinformatics Institute and
 Genome Research Limited.  All rights reserved.                                                                      
                                                                                                                     
 This software is distributed under a modified Apache license.                                                       
 For license details, please see

   http://www.ensembl.org/info/about/code_licence.html                                                               
                                                                                                                     
=head1 CONTACT                                                                                                       

 William McLaren <wm2@ebi.ac.uk>
    
=cut

=head1 NAME

 UpDownDistance

=head1 SYNOPSIS

 mv LoFtool.pm ~/.vep/Plugins
 mv LoFtool_scores.txt ~/.vep/Plugins
 perl variant_effect_predictor.pl -i variants.vcf --plugin LoFtool

=head1 DESCRIPTION

 Add LoFtool scores to the VEP output.
 The LoFtool_scores.txt file is found alongside the plugin in the
 VEP_plugins GitHub repo.

 To use another scores file, add it as a parameter i.e.

 perl variant_effect_predictor.pl -i variants.vcf --plugin LoFtool,scores_file.txt

=cut

package LoFtool;

use strict;
use warnings;

use DBI;

use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);

sub new {
  my $class = shift;

  my $self = $class->SUPER::new(@_);
  
  my $file = $self->params->[0];

  if(!$file) {
    my $plugin_dir = $INC{'LoFtool.pm'};
    $plugin_dir =~ s/LoFtool\.pm//i;
    $file = $plugin_dir.'/LoFtool_scores.txt';
  }
  
  die("ERROR: LoFtool scores file $file not found\n") unless $file && -e $file;
  
  open IN, $file;
  my %scores;
  
  while(<IN>) {
    chomp;
    my ($gene, $score) = split;
    next if $score eq 'LoFtool_percentile';
    $scores{lc($gene)} = sprintf("%g", $score);
  }
  
  close IN;
  
  die("ERROR: No scores read from $file\n") unless scalar keys %scores;
  
  $self->{scores} = \%scores;
  
  return $self;
}

sub feature_types {
  return ['Transcript'];
}

sub get_header_info {
  return {
    LoFtool => "LoFtool score for gene"
  };
}

sub run {
  my $self = shift;
  my $tva = shift;
  
  my $symbol = $tva->transcript->{_gene_symbol} || $tva->transcript->{_gene_hgnc};
  return {} unless $symbol;
  
  return $self->{scores}->{lc($symbol)} ? { LoFtool => $self->{scores}->{lc($symbol)}} : {};
}

1;
