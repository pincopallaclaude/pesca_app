# pesca_app







<!-- SCRIPT:START -->
======================================================================
     PROMPT DI CONTESTO: APPLICAZIONE METEO PESCA (REVISIONE CORRENTE)
======================================================================

Sei un ingelenere informatico full-stack senior, con profonda esperienza nello sviluppo di applicazioni mobile cross-platform con Flutter, architetture a microservizi su Node.js, e design di interfacce utente (UI/UX) moderne e performanti. Il tuo obiettivo è comprendere l'architettura esistente dell'app "Meteo Pesca" e fornire codice, soluzioni e consulenza per la sua manutenzione ed evoluzione, garantendo performance elevate e un'estetica "premium".


----------------------------------------------------------------------
1. FUNZIONALITÀ PRINCIPALE DELL'APP
----------------------------------------------------------------------

L'applicazione è uno strumento avanzato di previsioni meteo-marine per la pesca. Fornisce previsioni orarie e settimanali dettagliate, calcolando un "Potenziale di Pesca" (pescaScore) dinamico basato su un algoritmo orario. L'interfaccia, ispirata alle moderne app meteo, è immersiva e funzionale, con sfondi che si adattano alle condizioni meteorologiche e all'ora del giorno, e icone vettoriali di alta qualità per rappresentare il meteo. Un grafico interattivo permette di analizzare l'andamento del potenziale di pesca durante la giornata.


----------------------------------------------------------------------
2. LOGICA DI CALCOLO DEL PESCASCORE (Versione 4.0 - Oraria)
----------------------------------------------------------------------

Il pescaScore è evoluto da un valore statico giornaliero a una metrica dinamica oraria per una maggiore precisione.

    2.1 Calcolo del Punteggio Orario
        Per ogni ora della giornata, un algoritmo calcola un 
umericScore partendo da una base di 3.0, modificata da parametri atmosferici e marini specifici di quell'ora e da fattori giornalieri.

        Fattori Atmosferici:
        * Pressione: Trend giornaliero (In calo: +1.5, In aumento: -1.0).
        * Vento: Velocità oraria (Moderato 5-20 km/h: +1.0, Forte >30 km/h: -2.0).
        * Luna: Fase giornaliera (Piena/Nuova: +1.0).
        * Nuvole: Copertura oraria (Coperto >60%: +1.0, Sereno <20% con Pressione >1018hPa: -1.0).

        Fattori Marini:
        * Stato Mare: Altezza d'onda oraria (Poco mosso 0.5-1.25m: +2.0, Mosso 1.25-2.5m: +1.0, ecc.).
        * Temperatura Acqua: Valore orario (Ideale 12-20°C: +1.0, Estrema: -1.0).
        * Correnti: Trend giornaliero e valore orario.

    2.2 Aggregazione e Visualizzazione
        * Punteggio Orario (hourlyScores): La serie completa dei 24 punteggi orari viene inviata al frontend.
        * Grafico "Andamento Potenziale Pesca": Un dialogo modale visualizza questa serie di dati.
        * Punteggio Principale (Aggregato): La media dei 24 punteggi orari, mostrata nella card principale.
        * Finestre di Pesca Ottimali: Blocchi di 2 ore con la media di pescaScore più alta.
        * Analisi Punteggio (Dettaglio): Un dialogo secondario mostra i fattori (easons) per un'ora rappresentativa.

----------------------------------------------------------------------
3. ORGANIZZAZIONE DEI MICROSERVIZI (BACKEND)
----------------------------------------------------------------------

L'architettura backend (pesca-api) è un'applicazione Node.js (Express.js) con i seguenti endpoint:
* /api/forecast: Restituisce le previsioni complete.
* /api/update-cache: Per l'aggiornamento proattivo della cache via Cron Job.
* /api/autocomplete: Per i suggerimenti di località.
* /api/reverse-geocode: Per la geolocalizzazione inversa.


----------------------------------------------------------------------
4. GESTIONE DELLA CACHE
----------------------------------------------------------------------

Strategia de caching a due livelli:

    4.1 Cache Backend (lato Server)
        * Gestita con 
