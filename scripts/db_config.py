"""
Database configuration loader
Supports both .env file and dbConfig.json (for backward compatibility)
"""
import os
from pathlib import Path

def load_db_config():
    """
    Load database configuration from environment variables or dbConfig.json
    Priority: .env file > dbConfig.json
    """
    # Try to load from .env file first (most secure)
    try:
        from dotenv import load_dotenv
        
        # Look for .env in project root
        project_root = Path(__file__).parent.parent
        env_path = project_root / '.env'
        
        if env_path.exists():
            load_dotenv(env_path)
            
            # Check if all required env vars are set
            if all([
                os.getenv('DB_HOST'),
                os.getenv('DB_PORT'),
                os.getenv('DB_NAME'),
                os.getenv('DB_USER'),
                os.getenv('DB_PASSWORD')
            ]):
                return {
                    'host': os.getenv('DB_HOST'),
                    'port': int(os.getenv('DB_PORT')),
                    'database': os.getenv('DB_NAME'),
                    'user': os.getenv('DB_USER'),
                    'password': os.getenv('DB_PASSWORD')
                }
    except ImportError:
        pass  # python-dotenv not installed
    
    # Fallback to dbConfig.json (backward compatibility)
    try:
        import json
        config_path = Path(__file__).parent / 'dbConfig.json'
        
        if config_path.exists():
            with open(config_path, 'r') as f:
                return json.load(f)
    except Exception as e:
        pass
    
    # If nothing works, raise error
    raise FileNotFoundError(
        "Database configuration not found. Please create either:\n"
        "  1. .env file in project root (recommended for security), or\n"
        "  2. scripts/dbConfig.json file\n"
        "See env.example for template."
    )

