# Lab setup on a new machine

Step-by-step guide to rebuild the pentest lab from scratch and run the two agent setups we use:

- **opencode** in `kali-attacker` (open-ended agent, driven by the prompts in `prompts/`).
- **EvoPentester** in `kali-evo` (evolutionary planner "ESO" + its execution service "ACI").

`lab/README.md` is the short reference; this file is the full walkthrough, including the problems we hit.

## What you end up with

```
                       egress network (internet: package installs, LLM APIs)
                            |                         |
                     +--------------+          +--------------+
                     | kali-attacker|          |   kali-evo   |
                     |   opencode   |          | ESO + ACI    |
                     +--------------+          +--------------+
                            |                         |
        targets network (internal: no internet, no host ports)
            |             |              |              |
        vuln-bank     paygoat       paygoat-api      xben-090
        (+ vuln-bank-db)   (UI :8000)   (API :3000)    (:5003)
```

The two Kali containers are separate on purpose: separate workspaces (`lab/workspace/` and `lab/evo-workspace/`), shell history and agent state, so runs from one never contaminate the other.

## 1. Prerequisites

- Docker with Compose v2 (Docker Desktop or Engine). Images are multi-arch (arm64 and amd64).
- `git`, and roughly 15 GB of free disk (the Kali base image alone is ~4.6 GB; `kali-evo` adds more).
- An **OpenRouter API key** (both agents use `qwen/qwen3.8-flash` through OpenRouter).
- A **GitHub account that can read `kaushithamsilva/evopentester`** (private repo; ask the owner to add you as a collaborator). `kaviru2/pi-monorepo` is public.
- Optional, to score results on the host: Python 3.11+, Poetry and an LLM key for ethibench's matcher (see the main `README.md` and `.env.sample`).

## 2. Get the repo and build the lab

```bash
git clone https://github.com/mottretor/ethibench
cd ethibench
git switch experiments/opencode-qwen-vuln-bank   # the branch holding the lab and prompts

bash lab/targets/setup.sh                 # clones the 3 targets at the pinned commits + applies lab/targets/patches/*.patch
docker compose -f lab/docker-compose.yml build kali vuln-bank paygoat paygoat-api xben-090
docker compose -f lab/docker-compose.yml up -d kali vuln-bank vuln-bank-db paygoat paygoat-api xben-090
```

Check from Kali (the targets publish no host ports):

```bash
docker exec kali-attacker bash -c 'for u in http://vuln-bank:5000/ http://paygoat:8000/ http://paygoat-api:3000/api-docs/ http://xben-090:5003/; do echo "$u $(curl -s -o /dev/null -w %{http_code} -L --max-time 8 $u)"; done'
```

