
# Configuration
$csvPath = "C:\utilisateurs.csv"
$ouPath = "OU=Utilisateurs,DC=laplateforme,DC=io"
$domain = "laplateforme.io"
$logFile = "C:\log_peuplement.txt"

# Définition du mot de passe par défaut
$defaultPassword = ConvertTo-SecureString "Azerty_2025!" -AsPlainText -Force

# Importation des données du fichier .csv
$users = Import-Csv -Path $csvPath

# Fonction de log
function Log {
    param ($message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logFile -Append
    Write-Host $message
}

Log "===== DÉBUT DE LA CREATION DES UTILISATEURS ET DE LEURS INTEGRATION AUX DIFFERENTS GROUPES ====="

foreach ($user in $users) {
    $nom = $user.Nom
    $prenom = $user.prenom
    $username = "$prenom.$nom".ToLower()
    $fullname = "$prenom $nom"
    $upn = "$username@$domain"

    # Vérification préalable si l'utilisateur existe
    if (Get-ADUser -Filter { SamAccountName -eq $username } -ErrorAction SilentlyContinue) {
        Log "L'utilisateur $username existe déjà. La création a été ignorée pour $nom $prenom."
        continue
    }

    try {
        #  création de l'utilisateur s'il n'existe pas
        New-ADUser `
            -Name $fullname `
            -GivenName $prenom `
            -Surname $nom `
            -SamAccountName $username `
            -UserPrincipalName $upn `
            -AccountPassword $defaultPassword `
            -ChangePasswordAtLogon $true `
            -Enabled $true `
            -Path $ouPath

        Log "L'utilisateur $nom $prenom a été créé avec succès."
    } catch {
        Log "Erreur lors de la création de l'utilisateur $nom $prenom : $_"
        continue
    }

    # CREATION DES GROUPES ET AJOUT DES UTILISATEURS AU DIFFERENTS GROUPES
    for ($i = 1; $i -le 6; $i++) {
        $groupe = $user."groupe$i"
        if (![string]::IsNullOrWhiteSpace($groupe)) {
            # Vérification préalable de l'existence du groupe
            if (-not (Get-ADGroup -Filter { Name -eq $groupe } -ErrorAction SilentlyContinue)) {
                try {
                    New-ADGroup -Name $groupe -GroupScope Global -Path $ouPath
                    Log "Groupe $groupe a été créé avec succès."
                } catch {
                    Log "Erreur de création du groupe $groupe : $_"
                    continue
                }
            }

            try {
                Add-ADGroupMember -Identity $groupe -Members $username
                Log "Utilisateur $nom $prenom ajouté au groupe $groupe."
            } catch {
                Log "Erreur d’ajout de $nom $prenom au groupe $groupe : $_"
            }
        }
    }
}

Log "===== FIN DU TRAITEMENT ====="
