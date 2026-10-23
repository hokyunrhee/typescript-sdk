/**
 * Type-checked examples for `stdio.ts`.
 *
 * These examples are synced into JSDoc comments via the sync-snippets script.
 * Each function's region markers define the code snippet that appears in the docs.
 *
 * @module
 */

import { McpServer } from './mcp';
import { StdioServerTransport } from './stdio';

/**
 * Example: Basic stdio transport usage.
 */
async function StdioServerTransport_basicUsage() {
    //#region StdioServerTransport_basicUsage
    const server = new McpServer({ name: 'my-server', version: '1.0.0' });
    // A message larger than 4 MB closes the transport with an error.
    const transport = new StdioServerTransport(process.stdin, process.stdout, { maxBufferSize: 4 * 1024 * 1024 });
    await server.connect(transport);
    //#endregion StdioServerTransport_basicUsage
}
