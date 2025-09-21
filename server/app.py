import os
import json
import mysql.connector
from flask import Flask, request, jsonify
from dotenv import load_dotenv

# LangChain + Gemini
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.output_parsers import JsonOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnablePassthrough

# --- Bug Ticket Schema ---
# We define a structured schema that the LLM will follow.
# This ensures a consistent JSON output.
ticket_schema = {
    "title": "short, clear title of the issue",
    "description": "1-2 lines summarizing the bug",
    "steps": "step by step guide to reproduce the issue"
}

# Parser
parser = JsonOutputParser(pydantic_object=None, json_object=ticket_schema)

# Load env
load_dotenv()

# Gemini LLM via LangChain
llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-flash", 
    google_api_key=os.getenv("GEMINI_API_KEY")
)

# Prompt with format instructions
prompt = ChatPromptTemplate.from_template("""
You are a bug ticket generator.
Convert this messy bug report into a clean ticket.

{format_instructions}

Raw bug: "{bug}"
""").partial(format_instructions=parser.get_format_instructions())

# Chain with parser
chain = prompt | llm | parser

# Flask app
app = Flask(__name__)

# MySQL connection
try:
    db = mysql.connector.connect(
        host=os.getenv("DB_HOST"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME")
    )
    cursor = db.cursor()
    print("Successfully connected to the MySQL database.")
except mysql.connector.Error as err:
    print(f"Error connecting to MySQL: {err}")
    db = None
    cursor = None

# Ensure table exists
if cursor:
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS tickets (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(255),
        description TEXT,
        steps TEXT
    )
    """)
    db.commit()
    print("Table 'tickets' checked/created.")

@app.route("/create_ticket", methods=["POST"])
def create_ticket():
    if not db or not cursor:
        return jsonify({"error": "Database connection not available"}), 500

    data = request.get_json()
    raw_bug = data.get("bug")

    if not raw_bug:
        return jsonify({"error": "Bug text is required"}), 400

    try:
        # Use LangChain to process the bug report. The parser will automatically
        # convert the LLM's JSON output into a Python dictionary.
        ticket = chain.invoke({"bug": raw_bug})
    except Exception as e:
        print(f"Error invoking LangChain: {e}")
        # Fallback in case the LangChain call fails or returns malformed data
        ticket = {
            "title": "Unknown issue",
            "description": raw_bug,
            "steps": "Not provided"
        }

    # Ensure all keys exist in the ticket dictionary before saving
    ticket_title = ticket.get("title", "Unknown issue")
    ticket_description = ticket.get("description", raw_bug)
    
    # Handle both 'steps' and 'steps_to_reproduce' from the LLM's output
    ticket_steps_raw = ticket.get("steps", ticket.get("steps_to_reproduce", "Not provided"))
    if isinstance(ticket_steps_raw, list):
        # Join the list of steps into a single string for the database
        ticket_steps = "\n".join(ticket_steps_raw)
    else:
        ticket_steps = ticket_steps_raw

    # Save to DB
    cursor.execute(
        "INSERT INTO tickets (title, description, steps) VALUES (%s, %s, %s)",
        (ticket_title, ticket_description, ticket_steps)
    )
    db.commit()

    return jsonify({"message": "Ticket created successfully", "ticket": ticket})

@app.route("/tickets", methods=["GET"])
def get_tickets():
    if not db or not cursor:
        return jsonify({"error": "Database connection not available"}), 500
        
    cursor.execute("SELECT * FROM tickets")
    rows = cursor.fetchall()

    tickets = []
    for row in rows:
        tickets.append({
            "id": row[0],
            "title": row[1],
            "description": row[2],
            "steps": row[3]
        })

    return jsonify(tickets)

if __name__ == "__main__":
    app.run(debug=True)
