// ===================================================================
// LES IMPORTS — on récupère les libs installées via npm
// ===================================================================

// Express = le framework qui gère les routes (on en a déjà parlé)
const express = require('express');

// cors = une lib de sécurité
// Par défaut les navigateurs BLOQUENT les requêtes vers un autre domaine
// ex: ton site est sur elyas.fr mais l'API est sur amazonaws.com
// Sans cors → le navigateur dit "non je veux pas" et bloque tout
// Avec cors → on dit "ok je fais confiance à tout le monde" (ou à certains domaines)
const cors = require('cors');

// aws-serverless-express = le traducteur entre Lambda et Express
// Lambda et Express parlent pas le même langage nativement
// Cette lib fait la traduction automatiquement
// Sans elle, Lambda comprendrait pas les requêtes HTTP d'Express
const awsServerlessExpress = require('aws-serverless-express');


// ===================================================================
// CRÉATION DE L'APP EXPRESS
// C'est le point de départ, on crée l'objet "app" qui va tout gérer
// ===================================================================
const app = express();

// On active cors pour TOUTES les routes
// Concrètement ça ajoute des headers HTTP qui disent au navigateur
// "t'inquiète, cette API accepte les requêtes de partout"
app.use(cors());

// On dit à Express de comprendre le JSON automatiquement
// Quand le front envoie des données en JSON, Express les parse tout seul
// Sans ça il comprendrait pas ce qui arrive
app.use(express.json());


// ===================================================================
// LES ROUTES — c'est ici qu'on définit ce que l'API peut faire
//
// Une route c'est une adresse URL + une action
// C'est comme les pages d'un site, mais pour une API
// Au lieu de retourner du HTML, on retourne du JSON
// ===================================================================


// ── ROUTE 1 : GET /api/profile ──────────────────────────────────────
// GET = le front DEMANDE des données (il lit, il modifie rien)
// /api/profile = l'adresse de la route
//
// Concrètement : quand le front fait fetch('/api/profile')
// → cette fonction se déclenche et renvoie les infos du profil
//
// req = la requête qui arrive (ce que le front envoie)
// res = la réponse qu'on renvoie au front
app.get('/api/profile', (req, res) => {

  // res.json() = on renvoie un objet JavaScript au format JSON
  // Le front reçoit ça et peut l'utiliser directement
  res.json({
    name: "Elyas MEZIANI",
    seeking: "Alternance 1 an",
    available: "Septembre 2026",

    // Un tableau d'expériences — le front va faire un .map() dessus
    // pour afficher les cartes
    experiences: [
      {
        role: "Concepteur Datalake",
        company: "EDF",
        description: "Conception d'architectures Datalake à grande échelle"
      },
      {
        role: "Cloud DevOps Engineer",
        company: "Atmira",
        description: "Automatisation CI/CD, infrastructure as code, cloud"
      }
    ]
  });
  // À ce moment là le front reçoit ce JSON et peut l'afficher
});


// ── ROUTE 2 : GET /api/health ───────────────────────────────────────
// C'est une route de "healthcheck" — elle sert juste à vérifier
// que l'API est bien en vie et répond
//
// Concrètement : AWS (ou toi) peut ping cette route toutes les X minutes
// Si elle répond pas → y'a un problème → on reçoit une alerte
// C'est comme appuyer sur le bouton "test" d'un détecteur de fumée
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',                          // tout va bien
    timestamp: new Date().toISOString()    // l'heure actuelle, pour savoir quand ça a été vérifié
  });
});


// ===================================================================
// CONNEXION AVEC LAMBDA
//
// Jusqu'ici on a juste créé une app Express normale
// Maintenant on doit la "brancher" sur Lambda
//
// Lambda fonctionne pas comme un serveur classique qui tourne en continu
// Lambda se réveille UNIQUEMENT quand une requête arrive
// puis il se rendort aussitôt après
// C'est comme un livreur qui dort chez lui et sort SEULEMENT quand
// il y a une livraison à faire, plutôt qu'un livreur qui reste au dépôt 24h/24
// ===================================================================

// On crée un "serveur" à partir de l'app Express
// aws-serverless-express va s'en servir pour faire la traduction
const server = awsServerlessExpress.createServer(app);


// ── LE POINT D'ENTRÉE LAMBDA ────────────────────────────────────────
// C'est LA fonction que Lambda appelle quand une requête arrive
// AWS sait qu'il doit appeler "exports.handler" — c'est une convention
//
// event = toutes les infos sur la requête HTTP qui arrive
//         (l'URL, les headers, le body, etc.)
// context = infos sur l'environnement Lambda (temps restant, etc.)
exports.handler = (event, context) => {

  // proxy() fait la traduction :
  // il prend le "event" Lambda → le convertit en requête HTTP Express
  // Express traite la requête → trouve la bonne route → renvoie une réponse
  // proxy() retraduit la réponse Express → format Lambda → renvoie au front
  awsServerlessExpress.proxy(server, event, context);

};
// Sans cette fonction exports.handler, Lambda saurait pas quoi appeler
// C'est comme le bouton "ON" d'une télé — sans lui rien se passe