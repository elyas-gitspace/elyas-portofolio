// ===================================================================
// LES IMPORTS — on va chercher ce dont on a besoin dans node_modules
// ===================================================================

// On importe React (obligatoire, c'est le moteur)
// et deux "outils" spéciaux appelés HOOKS : useState et useEffect
// Un hook c'est juste une fonction spéciale que React met à dispo
import React, { useState, useEffect } from 'react';

// On importe le CSS (le décor, on s'en fout pour l'instant)
import './App.css';


// ===================================================================
// LES DONNÉES — en dur dans le code pour l'instant
// Plus tard on les récupérera depuis le backend via fetch()
// ===================================================================

// Un tableau avec les 3 textes qui vont défiler en boucle
// genre l'animation de typage sur la page d'accueil
const ROLES = [
  "Cloud DevOps Engineer",
  "Datalake Architect",
  "Alternant disponible sept. 2026"
];


// ===================================================================
// LE COMPOSANT PRINCIPAL — c'est UNE fonction qui retourne du HTML
// React va l'appeler et afficher ce qu'elle retourne
// ===================================================================
function App() {

  // =================================================================
  // LES STATES — les variables "connectées" à l'affichage
  // Quand un state change → React réaffiche automatiquement la page
  // C'est la différence avec une variable JS normale qui s'en fout
  // =================================================================

  // Quel mot on est en train d'afficher (0 = "Cloud DevOps Engineer")
  // genre l'index dans le tableau ROLES
  const [roleIndex, setRoleIndex] = useState(0);

  // Le texte actuellement affiché à l'écran lettre par lettre
  // Au départ c'est vide, puis ça devient "C", "Cl", "Clo"...
  const [displayed, setDisplayed] = useState('');

  // Jusqu'à quelle lettre on est arrivé
  // 0 = rien affiché, 1 = première lettre, 2 = deux lettres, etc.
  const [charIndex, setCharIndex] = useState(0);

  // Est-ce qu'on est en train d'EFFACER le texte ?
  // false = on écrit, true = on efface
  const [deleting, setDeleting] = useState(false);


  // =================================================================
  // LE useEffect DE L'ANIMATION — le cerveau de l'effet de typage
  //
  // useEffect c'est une fonction qui s'exécute AUTOMATIQUEMENT
  // à chaque fois que les variables dans [] changent
  // Ici [] contient charIndex, deleting, roleIndex
  // donc il se relance à chaque fois que l'un d'eux change
  // =================================================================
  useEffect(() => {

    // On récupère le mot en cours dans le tableau
    // ex: ROLES[0] = "Cloud DevOps Engineer"
    const current = ROLES[roleIndex];

    // On déclare timeout ici pour pouvoir l'annuler dans le return
    let timeout;

    if (!deleting && charIndex < current.length) {
      // CAS 1 : on est PAS en train d'effacer ET on a PAS fini d'écrire
      // → on attend 60ms puis on ajoute une lettre
      // setTimeout = attendre X millisecondes puis exécuter une fonction
      timeout = setTimeout(() => {

        // slice(0, 3) sur "DevOps" donne "Dev"
        // donc slice(0, charIndex + 1) ajoute une lettre à chaque fois
        setDisplayed(current.slice(0, charIndex + 1));

        // on passe à la lettre suivante
        // la syntaxe "i => i + 1" c'est pour être sûr d'avoir la valeur la plus récente
        setCharIndex(i => i + 1);

      }, 60); // 60ms entre chaque lettre → vitesse d'écriture

    } else if (!deleting && charIndex === current.length) {
      // CAS 2 : on a FINI d'écrire le mot entier
      // → on attend 1.8 secondes puis on passe en mode "effacement"
      timeout = setTimeout(() => setDeleting(true), 1800);

    } else if (deleting && charIndex > 0) {
      // CAS 3 : on est en mode effacement ET il reste des lettres
      // → on efface une lettre toutes les 35ms (plus rapide que l'écriture)
      timeout = setTimeout(() => {
        setDisplayed(current.slice(0, charIndex - 1)); // on enlève la dernière lettre
        setCharIndex(i => i - 1);
      }, 35);

    } else if (deleting && charIndex === 0) {
      // CAS 4 : on a TOUT effacé
      // → on repart en mode écriture et on passe au mot suivant
      setDeleting(false);

      // % ROLES.length = quand on arrive à la fin du tableau, on repart au début
      // ex: si roleIndex = 2 (dernier), (2+1) % 3 = 0 → retour au début
      setRoleIndex(i => (i + 1) % ROLES.length);
    }

    // Le return du useEffect = nettoyage
    // Si le composant disparaît ou si useEffect se relance,
    // on annule le timeout en cours pour éviter des bugs
    return () => clearTimeout(timeout);

  }, [charIndex, deleting, roleIndex]);
  // ↑ ces 3 variables sont surveillées
  // dès que l'une change → useEffect se relance


  // =================================================================
  // LES DONNÉES DES EXPÉRIENCES
  // Pour l'instant c'est écrit ici en dur
  // Plus tard on fera un fetch() vers le backend pour les récupérer
  // =================================================================
  const experiences = [
    {
      role: "Concepteur Datalake",
      company: "EDF",
      icon: "⚡",
      color: "#00d4ff",
      description: "Conception et développement d'architectures Datalake à grande échelle pour l'un des leaders européens de l'énergie.",
      tags: ["Data Engineering", "Cloud", "Big Data"]
    },
    {
      role: "Cloud DevOps Engineer",
      company: "Atmira",
      icon: "☁️",
      color: "#a78bfa",
      description: "Automatisation des pipelines CI/CD, infrastructure as code et déploiements cloud pour des clients grands comptes.",
      tags: ["DevOps", "Terraform", "AWS", "CI/CD"]
    }
  ];


  // =================================================================
  // LE RETURN — ce que React va afficher dans le navigateur
  // Tout ce qui est entre () c'est du JSX (HTML + JS mélangés)
  // =================================================================
  return (
    // Une seule balise parente obligatoire — ici une div avec la classe "app"
    <div className="app">

      {/* FOND DE PAGE — juste du décor CSS, rien d'important */}
      <div className="bg-grid" />
      <div className="bg-glow" />


      {/* ── NAVBAR ── */}
      <nav className="nav">
        <span className="nav-logo">EM</span>
        <div className="nav-links">
          {/* Les liens # renvoient vers les sections de la page */}
          <a href="#about">Profil</a>
          <a href="#xp">Expériences</a>
          <a href="#contact">Contact</a>
        </div>
      </nav>


      {/* ── HERO (la grande section avec ton nom) ── */}
      <section className="hero" id="about">

        <div className="hero-badge">
          🎯 Recherche alternance · 1 an · Septembre 2026
        </div>

        <h1 className="hero-name">
          Elyas<br />
          {/* Le span permet de mettre une couleur différente sur MEZIANI */}
          <span>MEZIANI</span>
        </h1>

        {/* L'animation de typage */}
        <div className="hero-role">
          {/* {displayed} = on affiche la valeur du state "displayed"
              qui change toutes les 60ms grâce au useEffect au dessus */}
          <span className="role-text">{displayed}</span>

          {/* Le curseur clignotant | — c'est juste du CSS qui clignote */}
          <span className="cursor">|</span>
        </div>

        <p className="hero-desc">
          Passionné par le cloud, le DevOps et le monitoring, je construis des infrastructures robustes
          et des pipelines de données à grande échelle
        </p>

        <div className="hero-cta">
          <a href="#xp" className="btn btn-primary">Voir mes expériences</a>
          <a href="#contact" className="btn btn-ghost">Me contacter</a>
        </div>

        {/* Les 3 stats en bas du hero */}
        <div className="stats">
          <div className="stat">
            <span className="stat-num">2</span>
            <span className="stat-label">Expériences pro</span>
          </div>
          <div className="stat-divider" />
          <div className="stat">
            <span className="stat-num">1 an</span>
            <span className="stat-label">Alternance visée</span>
          </div>
          <div className="stat-divider" />
          <div className="stat">
            <span className="stat-num">Sept.</span>
            <span className="stat-label">Disponibilité 2026</span>
          </div>
        </div>

      </section>


      {/* ── SECTION EXPÉRIENCES ── */}
      <section className="section" id="xp">
      <div className="section-label">&#47;&#47; expériences</div>
        <h2 className="section-title">Parcours professionnel</h2>

        <div className="xp-grid">
          {/*
            .map() = pour chaque élément du tableau "experiences",
            on crée une carte HTML

            c'est comme une boucle for mais en JSX :
            pour chaque xp → retourne une div avec ses infos

            "key={i}" est OBLIGATOIRE quand on fait un .map()
            React en a besoin pour identifier chaque élément
          */}
          {experiences.map((xp, i) => (
            <div
              className="xp-card"
              key={i}
              style={{ '--accent': xp.color }}
              // style= permet de mettre du CSS directement en JS
              // ici on définit une variable CSS "--accent" avec la couleur
              // de l'expérience (bleu pour EDF, violet pour Atmira)
              // le CSS l'utilise ensuite avec var(--accent)
            >
              <div className="xp-card-top">
                <span className="xp-icon">{xp.icon}</span>
                <div>
                  <div className="xp-role">{xp.role}</div>
                  <div className="xp-company">{xp.company}</div>
                </div>
              </div>
              <p className="xp-desc">{xp.description}</p>

              {/* Un autre .map() pour afficher les tags
                  ex: ["DevOps", "Terraform", "AWS"] → 3 petits badges */}
              <div className="xp-tags">
                {xp.tags.map(t => (
                  <span className="tag" key={t}>{t}</span>
                ))}
              </div>
            </div>
          ))}
        </div>
      </section>


      {/* ── SECTION STACK TECHNIQUE ── */}
      <section className="section stack-section">
      <div className="section-label">&#47;&#47; stack technique</div>
        <h2 className="section-title">Technologies</h2>

        <div className="tech-grid">
          {/* Encore un .map() sur un tableau de strings cette fois
              Pour chaque techno → un petit badge */}
          {["AWS", "Terraform", "React", "Node.js", "Python", "Docker", "Kubernetes", "Git"].map(t => (
            <div className="tech-pill" key={t}>{t}</div>
          ))}
        </div>
      </section>


      {/* ── SECTION CONTACT ── */}
      <section className="section contact-section" id="contact">
      <div className="section-label">&#47;&#47; contact</div>
        <h2 className="section-title">Travaillons ensemble</h2>

        <p className="contact-text">
          Je recherche une alternance de <strong>1 an</strong> à partir de{' '}
          {/* {' '} = juste un espace en JSX, sinon React mange les espaces */}
          <strong>septembre 2026</strong>.<br />
          Ouvert à toutes les opportunités dans le cloud, la data ou le DevOps.
        </p>

        <div className="contact-card">
          <div className="contact-info">
            <span>📧</span>
            <span>elyas.mezianipro@email.com</span>
          </div>
          <div className="contact-info">
            <span>💼</span>
            {/* target="_blank" = ouvre dans un nouvel onglet */}
            {/* rel="noreferrer" = sécurité, toujours mettre avec target="_blank" */}
            <a href="https://linkedin.com/in/elyas-meziani" target="_blank" rel="noreferrer">
              linkedin.com/in/elyas-meziani
            </a>
          </div>
        </div>
      </section>


      {/* ── FOOTER ── */}
      <footer className="footer">
        <span>Elyas MEZIANI · {new Date().getFullYear()}</span>
        {/* new Date().getFullYear() = l'année actuelle en JS
            comme ça pas besoin de changer 2026 en 2027 l'année prochaine */}
        <span>Built with React · Hosted on AWS</span>
      </footer>

    </div>
  );
}


// EXPORT — obligatoire pour que index.js puisse importer ce composant
// sans ça, App.js existe mais personne peut l'utiliser
// c'est comme rendre ton code "public" pour les autres fichiers
export default App;

