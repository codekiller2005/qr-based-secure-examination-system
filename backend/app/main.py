import time
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.routes.auth import router as auth_router
from app.routes.admin import router as admin_router
from app.routes.invigilator import router as invigilator_router
from app.routes.student import router as student_router
from app.routes.qr import router as qr_router
from app.routes.violation import router as violations_router
# Initialize FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    description="Backend API for QR-Based Secure Offline Examination System with Airplane Mode validation.",
    version="0.1.0",
    debug=settings.DEBUG
)
app.add_middleware(
    CORSMiddleware,
   
    
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth_router, prefix="/api/v1")
app.include_router(admin_router, prefix="/api/v1")
app.include_router(invigilator_router, prefix="/api/v1")
app.include_router(student_router, prefix="/api/v1")
app.include_router(qr_router, prefix="/api/v1")
app.include_router(violations_router, prefix="/api/v1")
@app.get("/health", tags=["System"])
async def health_check():
    """
    Standard service health verification endpoint.
    Used by load balancers, orchestrators, and monitoring agents.
    
    Returns:
        JSON response with service status, active running environment, and UNIX timestamp.
    """
    return {
        "status": "healthy",
        "app_name": settings.APP_NAME,
        "environment": settings.APP_ENV,
        "timestamp": int(time.time())
    }
if __name__ == "__main__":
    import uvicorn
    # Allow running the API directly using `python app/main.py`
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=settings.DEBUG)
 