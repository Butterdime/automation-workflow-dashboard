#!/usr/bin/env node

/**
 * Shared Smoke Test Suite
 * Universal testing for all Perplexity spaces
 * Validates Copilot agent, tunnel, and Slack integration
 */

import { fileURLToPath } from 'url';
import path from 'path';
import fs from 'fs/promises';

// ES Module dirname equivalent
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configuration
const COPILOT_PORT = process.env.COPILOT_PORT || 4000;
const SPACE_NAME = process.env.SPACE_NAME || 'unknown-space';
const WEBHOOK_PORT = process.env.WEBHOOK_PORT || 3000;
const TUNNEL_URL = process.env.TUNNEL_URL;
const SLACK_BOT_TOKEN = process.env.SLACK_BOT_TOKEN;

class SmokeTestSuite {
    constructor() {
        this.tests = [];
        this.results = [];
        this.startTime = Date.now();
    }

    async log(level, message, data = {}) {
        const timestamp = new Date().toISOString();
        console.log(`[${level}] ${message}`, data);
        
        // Log to file
        const logEntry = `${timestamp} [${level}] [${SPACE_NAME}] ${message} ${JSON.stringify(data)}\n`;
        try {
            await fs.appendFile(path.join(__dirname, 'smoke-test.log'), logEntry);
        } catch (error) {
            // Fail silently
        }
    }

    addTest(name, testFn, timeout = 30000) {
        this.tests.push({ name, testFn, timeout });
    }

    async runTest(test) {
        const startTime = Date.now();
        
        try {
            await this.log('INFO', `Starting test: ${test.name}`);
            
            // Run test with timeout
            const timeoutPromise = new Promise((_, reject) => {
                setTimeout(() => reject(new Error('Test timeout')), test.timeout);
            });
            
            await Promise.race([test.testFn(), timeoutPromise]);
            
            const duration = Date.now() - startTime;
            const result = { name: test.name, status: 'PASS', duration, error: null };
            
            this.results.push(result);
            await this.log('SUCCESS', `Test passed: ${test.name}`, { duration });
            
            return result;
            
        } catch (error) {
            const duration = Date.now() - startTime;
            const result = { name: test.name, status: 'FAIL', duration, error: error.message };
            
            this.results.push(result);
            await this.log('ERROR', `Test failed: ${test.name}`, { error: error.message, duration });
            
            return result;
        }
    }

    async makeHttpRequest(url, options = {}) {
        const { default: fetch } = await import('node-fetch');
        
        const defaultOptions = {
            method: 'GET',
            timeout: 10000,
            headers: {
                'Content-Type': 'application/json',
                'User-Agent': `SmokeTest/${SPACE_NAME}`
            }
        };
        
        const finalOptions = { ...defaultOptions, ...options };
        
        const response = await fetch(url, finalOptions);
        return response;
    }

    async runAllTests() {
        await this.log('INFO', `Starting smoke test suite for space: ${SPACE_NAME}`, {
            totalTests: this.tests.length,
            copilotPort: COPILOT_PORT,
            webhookPort: WEBHOOK_PORT
        });

        for (const test of this.tests) {
            await this.runTest(test);
        }

        return this.generateReport();
    }

    generateReport() {
        const endTime = Date.now();
        const totalDuration = endTime - this.startTime;
        const passCount = this.results.filter(r => r.status === 'PASS').length;
        const failCount = this.results.filter(r => r.status === 'FAIL').length;
        
        const report = {
            space: SPACE_NAME,
            timestamp: new Date().toISOString(),
            summary: {
                total: this.results.length,
                passed: passCount,
                failed: failCount,
                successRate: this.results.length > 0 ? (passCount / this.results.length) * 100 : 0,
                totalDuration
            },
            results: this.results,
            environment: {
                copilotPort: COPILOT_PORT,
                webhookPort: WEBHOOK_PORT,
                tunnelUrl: TUNNEL_URL || 'not-configured',
                nodeVersion: process.version
            }
        };
        
        return report;
    }
}

