import requests
import json

BASE_URL = "http://localhost:8000"  # Adjust if backend is running on a different port

def test_spi_login():
    print("Testing 'spi' login...")
    payload = {
        "username": "spi",
        "password": "12345"
    }
    try:
        response = requests.post(f"{BASE_URL}/auth/login", json=payload)
        
        if response.status_code == 200:
            data = response.json()
            print("Login successful!")
            # print(json.dumps(data, indent=2))
            
            assert data["username"] == "spi"
            assert data["privilege"] == "Admin"
            assert data["user_type"] == "CompanyEmployee"
            assert data["access_token"] is not None
            print("Verification passed: JWT token and user info received.")
            
            token = data["access_token"]
            test_protected_route(token)
        else:
            print(f"Login failed with status code: {response.status_code}")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"An error occurred: {e}")

def test_protected_route(token):
    print("\nTesting protected route access with 'spi' token...")
    headers = {
        "Authorization": f"Bearer {token}"
    }
    try:
        response = requests.get(f"{BASE_URL}/employees/company", headers=headers)
        if response.status_code == 200:
            print("Successfully accessed protected route!")
        else:
            print(f"Failed to access protected route: {response.status_code}")
            print(f"Response: {response.text}")
    except Exception as e:
        print(f"An error occurred during protected route test: {e}")

if __name__ == "__main__":
    # Note: Make sure the backend server is running before executing this test.
    test_spi_login()
