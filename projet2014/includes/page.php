<?php
/* Classe représentant une page (pour résoudre les portées
   de variables.
   Par Xavier Van de Woestyne et Paul Laforgue 
   Groupe 3

  Le contenu d'une page doit être défini dans _layout
  pour faciliter le relais d'information. 
  la variable $this->bdd est une instance singleton 
  de PDO
 */
abstract class Page{
  /* Fonction d'initialisation d'une page */
  abstract function initialize();
  /* Instance de PDO */
  protected $bdd; 
  public function __construct(){
    $this->bdd = 
      new PDO('pgsql:host='.HOST.';dbname='.DBNAME, ROOT, PASS);
    initialize();
  }
}
?>