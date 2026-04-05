# ===================================================================
# main.tf — LE CHEF D'ORCHESTRE
#
# Ce fichier dit à Terraform QUOI créer sur AWS
# Il appelle les modules (les ouvriers spécialisés)
# qui savent EUX comment créer chaque ressource
#
# C'est comme une commande McDonald's :
# tu dis "je veux un BigMac + frites + coca"
# et la cuisine (les modules) s'occupe de tout préparer
# ===================================================================


# ===================================================================
# CONFIGURATION DE TERRAFORM
# On dit à Terraform quelle version utiliser et quel "plugin" AWS
# ===================================================================
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      # Le plugin AWS pour Terraform
      # Sans lui Terraform sait pas parler à AWS
      # C'est comme un traducteur entre Terraform et AWS
    }
  }

  # LE STATE TERRAFORM
  # Terraform garde une "photo" de tout ce qu'il a créé
  # dans un fichier appelé "state"
  # On le stocke dans S3 pour pas le perdre si ton PC plante
  # C'est comme sauvegarder ta partie de jeu vidéo sur le cloud
  # plutôt que sur ta console locale
  #
  # ⚠️ CE BUCKET DOIT ÊTRE CRÉÉ MANUELLEMENT AVANT de faire terraform init
  # Lance cette commande d'abord :
  # aws s3 mb s3://portfolio-elyas-terraform-state --region eu-west-3
  backend "s3" {
    bucket = "portfolio-elyas-terraform-state"
    key    = "portfolio/terraform.tfstate"  # chemin du fichier dans le bucket
    region = "eu-west-3"
  }
}


# ===================================================================
# LE PROVIDER AWS
# On dit à Terraform dans quelle région AWS on veut créer les ressources
# eu-west-3 = Paris 🗼
# ===================================================================
provider "aws" {
  region = var.aws_region
  # var.aws_region = on va chercher la valeur dans variables.tf
  # c'est "eu-west-3" par défaut
}


# ===================================================================
# MODULE S3
# Crée le bucket S3 qui va stocker les fichiers React buildés
# (le HTML, CSS, JS que le navigateur va télécharger)
#
# C'est comme une clé USB sur internet qui stocke ton site
# ===================================================================
module "s3" {
  source      = "./modules/s3"
  # source = où trouver le code du module (le dossier modules/s3/)

  bucket_name = var.s3_bucket_name
  # on passe le nom du bucket depuis variables.tf
}


# ===================================================================
# MODULE LAMBDA
# Crée la fonction Lambda qui va faire tourner handler.js
#
# C'est le serveur qui se réveille UNIQUEMENT quand une requête arrive
# et se rendort après — comme un livreur qui sort que quand y'a une livraison
# ===================================================================
module "lambda" {
  source        = "./modules/lambda"

  function_name = "portfolio-api"         # le nom de ta Lambda sur AWS
  handler       = "src/handler.handler"   # fichier.nomDeLaFonction exportée
  # "src/handler" = le fichier src/handler.js
  # ".handler"    = exports.handler dans ce fichier
  runtime       = "nodejs20.x"            # version de Node.js sur AWS
  zip_path      = "../backend/function.zip"
  # le chemin vers le zip du backend
  # (on le crée juste avant de faire terraform apply)
}


# ===================================================================
# MODULE API GATEWAY
# Crée la "porte d'entrée" HTTP vers ta Lambda
#
# Lambda comprend pas le HTTP nativement
# API Gateway fait la traduction :
# requête HTTP → format Lambda → réponse Lambda → réponse HTTP
#
# C'est le serveur du resto qui prend ta commande
# et la transmet à la cuisine (Lambda)
# ===================================================================
module "api_gateway" {
  source      = "./modules/api_gateway"

  lambda_arn  = module.lambda.lambda_arn
  # l'identifiant unique de ta Lambda sur AWS
  # module.lambda.lambda_arn = on récupère cet output depuis le module lambda

  lambda_name = module.lambda.lambda_name
  # le nom de la Lambda, utilisé pour les permissions

  api_name    = "portfolio-api"           # le nom de ton API sur AWS
}


# ===================================================================
# MODULE CLOUDFRONT
# Crée le CDN qui va distribuer ton site partout dans le monde
# ET qui fait le tri entre les requêtes :
# → "/"      va vers S3 (le React)
# → "/api/*" va vers API Gateway (le backend)
#
# C'est le videur + livreur ultra rapide dont on a parlé
# ===================================================================
module "cloudfront" {
  source           = "./modules/cloudfront"

  s3_bucket_id     = module.s3.bucket_id
  # l'ID du bucket S3 créé par le module s3

  s3_bucket_domain = module.s3.bucket_regional_domain
  # l'adresse du bucket S3 (ex: portfolio-elyas-frontend.s3.amazonaws.com)

  s3_oac_id        = module.s3.oac_id
  # l'ID du "badge" qui autorise CloudFront à lire dans S3
  # (on en parle dans le module S3)

  api_gateway_url  = module.api_gateway.api_url
  # l'URL de l'API Gateway pour que CloudFront sache où rediriger /api/*
}


# ===================================================================
# OUTPUTS — ce que Terraform affiche à la fin de terraform apply
# Pour que tu saches les URLs et IDs importants
# ===================================================================
output "cloudfront_url" {
  description = "L'URL de ton site (à ouvrir dans le navigateur)"
  value       = "https://${module.cloudfront.distribution_domain}"
}

output "cloudfront_distribution_id" {
  description = "L'ID CloudFront (nécessaire pour le CI/CD GitHub Actions)"
  value       = module.cloudfront.distribution_id
}

output "api_url" {
  description = "L'URL de l'API Gateway"
  value       = module.api_gateway.api_url
}