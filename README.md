# Modul 300 - Plattformübergreifende Dienste in ein Netzwerk integrieren

# Inhaltsverzeignis
- [Modul 300 - Plattformübergreifende Dienste in ein Netzwerk integrieren](#modul-300---plattformübergreifende-dienste-in-ein-netzwerk-integrieren)
- [Inhaltsverzeignis](#inhaltsverzeignis)
- [Informieren](#informieren)
- [Entscheidung](#entscheidung)

# Informieren

In der Informationsphase habe ich mir verschiedene Projekte angeschaut. Ich möchte vor allem mit den Themen CI/CD, Docker und den Cloud-Plattformen AWS oder Azure arbeiten.

Ich bin mir noch nicht ganz sicher, was ich genau umsetzen soll. Meine Idee bis jetzt:

- Ich erstelle mehrere Dockerfiles für verschiedene Services. (Web, API, DB)
- Diese baue ich automatisch mit einer CI/CD-Pipeline diese Images.
- Danach lade ich die fertigen Container-Images in eine Cloud-Registry, z. B. Azure Container Registry oder AWS ECR.
- Danach starte ich eine virtuelle Maschine, die diese Container ausführt und die Services bereitstellt.
- Zum Schluss werde ich mit Uptime Kuma einen regelmässigen Überwachungs-Job für meine Services einrichten.
- Beide VMs sollten idealer weise mit Terraform verwaltet werden.

# Entscheidung
