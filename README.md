# ADVOCATE: Concurrency Bug Detection for Go

ADVOCATE is a toolset for analyzing, fuzzing, recording, and replaying concurrency bugs in Go programs. The original Git Repository can be found [here](https://github.com/ErikKassubek/ADVOCATE).

This project aims to test the three different fuzzing modes with specific samples of Go Concurrency Primitives.

---

## Install Advocate
### Prerequisites
- Linux OS or WSL
- Go Version 1.24

### Step 1: Update System

```bash
sudo apt update
sudo apt upgrade
```


### Step 2: Install Go 1.24.2
```bash
cd ~
curl -LO https://go.dev/dl/go1.24.2.linux-amd64.tar.gz
tar -xzf go1.24.2.linux-amd64.tar.gz
mv go go-runtime
```


### Step 3: Set Go Environment
```bash
echo 'export GOROOT=$HOME/go-runtime' >> ~/.bashrc
echo 'export PATH=$GOROOT/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```


### 4. Verify Version
```bash
go version # Expected: go version go1.24.2 linux/amd64
```

### 5. Clone & Build Advocate
```bash
# Clone git
git clone https://github.com/ErikKassubek/ADVOCATE.git
cd ADVOCATE

# Patch Go Runtime
cd go-patch/src
./make.bash

# Build CLI
cd ../../advocate
go build
```


### 6. Test Sample
```bash
./advocate \
  fuzzing \
  -path ~/path/to/sample/project \
  -exec NameOfTestFunction \ 
  -fuzzingMode GoPie \
  -prog deadlock_test
```