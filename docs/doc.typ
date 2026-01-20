#set page(
  paper: "a4",
  margin: (x: 2.5cm, y: 2.5cm),
)

#set text(
  font: "Linux Libertine",
  size: 11pt,
  hyphenate: false
)

#show heading: set text(font: "Roboto", weight: "bold", fill: rgb("#333333"))

#show regex("[a-z]+_[a-z]+(_[a-z]+)?"): it => text(font: "Roboto Mono", fill: rgb("#005a9c"), it)

#show heading: set text(font: "Roboto", weight: "bold", fill: rgb("#333333"))
#set heading(numbering: "1.")

#let h2(header) = box()[
  #show heading.where(level: 2): it => context {
    let c = counter(heading).get()
    text(size: 14pt, fill: rgb("#333333"))[ #c.at(0).#c.at(1). #it.body ]
  }
  == #header
]

#let h3(header) = box()[
  #show heading.where(level: 3): it => context {
    let c = counter(heading).get()
    text(size: 12pt, style: "italic")[ #c.at(0).#c.at(1).#c.at(2). #it.body ]
  }
  === #header
]

#let def(term, body) = {
    block(below: 1em, breakable: false)[
      #text(weight: "bold", fill: rgb("#2c3e50"))[#term] $arrow.r$ #body
    ]
}

#align(center)[
  #text(17pt, weight: "bold")[Employee Activity Monitoring System]
  #v(0.5em)
  #text(12pt, style: "italic")[AI Methodology & Status Classification]
]
#line(length: 100%, stroke: 0.5pt + gray)
#v(1cm)


#h2("Application Categorization")

We categorize applications into three distinct types to better understand user intent:

- *Main Apps:* Core work tools (e.g., IDEs, Spreadsheet software).
- *Helper Apps:* Documentation, AI tools, research platforms, etc.
- *Entertainment Apps:* Non-work related applications.

For data collection, we aggregate the percentage of time spent in each category, the `focus_switch_rate` (indicating the frequency of context switching), and the `overall_idle_percent` from received records. Additionally, we track the volume of keystrokes and mouse events occurring within each of the three categories.

#h2("State Classification Pipeline")

For the incoming log records (generated/received upon specific events like a focus switch, or at fixed time intervals), we first use *rule-based extraction* to compute the metrics mentioned above. Then, we feed these metrics into a Machine Learning model to classify the employee's state.

In real-time, the system determines the following:

- Online: Yes/No #text(size: 0.9em, fill: gray)[(Determined by the presence of receiving records, independent of the ML model).]

- Status Classification:

  #def("Productive")[
    Mostly in Main Apps with HIGH input intensity (keystrokes/mouse).
  ]

  #def("Active")[
    Likely researching or reading documentation. Characterized by moderate Helper App usage, low keystrokes (reading mode), high mouse usage (scrolling), and low idle time.
  ]

  #def("Fragmented")[
    Characterized by a High `focus_switch_rate`. The user is rapidly jumping between Main, Helper, and Entertainment apps, often with moderate input but no sustained focus on a single task.
  ]

  #def("Distracted")[
    Dominated by Entertainment App usage. Input rate and idle time are irrelevant here; if the primary active window is non-work for a significant duration, the status is distracted.
  ]

  #def("Idle")[
    High `idle_percent` across all categories with *Low* input.
  ]

#h2("State Processing & Stabilization")

To ensure the system provides a reliable assessment and eliminates the issue of "State Flickering," we process data through a robust aggregation pipeline.

Since analyzing raw event logs individually causes rapid status changes, we first extract metrics using rule-based logic and aggregate them into *discrete time chunks* (e.g., 30-second intervals), effectively converting the continuous stream into classifiable data points.

However, because a single interval might capture a momentary anomaly—such as a brief distraction within an otherwise productive session—we subsequently apply a *sliding window approach* over a sequence of these chunks. This helps us ignore random spikes, ensuring the final status shows the employee's true behavior over time rather than just a temporary moment. 

#h2("Data Acquisition")

The foundation of any machine learning system is high-quality data. For this project, the acquisition process involved three distinct phases: initial research, preliminary simulation, and advanced behavioral modeling.

#h3("Availability of Public Datasets")

Our initial objective was to acquire real-world datasets from open-source repositories (e.g., Kaggle, GitHub). However, due to the highly specific nature of our application—which requires detailed tracking of context switching, keystroke categories, and specific app usage—and the privacy issues surrounding employee monitoring logs, no suitable public datasets existed. Consequently, we opted to generate a synthetic dataset to train the model.

#h3("Generating Completely Random Unlabeled Samples")

Our preliminary generation attempt utilized a Bash script leveraging `awk` and its standard `rand()` function. This approach generated data based on a *Uniform Distribution*.

While fast and easy to write, this method was not suitable for training classifiers. Human behavior is not uniformly random; it follows distinct patterns (e.g., a productive user usually has high input rates, not random ones). The uniform distribution produced "white noise" data with no distinct clusters, resulting in poor performance during our initial clustering tests.

#h3("Level-Based Logic & Gaussian Simulation")

To resolve the lack of clear patterns, we switched to a *Level-Based Generation Strategy* backed by *Normal (Gaussian) Distributions*.

