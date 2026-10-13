# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

EthiBench is a Python CLI (`ethibench`) that scores AI pentesting agents' findings against expert-annotated ground truth (GT), using an LLM as a pairwise judge plus Hungarian bipartite matching. Methodology questions (why bipartite matching, why F0.5, sample sizes) are answered in the paper: arXiv:2605.10834.

## Commands

```bash
poetry install                      # dev setup (Python 3.11+)
poetry run ethibench --help         # banner = install works
poetry build                        # what CI runs on PRs (plus a check that README is embedded in the wheel/sdist)
ruff check src/                     # ruff config in pyproject.toml (line-length 100, py311); ruff is not a declared dep

# Typical end-to-end run against the bundled targets/GT
poetry run ethibench evaluate <experiment_dir> --dataset examples/dataset.yaml
poetry run ethibench evaluate --parent-dir experiments/ --dataset examples/dataset.yaml   # batch
poetry run ethibench analyze  --parent-dir experiments/ --dataset examples/dataset.yaml
poetry run ethibench compare  --parent-dir experiments/ --output-dir compare_all/
```

There is **no test suite**. CONTRIBUTING says not to add one for its own sake; a targeted regression test for a specific bug fix is fine. Verify changes by running the CLI on an existing experiment (e.g. `experiments/strix-gpt`). `evaluate` reuses cached intermediate artifacts unless `--force` is passed; downstream-only commands (`analyze`, `compare`, `subset`, `temporal`, and cumulative analysis) make no LLM calls.

LLM config is entirely via env vars (`ETHIBENCH_LLM_PROVIDER`, `ETHIBENCH_LLM_MODEL`, `ETHIBENCH_CONCURRENCY`, `ETHIBENCH_MAX_PARALLEL_RUNS`, provider API keys, …) — see `config.py` and `.env.sample`. `.env` is auto-loaded in `ethibench/__init__.py`.

## Architecture

Package lives in `src/ethibench/`; entry point `cli.py:cli` (Click). `cli.py` holds the orchestration glue (run discovery, batch modes, wiring of pipeline stages); modules import lazily inside commands.

**Data linkage is by name.** In an experiment directory, each target folder name must equal a `target_id` in the dataset YAML (`datasets.py`); GT entries (`*_gt.jsonl`, default `gt/` next to the YAML) carry `subset_name` + `target_id` and are filtered on those. If `run_*` subdirs exist, each is a run; otherwise the experiment dir itself is the single run (`_detect_run_dirs`).

**Evaluate pipeline** (`cli._run_single_evaluate` → `evaluate.run_evaluation` per run, runs in parallel under a semaphore):
1. `collect_findings` → `findings_parsed.jsonl`
2. Raw matching: async LLM YES/NO for every finding×GT pair in the same target (`llm.get_model` provider factory) → `raw_matchings/` (many-to-many; repeated per `--replicates`)
3. Bipartite matching via `scipy.optimize.linear_sum_assignment` → `matchings/`
4. Per-subset metrics → `results/`. Classification: TP = in 1-to-1 assignment; **Duplicate** = raw-matched but dropped by bipartite step; FP = no raw match at all; FN = unmatched GT. Also CVSS-bucketed severity score and CWE coverage (CWE parsed from GT `additional_info`).
5. `results.py` averages replicates → `results_avg/`, then across runs → `results_avg_all/`, adding weighted (YAML `weight`) and unweighted overall.
6. Multi-run only: `cumulative_analysis.py` merges all runs' findings + raw matchings (no new LLM calls), re-runs bipartite matching, and computes run overlap (Jaccard, discovery frequency) → `cumulative-analysis/`.
7. `metrics.py` aggregates optional per-target `metrics.json` (cost/tokens/duration) → `metrics_summary.json`; `plots.py` + `report.py` → `plots/`, `summary.md`.

Output layout differs by run count: single run writes straight into `evaluation_outputs/`; multi-run writes per-run subfolders `evaluation_outputs/<run_name>/` plus aggregated folders at the top. Downstream readers (`results.load_experiment_results`, `compare`, `subset`) depend on this layout, so keep it stable.

Downstream commands consume `evaluation_outputs/`: `analysis/` (duplicates, unmatched, GT stats; aggregated JSONL with `--parent-dir`), `pairwise.py` (A/B t-test/Cohen's d on top 4 by F1, emits `.md` + `.tex`), `subset.py` (exhaustive 2^N search for the target subset whose F1 best correlates with the full benchmark under a cost ratio), `temporal.py` (needs `timestamp` on findings).

`convert_report.py` is an example LLM-based markdown-report → `findings.jsonl` converter, expected to be adapted per agent.

## Non-package directories

- `examples/` — bundled dataset YAML + GT for vuln-bank, PAYGoat, XBEN-090. GT is pinned to specific upstream target versions (see README "Target version alignment"); don't assume latest upstream.
- `experiments/`, `compare_all/` — committed evaluation outputs from the paper (agent × model). Treat as data/results; regenerating them costs LLM calls.
- `lab/` — Docker Compose pentest lab: Kali attacker container (`kali-attacker`, on `targets` + `egress` networks) and the three benchmark targets on the internet-isolated `targets` network. `lab/targets/setup.sh` clones targets at the GT-pinned commits into git-ignored `lab/targets/src/` and applies `lab/targets/patches/*.patch`; change a target by editing its clone and regenerating the patch with `git diff`. Agent output goes in git-ignored `lab/workspace/`. See `lab/README.md`.
- `matching_experiments/` — standalone script (`run_experiment.py`) validating LLM judges against 50 human-annotated findings; not part of the installed package. See its README.

## Releases

semantic-release on every push to `main` publishes to PyPI, driven by Conventional Commit prefixes: `feat:` minor; `fix:`/`perf:`/`build:`/`revert:`/`docs:` patch; `chore:`/`ci:`/`refactor:`/`style:`/`test:` no release; `!`/`BREAKING CHANGE` major. Choose the prefix deliberately — `docs:` triggers a release. Don't hand-edit `version` in `pyproject.toml` or `CHANGELOG.md`; the release step (`.releaserc.yaml`) rewrites both and re-runs `poetry lock`. README image paths are rewritten to absolute URLs at release time, so keep them as relative `assets/...`.

Contribution scope (CONTRIBUTING): the tool is deliberately small — avoid new dependencies, cosmetic refactors, and renames without a concrete reason; update README for user-visible behavior changes.
