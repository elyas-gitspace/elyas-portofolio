# ===================================================================
# variables.tf — LE CAHIER DES CHARGES
#
# C'est ici qu'on définit toutes les variables réutilisables
# Au lieu d'écrire "eu-west-3" partout dans tous les fichiers,
# on le définit UNE FOIS ici et on l'utilise partout avec var.aws_region
#
# C'est comme les constantes en JavaScript :
# const REGION = "eu-west-3"
# ===================================================================


# La région AWS où tout sera créé
# eu-west-3 = Paris — logique pour un portfolio FR 🗼
variable "aws_region" {
  description = "Région AWS principale"
  type        = string
  default     = "eu-west-3"
}

# Le nom du bucket S3 qui va stocker ton site React
# ⚠️ Les noms de buckets S3 sont UNIQUES dans le monde entier
# Si quelqu'un a déjà pris "portfolio-elyas-frontend", faut changer le nom
variable "s3_bucket_name" {
  description = "Nom du bucket S3 pour le frontend"
  type        = string
  default     = "portfolio-elyas-frontend"
}
