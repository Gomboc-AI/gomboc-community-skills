import requests

def fetch_data(url):
    response = requests.get(url, verify=True)
    return response.json()

def post_data(url, payload):
    response = requests.post(url, json=payload, verify=True)
    return response.status_code
