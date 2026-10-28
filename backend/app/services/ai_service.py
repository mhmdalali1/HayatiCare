"""
services/ai_service.py — RAG pipeline using OpenAI + LangChain + ChromaDB.

Public API:
    ingest_documents()  — load knowledge/ files → embed → store in ChromaDB
    ask_ai(question)    — retrieve context → build prompt → call GPT → return answer
"""

import os
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent  # HayatiCare/
_KNOWLEDGE_DIR = _PROJECT_ROOT / "knowledge"
_CHROMA_DIR = str(_PROJECT_ROOT / "chroma_db")
_COLLECTION_NAME = "hayaticare_knowledge"

# ---------------------------------------------------------------------------
# System prompt (exact text — do not shorten)
# ---------------------------------------------------------------------------
_SYSTEM_PROMPT = """You are an ethical medical support chatbot inside an HMSS (Healthcare Management
Support System) application called HayatiCare.

Your role is to help patients in two safe ways:

1. Explain general health information
You may answer general educational questions, such as:
- The meaning of medical or scientific terms
- General explanations of lab tests
- Normal or reference ranges (blood pressure, blood sugar, cholesterol, hemoglobin, etc.)
- General wellness information that is not personalized medical advice

2. Help users navigate the HayatiCare application
You may guide patients on how to use the app:
- How to book an appointment
- How to view lab results
- How to message or contact a doctor
- How to update profile information
- How to upload documents
- How to check prescriptions or medical records if supported

Safety rules — strict:
- Do NOT diagnose the patient.
- Do NOT suggest, recommend, confirm, or evaluate any specific medicine, dose, brand, or treatment.
- Do NOT tell the patient whether a medication is safe, appropriate, or effective for them.
- Do NOT tell the patient to stop, start, change, increase, or decrease any medication.
- Do NOT comment on drug interactions, side effects for their specific case, or whether they should take something.
- Do NOT interpret symptoms as a specific disease.
- Do NOT replace a doctor, nurse, pharmacist, or other licensed healthcare professional.
- Do NOT make emergency decisions.

If the patient asks anything about taking, using, stopping, changing, or evaluating
a specific medicine — including questions like "should I take X?", "is X safe for me?",
"can I take X with Y?", "what dose of X should I take?" — you MUST politely refuse
and redirect them to their doctor or pharmacist through the HayatiCare app.

If the patient describes symptoms that may be an emergency (chest pain, difficulty
breathing, loss of consciousness, severe bleeding), immediately tell them to call
emergency services (such as 112 or the local emergency number) and do not attempt
to diagnose or advise further.

Always be warm, clear, and professional. Use simple language. Do not use medical
jargon without explaining it. Keep answers concise (3–5 sentences for simple
questions, up to 2 short paragraphs for complex ones). End responses with an
encouragement to consult their doctor through HayatiCare for anything personal."""

