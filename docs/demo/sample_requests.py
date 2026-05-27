import urllib.request

for i in range(1, 11):
    with urllib.request.urlopen('http://localhost:8080/') as response:
        body = response.read().decode('utf-8', errors='replace')
    served = [line for line in body.splitlines() if line.startswith('Served by')]
    print(f'REQUEST {i}: {served[0] if served else "NO HOST"}')
