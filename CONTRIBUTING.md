# Contributing

Contributions are very welcome!

## Tooling
Docker, docker-compose and some python tooling is used in development and testing, because that's what I know best :)

## The ./tests directory

All commands you'll need during dev are only available from within the `./tests` directory.

```shell
cd ./tests
```

## Building the testing container

```shell
make build
```

## Running the tests

```shell
make tests
```

## Formatting & Linting the python tests

For formatting and linting the python tests, following tools are used:

 - black
 - isort
 - flake8

## conventional commits
For automatically generating release notes, commit messages are parsed. This only works, if they follow the
[Conventional Commits specification](https://www.conventionalcommits.org/en/v1.0.0/).


## Setup pre commit
Pre commit hooks is an additional option instead of linting and formatting checks in your editor of choice.

First create a virtualenv with the tool of your choice before running below commands:

```shell
pip install pre-commit
pip install -r requirements.txt
pre-commit install --hook=pre-commit
pre-commit install --hook=commit-msg
```

## Generating the release notes
Make sure [python-semantic-release](https://github.com/relekang/python-semantic-release) is
installed and then run

```shell
make release-notes
```
