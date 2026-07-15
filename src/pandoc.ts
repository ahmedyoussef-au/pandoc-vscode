import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';
import { spawn } from 'child_process';

type Format = 'docx' | 'html' | 'pdf';

export async function convertMarkdown(uri: vscode.Uri, format: Format, isFolderConversion: boolean = false, extensionPath: string = ''): Promise<void> {
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
  const args = buildArgsForFormat(cfg, format, input, output, uri, isFolderConversion, extensionPath);
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

function buildArgsForFormat(cfg: vscode.WorkspaceConfiguration, fmt: Format, input: string, output: string, uri: vscode.Uri, isFolderConversion: boolean, extensionPath: string): string[] {
  const defaultArgs = ["--from=markdown+hard_line_breaks"];
  
  const filterArgs = resolveFilterArgs(cfg, extensionPath, uri);
  
  const commonArgs = cfg.get<string[]>(`${fmt}.commonArgs`);
  const customArgs = cfg.get<string[]>(`${fmt}.customArgs`) || [];
  const baseArgs = (commonArgs && commonArgs.length > 0) ? commonArgs : customArgs;
  
  // Merge with single file or multiple files custom args based on conversion type
  const contextSpecificArgs = isFolderConversion
    ? cfg.get<string[]>(`${fmt}.multipleFilesCustomArgs`) || []
    : cfg.get<string[]>(`${fmt}.singleFileCustomArgs`) || [];
  
  const mergedArgs = [...baseArgs, ...contextSpecificArgs];
  const templateArgs = resolveTemplateArgs(cfg, fmt, mergedArgs, uri, isFolderConversion);
  const resolvedArgs = mergedArgs.map(arg => resolveVariables(arg, uri));
  const args: string[] = [...defaultArgs, ...filterArgs, ...templateArgs, ...resolvedArgs, '-o', output, input];
  return args;
}

function resolveTemplateArgs(cfg: vscode.WorkspaceConfiguration, fmt: Format, existingArgs: string[], uri: vscode.Uri, isFolderConversion: boolean): string[] {
  const folderTemplate = isFolderConversion
    ? (cfg.get<string>(`${fmt}.multipleFilesTemplate`) || '').trim()
    : '';
  const template = folderTemplate || (cfg.get<string>(`${fmt}.template`) || '').trim();
  if (!template) {
    return [];
  }

  const optionNames = fmt === 'docx'
    ? ['--reference-doc', '--reference-docx']
    : ['--template'];

  if (hasPandocOption(existingArgs, optionNames)) {
    return [];
  }

  const optionName = optionNames[0];
  return [`${optionName}=${resolvePathSetting(template, uri)}`];
}

function hasPandocOption(args: string[], optionNames: string[]): boolean {
  return args.some((arg, index) => optionNames.some(optionName =>
    arg === optionName ||
    arg.startsWith(`${optionName}=`) ||
    args[index - 1] === optionName
  ));
}

function resolvePathSetting(setting: string, uri: vscode.Uri): string {
  const resolved = resolveVariables(setting, uri);
  if (path.isAbsolute(resolved)) {
    return resolved;
  }

  const folder = vscode.workspace.getWorkspaceFolder(uri);
  const workspaceFolder = folder?.uri.fsPath || path.dirname(uri.fsPath);
  return path.resolve(workspaceFolder, resolved);
}

function resolveFilterArgs(cfg: vscode.WorkspaceConfiguration, extensionPath: string, uri: vscode.Uri): string[] {
  const filters = cfg.get<string[]>('filters') || [];
  const folder = vscode.workspace.getWorkspaceFolder(uri);
  const workspacePath = folder?.uri.fsPath || path.dirname(uri.fsPath);
  const args: string[] = [];

  for (const entry of filters) {
    let filterPath: string;

    if (entry.startsWith('builtin:')) {
      const name = entry.slice('builtin:'.length);
      filterPath = path.join(extensionPath, 'pandoc', 'filters', `${name}.lua`);
    } else {
      filterPath = entry.replace(/\$\{workspaceFolder\}/g, workspacePath);
    }

    if (!fs.existsSync(filterPath)) {
      vscode.window.showWarningMessage(`Pandoc filter not found: ${filterPath}`);
      continue;
    }

    args.push(`--lua-filter=${filterPath}`);
  }

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
