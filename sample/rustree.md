# Rust Project Structure

project/
├── src/
│   ├── main.rs
│   ├── lib.rs
│   ├── config.rs
│   ├── utils/
│   │   ├── mod.rs
│   │   ├── file1.rs
│   │   └── file2.rs
│   └── models/
│       ├── mod.rs
│       ├── model1.rs
│       └── model2.rs
├── tests/
│   ├── integration_test.rs
│   └── common/
│       └── mod.rs
├── benches/
│   └── benchmark1.rs
├── examples/
│   ├── example1.rs
│   └── example2.rs
├── data/
│   ├── input/
│   └── output/
├── docs/
│   └── architecture.md
├── Cargo.toml
├── Cargo.lock
├── README.md
└── .gitignore
