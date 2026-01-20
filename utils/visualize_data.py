import random
import numpy as np
import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
import os

file_path = "./final-data/data.csv"
if not os.path.exists(file_path):
    raise FileNotFoundError(f"Could not find {file_path}. Are you in the right folder?")

df = pd.read_csv(file_path)

# # CRITICAL FIX: If data is huge (like 500k rows), we MUST sample it.
# # Visualizing 500k points creates a blob and crashes memory. 
# # 3000 points is enough to see the perfect distribution patterns.
if len(df) > 3000:
    print(f"Dataset is large ({len(df)} rows). Sampling 3000 rows for clean visualization...")
    plot_df = df.sample(3000, random_state=42)
else:
    plot_df = df

output_dir = "./final-data"
os.makedirs(output_dir, exist_ok=True)

# --- 2. Styling (Make it Pretty) ---
# 'context="talk"' scales fonts up for presentations/papers
# 'style="ticks"' looks cleaner than grids for scatterplots
sns.set_theme(context="notebook", style="whitegrid", font_scale=1.1)
custom_palette = "bright" # 'husl', 'deep', 'bright', or 'viridis'

# --- 3. Plot 1: Key Features Pairplot ---
# Renamed from "hero_features". These are selected because 
# they mathematically define your profiles best.
key_features = [
    "main_keystrokes",      # Separates Productive
    "focus_switch_rate",    # Separates Fragmented
    "entertain_keystrokes", # Separates Distracted
    "idle_time_percent"     # Separates Idle
]

print("Generating Key Features Pairplot...")
plt.figure(figsize=(15, 10))
plot = sns.pairplot(
    plot_df, 
    vars=key_features, 
    hue="status", 
    palette=custom_palette,
    diag_kind="kde", # Density curve on diagonal
    height=2.5,
    aspect=1.2,
    plot_kws={'alpha': 0.6, 's': 15, 'edgecolor': 'none'} # 's' is dot size
)
plot.fig.suptitle("Behavioral Clusters (Key Features)", y=1.02, fontsize=16, fontweight='bold')
plot.savefig(f"{output_dir}/1_cluster_separation.png", dpi=300, bbox_inches='tight')
plt.close()

# --- 4. Plot 2: Random Features Pairplot ---
# We exclude 'status' and the key features to see *other* correlations
all_cols = [c for c in df.columns if c != 'status']
# Ensure we don't error if we ask for more columns than exist
num_to_sample = min(3, len(all_cols)) 
selected_features = random.sample(all_cols, num_to_sample)

print(f"Generating Random Pairplot for: {selected_features}")
plt.figure(figsize=(10, 8))
plot = sns.pairplot(
    plot_df, 
    vars=selected_features,
    hue="status", 
    palette=custom_palette,
    diag_kind="kde",
    plot_kws={'alpha': 0.5, 's': 20}
)
plot.fig.suptitle(f"Random Feature Interaction", y=1.02)
plot.savefig(f"{output_dir}/random_feature_pairplot.png", dpi=300, bbox_inches='tight')
plt.close()

# --- 5. Plot 3: Boxplot (Focus Switching) ---
print("Generating Boxplot...")
plt.figure(figsize=(12, 6))
sns.boxplot(
    x="status", 
    y="focus_switch_rate", 
    data=plot_df, 
    palette="pastel",
    linewidth=1.5
)
plt.title("Distribution of Focus Switching by Status", fontsize=14, pad=15)
plt.grid(True, axis='y', linestyle='--', alpha=0.7) # Add subtle grid
plt.savefig(f"{output_dir}/2_boxplot_focus.png", dpi=300, bbox_inches='tight')
plt.close()

# --- 6. Plot 4: PCA Projection ---
print("Generating PCA Projection...")
# Step A: Standardize the SAMPLED data
features = plot_df.drop(columns=['status'])
x = StandardScaler().fit_transform(features)

# Step B: PCA
pca = PCA(n_components=2)
principalComponents = pca.fit_transform(x)
pca_df = pd.DataFrame(data=principalComponents, columns=['PC1', 'PC2'])
pca_df['status'] = plot_df['status'].values # Reset index to match

# Step C: Plot
plt.figure(figsize=(11, 9))
sns.scatterplot(
    x="PC1", y="PC2", 
    hue="status", 
    data=pca_df, 
    palette="deep", 
    s=50, 
    alpha=0.7,
    edgecolor="w", # White edge makes dots pop
    linewidth=0.5
)

plt.title("2D PCA Projection of Employee Behaviors", fontsize=15, fontweight='bold')
plt.xlabel(f"Principal Component 1 ({pca.explained_variance_ratio_[0]:.1%} variance)")
plt.ylabel(f"Principal Component 2 ({pca.explained_variance_ratio_[1]:.1%} variance)")
plt.legend(bbox_to_anchor=(1.02, 1), loc='upper left', borderaxespad=0., title="Status")
plt.tight_layout()

plt.savefig(f"{output_dir}/3_pca_projection.png", dpi=300, bbox_inches='tight')
plt.close()

print(f"Success! High-resolution plots saved to: {output_dir}")
