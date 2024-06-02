# Dit PowerShell-script wijzigt de taakbalkuitlijning naar links op een Windows 11-systeem.
# Het doet dit door een registerinstelling te wijzigen en vervolgens de Windows Verkenner opnieuw op te starten om de wijzigingen door te voeren.

########################### WARNING ################################
###                                                              ###
###               Explorer krijgt een restart                    ###
###                                                              ###
########################### WARNING ################################


# Definitie van het registerpad en de naam van de waarde die moet worden gewijzigd
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$valueName = "TaskbarAl"

# Waarschuwing aan de gebruiker
Write-Output "LET OP: Dit script zal Windows Verkenner opnieuw starten, wat kan leiden tot het sluiten van geopende Verkenner-vensters."

# Stel de taakbalkuitlijning in op links (waarde 0)
Set-ItemProperty -Path $registryPath -Name $valueName -Value 0

# Herstart Windows Verkenner om de wijzigingen toe te passen
Stop-Process -Name explorer -Force

# Bevestigingsbericht
Write-Output "Taakbalk is uitgelijnd naar links."