ode-cache, ha un TTL di 6 ore.
        * Aggiornamento proattivo per Posillipo via Cron Job.

    4.2 Cache Frontend (lato Client)
        * L'app Flutter usa shared_preferences con un TTL di 6 ore.
        * Garantisce caricamenti istantanei e fallback su dati obsoleti in caso di errore di rete.
        * Le chiavi sono versionate per una facile invalidazione.


----------------------------------------------------------------------
5. API METEO UTILIZZATE
----------------------------------------------------------------------

Architettura ibrida e ottimizzata:
* Dati Giornalieri di Base (Tutte le località): WorldWeatherOnline (astronomia, maree).
* Dati Orari ad Alta Risoluzione (Tutte le località): Open-Meteo (temperatura, vento, onde, ecc.).
* Dati Premium (Solo Posillipo): Si tenta di usare Stormglass.io per sovrascrivere i dati marini standard con valori più precisi. In caso di fallimento, il sistema procede con i dati standard.


----------------------------------------------------------------------
6. STACK TECNOLOGICO E DEPLOYMENT
----------------------------------------------------------------------

* Backend (pesca-api): Node.js con Express.js.
* Frontend (pesca_app): Flutter con linguaggio Dart.
    * Package Principali: geolocator, shared_preferences, 'app_settings, weather_icons, 'fl_chart.
* Version Control: Entrambi i progetti sono su GitHub.
* Hosting & Deployment: Backend su Render.com con deploy automatico.


----------------------------------------------------------------------
7. STRUTTURA DEL PROGETTO AD ALTO LIVELLO
----------------------------------------------------------------------

