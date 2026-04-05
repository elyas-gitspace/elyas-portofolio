# ===================================================================
# modules/cloudfront/main.tf — L'OUVRIER CLOUDFRONT
#
# Ce module crée le CDN qui :
# 1. Distribue ton site React depuis S3 à tous les visiteurs
# 2. Redirige les requêtes /api/* vers API Gateway
# 3. Accélère le site en mettant en cache les fichiers partout dans le monde
#
# Rappel : c'est le videur + livreur ultra rapide 🚀
# ===================================================================


resource "aws_cloudfront_distribution" "portfolio" {
  enabled             = true           # la distribution est active
  is_ipv6_enabled     = true           # supporte IPv6
  default_root_object = "index.html"   # quand on arrive sur "/" → sert index.html
  price_class         = "PriceClass_100"
  # PriceClass_100 = utilise seulement les serveurs Europe + USA
  # moins cher que d'utiliser tous les serveurs du monde
  # largement suffisant pour un portfolio FR


  # =================================================================
  # LES ORIGINES — les "sources" depuis lesquelles CloudFront récupère les fichiers
  # C'est les entrepôts depuis lesquels le livreur récupère les colis
  # =================================================================

  # ORIGINE 1 : S3 (les fichiers React)
  origin {
    domain_name              = var.s3_bucket_domain
    # l'adresse du bucket S3 ex: portfolio-elyas-frontend.s3.eu-west-3.amazonaws.com

    origin_id                = "S3-portfolio"
    # un surnom pour cette origine, utilisé plus bas dans les comportements

    origin_access_control_id = var.s3_oac_id
    # le badge d'accès qui autorise CloudFront à lire dans S3
  }

  # ORIGINE 2 : API Gateway (le backend)
  origin {
    domain_name = replace(replace(var.api_gateway_url, "https://", ""), "/", "")
    # on enlève le "https://" et le "/" final de l'URL API Gateway
    # car CloudFront veut juste le domaine sans le protocole
    # ex: "abc123.execute-api.eu-west-3.amazonaws.com"

    origin_id   = "API-portfolio"
    # surnom pour cette origine

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"  # on parle UNIQUEMENT en HTTPS avec l'API
      origin_ssl_protocols   = ["TLSv1.2"]   # version du protocole SSL
    }
  }


  # =================================================================
  # LES COMPORTEMENTS — qui va où selon l'URL
  # C'est ici que CloudFront fait le tri entre front et back
  # =================================================================

  # COMPORTEMENT PAR DÉFAUT → S3
  # Toutes les requêtes qui correspondent à aucune règle spécifique
  # vont vers S3 (le React)
  # ex: /, /contact, /about → tout ça va vers S3
  default_cache_behavior {
    target_origin_id       = "S3-portfolio"        # envoie vers S3
    viewer_protocol_policy = "redirect-to-https"   # force HTTPS (redirige HTTP → HTTPS)
    allowed_methods        = ["GET", "HEAD"]        # on accepte que les lectures
    cached_methods         = ["GET", "HEAD"]        # on met en cache les lectures
    compress               = true                   # compresse les fichiers (site plus rapide)

    forwarded_values {
      query_string = false        # on transmet pas les paramètres d'URL à S3 (inutile)
      cookies { forward = "none" } # on transmet pas les cookies à S3 (inutile)
    }

    # durée de mise en cache des fichiers React
    # 3600 secondes = 1 heure par défaut
    # les fichiers JS/CSS ont un hash dans leur nom donc peuvent être cachés longtemps
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400  # 24 heures maximum
  }

  # COMPORTEMENT SPÉCIFIQUE : /api/* → API Gateway
  # Toutes les requêtes qui commencent par /api/ vont vers le backend
  # ex: /api/profile, /api/health → API Gateway → Lambda → handler.js
  ordered_cache_behavior {
    path_pattern           = "/api/*"              # s'applique à toutes les URLs /api/...
    target_origin_id       = "API-portfolio"       # envoie vers API Gateway
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    # on accepte toutes les méthodes HTTP pour l'API
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = true   # on transmet les paramètres d'URL à l'API (important !)
      headers      = ["Origin", "Authorization", "Content-Type"]
      # on transmet ces headers à l'API (nécessaire pour CORS et auth)
      cookies { forward = "none" }
    }

    # PAS de cache pour l'API — on veut toujours les données fraîches
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }


  # =================================================================
  # SPA ROUTING
  # Quand React Router est utilisé, des URLs comme /contact n'existent
  # pas vraiment dans S3 — seul index.html existe
  # Sans ça, un refresh sur /contact donnerait une erreur 404 de S3
  # Avec ça, CloudFront redirige tous les 404/403 vers index.html
  # et React Router gère le reste
  # =================================================================
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }


  # Pas de restriction géographique — tout le monde peut accéder au site
  restrictions {
    geo_restriction { restriction_type = "none" }
  }


  # CERTIFICAT SSL
  # cloudfront_default_certificate = true → utilise le certificat GRATUIT de CloudFront
  # Ça donne automatiquement le HTTPS sur l'URL *.cloudfront.net
  # Si t'avais un domaine custom, tu mettrais ton propre certificat ACM ici
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


# ===================================================================
# OUTPUTS
# ===================================================================
output "distribution_id" {
  value = aws_cloudfront_distribution.portfolio.id
  # ex: "E1ABCDEF123456"
  # GitHub Actions en a besoin pour invalider le cache après un déploiement
}

output "distribution_domain" {
  value = aws_cloudfront_distribution.portfolio.domain_name
  # ex: "d1234abcd.cloudfront.net"
  # C'est L'URL de ton site ! Tu l'ouvriras dans le navigateur
}


# ===================================================================
# VARIABLES
# ===================================================================
variable "s3_bucket_id" {
  type        = string
  description = "ID du bucket S3"
}

variable "s3_bucket_domain" {
  type        = string
  description = "Domaine régional du bucket S3"
}

variable "s3_oac_id" {
  type        = string
  description = "ID du Origin Access Control"
  default     = ""
}

variable "api_gateway_url" {
  type        = string
  description = "URL de l'API Gateway"
}
