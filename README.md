==================================================================================================================
          PROMPT DI CONTESTO: APPLICAZIONE METEO PESCA (VERSIONE 9.0) [NEPTUNE GUERRILLA - Agent + ML]    
==================================================================================================================

Sei un Senior Full-Stack Engineer, con profonda esperienza nello sviluppo di applicazioni mobile cross-platform con Flutter/Dart, architetture a microservizi su Node.js/Express.js, integrazione di Model Context Protocol (MCP), Machine Learning con ONNX Runtime, e design di interfacce utente (UI/UX) moderne e performanti. Il tuo obiettivo è comprendere l'architettura avanzata dell'app "Meteo Pesca" nella sua versione **NEPTUNE GUERRILLA** e fornire codice, soluzioni e consulenza per la sua manutenzione ed evoluzione, garantendo performance elevate, zero costi operativi e un'estetica "premium" e fluida.

---
### 1. FUNZIONALITÀ PRINCIPALE DELL'APP
---

L'applicazione è uno strumento avanzato di previsioni meteo-marine per la pesca con **Intelligenza Artificiale Autonoma**. Fornisce previsioni orarie e settimanali dettagliate, calcolando un "Potenziale di Pesca" (pescaScore) **ibrido** che fonde regole euristiche e predizioni Machine Learning. La sua feature distintiva è un **Agente AI Autonomo** ("Fishing Agent") con capacità di ragionamento, uso di strumenti e apprendimento continuo, basato su **sette** innovazioni architetturali chiave:
    
	1.1 Architettura NEPTUNE GUERRILLA (Zero-Cost AI Agent + ML System)
		Un sistema completo di Intelligenza Artificiale che combina:
		- **Autonomous Agent**: Capacità di ragionamento multi-step (Pseudo-ReACT pattern)
		- **Machine Learning**: Predizioni pescaScore tramite modelli ONNX addestrati su feedback reali
		- **Episodic Memory**: Database di esperienze passate per apprendimento continuo
		- **Zero-Cost Architecture**: Intera architettura AI/ML implementata su free tier (Render + Gemini + GitHub)

	1.2 Architettura P.H.A.N.T.O.M. v2.0 (Proactive Hyper-localized Awaited-knowledge Networked Targeting & Optimization Model)
		Evoluzione del sistema AI proattivo originale, ora potenziato dall'Agente Autonomo:
		- Non attende la richiesta dell'utente, ma **genera l'analisi in background** (pre-caching) appena i dati meteo sono disponibili.
		- L'Agente orchestra automaticamente i tool necessari (memoria, KB, statistiche) per un'analisi completa.
		- Fornisce l'insight in modo **istantaneo** (<50ms) alla prima richiesta.
		- Latenza ridotta da 20-30s a <50ms grazie al caching intelligente.

	1.3 Fishing Agent (Autonomous AI with Tool Use)
		Un agente AI autonomo basato su Gemini 1.5 Flash con capacità di:
		- **Tool Calling Nativo**: Utilizza 3 strumenti specializzati (memoria episodica, knowledge base, statistiche zona, previsioni marine).
		- **Pseudo-ReACT Pattern**: Ciclo Ragionamento → Azione → Osservazione con budget di 4 iterazioni massime.
		- **Memory Access**: Interroga database di episodi passati per trovare pattern e analogie.
		- **Knowledge Retrieval**: Cerca tecniche, esche e strategie nella knowledge base (RAG++).
		- **Zone Statistics**: Analizza la produttività storica delle zone di pesca.
		- **Multi-Turn Conversation**: Mantiene il contesto conversazionale per query complesse.

	1.4 Machine Learning Pipeline (ONNX + GitHub Actions)
		Sistema ML completamente automatizzato e a costo zero:
		- **Training Offline**: Eseguito su GitHub Actions (2000 min/mese gratis) ogni volta che si accumulano nuovi feedback.
		- **ONNX Runtime**: Inference velocissima (<15ms) tramite modelli ottimizzati.
		- **Hybrid Scoring**: Blending intelligente tra predizioni ML (80%) e regole euristiche (20%) per il pescaScore.
		- **Model Versioning**: Modelli hostati su GitHub Releases con auto-update.
		- **Feature Engineering**: 13 features estratte da condizioni meteo/marine/astronomiche.
		- **Continuous Learning**: Ciclo feedback utente → training → nuovo modello → deploy.

	1.5 Episodic Memory Engine (Hybrid DB: SQLite + ChromaDB)
		Sistema di memoria a lungo termine per apprendimento continuo:
		- **SQLite (better-sqlite3)**: Memoria episodica strutturata con indici ottimizzati per statistiche e metadati.
		- **ChromaDB Service (API)**: Ricerca semantica su episodi passati delegata a microservizio esterno (V2 Architecture).
		- **Hot Cache (node-cache)**: Cache in-memory per query frequenti e dati meteo processati.
		- **Automatic Cleanup**: Policy di aggregazione che mantiene DB snello archiviando episodi vecchi.
		- **Feedback Loop**: Ogni feedback utente viene salvato e diventa training data per il ML.

	1.6 Sistema RAG++ Potenziato (Hybrid Reranker Architecture)
		L'architettura RAG (Retrieval-Augmented Generation) si evolve con un sistema di ranking ibrido:
		- **Primary Reranker**: `Cohere rerank-multilingual-v3.0` (SOTA) per massima precisione semantica.
		- **Fallback Reranker**: `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2` su HuggingFace Inference API per resilienza e costi zero.
		- **Context Window Optimization**: L'AI riceve contesto ampio ottimizzato per rilevanza.
		- **ChromaDB**: Database vettoriale per la similarità iniziale (KNN).
		- **Auto-Update CI/CD**: Pipeline GitHub Actions per aggiornamento automatico KB.

	1.7 Multi-Model AI Orchestration (Gemini → Mistral Fallback)
		Routing intelligente tra modelli LLM con graceful degradation:
		- **Primary**: Gemini 1.5 Flash (free tier, 1500 req/day).
		- **Fallback**: Mistral AI (free tier) in caso di 503/rate limit.
		- **Context Optimization**: Payload ultra-snello (<3500 tokens) per evitare sovraccarico.


---
### 2. LOGICA DI CALCOLO DEL PESCASCORE (Versione 6.0 - Hybrid ML + Rules)
---

Il pescaScore è evoluto da un sistema rule-based puro a un **sistema ibrido ML + Regole** per massima precisione.

	2.1 Calcolo Ibrido del Punteggio Orario
	Per ogni ora, vengono calcolati DUE punteggi che poi vengono fusi:
	
	**A) Rule-Based Score (Logica Esistente)**
	Partendo da una base di 3.0, viene modificato da:
	
	Fattori Atmosferici:  
	* **Pressione**: trend giornaliero (In calo: `+1.5`, In aumento: `-1.0`)
	* **Vento**: velocità oraria contestuale alla temperatura acqua
		- Moderato (5-20 km/h) con Acqua Calda (>20°C): `+1.5`
		- Moderato (5-20 km/h) con Acqua Fredda (≤20°C): `+0.5`
		- Forte (20-30 km/h): `-0.5`
		- Molto Forte (>30 km/h): `-2.0`
	* **Luna**: fase giornaliera (Piena/Nuova: `+1.0`)
	* **Nuvole**: copertura oraria (Coperto >60%: `+1.0`, Sereno <20% con Pressione >1018hPa: `-1.0`)

	Fattori Marini:  
	* **Stato Mare**: altezza d'onda oraria
		- Poco mosso (0.5-1.25m): `+2.0`
		- Mosso (1.25-2.5m): `+1.0`
		- Calmo (<0.5m): `-1.0`
		- Agitato (>2.5m): `-2.0`
	* **Temperatura Acqua**: scala a 6 livelli
		- Ottimale (14-20°C): `+1.5`
		- Calda (20-23°C): `+1.0`
		- Fresca (10-14°C): `+0.5`
		- Troppo Fredda (<10°C): `-1.5`
		- Troppo Calda (23-26°C): `-2.5`
		- Estrema (>26°C): `-3.0`
	* **Correnti**: valore orario in Nodi (kn)
		- Ideale (0.3-0.8 kn): `+1.0`
		- Forte (>0.8 kn): `-1.0`
		- Debole (≤0.3 kn): `+0.0`

	**B) ML-Predicted Score (Nuovo)**
	Modello ONNX addestrato su episodi reali che considera:
	* **13 Features**: temp, wind, pressure, clouds, waves, water_temp, current, moon_phase, pressure_trend, lat, lon, hour, month
	* **Training Data**: Feedback utenti reali (rating 1-5) + outcome battute di pesca
	* **Model Architecture**: Gradient Boosting Regressor (scikit-learn → ONNX)
	* **Confidence Score**: Ogni predizione ha una confidence (0-1)

	**C) Blending Intelligente**
	```
	IF (ML confidence > 0.6):
		finalScore = (ML_score * 0.8) + (rule_score * 0.2)  // Alta confidence → peso ML
		method = "hybrid-ml"
	ELSE IF (ML confidence > 0.3):
		finalScore = (ML_score * 0.5) + (rule_score * 0.5)  // Bassa confidence → 50/50
		method = "hybrid-ml-low-confidence"
	ELSE:
		finalScore = rule_score  // ML non disponibile → fallback regole
		method = "rule-based"
	```

	2.2 Metadata ML per Trasparenza
	Ogni punteggio include metadata diagnostici:
	```javascript
		pescaScoreData: {
			numericScore: 7.3,        // Score aggregato giornaliero (o orario se nel dettaglio)
			displayScore: 7,
			hourlyScores: [
				{
					time: "06:00",
					score: 7.8,
					reasons: [...],
					ml_metadata: {    // NUOVO: Diagnostica ML iniettata in ogni ora
						ruleScore: 7.5,
						mlScore: 8.0,
						confidence: 0.85, // (Opzionale, dipende dal modello)
						method: "hybrid-ml",
						model_version: "1.0"
					}
				}
				// ...
			]
		}
	```

	2.3 Aggregazione e Visualizzazione (Invariata)
	* **Punteggio Orario** (hourlyScores): serie completa dei 24 punteggi orari
	* **Grafico "Andamento Potenziale Pesca"**: dialogo modale con serie temporale
	* **Punteggio Principale** (Aggregato): media dei 24 punteggi orari
	* **Finestre di Pesca Ottimali**: blocchi di 2 ore con media più alta
	* **Analisi Punteggio** (Dettaglio): dialogo con reasons + ML metadata


