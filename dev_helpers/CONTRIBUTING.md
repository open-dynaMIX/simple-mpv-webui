# Contributing

Contributions are very welcome!

## Tooling
Some python tooling is used in development, because that's what I already know :)

To install everything needed, you can run

```bash
pip install -r ./dev_helpers/requirements.txt
```

in a virtual environment.

## conventional commits
For automatically generating release notes, commit messages are parsed. This only works, if they follow the
[Conventional Commits specification](https://www.conventionalcommits.org/en/v1.0.0/).

There is a github action that enforces this.

### Local linting
For local linting, there is a `commit-msg` hook in `dev_helpers`.

This hook uses [gitlint](https://github.com/jorisroovers/gitlint), so you need to make sure it's installed.

Then you can add the foloowing symlink:

```bash
ln -s "$(pwd)/dev_helpers/commit-msg" "$(pwd).git/hooks/commit-msg"
```

Now, your commit messages will be linted, before comitting.

## Generating the release notes
Make sure [python-semantic-release](https://github.com/relekang/python-semantic-release) is
installed and then execute `./dev_helpers/generate_release_notes.sh`.
