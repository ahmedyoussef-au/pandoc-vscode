import * as vscode from 'vscode';
import { convertMarkdown } from './pandoc';

export function activate(context: vscode.ExtensionContext) {
  const register = (cmd: string, fmt: 'docx' | 'html' | 'pdf') =>
    vscode.commands.registerCommand(cmd, async (resource?: vscode.Uri) => {
      try {
        const uri = await getMarkdownUri(resource);
        if (!uri) {
          return;
        }
        await convertMarkdown(uri, fmt);
      } catch (err: any) {
        vscode.window.showErrorMessage(err?.message || String(err));
      }
    });

  context.subscriptions.push(
    register('pandoc.convertToDocx', 'docx'),
    register('pandoc.convertToHtml', 'html'),
    register('pandoc.convertToPdf', 'pdf')
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

export function deactivate() {}
