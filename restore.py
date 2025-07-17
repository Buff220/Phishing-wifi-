import os

with open("restore.txt", "r") as f:
    for line in f:
        line = line.strip()
        if line:  # avoid empty lines
            print(f"[+] Executing: {line}")
            read=os.popen(line).read()
            print(read)
