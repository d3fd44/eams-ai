import numpy as np
import pandas as pd

RECORDS_COUNT = 1
OUTPUT_FILE = "data.csv"

def generate_data(n_samples):
    data = []
    labels = []
    
    statuses = ['productive', 'active', 'fragmented', 'distracted', 'idle']
    probs =    [0.35,         0.20,     0.20,         0.15,         0.10]

    for _ in range(n_samples):
        status = np.random.choice(statuses, p=probs)
        
        focus_switch = 5.0
        overall_idle = 0.1
        
        main_keys, main_mouse = 0.2, 0.2
        helper_keys, helper_mouse = 0.1, 0.1
        entertain_keys, entertain_mouse = 0.05, 0.05

        if status == 'productive':
            focus_switch = np.random.normal(4, 2)
            overall_idle = np.random.normal(0.05, 0.02)
            main_keys = np.random.normal(0.8, 0.15) 
            main_mouse = np.random.normal(0.5, 0.2)
            
        elif status == 'active':
            focus_switch = np.random.normal(8, 3)
            overall_idle = np.random.normal(0.1, 0.05)
            main_keys = np.random.normal(0.15, 0.1)
            helper_mouse = np.random.normal(0.7, 0.15)
            helper_keys = np.random.normal(0.2, 0.1)
            
        elif status == 'fragmented':
            focus_switch = np.random.normal(35, 10) 
            overall_idle = np.random.normal(0.02, 0.02)
            main_keys = np.random.normal(0.4, 0.2)
            entertain_keys = np.random.normal(0.2, 0.15)
            
        elif status == 'distracted':
            focus_switch = np.random.normal(10, 5)
            overall_idle = np.random.normal(0.05, 0.05)
            main_keys = np.random.normal(0.05, 0.05)
            entertain_keys = np.random.normal(0.75, 0.2)
            entertain_mouse = np.random.normal(0.7, 0.2)
            
        elif status == 'idle':
            focus_switch = np.random.normal(0, 0.5)
            overall_idle = np.random.normal(0.95, 0.05)
            main_keys, main_mouse = 0.0, 0.0
            helper_keys, helper_mouse = 0.0, 0.0
            entertain_keys, entertain_mouse = 0.0, 0.0

        raw_row = [
            focus_switch,
            overall_idle,
            main_keys, main_mouse,
            helper_keys, helper_mouse,
            entertain_keys, entertain_mouse
        ]
        
        processed_row = []
        for i, val in enumerate(raw_row):
            val += np.random.normal(0, 0.01) # Small noise
            
            if i == 0:
                val = int(max(0, val))
            else:
                val = np.clip(val, 0.0, 1.0)
            
            processed_row.append(val)
            print(type(val))
            
        data.append(processed_row)
        labels.append(status)

    final_cols = [
        "focus_switch_rate", "overall_idle_percent",
        "main_keystrokes", "main_mouse_events",
        "helper_keystrokes", "helper_mouse_events",
        "entertain_keystrokes", "entertain_mouse_events"
    ]
    
    df = pd.DataFrame(data)
    df.columns = final_cols
    df['status'] = labels 
    
    return df

df = generate_data(RECORDS_COUNT)
df = df.sample(frac=1).reset_index(drop=True)
df.to_csv(OUTPUT_FILE, index=False)

df.info()
print(f"Generated {len(df)} rows with {len(df.columns)} columns.")
print(df.head())
