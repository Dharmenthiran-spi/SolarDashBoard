import base64
from typing import Optional

def decode_base64_image(v: Optional[str]) -> Optional[bytes]:
    """Helper to decode base64 string from frontend into bytes for backend storage."""
    if not v:
        return None
    if isinstance(v, str):
        if v.startswith('http'): # It's a URL, not base64
            return None
        try:
            # Handle data:image/png;base64,... prefixes
            if ',' in v:
                v = v.split(',')[-1]
            # Standardize padding if needed, but b64decode usually handles it
            return base64.b64decode(v)
        except Exception:
            # If it's not valid base64 and not empty, return None to avoid garbage in DB
            return None
    return v

def encode_binary_image(v: Optional[bytes]) -> Optional[str]:
    """Helper to encode binary data from database into base64 string for frontend display."""
    if not v:
        return None
    if isinstance(v, bytes):
        return base64.b64encode(v).decode('utf-8')
    return v
