"""
Pydantic schemas — define the shape of request bodies and responses.
FastAPI uses these to validate input and serialize output automatically.
"""

from pydantic import BaseModel, Field
from typing import Optional
from datetime import date


class TaskCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: str = Field(default="")
    due_date: date
    status: str = Field(default="To-Do")
    blocked_by_id: Optional[str] = None
    recurring_type: str = Field(default="None")


class TaskUpdate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: str = Field(default="")
    due_date: date
    status: str
    blocked_by_id: Optional[str] = None
    recurring_type: str = Field(default="None")


class TaskOut(BaseModel):
    id: str
    title: str
    description: str
    due_date: str        # ISO date string — easiest for Flutter to parse
    status: str
    blocked_by_id: Optional[str]
    recurring_type: str
    sort_order: int
    created_at: str

    class Config:
        from_attributes = True


class ReorderPayload(BaseModel):
    ordered_ids: list[str]
