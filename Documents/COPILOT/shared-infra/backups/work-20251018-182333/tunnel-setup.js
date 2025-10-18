#!/usr/bin/env node

/**
 * Shared Tunnel Setup Script
 * Universal ngrok tunnel configuration for all Perplexity spaces
 * Provides secure external access while maintaining space isolation
 */

import { spawn } from 'child_process';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

// ES Module dirname equivalent
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configuration
const COPILOT_PORT = process.env.COPILOT_PORT || 4000;
const SPACE_NAME = process.env.SPACE_NAME || 'unknown-space';
const TUNNEL_SUBDOMAIN = process.env.TUNNEL_SUBDOMAIN || `${SPACE_NAME}-copilot`;
const LOG_FILE = path.join(__dirname, 'tunnel.log');

class TunnelManager {
    constructor() {
        this.tunnelProcess = null;
        this.tunnelUrl = null;
        this.isConnected = false;
    }

    async log(level, message, data = {}) {
        const timestamp = new Date().toISOString();
        const logEntry = `${timestamp} [${level}] [${SPACE_NAME}] ${message} ${JSON.stringify(data)}\n`;
        
        console.log(`[${level}] ${message}`, data);
        
        try {
            await fs.appendFile(LOG_FILE, logEntry);
        } catch (error) {
            console.warn(`Failed to write to log file: ${error.message}`);
        }
    }

    async checkNgrokInstallation() {
        return new Promise((resolve) => {
            const ngrok = spawn('ngrok', ['--version'], { stdio: 'pipe' });
            
            ngrok.on('close', (code) => {
                resolve(code === 0);
            });
            
            ngrok.on('error', () => {
                resolve(false);
            });
        });
    }

    async startTunnel() {
        try {
            await this.log('INFO', 'Starting tunnel setup', {
                port: COPILOT_PORT,
                space: SPACE_NAME,
                subdomain: TUNNEL_SUBDOMAIN
            });

            // Check if ngrok is installed
            const ngrokInstalled = await this.checkNgrokInstallation();
            if (!ngrokInstalled) {
                throw new Error('ngrok is not installed or not in PATH');
            }

            // Build ngrok command
            const ngrokArgs = ['http', COPILOT_PORT];
            
            // Add subdomain if specified and available
            if (TUNNEL_SUBDOMAIN && TUNNEL_SUBDOMAIN !== 'unknown-space-copilot') {
                ngrokArgs.push('--subdomain', TUNNEL_SUBDOMAIN);
            }

            // Add region if specified
            if (process.env.TUNNEL_REGION) {
                ngrokArgs.push('--region', process.env.TUNNEL_REGION);
            }

            await this.log('INFO', 'Starting ngrok tunnel', { args: ngrokArgs });

            // Start ngrok process
            this.tunnelProcess = spawn('ngrok', ngrokArgs, {
                stdio: ['ignore', 'pipe', 'pipe']
            });

            // Handle tunnel process events
            this.tunnelProcess.stdout.on('data', (data) => {
                const output = data.toString();
                console.log('ngrok stdout:', output);
                this.parseNgrokOutput(output);
            });

            this.tunnelProcess.stderr.on('data', (data) => {
                const error = data.toString();
                console.error('ngrok stderr:', error);
                this.log('ERROR', 'ngrok stderr', { error });
            });

            this.tunnelProcess.on('close', async (code) => {
                this.isConnected = false;
                await this.log('WARN', 'ngrok process closed', { code });
                
                if (code !== 0) {
                    await this.log('ERROR', 'ngrok exited with error', { code });
                }
            });

            this.tunnelProcess.on('error', async (error) => {
                await this.log('ERROR', 'Failed to start ngrok', { error: error.message });
                throw error;
            });

            // Wait for tunnel to establish
            await this.waitForTunnelConnection();

            return {
                url: this.tunnelUrl,
                port: COPILOT_PORT,
                space: SPACE_NAME,
                subdomain: TUNNEL_SUBDOMAIN
            };

        } catch (error) {
            await this.log('ERROR', 'Tunnel setup failed', { error: error.message });
            throw error;
        }
    }

    parseNgrokOutput(output) {
        // Look for tunnel URL in ngrok output
        const urlMatch = output.match(/https:\/\/[^\s]+\.ngrok\.io/);
        if (urlMatch && !this.tunnelUrl) {
            this.tunnelUrl = urlMatch[0];
            this.isConnected = true;
            this.log('SUCCESS', 'Tunnel established', {
                url: this.tunnelUrl,
                port: COPILOT_PORT,
                space: SPACE_NAME
            });
        }
    }

