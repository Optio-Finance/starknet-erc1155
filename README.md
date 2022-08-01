# ERC1155 on StarkNet

This repo contains highly experimental code. Expect rapid iteration.

## Installation

### First time?

Before installing Cairo on your machine, you need to install `gmp`:

```bash
sudo apt install -y libgmp3-dev # linux
brew install gmp # mac
brew install pipenv
```

> If you have any troubles installing gmp on your Apple M1 computer,
> [here’s a list of potential solutions](https://github.com/OpenZeppelin/nile/issues/22).

### Set up the project

Clone the repository

```bash
git clone git@github.com:Optio-Finance/starknet-erc1155.git
```

`cd` into it and create a Python virtual environment:

```bash
cd cairo-contracts
pipenv shell
```

Install the [Nile](https://github.com/OpenZeppelin/nile) dev environment and
then run `install` to get
[the Cairo language](https://www.cairo-lang.org/docs/quickstart.html), a
[local network](https://github.com/Shard-Labs/starknet-devnet/), and a
[testing framework](https://docs.pytest.org/en/6.2.x/).

```bash
pipenv install cairo-nile
nile install
```

## Security

This project is still in a very early and experimental phase. It has never been
audited nor thoroughly reviewed for security vulnerabilities. Please report any
security issues you find to security@optio.finance.

## License

TODO
