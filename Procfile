blockchain: cd blockchain && trap 'kill %1 ; fablo prune' EXIT > /dev/null; set -m; fablo recreate && top & wait %1
frontend: cd frontend && npm run dev
backend: cd backend && go run .
