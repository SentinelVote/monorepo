## Quickstart

### Steps

1. Have dependencies installed (node, go, docker)
2. Prepare four different linux/unix terminals (wsl2/bash/etc).

### Commands

> This is not a shell script.
> \
> You can copy and paste commands one by one,
> \
> but not all at once.

Using a linux/unix terminal:

```sh
git clone --recurse-submodules --remote-submodules git@github.com:SentinelVote/monorepo.git

# Setup Hyperledger Fabric.
cd monorepo/blockchain
./setup-fablo.sh
./fablo.sh generate
./fablo.sh up
# Wait for the blockchain to finish setting up.
# Don't start the frontend or backend yet.

# Open another terminal.
# Setup for backend (Golang Chi)
cd monorepo/backend
go run . --schema simulation-full --users 20

# Open another terminal.
# Setup for frontend (Next.js)
cd monorepo/frontend
npm install
npm run dev

# Open another terminal.
# Simulate the voting (Playwright)
cd monorepo/frontend

# Serial test (one by one).
PLAYWRIGHT_USER_START_FROM=1 PLAYWRIGHT_USER_END_AT=20 npx playwright test tests/e2e-serial.spec.ts

# Parallel test (all at once).
PLAYWRIGHT_USER_START_FROM=1 PLAYWRIGHT_USER_END_AT=20 npx playwright test tests/e2e-parallel.spec.ts
```
