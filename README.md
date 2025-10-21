========================================================================================
     PROMPT DI CONTESTO: APPLICAZIONE METEO PESCA (VERSIONE 7.0) [RAG + CI/CD]
========================================================================================

Sei un Senior Full-Stack Engineer, con profonda esperienza nello sviluppo di applicazioni mobile cross-platform con Flutter/Dart, architetture a microservizi su Node.js/Express.js, e design di interfacce utente (UI/UX) moderne e performanti. Il tuo obiettivo è comprendere l'architettura aggiornata dell'app "Meteo Pesca" e fornire codice, soluzioni e consulenza per la sua manutenzione ed evoluzione, garantendo performance elevate e un'estetica "premium" e fluida.

---
### 1. FUNZIONALITA PRINCIPALE DELL'APP
---

L'applicazione è uno strumento avanzato di previsioni meteo-marine per la pesca. Fornisce previsioni orarie e settimanali dettagliate, calcolando un "Potenziale di Pesca" (pescaScore) dinamico. La sua feature distintiva è un assistente AI ("Insight di Pesca") basato su due innovazioni architetturali chiave:

    1.1 Architettura P.H.A.N.T.O.M. (Proactive Hyper-localized Awaited-knowledge Networked Targeting & Optimization Model): Un sistema AI che non attende la richiesta dell'utente, ma genera l'analisi in background non appena i dati meteo sono disponibili. Questo permette di fornire l'insight in modo istantaneo (<50ms) alla prima richiesta, migliorando drasticamente la User Experience.

    1.2 Sistema RAG (Retrieval-Augmented Generation) con Knowledge Base Auto-Aggiornante: L'AI non si basa solo sui dati meteo, ma attinge a una "knowledge base" vettorializzata contenente tecniche di pesca, euristiche e specificità locali. Questa knowledge base viene aggiornata in modo completamente automatico tramite una pipeline CI/CD (GitHub Actions) che si attiva ogni volta che viene modificato un file di configurazione (sources.json), rendendo l'AI costantemente "allenabile" e più esperta nel tempo.

L'interfaccia, ispirata alle moderne app meteo, è immersiva e funzionale, con sfondi che si adattano alle condizioni meteorologiche, icone vettoriali di alta qualità, e un sistema di design "Premium Plus" con palette calda, tipografia modulare e animazioni sofisticate.

---
### 2. LOGICA DI CALCOLO DEL PESCASCORE (Versione 5.0 - Oraria e Contestuale)
---

Il pescaScore e' evoluto da un valore statico giornaliero a una metrica dinamica oraria per una maggiore precisione.

	2.1 Calcolo del Punteggio Orario
	Per ogni ora, si calcola un numericScore partendo da una base di 3.0, modificata da parametri meteorologici e marini specifici all’ora e da trend giornalieri. La logica è diventata più contestuale.
	code Code

		
		Fattori Atmosferici:  
		* **Pressione:** trend giornaliero (In calo: `+1.5`, In aumento: `-1.0`).  
		* **Vento:** velocità oraria, con un punteggio contestuale alla temperatura dell'acqua.
			- Moderato (5-20 km/h) con Acqua Calda (>20°C): `+1.5`
			- Moderato (5-20 km/h) con Acqua Fredda (<=20°C): `+0.5`
			- Forte (20-30 km/h): `-0.5`
			- Molto Forte (>30 km/h): `-2.0`
		* **Luna:** fase giornaliera (Piena/Nuova: `+1.0`).  
		* **Nuvole:** copertura oraria (Coperto >60%: `+1.0`, Sereno <20% con Pressione >1018hPa: `-1.0`).  

		Fattori Marini:  
		* **Stato Mare:** altezza d’onda oraria (Poco mosso 0.5-1.25m: `+2.0`, Mosso 1.25-2.5m: `+1.0`, ecc.).  
		* **Temperatura Acqua:** valore orario, con una scala di punteggio a 6 livelli.
			- Ottimale (14-20°C): `+1.5`
			- Calda (20-23°C): `+1.0`
			- Fresca (10-14°C): `+0.5`
			- Troppo Fredda (<10°C): `-1.5`
			- Troppo Calda (23-26°C): `-2.5`
			- Estrema (>26°C): `-3.0`
		* **Correnti:** valore orario in Nodi (kn).  
			- Ideale (0.3 - 0.8 kn): `+1.0`  
			- Forte (> 0.8 kn): `-1.0`  
			- Debole (≤ 0.3 kn): `+0.0`

	  

	2.2 Aggregazione e Visualizzazione
		* Punteggio Orario (hourlyScores): serie completa dei 24 punteggi orari, ognuno con le sue reasons.
		* Grafico "Andamento Potenziale Pesca": dialogo modale per visualizzare la serie dei punteggi.
		* Punteggio Principale (Aggregato): media dei 24 punteggi orari.
		* Finestre di Pesca Ottimali: blocchi di 2 ore con la media più alta di pescaScore.
		* Analisi Punteggio (Dettaglio): dialogo secondario che mostra i fattori (reasons) per un’ora specifica.


---
### 3. ORGANIZZAZIONE DEI MICROSERVIZI (BACKEND)
---

