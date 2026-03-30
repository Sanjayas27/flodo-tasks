# Flodo Tasks — Flutter Task Management App

> Flutter + FastAPI + SQLite · Track A submission for Flodo AI take-home assignment

---

## Track & Stretch Goal

|                  |                                                           |
| ---------------- | --------------------------------------------------------- |
| **Track**        | A — Full Stack Builder                                    |
| **Backend**      | Python 3.14 · FastAPI · SQLite                            |
| **Frontend**     | Flutter (Dart)                                            |
| **Stretch Goal** | Debounced Autocomplete Search with highlighted match text |
| **Bonus**        | Recurring Tasks Logic + Persistent Drag-and-Drop          |

---

## Demo Video

[Google Drive Link](https://drive.google.com/file/d/19ynEDNj0ctC9Mu4SxT_jh9wmdO6mQHpo/view?usp=sharing)

---

## Features

### Core Requirements

- Task model with Title, Description, Due Date, Status, Blocked By
- Blocked tasks are greyed out with lock icon until blocker is marked Done
- Full CRUD — Create, Read, Update, Delete
- Draft saving — text auto saved to SharedPreferences on every keystroke
- Debounced search — 300ms timer, matched text highlighted in amber
- Status filter chips — To-Do, In Progress, Done
- 2 second delay on Create and Update with spinner and disabled button

### Stretch Goal — Debounced Autocomplete Search

- 300ms debounce using dart:async Timer
- Matched text highlighted in amber inside task cards

### Bonus Features

- Recurring Tasks — Daily or Weekly auto repeat when marked Done
- Drag and Drop — reorder tasks, order saved to database

---

## Setup Instructions

### Prerequisites

- Python 3.10 or higher
- Flutter SDK 3.0 or higher
- Android device or emulator

### Step 1 — Start the Backend

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# Mac or Linux
source venv/bin/activate

pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Backend runs at http://localhost:8000
API docs at http://localhost:8000/docs

### Step 2 — Configure Flutter App

Open `lib/services/api_service.dart` and set your IP address:

```dart
// Android Emulator
static const String baseUrl = 'http://10.0.2.2:8000';

// Physical device — use your PC local IP
static const String baseUrl = 'http://192.168.1.100:8000';
```

### Step 3 — Run Flutter App

```bash
flutter pub get
flutter run
```

---

## Project Structure

```
├── backend/
│   ├── main.py          — FastAPI routes
│   ├── database.py      — SQLite operations
│   ├── schemas.py       — Pydantic models
│   └── requirements.txt
│
└── lib/
    ├── main.dart
    ├── models/
    │   └── task.dart
    ├── services/
    │   └── api_service.dart
    ├── providers/
    │   └── task_provider.dart
    ├── screens/
    │   ├── home_screen.dart
    │   └── task_form_screen.dart
    ├── widgets/
    │   ├── task_card.dart
    │   └── highlighted_text.dart
    └── theme/
        └── app_theme.dart
```

---

## Technical Decisions

### 1. FastAPI with asyncio.sleep for non-blocking delay

Used asyncio.sleep(2) instead of time.sleep(2) so the server
remains responsive to other requests during the simulated delay.

### 2. Client side debounce with dart:async Timer

No extra package needed. Each keystroke cancels the previous
timer and starts a fresh 300ms countdown. Provider is only
notified after user stops typing.

### 3. Optimistic delete

Task is removed from UI immediately before HTTP call completes.
If server returns error, task is restored. Makes app feel instant.

### 4. Draft saving per keystroke

TextEditingController listener calls saveDraft on every change.
Written as fire and forget so it never blocks the UI thread.

---

## AI Usage Report

Claude was used throughout this project.

### Most useful prompts

- Designing the FastAPI endpoints with non-blocking asyncio delay
- Writing the HighlightedText Flutter widget using RichText and TextSpan
- Implementing debounce pattern using dart:async Timer

### Where AI needed correction

- AI suggested localhost for Android emulator — corrected to 10.0.2.2
- AI used deprecated WillPopScope — corrected to PopScope
- AI generated reorder logic had index mapping bug when list was filtered
- AI initially used pydantic version incompatible with Python 3.14 — updated requirements.txt

---

## Repository

https://github.com/Sanjayas27/flodo-tasks

```

---




```
