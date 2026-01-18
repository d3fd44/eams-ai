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

#show regex("[a-z]+_[a-z]+(_[a-z]+)?"): it => text(font: "Roboto Mono", size: 0.9em, fill: rgb("#005a9c"), it)

#align(center)[
  #text(17pt, weight: "bold")[Employee Activity Monitoring System]
  #v(0.5em)
  #text(12pt, style: "italic")[AI Methodology & Status Classification]
]
#line(length: 100%, stroke: 0.5pt + gray)
#v(1cm)


= Application Categorization

We categorize applications into three distinct types to better understand user intent:

- *Main Apps:* Core work tools (e.g., IDEs, Spreadsheet software).
- *Helper Apps:* Documentation, AI tools, research platforms, etc.
- *Entertainment Apps:* Non-work related applications.

For data collection, we aggregate the percentage of time spent in each category, the `focus_switch_rate` (indicating the frequency of context switching), and the overall `idle_percent` from received records. Additionally, we track the volume of keystrokes and mouse events occurring within each of the three categories.

= State Classification Pipeline

For the incoming log records (generated/received upon specific events like a focus switch, or at fixed time intervals), we first use *rule-based extraction* to compute the metrics mentioned above. Then, we feed these metrics into a Machine Learning model to classify the employee's state.

In real-time, the system determines the following:

- Online: Yes/No #text(size: 0.9em, fill: gray)[(Determined by the presence of receiving records, independent of the ML model).]

- Status Classification:

  #let def(term, body) = {
    block(below: 1em, breakable: false)[
      #text(weight: "bold", fill: rgb("#2c3e50"))[#term] $arrow.r$ #body
    ]
  }

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

= State Processing & Stabilization

To ensure the system provides a reliable assessment and eliminates the issue of "State Flickering," we process data through a robust aggregation pipeline.

Since analyzing raw event logs individually causes rapid status changes, we first extract metrics using rule-based logic and aggregate them into *discrete time chunks* (e.g., 30-second intervals), effectively converting the continuous stream into classifiable data points.

However, because a single interval might capture a momentary anomaly—such as a brief distraction within an otherwise productive session—we subsequently apply a *sliding window approach* over a sequence of these chunks. This helps us ignore random spikes, ensuring the final status shows the employee's true behavior over time rather than just a temporary moment.

= Data Acquisition

The foundation of any machine learning system is high-quality data. For this project, the acquisition process involved three distinct phases: initial research, preliminary simulation, and advanced behavioral modeling.

== Availability of Public Datasets
Our initial objective was to acquire real-world datasets from open-source repositories (e.g., Kaggle, GitHub). However, due to the highly specific nature of our application—which requires granular telemetry on focus switching, specific keystroke categories, and application types—and the inherent privacy concerns surrounding employee monitoring logs, no suitable public datasets existed. Consequently, we opted to generate a synthetic dataset to train the model.

== Initial Simulation: Uniform Distribution
Our preliminary generation attempt utilized a Bash script leveraging `awk` and its standard `rand()` function. This approach generated data based on a *Uniform Distribution*.

While computationally efficient, this method proved unsuitable for training classifiers. Human behavior is not uniformly random; it follows distinct patterns (e.g., a productive user consistently has high input rates). The uniform distribution produced "white noise" data with no discernable clusters, resulting in poor performance during unsupervised clustering attempts (e.g., K-Means yielding high inertia scores).

== Final Approach: Gaussian Behavioral Simulation
To resolve the lack of patternality, we migrated the generation logic to a Python environment utilizing the `NumPy` library. This allowed us to model user behavior using *Normal (Gaussian) Distributions* rather than uniform randomness.

By mapping the status definitions (Productive, Fragmented, etc.) to statistical parameters, we created distinct "Data Personas":

- *Statistical Bias:* Each status is assigned specific means and standard deviations for every feature.
  - _Example:_ Records labeled "Productive" are generated with a high mean for `main_keystrokes` and a low standard deviation (indicating consistency), whereas "Fragmented" records are generated with a significantly higher mean for `focus_switch_rate`.
- *Noise Injection:* We introduced controlled variance to non-defining features to prevent the model from overfitting to perfect data, ensuring it remains robust against real-world irregularities.

This process yielded a labeled, clustered dataset that statistically mirrors real-world usage patterns, providing a reliable foundation for supervised learning with XGBoost.