// Define standard smoke tests
async function defineTests(suite) {
    
    // Test 1: Copilot Agent Health Check
    suite.addTest('Copilot Agent Health Check', async () => {
        const url = `http://localhost:${COPILOT_PORT}/health`;
        const response = await suite.makeHttpRequest(url);
        
        if (!response.ok) {
            throw new Error(`Health check failed: ${response.status} ${response.statusText}`);
        }
        
        const data = await response.json();
        
        if (data.status !== 'healthy') {
            throw new Error(`Unhealthy status: ${data.status}`);
        }
        
        if (data.space !== SPACE_NAME) {
            throw new Error(`Space mismatch: expected ${SPACE_NAME}, got ${data.space}`);
        }
    });
    
    // Test 2: Copilot Processing Endpoint
    suite.addTest('Copilot Processing Endpoint', async () => {
        const url = `http://localhost:${COPILOT_PORT}/process`;
        const response = await suite.makeHttpRequest(url, {
            method: 'POST',
            body: JSON.stringify({
                prompt: 'Test prompt for smoke testing',
                context: { test: true, space: SPACE_NAME }
            })
        });
        
        if (!response.ok) {
            throw new Error(`Processing failed: ${response.status} ${response.statusText}`);
        }
        
        const data = await response.json();
        
        if (!data.response || !data.id) {
            throw new Error('Invalid response format');
        }
        
        if (data.space !== SPACE_NAME) {
            throw new Error(`Space mismatch in response: expected ${SPACE_NAME}, got ${data.space}`);
        }
    });
    
    // Test 3: Space Information Endpoint
    suite.addTest('Space Information Endpoint', async () => {
        const url = `http://localhost:${COPILOT_PORT}/space`;
        const response = await suite.makeHttpRequest(url);
        
        if (!response.ok) {
            throw new Error(`Space endpoint failed: ${response.status} ${response.statusText}`);
        }
        
        const data = await response.json();
        
        if (data.name !== SPACE_NAME) {
            throw new Error(`Space name mismatch: expected ${SPACE_NAME}, got ${data.name}`);
        }
        
        if (!Array.isArray(data.capabilities)) {
            throw new Error('Capabilities should be an array');
        }
    });
    
    // Test 4: Metrics Endpoint
    suite.addTest('Metrics Endpoint', async () => {
        const url = `http://localhost:${COPILOT_PORT}/metrics`;
        const response = await suite.makeHttpRequest(url);
        
        if (!response.ok) {
            throw new Error(`Metrics failed: ${response.status} ${response.statusText}`);
        }
        
        const data = await response.json();
        
        if (!data.system || !data.performance) {
            throw new Error('Invalid metrics format');
        }
        
        if (data.space !== SPACE_NAME) {
            throw new Error(`Space mismatch in metrics: expected ${SPACE_NAME}, got ${data.space}`);
        }
    });
    
    // Test 5: Webhook Multiplexer Health (if available)
    suite.addTest('Webhook Multiplexer Health', async () => {
        try {
            const url = `http://localhost:${WEBHOOK_PORT}/health`;
            const response = await suite.makeHttpRequest(url);
            
            if (!response.ok) {
                throw new Error(`Webhook health failed: ${response.status} ${response.statusText}`);
            }
            
            const data = await response.json();
            
            if (data.status !== 'healthy') {
                throw new Error(`Unhealthy webhook status: ${data.status}`);
            }
            
        } catch (error) {
            // Webhook multiplexer might not be running - this is a warning, not a failure
            if (error.code === 'ECONNREFUSED') {
                throw new Error('Webhook multiplexer not running (optional)');
            }
            throw error;
        }
    });
    
    // Test 6: Tunnel Connectivity (if configured)
    if (TUNNEL_URL) {
        suite.addTest('Tunnel Connectivity', async () => {
            const url = `${TUNNEL_URL}/health`;
            const response = await suite.makeHttpRequest(url);
            
            if (!response.ok) {
                throw new Error(`Tunnel health check failed: ${response.status} ${response.statusText}`);
            }
            
            const data = await response.json();
            
            if (data.status !== 'healthy') {
                throw new Error(`Unhealthy tunnel status: ${data.status}`);
            }
        });
    }
    
    // Test 7: Slack Integration (if configured)
    if (SLACK_BOT_TOKEN) {
        suite.addTest('Slack Integration Test', async () => {
            const url = 'https://slack.com/api/auth.test';
            const response = await suite.makeHttpRequest(url, {
                headers: {
                    'Authorization': `Bearer ${SLACK_BOT_TOKEN}`,
                    'Content-Type': 'application/json'
                }
            });
            
            if (!response.ok) {
                throw new Error(`Slack API request failed: ${response.status} ${response.statusText}`);
            }
            
            const data = await response.json();
            
            if (!data.ok) {
                throw new Error(`Slack auth test failed: ${data.error || 'Unknown error'}`);
            }
        });
    }
    
    // Test 8: File System Permissions
    suite.addTest('File System Permissions', async () => {
        const testFile = path.join(__dirname, 'test-permissions.tmp');
        
        try {
            // Test write permissions
            await fs.writeFile(testFile, 'test content');
            
            // Test read permissions
            const content = await fs.readFile(testFile, 'utf8');
            
            if (content !== 'test content') {
                throw new Error('File content mismatch');
            }
            
            // Cleanup
            await fs.unlink(testFile);
            
        } catch (error) {
            // Cleanup on error
            try {
                await fs.unlink(testFile);
            } catch {}
            
            throw error;
        }
    });
    
    // Test 9: Environment Configuration
    suite.addTest('Environment Configuration', async () => {
        const requiredEnvVars = ['SPACE_NAME'];
        const missingVars = [];
        
        for (const varName of requiredEnvVars) {
            if (!process.env[varName]) {
                missingVars.push(varName);
            }
        }
        
        if (missingVars.length > 0) {
            throw new Error(`Missing required environment variables: ${missingVars.join(', ')}`);
        }
        
        // Check .env.template exists
        const envTemplatePath = path.join(__dirname, '.env.template');
        try {
            await fs.access(envTemplatePath);
        } catch (error) {
            throw new Error('.env.template file not found');
        }
    });
}

