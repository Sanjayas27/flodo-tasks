"""
Flodo Tasks — FastAPI Backend
Run with: uvicorn main:app --reload --host 0.0.0.0 --port 8000
"""

import asyncio
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional
import database
import schemas

app = FastAPI(title="Flodo Tasks API", version="1.0.0")

# Allow Flutter app (any origin during development) to talk to this server
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup():
    """Initialize the SQLite database on first run."""
    database.init_db()


# ─────────────────────────────────────────────
# TASKS ENDPOINTS
# ─────────────────────────────────────────────

@app.get("/tasks", response_model=list[schemas.TaskOut], summary="Get all tasks")
async def get_tasks(
    status: Optional[str] = Query(None, description="Filter by status label"),
    search: Optional[str] = Query(None, description="Search by title (case-insensitive)"),
):
    """Return all tasks, with optional status filter and title search."""
    tasks = database.get_all_tasks(status=status, search=search)
    return tasks


@app.get("/tasks/{task_id}", response_model=schemas.TaskOut, summary="Get a single task")
async def get_task(task_id: str):
    task = database.get_task_by_id(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@app.post("/tasks", response_model=schemas.TaskOut, status_code=201, summary="Create a task")
async def create_task(payload: schemas.TaskCreate):
    """Create a new task. Simulates a 2-second processing delay."""
    await asyncio.sleep(2)  # Simulated delay — UI must handle loading state
    task = database.create_task(payload)
    return task


@app.put("/tasks/{task_id}", response_model=schemas.TaskOut, summary="Update a task")
async def update_task(task_id: str, payload: schemas.TaskUpdate):
    """Update an existing task. Simulates a 2-second processing delay."""
    existing = database.get_task_by_id(task_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Task not found")

    await asyncio.sleep(2)  # Simulated delay

    updated = database.update_task(task_id, payload)

    # Recurring logic: if task just became Done and is recurring, spawn next
    if payload.status == "Done" and existing["status"] != "Done" and existing["recurring_type"] != "None":
        database.spawn_next_recurring(updated)

    return updated


@app.delete("/tasks/{task_id}", status_code=204, summary="Delete a task")
async def delete_task(task_id: str):
    """Delete a task. Also clears it as a blocker from other tasks."""
    existing = database.get_task_by_id(task_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Task not found")
    database.delete_task(task_id)


@app.patch("/tasks/reorder", status_code=204, summary="Reorder tasks (drag-and-drop)")
async def reorder_tasks(payload: schemas.ReorderPayload):
    """Accepts an ordered list of task IDs and updates their sort_order."""
    database.update_sort_orders(payload.ordered_ids)
