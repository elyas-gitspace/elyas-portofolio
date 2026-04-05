# ===================================================================
# modules/lambda/main.tf — L'OUVRIER LAMBDA
#
# Ce module crée la fonction Lambda qui fait tourner handler.js
#
# C'est quoi Lambda ?
# C'est un serveur qui existe PAS en permanence
# Il se réveille quand une requête arrive, répond, et se rendort
# Tu paies UNIQUEMENT quand il tourne (pas quand il dort)
#
# Pour un portfolio avec peu de trafic → quasiment GRATUIT 🎉
# ===================================================================


# LE RÔLE IAM DE LA LAMBDA
# Sur AWS, chaque service doit avoir un "rôle" qui définit ses droits
# C'est comme un badge d'employé qui dit ce qu'il a le droit de faire
#
# Ici on crée un rôle pour dire :
# "cette Lambda a le droit d'exister et d'écrire des logs CloudWatch"
resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"
  # "${var.function_name}-role" = "portfolio-api-role"
  # ${} = interpolation, comme les template literals en JS

  # assume_role_policy = qui a le droit d'utiliser ce rôle
  # ici on dit "le service Lambda peut utiliser ce rôle"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
        # seul le service Lambda peut prendre ce rôle
      }
    }]
  })
}


# ON ATTACHE UNE POLICY AU RÔLE
# AWSLambdaBasicExecutionRole = policy AWS prédéfinie qui donne à Lambda
# le droit d'écrire des logs dans CloudWatch
# (CloudWatch = le système de logs d'AWS, genre console.log mais sur le cloud)
resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


# LA FONCTION LAMBDA
# C'est ici qu'on crée vraiment la Lambda avec notre code dedans
resource "aws_lambda_function" "api" {
  filename      = var.zip_path
  # le chemin vers function.zip sur ton PC
  # Terraform va uploader ce fichier sur AWS

  function_name = var.function_name
  # "portfolio-api" — le nom qui apparaîtra dans la console AWS

  role          = aws_iam_role.lambda_role.arn
  # le badge d'accès qu'on vient de créer au dessus

  handler       = var.handler
  # "src/handler.handler" =
  # → cherche le fichier src/handler.js dans le zip
  # → appelle la fonction exports.handler dedans

  runtime       = var.runtime
  # "nodejs20.x" = utilise Node.js version 20 pour faire tourner le code

  source_code_hash = filebase64sha256(var.zip_path)
  # C'est une empreinte digitale du zip
  # Si le zip change → l'empreinte change → Terraform re-déploie la Lambda
  # Si le zip change pas → Terraform touche à rien (optimisation)

  environment {
    variables = {
      NODE_ENV = "production"
      # variable d'environnement disponible dans handler.js via process.env.NODE_ENV
    }
  }
}


# ===================================================================
# OUTPUTS
# ===================================================================
output "lambda_arn" {
  value = aws_lambda_function.api.arn
  # l'identifiant unique de la Lambda
  # API Gateway en a besoin pour savoir quelle Lambda appeler
}

output "lambda_name" {
  value = aws_lambda_function.api.function_name
  # "portfolio-api"
  # utilisé pour donner les permissions à API Gateway
}


# ===================================================================
# VARIABLES
# ===================================================================
variable "function_name" {
  type        = string
  description = "Nom de la fonction Lambda"
}

variable "handler" {
  type        = string
  description = "Point d'entrée (fichier.fonction)"
}

variable "runtime" {
  type        = string
  description = "Version de Node.js"
}

variable "zip_path" {
  type        = string
  description = "Chemin vers le zip du backend"
}
