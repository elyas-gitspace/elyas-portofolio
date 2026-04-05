# ===================================================================
# modules/api_gateway/main.tf — L'OUVRIER API GATEWAY
#
# Ce module crée la "porte d'entrée HTTP" vers ta Lambda
#
# Rappel : Lambda comprend pas le HTTP nativement
# API Gateway fait la traduction dans les deux sens :
# Navigateur → HTTP → API Gateway → format Lambda → handler.js
# handler.js → réponse → API Gateway → HTTP → Navigateur
#
# C'est le serveur du resto entre le client et la cuisine
# ===================================================================


# L'API HTTP
# On crée une API de type HTTP (la plus simple et la moins chère)
# Il existe aussi "REST" mais HTTP suffit largement pour notre cas
resource "aws_apigatewayv2_api" "portfolio" {
  name          = var.api_name   # "portfolio-api"
  protocol_type = "HTTP"

  # CORS — Cross Origin Resource Sharing
  # Sans ça, le navigateur bloquerait les requêtes du front vers l'API
  # car ils sont sur des domaines différents
  # (cloudfront.net vs execute-api.amazonaws.com)
  #
  # C'est une règle de sécurité des navigateurs :
  # "t'as pas le droit d'appeler un domaine différent du tien"
  # sauf si ce domaine dit explicitement "je t'autorise"
  # C'est ce qu'on fait ici
  cors_configuration {
    allow_origins = ["*"]                                          # autorise tout le monde
    allow_methods = ["GET", "POST", "OPTIONS"]                     # les types de requêtes autorisés
    allow_headers = ["Content-Type", "Authorization"]              # les headers autorisés
  }
}


# L'INTÉGRATION AVEC LAMBDA
# On connecte l'API Gateway à notre Lambda
# Quand une requête arrive sur l'API → elle est transmise à Lambda
resource "aws_apigatewayv2_integration" "lambda" {
  api_id             = aws_apigatewayv2_api.portfolio.id
  integration_type   = "AWS_PROXY"
  # AWS_PROXY = API Gateway transmet la requête TELLE QUELLE à Lambda
  # Lambda reçoit tous les détails (headers, body, URL, etc.)

  integration_uri    = var.lambda_arn
  # l'adresse de notre Lambda — c'est elle qui sera appelée

  payload_format_version = "2.0"
  # format du message envoyé à Lambda (2.0 = le plus récent)
}


# LA ROUTE
# On définit quelle URL déclenche quelle intégration
# "ANY /api/{proxy+}" = toutes les méthodes HTTP sur n'importe quelle URL /api/...
#
# {proxy+} = un "joker" qui capture tout ce qui suit /api/
# ex: /api/profile, /api/health, /api/n'importe-quoi → tout passe par Lambda
# C'est Express dans handler.js qui fait ensuite le tri
resource "aws_apigatewayv2_route" "api" {
  api_id    = aws_apigatewayv2_api.portfolio.id
  route_key = "ANY /api/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}


# LE STAGE
# Un "stage" c'est une version déployée de l'API
# auto_deploy = true → chaque modification est déployée automatiquement
# "$default" = le stage par défaut (pas de préfixe dans l'URL)
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.portfolio.id
  name        = "$default"
  auto_deploy = true
}


# LA PERMISSION
# On donne à API Gateway le droit d'invoquer (appeler) notre Lambda
# Sans cette permission → API Gateway serait bloqué par AWS
#
# C'est comme donner les clés de la cuisine au serveur
# Sans les clés → il peut pas rentrer pour récupérer les plats
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"    # droit d'appeler la Lambda
  function_name = var.lambda_name
  principal     = "apigateway.amazonaws.com" # qui reçoit ce droit
  source_arn    = "${aws_apigatewayv2_api.portfolio.execution_arn}/*/*"
  # source_arn = depuis quelle API Gateway (sécurité supplémentaire)
}


# ===================================================================
# OUTPUTS
# ===================================================================
output "api_url" {
  value = aws_apigatewayv2_stage.prod.invoke_url
  # ex: "https://abc123.execute-api.eu-west-3.amazonaws.com"
  # CloudFront utilise cette URL pour rediriger les requêtes /api/*
}


# ===================================================================
# VARIABLES
# ===================================================================
variable "api_name" {
  type        = string
  description = "Nom de l'API Gateway"
}

variable "lambda_arn" {
  type        = string
  description = "ARN de la Lambda à connecter"
}

variable "lambda_name" {
  type        = string
  description = "Nom de la Lambda"
}
