# 🛡️ **Gestionnaire de Comptes AD & VPN**

> Une solution intégrée pour la gestion de vos utilisateurs, au bout de vos doigts.

## 🚀 **Table des matières**

1. [🎯 **Description**](#description)
2. [🔧 **Prérequis**](#prérequis)
3. [🔑 **Utilisation**](#utilisation)
4. [💡 **Fonctionnalités**](#fonctionnalités)

## 🎯 **Description**

Ce script, vous permet de prendre le contrôle total de la réinitialisation des mots de passe de vos utilisateurs dans **Active Directory**, d'activer leurs comptes pour une durée spécifiée, et d'assurer la gestion de leurs accès VPN. Une notification intégrée informe immédiatement via Microsoft Teams du statut des opérations.

## 🔧 **Prérequis**

- **Environnement** : PowerShell v5.1 ou supérieur.
- **Modules PowerShell** : `System.Windows.Forms`, `ActiveDirectory`.
- **Réseau** : Accès direct à l'Active Directory et à la passerelle VPN.

### ⚙️ **Configuration**

Pour utiliser ce script, modifiez les informations suivantes dans le code:

- Ligne 9 : Remplacez `"domain"` par le nom de votre domaine.
- Ligne 11 : Remplacez `"nom serveur ad"` par le nom de votre serveur Active Directory.
- Ligne 12 : Remplacez `"Admins du domaine"` par le nom de votre groupe d'administrateurs.
- Ligne 49 : Remplacez `"Chemin de l'OU"` par le chemin de votre unité d'organisation dans l'Active Directory.
- Ligne 104 : Remplacez `"api forti/$userToChangePassword"` par votre URL d'API Fortinet.
- Ligne 107 : Remplacez `'clef api'` par votre clé d'API.
- Ligne 137 : Remplacez `"webhook teams"` par votre lien webhook de Microsoft Teams.

## 🔑 **Utilisation**

1. **Lancement** : Ouvrez une session PowerShell.
2. **Navigation** : Dirigez-vous vers le dossier contenant le script.
3. **Execution** : Tapez `.\NomDuScript.ps1` et appuyez sur `Entrée`.
4. **Instructions** : Suivez soigneusement les instructions interactives à l'écran.

## 💡 **Fonctionnalités**

- 🛡️ **Sécurité SSL** : Bypass des erreurs liées aux certificats SSL lors des connexions.
- 📜 **Logging avancé** : Un système de journalisation en temps réel pour traquer chaque action dans un fichier `log.log`.
- 🔒 **Générateur de mots de passe** : Créez des mots de passe robustes et aléatoires pour chaque utilisateur.
- 🖥️ **Interface utilisateur GUI** : Une interface graphique intuitive pour une expérience utilisateur améliorée.
- 🌐 **Gestion VPN** : Active automatiquement le compte VPN de l'utilisateur après chaque réinitialisation de mot de passe.
- 📬 **Notifications Teams** : Restez informé à chaque étape grâce aux notifications en temps réel sur Microsoft Teams.
