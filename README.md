# Cronyx

<p align="center">
  Cron like job scheduler built in Elixir. Supports both ad-hoc and persisted job store
</p>

[![Elixir CI](https://github.com/SoundstripeEngineering/transloaditex/actions/workflows/ci.yml/badge.svg)](https://github.com/SoundstripeEngineering/cronyx)
[![Module Version](https://img.shields.io/hexpm/v/transloaditex.svg)](https://hex.pm/packages/cronyx)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/cronyx/)
[![Total Download](https://img.shields.io/hexpm/dt/transloaditex.svg)](https://hex.pm/packages/cronyx)
[![License](https://img.shields.io/hexpm/l/transloaditex.svg)](https://github.com/WTTJ/cronyx/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/SoundstripeEngineering/transloaditex.svg)](https://github.com/SoundstripeEngineering/cronyx/commits/master)

## Features

Cronyx is a simple, easy to use, library that handles a wide range of background job scheduling use cases. It presents a straightforward API for scheduling and executing fault-tolerant jobs and logs execution results.

- **Scheduled Jobs** - Jobs can be scheduled using familiar cron notation.

- **Ad-Hoc Jobs** - Jobs can be added via code using a simplified method of defining the schedule.

- **Execution Result Logging** - Job results are captured, including exceptions, and are stored in the persistent data store.

- **Additional Job Conditions** - Persisted jobs get an extra level of job condition. In addition to the cron notation, persisted jobs can be dependent on the status of other jobs.

- **Fault Tolerant** - Jobs are each isolated into their own worker process. When a job crashes it does not cause your application to crash.

## Usage

Cronyx is a robust job scheduling library using either Ecto repo for persistence, or manually created ad-hoc jobs.

### Installation

### Requirements
