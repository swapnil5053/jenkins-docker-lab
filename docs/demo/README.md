# Demo Assets

This folder contains runtime evidence and demo assets for the platform.

- `sample_requests.py` — lightweight proof script to query the NGINX frontend and capture backend hostnames.
- `demo-output.txt` — generated sample output showing request response behavior.

## How to use

1. Start the platform: `docker compose up -d`
2. Run the sample script: `python docs/demo/sample_requests.py`
3. Review `docs/demo/demo-output.txt` for a captured sample run.
