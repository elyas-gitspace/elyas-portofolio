# ===================================================================
# modules/s3/main.tf — L'OUVRIER S3
#
# Ce module crée le bucket S3 qui stocke ton site React buildé
#
# C'est quoi S3 ?
# C'est un service de stockage de fichiers sur AWS
# Imagine un disque dur sur internet, accessible de partout
# Ton build React (HTML/CSS/JS) sera stocké là-dedans
# et CloudFront ira le chercher pour le servir aux visiteurs
# ===================================================================


# LE BUCKET S3
# C'est la "boîte" qui va contenir tous tes fichiers
resource "aws_s3_bucket" "frontend" {
  bucket = var.bucket_name
  # var.bucket_name = "portfolio-elyas-frontend" (depuis main.tf)
}


# BLOQUER L'ACCÈS PUBLIC
# Par défaut on bloque tout accès public direct au bucket
# Les gens pourront PAS accéder à ton bucket directement via son URL
# Ils passeront OBLIGATOIREMENT par CloudFront
#
# C'est comme un entrepôt privé — les clients rentrent pas dedans
# ils passent par le magasin (CloudFront) qui va chercher les produits
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true  # bloque les ACL publiques
  block_public_policy     = true  # bloque les policies publiques
  ignore_public_acls      = true  # ignore les ACL publiques existantes
  restrict_public_buckets = true  # restreint l'accès public total
}


# OAC — ORIGIN ACCESS CONTROL
# C'est le "badge" qui autorise CloudFront à lire dans ton bucket S3
# Sans ce badge, CloudFront peut pas accéder aux fichiers
#
# C'est comme un badge d'accès entre le magasin et l'entrepôt
# Le magasin (CloudFront) doit badger pour entrer dans l'entrepôt (S3)
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.bucket_name}-oac"
  description                       = "OAC pour le portfolio S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"   # toujours signer les requêtes
  signing_protocol                  = "sigv4"    # protocole de signature AWS
}


# LA POLICY DU BUCKET
# On définit QUI a le droit de lire les fichiers dans le bucket
# Ici on dit : "seul CloudFront peut lire les fichiers"
data "aws_iam_policy_document" "s3_cf_policy" {
  statement {
    actions   = ["s3:GetObject"]  # droit de LIRE les fichiers
    resources = ["${aws_s3_bucket.frontend.arn}/*"]
    # arn = l'identifiant unique du bucket sur AWS
    # /* = tous les fichiers dans le bucket

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
      # seul CloudFront est autorisé
    }
  }
}

# On applique la policy au bucket
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.s3_cf_policy.json
}


# ===================================================================
# OUTPUTS — ce que ce module expose aux autres modules
# main.tf en a besoin pour connecter S3 à CloudFront
# ===================================================================
output "bucket_id" {
  value = aws_s3_bucket.frontend.id
  # ex: "portfolio-elyas-frontend"
}

output "bucket_arn" {
  value = aws_s3_bucket.frontend.arn
  # ex: "arn:aws:s3:::portfolio-elyas-frontend"
}

output "bucket_regional_domain" {
  value = aws_s3_bucket.frontend.bucket_regional_domain_name
  # ex: "portfolio-elyas-frontend.s3.eu-west-3.amazonaws.com"
  # CloudFront utilise cette adresse pour aller chercher les fichiers
}

output "oac_id" {
  value = aws_cloudfront_origin_access_control.oac.id
  # l'ID du badge d'accès, CloudFront en a besoin
}


# ===================================================================
# VARIABLES — ce que main.tf doit passer à ce module
# ===================================================================
variable "bucket_name" {
  type        = string
  description = "Le nom du bucket S3"
}
