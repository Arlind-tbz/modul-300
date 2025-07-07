# Lernjournal | Woche 4 - 03.06.2025

## Inhaltsverzeichnis
1. [Lernjournal | Woche 4 - 03.06.2025](#lernjournal--woche-4---03062025)
   1. [Inhaltsverzeichnis](#inhaltsverzeichnis)
   2. [Tagesziele](#tagesziele)
   3. [Erreichte Tagesziele](#erreichte-tagesziele)
   4. [Probleme \& Herausforderungen](#probleme--herausforderungen)
   5. [Genutzte \& neu entdeckte Ressourcen](#genutzte--neu-entdeckte-ressourcen)
   6. [Verweise auf Ergebnisse / Übungen / Dokumentationen](#verweise-auf-ergebnisse--übungen--dokumentationen)

## Tagesziele

- Node Exporter installieren und mit Prometheus verwenden.
- Prometheus installieren und verstehen (lokal, ausprobieren)
- Grafana installieren und ein Dashboard mit Prometheus-Datenquelle einrichten.

## Erreichte Tagesziele

- Prometheus erfolgreich installiert und Grundkonfiguration durchgeführt
- Grafana installiert und mit Prometheus verbunden
- Einfaches Dashboard erstellt

## Probleme & Herausforderungen

Am schwierigsten war das Einrichten von Prometheus mit Grafana. Ich dachte zuerst, ich könne z. B. den Node Exporter direkt in Grafana einbinden, aber man muss es zuerst in Prometheus als Target hinzufügen. Erst dann kann Grafana über Prometheus auf die Daten zugreifen.

Auch das Einrichten der Datenquelle in Grafana war etwas schwierig. Ich musste mehrmals die Prometheus-URL und Ports überprüfen, bis alles lief.

Zusätzlich gab es Berechtigungsprobleme, wenn ich Grafana und Prometheus mit dem Benutzer `1000:1000` gestartet habe. Manche Verzeichnisse konnten nicht gelesen werden. Insbesondere `/prometheus` für Persistenz.

## Genutzte & neu entdeckte Ressourcen

- Prometheus
- Grafana

## Verweise auf Ergebnisse / Übungen / Dokumentationen

- [Prometheus Installation & Getting Started](https://prometheus.io/docs/prometheus/latest/installation/#using-docker)
- [Grafana Dokumentation](https://grafana.com/docs/grafana/latest/setup-grafana/installation/docker/)
- [Artikel zu Grafana + Prometheus + Node Exporter](https://medium.com/@DanialEskandari/system-monitoring-with-prometheus-grafana-and-node-exporter-412027684564)
