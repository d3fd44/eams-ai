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

Our initial objective was to acquire real-world datasets from open-source repositories (e.g., Kaggle, GitHub). However, due to the highly specific nature of our application—which requires granular telemetry on focus switching, specific keystroke categories, and application types—and the inherent privacy concerns surrounding employee monitoring logs, no suitable public datasets existed. Consequently, we opted to generate a synthetic dataset to train the model.

#h3("Generating Completely Random Unlabeled Samples")

Our preliminary generation attempt utilized a Bash script leveraging `awk` and its standard `rand()` function. This approach generated data based on a *Uniform Distribution*.

While computationally efficient, this method proved unsuitable for training classifiers. Human behavior is not uniformly random; it follows distinct patterns (e.g., a productive user consistently has high input rates). The uniform distribution produced "white noise" data with no discernable clusters, resulting in poor performance during unsupervised clustering attempts (e.g., K-Means yielding high inertia scores).

#h3("Gaussian Behavioral Simulation")

To resolve the lack of clear patterns, we tried to model user behavior using *Normal (Gaussian) Distributions* rather than uniform randomness.

By mapping the status definitions (Productive, Fragmented, etc.) to statistical parameters, we created distinct "Data Personas":

- *Statistical Bias:* Each status is assigned specific means and standard deviations for every feature.
  - _Example:_ Records labeled "Productive" are generated with a high mean for `main_keystrokes` and a low standard deviation (indicating consistency), whereas "Fragmented" records are generated with a significantly higher mean for `focus_switch_rate`.
- *Noise Injection:* We introduced controlled variance to non-defining features to prevent the model from overfitting to perfect data, ensuring it remains robust against real-world irregularities.

This process yielded a labeled, clustered dataset that statistically mirrors real-world usage patterns, providing a reliable foundation for a supervised learning task.

#figure(
  image("./data-5k-pairplot_clusters.png", width: 80%),
  caption: [Feature separation pairplot: This confirms that the Gaussian generation strategy successfully created distinct regions for each status.],
)

#figure(
  image("./data-5k-pca_projection.png", width: 80%),
  caption: [2D PCA Projection: Dimensionality reduction illustrates that the synthetic behavioral profiles form separable, cohesive clusters, validating the dataset for classification tasks.],
)

This was made possible and straightforward using Python and the `NumPy` library, creating a realistic distribution of employee work patterns:
```python
    statuses = ['productive', 'active', 'fragmented', 'distracted', 'idle']
    probs =    [0.35,          0.20,     0.20,         0.15,         0.10]
```

This implies that approximately 35% of employees work productively, while 20% spend time learning new tools or conducting research. Finally, a small percentage spend time away from the computer.

For each of the mentioned working statuses, the following sample/instance is generated:

```python
{
  focus_switch_rate       :int,
  overall_idle_percent    :float,
  main_keystrokes         :float,
  main_mouse_events       :float,
  helper_keystrokes       :float,
  helper_mouse_events     :float,
  entertain_keystrokes    :float,
  entertain_mouse_events  :float
}


```

Therefore, generating records for the "Fragmented" status, for example, can be achieved with the following snippet:
```python
if status == 'fragmented':
    focus_switch_rate    = np.random.normal(35, 10) 
    overall_idle_percent = np.random.normal(0.02, 0.02)
    main_keystrokes      = np.random.normal(0.4, 0.2)
    entertain_keystrokes = np.random.normal(0.2, 0.15)


```

Note that for a high `focus_switch_rate` in the "Fragmented" status, we specified a high mean value (`loc=35`) which is the center of the normal distribution, and a moderately high standard deviation (`scale=10`). This allows us to generate ~500k samples of semi-realistic data in just a few seconds.

#block(stroke: (left: 3pt + gray), radius: 2pt, inset: (left: 1em))[
Note: It may not be the perfect data type choice for the input volumes (`main_keystrokes`, `main_mouse_events`, etc.). For now, it simulates a percentage over time of input, which is sufficient for a first prototype of the AI workflow in the system.
]

\

#h2("Model Architecture: Tools & Workflow")

Following the generation of our synthetic Gaussian dataset, we will proceed to the training and workflow design phase.

Given the tabular nature of our telemetry data, where relationships between features like `focus_switch_rate` and `idle_percent` are non-linear but structured, we selected a Gradient Boosting framework.

#h3("Algorithm Selection: XGBoost")

We found that the *XGBoost (eXtreme Gradient Boosting)* classifier is a good choice for our case. This algorithm was chosen over other potential candidates (such as Random Forests or Neural Networks) for three key reasons:

- *Tabular Dominance:* Gradient boosted trees historically outperform deep learning models on structured, low-dimensional tabular data.
- *Regularization:* XGBoost includes built-in L1 (Lasso) and L2 (Ridge) regularization, which prevents the model from overfitting to the synthetic "perfect" patterns in our training data.
- *Inference Speed:* The optimized C++ backend of XGBoost allows for incredibly fast prediction times (ms), which is a hard requirement for our real-time dashboard.

#h3("Tools For An Efficient Real-Time System")

A real-time system requires a reliable environment that delivers speed, load-balancing, and efficient buffering, just to name a few. Given the nature of our system, which might involve tens, hundreds, or maybe thousands of active Agents sitting on each employee's computer sending tons of log records per session, we must rely on a *Streaming* or *Message Queuing* Platform.

For that specific purpose, we chose *Apache Kafka*. It is an open-source, distributed event streaming platform that handles real-time data feeds, acting as a high-throughput, fault-tolerant message bus for building data pipelines and streaming applications, allowing systems to publish and subscribe to streams of records (events). Kafka can deal with continuous streams of "events," which are records of anything that happens. This is exactly what we want!

To simplify the setup and reduce development effort, we will rely heavily on *n8n* to build an integrated workflow and manage the data pipeline. The entire system will run in a _containerized_ environment using *Docker*, ensuring consistency and ease of deployment.
