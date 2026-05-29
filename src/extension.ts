import * as vscode from 'vscode';
import { convertMarkdown } from './pandoc';
import * as fs from 'fs';
import * as path from 'path';

export function activate(context: vscode.ExtensionContext) {
  const extensionPath = context.extensionUri.fsPath;

  const registerActiveFile = (cmd: string, fmt: 'docx' | 'html' | 'pdf') =>
    vscode.commands.registerCommand(cmd, async (resource?: vscode.Uri) => {
      try {
        const uri = await getMarkdownUri(resource);
        if (!uri) {
          return;
        }
        await convertMarkdown(uri, fmt, false, extensionPath);
      } catch (err: any) {
        vscode.window.showErrorMessage(err?.message || String(err));
      }
    });

  const registerFolder = (cmd: string, fmt: 'docx' | 'html' | 'pdf') =>
    vscode.commands.registerCommand(cmd, async (folderUri?: vscode.Uri) => {
      try {
        if (!folderUri) {
          vscode.window.showWarningMessage('No folder selected.');
          return;
        }

        const folderStat = await vscode.workspace.fs.stat(folderUri);
        if (folderStat.type !== vscode.FileType.Directory) {
          vscode.window.showWarningMessage('Please select a folder.');
          return;
        }

        const mdFiles = await findMarkdownFiles(folderUri.fsPath);        
        if (mdFiles.length === 0) {
          vscode.window.showInformationMessage('No Markdown files found in this folder.');
          return;
        }
        
        // Create a glob pattern URI for the folder
        const globPattern = path.join(folderUri.fsPath, '*.md');
        const patternUri = vscode.Uri.file(globPattern);
        await convertMarkdown(patternUri, fmt, true, extensionPath);
      } catch (err: any) {
        vscode.window.showErrorMessage(err?.message || String(err));
      }
    });

  const generateSample = vscode.commands.registerCommand('pandoc.generateSampleMarkdown', async () => {
    const folder = vscode.workspace.workspaceFolders?.[0];
    if (!folder) {
      vscode.window.showWarningMessage('Please open a workspace folder first.');
      return;
    }

    const sampleSource = path.join(extensionPath, 'assets', 'samples', 'pandoc-sample.md');
    const filePath = path.join(folder.uri.fsPath, 'pandoc-sample.md');
    const content = await fs.promises.readFile(sampleSource, 'utf8');

    await fs.promises.writeFile(filePath, content, 'utf8');
    const doc = await vscode.workspace.openTextDocument(filePath);
    await vscode.window.showTextDocument(doc);
  });

  context.subscriptions.push(
    registerActiveFile('pandoc.convertToDocx', 'docx'),
    registerActiveFile('pandoc.convertToHtml', 'html'),
    registerActiveFile('pandoc.convertToPdf', 'pdf'),
    registerFolder('pandoc.convertFolderToDocx', 'docx'),
    registerFolder('pandoc.convertFolderToHtml', 'html'),
    registerFolder('pandoc.convertFolderToPdf', 'pdf'),
    generateSample
  );
}

async function getMarkdownUri(resource?: vscode.Uri): Promise<vscode.Uri | undefined> {
  let uri = resource;
  if (!uri) {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
      vscode.window.showWarningMessage('No active editor.');
      return;
    }
    uri = editor.document.uri;
  }
  
  // Skip validation for glob patterns
  const isGlob = uri.fsPath.includes('*');
  if (isGlob) {
    return uri;
  }
  
  const doc = await vscode.workspace.openTextDocument(uri);
  const isMd = doc.languageId === 'markdown' || uri.fsPath.toLowerCase().endsWith('.md');
  if (!isMd) {
    vscode.window.showWarningMessage('Please select a Markdown (.md) file.');
    return;
  }
  
  if (doc.isDirty) {
    const ok = await doc.save();
    if (!ok) {
      vscode.window.showWarningMessage('Please save the document before converting.');
      return;
    }
  }
  
  return uri;
}

async function findMarkdownFiles(dirPath: string): Promise<string[]> {
  const mdFiles: string[] = [];

  async function walk(dir: string): Promise<void> {
    const entries = await fs.promises.readdir(dir, { withFileTypes: true });
    
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      
      if (entry.isDirectory()) {
        await walk(fullPath);
      } else if (entry.isFile() && entry.name.toLowerCase().endsWith('.md')) {
        mdFiles.push(fullPath);
      }
    }
  }

  await walk(dirPath);
  return mdFiles;
}

export function deactivate() {}