Instead of manually guessing means and standard deviations for every single number, we defined a higher-level logic layer using semantic levels: `{ LOW, MEDIUM_LOW, MEDIUM, MEDIUM_HIGH, HIGH }`. A parser then automatically translates these descriptions into statistical parameters.

- *Logical Ranges:* We defined specific ranges (e.g., `HIGH` maps to $[0.8, 1.0]$). The system takes the center of that range as the *Mean* ($mu$) and calculates a *Standard Deviation* ($sigma$) that fits the range. This ensures that 95% of the generated numbers fall inside the correct area.

- *Data Centralization:* This logic naturally anchors profiles to realistic baselines. For example, the `Idle` profile is defined with `LOW` inputs. Consequently, the Gaussian generator produces numbers very close to 0.0, effectively creating a "zero-state" baseline that the model can easily distinguish from active states.

- *Epsilon ($epsilon$) Shift:* To prevent the Machine Learning model from simply memorizing exact values (Overfitting), we injected a small random "jitter" (Epsilon) into the generation process. For every generated sample, the target Mean is shifted slightly (e.g., $0.80 plus.minus 0.001$). This ensures that no two "Productive" records are mathematically identical, forcing the classifier to learn the general *concept* of high activity rather than memorizing a specific number.

- *Realistic Class Imbalance:* To mimic a real-world office environment, we did not generate equal amounts of data for each status. Instead, we applied weighted probabilities (e.g., 35% Productive vs. 10% Idle). This forces the model to learn to identify the "majority class" correctly without ignoring the rarer "minority class" (Idle), a common challenge in production systems.

This process yielded a labeled, clustered dataset that statistically mirrors real-world usage patterns.

#figure(
  image("./three_random_feature_pairplot.png", width: 80%),
  caption: [Feature separation pairplot: This confirms that the Level-Based generation strategy successfully created distinct regions for each status, while maintaining realistic overlaps.],
)

#figure(
  image("./pca_projection.png", width: 80%),
  caption: [2D PCA Projection (Dimensionality reduction): A clear "Lambda" ($lambda$) topology, validating that the features are correlated in distinct directions (Work vs. Distraction).],
)

The implementation was streamlined by defining "Profiles" in a configuration dictionary, which the generator reads to produce the samples:

```python
profiles = {
    'Productive': {
        'focus_switch':  ['L', 'M'], # Moderate switching
        'idle_percent':  ['L', 'ML'],
        'main_keys':     ['M', 'H'], # High Activity
        'main_mouse':    ['M', 'H'],
        'entertain_keys': 'L'        # Near Zero tolerance for games
    },
    'Fragmented': {
        'focus_switch':   ['MH', 'H'], # Extremely high switching
        'idle_percent':    'ML',
        'main_keys':      ['L', 'M'],
        'entertain_keys': ['L', 'M']
    }
    # and so on ...
}

```

This abstraction allows us to generate ~500k samples of semi-realistic data in seconds, with each profile adhering to strict behavioral rules (e.g., a "Productive" user can never have "High" entertainment usage).

#block(stroke: (left: 3pt + gray), radius: 2pt, inset: (left: 1em))[
Note: This might not be the perfect simulation for input volumes. Real-world features often depend on each other (e.g., typing fast usually means not using the mouse). However, for a first prototype, simulating a percentage of activity over time is sufficient to train the AI workflow.
]

\

#h2("Model Architecture: Tools & Workflow")

Following the generation of our synthetic Gaussian dataset, we will proceed to the training and workflow design phase.

Given the tabular nature of our data, where relationships between features like `focus_switch_rate` and `idle_percent` are non-linear but structured, we selected a Gradient Boosting framework.

#h3("Algorithm Selection: XGBoost")

We found that the *XGBoost (eXtreme Gradient Boosting)* classifier is a good choice for our case. This algorithm was chosen over other potential candidates (such as Random Forests or Neural Networks) for three key reasons:

- *Tabular Dominance:* Gradient boosted trees historically outperform deep learning models on structured, tabular data.
- *Regularization:* XGBoost includes built-in regularization, which prevents the model from memorizing the synthetic "perfect" patterns in our training data.
- *Inference Speed:* The optimized C++ backend of XGBoost allows for incredibly fast prediction times (ms), which is a hard requirement for our real-time dashboard.

#h3("Training Methodology")

The dataset was split into training (80%) and validation (20%) sets to ensure that the reported accuracy reflects the model's ability to generalize to unseen data, rather than simply recalling the training examples.

#h3("Tools For An Efficient Real-Time System")

A real-time system requires a reliable environment that delivers speed and load-balancing. Given that our system might involve hundreds of active Agents sending logs simultaneously, we must rely on a *Streaming Platform*.

For that specific purpose, we chose *Apache Kafka*. It acts as a high-throughput message bus that handles real-time data feeds. Kafka can deal with continuous streams of "events" (records of anything that happens), which is exactly what we want. This decoupling ensures that even if the AI Service is under heavy load, the Agents can continue sending data without crashing or losing records.

To simplify the setup, we will rely on *n8n* to manage the data pipeline. The entire system will run in a *containerized* environment using *Docker*, ensuring consistency and ease of deployment.

