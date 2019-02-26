#! /usr/bin/perl

use Modern::Perl;
use Catmandu;
use Data::Dumper;

# on définit les zones et sous-zones que l'on souhaite extraire
my @subd = qw(j x y z);
my @unimarc_fields = ( 
    {
        tag => 600,
        point_acces => ['a', 'b', 'c', 'd', 'f', 'g', 'p', @subd]
    },
    {
        tag => 601,
        point_acces => ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', @subd]
    },
    {
        tag => 604,
        point_acces => ['a', 'b', 'f', 't', @subd]
    },
    {
        tag => 605,
        point_acces => ['a', 'h', 'i', @subd]
    },
    {
        tag => 606,
        point_acces => ['a', @subd]
    },
    {
        tag => 607,
        point_acces => ['a', @subd]
    },
    {
        tag => 608,
        point_acces => ['a', @subd]
    },
    {
        tag => 609,
        point_acces => ['a', @subd]
    },
    {
        tag => 615,
        point_acces => ['a', @subd]
    },
    {
        tag => 676,
        point_acces => ['a', @subd]
    },
    {
        tag => 679,
        point_acces => ['a', @subd]
    },
    {
        tag => 686,
        point_acces => ['a', @subd]
    }
);
 
my $importer = Catmandu->importer('MARC', type => 'XML', file => 'input/sample.xml', fix => 'fix/etape2.fix');
my $exporter = Catmandu->exporter('CSV', file => 'etape2.csv');

$importer->each(sub {
    my $data = shift;
    
    # on crée un libellé "collection" unique
    if ( $data->{coll_lib4} ne 'INC') {
        $data->{collection} = $data->{coll_lib1} . " - " . $data->{coll_lib2} . " - " . $data->{coll_lib3} . " - " . $data->{coll_lib4};
    } elsif ( $data->{coll_lib3} ne 'INC' ) {
        $data->{collection} = $data->{coll_lib1} . " - " . $data->{coll_lib2} . " - " . $data->{coll_lib3};
    } elsif ( $data->{coll_lib2} ne 'INC' ) {
        $data->{collection} = $data->{coll_lib1} . " - " . $data->{coll_lib2};
    } elsif ( $data->{coll_lib1} ) {
        $data->{collection} = $data->{coll_lib1};
    }
    
    # on met la date de dernière transaction (801$c) au format AAAA-MM-DD
    if ( $data->{date_transaction} ) {
        my ($year, $month, $day) = ( $data->{date_transaction} =~ m/(\d{4})(\d{2})(\d{2})/ );
        $data->{date_transaction} = $year . "-" . $month . "-" . $day;
    }
    
    # si la notice comporte au moins une zone 6XX, on l'extrait
    if ( $data->{f6XX} eq 'ok' ) {
        foreach my $field ( @{$data->{record}} ) {                         # pour chaque champ unimarc de la notice...
            my $field_tag = @{$field}[0];
            if ( $field_tag ne 'LDR' ) {
                foreach my $unimarc_field (@unimarc_fields) {             # ... on vérifie s'il correspond à l'un des champs que l'on a choisi d'extraire...
                    if ( $field_tag == $unimarc_field->{tag} ) {
                        my @subfields = @{$unimarc_field->{point_acces}};           
                        my $subject = {};                                 # ... si oui, on crée une structure de données "subject" dans laquelle on va stocker l'extraction...
                        $subject->{biblionumber} = $data->{biblionumber};
                        $subject->{collection} = $data->{collection};
                        $subject->{collection} = $data->{collection};
                        $subject->{collection1} = $data->{coll_lib1};
                        $subject->{collection2} = $data->{coll_lib2};
                        $subject->{collection3} = $data->{coll_lib3};
                        $subject->{collection4} = $data->{coll_lib4};
                        $subject->{support} = $data->{support};
                        $subject->{agence_cat} = $data->{agence_cat};
                        $subject->{date_transaction} = $data->{date_transaction};
                        
                        my $n = scalar(@$field);                        # on extrait les valeurs des sous-zones spécifiées
                        my $analyse = {};
                        foreach my $subfield (@subfields) {
                            my $i = 3;   
                            while ( $i < $n) {
                                if ( @{$field}[$i] eq $subfield ) {
                                    $i++;
                                    $analyse->{$subfield} = @{$field}[$i];
                                    $i++;
                                } else {
                                    $i = $i + 2;
                                }
                            }
                        }
                    
                                              
                        my @to_join;
                        foreach my $subfield (@{$unimarc_field->{point_acces}}) {
                             if ( $analyse->{$subfield}) {
                                 push @to_join, $analyse->{$subfield};
                             }
                        }
                        $subject->{point_acces} = join " - ", @to_join;
                        
                        
                        if ( $analyse->{b} ) {
                            if ( $analyse->{f} ) {
                                $subject->{element_initial} = $analyse->{a} . " " . $analyse->{b} . " " . $analyse->{f};
                            } else {
                                $subject->{element_initial} = $analyse->{a} . " " . $analyse->{b};
                            }
                        } else {
                            $subject->{element_initial} = $analyse->{a};
                        }
                        $subject->{subd_forme} = $analyse->{j};
                        $subject->{subd_sujet} = $analyse->{x};
                        $subject->{subd_geo} = $analyse->{y};
                        $subject->{subd_chrono} = $analyse->{z};
                        $subject->{unimarc} = "f" . $unimarc_field->{tag};          
        
                        my @csv_columns = qw( biblionumber collection collection1 collection2 collection3 collection4 support point_acces element_initial subd_geo subd_chrono subd_sujet subd_forme agence_cat unimarc);
                        foreach my $column (@csv_columns) {
                            if ( !$subject->{$column}) {
                                $subject->{$column} = 'ABS';
                            }
                        }

                        $exporter->add($subject);

                    }
                }
            }
        }
    
    # en l'absence de zone 6XX, on effectue tout de même un enregistrement de la notice, pour savoir qu'elle ne comporte aucune point_acces
    } else {
        my $subject = {};
        my $analyse = {};
        $subject->{biblionumber} = $data->{biblionumber};
        $subject->{collection} = $data->{collection};
        $subject->{collection1} = $data->{coll_lib1};
        $subject->{collection2} = $data->{coll_lib2};
        $subject->{collection3} = $data->{coll_lib3};
        $subject->{collection4} = $data->{coll_lib4};
        $subject->{support} = $data->{support};
        $subject->{agence_cat} = $data->{agence_cat};
        $subject->{date_transaction} = $data->{date_transaction};

        my @csv_columns = qw( biblionumber collection collection1 collection2 collection3 collection4 support point_acces element_initial subd_geo subd_chrono subd_sujet subd_forme agence_cat unimarc);
        foreach my $column (@csv_columns) {
            if ( !$subject->{$column}) {
                $subject->{$column} = 'ABS';
            }
        }

        $exporter->add($subject);
    }    
});
