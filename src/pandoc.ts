import * as vscode from 'vscode';
import * as path from 'path';
import { spawn } from 'child_process';

type Format = 'docx' | 'html' | 'pdf';

export async function convertMarkdown(uri: vscode.Uri, format: Format, isFolderConversion: boolean = false): Promise<void> {
  const cfg = vscode.workspace.getConfiguration('pandoc');
  const pandocPath = (cfg.get<string>('path') || '').trim() || 'pandoc';

  await ensurePandocAvailable(pandocPath);

  const input = uri.fsPath;
  const outputDirSetting = (cfg.get<string>('outputDir') || '').trim();
  const outputDir = isFolderConversion 
    ? resolveOutputDir(outputDirSetting, path.dirname(input))
    : resolveOutputDir(outputDirSetting, input);
  const baseName = isFolderConversion 
    ? path.basename(path.dirname(input))
    : path.basename(input, path.extname(input));
  const output = path.join(outputDir, `${baseName}.${format}`);
  const args = buildArgsForFormat(cfg, format, input, output, uri, isFolderConversion);
  const cwd = path.dirname(input);
  await runProcess(pandocPath, args, cwd, isFolderConversion);

  await vscode.env.openExternal(vscode.Uri.file(output));
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

function buildArgsForFormat(cfg: vscode.WorkspaceConfiguration, fmt: Format, input: string, output: string, uri: vscode.Uri, isFolderConversion: boolean): string[] {
  const defaultArgs = ["--from=markdown+hard_line_breaks"];
  const customArgs = cfg.get<string[]>(`${fmt}.customArgs`) || [];
  
  // Merge with single file or multiple files custom args based on conversion type
  const contextSpecificArgs = isFolderConversion
    ? cfg.get<string[]>(`${fmt}.multipleFilesCustomArgs`) || []
    : cfg.get<string[]>(`${fmt}.singleFileCustomArgs`) || [];
  
  const mergedArgs = [...customArgs, ...contextSpecificArgs];
  const resolvedArgs = mergedArgs.map(arg => resolveVariables(arg, uri));
  const args: string[] = [...defaultArgs, ...resolvedArgs, '-o', output, input];
  return args;
}

function resolveVariables(text: string, uri: vscode.Uri): string {
  const folder = vscode.workspace.getWorkspaceFolder(uri);
  const workspaceFolder = folder?.uri.fsPath || path.dirname(uri.fsPath);
  
  return text
    .replace(/\$\{workspaceFolder\}/g, workspaceFolder)
    .replace(/\$\{workspaceFolderBasename\}/g, path.basename(workspaceFolder));
}

function runProcess(cmd: string, args: string[], cwd?: string, useShell: boolean = false): Promise<void> {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { cwd, shell: useShell });
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
