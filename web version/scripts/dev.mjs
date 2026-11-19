// `npm run dev`: starts the website (Vite, :5173) and the PHP back office
// (php -S, :4000) together. Ctrl+C stops both.
import { spawn } from "node:child_process";
import path from "node:path";

// Local test data goes to .local-data/, NOT public/api/data/ — otherwise it
// would be copied into dist/ and could overwrite the real data on upload.
process.env.MAKKAH_DATA_DIR = path.resolve(".local-data");

const isWin = process.platform === "win32";
const npm = isWin ? "npm.cmd" : "npm";

const procs = [
  ["site ", "dev:site", "\x1b[36m"],
  ["admin", "dev:admin", "\x1b[33m"],
].map(([name, script, color]) => {
  const child = spawn(npm, ["run", "--silent", script], { stdio: ["inherit", "pipe", "pipe"], shell: isWin });
  const prefix = `${color}[${name}]\x1b[0m `;
  const pipe = (stream, out) =>
    stream.on("data", (chunk) => {
      for (const line of chunk.toString().split(/\r?\n/)) if (line.trim()) out.write(prefix + line + "\n");
    });
  pipe(child.stdout, process.stdout);
  pipe(child.stderr, process.stderr);
  child.on("exit", (code) => {
    console.log(`${prefix}exited (${code ?? "signal"})`);
    stopAll();
  });
  return child;
});

let stopping = false;
function stopAll() {
  if (stopping) return;
  stopping = true;
  for (const p of procs) {
    if (p.exitCode !== null) continue;
    if (isWin) spawn("taskkill", ["/pid", String(p.pid), "/T", "/F"], { stdio: "ignore" });
    else p.kill("SIGTERM");
  }
  setTimeout(() => process.exit(0), 300);
}

process.on("SIGINT", stopAll);
process.on("SIGTERM", stopAll);
