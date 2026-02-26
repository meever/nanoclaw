import { exec, execFile } from 'child_process';
import fs from 'fs';
import path from 'path';

import { DATA_DIR, PROJECT_ROOT } from './config.js';
import { logger } from './logger.js';

export interface SelfUpdateResult {
  prUrl?: string;
  error?: string;
}

/**
 * Spawns a Claude Code developer subagent on the host to implement a requested
 * change, create a branch, and open a PR. Returns the PR URL when done.
 */
export async function runSelfUpdateAgent(
  description: string,
  onStatus?: (msg: string) => void,
): Promise<SelfUpdateResult> {
  const claudeBin = process.env.CLAUDE_BIN || 'claude';
  const branch = `feature/nanoclaw-self-update-${Date.now()}`;

  const prompt = `You are a developer working on the NanoClaw codebase. Your task is:

${description}

Instructions:
1. Create and checkout a new branch named: ${branch}
2. Explore the codebase to understand the relevant code
3. Implement the requested change
4. Run \`npm run build\` and ensure it succeeds
5. Run \`npm test\` if tests exist and ensure they pass
6. Commit your changes with a descriptive message
7. Push the branch to origin
8. Create a PR with \`gh pr create\` — do NOT merge to main
9. Output the PR URL as the final line of your response

IMPORTANT: Do not merge to main. Only create a PR.`;

  onStatus?.('Starting developer subagent...');

  return new Promise((resolve) => {
    const child = execFile(
      claudeBin,
      ['-p', prompt, '--output-format', 'text', '--max-turns', '50'],
      {
        cwd: PROJECT_ROOT,
        env: process.env,
        maxBuffer: 10 * 1024 * 1024, // 10MB
      },
      (error, stdout, stderr) => {
        if (error) {
          logger.error({ error, stderr }, 'Self-update agent failed');
          resolve({ error: `Developer subagent failed: ${error.message}` });
          return;
        }

        const output = stdout.trim();
        logger.info({ output: output.slice(0, 500) }, 'Self-update agent completed');

        // Extract PR URL from output
        const prMatch = output.match(/https:\/\/github\.com\/[^\s]+\/pull\/\d+/);
        if (prMatch) {
          resolve({ prUrl: prMatch[0] });
        } else {
          resolve({
            error: `Agent finished but no PR URL found. Output: ${output.slice(0, 300)}`,
          });
        }
      },
    );

    child.stderr?.on('data', (data: Buffer) => {
      logger.debug({ data: data.toString() }, 'Self-update agent stderr');
    });
  });
}

/**
 * Pulls main, rebuilds, and restarts the NanoClaw service.
 * Writes a flag file first so the next startup sends "back online".
 * Uses exec() — the process will die during restart, that's expected.
 */
export function runSelfRestart(onMessage: (msg: string) => void): void {
  const flagFile = path.join(DATA_DIR, '.self_restart_pending');

  try {
    fs.writeFileSync(flagFile, new Date().toISOString(), 'utf-8');
  } catch (err) {
    logger.error({ err }, 'Failed to write self_restart_pending flag');
  }

  const restartCmd =
    process.env.NANOCLAW_RESTART_CMD || 'systemctl --user restart nanoclaw';

  onMessage('Pulling main and restarting...');

  exec(
    `git -C "${PROJECT_ROOT}" pull origin main && npm --prefix "${PROJECT_ROOT}" run build && ${restartCmd}`,
    { env: process.env },
    (error) => {
      if (error) {
        logger.error({ error }, 'Self-restart sequence failed');
      }
    },
  );
}
