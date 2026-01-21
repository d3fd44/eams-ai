from flask import Flask, request, jsonify
import xgboost as xgb
import numpy as np
import os
import json
import threading
from kafka import KafkaConsumer, KafkaProducer

app = Flask(__name__)

MODEL_PATH = "./xgb3.json"
INPUT_TOPIC = "chunks"
OUTPUT_TOPIC = "statuses"
KAFKA_BROKER = os.environ.get('KAFKA_BROKER', 'localhost:9092') 

FEATURE_NAMES = [
    "focus_switch_rate", "idle_time_percent", "main_keystrokes", 
    "main_mouse_events", "helper_keystrokes", "helper_mouse_events", 
    "entertain_keystrokes", "entertain_mouse_events"
]

STATUS_MAP = {
    0: 'active', 1: 'distracted', 2: 'fragmented', 
    3: 'idle', 4: 'productive'
}

print(f"Loading XGBoost model...")
model = None
try:
    if os.path.exists(MODEL_PATH):
        model = xgb.Booster()
        model.load_model(MODEL_PATH)
        print("Model loaded successfully!")
    else:
        print(f"Error: Model file '{MODEL_PATH}' not found.")
except Exception as e:
    print(f"Failed to load model: {e}")

def get_prediction(features):
    if not model:
        raise Exception("Model not loaded")

    input_data = np.array(features)
    
    if input_data.ndim == 1:
        input_data = input_data.reshape(1, -1)

    if input_data.shape[1] != len(FEATURE_NAMES):
        raise Exception(f"Expected {len(FEATURE_NAMES)} features, got {input_data.shape[1]}")

    dmatrix = xgb.DMatrix(input_data, feature_names=FEATURE_NAMES)
    prediction_raw = model.predict(dmatrix)
    
    pred_id = int(prediction_raw[0])
    return pred_id, STATUS_MAP.get(pred_id, "unknown")

def consume_kafka():
    print(f"Starting Kafka Consumer for topic: {INPUT_TOPIC}")
    
    try:
        producer = KafkaProducer(
            bootstrap_servers=[KAFKA_BROKER],
            value_serializer=lambda x: json.dumps(x).encode('utf-8')
        )

        consumer = KafkaConsumer(
            INPUT_TOPIC,
            bootstrap_servers=[KAFKA_BROKER],
            auto_offset_reset='latest',
            enable_auto_commit=True,
            group_id='flask-prediction-group',
            value_deserializer=lambda x: json.loads(x.decode('utf-8'))
        )
        
        print(f"Kafka Connected! Reading from '{INPUT_TOPIC}', Writing to '{OUTPUT_TOPIC}'")

        for message in consumer:
            try:
                data = message.value
                emp_id = data.get('emp_id')
                features = data.get('features')

                if features:
                    pred_id, label = get_prediction(features)
                    
                    output_message = {
                        "emp_id": emp_id,
                        "status": label,
                        "status_id": pred_id
                    }

                    producer.send(OUTPUT_TOPIC, value=output_message, key=b'FAAHHH')
                    
                    print(f"Produced to '{OUTPUT_TOPIC}': {output_message}")
                else:
                    print(f"Message received without 'features': {data}")

            except Exception as inner_e:
                print(f"Error processing message: {inner_e}")

    except Exception as e:
        print(f"Kafka Error: {e}")


@app.route('/predict', methods=['POST'])
def predict_endpoint():
    try:
        content = request.get_json(force=True, silent=True)
        if not content or 'features' not in content:
            return jsonify({"error": "Missing 'features'"}), 400
        
        pred_id, label = get_prediction(content['features'])
        
        return jsonify({"status_id": pred_id, "status": label})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    kafka_thread = threading.Thread(target=consume_kafka, daemon=True)
    kafka_thread.start()

    app.run(host='0.0.0.0', port=5000)
