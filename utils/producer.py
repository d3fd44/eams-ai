from confluent_kafka import Producer

p = Producer({'bootstrap.servers': 'localhost:9092'})

def delivery_report(err, msg):
    if err is not None:
        print(f"Message delivery failed: {err}")
    else:
        print(f"Message delivered to {msg.topic()} [{msg.partition()}]: {msg}")

# Send a simple key-value event
p.produce('rawlogs', key=b'id_123', value=b'This Is Message 1 By Momen From a Python Script as a Producer', callback=delivery_report)
p.produce('rawlogs', key=b'id_123', value=b'This Is Message 2 By Momen From a Python Script as a Producer', callback=delivery_report)
p.produce('rawlogs', key=b'id_123', value=b'This Is Message 3 By Momen From a Python Script as a Producer', callback=delivery_report)
p.produce('rawlogs', key=b'id_123', value=b'This Is Message 4 By Momen From a Python Script as a Producer', callback=delivery_report)
p.flush()
