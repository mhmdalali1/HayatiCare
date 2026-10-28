import sys, os
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), "backend", ".env"))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "backend"))
from app.services.ai_service import ingest_documents
ingest_documents()
print("Ingestion complete.")