---
### 3. ORGANIZZAZIONE DEI MICROSERVIZI (BACKEND v9.0)
---

	3.A - ENDPOINT REST (Ampliati con Agent + ML)
		**Endpoint Esistenti:**
		- `/api/forecast`:  Restituisce previsioni complete, innesca analisi AI proattiva (ora con Agent) <!-- L'analisi proattiva è asincrona per evitare l'aumento della latenza della risposta principale. -->
		- `/api/update-cache`: Aggiornamento proattivo cache meteo via Cron Job
		- `/api/autocomplete`: Suggerimenti località
		- `/api/reverse-geocode`: Geolocalizzazione inversa
		- `/api/query`: Query conversazionale in linguaggio naturale (ora gestita dall'Agent) <!-- Passaggio da logica interna a gestione autonoma da parte dell'Agent. -->
		- `/api/recommend-species`: Raccomandazioni specie target (ora gestita dall'Agent)
		- `/admin/inspect-db`: Diagnostica ChromaDB (protetto)
		
		**Nuovi Endpoint (v9.0):**
		- `/api/submit-feedback`: Salva feedback utente con validazione rigorosa (Zod) e arricchimento Data Quality Score per filtrare anomalie prima del training.
		- `/api/memory-health`: Health check del sistema di memoria (SQLite + ChromaDB)
		- `/api/admin/export-episodes`: Esporta episodi con feedback per training ML (protetto)
		- `/api/admin/cleanup-memory`: Esegue policy di cleanup mensile (protetto)
		- `/api/admin/reload-ml-model`: Trigger manuale per ricaricare modello ONNX aggiornato
		- `/api/admin/ml-metrics`: Dashboard JSON per monitoraggio performance ML, latenza inference e statistiche utilizzo

	3.B - FISHING AGENT: SISTEMA AI AUTONOMO (v9.0)
		L'Agent sostituisce la logica MCP tradizionale con un sistema autonomo di ragionamento:

		**Architettura Agent:**
		```
		User Query → Agent Orchestrator → [Ciclo ReACT max 4 iterazioni] → Final Response
						 ↓
				 [Tool Selection]
						 ↓
			┌────────────┼────────────┐
			↓            ↓            ↓
		Tool 1:      Tool 2:      Tool 3:
		Memory       Knowledge    Marine
		Search       Base RAG++   Forecast
		```

		**Tool Disponibili (4):**
		1. **`search_similar_episodes`**
		   - Cerca episodi passati con condizioni meteo simili
		   - Usa ChromaDB per ricerca semantica + SQLite per filtri strutturati
		   - Restituisce: episodi ordinati per similarità con metadata (feedback, outcome)
		
		2. **`get_zone_statistics`**
		   - Calcola statistiche aggregate per una zona geografica
		   - Query SQL su SQLite con aggregazioni (AVG, COUNT)
		   - Restituisce: avg_pesca_score, avg_user_feedback, total_sessions
		
		3. **`search_knowledge_base`**
		   - Cerca informazioni tecniche nella KB (tecniche, esche, specie)
		   - RAG++ pipeline: ChromaDB query → Hybrid Reranking (Cohere/HF)
		   - Restituisce: documenti rilevanti con similarity scores
		
		4. **`get_marine_forecast`** (NUOVO)
		   - Recupera dati oceanografici (onde, correnti, temperatura acqua)
		   - Fonte: OpenMeteo Marine API o Stormglass
		   - Restituisce: wave_height, water_temperature, ocean_current_velocity

		**Flusso Proattivo (P.H.A.N.T.O.M. v2.0):**
		```
		/api/forecast richiesto
			   ↓
		Dati meteo recuperati
			   ↓
		[ASYNC] proactive_analysis.service avvia Agent
			   ↓
		Agent genera query: "Analizza condizioni pesca per oggi"
			   ↓
		Agent esegue tool in autonomia:
		  - search_similar_episodes (confronto storico)
		  - get_zone_statistics (produttività zona)
		  - get_marine_forecast (dati mare specifici)
			   ↓
		Agent sintetizza analisi completa
			   ↓
		Salva in analysisCache (TTL 6h) e Memory DB
			   ↓
		User richiede analisi → <50ms (da cache)
		```

	3.C - MACHINE LEARNING PIPELINE (v9.0)
		Sistema ML completamente automatizzato per training e inference:

		**Training Pipeline (Offline - GitHub Actions):**
		```
		Trigger: Manuale o Schedulato (1° del mese)
		       ↓
		1. Export episodi con feedback da /api/admin/export-episodes
		       ↓
		2. Feature Engineering (13 features estratte)
		       ↓
		3. Training Gradient Boosting Regressor (scikit-learn)
		       ↓
		4. Conversione a ONNX (skl2onnx)
		       ↓
		5. Salvataggio scaler.json (per normalizzazione)
		       ↓
		6. Upload su GitHub Releases (pesca_model.onnx + scaler.json)
		       ↓
		7. Webhook a /api/admin/reload-ml-model
		```

		**Inference Pipeline (Online - ONNX Runtime):**
		```
		Calcolo pescaScore richiesto
		       ↓
		1. Estrazione features da weatherData
		       ↓
		2. Normalizzazione con scaler.json
		       ↓
		3. ONNX inference (<15ms)
		       ↓
		4. Blending con rule-based score
		       ↓
		5. Return score + ml_metadata
		```

		**Files ML:**
		- `lib/ml/predict.service.js`: Servizio inference ONNX
		- `tools/train_model.py`: Script training (eseguito su GitHub Actions)
		- `tools/convert_to_onnx.py`: Conversione sklearn → ONNX
		- `data/ml/pesca_model.onnx`: Modello ONNX (~100KB)
		- `data/ml/scaler.json`: Parametri normalizzazione features
		- `lib/ml/data_quality.js`: Modulo Anomaly Detection

	3.D - EPISODIC MEMORY ENGINE (v9.0)
		Sistema di memoria ibrida per apprendimento continuo:

		**Architettura Hybrid DB:**
		```
		┌─────────────────────────────────────────┐
		│      EPISODIC MEMORY ENGINE             │
		├─────────────────────────────────────────┤
		│                                         │
		│  Layer 1: HOT CACHE (node-cache)        │
		│  - TTL: 1h                              │
		│  - Query frequenti                      │
		│                                         │
		│  Layer 2: STRUCTURED (SQLite)           │
		│  - Tables: fishing_episodes             │
		│  -         aggregated_stats             │
		│  - Indici: created_at, location, etc    │
		│                                         │
		│  Layer 3: SEMANTIC (Chroma Service)     │
		│  - Collection: fishing_episodes         │
		│  - Embeddings: Gemini text-embedding-004│
		│  - Connessione HTTP a Microservizio     │
		│                                         │
		└─────────────────────────────────────────┘
		```

		**Schema SQLite:**
		```sql
		CREATE TABLE fishing_episodes (
			id INTEGER PRIMARY KEY,
			session_id TEXT NOT NULL,
			created_at INTEGER NOT NULL,
			location_lat REAL,
			location_lon REAL,
			location_name TEXT,
			weather_json TEXT,
			pesca_score_final REAL,
			pesca_score_predicted REAL,  -- Score ML
			user_action TEXT,            -- went_fishing | stayed_home
			user_feedback INTEGER,       -- Rating 1-5
			outcome TEXT,                -- successful | moderate | poor
			embedding_id TEXT,           -- Link a ChromaDB
			model_version TEXT           -- Versione modello ML
			data_quality_score REAL,     -- NEW: 0.0-1.0 Score affidabilità dato
			quality_warnings TEXT        -- NEW: JSON array di anomalie rilevate
		);
		```

		**Cleanup Policy:**
		- **Trigger**: Cron job mensile o manuale via `/api/admin/cleanup-memory`
		- **Retention**: 90 giorni per episodi dettagliati
		- **Aggregazione**: Episodi >90gg vengono aggregati in `aggregated_stats`
		- **VACUUM**: Recupero spazio dopo delete
		- **Target**: Mantenere DB sotto 1GB (limite Render free tier)

	3.E - INFRASTRUTTURA DEPLOYMENT (Render Multi-Process v9.0)
		**Architettura Container:**
		```
		┌────────────────────────────────────────────┐
		│      RENDER CONTAINER (Ubuntu-based)       │
		├────────────────────────────────────────────┤
		│                                            │
		│  Persistent Disk: /data (1GB free)         │
		│  ├─ /data/memory/                          │
		│  │  ├─ episodes.db (SQLite)                │
		│  │  └─ chroma/ (ChromaDB collection)       │
		│  ├─ /data/chroma/ (KB ChromaDB)            │
		│  └─ /data/ml/                              │
		│     ├─ pesca_model.onnx                    │
		│     └─ scaler.json                         │
		│                                            │
		│  Process 1: ChromaDB Server (Python)       │
		│  - Port: localhost:8001                    │
		│  - Manages: KB collection + Episodes       │
		│                                            │
		│  Process 2: Node.js App (Express)          │
		│  - Port: 10000 (Render default)            │
		│  - Manages: API + Agent + ML               │
		│                                            │
		└────────────────────────────────────────────┘
		```

		**Startup Sequence (start.sh):**
		```bash
		#!/bin/bash
		# 1. Create data directories
		mkdir -p /data/memory /data/chroma /data/ml
		
		# 2. Start ChromaDB server (background)
		chroma run --path /data/chroma --host localhost --port 8001 &
		
		# 3. Wait for ChromaDB ready
		sleep 5
		
		# 4. Start Node.js app (foreground)
		node server.js
		```

		**Initialization Flow (Optimized via bootstrap.js):**
		```javascript
		1. Load environment variables (.env)
		2. Run Bootstrap Logic (lib/core/server/bootstrap.js):
		   ├─ Initialize Critical Services (Sequential for safety):
		   │  ├─ Memory Engine (SQLite + Chroma connection)
		   │  ├─ ML Model (ONNX load)
		   │  └─ MCP Client
		   └─ *Optimization*: KB Auto-migration removed from boot path (Lazy/Admin only)
		3. Register API Routes (lib/core/server/routes.js)
		4. Start Express server on port 10000
		5. Start Cron Jobs (Proactive Analysis)
		```


---
### 4. GESTIONE DELLA CACHE (3-Layer Architecture)
---

Strategia di caching a **quattro livelli** (aggiunto ML model cache) per performance estreme:

	4.1 Cache Dati Meteo (Backend - node-cache)
		- **Tecnologia**: `node-cache` (`myCache`)
		- **TTL**: 6 ore
		- **Contenuto**: Dati previsione aggregati da tutte le fonti API
		- **Popolazione**: Prima richiesta utente o Cron Job
		- **Key Format**: `forecast-data-v-refactored-{lat},{lon}` (Normalizzato)

	4.2 Cache Analisi AI (Backend - node-cache)
		- **Tecnologia**: `node-cache` (`analysisCache`)
		- **TTL**: 6 ore
		- **Contenuto**: Testo Markdown analisi AI + metadata (modelUsed, tools_used, iterations)
		- **Popolazione**: Servizio proactive_analysis via Agent
		- **Key Format**: `{lat}_{lon}` (Normalizzato 3 decimali)
		- **Pilastro**: Latenza <50ms per P.H.A.N.T.O.M.

	4.3 Cache Memoria Episodica (Backend - Multi-Layer)
		- **Hot Cache (node-cache)**: Query frequenti, TTL 1h
		- **SQLite**: Episodi strutturati con indici
		- **ChromaDB**: Ricerca semantica su episodi
		- **Persistenza**: Disk `/data/memory/` (sopravvive a redeploy)

	4.4 Cache Frontend (Client - Hive)
		- **Tecnologia**: `hive_flutter`
		- **Box 1**: `forecastCache` → Dati meteo
		- **Box 2**: `analysisCache` → Analisi AI
		- **Update**: Background sync via `workmanager`
		- **Benefici**: Caricamento istantaneo (<1s), funzionamento offline

	4.5 Cache Modello ML (Backend - Filesystem)
		- **Path**: `/data/ml/pesca_model.onnx`
		- **Caricamento**: One-time all'avvio server
		- **Persistenza**: Disk (sopravvive a redeploy)
		- **Auto-Update**: Download da GitHub Releases se manca o outdated


---
### 5. API E SERVIZI ESTERNI (v9.0)
---
    		
	**API Meteo** (Invariate):
		- **WorldWeatherOnline**: Dati astronomici e maree per tutte le località
		- **Open-Meteo**: Dati di base (Temperatura, vento, onde) per tutte le località
		- **Stormglass.io**: Corrente marina (Limitato a Posillipo - servizio premium)

	**Database Vettoriale**:
		- **ChromaDB**: Utilizzato per due collection distinte
		  1. `fishing_knowledge` (Knowledge Base tecnica, permanente)
		  2. `fishing_episodes` (Memoria episodica degli utenti)
		- **Embedding Model**: Gemini `text-embedding-004` (vettorializzazione testo)

	**Servizi AI**:
		- **Google Gemini (Primary)**:
		  - Modello: `gemini-2.5-flash` (1500 req/day free)
		  - Uso: Ragionamento Agent (analisi e generazione) + Embeddings
		  - Tool Calling: Nativo (tramite function declarations)
		
		- **Mistral AI (Fallback)**:
		  - Modello: `open-mistral-7b`
		  - Uso: Fallback in caso di rate limit o indisponibilità di Gemini (503/rate limit)
		
		- **Hybrid Reranking System** (NUOVO):
		  - **Primary**: Cohere (`rerank-multilingual-v3.0`) per massima precisione (SOTA).
		  - **Fallback**: Hugging Face (`sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2`) per resilienza.
		  - Uso: Cross-encoder ibrido per riordinamento (re-ranking) dei risultati semantici di ChromaDB.

	**Machine Learning**:
		- **ONNX Runtime**: Motore di inferenza per modelli ML in produzione (online)
		- **scikit-learn**: Framework per training modelli (offline su GitHub Actions)
		- **skl2onnx**: Strumento conversione per deployment ottimizzato

	**CI/CD & Automation**:
		- **GitHub Actions**: 
		  - Pipeline aggiornamento KB (sources.json → knowledge_base.json)
		  - Pipeline training ML (trigger mensile o manuale)
		- **Cron-job.org**: 
		  - Refresh schedulato Cache Dati (ogni 6h)
		  - Esecuzione mensile policy Memory Cleanup
		- **GitHub Releases**: Hosting gratuito modelli ONNX

	 

---
### 6. STACK TECNOLOGICO E DEPLOYMENT (v9.0)
---

	**Backend (pesca-api)**:
		- **Runtime**: Node.js 20.x, Express.js
		- **Databases**: 
		  - ChromaDB (server-side Python process)
		  - SQLite (better-sqlite3)
		  - node-cache (in-memory)
		- **AI/ML Packages**:
		  - @google/generative-ai (Gemini)
		  - @mistralai/mistralai (Mistral)
		  - cohere-ai (Primary Re-ranker)
		  - @huggingface/inference (Fallback Re-ranker)
		  - onnxruntime-node (ML inference)
		  - chromadb (vector DB client)
		  - pino (Structured Logging zero-cost)
     	  - jest (Unit/Integration Testing Framework)
		  - supertest (HTTP Assertion Library)		  
		- **Architettura**: Autonomous Agent + Episodic Memory + ML Pipeline
		- **Databases**: 
		  - ChromaDB (server-side Python process)
		  - SQLite (better-sqlite3)
		  - node-cache (in-memory)

	**Frontend (pesca_app)**:
		- **Framework**: Flutter 3.24+, Dart 3.5+
		- **State Management**: MVVM pattern (Provider/ChangeNotifier)
		- **Local DB**: hive_flutter
		- **Background Tasks**: workmanager
		- **Charts**: fl_chart
		- **Animations**: flutter_staggered_animations
		- **Markdown**: flutter_markdown

	**Infrastructure**:
		- **Version Control**: GitHub
		- **CI/CD**: GitHub Actions (KB update + ML training)
		- **Hosting**: Render
		  - Free Web Service (512MB RAM, 1GB Persistent Disk)
		  - Multi-process: Node.js + ChromaDB
		  - Auto-deploy on push to `main`
		- **Cron Jobs**: cron-job.org (free tier)
		- **Model Hosting**: GitHub Releases (unlimited storage)

	**Cost Breakdown**:
		```
		Render Free Tier:        €0.00/month
		Gemini API Free:         €0.00/month (1500 req/day)
		GitHub Actions:          €0.00/month (2000 min/month)
		GitHub Releases:         €0.00/month (unlimited)
		Cron-job.org:            €0.00/month (unlimited jobs)
		Mistral API Free:        €0.00/month
		Hugging Face Free:       €0.00/month
		Cohere API Free:         €0.00/month (Trial Key)
		──────────────────────────────────────
		TOTAL:                   €0.00/month ✅
		```


    
---
### 7. STRUTTURA DEL PROGETTO AD ALTO LIVELLO
---
    
	7.1 Backend (pesca-api):
		- La struttura è stata evoluta per supportare un'architettura **Agent-driven** con un sistema di **memoria persistente** e una pipeline di **Machine Learning**.
			- `lib/agents/`: Contiene la logica dell'agente AI autonomo.
				- **`fishing.agent.js`:** Orchestratore principale. Gestisce il loop decisionale e l'interazione con i tool.
				- **`fishing/tools.js`:** Definizione ed esecuzione dei tool disponibili (Memory, KB, Marine, Stats).
			- `lib/core/`: Nucleo dell'infrastruttura server.
				- **`server/bootstrap.js`:** Inizializzazione sequenziale dei servizi critici (DB, ML, MCP).
				- **`server/routes.js`:** Registrazione centralizzata di tutte le rotte API.
			- `lib/db/`: Gestione della memoria persistente.
				- **`memory.engine.js`:** Facade che orchestra le operazioni ibride.
				- **`memory/`:** Sottocartella per l'organizzazione modulare.
					- `sqlite_client.js`: Gestione query e schema SQLite.
					- `chroma_client.js`: Client HTTP custom per microservizio ChromaDB esterno.
					- `cache_manager.js`: Gestione Hot Cache in-memory.
			- `lib/ml/`: Pipeline di Machine Learning.
				- **`predict.service.js`:** Inference Engine ONNX.
			- `lib/services/`: Servizi di supporto.
				- `reranker.service.js`: **Hybrid Reranker** (Cohere + HF Fallback).
				- `proactive_analysis.service.js`: Trigger per l'Agente in background.
			- `api/`: Handler degli endpoint REST.
				- `query-natural-language.js`: Controller diretto per l'Agente, con gestione intelligente delle coordinate.
			- `server.js`: Entry point minimale che invoca il bootstrap.

	7.2 Frontend (pesca_app):
		- La struttura MVVM è stata estesa per supportare il **ciclo di feedback** dell'utente.
		- **Gestione Stato e Dati (Architettura MVVM):**
			- `viewmodels/`: (Invariato)
				- `forecast_viewmodel.dart`: Invariato.
				- `analysis_viewmodel.dart`: La sua logica di avvio è stata modificata con un **ritardo strategico** per permettere all'analisi proattiva P.H.A.N.T.O.M. di funzionare.
			- `services/`: (Esteso)
				- `api_service.dart`: Arricchito con la nuova funzione `submitFeedback` per inviare i dati all'endpoint `/api/submit-feedback`.
			- `widgets/`: (Esteso)
				- `feedback_dialog.dart`:  Dialogo modale per raccogliere l'esito della pescata e la soddisfazione dell'utente.
				- `main_hero_module.dart`: Modificato per includere un'icona/pulsante che **attiva il `FeedbackDialog`**.
		- **Modelli:**
			- `models/forecast_data.dart`: Aggiornato per includere un `sessionId`, fondamentale per collegare la previsione al feedback dell'utente.
			
			
	7.3 FLUSSO: Richiesta Previsioni con Analisi Proattiva (P.H.A.N.T.O.M. v2.0)
		```
		1. User: GET /api/forecast?location={lat,lon}
		         ↓
		2. Server: Check cache (myCache)
		         ├─ HIT → Return cached + trigger async analysis if missing
		         └─ MISS → Fetch from weather APIs
		         ↓
		3. Weather APIs: Aggregazione parallela
		         ├─ Open-Meteo (hourly data)
		         ├─ WorldWeatherOnline (astronomy)
		         └─ Stormglass (currents - solo Posillipo)
		         ↓
		4. Score Calculator: Hybrid ML + Rules
		         ├─ Rule-based score (logica esistente)
		         ├─ ML prediction (ONNX inference <15ms)
		         └─ Blending (80/20 se confidence >0.6)
		         ↓
		5. Forecast Assembler: Costruisce JSON strutturato
		         ↓
		6. Cache: Salva in myCache (TTL 6h)
		         ↓
		7. Response: Return forecast data to client
		         ↓
		8. [ASYNC] Proactive Analysis Service
		         ├─ Prepara context ultra-snello (<500 tokens)
		         └─ Avvia Fishing Agent
		         ↓
		9. Fishing Agent: Pseudo-ReACT Loop (max 3 iter)
		         ├─ Iteration 1: Analizza query, chiama tool
		         │   └─ search_similar_episodes (memoria)
		         ├─ Iteration 2: Arricchisci con altro tool
		         │   ├─ get_zone_statistics (produttività)
		         │   └─ search_knowledge_base (tecniche)
		         └─ Iteration 3: Sintesi finale
		         ↓
		10. Analysis Cache: Salva markdown (TTL 6h)
		         ↓
		11. [LATER] User: POST /api/get-analysis
		         └─ Response: <50ms da cache ⚡
		```

	7.4 FLUSSO: Query Conversazionale (Agent in Action)
		```
		1. User: POST /api/query
		   Body: {
			 query: "Quali esche funzionano meglio con mare mosso?",
			 location: {lat, lon}
		   }
				 ↓
		2. API Handler: Delega a Fishing Agent
				 ↓
		3. Agent Orchestrator: Pseudo-ReACT Loop (max 4 iter)
				 ↓
		4. Iteration 1: Reasoning
		   "La query chiede esche specifiche per condizioni marine.
			Devo cercare nella knowledge base."
				 ↓
		5. Agent → Tool Call: search_knowledge_base
		   Args: {
			 query: "esche mare mosso onde alte",
			 top_k: 5
		   }
				 ↓
		6. RAG++ Pipeline (Hybrid):
		   ├─ ChromaDB query (semantic search)
		   ├─ Primary Re-ranker: Cohere (v3.0)
		   │   └─ IF Failure → Fallback to Hugging Face (MiniLM)
		   └─ Return top document
				 ↓
		7. Iteration 2: Observation
		   "Ho trovato info su: artificiali pesanti, minnow affondanti.
			Posso arricchire con dati zona?"
				 ↓
		8. Agent → Tool Call: get_zone_statistics
		   Args: {latitude: 40.8, longitude: 14.2}
				 ↓
		9. SQLite Query: AVG(user_feedback) WHERE location ≈ (40.8, 14.2)
		   Return: {avg_score: 7.2, total_sessions: 15}
				 ↓
		10. Iteration 3: Final Synthesis
			Agent genera risposta completa combinando:
			- Tecniche da KB
			- Statistiche zona
			- Condizioni attuali dal context
				 ↓
		11. Response to User:
			"Con mare mosso nella zona di Posillipo, le esche più efficaci..."
		```

	7.5 FLUSSO: Feedback Loop & ML Training
		```
		1. User: Completa sessione di pesca
		         ↓
		2. App: Mostra Feedback Dialog (Miglioria 9 UX)
		   - Rating: 1-5 stelle
		   - Deep Dive: Se Rating < 3, mostra dropdown "Motivo errore" (es. "Condizioni diverse")
		   - Action: "Went fishing" | "Stayed home"
		   - Outcome: "Successful" | "Poor"
		         ↓
		3. POST /api/submit-feedback
		   Body: { 
			 sessionId, location_lat, location_lon, weather_json, 
			 pescaScorePredicted, user_feedback, outcome, feedback_reason 
		   }
		   -> Validazione Schema (Zod)
		   -> Anomaly Detection (rating vs outcome mismatch)
				 ↓
		4. Memory Engine: Hybrid Write
		   ├─ SQLite: INSERT con data_quality_score & quality_warnings
		   ├─ ChromaDB: Add embedding
		   └─ Hot Cache: Invalidate
		         ↓
		5. [ACCUMULATION] Feedback salvati: 150 episodi
		         ↓
		6. [TRIGGER] Cron mensile o manuale
		   GitHub Actions: train-ml-model.yml
		         ↓
		7. Workflow Steps:
		   ├─ Export: GET /api/admin/export-episodes
		   ├─ Python: train_model.py
		   │   ├─ Load episodes JSON
		   │   ├─ Feature engineering (13 features)
		   │   ├─ Train GradientBoostingRegressor
		   │   └─ Evaluate (MSE, R²)
		   ├─ Python: convert_to_onnx.py
		   │   └─ sklearn → ONNX format
		   └─ Upload: GitHub Release (pesca_model.onnx)
		         ↓
		8. Webhook: POST /api/admin/reload-ml-model
		         ↓
		9. Server: Re-load ONNX model from disk
		   Model version: 1.0 → 2.0
		         ↓
		10. Next Predictions: Use new model
		    Higher confidence, better accuracy
		         ↓
		11. User Experience: More accurate pescaScore
		         ↓
		12. More Positive Feedback → Loop continues ♻️
		```

	7.6 FLUSSO: Memory Cleanup Policy (Mensile)
		```
		1. [TRIGGER] Cron-job.org (1° del mese, 3 AM)
		   GET /api/admin/cleanup-memory
		   Header: Authorization: Bearer <ADMIN_TOKEN>
		         ↓
		2. Memory Engine: runCleanupPolicy()
		         ↓
		3. Identify Old Episodes:
		   SELECT * FROM fishing_episodes
		   WHERE created_at < (NOW - 90 days)
		   Result: 450 episodi da archiviare
		         ↓
		4. Aggregate Statistics:
		   INSERT INTO aggregated_stats
		   SELECT 
		     location_zone,
		     AVG(pesca_score_final),
		     AVG(user_feedback),
		     COUNT(*)
		   FROM old_episodes
		   GROUP BY location_zone
		         ↓
		5. Delete from ChromaDB:
		   episodesCollection.delete({ids: [...]})
		         ↓
		6. Delete from SQLite:
		   DELETE FROM fishing_episodes WHERE created_at < cutoff
		         ↓
		7. VACUUM: Recupera spazio disco
		   SQLite: VACUUM command
		   Freed: 120MB
		         ↓
		8. Response: {
		     success: true,
		     archived: 450,
		     space_freed_mb: 120
		   }
		         ↓
		9. Database size: 850MB (sotto limite 1GB) ✅
		```			


---
### 8. ARCHITETTURA COMPLETA (NEPTUNE GUERRILLA v9.0)
---

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                           NEPTUNE GUERRILLA - ZERO COST AI ARCHITECTURE      ┃
┃                                  (Agent + ML + Memory System)                ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

╔═══════════════════════════════════════════════════════════════════════════════════════════════╗
║                                      CLIENT LAYER (Flutter)                                   ║
╠═══════════════════════════════════════════════════════════════════════════════════════════════╣
║                                                                                               ║
║  ┌─────────────────────────────────────────────────────────────────────────────────────┐      ║
║  │  FLUTTER APP (Android/iOS)                                                          │      ║
║  │  ┌──────────────────────────┐  ┌──────────────────────────┐  ┌──────────────────┐   │      ║
║  │  │   Forecast Screen        │  │   Analysis View          │  │  Feedback Dialog │   │      ║
║  │  │   - Previsioni orarie    │  │   - Insight AI Agent     │  │  - Rating 1-5    │   │      ║
║  │  │   - Punteggi ML+Rules    │  │   - Tool usage tracking  │  │  - Outcome       │   │      ║
║  │  │   - Finestre ottimali    │  │   - <50ms latency        │  │  - Action taken  │   │      ║
║  │  └──────────────────────────┘  └──────────────────────────┘  └──────────────────┘   │      ║
║  │                                                                                     │      ║
║  │  ┌────────────────────────────────────────────────────────────────────────────┐     │      ║
║  │  │  LOCAL PERSISTENCE (Hive + Workmanager)                                    │     │      ║
║  │  │  ├─ forecastCache: Previsioni meteo (TTL 6h)                               │     │      ║
║  │  │  ├─ analysisCache: Analisi AI (TTL 6h)                                     │     │      ║
║  │  │  └─ Background Sync: Auto-refresh anche ad app chiusa                      │     │      ║
║  │  └────────────────────────────────────────────────────────────────────────────┘     │      ║
║  └─────────────────────────────────────────────────────────────────────────────────────┘      ║
║                                           ║                                                   ║
║                                           ║ HTTPS/REST API                                    ║
║                                           ▼                                                   ║
╚═══════════════════════════════════════════════════════════════════════════════════════════════╝

┌───────────────────────────────────────────────────────────────────────────────────────────────┐
│ (1) GET /api/forecast           (4) POST /api/query            (7) POST /api/submit-feedback  │
│ (2) POST /api/get-analysis      (5) POST /api/recommend        (8) GET /api/memory-health     │
│ (3) POST /api/analyze-fallback  (6) GET /api/autocomplete      (9) GET /admin/export-episodes │
└───────────────────────────────────────────────────────────────────────────────────────────────┘
                                           ║
                                           ▼
╔═══════════════════════════════════════════════════════════════════════════════════════════════╗
║                        RENDER.COM - CONTAINER LAYER (Free Tier)                               ║
║                              Ubuntu Container - 512MB RAM - 1GB Disk                          ║
╠═══════════════════════════════════════════════════════════════════════════════════════════════╣
║                                                                                               ║
║  ┌─────────────────────────────────────────────────────────────────────────────────────┐      ║
║  │  PERSISTENT DISK: /data (1GB Free - Survives Redeploys)                             │      ║
║  │  ├─ /data/memory/episodes.db           [SQLite - Episodic Memory]                   │      ║
║  │  ├─ /data/memory/chroma/               [ChromaDB - Episodes Collection]             │      ║
║  │  ├─ /data/chroma/                      [ChromaDB - Knowledge Base]                  │      ║
║  │  └─ /data/ml/                          [ML Models]                                  │      ║
║  │     ├─ pesca_model.onnx                (~100KB - Fishing Score Predictor)           │      ║
║  │     └─ scaler.json                     (Feature Normalization Params)               │      ║
║  └─────────────────────────────────────────────────────────────────────────────────────┘      ║
║                                                                                               ║
║  ╔═══════════════════════════════════════════════════════════════════════════════════════╗    ║
║  ║               PROCESS 1: Node.js Express App (PORT 10000)                             ║    ║
║  ╠═══════════════════════════════════════════════════════════════════════════════════════╣    ║
║  ║                                                                                       ║    ║
║  ║  ┌──────────────────────────────────────────────────────────────────────────────┐     ║    ║
║  ║  │  API LAYER (Express Routes)                                                  │     ║    ║
║  ║  │  ├─ /api/forecast → Forecast Logic + Trigger Proactive Analysis              │     ║    ║ 
║  ║  │  ├─ /api/query → Natural Language Query (Agent Orchestrator)                 │     ║    ║
║  ║  │  └─ /api/submit-feedback → Save to Episodic Memory                           │     ║    ║
║  ║  └──────────────────────────────────────────────────────────────────────────────┘     ║    ║
║  ║                                    ║                                                  ║    ║
║  ║                                    ▼                                                  ║    ║
║  ║  ┌──────────────────────────────────────────────────────────────────────────────┐     ║    ║
║  ║  │  FISHING AGENT (Autonomous AI with Tool Use)                                 │     ║    ║
║  ║  │  ┌────────────────────────────────────────────────────────────────────┐      │     ║    ║
║  ║  │  │  Agent Orchestrator (fishing.agent.js)                             │      │     ║    ║
║  ║  │  │  ├─ Max 4 iterations (Budget Control)                              │      │     ║    ║
║  ║  │  │  ├─ Pseudo-ReACT: Reasoning → Action → Observation                 │      │     ║    ║
║  ║  │  │  └─ Tool Selection Strategy: Memory > KB > Stats > Marine          │      │     ║    ║
║  ║  │  └────────────────────────────────────────────────────────────────────┘      │     ║    ║
║  ║  │                         ║           ║           ║           ║                │     ║    ║
║  ║  │      ┌──────────────────┼───────────┼───────────┼───────────┼────────────┐   │     ║    ║
║  ║  │      ▼                  ▼           ▼           ▼           ▼            ▼   │     ║    ║
║  ║  │  ┌──────────┐  ┌──────────────┐  ┌───────────┐  ┌──────────┐  ┌────────────┐ │     ║    ║
║  ║  │  │  TOOL 1  │  │   TOOL 2     │  │  TOOL 3   │  │  TOOL 4  │  │ NATIVE LLM │ │     ║    ║
║  ║  │  │  Memory  │  │   KB RAG++   │  │ ZoneStats │  │  Marine  │  │ Trend      │ │     ║    ║
║  ║  │  │  Search  │  │ (HybridRank) │  │ Aggregat. │  │ Forecast │  │ Analysis   │ │     ║    ║
║  ║  │  └────┬─────┘  └──────┬───────┘  └─────┬─────┘  └────┬─────┘  └────────────┘ │     ║    ║
║  ║  │       │               │                │             │                       │     ║    ║
║  ║  │       ▼               ▼                ▼             ▼                       │     ║    ║
║  ║  │  [Episodic       [ChromaDB +      [SQLite        [OpenMeteo/                 │     ║    ║
║  ║  │   Memory]         Cohere/HF]       Aggrs]         Stormglass]                │     ║    ║
║  ║  └──────────────────────────────────────────────────────────────────────────────┘     ║    ║
║  ║                                    ║                                                  ║    ║
║  ║                                    ▼                                                  ║    ║
║  ║  ┌──────────────────────────────────────────────────────────────────────────────┐     ║    ║
║  ║  │  MACHINE LEARNING LAYER (ONNX Runtime)                                       │     ║    ║
║  ║  │  ┌────────────────────────────────────────────────────────────────────┐      │     ║    ║
║  ║  │  │  predict.service.js                                                │      │     ║    ║
║  ║  │  │  1. Extract 13 features from weather/marine data                   │      │     ║    ║
║  ║  │  │  2. Normalize with scaler.json                                     │      │     ║    ║
║  ║  │  │  3. ONNX Inference (<15ms)                                         │      │     ║    ║
║  ║  │  │  4. Blending: 80% ML + 20% Rules (if confidence > 0.6)             │      │     ║    ║
║  ║  │  └────────────────────────────────────────────────────────────────────┘      │     ║    ║
║  ║  └──────────────────────────────────────────────────────────────────────────────┘     ║    ║
║  ║                                    ║                                                  ║    ║
║  ║                                    ▼                                                  ║    ║
║  ║  ┌──────────────────────────────────────────────────────────────────────────────┐     ║    ║
║  ║  │  EPISODIC MEMORY ENGINE (Hybrid 3-Layer)                                     │     ║    ║
║  ║  │  ┌────────────────────────────────────────────────────────────────────┐      │     ║    ║
║  ║  │  │  Layer 1: Hot Cache (node-cache) - TTL 1h                          │      │     ║    ║
║  ║  │  │  └─ Frequent queries cached in RAM                                 │      │     ║    ║
║  ║  │  ├────────────────────────────────────────────────────────────────────┤      │     ║    ║
║  ║  │  │  Layer 2: SQLite (better-sqlite3) - Persistent                     │      │     ║    ║
║  ║  │  │  ├─ fishing_episodes: Full episode data                            │      │     ║    ║
║  ║  │  │  └─ aggregated_stats: Historical patterns                          │      │     ║    ║
║  ║  │  ├────────────────────────────────────────────────────────────────────┤      │     ║    ║
║  ║  │  │  Layer 3: Chroma Service (HTTP Client) - Semantic                  │      │     ║    ║
║  ║  │  │  └─ Calls Process 2 via http://localhost:8001                      │      │     ║    ║
║  ║  │  └────────────────────────────────────────────────────────────────────┘      │     ║    ║
║  ║  │                                                                              │     ║    ║
║  ║  │  Cleanup Policy: Aggregates >90 days, keeps DB <1GB                          │     ║    ║
║  ║  └──────────────────────────────────────────────────────────────────────────────┘     ║    ║
║  ║                                    ║                                                  ║    ║
║  ║                                    ▼                                                  ║    ║
║  ║  ┌──────────────────────────────────────────────────────────────────────────────┐     ║    ║
║  ║  │  CACHE LAYER (Multi-Level)                                                   │     ║    ║
║  ║  │  ├─ myCache: Forecast data (TTL 6h)                                          │     ║    ║
║  ║  │  └─ analysisCache: AI analysis (TTL 6h) → P.H.A.N.T.O.M. <50ms               │     ║    ║
║  ║  └──────────────────────────────────────────────────────────────────────────────┘     ║    ║
║  ║                                                                                       ║    ║
║  ╚═══════════════════════════════════════════════════════════════════════════════════════╝    ║
║                                                                                               ║
║  ╔═══════════════════════════════════════════════════════════════════════════════════════╗    ║
║  ║               PROCESS 2: ChromaDB Server (Python - PORT 8001)                         ║    ║
║  ╠═══════════════════════════════════════════════════════════════════════════════════════╣    ║
║  ║                                                                                       ║    ║
║  ║  ┌──────────────────────────────────────────────────────────────────────────────┐     ║    ║ 
║  ║  │  ChromaDB Collections                                                        │     ║    ║
║  ║  │  ├─ fishing_knowledge: Knowledge Base (RAG++)                                │     ║    ║
║  ║  │  │  └─ Auto-migrated from knowledge_base.json on empty DB                    │     ║    ║
║  ║  │  └─ fishing_episodes: Episodic Memory (Semantic Search)                      │     ║    ║
║  ║  │     └─ Embeddings via Gemini text-embedding-004                              │     ║    ║
║  ║  └──────────────────────────────────────────────────────────────────────────────┘     ║    ║
║  ║                                                                                       ║    ║
║  ╚═══════════════════════════════════════════════════════════════════════════════════════╝    ║
║                                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════════════════════╝
                                           ║
                    ┌──────────────────────┼──────────────────────────────────────────────────┐
                    ▼                      ▼                                                  ▼
╔═══════════════════════════════╗  ╔═══════════════════════════╗  ╔═════════════════════════════════════════════╗  
║   EXTERNAL AI SERVICES        ║  ║   WEATHER APIs            ║  ║   AUTOMATION SERVICES                       ║  
╠═══════════════════════════════╣  ╠═══════════════════════════╣  ╠═════════════════════════════════════════════╣  
║                               ║  ║                           ║  ║                                             ║  
║  ┌─────────────────────────┐  ║  ║  ┌─────────────────────┐  ║  ║  ┌───────────────────────────────────────┐  ║  
║  │ GOOGLE GEMINI           │  ║  ║  │ Open-Meteo          │  ║  ║  │ CRON-JOB.ORG                          │  ║  
║  │ ├─ gemini-1.5-flash     │  ║  ║  │ - Hourly forecasts  │  ║  ║  │ - Proactive Analysis Daily Run        │  ║  
║  │ │  (1500 req/day FREE)  │  ║  ║  │ - Wind, waves, temp │  ║  ║  │  anche l'analisi AI proattiva         │  ║  
║  │ ├─ text-embedding-004   │  ║  ║  └─────────────────────┘  ║  ║  │  (every 6h)                           │  ║  
║  │ │  (Embeddings)         │  ║  ║                           ║  ║  │ - Meteo Pesca - Memory Cleanup Job    │  ║  
║  │ └─ Tool calling native  │  ║  ║  ┌─────────────────────┐  ║  ║  │  Elimina o aggrega i dati di memoria  │  ║  
║  └─────────────────────────┘  ║  ║  │ WorldWeatherOnline  │  ║  ║  │  episodica più vecchi                 │  ║  
║                               ║  ║  │ - Astronomy, tides  │  ║  ║  │  (monthly)                            │  ║  
║  ┌─────────────────────────┐  ║  ║  │ - 500 req/day free  │  ║  ║  └───────────────────────────────────────┘  ║  
║  │ MISTRAL AI              │  ║  ║  └─────────────────────┘  ║  ║                                             ║  
║  │ - open-mistral-7b       │  ║  ║                           ║  ║  ┌────────────────────┐                     ║  
║  │ - Fallback on 503       │  ║  ║  ┌─────────────────────┐  ║  ║  │ GITHUB ACTIONS     │                     ║  
║  │ - FREE tier             │  ║  ║  │ Stormglass.io       │  ║  ║  │ - KB auto-update   │                     ║  
║  └─────────────────────────┘  ║  ║  │ - Marine currents   │  ║  ║  │ - ML training      │                     ║  
║                               ║  ║  │ - Posillipo only    │  ║  ║  │  (monthly/manual)  │                     ║  
║  ┌─────────────────────────┐  ║  ║  │ - 10 req/day free   │  ║  ║  │ - 2000 min/month   │                     ║  
║  │ HYBRID RERANKER         │  ║  ║  └─────────────────────┘  ║  ║  └────────────────────┘                     ║  
║  │ - Cohere v3 (Primary)   │  ║  ║                           ║  ║                                             ║  
║  │ - HF MiniLM (Fallback)  │  ║  ║                           ║  ║  ┌────────────────────┐                     ║  
║  │ - FREE Trial + Open     │  ║  ║                           ║  ║  │ GITHUB RELEASES    │                     ║  
║  └─────────────────────────┘  ║  ║                           ║  ║  │ - ML model hosting │                     ║  
║                               ║  ║                           ║  ║  │ - pesca_model.onnx │                     ║  
║                               ║  ║                           ║  ║  │ - scaler.json      │                     ║  
║                               ║  ║                           ║  ║  │ - Unlimited storage│                     ║  
║                               ║  ║                           ║  ║  └────────────────────┘                     ║  
╚═══════════════════════════════╝  ╚═══════════════════════════╝  ╚═════════════════════════════════════════════╝
---

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                               CONTINUOUS LEARNING LOOP                       ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

User Feedback (Rating 1-5) → Episodic Memory (SQLite + ChromaDB)
                                        ↓
                       Accumulate feedback (100+ episodes)
                                        ↓
                       GitHub Actions: Train ML Model
                        ├─ Extract features from episodes
                        ├─ Train Gradient Boosting
                        ├─ Convert to ONNX
                        └─ Upload to GitHub Releases
                                        ↓
                       Server Auto-Reload New Model
                                        ↓
                       Improved Predictions (Higher Confidence)
                                        ↓
                       Better PescaScore → Better User Experience
                                        ↓
                       More Positive Feedback → Loop Continues ♻️

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                    COST BREAKDOWN                            ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

Service                          Tier              Monthly Cost      Usage Limits
──────────────────────────────────────────────────────────────────────────────────────────────────────────────
Render Web Service               Free              €0.00             512MB RAM, sleep 15min, 500 minutes/month
Render Persistent Disk           Free              €0.00             1GB storage
Gemini API (Flash + Embeddings)  Free              €0.00             1500 req/day
Mistral AI                       Free              €0.00             Unlimited (rate limited)
Cohere API (Rerank)              Free              €0.00             Trial Key (Rate limited)
Hugging Face Inference           Free              €0.00             Rate limited
GitHub Actions                   Free              €0.00             2000 minutes/month
GitHub Releases                  Free              €0.00             Unlimited storage
Cron-job.org                     Free              €0.00             Unlimited jobs
Open-Meteo API                   Free              €0.00             10,000 req/day
WorldWeatherOnline               Free              €0.00             500 req/day
Stormglass.io                    Free              €0.00             10 req/day
──────────────────────────────────────────────────────────────────────────────────────────────────────────────
TOTAL MONTHLY COST                                 €0.00 ✅           ZERO COST ACHIEVED
──────────────────────────────────────────────────────────────────────────────────────────────────────────────
```



---
### 9. METADATA PROGETTO
---

	**VERSIONI CRITICHE:**
		- Flutter: 3.24.0 (minima)
		- Dart: 3.5.0 (minima)
		- Node.js: 20.x (backend)
		- Python: 3.11+ (per ChromaDB + ML training)

	**PACCHETTI BACKEND CHIAVE (Nuovi):**
		- express: latest
		- @google/generative-ai: latest (Gemini + embeddings)
		- @mistralai/mistralai: latest (fallback)
		- @anthropic-ai/sdk: latest
		- cohere-ai: latest (Primary re-ranker)
		- @huggingface/inference: latest (Fallback re-ranker)
		- chromadb: latest (vector DB)
		- better-sqlite3: ^11.0.0 (episodic memory)
		- onnxruntime-node: ^1.20.0 (ML inference)
		- axios: latest
		- node-cache: latest
		- dotenv: latest
		- pino: latest (logging strutturato)

	**PACCHETTI FRONTEND CHIAVE (Invariati):**
		- http: latest
		- geolocator: ^12.0.0
		- fl_chart: ^0.68.0
		- hive: ^2.2.3
		- hive_flutter: ^1.1.0
		- workmanager: ^0.9.0
		- flutter_staggered_animations: latest
		- flutter_markdown: ^0.7.1
		- google_fonts: ^6.2.1

	**ENDPOINT API COMPLETI (v9.0):**
		**Public:**
		- Forecast: GET /api/forecast
		- Analysis (Cache Check): POST /api/get-analysis
		- Analysis (Fallback): POST /api/analyze-day-fallback
		- Natural Language Query: POST /api/query
		- Species Recommendation: POST /api/recommend-species
		- Proactive Trigger (Cron): GET /api/run-proactive-analysis		
		- Feedback: POST /api/submit-feedback ⭐ NEW
		- Geocoding: GET /api/autocomplete
		- Geocoding: GET /api/reverse-geocode
		- Memory Health: GET /api/memory-health ⭐ NEW
		- Server Health: GET /health
		
		**Admin (Protected):**
		- GET /admin/inspect-db
		- GET /admin/export-episodes ⭐ NEW
		- GET /admin/cleanup-memory ⭐ NEW
		- POST /admin/reload-ml-model ⭐ NEW
		- GET /api/admin/ml-metrics ⭐ NEW

	**AGENT TOOLS DISPONIBILI (4):**
		- `search_similar_episodes`: Memoria episodica semantica
		- `get_zone_statistics`: Statistiche aggregate zona
		- `search_knowledge_base`: RAG++ su KB (Hybrid Rerank)
		- `get_marine_forecast`: Dati oceano (onde/correnti) ⭐ NEW
		- ~~`analyze_weather_trend`~~: RIMOSSO (LLM nativo)

	**ML MODEL SPECS:**
		- Architecture: Gradient Boosting Regressor (scikit-learn)
		- Features: 13 (temp, wind, pressure, clouds, waves, water_temp, current, moon, pressure_trend, lat, lon, hour, month)
		- Training: Offline su GitHub Actions
		- Inference: ONNX Runtime (<15ms)
		- Target: pescaScore (0-10)
		- Blending: 80% ML + 20% Rules (se confidence >0.6)

	**LOCALITÀ DI TEST:**
		- Posillipo (Premium + Corrente): 40.813, 14.209
		- Napoli Centro: 40.8518, 14.2681
		- Roma (Generico Mare): 41.8902, 12.4922
		- Milano (Generico Standard): 45.4642, 9.1900

	**MCP TOOLS DISPONIBILI (Interni):**
		- La logica interna dei tool come `analyze_with_best_model` orchestra le chiamate dirette ai servizi `chromadb.service.js` (per il recupero) e `reranker.service.js` (per il riordino).

	**MCP RESOURCES DISPONIBILI (Interni):**
		- `kb://fishing/knowledge_base`: Rappresenta concettualmente l'accesso alla collection `fishing_knowledge` in ChromaDB.

	**LIMITI NOTI / RATE LIMITS:**
		- Google Gemini API (Free): 1500 req/day
		- Mistral AI API (Free): Rate limited
		- Cohere API (Free): Rate limited (Trial Key)
		- Hugging Face (Free): Rate limited
		- Stormglass API (Free): 10 req/day
		- WorldWeatherOnline (Free): 500 req/day
		- Open-Meteo (Free): 10,000 req/day

	**PERFORMANCE TARGETS (v9.0):**
		- Cache HIT (analysisCache): < 50ms ✅
		- Analisi Proattiva (background): ~15-20s ✅
		- ML Inference (ONNX): < 15ms ✅
		- Agent Query (3+ tool calls): < 10s ✅
		- Memory Query (similar episodes): < 2s ✅
		- Forecast API: < 3s ✅
		- **Query Vettoriale + Hybrid Reranking:** < 3s
		
	**FILE DA NON MODIFICARE MAI:**
		- `pubspec.lock`, `package-lock.json`
		- Cartelle `build/`, `.dart_tool/`, `node_modules/`
		- File autogenerati (`.g.dart`)
		- `data/memory/episodes.db` (gestito da app)
		- `data/ml/*.onnx` (generato da training)

	**FILE CRITICI PER L'AI/ML (Modificabili):**
		- `sources.json`: "Telecomando" per l'aggiornamento della conoscenza.
		- `tools/data-pipeline.js`: Script che genera `knowledge_base.json`.
		- `tools/migrate-to-chromadb.js`: Script con la logica di migrazione automatica.
		- `tools/train_model.py`: Training ML
		- `tools/convert_to_onnx.py`: Conversione ONNX
		- `lib/agents/fishing.agent.js`: Logica Agent Orchestrator
		- `lib/agents/fishing/tools.js`: Definizione Tools Agent
		- `lib/ml/predict.service.js`: Inference ML
		- `lib/db/memory.engine.js`: Gestione memoria
		- `lib/domain/score.calculator.js`: Hybrid scoring
		- `lib/services/chromadb.service.js`: Servizio di interazione con ChromaDB.
		- `lib/services/reranker.service.js`: Servizio di re-ranking ibrido.
		- `lib/services/proactive_analysis.service.js`: Trigger analisi background.


---
### 10. ANTI-PATTERN DA EVITARE (OBBLIGATORIO)
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
		- Security First: Tutte le rotte /api/ devono essere protette da Rate Limiting globale (max 100 req/15min).
		- CORS: Mai usare cors() aperto (*) in produzione; usare sempre whitelist via ENV.
		
---
### 10.1. GUIDA ALLA SEPARAZIONE DEI CONCERNS
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
		✅ Test Unitari: Ogni modulo critico (Domain/Utils) deve avere una suite Jest associata in test/ che copre i casi positivi e negativi.

---
### 10.2. GUIDA ALLE DIMENSIONI DEI MODULI (Code Review)
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
### 11. ESEMPI DI CODICE REFERENCE (Best Practice)
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
| 	|-- dartpad
| 	|-- extension_discovery
| 	|-- flutter_build
| 	|-- package_config.json
| 	|-- package_graph.json
| 	|-- version
|-- android/ # Wrapper nativo Android; contiene il codice sorgente per l'app Android.
| 	|-- .gradle
| 	|-- .kotlin
| 	|-- app
| 	|-- gradle
| 	|-- .gitignore
| 	|-- build.gradle.kts
| 	|-- gradle.properties
| 	|-- gradlew
| 	|-- gradlew.bat
| 	|-- local.properties
| 	|-- settings.gradle.kts
|-- assets/ # Risorse statiche come immagini e font.
| 	|-- fonts
| 	|-- background.jpg
| 	|-- background_daily.jpg
| 	|-- background_nocturnal.jpg
| 	|-- background_rainy.jpg
| 	|-- background_sunset.jpg
|-- build/ # Cartella di output per gli artefatti di compilazione.
| 	|-- .cxx
| 	|-- 6feb85370b059f99fb633de01be4ce52
| 	|-- app
| 	|-- app_settings
| 	|-- geolocator_android
| 	|-- light
| 	|-- native_assets
| 	|-- package_info_plus
| 	|-- path_provider_android
| 	|-- reports
| 	|-- shared_preferences_android
| 	|-- sqflite_android
| 	|-- workmanager_android
|	|-- f61019181a390ebae04f980d79c3991a.cache.dill.track.dill
|-- ios/ # Wrapper nativo iOS; contiene il progetto Xcode per l'app iOS.
| 	|-- Flutter
| 	|-- Runner
| 	|-- Runner.xcodeproj
| 	|-- Runner.xcworkspace
| 	|-- RunnerTests
| 	|-- .gitignore
|-- lib/ # Cuore dell'applicazione. Contiene tutto il codice sorgente Dart.
|   |-- models/ # Definisce le strutture dati (POJO/PODO).
|   |   |-- forecast_data.dart # Modello dati core. Delinea la struttura dell'intero payload JSON ricevuto dal backend, inclusi dati orari, giornalieri, astronomici e di pesca.
|   |-- screens/ # Componenti di primo livello che rappresentano un'intera schermata. 
|   |   |-- mission_control/              # Moduli Dashboard
|   |   |   |-- models.dart               # Dati (WorkerStatus, LogEntry)
|   |   |   |-- painters.dart             # CustomPainters (Grid, Plasma)
|   |   |   |-- mission_control_screen.dart # Presentation Layer (gestisce l'assemblaggio dei widget, le animazioni grafiche (parallasse, flusso) e il binding con il ViewModel, senza contenere più logica di business)
|   |   |   |-- mission_control_view_model.dart # Gestisce la business logic della dashboard, separando i dati dalla UI. Contiene lo stato reattivo (ChangeNotifier), i timer per la simulazione realtime delle metriche (latenza, carico CPU, log) e le funzioni di controllo per l'interattività dei widget.
|   |   |   |-- widgets/
|   |   |   |	|-- core_widgets.dart     # Widget Base (PlatinumCard, SectionLabel)
|   |   |   |   |-- diagnostic_widgets.dart # Threat Gauge, CPU/Mem Rows
|   |   |   |   |-- infrastructure_widgets.dart # SQLite/Chroma status, Cron jobs
|   |   |   |   |-- log_widgets.dart      # Terminal log viewer
|   |   |   |   |-- network_widgets.dart  # Latency card, IO stats
|   |   |   |   |-- worker_widgets.dart   # 3D Worker Rows
|   |   |-- forecast_screen.dart # "Container" di primo livello. La sua responsabilità è unicamente inizializzare e "possedere" i ViewModel e gestire la presentazione degli Overlay (es. SearchOverlay), senza contenere logica di business.
|   |-- services/ # Moduli dedicati alle interazioni con sistemi esterni.
|   |   |-- api_service.dart # Il "Data Layer" di rete. Aderisce al Principio di Singola Responsabilità: il suo UNICO compito è eseguire chiamate HTTP al backend e restituire risposte grezze (solitamente Map<String, dynamic>), senza logica di caching o di business.
|   |   |-- cache_service.dart # [CHIAVE-ARCHITETTURA] Il "Cervello della Cache". Centralizza TUTTA la logica di persistenza locale (lettura, scrittura, TTL) tramite Hive.
|   |-- utils/ # Funzioni helper pure, stateless e riutilizzabili. 
|   |   |-- weather_icon_mapper.dart # Traduttore di codici meteo in icone e colori.
|   |-- viewmodels/ # Contiene i "cervelli" della nostra UI (Pattern: ViewModel). Incapsulano la logica di stato e di business, disaccoppiandola dalla UI.
|   |   |-- forecast_viewmodel.dart # Il gestore dello stato e della logica di business per la schermata principale. Orchestra CacheServiceeApiService per recuperare i dati e li processa per la UI.
|   |   |-- analysis_viewmodel.dart # Il "cervello" dell'analisi AI. Incapsula tutta la logica a 3 fasi (cache locale -> cache backend -> fallback) e gestisce lo stato (_currentState, _analysisText, _errorText, _cachedMetadata), notificando la AnalysisView dei cambiamenti.
|   |-- widgets/ # Componenti UI riutilizzabili (mattoni dell'interfaccia).
|   |   |-- premium_drawer/ # Modulo UI per il menu laterale "Extra Platinum" con effetti olografici.
|   |   |   |-- drawer_footer_widgets.dart # Componente footer stile HUD che visualizza telemetria real-time (Lat/Lon/RAM) e stato di sicurezza.
|   |   |   |-- drawer_header_widgets.dart # Intestazione animata con effetto laser "Scanline" continuo e branding olografico.
|   |   |   |-- drawer_menu_widgets.dart # Lista di navigazione composta da pulsanti olografici (HoloMenuItem) con effetti glassmorphism e glow.
|   |   |   |-- mesh_gradient_painter.dart # Motore di rendering per lo sfondo "Living Glass" con gradienti fluidi animati.
|   |   |   |-- premium_drawer.dart # Widget principale del drawer laterale premium con animazioni
|   |   |   |-- premium_drawer_components.dart # Modello dati (lat/lon/mem) e configurazione voci menu
|   |   |   |-- premium_drawer_painters.dart # Custom painter per background animato con gradiente mesh
|   |   |-- analyst_card.dart # Contenitore "intelligente" (StatefulWidget) che crea, gestisce e fornisce l'istanza di AnalysisViewModelal suo widget figlio,AnalysisView
|   |   |-- analysis_view.dart # La "vista" pura dell'analisi AI. È un widget reattivo (es. Consumer) che si limita ad ascoltare i cambiamenti dell'AnalysisViewModel e a ricostruire la UI per mostrare lo stato appropriato (loading, success, error), senza contenere alcuna logica di business.
|   |   |-- analysis_skeleton_loader.dart # [CHIAVE-UX] Placeholder animato ("shimmer") per l'analisi di fallback.
|   |   |-- drawer_header_widgets.dart # Componenti header: logo, titolo, status e effetto scanline
|   |   |-- drawer_menu_widgets.dart # Lista menu animata con elementi interattivi ed effetti haptic
|   |   |-- drawer_footer_widgets.dart # Footer con dati telemetrici (LAT/LON/MEM) e status sicurezza
|   |   |-- feedback_dialog.dart # User feedback form
|   |   |-- fishing_score_indicator.dart # Dataviz specializzato per il pescaScore.
|   |   |-- forecast_page.dart # Componente di presentazione per una singola giornata di previsione.
|   |   |-- forecast_view.dart # Il "corpo" visivo della ForecastScreen. Ascolta il ForecastViewModel e mostra lo stato di caricamento, errore o i dati.
|   |   |-- glassmorphism_card.dart # Il "pilastro" del Design System. Widget riutilizzabile per l'effetto vetro.
|   |   |-- hourly_forecast.dart # Widget tabellare per le previsioni orarie.
|   |   |-- live_flow_diagram.dart # Widget principale che orchestra il diagramma interattivo, gestendo lo stato di selezione dei nodi, l'animazione parallasse e la logica di isolamento semantico (dimming).
|   |   |-- live_flow_diagram_nodes.dart # Libreria di componenti UI riutilizzabili per i nodi del grafo (Agenti, DB, Worker) e l'overlay del terminale olografico
|   |   |-- live_flow_diagram_painter.dart # Motore grafico CustomPainter che disegna le connessioni al neon, le curve di Bezier e le particelle dati animate tra i nodi.
|   |   |-- location_services_dialog.dart # Dialogo per la gestione dei permessi di localizzazione.
|   |   |-- main_hero_module.dart # Componente principale che mostra i dati salienti e ospita il trigger per l'analisi AI.
|   |   |-- score_chart_dialog.dart # Dataviz interattivo per il grafico del pescaScore.
|   |   |-- score_details_dialog.dart # Dialogo che spiega i "reasons" di un punteggio orario.
|   |   |-- search_overlay.dart # Layer UI per la ricerca di località.
|   |   |-- stale_data_dialog.dart # Dialogo di fallback per dati in cache obsoleti.
|   |   |-- system_metrics.dart # Widget per la visualizzazione delle metriche di sistema (CPU, RAM, Latenza) con grafici Plasma e indicatori di stato.
|   |   |-- weekly_forecast.dart # Dataviz per le previsioni settimanali. 
|-- main.dart # Il punto di ingresso e orchestratore. Inizializza l'app, apre i "box" di Hive, e registra/pianifica il task di aggiornamento in background tramite Workmanager.
|-- linux/ # Wrapper nativo Linux.
| 	|-- flutter
| 	|-- runner
| 	|-- .gitignore
| 	|-- CMakeLists.txt
|-- macos/ # Wrapper nativo macOS.
| 	|-- Flutter
| 	|-- Runner
| 	|-- Runner.xcodeproj
| 	|-- Runner.xcworkspace
| 	|-- RunnerTests
| 	|-- .gitignore
|-- node_modules/ # Dipendenze per strumenti di sviluppo basati su Node.js.
| 	|-- .bin
| 	|-- chromadb
| 	|-- chromadb-js-bindings-win32-x64-msvc
| 	|-- semver
| 	|-- .package-lock.json
|-- test/ # Contiene i file per i test automatici.
| 	|-- widget_test.dart
|-- web/ # Codice sorgente per la versione web.
| 	|-- icons
| 	|-- favicon.png
| 	|-- index.html
| 	|-- manifest.json
|-- windows/ # Wrapper nativo Windows.
| 	|-- flutter
| 	|-- runner
| 	|-- .gitignore
| 	|-- CMakeLists.txt
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
|-- .github/ # Contiene i workflow di automazione CI/CD
|   |-- workflows/ # File di configurazione per GitHub Actions
|   |   |-- train-ml-model.yml # Workflow CI/CD per l'addestramento e l'aggiornamento del modello di Machine Learning (ML).
|   |   |-- update-kb.yml # Workflow CI che, alla modifica di `sources.json`, lancia la data-pipeline per aggiornare la Knowledge Base (`knowledge_base.json`).
|-- api/ # Handler degli endpoint REST. La logica è mantenuta leggera e delegata ai servizi.
|   |-- admin/ # Endpoint amministrativi per la manutenzione del sistema.
|   |   |-- cleanup-memory.js # Handler per l'esecuzione manuale della policy di pulizia della memoria (SQLite e ChromaDB).
|   |   |-- export-episodes.js # Handler per l'esportazione dei dati storici degli episodi di pesca.
|   |   |-- ml-metrics.js # Endpoint monitoraggio performance ML e risorse 
|   |-- analyze-day-fallback.js # Endpoint per attivare l'analisi AI in modalità fallback o su richiesta esplicita (non tramite logica automatica).
|   |-- autocomplete.js # Gestisce i suggerimenti di località basati sull'input dell'utente.
|   |-- memory-health.js # Restituisce lo stato di salute e le statistiche del sistema di memoria (SQLite e ChromaDB).
|   |-- query-natural-language.js # Gestisce le query conversazionali in linguaggio naturale, orchestrate tramite il Memory and Compute Plane (MCP).
|   |-- recommend-species.js # Gestisce le richieste di raccomandazioni per specie di pesce, orchestrate tramite MCP.
|   |-- reverse-geocode.js # Esegue la geolocalizzazione inversa (conversione di coordinate in nome località).
|   |-- submit-feedback.js # Handler per l'invio del feedback degli utenti sull'accuratezza delle analisi AI.
|-- data/ # Contiene dati persistenti e file generati in runtime dall'applicazione. E' stata creata per supportare il test [eventualmente da rimuovere in un secondo momento]
|   |-- data/ #
|   |-- memory/ #
|   |-- ml/ #
-- lib/ # Core dell'applicazione: logica di business, servizi, utilità.
|   |-- agents/ # 
|   |   |-- orchestrator/ # Moduli di supporto specifici per l'agente di pesca.
|   |   |   |-- super.agent.js # Super Agent Orchestrator (Cervello Centrale)
|   |   |   |-- routing.strategy.js # Logica di routing e decomposizione query
|   |   |   |-- response.aggregator.js # Aggregazione risposte dai Workers
|   |   |-- workers/ # 
|   |   |   |-- meteo.analyst.js # Specialista Analisi Meteorologica
|   |   |   |-- gear.strategist.js # Specialista Attrezzatura & Tecniche
|   |   |   |-- marine.specialist.js # Specialista Condizioni Marine
|   |   |   |-- memory.retriever.js # Specialista Ricerca Memoria Episodica
|   |   |   |-- species.advisor.js # Specialista Raccomandazioni Specie
|   |   |-- shared/ # 
|   |   |   |-- base.worker.js # Classe astratta base per tutti i Workers
|   |   |   |-- tool.registry.js # Registry dei tool disponibili per ogni Worker
|   |   |   |-- context.builder.js # Builder per contesti specializzati
|   |-- core/ # Nucleo centrale dell'infrastruttura server.
|   |   |-- server/
|   |   |   |-- bootstrap.js # Inizializzazione sequenziale dei servizi critici (DB, ML, MCP).
|   |   |   |-- routes.js # Definizione e registrazione di tutte le rotte API.
|   |-- db/ # Gestione del database persistente.
|   |   |-- memory/ # Componenti interni del sistema di memoria.
|   |   |   |-- chroma_client.js # Client HTTP per operazioni semantiche su ChromaDB.
|   |   |   |-- sqlite_client.js # Gestione schema e query strutturate su SQLite.
|   |   |   |-- cache_manager.js # Gestione della cache in-memory (Hot Cache).
|   |   |-- memory.engine.js # Orchestratore: coordina SQLite, Chroma e Cache.
|   |-- domain/ # Logica di business pura e calcoli specifici del dominio "pesca".
|   |   |-- forecast.assembler.js # Assembla e normalizza i dati grezzi provenienti da tutte le API meteo in un formato JSON strutturato unico.
|   |   |-- score.calculator.js # Algoritmo proprietario che calcola il "pescaScore" orario e giornaliero.
|   |   |-- weather.service.js # Aggrega e coordina in parallelo il recupero dati da tutte le fonti API meteo esterne.
|   |   |-- window.calculator.js # Algoritmo che identifica le "finestre di pesca ottimali" in base a parametri metereologici e astronomici.
|   |-- ml/ # Moduli relativi al Machine Learning e alla previsione.
|   |   |-- data_quality.js # Logica di anomaly detection sui dati di feedback
|   |   |-- predict.service.js # Servizio per la gestione e l'esecuzione delle previsioni del modello ML serializzato.
|   |-- services/ # Moduli che comunicano con sistemi esterni (API, DB) e LLM.
|   |   |-- chromadb.service.js # Servizio wrapper per la gestione di tutte le interazioni CRUD (Create, Read, Update, Delete) con ChromaDB.
|   |   |-- claude.service.js # Wrapper per l'API di Anthropic Claude (Generazione di testo).
|   |   |-- gemini.service.js # Wrapper per l'API di Google Gemini (Generazione di testo e calcolo degli embeddings).
|   |   |-- geo.service.js # Servizio unificato per geocoding, reverse geocoding e ricerca di località.
|   |   |-- marine.service.js # Servizio che aggrega i dati marini (maree, onde) da fonti esterne specializzate.
|   |   |-- mcp-client.service.js # [MOCK] Simula il client del Memory and Compute Plane, eseguendo i tool come funzioni locali.
|   |   |-- mistral.service.js # Wrapper per l'API di Mistral AI (Generazione di testo).
|   |   |-- openmeteo.service.js # Servizio specializzato per l'API Open-Meteo (Previsioni meteorologiche).
|   |   |-- proactive_analysis.service.js # Motore dell'analisi proattiva basata sull'architettura P.H.A.N.T.O.M.
|   |   |-- reranker.service.js # Chiama l'API Hugging Face per il re-ranking dei risultati di ricerca semantica di ChromaDB.
|   |   |-- stormglass.service.js # Servizio specializzato per l'API Stormglass (Dati marini e meteo).
|   |   |-- wwo.service.js # Servizio specializzato per l'API WorldWeatherOnline (Dati meteo aggiuntivi).
|   |-- utils/ # Funzioni helper pure, stateless e riutilizzabili in tutto il backend.
|   |   |-- cache.manager.js # Gestisce le istanze di cache in-memory (per dati meteo, analisi AI, ecc.).
|   |   |-- constants.js # Contiene costanti globali e di configurazione (es. URL API, soglie di punteggio).
|   |   |-- formatter.js # Funzioni pure per la formattazione di date, numeri e altre stringhe.
|   |   |-- geo.utils.js # Funzioni di utilità geospaziale (es. calcolo distanze, conversioni di coordinate).
|   |   |-- logger.js # Logger strutturato Pino
|   |   |-- query-expander.js # [LEGACY, da rimuovere] Logica obsoleta per l'espansione delle query di ricerca pre-ChromaDB.
|   |   |-- validation.js # Schemi Zod per validazione input rigorosa
|   |   |-- wmo_code_converter.js # Converte i codici meteo WMO in descrizioni testuali comprensibili dall'utente.
| 	|-- forecast-logic.js # Orchestratore principale che coordina il flusso di recupero e assemblaggio dati meteo
|-- mcp/ # Infrastruttura concettuale del Model Context Protocol (MCP) per l'orchestrazione AI e la gestione delle risorse.
|   |-- resources/ # Risorse esposte in modo standardizzato che gli Agenti e i Tool possono invocare.
|   |   |-- knowledge-base.js # Espone i metodi per l'accesso e la query alla Memoria Semantica (ChromaDB), gestendo il flusso RAG di recupero.
|   |-- tools/ # Tool AI eseguibili che estendono le capacità del Modello (es. RAG, raccomandazioni).
|   |   |-- analyze-with-best-model.js # [CHIAVE] Tool che orchestra la pipeline di analisi AI completa: ChromaDB query -> Re-rank -> Generazione da LLM (con fallback automatico a Mistral in caso di fallimento di Gemini).
|   |   |-- extract-intent.js # Tool che analizza una query dell'utente per estrarre l'intento principale e le entità pertinenti.
|   |   |-- recommend-for-species.js # Tool che genera raccomandazioni operative e basate sui dati per una specie ittica specifica.
|-- node_modules/ # Dipendenze npm installate per il progetto
|   |-- @mistralai/ # SDK per l'API di Mistral AI
|   |-- @anthropic-ai/ # SDK per l'API di Anthropic (Claude)
|   |-- @huggingface/ # SDK per l'API di Hugging Face Inference, usato dal re-ranker
|   |-- @google/ # SDK per l'API di Google (Gemini)
|   |-- @modelcontextprotocol/ # SDK per il Model Context Protocol
|   |-- chromadb/ # Client JavaScript per comunicare con il server ChromaDB
|   |-- chromadb-default-embed/ # Dipendenza di ChromaDB per embedding di default (non usata da noi)
|   |-- several files and folders # Altre dipendenze e sotto-dipendenze del progetto
|-- pesca_app/ # Codice sorgente del frontend Flutter (non espanso qui)
|   |-- build # Cartella di output della build del frontend
|-- public/ # Asset statici serviti direttamente da Express.
|-- test/ # Suite di test automatizzati (Miglioria 6).
|   |-- domain/ #
|   |   |-- score.calculator.test.js # Unit test per logica di dominio (es. blending ML+Rules).
|   |-- utils/ #
|   |   |-- validation.test.js # Unit test per schemi Zod e Data Quality.
|   |-- manual/ # Script di test manuali e legacy (spostati dalla root).
|   |   |-- test-chroma-v2.js # Script per verifica manuale connessione ChromaDB v2.
|   |   |-- test-chroma.js # Script legacy per test base ChromaDB.
|   |   |-- test-endpoints.js # Script per invocare manualmente gli endpoint API.
|   |   |-- test-results.json # File di output generato dai test manuali.
|   |   |-- test-simple.js # Sanity check minimale per l'avvio del server.
|-- tools/ # Script di supporto, pipeline dati e utilità per la manutenzione.
|   |-- convert_to_onnx.py # Script Python per convertire il modello ML allenato nel formato ONNX per l'ottimizzazione e il deploy.
|   |-- data-pipeline.js # Script eseguito da GitHub Actions per pre-processare le fonti dati e generare il file `knowledge_base.json`.
|   |-- inspect-chroma.js # Script di utilità per interrogare e ispezionare manualmente lo stato del server ChromaDB (debug).
|   |-- Project_lib_extract.ps1 # Script PowerShell per estrarre o analizzare la struttura della libreria (`lib/`).
|   |-- train_model.py # Script Python per l'addestramento e la valutazione del modello di Machine Learning.
|   |-- Update-ProjectDocs.ps1 # Script PowerShell per l'aggiornamento automatico della documentazione di progetto (es. README).
|-- .dockerignore # Specifica i file da ignorare durante la creazione dell'immagine Docker.
|-- .env # File per le variabili d'ambiente locali (API keys, etc.) - NON COMMETTERE MAI SU GIT.
|-- .gitignore #
|-- docker-compose.yml #
|-- Dockerfile # Definisce l'ambiente del container per Render (include Node.js e dipendenze Python per Chroma).
|-- knowledge_base.json # "Source of truth" per la KB, generato da CI/CD e usato per la migrazione automatica.
|-- package-lock.json #
|-- package.json # Definisce le dipendenze npm e gli script del progetto.
|-- server.js # Entry point minimale: avvia il bootstrap e il listener HTTP.
|-- sources.json # "Telecomando" dell'AI: le sue modifiche su Git innescano l'aggiornamento della KB.
|-- start.sh # Script di avvio per Render che orchestra i processi Node.js e ChromaDB.
```



######################################################################################################################################################
######################################################################################################################################################
################################################################# SINTESI DEL READMI #################################################################
######################################################################################################################################################
######################################################################################################################################################


***

---

## 👻 Architettura P.H.A.N.T.O.M. v10.0 (Multi-Agent System)

Il sistema **P.H.A.N.T.O.M.** è un'architettura **Multi-Agent Ibrida** che orchestra intelligenza matematica locale (Edge AI) e capacità di ragionamento linguistico in cloud (LLM).

Per comprendere il flusso logico, analizziamo cosa accade dietro le quinte con un esempio reale:

> **Richiesta Utente:** *"Che pesce posso pescare domani mattina a Posillipo e perché?"*

*   **Nota:** Attualmente questa interazione è gestita su tre livelli:
*   **Implicita (UI):** La selezione di una località nell'App viene tradotta automaticamente nell'intent di analisi ("Analizza oggi/domani").
*   **Simulata (Background):** Il servizio proattivo (`proactive_analysis.service.js`) simula periodicamente queste query specifiche per pre-calcolare gli insight tramite il Super Agent.
*   **Nativa (Backend):** L'endpoint `/api/query` supporta già il linguaggio naturale, rendendo l'architettura pronta per future interfacce Chat o Voice senza refactoring.

---

### 1. 🌡️ Il Termometro della Realtà (ML Predittivo Locale)
Prima che gli agenti inizino a "pensare", il sistema stabilisce oggettivamente la qualità della giornata.

*   **L'Azione:** Il sistema alimenta il modello **Machine Learning locale** (`pesca_model.onnx`) con i dati meteo grezzi (Vento 15km/h, onde 0.8m, ecc.), che in questa fase sono recuperati tramite WeatherService.
*   **Il Dato (PescaScore):** Il modello calcola istantaneamente un punteggio, es. **7.8/10**. Non "pensa" come un umano, ma applica una formula statistica complessa (*Gradient Boosting*) basata su migliaia di bivi decisionali appresi dallo storico.
*   **Cold Start:** Attualmente il modello è un "Seed Model" (addestrato su regole euristiche sintetiche). Man mano che gli utenti invieranno feedback reali, un workflow automatico (GitHub Actions) ri-addestrerà mensilmente il modello sulla realtà accumulata in SQLite.
*   **Il Vincolo:** Questo voto (**7.8**) viene imposto a tutti i Workers: nessuno può consigliare strategie fallimentari se la matematica dice che le condizioni sono buone, e viceversa.

---

### 2. 🧠 Il Cervello Centrale (Super Agent Orchestrator)
Ora che abbiamo il "voto" oggettivo, entra in gioco il **Super Agent** (Node.js), che organizza il lavoro intellettuale.

*   **Routing Intelligente:** Analizza la richiesta (*"pesce"*, *"domani"*, *"Posillipo"*) e comprende che serve una strategia complessa.
*   **Reclutamento:** Attiva in parallelo solo gli **Specialisti (Workers)** necessari, fornendo loro il PescaScore come guida:
    *   `MeteoAnalyst`: Per i trend barometrici (da API OpenMeteo recupera dati live: pressione, vento, pioggia.)
    *   `MarineSpecialist`: Per lo stato del mare e le correnti (da API Marine recupera dati live: altezza onde, correnti)
    *   `SpeciesAdvisor`: Per la biologia delle prede (da ChromaDB (RAG) conoscenza statica: manuali, biologia, abitudini pesci)
    *   `MemoryRetriever`: Per cercare episodi passati simili (da SQLite + Chroma recupera esperienza passata: i vecchi feedback.)
*   **Parallelismo:** Questi agenti lavorano **contemporaneamente**, riducendo drasticamente i tempi di attesa.

---

### 3. 📚 La Biblioteca e la Memoria (Workers in Azione)
Gli agenti non "inventano" le informazioni, le recuperano da fonti certificate e poi "pensano" usando l'LLM (Gemini) come cervello.

*   **RAG (Conoscenza Tecnica):** Lo `SpeciesAdvisor` consulta la **Knowledge Base** (ChromaDB). Cerca documenti reali (manuali, articoli). Si alimenta sia manualmente (`sources.json`) che automaticamente tramite la parte descrittiva dei feedback utente (memoria associativa).
    *   *Esempio:* Trova un documento: *"Con vento da Nord a Posillipo gira la Spigola"*.
*   **Memoria Episodica (Esperienza):** Il `MemoryRetriever` consulta il database storico (SQLite). Si alimenta automaticamente con la parte numerica dei feedback utente (memoria numerica) ed è la base per il riaddestramento del ML.
    *   *Esempio:* Cerca: *"Cosa è successo l'anno scorso con queste condizioni?"* e trova una cattura passata come prova.

---

### 4. 🗣️ La Sintesi (Il Ruolo di Gemini/Cloud AI)
Qui avviene l'interazione finale tra "Corpo" (Codice) e "Mente" (LLM).

*   **Il Corpo (Node.js):** Il componente `Response Aggregator` raccoglie i report tecnici dei singoli Workers (già elaborati tramite i loro System Prompts).
*   **La Mente (Gemini):** Il sistema invia tutto questo pacchetto di dati al Cloud con un'istruzione: *"Agisci come un consulente esperto e unisci questi fatti in una risposta coerente"*.
*   **L'Output:** Gemini usa la sua capacità linguistica per collegare i puntini forniti dai Workers, senza allucinare: *"Domani a Posillipo le condizioni sono ottime (**Score 7.8**). Il mare mosso (dato Marine) favorisce i predatori. Basandomi sui manuali locali (dato RAG), ti consiglio di puntare alla **Spigola**..."*

---

### ⚙️ Caratteristiche Architetturali

*   **Resilienza:** Se un Worker fallisce, il Super Agent fornisce una risposta parziale (Graceful Degradation).
*   **Velocità Proattiva:** Di notte il sistema pre-calcola le analisi, permettendo risposte istantanee (<50ms) all'apertura dell'app.
*   **Zero-Cost:** Uso esclusivo di risorse Free Tier (Render, GitHub, Gemini) per sostenibilità totale.