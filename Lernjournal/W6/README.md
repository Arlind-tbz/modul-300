# Lernjournal | Woche 6 - 17.06.2025

## Inhaltsverzeichnis
1. [Lernjournal | Woche 6 - 17.06.2025](#lernjournal--woche-6---17062025)
   1. [Inhaltsverzeichnis](#inhaltsverzeichnis)
   2. [Tagesziele](#tagesziele)
   3. [Erreichte Tagesziele](#erreichte-tagesziele)
   4. [Probleme \& Herausforderungen](#probleme--herausforderungen)
   5. [Genutzte \& neu entdeckte Ressourcen](#genutzte--neu-entdeckte-ressourcen)
   6. [Verweise auf Ergebnisse / Übungen / Dokumentationen](#verweise-auf-ergebnisse--übungen--dokumentationen)

## Tagesziele

- GitHub Actions installieren und mit Terraform verwenden.

## Erreichte Tagesziele

- GitHub Actions installieren und mit Terraform verwenden.

## Probleme & Herausforderungen

Technisch gesehen habe ich mein Ziel erreicht, aber meine momentane lösung ist nicht optimal. Momentan habe ich die tfvars und tfstate datei im Repository gespeichert. Das sollte nicht so sein. Ich habe ein bisschen recherchiert und habe die folgenden Optionen gefunden:

Man kann Tfstate dateien in einem Storage Account speichern. Aber man kann nicht einen Storage account definieren und erstellen, und danach diesen Storage Account als Remote Backend in Terraform verwenden. Das heisst ich muss ein neues Deployment machen für diesen Storage Account. Damit dieses Deployment aber überhaupt funktioniert ist die Frage, wie erstelle ich das neue deployment ohne ein tfstate? Die lösung auf die ich gekommen bin ist das ich im CiCD einen Terraform import if exists ausführen lasse. Mit dem starte ich nächste Woche.

Ich habe eingetragen das ich momentan "at risk" bin aber keine hilfe brauche. Da ich weiss was ich machen muss. Ich muss es nur zum funktionieren bringen.

## Genutzte & neu entdeckte Ressourcen

Terraform Backend (TFstate in Storage Account speichern)

## Verweise auf Ergebnisse / Übungen / Dokumentationen

[Terraform Backend Docs](https://developer.hashicorp.com/terraform/language/backend/azurerm)
[Successful attempt](https://github.com/Arlind-tbz/modul-300/actions/runs/15562116727)