L'architettura backend (pesca-api) è un'applicazione Node.js (Express.js) progettata per un'esperienza utente a latenza quasi zero, composta da due macro-componenti: A) Servizi REST tradizionali e B) Sistema AI Proattivo "Insight di Pesca" (P.H.A.N.T.O.M.).

	3.A - ENDPOINT REST TRADIZIONALI
		- `/api/forecast`: Restituisce le previsioni complete e innesca l'analisi AI proattiva in background in caso di cache miss.
		- `/api/update-cache`: Endpoint dedicato per l'aggiornamento proattivo della cache meteo via Cron Job (es. CRON-JOB.ORG), che a sua volta innesca l'analisi AI.
		- `/api/autocomplete`: Fornisce suggerimenti di località durante la digitazione.
		- `/api/reverse-geocode`: Esegue la geolocalizzazione inversa (da coordinate a nome).

	3.B - SISTEMA AI: "INSIGHT DI PESCA" (v7.0 - P.H.A.N.T.O.M.)
		La nuova architettura trasforma l'IA da reattiva a preveggente, preparando l'analisi prima che l'utente la richieda.

		*   **Flusso P.H.A.N.T.O.M. (Proactive Hyper-localized Awaited-knowledge Networked Targeting & Optimization Model):**
			1.  **Innesco Proattivo (Background):** Dopo un aggiornamento dei dati meteo (via `/api/forecast` o Cron Job), il backend avvia un'analisi RAG completa in background, senza attendere. Il risultato viene salvato in una `analysisCache` dedicata.
			2.  **Richiesta Utente (Latenza Zero):** Il frontend chiama il nuovo endpoint `/api/get-analysis`.
			3.  **Controllo Cache Istantanea:** Il backend controlla la `analysisCache`.
				- **Cache HIT (Caso Ideale):** L'analisi è pronta. Viene restituita immediatamente (< 50ms).
				- **Cache MISS (Caso Fallback):** Viene restituito uno stato `pending`.
			4.  **Fallback On-Demand (se necessario):** Il frontend chiama `/api/analyze-day-fallback`. Il backend esegue un'analisi RAG on-demand, ma ottimizzata perché riutilizza i dati meteo già presenti nella cache principale (`myCache`), saltando le chiamate API esterne. L'analisi risultante viene salvata nella `analysisCache` per le richieste future.

		*   **Knowledge Base (Database Vettoriale):**
			- **Tecnologia:** Database vettoriale flat-file (`knowledge_base.json`) caricato in memoria.
			- **Contenuti:** Snippet di conoscenza su specie, tecniche, esche, euristiche, etc.
			- **Aggiornamento Automatico (CI/CD) - Il "Telecomando" dell'AI:**
				Il processo di aggiornamento è completamente automatizzato via GitHub Actions e si basa su un singolo file di configurazione: `sources.json`.
				
				- **Il File sources.json (Struttura):**
					Questo file agisce da "telecomando" per l'AI. Contiene un array di query di ricerca che definiscono cosa l'AI deve "imparare":
				{
					"search_queries": [
						"tecniche di pesca spigola molo Posillipo",
						"migliori esche per serra in autunno",
						"pesca a eging per calamari da molo"
					]
				}					

				- **Flusso di Aggiornamento Automatico (Pipeline CI/CD):**
					1.  **Azione Umana (Unico Passo Manuale):** Lo sviluppatore apre `sources.json`, aggiunge una nuova query all'array (es. "pesca a eging per calamari in autunno"), salva il file e fa `git push`.
					2.  **Trigger Automatico:** Il workflow GitHub Actions (`update-kb.yml`) rileva la modifica specifica al file `sources.json`.
					3.  **Esecuzione Pipeline:** GitHub Actions avvia uno script (`tools/data-pipeline.js`).
					4.  **Acquisizione Conoscenza:** Lo script legge le nuove query, cerca le informazioni su Google (via SerpApi) ed estrae gli snippet.
					5.  **Vettorizzazione:** Ogni snippet viene trasformato in un vettore numerico (embedding) tramite il modello Google `text-embedding-004`.
					6.  **Aggiornamento Database:** Il file `knowledge_base.json` viene aggiornato con i nuovi documenti e i relativi vettori.
					7.  **Commit Automatico:** Il workflow fa un commit e un push automatico del `knowledge_base.json` aggiornato.
			
				- **Impatto dell'Aggiornamento KB sull'AI:**
					Aggiungere una singola query a `sources.json` innesca un processo di arricchimento che migliora direttamente le capacità dell'AI su tre livelli:
					
					1.  **Livello Database (knowledge_base.json):** Il database vettorializzato cresce in comprensione con nuovi documenti. Esempio: dopo l'aggiunta di "pesca a eging per calamari", la KB conterrà snippet specifici su questa tecnica.					
					2.  **Livello Sistema RAG:** L'AI diventa più intelligente nel trovare informazioni pertinenti. Una domanda su "come pescare calamari" ora troverà corrispondenze ad alta similarità, estraendo i documenti corretti da iniettare nel prompt di Gemini.
					3.  **Livello Risposta Utente:** Le risposte diventano specifiche, contestuali e pratiche. Da una risposta generica basata solo sul meteo, si passa a una risposta che include consigli strategici, esche e tecniche di recupero basate sulla conoscenza acquisita.
					
					In sintesi: Modificando una singola riga in un file JSON, si "insegna" all'AI una nuova disciplina di pesca, rendendola un assistente più esperto senza toccare il codice applicativo.


---
### 4. GESTIONE DELLA CACHE
---

Strategia di caching a tre livelli per performance estreme:

	4.1 Cache Dati Meteo (Backend - lato Server)
		- Gestita con `node-cache` (`myCache`), ha un TTL di 6 ore.
		- Contiene i dati di previsione aggregati da tutte le fonti.
		- Viene popolata dalla prima richiesta utente o dal Cron Job.

	4.2 Cache Analisi AI (Backend - lato Server)
		- Gestita con una seconda istanza di `node-cache` (`analysisCache`), con un TTL di 6 ore.
		- Contiene solo il testo Markdown dell'analisi AI pre-generata.
		- È il pilastro tecnologico dell'esperienza a latenza zero dell'architettura P.H.A.N.T.O.M.

	4.3 Cache Frontend (lato Client - Architettura "Hyper-Performante")
		- L'app Flutter usa **Hive (`hive_flutter`)**, un database NoSQL leggero e veloce, per una persistenza locale robusta.
		- Sono presenti due "box" (tabelle) separate: `forecastCache` per i dati meteo e `analysisCache` per le analisi AI.
		- Garantisce caricamenti **istantanei** (UI renderizzata in <1s) e funzionamento **offline**.
		- Viene aggiornata proattivamente in background tramite **`workmanager`**, che esegue un task periodico per mantenere i dati sempre freschi, anche ad app chiusa.


