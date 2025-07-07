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

- GitHub Actions installiert und mit Terraform verwendet.

## Probleme & Herausforderungen

Technisch gesehen habe ich mein Ziel erreicht, allerdings ist meine aktuelle Lösung nicht optimal. Momentan speichere ich die `tfvars`- und `tfstate`-Dateien im Repository, das sollte so nicht sein. Nach etwas Recherche habe ich folgende Optionen gefunden:

Man kann `tfstate`-Dateien in einem Azure Storage Account speichern. Allerdings kann man nicht einfach einen Storage Account per Terraform definieren und erstellen und diesen anschließend im selben Terraform-Workflow als Remote Backend verwenden. Das bedeutet, ich muss ein separates Deployment durchführen, um diesen Storage Account bereitzustellen.

Die Herausforderung besteht nun darin: Wie kann ich dieses erste Deployment durchführen, ohne bereits ein funktionierendes `tfstate`-Backend zu haben? Meine derzeitige Lösungsidee ist, im CI/CD-Prozess einen `terraform import` (sofern die Ressourcen existieren) durchzuführen. Damit werde ich nächste Woche starten.

Ich habe eingetragen, dass ich aktuell "at risk" bin, aber keine Hilfe benötige, da ich genau weiß, was zu tun ist – ich muss es nur noch zum Laufen bringen.

Die tfvars Datei will ich dynamisch erstellen mit GitHub Secrets.

## Genutzte & neu entdeckte Ressourcen

- Terraform Backend (Speichern von `tfstate`-Dateien im Storage Account)

## Verweise auf Ergebnisse / Übungen / Dokumentationen

[Terraform Backend Docs](https://developer.hashicorp.com/terraform/language/backend/azurerm)
[Successful attempt](https://github.com/Arlind-tbz/modul-300/actions/runs/15562116727)
