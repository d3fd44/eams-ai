import numpy as np
import pandas as pd

RECORDS_COUNT = 583746 # pretend that this is a magical number
OUTPUT_FILE = "data.csv"
EPSILON = 0.05  # How much the mean "wiggles" per sample

class LevelParser:
    """Translates 'L', 'M', 'H' into mathematical Mean and StdDev."""
    
    # Define the 0.0 - 1.0 boundaries for each level
    LEVEL_MAP = {
        'L':  (0.0, 0.2),
        'ML': (0.2, 0.4),
        'M':  (0.4, 0.6),
        'MH': (0.6, 0.8),
        'H':  (0.8, 1.0)
    }

    @staticmethod
    def get_stats(levels, scale=1.0):
        """
        Input: levels=['L', 'M'] (Range from Low to Medium, for Example)
        Output: (mean, std_dev) scaled to the feature
        """
        if isinstance(levels, str):
            levels = [levels] # Handle single level case like 'L'
            
        min_val = min(LevelParser.LEVEL_MAP[l][0] for l in levels)
        max_val = max(LevelParser.LEVEL_MAP[l][1] for l in levels)
        
        center = (min_val + max_val) / 2.0
        width = max_val - min_val
        
        # Range covers ~4 standard deviations (95% confidence)
        # We add a tiny buffer to std so it's not too sharp
        mean = center * scale
        std = (width / 4.0) * scale
        
        return mean, std

def generate_data(n_samples):
    data = []
    labels = []
    
    profiles = {
        'productive': {
            'focus_switch': ['L', 'M'],
            'idle':         ['L', 'ML'],
            'main_keys':    ['M', 'H'],
            'main_mouse':   ['M', 'H'],
            'helper_keys':  ['L', 'ML'],
            'helper_mouse': ['L', 'ML'],
            'ent_keys':     'L',
            'ent_mouse':    'L'
        },
        'active': {
            'focus_switch': ['ML', 'MH'],
            'idle':         ['ML', 'M'],
            'main_keys':    ['L', 'M'],
            'main_mouse':   ['L', 'M'],
            'helper_keys':  ['M', 'H'],
            'helper_mouse': ['M', 'H'],
            'ent_keys':     'L',
            'ent_mouse':    'L'
        },
        'fragmented': {
            'focus_switch': ['MH', 'H'],
            'idle':         'ML',
            'main_keys':    ['L', 'M'],
            'main_mouse':   ['L', 'M'],
            'helper_keys':  ['L', 'M'],
            'helper_mouse': ['L', 'M'],
            'ent_keys':     ['L', 'M'],
            'ent_mouse':    ['L', 'M']
        },
        'distracted': {
            'focus_switch': ['L', 'H'], # Huge range!
            'idle':         ['L', 'M'], # Huge range!
            'main_keys':    'L',
            'main_mouse':   'L',
            'helper_keys':  'L',
            'helper_mouse': 'L',
            'ent_keys':     ['M', 'H'],
            'ent_mouse':    ['M', 'H']
        },
        'idle': {
            'focus_switch': ['L', 'ML'],
            'idle':         'H',
            'main_keys':    'L',
            'main_mouse':   'L',
            'helper_keys':  'L',
            'helper_mouse': 'L',
            'ent_keys':     'L',
            'ent_mouse':    'L'
        }
    }

    statuses = list(profiles.keys())
    probs = [0.35, 0.20, 0.20, 0.15, 0.10] 

    for _ in range(n_samples):
        status = np.random.choice(statuses, p=probs)
        features = profiles[status]
        
        row_values = []
        
        
        def get_val(rule, scale=1.0):
            base_mean, base_std = LevelParser.get_stats(rule, scale)
            
            epsilon = np.random.uniform(-EPSILON, EPSILON) * scale
            shifted_mean = base_mean + epsilon
            
            val = np.random.normal(shifted_mean, base_std)
            
            if scale > 1: return int(max(0, val)) # For focus switch (0 to 20)
            return np.clip(val, 0.0, 1.0)

        row_values.append(get_val(features['focus_switch'], scale=20.0))
        row_values.append(get_val(features['idle']))
        row_values.append(get_val(features['main_keys']))
        row_values.append(get_val(features['main_mouse']))
        row_values.append(get_val(features['helper_keys']))
        row_values.append(get_val(features['helper_mouse']))
        row_values.append(get_val(features['ent_keys']))
        row_values.append(get_val(features['ent_mouse']))
        
        data.append(row_values)
        labels.append(status)

    cols = [
        "focus_switch_rate", "idle_time_percent",
        "main_keystrokes", "main_mouse_events",
        "helper_keystrokes", "helper_mouse_events",
        "entertain_keystrokes", "entertain_mouse_events"
    ]
    
    df = pd.DataFrame(data)
    df.columns=cols
    df['status'] = labels
    return df

df = generate_data(RECORDS_COUNT)
df.to_csv(OUTPUT_FILE, index=False)
print(f"Generated {len(df)} records using Logic Levels.")
print(df.groupby('status').mean()) # Check if the means match your intuition