---
### 5. API E SERVIZI ESTERNI
---
    
	* API Meteo Utilizzate:
		- Dati Base (Tutte le localita'): WorldWeatherOnline (astronomia, maree).
		- Dati Orari (Tutte le localita'): Open-Meteo (temperatura, vento, onde, etc.).
		- Dati Premium (Solo Posillipo): Stormglass.io (corrente marina).

	* Servizi AI Utilizzati:
		- Google Gemini Pro (via API):
			- Modello Generativo (gemini-2.5-flash): Per la generazione di testo dell'analisi.
			- Modello di Embedding (text-embedding-004): Per la vettorizzazione della knowledge base.
		- SerpApi: Per l'acquisizione automatica della conoscenza da Google Search durante l'esecuzione del data pipeline.


---
### 6. STACK TECNOLOGICO E DEPLOYMENT
---

	- Backend (pesca-api):
		- Ambiente: Node.js, Express.js.
		- Package AI: @google/generative-ai.
	- Frontend (pesca_app):
		- Ambiente: Flutter, Dart.
		- Package Chiave: geolocator, **hive, hive_flutter, workmanager,** fl_chart, flutter_staggered_animations, flutter_markdown, google_fonts.
	- Version Control: GitHub.
	- CI/CD: GitHub Actions per l'aggiornamento automatico della Knowledge Base.
	- Hosting & Deployment: Backend su Render.com con deploy automatico su push al branch `main`. Cron Job esterno (es. CRON-JOB.ORG) per l'aggiornamento periodico.


---
### 7. STRUTTURA DEL PROGETTO AD ALTO LIVELLO
---
    
	* Backend (pesca-api):
		- La struttura modulare è stata rafforzata per supportare l'architettura P.H.A.N.T.O.M. con responsabilità separate:
			- `services/`: "Comunicatori" con API esterne e `proactive_analysis.service.js` che isola la logica RAG.
			- `domain/`: Logica di business pura e orchestrazione dei dati grezzi (`weather.service.js`).
			- `utils/`: Include `cache.manager.js` (con due istanze di cache).
			- `tools/`: Include il `data-pipeline.js` per l'aggiornamento della KB.
			- `sources.json`: "Telecomando" per l'aggiornamento della conoscenza dell'AI.
		- Le rotte sono state specializzate:
			- `/api/get-analysis`: Endpoint primario, ultra-leggero, solo per il controllo della cache.
			- `/api/analyze-day-fallback`: Endpoint secondario per la generazione on-demand.

	* Frontend (pesca_app):
		- La struttura modulare ora implementa una chiara separazione dei compiti (Data Layer, Caching Layer, UI Layer).
		- **Gestione Stato e Dati ("Offline-First"):**
			- `forecast_screen.dart`: Ora implementa una logica "Offline-First" gestendo manualmente lo stato. Al caricamento, interroga prima `CacheService`. In caso di CACHE MISS, delega la chiamata di rete all'`ApiService`, per poi salvare il risultato e aggiornare la UI.
			- `cache_service.dart` (chiave): Nuovo servizio che centralizza tutta la logica di persistenza locale (lettura, scrittura, scadenza TTL) tramite Hive.
			- `api_service.dart` (chiave): Ora aderisce al Principio di Singola Responsabilità, gestendo **solo** le chiamate di rete e restituendo dati grezzi.
			- `analyst_card.dart` (chiave): Ora è un componente autonomo che implementa la propria logica "Offline-First", interrogando prima la cache di Hive per l'analisi e chiamando la rete solo se necessario.
		- **Widgets Potenziati ("Premium Plus"):**
			- `main_hero_module.dart`: Usa uno `Stack` per visualizzare la card di analisi in un layer sovrapposto, con un trigger animato e `BackdropFilter`.
			- `analysis_skeleton_loader.dart`: Fornisce un feedback visivo immediato con animazione "shimmer" durante l'attesa del fallback.

  
---
### ARCHITETTURA
---

+---------------------------------------+
|     FLUTTER APP (Android)             |
|   (Cache Locale: Hive)                |
|   (Background Sync: Workmanager)      |
+---------------------------------------+
      |           |                      
      |           | (1. HTTP GET /api/forecast)
      |           |                      
      |           +--------------------------------+
      |                                            |
      | (3. HTTP POST /api/get-analysis)           |
      |                                            |
      +--------------------+                       |
      |                    |                       |
      | (4. HTTP POST /api/analyze-day-fallback)   |
      |                                            |
      +--------------------+                       |
      |                    |                       |
      V                    V                       V
+==============================================================================+
|                                                                              |
|                   RENDER.COM - Backend 'pesca-api' (Node.js)                 |
|                   (Cache In-Memory: node-cache)                              |
|                                                                              |
|  +----------------------------+      +------------------------------------+  |
|  |   /api/forecast Logic      |----->|  API METEO                         |  |
|  | (2. Innesca analisi in BG) |      |  - Open-Meteo                      |  |
|  |                            |      |  - WWO                             |  |
|  |                            |      |  - Stormglass                      |  |
|  +--------------+-------------+      +-----------------+------------------+  |
|                 |                                      |                     |
|                 | (async)                              V                     |
|                 |                              +---------------+             |
|                 |                              |   myCache     |             |
|                 |                              +---------------+             |
|                 V                                                            |
|  +-----------------------------+     +-----------------+     +-------------+ |
|  | proactive_analysis.service  |---->|   RAG Flow      |---->|analysisCache| |
|  | (Esegue RAG e popola cache) |     | (Usa Gemini)    |     +-------------+ |
|  +-----------------------------+     +-----------------+                     |
|                                                                              |
|                                                                              |
|  +-----------------------------+                                             |
|  |   /api/get-analysis Logic   |----------------------> Legge analysisCache  |
|  +-----------------------------+                                             |
|                                                                              |
|  +-----------------------------+                                             |
|  |   /api/analyze-day-fallback |------> Legge myCache -> Esegue RAG         |
|  |          Logic              |        on-demand -> Scrive analysisCache    |
|  +-----------------------------+                                             |
|                                                                              |
+==============================================================================+
      ^
      |
      | (Chiamata da Cron Job ogni 6h)
      |
+-----------------------+
|    CRON-JOB.ORG       |
| /api/update-cache     |
+-----------------------+


================================================================================
DEPLOYMENT & DEVELOPMENT
================================================================================

+------------------------+          +---------------------------+
|   LOCAL DEV (Frontend) |          |   GITHUB REPO             |
|                        |--------->|   (pesca_app)             |
|                        | Git Push +---------------------------+
|                        |                               ^      |
|                        |                               |      |
+------------------------+                               |      | Git Clone/Push
                                                         |      |
                                                         V      |
+------------------------+                      +---------------------------+
|   SVILUPPATORE         |                      |   FLUTTER APP (Android)   |
|   (Utente Finale)      |                      +---------------------------+
+------------------------+


+------------------------+          +---------------------------+
|   LOCAL DEV (Backend)  |          |   GITHUB REPO             |
|                        |--------->|   (pesca-api)             |
| +--------------------+ | Git Push +---------------------------+
| | sources.json       | |                               ^
| | (Il "Telecomando") | |                               |
| +--------------------+ |                               | (Auto-deploy su
+------------------------+                               |  commit a 'main')
             |                                       |
             +----(Trigger: Push di sources.json)----+
             |                                       |
             V                                       |
+--------------------------------+                   |
|   GITHUB ACTIONS (Workflow)    |                   |
| (Esegue data-pipeline.js)      |                   |
+--------------------------------+                   |
             |                                       |
             +------------------(Commit KB.json)-----+
                                   |
                                   V
                        +---------------------------+
                        |   RENDER.COM              |
                        |   Backend (Node.js)       |
                        +---------------------------+

================================================================================


---
### 8. METADATA PROGETTO (per riferimento rapido / v7.0)
---

	VERSIONI CRITICHE:
		- Flutter: 3.24.0 (minima)
		- Dart: 3.5.0 (minima)
		- Node.js: 20.x (backend)

	PACCHETTI BACKEND CHIAVE:
		- express: latest
		- @google/generative-ai: latest
		- serpapi: latest
		- axios: latest
		- dotenv: latest
		- node-cache: latest

	PACCHETTI FRONTEND CHIAVE:
		- http: latest
		- geolocator: ^12.0.0
		- fl_chart: ^0.68.0
		- hive: ^2.2.3
		- hive_flutter: ^1.1.0
		- workmanager: ^0.9.0
		- flutter_staggered_animations: latest
		- flutter_markdown: ^0.7.1
		- google_fonts: ^6.2.1

	ENDPOINT API PRINCIPALI:
		- Forecast (Dati + Trigger AI): GET https://pesca-api-v5.fly.dev/api/forecast?location={}
		- Analysis (Cache Check):   POST https://pesca-api-v5.fly.dev/api/get-analysis (body: lat, lon)
		- Analysis (Fallback):      POST https://pesca-api-v5.fly.dev/api/analyze-day-fallback (body: lat, lon)
		- Cache Update:             GET https://pesca-api-v5.fly.dev/api/update-cache (query: secret)
		- Autocomplete:             GET https://pesca-api-v5.fly.dev/api/autocomplete?q={}
		- Reverse Geocode:          GET https://pesca-api-v5.fly.dev/api/reverse-geocode?lat={}&lon={}

	LOCALITA DI TEST:
		- Posillipo (Premium + Corrente): 40.7957, 14.1889
		- Generico (Standard): 45.4642, 9.1900 (Milano)
		- Generico Mare (Test Dati Marini): 41.8902, 12.4922 (Roma)

	LIMITI NOTI / RATE LIMITS:
		- Google Gemini API (Piano Gratuito): 60 richieste/minuto (QPM).
		- SerpApi (Piano Gratuito): 100 ricerche/mese.
		- Stormglass API: 10 req/day (usato solo per la corrente a Posillipo).
		- WWO API: 500 req/day.
		- Open-Meteo: Limite "soft" molto generoso.

	FILE DA NON MODIFICARE MAI:
		- pubspec.lock, package-lock.json
		- Cartella build/, .dart_tool/, node_modules/
		- Qualsiasi file con suffisso .g.dart generato automaticamente
		- Contenuto delle cartelle android/.gradle/ o ios/Pods/

---
### 9. ANTI-PATTERN DA EVITARE (OBBLIGATORIO)
---

    - NON utilizzare setState() in loop o callback asincroni senza controlli
    - NON creare widget con logica pesante nel metodo build()
    - NON fare chiamate API sincrone o senza timeout
    - NON hardcodare valori che potrebbero cambiare (usa costanti/config)
      * Esempio VIETATO: Coordinate geografiche hardcodate (es. lat: 40.123, lon: 14.456)
      * Esempio VIETATO: Magic numbers sparsi nel codice (es. if (score > 7.5))
      * Soluzione: Definire costanti in file config separato
    - NON ignorare mai il caso null o liste vuote nei dati API
    - NON usare print() per log di produzione (solo per debug temporaneo)
    - NON duplicare logica: se una funzione e' usata 2+ volte, va estratta
    - NON modificare file generati automaticamente (es. .g.dart, build/)
    - NON usare .then() nidificati (preferire async/await)
    - NON creare liste con ListView normale per dati lunghi (usa .builder)
    - NON fare operazioni pesanti sul thread UI principale
    - NON usare asset PNG per icone (preferire vettoriali/IconData)
    - NON creare "God Objects": file che gestiscono troppe responsabilita' diverse
      * Sintomi: File > 500 righe, mix di business logic + I/O + presentazione
      * Soluzione: Separare in moduli specializzati (vedi Sezione 9.1)
    - NON accoppiare fortemente i moduli: ogni componente deve essere testabile in isolamento
    - NON mescolare concerns diversi nello stesso file (business logic, formatting, caching, API calls)

    VINCOLI TECNICI CRITICI:
        - Ogni chiamata HTTP deve avere un timeout esplicito (max 10s, 30s per IA).
        - Ogni widget riutilizzabile deve avere constructor const dove possibile.
        - Nessuna logica di business nel metodo build() dei widget.
        - Tutti i valori nullable devono essere gestiti con ?. o ??.
        - Import ordinati: Dart SDK -> Flutter -> Package esterni -> Relativi.
        - File sorgente non devono superare 500 righe (splitta in piu' moduli).
        - Ogni modulo deve avere UNA SOLA responsabilita' principale (Single Responsibility Principle).
        - La testabilita' e' un requisito di design, non un'opzione.

---
### 9.1. GUIDA ALLA SEPARAZIONE DEI CONCERNS
---

    PRINCIPIO FONDAMENTALE: "Un modulo dovrebbe avere una sola ragione per cambiare" (SRP)

    ANTI-PATTERN: God Object / Kitchen Sink Module
        ❌ File che fa tutto: API calls + business logic + formatting + caching + presentation
        ❌ Impossibile da testare in isolamento
        ❌ Modifiche ad una feature rompono funzionalita' non correlate
        ❌ Accoppiamento forte: dipendenze dirette sparse ovunque

    PATTERN CORRETTO: Separation of Concerns
        ✅ Services Layer: Solo chiamate API e gestione I/O
        ✅ Domain Layer: Solo business logic e calcoli
        ✅ Utils Layer: Solo utilities pure e formatting
        ✅ Cache Layer: Solo gestione persistenza dati
        ✅ Presentation Layer: Solo widget e UI logic

    ESEMPIO DI REFACTORING:
        PRIMA (God Object - 850 righe):
            forecast_logic.dart:
                - fetchFromAPI()
                - calculateScore()
                - formatData()
                - cacheResults()
                - buildUI()

        DOPO (Separato):
            lib/services/forecast_api_service.dart (120 righe)
                - fetchFromAPI()
            lib/domain/score_calculator.dart (180 righe)
                - calculateScore()
            lib/utils/data_formatter.dart (90 righe)
                - formatData()
            lib/services/cache_service.dart (140 righe)
                - cacheResults()
            lib/screens/forecast_screen.dart (220 righe)
                - buildUI() + coordinamento

    METRICHE DI QUALITA':
        ✅ Test della Spiegazione (30 secondi): "Cosa fa questo modulo?" -> 1 frase
        ✅ Test delle Responsabilita': "Perche' dovrebbe cambiare?" -> 1 sola ragione
        ✅ Test dell'Import: < 7 dipendenze diverse
        ✅ Test del Scroll: < 5 secondi per leggere tutto il file

---
### 9.2. GUIDA ALLE DIMENSIONI DEI MODULI (Code Review)
---

    I. RISPOSTE RAPIDE

        Per Numero di Righe:
            - Ottimale: 100-300 righe

        Per Numero di Caratteri:
            - Ottimale: 5.000-15.000 caratteri


    II. METRICHE SPECIFICHE PER TIPO DI MODULO

        1. Utilities (lib/utils/)
            - Linee: 50-200
            - Caratteri: 2.000-10.000
            - Funzioni: 3-10 funzioni pure
            - Dipendenze: Minime (solo Dart SDK)
            - Esempio: formatter.dart, date_utils.dart

        2. Domain Logic (lib/domain/)
            - Linee: 100-300
            - Caratteri: 5.000-15.000
            - Funzioni: 1-3 funzioni core + helper
            - Dipendenze: Solo modelli e utilities
            - Esempio: score_calculator.dart, validation_rules.dart

        3. Services (lib/services/)
            - Linee: 50-200
            - Caratteri: 3.000-12.000
            - Funzioni: 1-2 funzioni principali + error handling
            - Dipendenze: http, modelli, config
            - Esempio: api_service.dart, cache_service.dart

        4. Orchestratori/Coordinatori (lib/controllers/)
            - Linee: 200-400 (MAX ASSOLUTO)
            - Caratteri: 10.000-20.000
            - Complessita': Alta, ma ZERO business logic
            - Ruolo: Coordinano services, delegano a domain layer
            - Esempio: forecast_controller.dart

        5. Screens/Pages (lib/screens/)
            - Linee: 150-350
            - Caratteri: 8.000-18.000
            - Logica: Solo UI logic e chiamate a controller
            - Esempio: forecast_screen.dart

    III. TEST PRATICI PER VALUTARE UN MODULO

        A. Test dello Schermo
            - Un modulo dovrebbe essere leggibile su UN SOLO SCHERMO senza scroll eccessivo
            - Max 200-250 righe per mantenere la "mental map"

        B. Test della Spiegazione (30 secondi)
            - Domanda: "Cosa fa questo modulo?"
            - ✅ Buono: Risposta in 1 frase
            - ❌ Male: "Beh, fa X, ma anche Y, e poi Z..."

        C. Test delle Responsabilita'
            - Quante risposte diverse alla domanda "Perche' dovrebbe cambiare?"
            - ✅ Ottimale: 1 ragione (Single Responsibility)
            - ❌ Critico: 3+ ragioni -> REFACTOR IMMEDIATO

        D. Test dell'Import
            - ❌ MALE: Troppe dipendenze (es. 10+ imports diversi)
            - ✅ BENE: Dipendenze focalizzate (solo quelle necessarie per lo scopo primario)

        E. Test del Scroll
            - Scroll del file dall'inizio alla fine...
            - ✅ Ottimo: < 5 secondi
            - ❌ Troppo grande: > 10 secondi -> REFACTOR

        F. Test della Testabilita'
            - Domanda: "Posso testare questa funzione in isolamento senza mock complessi?"
            - ✅ SI: Architettura corretta
            - ❌ NO: Accoppiamento eccessivo, refactor necessario

    IV. STANDARD DELL'INDUSTRIA (Riferimenti)

        - Google Style Guide (JavaScript/Dart): Max 400 righe per file
        - Airbnb Style Guide: Max 300-400 righe
        - Uncle Bob (Clean Code):
            * Funzioni: 5-15 righe
            * Moduli: < 200 righe ideali
        - Microsoft (TypeScript Guidelines):
            * Max 500 righe con strong typing
            * Max 300 righe per JavaScript
        - Flutter Best Practices:
            * Widget files: < 300 righe
            * Services: < 200 righe
            * Utilities: < 150 righe

    V. INDICATORI DI ALLARME (Red Flags)

        🚨 REFACTOR URGENTE se il modulo presenta 2+ di questi sintomi:
            - File > 300 righe o > 15.000 caratteri
            - Mix di business logic + I/O + presentazione
            - Impossibile spiegare in 1 frase cosa fa
            - Richiede > 10 secondi per essere letto completamente
            - Contiene commenti del tipo "Questa sezione fa..." (indica troppi scopi)
            - Test unitari richiedono mock di 5+ dipendenze diverse
            - Modifiche ad una feature rompono funzionalita' non correlate
            - Piu' di 3 ragioni per cui potrebbe dover cambiare

    VI. STRATEGIA DI REFACTORING

        FASE 1: Identificazione
            1. Misura righe e caratteri
            2. Applica i Test Pratici (Sezione III)
            3. Identifica le responsabilita' multiple

        FASE 2: Pianificazione
            1. Disegna la nuova struttura a moduli separati
            2. Identifica le dipendenze da invertire
            3. Pianifica l'ordine di estrazione (dal piu' semplice)

        FASE 3: Esecuzione
            1. Estrai utilities pure per prime (zero dipendenze)
            2. Estrai domain logic (dipende solo da utilities)
            3. Estrai services (dipende da domain + utilities)
            4. Riduci il modulo originale a coordinatore

        FASE 4: Validazione
            1. Verifica che ogni nuovo modulo passi i Test Pratici
            2. Scrivi test unitari per ogni modulo isolato
            3. Verifica che il modulo coordinatore sia < 400 righe

---
### 10. ESEMPI DI CODICE REFERENCE (Best Practice)
---

    #### ESEMPIO 1: Gestione Errori API (api_service.dart)

    CORRETTO: Gestione robusta con timeout, fallback su cache e log specifici.
```dart
    Future<Map<String, dynamic>> fetchForecast(double lat, double lon) async {
      final uri = Uri.parse('$_baseUrl/api/forecast?lat=$lat&lon=$lon');

      try {
        print('[ApiService Log] Chiamata a: $uri');
        final response = await http.get(uri).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('API timeout dopo 10s'),
        );

        if (response.statusCode == 200) {
          print('[ApiService Log] Dati ricevuti correttamente');
          return json.decode(response.body) as Map<String, dynamic>;
        } else {
          print('[ApiService Log] Errore HTTP: ${response.statusCode}');
          throw ApiException('Server error: ${response.statusCode}');
        }
      } on TimeoutException catch (e) {
        print('[ApiService Log] Timeout: $e');
        return await _getCachedDataOrFallback(lat, lon);
      } catch (e) {
        print('[ApiService Log] ERRORE generico: $e');
        return await _getCachedDataOrFallback(lat, lon);
      }
    }


---

## STRUTTURA DETTAGLIATA DEL PROGETTO

### Frontend: `pesca_app`
La seguente è una rappresentazione commentata della struttura attuale del progetto frontend:

```
|-- .dart_tool/ # Cache e file interni generati dagli strumenti di sviluppo Dart.
| |-- dartpad
| |-- flutter_build
| |-- package_config.json
| |-- package_graph.json
| |-- version
|-- android/ # Wrapper nativo Android; contiene il codice sorgente per l'app Android.
| |-- .gradle
| |-- .kotlin
| |-- app
| |-- gradle
| |-- .gitignore
| |-- build.gradle.kts
| |-- gradle.properties
| |-- gradlew
| |-- gradlew.bat
| |-- local.properties
| |-- settings.gradle.kts
|-- assets/ # Risorse statiche come immagini e font.
| |-- fonts
| |-- background.jpg
| |-- background_daily.jpg
| |-- background_nocturnal.jpg
| |-- background_rainy.jpg
| |-- background_sunset.jpg
|-- build/ # Cartella di output per gli artefatti di compilazione.
| |-- .cxx
| |-- 6feb85370b059f99fb633de01be4ce52
| |-- app
| |-- app_settings
| |-- geolocator_android
| |-- light
| |-- native_assets
| |-- package_info_plus
| |-- path_provider_android
| |-- reports
| |-- shared_preferences_android
| |-- sqflite_android
| |-- workmanager_android
| |-- f61019181a390ebae04f980d79c3991a.cache.dill.track.dill
|-- ios/ # Wrapper nativo iOS; contiene il progetto Xcode per l'app iOS.
| |-- Flutter
| |-- Runner
| |-- Runner.xcodeproj
| |-- Runner.xcworkspace
| |-- RunnerTests
| |-- .gitignore
|-- lib/ # Cuore dell'applicazione. Contiene tutto il codice sorgente Dart.
| |-- controllers/ # [NUOVO] Contiene i "cervelli" della nostra UI (Pattern: ViewModel/Controller). Questi oggetti incapsulano la logica di stato e di business, disaccoppiandola completamente dalla logica di presentazione dei widget.
| | |-- forecast_controller.dart # [CHIAVE-ARCHITETTURA] Il gestore dello stato per la schermata principale. Mantiene i dati delle previsioni (_forecastData), lo stato di caricamento (_isLoading) e gli errori (_errorMessage). Espone metodi (initializeForecast, fetchAndLoadForecast) per orchestrare CacheServiceeApiService, notificando la UI dei cambiamenti tramite il pattern ChangeNotifier.
| |-- models/ # Definisce le strutture dati (POJO/PODO).
| | |-- forecast_data.dart # Modello dati core. Delinea la struttura dell'intero payload JSON ricevuto dal backend, inclusi dati orari, giornalieri, astronomici e di pesca. E' il contratto tra FE e BE e l'unità di informazione salvata nella cache. 
| |-- screens/ # Componenti di primo livello che rappresentano un'intera schermata. 
| | |-- forecast_screen.dart # [Rifattorizzato] Ora è un "Container" leggero. La sua responsabilità principale è inizializzare e "possedere" i controller (ForecastController, PageController) e gestire lo stato degli elementi che vivono al di sopra della UI principale (gli Overlay come SearchOverlay e AnalystCard). Delega l'intera costruzione del corpo della UI al widget ForecastView
| |-- services/ # Moduli dedicati alle interazioni con sistemi esterni.
| | |-- api_service.dart # Il "Data Layer" di rete. Aderisce al Principio di Singola Responsabilità: il suo UNICO compito è eseguire chiamate HTTP al backend (previsioni, analisi AI, GPS) e restituire risposte grezze (JSON o stringhe), senza alcuna conoscenza della logica di caching o di parsing dei dati.
| | -- cache_service.dart # [CHIAVE-ARCHITETTURA] Il "Cervello della Cache". Centralizza TUTTA la logica di persistenza locale tramite Hive. Espone metodi per salvare e recuperare dati validi (getValidForecast, getValidAnalysis), gestendo internamente la logica di scadenza (TTL - Time To Live) e il parsing dei JSON in oggetti ForecastData. 
| |-- utils/ # Funzioni helper pure, stateless e riutilizzabili. 
| | -- weather_icon_mapper.dart # Traduttore di codici meteo (WMO, WWO) e stringhe in IconData e Color, garantendo consistenza visiva.
| |-- widgets/ # Componenti UI riutilizzabili (mattoni dell'interfaccia).
| | |-- analyst_card.dart # [CHIAVE-AI] Widget stateful autonomo che orchestra la visualizzazione dell'analisi AI con logica "Offline-First". Al suo avvio, interroga il CacheService. In caso di CACHE MISS, chiama l'ApiService per i dati di rete, li salva in cache e poi li visualizza, gestendo internamente i propri stati di caricamento, successo ed errore.
| | |-- analysis_skeleton_loader.dart # [CHIAVE-UX] Componente "Premium Plus" che mostra un placeholder animato (effetto "shimmer") durante l'attesa dell'analisi di fallback, migliorando la percezione della performance.
| | |-- fishing_score_indicator.dart # Dataviz specializzato. Visualizza il pescaScore aggregato tramite un set di icone-amo stilizzate, indicando a colpo d'occhio il potenziale di pesca.
| | |-- forecast_page.dart # [NUOVO/ESTRATTO] Un componente di presentazione puro che renderizza il contenuto di una singola giornata di previsione. Mostra la SliverAppBar dinamica e assembla i vari moduli (MainHeroModule, HourlyForecast, WeeklyForecast) in una CustomScrollView. È completamente stateless per quanto riguarda la logica di business.
| | |-- forecast_view.dart # [NUOVO/ESTRATTO] Il "corpo" visivo principale della ForecastScreen. È un widget stateless che ascolta i cambiamenti del ForecastControllere si ricostruisce di conseguenza, mostrando lo stato di caricamento, l'errore o ilPageViewcon leForecastPage` effettive. Incapsula tutta la logica di layout della schermata.
| | |-- glassmorphism_card.dart # Il "pilastro" del nostro Design System di Profondita'. Widget riutilizzabile che crea un pannello con effetto vetro smerigliato (BackdropFilter), fondamentale per la gerarchia visiva.
| | |-- hourly_forecast.dart # Widget tabellare ad alta densita' di informazioni. Mostra le previsioni ora per ora con logica di "Heatmap" dinamica (colori caldi/freddi) per vento, onde e umidita', e animazioni a cascata.
| | |-- location_services_dialog.dart # Gestore di permessi. Dialogo standardizzato per guidare l'utente nell'attivazione dei servizi di localizzazione quando sono disabilitati.
| | |-- main_hero_module.dart # Il "biglietto da visita" della schermata. E' il componente principale che mostra i dati salienti (localita', temperatura) e funge da "host" per il trigger della feature AI (l'icona _PulsingIcon), gestendo l'attivazione dell'overlay "Modal Focus".
| | |-- score_chart_dialog.dart # Dataviz interattivo. Mostra un dialogo modale con un grafico a linee (fl_chart) per l'andamento orario del pescaScore.
| | |-- score_details_dialog.dart # Spiegazione del "perche'". Dialogo che mostra i fattori positivi/negativi (reasons) che hanno contribuito a un determinato punteggio orario.
| | |-- search_overlay.dart # Motore di ricerca UI. Un layer sovrapposto che gestisce la ricerca di localita' tramite autocomplete e l'accesso rapido al GPS.
| | |-- stale_data_dialog.dart # Gestore di fallback. Dialogo che avvisa l'utente quando l'app sta usando dati in cache obsoleti a causa di un errore di rete, offrendo una scelta.
| | -- weekly_forecast.dart # Dataviz settimanale. Lista che mostra le previsioni aggregate per i giorni successivi, inclusi min/max di temperatura e il pescaScore medio giornaliero. | -- main.dart # Il punto di ingresso e orchestratore dei servizi di background. Inizializza l'app, inizializza e apre i "box" di Hive (forecastCache, analysisCache). Registra e pianifica il task di aggiornamento periodico in background tramite Workmanager, definendo il callbackDispatcher che verrà eseguito dal sistema operativo per mantenere la cache sempre fresca.
|-- linux/ # Wrapper nativo Linux.
| |-- flutter
| |-- runner
| |-- .gitignore
| |-- CMakeLists.txt
|-- macos/ # Wrapper nativo macOS.
| |-- Flutter
| |-- Runner
| |-- Runner.xcodeproj
| |-- Runner.xcworkspace
| |-- RunnerTests
| |-- .gitignore
|-- node_modules/ # Dipendenze per strumenti di sviluppo basati su Node.js.
| |-- .bin
| |-- chromadb
| |-- chromadb-js-bindings-win32-x64-msvc
| |-- semver
| |-- .package-lock.json
|-- test/ # Contiene i file per i test automatici.
| |-- widget_test.dart
|-- web/ # Codice sorgente per la versione web.
| |-- icons
| |-- favicon.png
| |-- index.html
| |-- manifest.json
|-- windows/ # Wrapper nativo Windows.
| |-- flutter
| |-- runner
| |-- .gitignore
| |-- CMakeLists.txt
|-- .flutter-plugins-dependencies # File generato che mappa i plugin alle loro piattaforme native.
|-- .gitignore # Specifica i file da ignorare nel controllo di versione.
|-- .metadata # File generato da Flutter per tracciare le proprietà del progetto.
|-- .project-structure.json # File di dati/configurazione JSON.
|-- analysis_options.yaml # Configura le regole di analisi statica del codice.
|-- flutter_01.png # File immagine PNG.
|-- flutter_02.png # File immagine PNG.
|-- package-lock.json # File di lock per le dipendenze Node.js.
|-- package.json # File di manifesto per le dipendenze Node.js.
|-- pubspec.lock # File che blocca le versioni esatte delle dipendenze Dart/Flutter.
|-- pubspec.yaml # File di manifesto del progetto: definisce dipendenze, asset, etc.
|-- README.md # File di documentazione Markdown.
```

### Backend: `pesca-api`
La seguente è una rappresentazione commentata della struttura attuale del progetto backend, arricchita con la conoscenza architetturale v7.0 (P.H.A.N.T.O.M. e CI/CD).

```
|-- .github/ # Contiene i workflow di automazione
| |-- workflows/ # Contiene i file di configurazione dei workflow
|-- api/ # Contiene la logica specifica per le route REST più semplici e dirette.
| |-- autocomplete.js # Logica per i suggerimenti di località
| |-- reverse-geocode.js # Logica per la geolocalizzazione inversa
|-- lib/ # Contiene tutta la logica di business e i moduli core dell'applicazione.
| |-- domain/ # Contiene la logica di business pura, slegata da API e framework.
| | |-- score.calculator.js # Il "**Calcolatore**". Contiene `calculateHourlyPescaScore` per il punteggio di "pescabilità".
| | |-- weather.service.js # [NUOVO] IL **DIRETTORE D'ORCHESTRA DATI**. Aggrega in parallelo i dati grezzi da tutte le fonti.
| | |-- window.calculator.js # L' "**Ottimizzatore**". Contiene `findBestTimeWindow` per identificare le migliori fasce orarie.
| |-- services/ # "**Ambasciatori**" verso il mondo esterno (gestione API).
| | |-- gemini.service.js # Interfaccia con Google AI. Espone `generateAnalysis` (RAG) e `generateEmbeddings`.
| | |-- openmeteo.service.js # Specialista di Open-Meteo per i dati orari ad alta risoluzione.
| | |-- proactive_analysis.service.js # [CHIAVE-PHANTOM] Il motore dell'analisi **proattiva**. Esegue la RAG in background e popola la `analysisCache`.
| | |-- stormglass.service.js # Specialista di Stormglass per i dati marini **premium** (es. corrente marina).
| | |-- vector.service.js # Il "**Bibliotecario Intelligente**". Gestisce il ciclo di vita della KB (`queryKnowledgeBase`, `saveKnowledgeBaseToFile`).
| | |-- wwo.service.js # Specialista di WorldWeatherOnline per dati complementari (astronomia, maree).
| |-- utils/ # La "**cassetta degli attrezzi**" (funzioni pure e riutilizzabili).
| | |-- cache.manager.js # Gestore della Cache. Esporta `myCache` e `analysisCache` (pilastro P.H.A.N.T.O.M.).
| | |-- formatter.js # Specialista di Formattazione (conversione di date ISO, codici numerici).
| | |-- geo.utils.js # Specialista **Geospaziale** (calcoli geografici puri).
| | |-- wmo_code_converter.js # Specialista di Codici Meteo (traduzione da codici WMO a descrizioni/icone).
| |-- forecast-logic.js # IL **COORDINATORE DI LOGICA**. Il cervello dell'endpoint `/forecast`. Controlla la cache, chiama i servizi e innesca **asincronamente** l'analisi proattiva.
| |-- forecast.assembler.js # [NUOVO] L' "**Assemblatore Finale**". Prende i dati grezzi e li trasforma nel payload JSON strutturato per il frontend.
|-- public/ # Contiene file statici serviti al client
| |-- fish_icon.png
| |-- half_moon.png
| |-- index.html
| |-- logo192.png
| |-- logo512.png
| |-- manifest.json
|-- tools/ # Contiene script e tool di supporto
| |-- data-pipeline.js # [CHIAVE-CI/CD] Lo script della pipeline (SerpApi/Gemini)
| |-- Project_lib_extract.ps1
| |-- Update-ProjectDocs.ps1
|-- .env # Contiene le variabili d'ambiente (API keys)
|-- debug.html # File di utilità per il debug
|-- knowledge_base.json # [CHIAVE-RAG] IL DATABASE VETTORIALE (Generato da CI/CD). Viene generato e aggiornato automaticamente dalla nostra pipeline CI/CD (data-pipeline.js). Questo script legge le fonti da sources.json, recupera le informazioni, le processa con Gemini per creare i vector embeddings, e salva tutto in questo file JSON.
|-- package-lock.json # File blocco dipendenze
|-- package.json # File manifesto del progetto
|-- README.md # File di documentazione Markdown
|-- server.js # Punto di ingresso principale (Avvia Express e le route)
|-- amente. Ecco una sintesi perfetta da usare come commento, mantenendo la metafora del "telecomando".
|-- sources.json # [CHIAVE-CI/CD] IL "TELECOMANDO" DELL'AI. File di configurazione che definisce gli argomenti di conoscenza per la pipeline di aggiornamento. Ogni stringa in questo file è una query che lo scriptdata-pipeline.js(eseguito da GitHub Actions) usa per cercare, sintetizzare e vettorizzare nuove informazioni, aggiornando automaticamente ilknowledge_base.json. Una sua modifica innesca l'intero workflow per rendere l'AI più intelligente, senza toccare il codice dell'app.
|-- test-gemini.js # Script per testare l'API Gemini
|-- test_kb.js # Script per testare le query sulla knowledge base locale
```









#########################################################################################################################################################
#########################################################################################################################################################
############################################################ PROMPT OTTIMIZZATO PER L'AI ################################################################
#########################################################################################################################################################
#########################################################################################################################################################




###############################################################
#             DOCUMENTAZIONE PROGETTO: METEO PESCA v7.0         #
#                                                               #
# RUOLO: Senior Full-Stack Engineer                             #
# FOCUS: Sviluppo App Mobile Cross-Platform (Flutter/Dart),     #
#        Microservizi (Node.js/Express.js), UI/UX Design.       #
# OBIETTIVO: Evoluzione e manutenzione dell'App "Meteo Pesca".  #
###############################################################

========================================
[1] FUNZIONALITÀ CORE E ARCHITETTURA AI
========================================

SCOPO: Fornire previsioni meteo-marine avanzate per la pesca, con un "Potenziale di Pesca" (pescaScore) orario e un assistente AI per "Insight di Pesca".

ARCHITETTURA AI (P.H.A.N.T.O.M.):
* Sistema Proattivo: Genera l'analisi AI in background non appena i dati meteo sono disponibili.
* Latenza: Risposta all'utente in <50ms (latenza zero percepita).
* RAG System: Utilizza un sistema RAG (Retrieval-Augmented Generation).
* Knowledge Base: Interroga un knowledge base vettoriale (knowledge_base.json).
* Aggiornamento KB: KB auto-aggiornante tramite pipeline CI/CD (GitHub Actions) attivata dalla modifica di sources.json.

==============================================
[2] LOGICA DI BUSINESS: CALCOLO del pescaScore
==============================================

PUNTEGGIO BASE: 3.0 (modificato dai seguenti fattori orari, tranne ove specificato).

FATTORI ATMOSFERICI:
* Pressione (Trend giornaliero):
    * In calo: +1.5
    * In aumento: -1.0
* Vento (Orario):
    * Moderato (5-20 km/h) con acqua calda: +1.5
    * Moderato (5-20 km/h) con acqua fredda: +0.5
    * Forte (20-30 km/h): -0.5
    * Molto Forte (>30 km/h): -2.0
* Luna (Giornaliera):
    * Piena/Nuova: +1.0
* Nuvole (Orarie):
    * Coperto (>60%): +1.0
    * Sereno (<20%) con alta pressione: -1.0

FATTORI MARINI:
* Stato Mare (Orario):
    * Poco mosso: +2.0
    * Mosso: +1.0
* Temperatura Acqua (Oraria):
    * Ottimale (14-20°C): +1.5
    * Malus per temperature troppo fredde o calde.
* Correnti (Orarie):
    * Ideale (0.3-0.8 kn): +1.0
    * Forte (>0.8 kn): -1.0

==============================================
[3] ARCHITETTURA BACKEND (Node.js - pesca-api)
==============================================

STRUTTURA: Applicazione Express.js modulare (services, domain, utils, tools).
DEPLOYMENT: Render.com.
ENDPOINT BASE: https://pesca-api-v5.fly.dev

ENDPOINT PRINCIPALI:
* GET /api/forecast: Fornisce i dati e innesca l'analisi proattiva in background.
* POST /api/get-analysis: Recupera l'analisi pre-calcolata dalla analysisCache (latenza zero).
* POST /api/analyze-day-fallback: Endpoint di emergenza per generare l'analisi on-demand.
* GET /api/update-cache: Usato da un Cron Job (CRON-JOB.ORG) per l'aggiornamento periodico.

FLUSSO AI (P.H.A.N.T.O.M.):
1.  /forecast riceve e salva i dati meteo in 'myCache'.
2.  Avvia asincronamente l'analisi RAG in background.
3.  L'analisi RAG interroga 'knowledge_base.json', genera testo con Gemini e salva il risultato in 'analysisCache'.
4.  Il client chiama /get-analysis per risposta istantanea da 'analysisCache'.

CI/CD per la KB:
* Trigger: Modifica di 'sources.json'.
* Azione: GitHub Action esegue 'tools/data-pipeline.js'.
* Processo: Usa SerpApi per ricerca, Gemini per vettorizzazione, e aggiorna 'knowledge_base.json'.

===============================================
[4] ARCHITETTURA FRONTEND (Flutter - pesca_app)
===============================================

PRINCIPIO: "Offline-First" (funzionamento istantaneo e senza connessione).
CACHING LOCALE: Hive (due box: 'forecastCache' per i dati e 'analysisCache' per gli insight AI).
AGGIORNAMENTO: workmanager per aggiornamento periodico in background (anche ad app chiusa).

SEPARATION OF CONCERNS (SRP):
* controllers/forecast_controller.dart: Stato e Logica di Business (ViewModel).
* screens/forecast_screen.dart: Container leggero, orchestrazione controller/overlay (solo UI).
* services/api_service.dart: Solo chiamate di rete.
* services/cache_service.dart: Solo interazione con Hive.
* widgets/: Componenti UI puri e riutilizzabili.

================================
[5] STACK TECNOLOGICO E METADATI
================================

FRONTEND:
* Stack: Flutter 3.24+, Dart 3.5+.
* Pacchetti chiave: hive, workmanager, http, geolocator.

BACKEND:
* Stack: Node.js 20.x, Express.js.
* Pacchetti chiave: @google/generative-ai, serpapi, node-cache.

SERVIZI ESTERNI:
* Google Gemini (Generativo e Embedding).
* SerpApi, Open-Meteo, WorldWeatherOnline, Stormglass.io.

====================================================================
[6] REGOLE FONDAMENTALI: Anti-Pattern e Best Practice (OBBLIGATORIO)
====================================================================

1.  Single Responsibility Principle (SRP): Unica ragione per cambiare per ogni modulo/file/classe. Logica API, Business, Caching, UI sempre in file separati.

2.  Dimensioni dei Moduli:
    * Obiettivo: 100-300 righe/file.
    * LIMITE ASSOLUTO: 500 righe (oltre è "God Object" -> refactoring immediato).
    * Test dei 30 secondi: Spiegare la funzione del modulo in una sola frase.

3.  No Logica nel build(): I metodi build dei widget contengono SOLO logica di presentazione (NO calcoli business o chiamate di rete).

4.  Immutabilità e Purezza: Preferire funzioni pure e widget 'const' dove possibile.

5.  Gestione Errori e Nullability:
    * Ogni chiamata di rete deve avere un timeout.
    * Ogni valore 'nullable' deve essere gestito esplicitamente.

6.  No "Magic Numbers" o Stringhe Hardcodate: Utilizzare file di costanti.

7.  Asincronia: Usare 'async/await' e MAI '.then()' nidificati.

8.  Testabilità: Codice scritto per essere facilmente testabile in isolamento.


==================================
CONCLUSIONE E ISTRUZIONI OPERATIVE
==================================

Hai ora a disposizione l'intera documentazione di progetto. A partire da questo momento, ogni tua risposta dovrà essere:

1. Coerente: Basata esclusivamente sulle informazioni fornite.

2. Conforme: Rispettosa di TUTTI gli anti-pattern, i vincoli e le guide stilistiche (SRP, dimensioni dei moduli, ecc.).

3. Pratica: Fornire codice Flutter/Dart o Node.js/Express che si integri perfettamente nell'architettura descritta.

Sei pronto a procedere. Attendi la mia prossima richiesta.