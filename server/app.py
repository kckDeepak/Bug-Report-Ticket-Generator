from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import json
import mysql.connector
from dotenv import load_dotenv
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.output_parsers import JsonOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnablePassthrough

# --- Bug Ticket Schema ---
ticket_schema = {
    "title": "short, clear title of the issue",
    "description": "1-2 lines summarizing the bug",
    "steps": "step by step guide to reproduce the issue, provided as a list or string"
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

# Updated Prompt with explicit instructions for steps
prompt = ChatPromptTemplate.from_template("""
You are a bug ticket generator. Convert this messy bug report into a clean ticket in JSON format.
Ensure the output includes a 'steps' field with clear steps to reproduce the issue, even if the input is vague.
If no specific steps are provided, infer reasonable steps based on the bug description.

{format_instructions}

Raw bug: "{bug}"
""").partial(format_instructions=parser.get_format_instructions())

# Chain with parser
chain = prompt | llm | parser

# Flask app
app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})  # Allow all origins for development

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
        # Use LangChain to process the bug report
        ticket = chain.invoke({"bug": raw_bug})
        print(f"LLM Output: {ticket}")  # Debug: Log raw LLM output
    except Exception as e:
        print(f"Error invoking LangChain: {e}")
        # Fallback in case the LangChain call fails
        ticket = {
            "title": "Unknown issue",
            "description": raw_bug,
            "steps": "Could not generate steps due to processing error"
        }

    # Ensure all keys exist in the ticket dictionary
    ticket_title = ticket.get("title", "Unknown issue")
    ticket_description = ticket.get("description", raw_bug)
    
    # Handle steps field robustly
    ticket_steps_raw = ticket.get("steps", ticket.get("steps_to_reproduce", None))
    if ticket_steps_raw is None or ticket_steps_raw == "":
        # Fallback if steps are null or empty
        ticket_steps = "No specific steps provided; please verify the issue manually."
    elif isinstance(ticket_steps_raw, list):
        # Join list of steps into a single string
        ticket_steps = "\n".join(str(step) for step in ticket_steps_raw if step)
    else:
        # Use steps as-is if it's a string
        ticket_steps = str(ticket_steps_raw)

    # Save to DB
    cursor.execute(
        "INSERT INTO tickets (title, description, steps) VALUES (%s, %s, %s)",
        (ticket_title, ticket_description, ticket_steps)
    )
    db.commit()

    # Return the ticket with the processed steps
    return jsonify({
        "message": "Ticket created successfully",
        "ticket": {
            "title": ticket_title,
            "description": ticket_description,
            "steps": ticket_steps
        }
    })

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