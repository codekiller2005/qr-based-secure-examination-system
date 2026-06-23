from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from datetime import datetime
class ViolationCreate(BaseModel):
    """
    Schema for registering a single violation event.
    """
    student_exam_id: str = Field(..., description="ID of the student's exam session")
    violation_type: str = Field(..., description="Type of violation (e.g. SCREENSHOT, INTERNET_ON)")
    timestamp: datetime = Field(..., description="Event timestamp captured by client clock")
    details: Optional[str] = Field(None, description="Detailed context or parameter description")
    chain_index: int = Field(..., description="Cryptographical block sequence index")
    hash_value: str = Field(..., description="Chain hash signature verifying sequence integrity")
class ViolationSyncRequest(BaseModel):
    """
    Schema for bulk syncing offline violations.
    """
    student_exam_id: str = Field(..., description="ID of the student's exam session")
    violations: List[ViolationCreate] = Field(..., description="List of offline violations to synchronize")
class ViolationResponse(BaseModel):
    """
    Schema representing registered violation event logs.
    """
    id: str
    student_exam_id: str
    violation_type: str
    timestamp: datetime
    details: Optional[str]
    chain_index: int
    hash_value: str
    created_at: datetime
    model_config = {
        "from_attributes": True
    }
class ViolationSummaryItem(BaseModel):
    """
    Summary counts of registered violations grouped by event types.
    """
    total_violations: int
    by_type: Dict[str, int] = Field(default_factory=dict)
class StudentViolationReport(BaseModel):
    """
    Comprehensive violation history report for a single student.
    """
    student_id: str
    username: str
    email: str
    exam_id: str
    exam_title: str
    student_exam_status: str
    violation_count: int
    violations: List[ViolationResponse]
class ExamViolationReport(BaseModel):
    """
    Audit report aggregating all security alerts flagged for a specific exam.
    """
    exam_id: str
    exam_title: str
    total_students_registered: int
    total_flagged_students: int
    total_violations: int
    violation_counts_by_type: Dict[str, int]
    flagged_student_list: List[Dict[str, str]] # List containing student summary info
