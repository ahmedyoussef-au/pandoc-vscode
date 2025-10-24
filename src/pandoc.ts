import * as vscode from 'vscode';
import * as path from 'path';
import { spawn } from 'child_process';

type Format = 'docx' | 'html' | 'pdf';

export async function convertMarkdown(uri: vscode.Uri, format: Format): Promise<void> {
  const cfg = vscode.workspace.getConfiguration('pandoc');
  const pandocPath = (cfg.get<string>('path') || '').trim() || 'pandoc';

  await ensurePandocAvailable(pandocPath);

  const input = uri.fsPath;
  const outputDirSetting = (cfg.get<string>('outputDir') || '').trim();
  const outputDir = resolveOutputDir(outputDirSetting, input);
  const baseName = path.basename(input, path.extname(input));
  const output = path.join(outputDir, `${baseName}.${format}`);

  const args = buildArgsForFormat(cfg, format, input, output);
  await runProcess(pandocPath, args, path.dirname(input));

  await vscode.commands.executeCommand('vscode.open', vscode.Uri.file(output));
  vscode.window.showInformationMessage(`Converted to ${format.toUpperCase()}: ${output}`);
}

function resolveOutputDir(setting: string, inputPath: string): string {
  if (!setting) {
    return path.dirname(inputPath);
  }
  if (path.isAbsolute(setting)) {
    return setting;
  }
  const folder = vscode.workspace.getWorkspaceFolder(vscode.Uri.file(inputPath));
  const base = folder?.uri.fsPath || path.dirname(inputPath);
  return path.resolve(base, setting);
}

async function ensurePandocAvailable(pandocPath: string): Promise<void> {
  try {
    await runProcess(pandocPath, ['--version']);
  } catch (err) {
    const choice = await vscode.window.showErrorMessage(
      'Pandoc not found. Please install Pandoc and ensure it is on your PATH, or set pandoc.path in settings.',
      'Open Installation Guide'
    );
    if (choice === 'Open Installation Guide') {
      await vscode.env.openExternal(vscode.Uri.parse('https://pandoc.org/installing.html'));
    }
    throw err;
  }
}

function buildArgsForFormat(cfg: vscode.WorkspaceConfiguration, fmt: Format, input: string, output: string): string[] {
  const args: string[] = [];
  
  if (fmt === 'docx') {
    const ref = (cfg.get<string>('docx.referenceDoc') || '').trim();
    const number = !!cfg.get<boolean>('docx.numberSections');
    const extra = cfg.get<string[]>('docx.customArgs') || [];
    if (ref) {
      args.push(`--reference-doc=${ref}`);
    }
    if (number) {
      args.push('--number-sections');
    }
    args.push(...extra);
  } else if (fmt === 'html') {
    const standalone = cfg.get<boolean>('html.standalone', true);
    const css = cfg.get<string[]>('html.css') || [];
    const extra = cfg.get<string[]>('html.customArgs') || [];
    if (standalone) {
      args.push('--standalone');
    }
    for (const c of css) {
      if (c && c.trim()) {
        args.push(`--css=${c}`);
      }
    }
    args.push(...extra);
  } else if (fmt === 'pdf') {
    const engine = (cfg.get<string>('pdf.pdfEngine') || '').trim();
    const number = !!cfg.get<boolean>('pdf.numberSections');
    const extra = cfg.get<string[]>('pdf.customArgs') || [];
    if (engine) {
      args.push('--pdf-engine', engine);
    }
    if (number) {
      args.push('--number-sections');
    }
    args.push(...extra);
  }
  
  args.push('-o', output);
  args.push(input);
  return args;
}

function runProcess(cmd: string, args: string[], cwd?: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { cwd, shell: false });
    let stderr = '';
    child.stderr.on('data', d => (stderr += d.toString()));
    child.on('error', err => reject(err));
    child.on('close', code => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(stderr || `Command failed with exit code ${code}`));
      }
    });
  });
}