// CLI interface
async function main() {
    console.log('🧪 Shared Smoke Test Suite - Universal Testing');
    console.log(`📍 Space: ${SPACE_NAME}`);
    console.log(`🔗 Copilot Port: ${COPILOT_PORT}`);
    console.log(`🌐 Webhook Port: ${WEBHOOK_PORT}`);
    console.log(`🚇 Tunnel URL: ${TUNNEL_URL || 'not configured'}\n`);
    
    const suite = new SmokeTestSuite();
    
    // Define all tests
    await defineTests(suite);
    
    try {
        // Run all tests
        const report = await suite.runAllTests();
        
        // Display results
        console.log('\n📊 Test Results Summary:');
        console.log(`   Total Tests: ${report.summary.total}`);
        console.log(`   Passed: ${report.summary.passed}`);
        console.log(`   Failed: ${report.summary.failed}`);
        console.log(`   Success Rate: ${report.summary.successRate.toFixed(1)}%`);
        console.log(`   Total Duration: ${report.summary.totalDuration}ms`);
        
        // Show failed tests
        const failedTests = report.results.filter(r => r.status === 'FAIL');
        if (failedTests.length > 0) {
            console.log('\n❌ Failed Tests:');
            for (const test of failedTests) {
                console.log(`   • ${test.name}: ${test.error}`);
            }
        }
        
        // Write report to file
        const reportPath = path.join(__dirname, `smoke-test-report-${Date.now()}.json`);
        await fs.writeFile(reportPath, JSON.stringify(report, null, 2));
        console.log(`\n📝 Report saved: ${reportPath}`);
        
        // Exit with appropriate code
        if (failedTests.length > 0) {
            console.log('\n⚠️  Some tests failed. Check the results above.');
            process.exit(1);
        } else {
            console.log('\n✅ All tests passed! System is healthy.');
            process.exit(0);
        }
        
    } catch (error) {
        console.error('\n💥 Smoke test suite crashed:', error.message);
        process.exit(1);
    }
}

// Export for programmatic use
export { SmokeTestSuite };

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
    main().catch(console.error);
}