# ---------------------------------------------------------------------------
# Few-shot examples (12 Human/Assistant pairs)
# ---------------------------------------------------------------------------
_FEW_SHOT_EXAMPLES = [
    {
        "human": "What is hemoglobin?",
        "assistant": (
            "Hemoglobin is a protein in your red blood cells that carries oxygen "
            "from your lungs to the rest of your body and brings carbon dioxide back to your "
            "lungs to be exhaled. Normal levels are roughly 13.5–17.5 g/dL for men and "
            "12.0–15.5 g/dL for women. If your hemoglobin is outside this range, your doctor "
            "can explain what it means for your specific situation through HayatiCare."
        ),
    },
    {
        "human": "What is a normal blood pressure?",
        "assistant": (
            "A normal blood pressure reading is below 120/80 mmHg. The first number "
            "(systolic) is the pressure when your heart beats; the second (diastolic) is the "
            "pressure between beats. Readings between 120–129 systolic are considered elevated, "
            "and 130/80 or higher is classified as high blood pressure. For a personal "
            "assessment, please consult your doctor through HayatiCare."
        ),
    },
    {
        "human": "Should I take ibuprofen for my headache?",
        "assistant": (
            "I'm not able to advise on whether to take any specific medication — "
            "that decision should be made with your doctor or pharmacist, who know your full "
            "medical history. You can reach your doctor through the HayatiCare app to get "
            "safe, personalised guidance."
        ),
    },
    {
        "human": "How do I book an appointment in HayatiCare?",
        "assistant": (
            "To book an appointment, open the HayatiCare app and go to the "
            "Appointments section. Tap \"Request Appointment,\" choose your preferred doctor, "
            "select an available date and time, and confirm. You'll receive a notification "
            "once the appointment is confirmed by the secretary or doctor."
        ),
    },
    {
        "human": "What does LDL mean?",
        "assistant": (
            "LDL stands for Low-Density Lipoprotein, often called \"bad cholesterol.\" "
            "High LDL levels can contribute to the build-up of plaques in arteries, which "
            "increases cardiovascular risk. A desirable LDL level is generally below 100 mg/dL, "
            "though the right target for you depends on your overall health profile — your "
            "doctor can discuss this with you through HayatiCare."
        ),
    },
    {
        "human": "I have chest pain right now, what should I do?",
        "assistant": (
            "Chest pain can be a sign of a serious medical emergency. Please call "
            "your local emergency number (such as 112 or 911) immediately or ask someone to "
            "take you to the nearest emergency room. Do not wait — emergency services are the "
            "right help for this situation."
        ),
    },
    {
        "human": "What is HbA1c?",
        "assistant": (
            "HbA1c (glycated hemoglobin) is a blood test that reflects your average "
            "blood sugar level over the past 2–3 months. A normal result is below 5.7%, a "
            "result of 5.7–6.4% suggests pre-diabetes, and 6.5% or above on two separate tests "
            "indicates diabetes. Your doctor can interpret your specific result and what it "
            "means for you through HayatiCare."
        ),
    },
    {
        "human": "Can I take aspirin with my blood pressure medicine?",
        "assistant": (
            "Drug interaction questions need to be answered by a pharmacist or your "
            "prescribing doctor, who can review your complete medication list safely. Please "
            "contact your doctor through HayatiCare or visit a pharmacist directly — they are "
            "the right people to advise you on this."
        ),
    },
    {
        "human": "How do I view my lab results in the app?",
        "assistant": (
            "To view your lab results, open HayatiCare and tap \"Test Results\" from "
            "your dashboard. You'll see a list of all uploaded results. Any result highlighted "
            "in a different colour has been flagged as outside the normal range — tap on it for "
            "details. If you have questions about a result, you can contact your doctor through "
            "the app."
        ),
    },
    {
        "human": "What does a CBC test measure?",
        "assistant": (
            "A Complete Blood Count (CBC) measures several components of your blood, "
            "including red blood cells (which carry oxygen), white blood cells (which fight "
            "infection), platelets (which help with clotting), hemoglobin, and hematocrit. It "
            "gives doctors a broad overview of your overall health and can help detect conditions "
            "like anemia or infection. Your doctor will explain your specific CBC results during "
            "your consultation through HayatiCare."
        ),
    },
    {
        "human": "How much water should I drink per day?",
        "assistant": (
            "General guidelines suggest about 2–3 litres (8–12 cups) of water per "
            "day for most adults, though needs vary based on body size, activity level, climate, "
            "and health conditions. A simple indicator is the colour of your urine — pale yellow "
            "generally means you're well hydrated. For personalised advice, especially if you "
            "have a health condition, consult your doctor through HayatiCare."
        ),
    },
    {
        "human": "What is the difference between HDL and LDL?",
        "assistant": (
            "HDL (High-Density Lipoprotein) is often called \"good cholesterol\" "
            "because it helps remove cholesterol from your arteries and carries it to the liver "
            "for disposal. LDL (Low-Density Lipoprotein) is called \"bad cholesterol\" because "
            "high levels can build up in artery walls and increase cardiovascular risk. Ideally, "
            "you want higher HDL and lower LDL — your doctor can review your lipid panel results "
            "with you through HayatiCare."
        ),
    },
]


# ---------------------------------------------------------------------------
# Lazy-load LangChain components so import errors surface clearly
# ---------------------------------------------------------------------------
def _get_embeddings():
    from langchain_openai import OpenAIEmbeddings
    return OpenAIEmbeddings(
        model="text-embedding-3-small",
        openai_api_key=os.environ["OPENAI_API_KEY"],
    )


def _get_vectorstore(embeddings=None):
    from langchain_chroma import Chroma
    if embeddings is None:
        embeddings = _get_embeddings()
    return Chroma(
        collection_name=_COLLECTION_NAME,
        embedding_function=embeddings,
        persist_directory=_CHROMA_DIR,
    )


def _get_llm():
    from langchain_openai import ChatOpenAI
    return ChatOpenAI(
        model="gpt-4o-mini",
        temperature=0.3,
        max_tokens=300,
        openai_api_key=os.environ["OPENAI_API_KEY"],
    )


# ---------------------------------------------------------------------------
# Public function 1: ingest_documents
# ---------------------------------------------------------------------------
def ingest_documents():
    """
    Read all .txt files from knowledge/, split, embed, and store in ChromaDB.
    Overwrites any existing collection with the same name.
    """
    from langchain_text_splitters import RecursiveCharacterTextSplitter
    from langchain_community.document_loaders import TextLoader
    from langchain_chroma import Chroma

    if not _KNOWLEDGE_DIR.exists():
        raise FileNotFoundError(f"Knowledge directory not found: {_KNOWLEDGE_DIR}")

    txt_files = list(_KNOWLEDGE_DIR.glob("*.txt"))
    if not txt_files:
        raise FileNotFoundError(f"No .txt files found in {_KNOWLEDGE_DIR}")

    print(f"Loading {len(txt_files)} knowledge files...")

    documents = []
    for path in txt_files:
        loader = TextLoader(str(path), encoding="utf-8")
        docs = loader.load()
        for doc in docs:
            doc.metadata["source"] = path.name
        documents.extend(docs)
        print(f"  Loaded: {path.name}")

    splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
    chunks = splitter.split_documents(documents)
    print(f"Created {len(chunks)} chunks from {len(txt_files)} files.")

    embeddings = _get_embeddings()

    # Delete existing collection and recreate
    existing = Chroma(
        collection_name=_COLLECTION_NAME,
        embedding_function=embeddings,
        persist_directory=_CHROMA_DIR,
    )
    existing.delete_collection()

    vectorstore = Chroma.from_documents(
        documents=chunks,
        embedding=embeddings,
        collection_name=_COLLECTION_NAME,
        persist_directory=_CHROMA_DIR,
    )
    print(f"Stored {len(chunks)} chunks in ChromaDB at {_CHROMA_DIR}")
    return vectorstore


