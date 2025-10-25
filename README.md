# Locallens — AI-Powered Hyperlocal Discovery

![Locallens architecture](https://user-gen-media-assets.s3.amazonaws.com/seedream_images/e0fbf4cb-5d65-463e-97d7-3d48ef0f8323.png)

Locallens helps users discover, compare, and purchase products from local and online stores while optimizing for verified inventory, price, pickup time, and sustainability.

## Key features

- Universal product resolver (links, images, voice) using computer vision + NLP
- Real-time local & online comparison (price, stock, pickup time, CO₂ footprint)
- AI trip & bulk-order planner for efficient pickups and reduced emissions
- Community verification and crowdsourced inventory updates
- Rewards & referral system to incentivize healthy/local shopping

## Why Locallens

Locallens combines agentic AI, community trust signals, and route optimization to surface healthier, lower-carbon shopping options at neighborhood scale.

## Technology stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (mobile/web), optional React dashboard |
| Backend | Python (FastAPI), Node.js services |
| Database | Firebase Firestore, MongoDB |
| AI / ML | Hugging Face models, Gemini Vision API (optional) |
| Routing | Google Maps API, OR-Tools |
| Scraping | Scrapy, BeautifulSoup |
| Cache | Redis |
| Auth & Security | OAuth2, AES encryption for sensitive data |

## Quick start (developer)

Requirements: Flutter SDK, Python 3.8+, Node.js, and git.

1. Clone the repo

```powershell
git clone https://github.com/Aditya-MP/Locallens-AI-Powered-Hyperlocal-Discovery-Optimization.git
cd Locallens/locallens
```

2. Install frontend deps (Flutter)

```powershell
flutter pub get
```

3. (Optional) Install React dashboard deps

```powershell
cd web
npm install
cd ..
```

4. Backend (Python)

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

5. Configure environment variables

Create a `.env` file with keys for Google Maps, Gemini (if used), and any merchant APIs. Example:

```env
GOOGLE_MAPS_API_KEY=your_key
GEMINI_API_KEY=your_key
```

6. Run services

- FastAPI backend:

```powershell
python main.py
```

- Flutter frontend (mobile/web):

```powershell
flutter run
```

## Contributing

Contributions are welcome. Suggested workflow:

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Commit changes and push
4. Open a pull request describing your changes

See `CONTRIBUTING.md` for detailed guidelines.

## License

This project is licensed under the MIT License — see `LICENSE.md`.

## Acknowledgments

MumbaiHacks 2025 and early contributors.

---
_Last updated: 2025-10-25 UTC_
