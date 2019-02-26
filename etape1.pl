#! /usr/bin/perl

use Modern::Perl;
use Catmandu;
use Search::Elasticsearch;

my $e = Search::Elasticsearch->new( nodes => 'localhost:9200');
 
my $importer = Catmandu->importer('MARC', type => 'XML', file => 'input/sample.xml', fix => 'fix/etape1.fix');

$importer->each(sub {
    my $data = shift; # voir un exemple de structure de données : output/etape1_data.txt
    #print Data::Dumper::Dumper($data);
    # on extrait l'étiquette de chacune des zones unimarc utilisées dans la notice
    foreach my $field ( @{$data->{record}} ) {
        my $tag = @$field[0];
        if ( $tag =~ m/^\d{3}$/) {
            my $block = substr $tag, 0, 1;
            $block = $block . 'XX';
            unless (grep $tag eq $_, @{$data->{$block}}) {
                push @{$data->{$block}}, $tag;
            }
        }
    }

    delete $data->{record};
    
    # on indexe la structure de données obtenue dans Elasticsearch
    # voir un exemple de structure de données en json : output/etape1_index.txt
    my $index = {
        index   => 'indexation_zones',
        type    => 'zones',
        id      => $data->{biblionumber}, 
        body    => $data
    };  
    #$e->index($index);
    print Data::Dumper::Dumper($index);
});