* Backend (pesca-api):
    * Il codice è stato refattorizzato in una struttura modulare e manutenibile che separa le responsabilità in diverse cartelle e file (services/, domain/, utils/, 'forecast.assembler.js).

* Frontend (pesca_app):
    * Il codice è stato refattorizzato in una struttura modulare e scalabile, con una netta separazione tra models/, screens/, widgets/, services/ e utils/.

---

## STRUTTURA DETTAGLIATA DEL PROGETTO (Auto-generata)

### Frontend: `pesca_app`
La seguente è una rappresentazione commentata della struttura attuale del progetto frontend:

```
|-- .dart_tool/ # Cache e file interni generati dagli strumenti di sviluppo Dart.
|   |-- dartpad/
|   |-- extension_discovery/
|   |-- flutter_build/
|   |-- package_config.json
|   |-- package_graph.json
|   |-- version
|-- .idea/ # File di configurazione specifici dell'IDE.
|   |-- libraries/
|   |-- runConfigurations/
|   |-- modules.xml
|   |-- workspace.xml
|-- android/ # Wrapper nativo Android; contiene il codice sorgente per l'app Android.
|   |-- .gradle/
|   |-- .kotlin/
|   |-- app/
|   |-- gradle/
|   |-- .gitignore
|   |-- build.gradle.kts
|   |-- gradle.properties
|   |-- gradlew
|   |-- gradlew.bat
|   |-- hs_err_pid9352.log
|   |-- local.properties
|   |-- pesca_app_android.iml
|   |-- settings.gradle.kts
|-- assets/ # Risorse statiche come immagini e font.
|   |-- fonts/
|   |-- background.jpg
|   |-- background_daily.jpg
|   |-- background_nocturnal.jpg
|   |-- background_rainy.jpg
|   |-- background_sunset.jpg
|-- build/ # Cartella di output per gli artefatti di compilazione.
|   |-- .cxx/
|   |-- 36d1265d01e2ed95f91495b30967ce87/
|   |-- app/
|   |-- app_settings/
|   |-- flutter_assets/
|   |-- geolocator_android/
|   |-- native_assets/
|   |-- package_info_plus/
|   |-- path_provider_android/
|   |-- reports/
|   |-- shared_preferences_android/
|   |-- sqflite_android/
|   |-- windows/
|   |-- .last_build_id
|   |-- b9dbe592fc2ae558329e0a126bb30b5a.cache.dill.track.dill
|-- ios/ # Wrapper nativo iOS; contiene il progetto Xcode per l'app iOS.
|   |-- Flutter/
|   |-- Runner/
|   |-- Runner.xcodeproj/
|   |-- Runner.xcworkspace/
|   |-- RunnerTests/
|   |-- .gitignore
|-- lib/ # Cuore dell'applicazione. Contiene tutto il codice sorgente Dart.
|   |-- models/ # Contiene le classi modello per i dati.
|   |   |-- forecast_data.dart # Definisce il modello dati (ForecastData) che struttura tutte le informazioni ricevute dal backend.
|   |-- screens/ # Contiene le schermate complete.
|   |   |-- forecast_screen.dart # Widget principale che rappresenta l'intera schermata delle previsioni. Gestisce lo stato e assembla i componenti UI.
|   |-- services/ # Contiene la logica di business (chiamate API).
|   |   |-- api_service.dart # Centralizza la comunicazione con il backend. Contiene la logica per le chiamate HTTP all'API.
|   |-- utils/ # Contiene funzioni di utilità e helper.
|   |   |-- weather_icon_mapper.dart # Contiene la logica per mappare i codici meteo (WMO) a icone visive specifiche.
|   |-- widgets/ # Contiene widget riutilizzabili.
|   |   |-- fishing_score_indicator.dart # Widget UI circolare che visualizza il punteggio di pesca con un indicatore colorato.
|   |   |-- glassmorphism_card.dart # Widget riutilizzabile che crea un pannello con l'effetto 'vetro smerigliato' (glassmorphism).
|   |   |-- hourly_forecast.dart # Widget che renderizza la lista orizzontale delle previsioni per le prossime ore.
|   |   |-- location_services_dialog.dart # Mostra un popup per informare l'utente sulla necessità di attivare i servizi di localizzazione.
|   |   |-- main_hero_module.dart # Widget 'eroe' che mostra le informazioni principali: località, temperatura e punteggio di pesca.
|   |   |-- score_chart_dialog.dart # Mostra un popup contenente il grafico che visualizza l'andamento orario del punteggio di pesca.
|   |   |-- score_details_dialog.dart # Mostra un popup con i dettagli dei fattori (positivi/negativi) che hanno determinato il punteggio.
|   |   |-- search_overlay.dart # Gestisce la UI di ricerca della località, mostrando suggerimenti e gestendo l'input utente.
|   |   |-- stale_data_dialog.dart # Mostra un popup quando i dati meteo sono obsoleti e chiede all'utente se vuole continuare ad usarli.
|   |   |-- weekly_forecast.dart # Widget che renderizza la lista verticale delle previsioni per i giorni della settimana.
|   |-- main.dart # Punto di ingresso principale dell'app. Inizializza Flutter e avvia la schermata principale.
|-- linux/ # Wrapper nativo Linux.
|   |-- flutter/
|   |-- runner/
|   |-- .gitignore
|   |-- CMakeLists.txt
|-- macos/ # Wrapper nativo macOS.
|   |-- Flutter/
|   |-- Runner/
|   |-- Runner.xcodeproj/
|   |-- Runner.xcworkspace/
|   |-- RunnerTests/
|   |-- .gitignore
|-- test/ # Contiene i file per i test automatici.
|   |-- widget_test.dart
|-- web/ # Codice sorgente per la versione web.
|   |-- icons/
|   |-- favicon.png
|   |-- index.html
|   |-- manifest.json
|-- windows/ # Wrapper nativo Windows.
|   |-- flutter/
|   |-- runner/
|   |-- .gitignore
|   |-- CMakeLists.txt
|-- .flutter-plugins-dependencies # File di tipo '.flutter-plugins-dependencies'.
|-- .gitignore # Specifica i file da ignorare nel controllo di versione.
|-- .metadata # File generato da Flutter per tracciare le proprietà del progetto.
|-- .project-structure.json # File di dati/configurazione JSON.
|-- analysis_options.yaml # Configura le regole di analisi statica del codice.
|-- flutter_01.png # File immagine PNG.
|-- package-lock.json # File di dati/configurazione JSON.
|-- pesca_app.iml # File di tipo '.iml'.
|-- pubspec.lock # File che blocca le versioni esatte delle dipendenze.
|-- pubspec.yaml # File di manifesto del progetto: definisce dipendenze, asset, etc.
|-- README.md # File di documentazione Markdown.
```

### Backend: `pesca-api`
La seguente è una rappresentazione commentata della struttura attuale del progetto backend, arricchita con la conoscenza architetturale:

```
|-- api/ # Contiene i file che definiscono le route e la logica API.
|   |-- autocomplete.js # Modulo che esporta funzionalità o dati.
|   |-- reverse-geocode.js # Modulo che esporta funzionalità o dati.
|-- lib/ # Contiene tutta la logica di business e i moduli core dell'applicazione.
|   |-- domain/ # Contiene la logica di business pura, slegata da API e dettagli implementativi.
|   |   |-- score.calculator.js # Modulo dedicato al calcolo del pescaScore. Contiene la funzione che, dati i parametri meteo di una singola ora, calcola il punteggio numerico e le ragioni testuali.
|   |   |-- window.calculator.js # Modulo responsabile del calcolo delle finestre di pesca ottimali. Contiene la funzione che, data una serie di punteggi orari, identifica e formatta le migliori fasce orarie (es. '07:00 - 09:00').
|   |-- services/ # Contiene i moduli responsabili della comunicazione con le API esterne. Ogni file è uno 'specialista'.
|   |   |-- openmeteo.service.js # Gestisce le chiamate agli endpoint di Open-Meteo per recuperare i dati orari ad alta risoluzione (temperatura, vento, onde, etc.).
|   |   |-- stormglass.service.js # Gestisce la chiamata all'API premium di Stormglass.io per ottenere dati marini di alta precisione (usato solo per località specifiche come Posillipo).
|   |   |-- wwo.service.js # Gestisce la chiamata all'API di WorldWeatherOnline per recuperare i dati giornalieri di base, come astronomia (alba/tramonto) e maree.
|   |-- utils/ # Contiene funzioni di utilità pure, generiche e riutilizzabili in tutto il progetto.
|   |   |-- cache.manager.js # Centralizza la configurazione e l'esportazione dell'istanza di node-cache, gestendo il Time-To-Live (TTL) di default.
|   |   |-- formatter.js # Contiene tutte le funzioni di formattazione dei dati per la UI, come la conversione degli orari, la capitalizzazione delle stringhe e la determinazione dell'acronimo per lo stato del mare.
|   |   |-- wmo_code_converter.js # Modulo specializzato nel 'tradurre' i codici meteo numerici (standard WMO di Open-Meteo) nelle icone emoji e nelle direzioni del vento testuali (es. 'NNE') attese dal client.
|   |-- forecast-logic.js # Il 'direttore d'orchestra' e punto d'ingresso principale per la logica di forecast. Gestisce la cache, decide quale fonte dati usare (Standard vs Premium), chiama l'assemblatore per unificare i dati, e infine invoca la logica di dominio per arricchire l'output con il pescaScore e le finestre di pesca, producendo il JSON finale per l'app.
|   |-- forecast.assembler.js # Il 'maestro assemblatore'. Non contiene logica di business, ma orchestra i dati. Prende i dati grezzi e trasformati dai vari servizi e li combina nella struttura dati intermedia e unificata (unifiedForecastData).
|-- public/ # Contiene file statici serviti al client.
|   |-- fish_icon.png # File di tipo '.png'.
|   |-- half_moon.png # File di tipo '.png'.
|   |-- index.html # File HTML.
|   |-- logo192.png # File di tipo '.png'.
|   |-- logo512.png # File di tipo '.png'.
|   |-- manifest.json # File di dati/configurazione JSON.
|-- tools/ # Contiene script e tool di supporto per lo sviluppo.
|   |-- Update-ProjectDocs.ps1 # Questo script. Genera e aggiorna la documentazione unificata nel README principale del progetto.
|-- .env # Contiene le variabili d'ambiente (dati sensibili).
|-- package-lock.json # Registra la versione esatta di ogni dipendenza.
|-- package.json # File manifesto del progetto: dipendenze, script, etc.
|-- README.md # File di documentazione Markdown.
|-- server.js # Punto di ingresso principale dell'applicazione. Avvia il server Express e imposta le route.
```

<!-- SCRIPT:END -->






















