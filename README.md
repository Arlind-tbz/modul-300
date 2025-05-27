# Modul 300 - Plattformübergreifende Dienste in ein Netzwerk integrieren

## Inhaltsverzeichnis

- [Modul 300 - Plattformübergreifende Dienste in ein Netzwerk integrieren](#modul-300---plattformübergreifende-dienste-in-ein-netzwerk-integrieren)
  - [Inhaltsverzeichnis](#inhaltsverzeichnis)
- [Projektideen](#projektideen)
- [Projektstruktur \& Umsetzungsschritte](#projektstruktur--umsetzungsschritte)

# Projektideen

In der Informationsphase habe ich mir verschiedene Projekte angeschaut. Ich möchte vor allem mit den Themen **CI/CD**, **Docker** und den Cloud-Plattformen **AWS** oder **Azure** arbeiten.

Ich bin mir noch nicht ganz sicher, was ich genau umsetzen soll. Meine Idee bis jetzt:

- Ich erstelle mehrere **Dockerfiles** für verschiedene Services (z. B. **Web**, **API**, **DB**).
- Diese baue ich automatisch mit einer **CI/CD-Pipeline**.
- Danach lade ich die fertigen **Container-Images** in eine **Cloud-Registry**, z. B. **Azure Container Registry** oder **AWS ECR**.
- Danach starte ich eine **virtuelle Maschine**, die diese Container ausführt und die Services bereitstellt.
- Zum Schluss werde ich mit **Uptime Kuma** einen regelmässigen **Überwachungs-Job** für meine Services einrichten.
- Die **VMs** sollen idealerweise mit **Terraform** verwaltet werden.

# Projektstruktur & Umsetzungsschritte

Ich habe mich entschieden, mein Projekt mit **Microsoft Azure** umzusetzen. Azure bietet viele praktische Tools für **CI/CD**, **Container** und Infrastruktur mit **Terraform**. Die Integration ist gut, und die Dokumentation hat mir geholfen, schnell einen Überblick zu bekommen.

Die Anwendungen selbst werden eher einfach bleiben – zum Beispiel ein kleiner **Webserver**, eine **API** und eine **Datenbank**. Mein Fokus liegt mehr auf dem ganzen Setup und der **Automatisierung**. Geplant ist:

- Die **Dockerfiles** werden automatisch mit einer **CI/CD-Pipeline** in **GitHub Actions** gebaut.
- Die **Images** lade ich in die **Azure Container Registry (ACR)** hoch.
- Danach starte ich eine **Azure VM**, auf der die Container laufen – vielleicht mit **Docker Compose**.
- Mit **Uptime Kuma** überwache ich, ob die Services online sind.
- Die **Infrastruktur**, vor allem die **VMs**, wird mit **Terraform** erstellt und verwaltet.

Mir ist wichtig, dass ich mit diesem Projekt zeigen kann, wie man eine einfache, aber gut strukturierte **Cloud-Umgebung** automatisiert aufbauen kann – mit Fokus auf **DevOps-Themen** wie **CI/CD**, **Containerisierung** und **Infrastructure as Code**. Natürlich gebe ich mir auch bei der **Web App** Mühe, auch wenn sie nicht der Hauptteil des Projekts ist.

# Umsetzung

## Terraform

Ich habe mich heute mit Terraform auseinandergesetzt. Terraform ist eine Open-Source-Software, die es ermöglicht, Infrastruktur in einer **Cloud-Umgebung** zu verwalten. Terraform bietet eine Vielzahl von **Modulen**, die einfach zu verwenden sind. Zum Beispiel mit Azure können **Resource-Gruppen** erstellt werden, die dann **VMs**, **Container-Images** und **Storage-Accounts** enthalten.

Terraform bietet auch eine **CLI**, die es ermöglicht, die **Infrastruktur** direkt aus der Kommandozeile zu verwalten.

Terraform habe ich mit winget installiert:

```powershell
winget install terraform
```
