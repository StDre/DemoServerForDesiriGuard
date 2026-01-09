import socket
with open(r"msg.bin","rb") as f:
    data = f.read()
with socket.create_connection(("127.0.0.1",9000)) as s:
    s.sendall(data)
print("sent", len(data), "bytes")