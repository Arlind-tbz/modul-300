# Lernjournal | Woche 8 - 01.07.2025

## Inhaltsverzeichnis
1. [Lernjournal | Woche 8 - 01.07.2025](#lernjournal--woche-8---01072025)
   1. [Inhaltsverzeichnis](#inhaltsverzeichnis)
   2. [Tagesziele](#tagesziele)
   3. [Erreichte Tagesziele](#erreichte-tagesziele)
   4. [Probleme \& Herausforderungen](#probleme--herausforderungen)
   5. [Genutzte \& neu entdeckte Tools / Ressourcen](#genutzte--neu-entdeckte-tools--ressourcen)
   6. [Verweise auf Ergebnisse, Übungen und Dokumentationen](#verweise-auf-ergebnisse-übungen-und-dokumentationen)

## Tagesziele

- GitHub Actions so anpassen, dass Azure als Backend verwendet wird
- Die eigene 3-Tier-Architektur implementieren und lokal testen

## Erreichte Tagesziele

- GitHub Actions erfolgreich auf Azure als Backend umgestellt
- 3-Tier-Architektur programmiert und lokal getestet
- Netzwerkplan und Sequenzdiagramm für die Architektur erstellt
- CI/CD-Pipeline visuell dokumentiert
- Mit der Hauptdokumentation begonnen
- Fehlerbehandlung und Retry-Mechanismen integriert
- Monitoring und Alerting implementiert

## Probleme & Herausforderungen

In der Schule konnte ich endlich meine CI/CD-Pipeline erfolgreich reparieren und mit der eigentlichen Entwicklung der Web-App inklusive Backend und Datenbank beginnen. Da der Fokus des Moduls nicht auf der Web-App liegt, habe ich eine einfache API entwickelt, die Tasks aus der Datenbank liefert. Diese API befindet sich in der Datei `src/docker/backend/app.py`.

Ein zentrales Problem war die Datenbankkonfiguration: Benutzer und Datenbank mussten beim Start automatisch erstellt werden. Dies habe ich durch die Verwendung von Environment-Variablen gelöst:

```bash
MYSQL_USER
MYSQL_PASSWORD
MYSQL_DATABASE
MYSQL_HOST
MYSQL_ROOT_PASSWORD
```

Bei jedem Containerstart wird die Datenbank (falls nicht vorhanden) inklusive Benutzer automatisch erstellt.

Durch die Verwendung von Environment-Variablen konnte ich die Konfiguration einfach in Azure Container Apps übernehmen. Hier traten jedoch mehrere Probleme auf. Zwar konnten die Container-Images erfolgreich in die Azure Container Registry (ACR) gepusht und die Apps technisch gesehen deployed werden – jedoch funktionierte die Kommunikation zwischen den Containern nicht.

Der Fehler lag darin, dass ich beim Ingress das Protokoll „auto“ verwendete. Dies führte dazu, dass automatisch ein HTTP-Ingress auf Port 80/443 erstellt wurde, was für MySQL auf Port 3306 ungeeignet ist. Die Lösung bestand darin, für die Backend- und Datenbankdienste explizit TCP als Protokoll zu definieren. Nur für das Frontend wurde ein HTTP-Ingress beibehalten.

Das Monitoring und Alerting verlief hingegen problemlos. Ein Test-Alert wurde ausgelöst, sobald die Anzahl der Replikas im Backend unter 1 fiel. Nach dem Skalieren auf 0 wurde die Benachrichtigung sofort korrekt per E-Mail versendet.

## Genutzte & neu entdeckte Tools / Ressourcen

- Azure Monitoring
- Mermaid
- Visual Studio Code Extension: Markdown All in One

## Verweise auf Ergebnisse, Übungen und Dokumentationen

- [Terraform: Azure Container App Resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app)
- [Terraform: Backend-Konfiguration mit Azure](https://developer.hashicorp.com/terraform/language/backend/azurerm)
- [GitHub Actions Run](https://github.com/Arlind-tbz/modul-300/actions/runs/16115231794)