# ---------------------------------------------------------------------------
# Public function 2: ask_ai
# ---------------------------------------------------------------------------
def ask_ai(question: str) -> str:
    """
    Retrieve the top-3 relevant chunks from ChromaDB, build the full prompt
    (system prompt + few-shot examples + context + question), call GPT-4o-mini,
    and return the answer string.

    On any exception, returns a friendly error message instead of raising.
    """
    try:
        from langchain_core.messages import SystemMessage, HumanMessage, AIMessage

        from langchain_openai import ChatOpenAI as _ChatOpenAI
        if len(question.split()) < 10:
            correction_prompt = f"Fix any spelling mistakes in this sentence and return only the corrected sentence, nothing else: '{question}'"
            corrected = _ChatOpenAI(model="gpt-4o-mini", max_tokens=50, temperature=0, openai_api_key=os.environ["OPENAI_API_KEY"]).invoke(correction_prompt).content.strip()
            question = corrected

        vectorstore = _get_vectorstore()
        retriever = vectorstore.as_retriever(search_kwargs={"k": 2})
        docs = retriever.invoke(question)

        context_text = "\n\n---\n\n".join(
            f"[Source: {doc.metadata.get('source', 'unknown')}]\n{doc.page_content}"
            for doc in docs
        )

        llm = _get_llm()

        messages = [SystemMessage(content=_SYSTEM_PROMPT)]

        # Few-shot examples
        for example in _FEW_SHOT_EXAMPLES:
            messages.append(HumanMessage(content=example["human"]))
            messages.append(AIMessage(content=example["assistant"]))

        # Retrieved context + actual question
        user_content = (
            f"Relevant reference information:\n\n{context_text}\n\n"
            f"---\n\nPatient question: {question}"
        )
        messages.append(HumanMessage(content=user_content))

        response = llm.invoke(messages)
        return response.content

    except Exception as exc:
        return (
            "I'm sorry, I couldn't process your question right now. "
            "Please try again in a moment, or contact the clinic directly "
            f"through HayatiCare. (Error: {type(exc).__name__})"
        )


# ---------------------------------------------------------------------------
# Public function 3: ask_ai_stream
# ---------------------------------------------------------------------------
def ask_ai_stream(question: str):
    """
    Same pipeline as ask_ai() but yields text chunks as they arrive from the LLM.
    Yields strings. On error, yields a single friendly error string then stops.
    """
    try:
        from langchain_core.messages import SystemMessage, HumanMessage, AIMessage
        from langchain_openai import ChatOpenAI as _ChatOpenAI

        if len(question.split()) < 10:
            correction_prompt = (
                f"Fix any spelling mistakes in this sentence and return only "
                f"the corrected sentence, nothing else: '{question}'"
            )
            corrected = _ChatOpenAI(
                model="gpt-4o-mini", max_tokens=50, temperature=0,
                openai_api_key=os.environ["OPENAI_API_KEY"],
            ).invoke(correction_prompt).content.strip()
            question = corrected

        vectorstore = _get_vectorstore()
        retriever = vectorstore.as_retriever(search_kwargs={"k": 2})
        docs = retriever.invoke(question)

        context_text = "\n\n---\n\n".join(
            f"[Source: {doc.metadata.get('source', 'unknown')}]\n{doc.page_content}"
            for doc in docs
        )

        llm = _ChatOpenAI(
            model="gpt-4o-mini",
            temperature=0.3,
            max_tokens=300,
            streaming=True,
            openai_api_key=os.environ["OPENAI_API_KEY"],
        )

        messages = [SystemMessage(content=_SYSTEM_PROMPT)]
        for example in _FEW_SHOT_EXAMPLES:
            messages.append(HumanMessage(content=example["human"]))
            messages.append(AIMessage(content=example["assistant"]))

        user_content = (
            f"Relevant reference information:\n\n{context_text}\n\n"
            f"---\n\nPatient question: {question}"
        )
        messages.append(HumanMessage(content=user_content))

        for chunk in llm.stream(messages):
            text = chunk.content
            if text:
                yield text

    except Exception as exc:
        yield (
            "I'm sorry, I couldn't process your question right now. "
            "Please try again in a moment, or contact the clinic directly "
            f"through HayatiCare. (Error: {type(exc).__name__})"
        )
