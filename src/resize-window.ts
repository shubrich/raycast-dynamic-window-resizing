import { closeMainWindow, environment, showHUD } from "@raycast/api";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { existsSync } from "node:fs";
import { join } from "node:path";

const run = promisify(execFile);

export default async function Command() {
  await closeMainWindow();

  const helper = join(environment.assetsPath, "window-resize-helper");

  if (!existsSync(helper)) {
    await showHUD("Helper binary missing — run `npm run build:helper`");
    return;
  }

  try {
    await run(helper, [], { timeout: 60_000 });
  } catch (err) {
    const stderr = (err as { stderr?: string }).stderr ?? "";
    if (stderr.includes("accessibility-not-granted")) {
      await showHUD("Grant Raycast Accessibility access in System Settings");
    } else if (stderr.includes("no-window")) {
      await showHUD("No active window to resize");
    } else if (stderr.includes("no-size")) {
      await showHUD("Active window is not resizable");
    } else if ((err as { killed?: boolean }).killed) {
      // Hit the 60s safety timeout — treat as a normal exit.
    } else {
      await showHUD(`Resize helper failed: ${stderr.trim() || (err as Error).message}`);
    }
  }
}
