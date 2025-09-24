# Bug Report to Ticket Generator

## Overview
The **Bug Report to Ticket Generator** is an agent-based web and mobile application that transforms messy, unstructured bug reports into clean, structured tickets. Using AI (powered by Google's Gemini LLM via LangChain), it generates fields like title, description, and steps to reproduce, then saves them to a MySQL database. The frontend is built with Flutter for cross-platform support (iOS, Android, web, desktop), allowing users to submit bugs, view tickets, and monitor dashboards. Ideal for development teams to streamline bug tracking and improve issue resolution efficiency.

## Features
- **AI-Powered Ticket Generation**: Convert raw bug descriptions (e.g., "checkout button not working on iPhone") into structured tickets with title, description, and reproducible steps.
- **Database Storage**: Save generated tickets in MySQL with timestamps for easy retrieval and history.
- **Cross-Platform Frontend**: Flutter app supporting mobile (iOS/Android), web, and desktop (Linux/macOS/Windows).
- **User Interfaces**:
  - Home screen for navigation.
  - Submit bug screen to input raw bugs and generate tickets.
  - View tickets screen to list all saved tickets.
  - Dashboard for overview stats (total tickets, open bugs, resolved, high priority) and recent activity.
  - Ticket detail screen for in-depth views.
- **Error Handling and Debugging**: Robust handling for API errors, loading states, and timestamp parsing.
- **Refresh and Real-Time Feel**: Pull-to-refresh and manual refresh for updating ticket lists.

## Prerequisites
- **Python 3.8+** for the backend.
- **Flutter 3.0+** and **Dart** for the frontend.
- **MySQL Server** for the database.
- **Google API Key** for Gemini LLM (via LangChain).
- A `.env` file for environment variables (API keys, database credentials, base URL).

## Installation

### Backend Setup
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd bug-report-ticket-generator/server
   ```
2. Create a virtual environment and activate it:
   ```bash
   python -m venv my_env
   source my_env/bin/activate  # On Unix/macOS
   # or
   my_env\Scripts\activate  # On Windows
   ```
3. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Create a `.env` file in the `server` directory with the following content:
   ```
   GEMINI_API_KEY=your_gemini_api_key
   DB_HOST=localhost
   DB_USER=your_db_user
   DB_PASSWORD=your_db_password
   DB_NAME=bug_tickets_db
   ```
5. Start the MySQL server and ensure the database is created (the app will handle table creation).
6. Run the Flask server:
   ```bash
   python app.py
   ```

### Frontend Setup
1. Navigate to the `client/bug_report_ticket_generator` directory:
   ```bash
   cd ../client/bug_report_ticket_generator
   ```
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Create a `.env` file in the root of the client directory:
   ```
   BASE_URL=http://localhost:5000
   ```
4. Run the Flutter app:
   - For web: `flutter run -d chrome`
   - For Android/iOS: Connect a device/emulator and run `flutter run`
   - For desktop: `flutter run -d <linux/macos/windows>`

## Usage
1. Start the backend server (`python app.py`).
2. Launch the Flutter app.
3. From the home screen:
   - Navigate to "Submit New Bug Report" to enter a raw bug description and generate a ticket.
   - View generated tickets in "View All Tickets" or check stats in "Dashboard".
4. Tickets are automatically saved to the database and can be viewed with details like creation time.

Example:
- Raw Input: "checkout button not working on iPhone"
- Generated Ticket:
  - Title: Checkout button broken on iPhone
  - Description: The checkout button fails to respond when tapped on iPhone devices.
  - Steps: 1. Open the app. 2. Add an item to the cart. 3. Tap the checkout button → nothing happens.

## Project Structure
```
bug-report-ticket-generator/
├── client/
│   └── bug_report_ticket_generator/
│       ├── android/
│       ├── build/
│       ├── ios/
│       ├── lib/
│       │   ├── screens/
│       │   │   ├── dashboard_screen.dart
│       │   │   ├── home_screen.dart
│       │   │   ├── submit_bug_screen.dart
│       │   │   ├── ticket_detail_screen.dart
│       │   │   └── view_tickets_screen.dart
│       │   └── main.dart
│       ├── linux/
│       ├── macos/
│       ├── test/
│       ├── web/
│       ├── windows/
│       ├── .env
│       ├── .gitignore
│       ├── .metadata
│       ├── analysis_options.yaml
│       └── pubspec.yaml
├── server/
│   ├── my_env/  # Virtual environment (git ignored)
│   ├── .env
│   ├── .gitignore
│   ├── app.py
│   └── requirements.txt
└── README.md
```

## Technologies Used
- **Backend**: Python, Flask, LangChain, Google Gemini LLM, MySQL Connector.
- **Frontend**: Flutter, Dart, Material Design, HTTP (for API calls).
- **Other**: DotEnv for environment variables, JSON parsing for API responses.

## Contributing
Contributions are welcome! Please fork the repository, create a feature branch, and submit a pull request. Ensure your code follows the existing style, add tests where possible, and update documentation.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact
- **Email:** [kckdeepak29@gmail.com](mailto:kckdeepak29@gmail.com)
- **GitHub Issues**