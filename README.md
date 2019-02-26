# Extraction de l'indexation présente dans les notices bibliographiques

On procède en deux étapes :
- dans un premier temps, on cherche à établir comment est structurée l’indexation : quels sont les champs utilisés ? Quelles sont les notices concernées, en fonction du support, de l’agence de catalogage et de la nature de la collection ? Comment affiner les trois groupes de notices précédemment établis ? On part en effet du principe que, dans un contexte de récupération des métadonnées, on ne connaît pas / plus assez nos notices pour pouvoir se passer de cette étape préalable,
- dans un second temps, on extrait, en fonction des groupes de notices redéfinis, les termes indexés et on analyse en particulier leur dispersion.

On utilise pour cela deux scripts Perl, qui s'appuient très largement sur le projet Catmandu.

## Etape 1 : recherche des zones unimarc utilisées pour l'indexation
Un premier script va extraire, pour chaque notice bibliographique du catalogue, chaque occurrence des étiquettes de zone et les pousser sous forme de liste, bloc par bloc, dans un index Elasticsearch. L'intérêt de recourir à Elasticsearch est de pouvoir analyser simplement des listes, ce qui serait très fastidieux avec un logiciel de type tableur.

Comme on considère que l'indexation se trouve dans le bloc 6XX, on concentrera ensuite l'analyse sur ce dernier.
L'analyse montre que sont les plus utilisées pour l'indexation les zones 600, 601, 606, 607, 608, 609, 676, 679 et 686.

## Etape 2 : extraction des termes utilisés pour l'indexation
Un second script extrait chacune des zones 6XX identifiées comme les plus souvent utilisées (soit 600, 601, 606, 607, 608, 609, 676, 679 et 686) et les reporter dans un fichier csv comprenant les colonnes suivantes :
- identifiant de la notice          =>      001
- support                           =>      099$t
- agence de catalogage	            =>	    801$b,
- collection	                      =>	    995$h,
- zone unimarc	                    =>	    on reprend l’étiquette de la zone unimarc utilisée (600, 601, ...)
- point d’accès	                    =>	    concaténation des valeurs de tous les sous-champs dont l’étiquette est une lettre ($a, $b, …) et non un chiffre,
- élément initial	                  =>      indexation sans les subdivisions (chronologiques, géographiques, sujet, forme)
- subdivision de forme	            =>	    6XX$j
- subdivision sujet	                =>	    6XX$x
- subdivision chronologique	        =>	    6XX$z
- subdivision géographique	        =>	    6XX$y

Chaque ligne du fichier correspond donc à une indexation. Il peut y avoir plusieurs lignes pour une même notice.
Une fois le fichier produit, on peut filtrer facilement sur les collections qui nous intéressent et effectuer des analyses avec un outil tableur comme LibreOffice Calc ou Microsoft Excel.
