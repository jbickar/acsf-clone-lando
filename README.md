# ACSF Clone Lando

Set of scripts to clone from Stanford Web Services' (SWS) Acquia Cloud Site Factory (ACSF) infrastructure.

## Setup

1. Clone this repo
2. `cd acsf-clone-lando`
3. `./setup.sh` and follow the prompts. This will create a `acsf-clone-lando.sh` file in this directory and add an alias to your `~/.bashrc`, `acsf-clone-lando`
4. Run `source ~/.bashrc`

## Use

1. Run `acsf-clone-lando <shortname>`, where `<shortname>` is the shortname of the site on ACSF. This will clone the site and spin up a Lando install locally.

### Options

1. Run `acsf-clone-lando <shortname> leland` to clone from the "leland" stack. "cardinald7" is the default; other available stacks are "leland", "cardinalsites", and "lelandd8".

## Requirements

1. Lando
