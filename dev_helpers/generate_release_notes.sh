#!/usr/bin/env bash

semantic-release version --noop -D version_source=tag
semantic-release changelog --noop --unreleased -D version_source=tag