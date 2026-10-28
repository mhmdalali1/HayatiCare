"""
run.py — Entry point for the HMSS Flask development server.

Usage (from the backend/ directory):
    python run.py
"""

import os
import sys

# Ensure the backend/ directory is on the path regardless of where
# this script is invoked from (e.g. python backend/run.py from the root).
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app

# Determine environment from ENV variable (defaults to development)
env = os.environ.get("FLASK_ENV", "development")
app = create_app(env)

if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=int(os.environ.get("PORT", 5000)),
        debug=(env == "development"),
    )
