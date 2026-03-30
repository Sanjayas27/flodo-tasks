"""
Database layer — all SQLite operations using Python's built-in sqlite3.
No ORM needed for this scale; raw SQL keeps it transparent and fast.
"""

import sqlite3
import uuid
from datetime import date, timedelta
from typing import Optional
import schemas

DB_PATH = "flodo_tasks.db"


def get_connection() -> sqlite3.Connection:
    """Return a connection with Row factory so rows act like dicts."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db():
    """Create tables if they don't exist yet."""
    with get_connection() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS tasks (
                id             TEXT PRIMARY KEY,
                title          TEXT NOT NULL,
                description    TEXT NOT NULL DEFAULT '',
                due_date       TEXT NOT NULL,
                status         TEXT NOT NULL DEFAULT 'To-Do',
                blocked_by_id  TEXT,
                recurring_type TEXT NOT NULL DEFAULT 'None',
                sort_order     INTEGER NOT NULL DEFAULT 0,
                created_at     TEXT NOT NULL
            )
        """)
        conn.commit()


# ─────────────────────────────────────────────
# READ
# ─────────────────────────────────────────────

def get_all_tasks(status: Optional[str] = None, search: Optional[str] = None) -> list[dict]:
    with get_connection() as conn:
        query = "SELECT * FROM tasks WHERE 1=1"
        params: list = []

        if status:
            query += " AND status = ?"
            params.append(status)

        if search:
            # Case-insensitive title search using LIKE
            query += " AND LOWER(title) LIKE ?"
            params.append(f"%{search.lower()}%")

        query += " ORDER BY sort_order ASC, created_at ASC"
        rows = conn.execute(query, params).fetchall()
        return [dict(row) for row in rows]


def get_task_by_id(task_id: str) -> Optional[dict]:
    with get_connection() as conn:
        row = conn.execute(
            "SELECT * FROM tasks WHERE id = ?", (task_id,)
        ).fetchone()
        return dict(row) if row else None


# ─────────────────────────────────────────────
# CREATE / UPDATE / DELETE
# ─────────────────────────────────────────────

def create_task(payload: schemas.TaskCreate) -> dict:
    task_id = str(uuid.uuid4())
    created_at = date.today().isoformat()

    # Count existing tasks to set initial sort order
    with get_connection() as conn:
        count = conn.execute("SELECT COUNT(*) FROM tasks").fetchone()[0]
        conn.execute("""
            INSERT INTO tasks
                (id, title, description, due_date, status, blocked_by_id, recurring_type, sort_order, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            task_id,
            payload.title,
            payload.description,
            payload.due_date.isoformat(),
            payload.status,
            payload.blocked_by_id,
            payload.recurring_type,
            count,
            created_at,
        ))
        conn.commit()

    return get_task_by_id(task_id)


def update_task(task_id: str, payload: schemas.TaskUpdate) -> dict:
    with get_connection() as conn:
        conn.execute("""
            UPDATE tasks SET
                title          = ?,
                description    = ?,
                due_date       = ?,
                status         = ?,
                blocked_by_id  = ?,
                recurring_type = ?
            WHERE id = ?
        """, (
            payload.title,
            payload.description,
            payload.due_date.isoformat(),
            payload.status,
            payload.blocked_by_id,
            payload.recurring_type,
            task_id,
        ))
        conn.commit()
    return get_task_by_id(task_id)


def delete_task(task_id: str):
    with get_connection() as conn:
        # Clear this task as a blocker from all other tasks
        conn.execute(
            "UPDATE tasks SET blocked_by_id = NULL WHERE blocked_by_id = ?",
            (task_id,)
        )
        conn.execute("DELETE FROM tasks WHERE id = ?", (task_id,))
        conn.commit()


def update_sort_orders(ordered_ids: list[str]):
    with get_connection() as conn:
        for i, task_id in enumerate(ordered_ids):
            conn.execute(
                "UPDATE tasks SET sort_order = ? WHERE id = ?", (i, task_id)
            )
        conn.commit()


# ─────────────────────────────────────────────
# RECURRING LOGIC
# ─────────────────────────────────────────────

def spawn_next_recurring(completed_task: dict):
    """When a recurring task is marked Done, create a fresh copy with incremented due date."""
    old_due = date.fromisoformat(completed_task["due_date"])

    if completed_task["recurring_type"] == "Daily":
        next_due = old_due + timedelta(days=1)
    elif completed_task["recurring_type"] == "Weekly":
        next_due = old_due + timedelta(weeks=1)
    else:
        return  # Not recurring

    payload = schemas.TaskCreate(
        title=completed_task["title"],
        description=completed_task["description"],
        due_date=next_due,
        status="To-Do",
        blocked_by_id=None,  # New instance starts unblocked
        recurring_type=completed_task["recurring_type"],
    )
    create_task(payload)
