
# === Définition des paramètres ===
$NomDomaine = "laplateforme.io"      # Nom de domaine complet (FQDN)
$NomNetBIOS = "LAPLATEFORME"            # Nom NetBIOS
$MotDePasse = "P@ssw0rd" | ConvertTo-SecureString -AsPlainText -Force  # Mot de passe du DSRM

# === Étape 1 : Installation des services AD-DS ===
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# === Étape 2 : Promouvoir ce serveur en tant que contrôleur de domaine principal (DC root) ===
Install-ADDSForest `
    -DomainName $NomDomaine `
    -DomainNetbiosName $NomNetBIOS `
    -SafeModeAdministratorPassword $MotDePasse `
    -InstallDNS `
    -Force:$true
