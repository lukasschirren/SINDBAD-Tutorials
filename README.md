# SINDBAD-Tutorials
A central repository to develop SINDBAD tutorials

## Getting the repo

The following command will install the tutorial files and SINDBAD itself.

```bash
git clone --recursive https://github.com/EarthyScience/SINDBAD-Tutorials.git
```

If cloned without the recursive flag, you can run to include SINDBAD as a submodule:
```bash
git submodule update --init --recursive
```

Note the root directory of where the repo is, for convenience, we'll call it `repo_root` from now on.

## Install Julia

Use Juliaup to install `Julia`. See instructions here:

https://github.com/JuliaLang/juliaup

The, install the VS Code Julia extension: 

https://marketplace.visualstudio.com/items?itemName=julialang.language-server


# Install Tutorial Environment
Open a terminal at the root of this repo (`repo_root`)

Go to the `ai4pex` tutorial folder:
```bash
cd tutorials/ai4pex_2025
```

Start up `Julia`, e.g., in Terminal:

```bash
julia
```

or in VSCode, open the `tutorials/ai4pex_2025` folder and start the REPL (Ctrl+Shift+J)

Activate an environment in the folder with:
```julia
using Pkg
Pkg.activate("./")
```

The prompt should change to `(ai4pex_2025) pkg>`.

Instantiate/install the packages in the environment with:
```julia
Pkg.instantiate()
```

# Set REPL environment
In VS code, set the `ai4pex_2025` as the active project by clicking on the `Julia env:` dropdown and selecting `ai4pex_2025` as the folder. This should change the default environment for the REPL.


# Download Tutorial Data
Download the data for the tutorial from [here](www.thedatadownlaodlinkhere.com). 
Unzip the file into `tutorials/data/ai4pex_2025`.

# Tutorials

The tutorials are located under `tutorials/ai4pex_2025`. Follow the instructions in the `.jl` files.