    async waitForTunnelConnection(timeout = 30000) {
        const startTime = Date.now();
        
        return new Promise((resolve, reject) => {
            const checkConnection = () => {
                if (this.isConnected && this.tunnelUrl) {
                    resolve();
                } else if (Date.now() - startTime > timeout) {
                    reject(new Error('Tunnel connection timeout'));
                } else {
                    setTimeout(checkConnection, 1000);
                }
            };
            
            checkConnection();
        });
    }

    async stopTunnel() {
        if (this.tunnelProcess) {
            await this.log('INFO', 'Stopping tunnel', { space: SPACE_NAME });
            
            this.tunnelProcess.kill('SIGTERM');
            
            // Wait for process to exit
            return new Promise((resolve) => {
                this.tunnelProcess.on('close', () => {
                    this.tunnelProcess = null;
                    this.tunnelUrl = null;
                    this.isConnected = false;
                    resolve();
                });
                
                // Force kill if it doesn't exit gracefully
                setTimeout(() => {
                    if (this.tunnelProcess) {
                        this.tunnelProcess.kill('SIGKILL');
                    }
                    resolve();
                }, 5000);
            });
        }
    }

    async updateEnvironment() {
        if (!this.tunnelUrl) {
            throw new Error('No tunnel URL available');
        }

        try {
            // Update .env file with tunnel URL
            const envPath = path.join(__dirname, '.env');
            let envContent = '';

            // Read existing .env file if it exists
            try {
                envContent = await fs.readFile(envPath, 'utf8');
            } catch (error) {
                // File doesn't exist, start fresh
            }

            // Update or add TUNNEL_URL
            const tunnelUrlLine = `TUNNEL_URL=${this.tunnelUrl}`;
            
            if (envContent.includes('TUNNEL_URL=')) {
                envContent = envContent.replace(/TUNNEL_URL=.*/, tunnelUrlLine);
            } else {
                envContent += `\n${tunnelUrlLine}\n`;
            }

            await fs.writeFile(envPath, envContent);
            
            await this.log('INFO', 'Environment updated', {
                tunnelUrl: this.tunnelUrl,
                envPath: envPath
            });

        } catch (error) {
            await this.log('ERROR', 'Failed to update environment', { error: error.message });
        }
    }

    async getTunnelStatus() {
        return {
            isConnected: this.isConnected,
            tunnelUrl: this.tunnelUrl,
            port: COPILOT_PORT,
            space: SPACE_NAME,
            processId: this.tunnelProcess?.pid || null
        };
    }
}

// CLI interface
async function main() {
    console.log('🚇 Shared Tunnel Setup - Universal ngrok Configuration');
    console.log(`📍 Space: ${SPACE_NAME}`);
    console.log(`🔗 Port: ${COPILOT_PORT}`);
    console.log(`🏷️  Subdomain: ${TUNNEL_SUBDOMAIN}\n`);

    const tunnel = new TunnelManager();

    // Handle process signals
    process.on('SIGINT', async () => {
        console.log('\n🛑 Received SIGINT, stopping tunnel...');
        await tunnel.stopTunnel();
        process.exit(0);
    });

    process.on('SIGTERM', async () => {
        console.log('\n🛑 Received SIGTERM, stopping tunnel...');
        await tunnel.stopTunnel();
        process.exit(0);
    });

    try {
        // Start the tunnel
        const result = await tunnel.startTunnel();
        
        console.log('\n✅ Tunnel Setup Complete!');
        console.log(`🌐 Public URL: ${result.url}`);
        console.log(`🔗 Local URL: http://localhost:${result.port}`);
        console.log(`📍 Space: ${result.space}`);
        console.log(`📋 Subdomain: ${result.subdomain}`);
        
        // Update environment file
        await tunnel.updateEnvironment();
        
        // Keep the process running
        console.log('\n🔄 Tunnel is running. Press Ctrl+C to stop.');
        
        // Health check loop
        setInterval(async () => {
            const status = await tunnel.getTunnelStatus();
            if (!status.isConnected) {
                console.log('⚠️  Tunnel connection lost');
                process.exit(1);
            }
        }, 30000);
        
        // Keep process alive
        process.stdin.resume();
        
    } catch (error) {
        console.error('\n❌ Tunnel setup failed:', error.message);
        
        if (error.message.includes('ngrok is not installed')) {
            console.log('\n💡 To install ngrok:');
            console.log('   npm install -g ngrok');
            console.log('   # or');
            console.log('   brew install ngrok/ngrok/ngrok');
        }
        
        process.exit(1);
    }
}

// Export for programmatic use
export { TunnelManager };

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
    main().catch(console.error);
}