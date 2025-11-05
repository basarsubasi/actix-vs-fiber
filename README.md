# Actix vs Fiber Benchmark Suite

This repository provides a reproducible environment for **benchmarking Actix-Web (Rust) and Fiber (Go) web frameworks** under high-concurrency, database-intensive workloads.

---

## Structure

- **`actix/`**
  - Rust Actix-Web benchmark app.
  - See `.env.example` for environment variables.

- **`fiber/`**
  - Go Fiber benchmark app.
  - See `.env.example` for environment variables.

- **`vms/`**
  - Scripts and configs for setting up VMs:
    - **`client-vm/`**: Kernel tuning for load generator (e.g., oha).
    - **`server-vm/`**: Kernel tuning for web server VM.
    - **`db-vm/`**:
      - PostgreSQL kernel and config tuning
      - `setup_database.sql`: Creates and seeds benchmark tables
      - `setup_benchmark_db.sh`: Automates DB setup
    - **`init/`**:
      - Tuned/minimal PostgreSQL configs
      - Full database (re)build script

---

## Usage

1. **Provision three VMs:**
   - Client (load generator)
   - Server (runs Actix or Fiber)
   - Database (PostgreSQL)

2. Run the setup scripts in each VM as root to apply **kernel optimizations**.

WIP