All four should print `200`. The first build takes several minutes (Kali tool install, PAYGoat's React build).

Targets, pinned versions and what the patches change are listed in `lab/README.md`. Don't use the upstream `main` branches; the ground truth in `examples/gt/` was annotated against specific versions.

### Resetting the targets

Agents change target state (new users, transfers, uploads). Reset before every run:

```bash
docker compose -f lab/docker-compose.yml up -d --force-recreate --renew-anon-volumes \
  vuln-bank vuln-bank-db paygoat paygoat-api xben-090
```

A clean vuln-bank has a single user, `admin`:
`docker compose -f lab/docker-compose.yml exec -T vuln-bank-db psql -U postgres -d vulnerable_bank -c "select username from users"`.

## 3. opencode in `kali-attacker`

opencode is **not baked into the image**; it is installed by hand inside the running container. Its binary, login and session history live in the container's writable layer, so they are lost if the container is **recreated** (`up --force-recreate`, or a compose-file change followed by `up -d`). Plain `docker stop` / `docker start` keeps them.

```bash
docker exec -it kali-attacker bash
  # inside the container:
  curl -fsSL https://opencode.ai/install | bash -s -- --version 2.0.28   # installs to ~/.opencode/bin and adds it to PATH in ~/.bashrc
  source ~/.bashrc
  opencode --version                                                      # v2.0.28
  opencode auth login                                                     # choose OpenRouter and paste your key when asked
  opencode auth list                                                      # should show OpenRouter as "stored"
  opencode models | grep qwen3.8-flash                                    # openrouter/qwen/qwen3.8-flash
```

Needs a real terminal (`docker exec -it ...`); a `!` command inside Claude Code has no TTY.

### Running one target

Give each run its **own directory** so agents never see each other's notes, copy in the matching prompt, and start opencode there:

```bash
# on the host: put the prompt in a fresh run folder (lab/workspace is /workspace in the container)
mkdir -p lab/workspace/run_1/vuln-bank
cp prompts/vuln-bank.md lab/workspace/run_1/vuln-bank/prompt.md      # or paygoat.md / xben-090.md

docker exec -it kali-attacker bash -c 'cd /workspace/run_1/vuln-bank && opencode'
```

In opencode, select the model `openrouter/qwen/qwen3.8-flash` and send: *"Follow the instructions in prompt.md."*

The non-interactive equivalent is `opencode run --model openrouter/qwen/qwen3.8-flash --auto -f prompt.md "Follow the instructions in prompt.md."` (flags from `opencode run --help`; `--auto` auto-approves permissions). We have not tested this form in the lab.

Which model the committed `opencode-qwen*` runs used is not recorded in the repo; pick the model you want to compare and note it in the experiment's metadata.

The three prompts in `prompts/` are identical except for the Target section. PAYGoat's prompt names only the UI (`http://paygoat:8000`); the agent has to discover the API host itself.

### Collecting results

The agent writes `findings.jsonl`, `pentest_log.md`, `unconfirmed.md`, `endpoints.md`, `coverage.md` and `artifacts/` in its directory. Copy the first five into the layout ethibench expects (folder name = `target_id` in `examples/dataset.yaml`):

```
experiments/<experiment>/run_1/<target_id>/findings.jsonl      # target_id: vuln-bank | paygoat | xben-090
```

Leave out `artifacts/` and any token/password files the agent saved (they hold forged tokens and captured credentials). Then score on the host:

```bash
poetry run ethibench evaluate experiments/<experiment> --dataset examples/dataset.yaml
```

## 4. EvoPentester in `kali-evo`

EvoPentester is two programs that both run inside `kali-evo`:

- **ESO**, `kaushithamsilva/evopentester` (Python 3.12, via `uv`): plans strategies with the LLM and sends actions to the ACI.
- **ACI**, `packages/autopentester` in `kaviru2/pi-monorepo` (Node): HTTP service on `localhost:3000` that runs each action as an LLM agent loop with real shell tools on the Kali box.

### 4.1 Key and container

```bash
# OpenRouter key, stored in a git-ignored file that compose loads into kali-evo only.
# bash:  read -s -p "OpenRouter key: " K && echo && printf 'OPENROUTER_API_KEY=%s\n' "$K" > lab/evo.env && chmod 600 lab/evo.env && unset K
# zsh:   read -s "K?OpenRouter key: " && echo && printf 'OPENROUTER_API_KEY=%s\n' "$K" > lab/evo.env && chmod 600 lab/evo.env && unset K

docker compose -f lab/docker-compose.yml up -d --build kali-evo
docker exec kali-evo bash -c 'echo "key set: ${OPENROUTER_API_KEY:+yes}"; node -v; uv --version; gh --version | head -1'
```

If you add or change `lab/evo.env` after the container exists, run `up -d kali-evo` again: environment is only read when the container is (re)created.

### 4.2 GitHub login (one time)

```bash
docker exec -it kali-evo gh auth login      # GitHub.com, HTTPS, log in with the web browser
docker exec kali-evo gh auth status
```

The login is stored in the `kali-evo-gh` Docker volume, so it survives container recreates.

### 4.3 Clone, build, install

`/workspace` in the container is `lab/evo-workspace/` on the host (git-ignored).

```bash
docker exec -it kali-evo bash
  cd /workspace
  gh repo clone kaushithamsilva/evopentester
  gh repo clone kaviru2/pi-monorepo

  # ESO
  (cd evopentester && uv sync)

  # ACI: install only the ACI's workspace (see "Troubleshooting" for why), then build the 4 packages it uses.
  cd pi-monorepo
  npm install -w packages/autopentester --include-workspace-root
  (cd packages/tui          && npm run build)
  (cd packages/ai           && npx tsgo -p tsconfig.build.json)   # NOT `npm run build`: it regenerates the model catalog and breaks the type-check
  (cd packages/agent        && npm run build)
  (cd packages/coding-agent && npm run build)
  git status --short                                              # should print nothing
exit

# from the host: copy the lab campaign into the ESO clone (lab/ is not mounted in the container)
docker cp lab/evo/campaigns/lab-web.yaml kali-evo:/workspace/evopentester/config/campaigns/
```

npm 12 prints "install-scripts" warnings for `esbuild`, `koffi`, `protobufjs` and `ssh2`. Leaving them unapproved worked for us.

### 4.3.1 Campaign: `lab/evo/campaigns/lab-web.yaml`

Differences from the stock `web.yaml`: no port-8000 pin, scope `full-host` with network mode `direct`, goal text that tells the agent to discover the ports itself and that backends the app calls are part of it, and `target_root_count: 100` so the 25 cycles (not 3 admin paths) end the run. The model and ACI configs are the repo's own `config/llm/openrouter-qwen3.8-flash.yaml` and `config/aci/docker.yaml` (`base_url: http://localhost:3000`).

### 4.4 Start the ACI

```bash
docker exec kali-evo bash -c 'tmux new-session -d -s aci "cd /workspace/pi-monorepo/packages/autopentester && npm run serve 2>&1 | tee /workspace/aci-server.log"'
docker exec kali-evo bash -c 'sleep 8; tail -3 /workspace/aci-server.log; curl -s -o /dev/null -w "GET /jobs/none -> %{http_code}\n" localhost:3000/jobs/none'   # expect 404
```

The ACI settings (`ACI_PROVIDER=openrouter`, `ACI_MODEL_ID=qwen/qwen3.8-flash`, `ACI_OPENROUTER_PROVIDER=alibaba`, `ACI_MAX_STEPS`, `ACI_TIME_LIMIT`, `ACI_ARTIFACT_DIR=/workspace/aci-artifacts`) come from the `kali-evo` service in `lab/docker-compose.yml`.

### 4.5 Dry run (no LLM calls)

```bash
docker exec kali-evo bash -c 'cd /workspace/evopentester && uv run evopentester mock vuln-bank --aci-config config/aci/mock.yaml'
```

**Always pass `--aci-config`.** Without it, `mock` and `run` use `config/aci/default.yaml`, whose `base_url` is the authors' VM (`http://192.168.64.3:3000`), so actions fail with "could not reach ACI". Delete the mock run's folder from `evopentester/logs/` afterwards so it doesn't get mixed up with real runs.

### 4.6 Real run, one target at a time

Reset the targets first (section 2), then, with the ACI running:

```bash
docker exec kali-evo bash -c 'cd /workspace/evopentester && tmux new-session -d -s evo-vuln-bank \
  "uv run evopentester run vuln-bank \
     --llm-config config/llm/openrouter-qwen3.8-flash.yaml \
     --campaign config/campaigns/lab-web.yaml \
     --aci-config config/aci/docker.yaml \
     --max-cycles 25 2>&1 | tee /workspace/evo-vuln-bank.log"'
```

Repeat with `paygoat` and `xben-090` after another target reset. The ACI is shared, so run one target at a time (parallel runs would need separate ACI ports and separate target instances).

Expect a long run: we saw roughly 20 to 30 minutes of LLM planning per cycle plus the action itself, so 25 cycles takes many hours. The first ACI action cost about $0.01.

Watch it:

```bash
docker exec -it kali-evo tmux attach -t evo-vuln-bank        # detach: Ctrl-b then d
docker exec kali-evo bash -c 'cd /workspace/evopentester && uv run evopentester analyse progress'
docker exec kali-evo tail -f /workspace/aci-server.log
```

Resume after a crash: `uv run evopentester run vuln-bank ... --resume logs/<run_id>` (forks into a new run folder).

### 4.7 Results

Everything is on the host under `lab/evo-workspace/`:

- `evopentester/logs/<run_id>/`: `report.md`, `report.pdf`, `taxonomy_matrix.yaml`, `evo_log.jsonl`, `trace.log`, checkpoints.
- `aci-artifacts/`: raw tool output per action (can contain captured credentials from the lab targets; don't commit blindly).

Copy the report files to `experiments/<name>/<target>/raw/` with a `metadata.json` (see `experiments/evopentester-qwen/`). EvoPentester produces a report, not `findings.jsonl`, so scoring with ethibench needs a conversion step first (for example `ethibench convert-report`, which uses an LLM).

## 5. Troubleshooting (all hit while building this)

| Symptom | Cause / fix |
|---|---|
| `docker exec -it ...` fails with "the input device is not a TTY" | Run it in a normal terminal. A `!` command in Claude Code has no TTY. |
| zsh: `read: -p: no coprocess` | zsh syntax is `read -s "K?prompt: "`. |
| `gh repo clone` says not logged in after a recreate | The login now lives in the `kali-evo-gh` volume; if you changed the compose file, run `gh auth login` again once. |
| `npm install` fails: `EALLOWREMOTE ... xlsx@https://cdn.sheetjs.com/...` | npm 12 blocks URL dependencies; only `packages/web-ui` uses `xlsx`. Use the scoped install in 4.3. |
| Scoped install fails: `sh: husky: not found` | The root `prepare` script needs husky; add `--include-workspace-root`. |
| `packages/ai` build fails with `TS2536 ... 'TProvider' cannot be used to index` | `npm run build` regenerates `models.generated.ts` from live catalogs; the new file breaks the type-check. Restore with `git checkout -- packages/ai/src/*.generated.ts` and build with `npx tsgo -p tsconfig.build.json`. The committed catalog already includes `qwen/qwen3.8-flash`. |
| Action fails with "could not reach ACI service" at `192.168.64.3:3000` | Default ACI config points at the authors' VM. Pass `--aci-config config/aci/docker.yaml` (or `mock.yaml`). |
| opencode, key or login gone | `kali-attacker` was recreated. Reinstall opencode and log in again (section 3). |
| A target behaves oddly or already has users | Reset the targets (section 2). |
| PAYGoat: UI loads but nothing works | The UI calls `paygoat-api:3000`; the patch `paygoat-lab.patch` must be applied (`bash lab/targets/setup.sh`) before building. |
