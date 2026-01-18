import random
import numpy             as np
import seaborn           as sns
import pandas            as pd
import matplotlib.pyplot as plt

df = pd.read_csv("./data.csv")
df.info(memory_usage='deep')

X = np.array(df.columns)[:-1]
y = np.array(df.columns)[-1]

from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
import os

output_dir = "data-1k"
os.makedirs(output_dir, exist_ok=True)

sns.set_theme(style="whitegrid")

hero_features = [
    "main_keystrokes", 
    "focus_switch_rate", 
    "entertain_keystrokes", 
    "overall_idle_percent"
]

plt.figure(figsize=(15, 10))
plot = sns.pairplot(
    df, 
    vars=hero_features, 
    hue="status", 
    palette="bright",
    diag_kind="kde",
    plot_kws={'alpha': 0.6}
)
plot.fig.suptitle("Feature Separation by Employee Status", y=1.02)

plot.savefig(f"{output_dir}/1_pairplot_clusters.png", dpi=300, bbox_inches='tight')
print("Saved Pairplot.")
plt.close()

feature_cols = [c for c in df.columns if c != 'status']
selected_features = random.sample(feature_cols, 3) 
print(f"Plotting: {selected_features}")
plt.figure(figsize=(10, 8))
plot = sns.pairplot(
    df, 
    vars=selected_features,
    hue="status", 
    palette="bright",
    diag_kind="kde",
    plot_kws={'alpha': 0.6, 's': 30}
)

# plot.fig.suptitle(f"Random Feature Interaction: {', '.join(selected_features)}", y=1.02)
plot.savefig(f"{output_dir}/random_feature_pairplot.png", dpi=300, bbox_inches='tight')
print("Saved Random Pairplot.")
plt.close()

plt.figure(figsize=(12, 6))
sns.boxplot(x="status", y="focus_switch_rate", data=df, palette="pastel")
plt.title("Distribution of Focus Switching by Status")

plt.savefig(f"{output_dir}/2_boxplot_focus.png", dpi=300, bbox_inches='tight')
print("Saved Boxplot.")
plt.close()

features = df.drop(columns=['status'])
x = StandardScaler().fit_transform(features)

pca = PCA(n_components=2)
principalComponents = pca.fit_transform(x)
pca_df = pd.DataFrame(data=principalComponents, columns=['PC1', 'PC2'])
pca_df['status'] = df['status']

plt.figure(figsize=(10, 8))
sns.scatterplot(
    x="PC1", y="PC2", 
    hue="status", 
    data=pca_df, 
    palette="deep", 
    s=60, 
    alpha=0.7
)
plt.title("2D PCA Projection of Employee Behaviors")
plt.xlabel(f"Principal Component 1 ({pca.explained_variance_ratio_[0]:.1%} variance)")
plt.ylabel(f"Principal Component 2 ({pca.explained_variance_ratio_[1]:.1%} variance)")
plt.legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.)
plt.tight_layout()

plt.savefig(f"{output_dir}/3_pca_projection.png", dpi=300, bbox_inches='tight')
print("Saved PCA Projection.")
plt.close()

print(f"All images saved to folder: {output_dir}")
