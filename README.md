# MAWA - More Than A Weather App 🌤️

MAWA (More Than A Weather App) is a location-aware environmental intelligence Android application built with **Flutter 3.x** and **Dart 3.x**. MAWA aggregates real-time weather metrics and severe weather alerts from the **National Weather Service (NWS)**, seismic activity from the **USGS Earthquake Hazards Program**, and connects to **Google Gemma 4** via the **OpenRouter API** to generate plain-language safety briefings.

---

## 🤖 AI Model & OpenRouter Connection Details

MAWA integrates with open-weight AI models to summarize environmental hazards into plain-language safety guidance:

* **AI Model Name**: `google/gemma-4-31b-it:free` (Google Gemma 4 31B Instruct)
* **API Provider & Location**: OpenRouter Cloud API Gateway (`https://openrouter.ai/api/v1/chat/completions`)
* **Privacy & Security**: Test prompts contain zero personal user information.

---

## 🔑 Security & OpenRouter API Key Setup (`--dart-define`)

> [!IMPORTANT]
> **API Key Security Requirement**:
> OpenRouter API keys must **never be hardcoded in source code files or committed to Git repositories**. The key is passed securely at build/runtime using `--dart-define=OPENROUTER_API_KEY=your_key_here`.

### Step 1: Obtain a Free OpenRouter API Key
1. Go to [https://openrouter.ai](https://openrouter.ai) and sign in or create an account.
2. Go to [https://openrouter.ai/keys](https://openrouter.ai/keys) and click **Create Key**.
3. Name your key (e.g. `MAWA Capstone`) and copy the generated key (starts with `sk-or-v1-...`).

### Step 2: Configure Android Studio Run Configuration
1. Open Android Studio and go to **Run ➔ Edit Configurations...**
2. Select your Flutter run configuration (**main.dart**).
3. In the **Additional run args** field, add:
   ```text
   --dart-define=OPENROUTER_API_KEY=sk-or-v1-your-actual-api-key-here
   ```
4. Click **Apply** and **OK**.

### Step 3: Run via Command Line / Terminal
You can also run the application directly from terminal:
```bash
flutter run --dart-define=OPENROUTER_API_KEY=sk-or-v1-your-actual-api-key-here
```

---

## 🚀 Key Features Implemented

* **User Profiles & Local Authentication**: Persistent account creation, login/logout sessions using `SharedPreferences`.
* **GPS & Location Services**: Runtime location permission consent, GPS hardware verification, and system settings redirection using `geolocator`.
* **Exact Reverse-Geocoding**: Converts raw GPS coordinates into exact street addresses and zip codes using `geocoding`.
* **National Weather Service (NWS) 2-Step Pipeline**: Fetches live temperature, weather conditions, wind speed/direction, relative humidity, and precipitation probability via `http`.
* **NWS Active Weather Alerts**: Displays active hazard warnings tagged with **"City-wide"** and **"for your information"** badges, or reassures users with *"No active alerts for your area"*.
* **USGS Earthquakes by Ring**: Queries seismic events within 50 km (last 7 days, magnitude ≥ 2.5), calculates geodesic distance in km, sorts quakes closest-first, and tags them by closeness ring (**`Here`** ≤2.5 km, **`Nearby`** ≤15 km, **`City-wide`** >15 km).
* **AI Model Connection Test Screen**: Developer test screen (`LlmTestScreen`) verifying connection to `google/gemma-4-31b:free` via OpenRouter.

---

## 🧪 Running Automated Tests

Run the full automated unit and widget test suite (40+ passing tests):
```bash
flutter test
```
