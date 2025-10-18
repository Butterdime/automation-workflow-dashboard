#!/usr/bin/env node

/**
 * Demo: Perplexity Space Integration with Log-Aware Copilot
 * 
 * This script demonstrates how a Perplexity space should integrate
 * with the log-aware Copilot agent following team workflow guidelines.
 */

import { execSync } from 'child_process';
import axios from 'axios';
import fs from 'fs';
import path from 'path';

const COPILOT_URL = process.env.COPILOT_URL || 'http://localhost:4000';
const SPACE_NAME = process.env.PERPLEXITY_SPACE_NAME || 'demo-space';
const LOG_PATH = process.env.SHARED_COPILOT_LOGS || '/shared/copilot-logs';

/**
 * Step 1: Read recent logs from shared location
 */
function readSharedLogs(lines = 20) {
  try {
    const date = new Date().toISOString().slice(0, 10);
    const logFile = path.join(LOG_PATH, `${date}.log`);
    
    if (!fs.existsSync(logFile)) {
      console.log(`⚠️  No log file found at ${logFile}, using fallback`);
      return [];
    }
    
    const logContent = fs.readFileSync(logFile, 'utf-8');
    return logContent.trim().split('\n').slice(-lines).filter(line => line.trim());
  } catch (error) {
    console.log(`⚠️  Failed to read shared logs: ${error.message}`);
    return [];
  }
}

/**
 * Step 2: Analyze logs for context patterns
 */
function analyzeLogs(logs) {
  const analysis = {
    totalEntries: logs.length,
    errorCount: logs.filter(line => line.includes('ERROR')).length,
    healthChecks: logs.filter(line => line.includes('HEALTH_CHECK')).length,
    threadStarts: logs.filter(line => line.includes('THREAD_START')).length,
    logChecks: logs.filter(line => line.includes('LOG_CHECK')).length,
    lastActivity: logs.length > 0 ? logs[logs.length - 1].substring(0, 24) : null,
    recentPatterns: {
      errors: logs.filter(line => line.includes('ERROR')).slice(-3),
      requests: logs.filter(line => line.includes('REQ')).slice(-3)
    }
  };
  
  return analysis;
}

/**
 * Step 3: Send context-aware request to Copilot
 */
async function sendToCopilotwithLogContext(prompt, userContext = {}) {
  console.log(`🔍 Reading recent logs from ${LOG_PATH}...`);
  
  // Read and analyze logs
  const recentLogs = readSharedLogs(20);
  const logAnalysis = analyzeLogs(recentLogs);
  
  console.log(`📊 Log Analysis:`, {
    entries: logAnalysis.totalEntries,
    errors: logAnalysis.errorCount,
    lastActivity: logAnalysis.lastActivity
  });
  
  // Check for concerning patterns
  if (logAnalysis.errorCount > 3) {
    console.log(`⚠️  High error count (${logAnalysis.errorCount}) detected in recent logs!`);
  }
  
  // Prepare contextualized request
  const requestPayload = {
    prompt,
    context: {
      ...userContext,
      spaceId: SPACE_NAME,
      requestId: `pplx-${Date.now()}`,
      timestamp: new Date().toISOString()
    },
    recentLogs: recentLogs.slice(-10) // Send last 10 log entries
  };
  
  try {
    console.log(`🤖 Sending request to Copilot at ${COPILOT_URL}/process...`);
    
    const response = await axios.post(`${COPILOT_URL}/process`, requestPayload, {
      headers: { 'Content-Type': 'application/json' },
      timeout: 30000
    });
    
    const result = response.data;
    
    console.log(`✅ Copilot Response:`, {
      reply: result.reply,
      serverMetrics: result.logMetrics,
      contextUsed: result.contextUsed
    });
    
    // Log interaction for audit trail
    console.log(`📋 Audit: Space '${SPACE_NAME}' - ${logAnalysis.errorCount} client errors, ${result.logMetrics?.errorCount || 0} server errors`);
    
    return result;
    
  } catch (error) {
    console.error(`❌ Failed to communicate with Copilot:`, error.message);
    
    if (error.code === 'ECONNREFUSED') {
      console.log(`💡 Suggestion: Ensure Copilot agent is running on ${COPILOT_URL}`);
    }
    
    throw error;
  }
}

/**
 * Step 4: Health check with log awareness
 */
async function checkCopilothealth() {
  try {
    console.log(`🩺 Checking Copilot health at ${COPILOT_URL}/health...`);
    
    const response = await axios.get(`${COPILOT_URL}/health`);
    const health = response.data;
    
    console.log(`📊 Copilot Health Status:`, {
      status: health.status,
      services: health.services,
      logMetrics: health.logMetrics,
      uptime: `${Math.floor(health.uptime / 60)} minutes`
    });
    
    // Alert on concerning health metrics
    if (health.status === 'degraded') {
      console.log(`⚠️  Copilot is in degraded state!`);
    }
    
    if (health.logMetrics?.errorCount > 0) {
      console.log(`⚠️  Recent errors detected: ${health.logMetrics.errorCount}`);
    }
    
    return health;
    
  } catch (error) {
    console.error(`❌ Health check failed:`, error.message);
    throw error;
  }
}

/**
 * Demo workflow execution
 */
async function runDemo() {
  console.log(`\n🚀 Perplexity Space Integration Demo`);
  console.log(`Space: ${SPACE_NAME}`);
  console.log(`Copilot: ${COPILOT_URL}`);
  console.log(`Logs: ${LOG_PATH}`);
  console.log(`=====================================\n`);
  
  try {
    // Step 1: Check Copilot health
    await checkCopilothealth();
    
    console.log(`\n---\n`);
    
    // Step 2: Send test request with log context
    const testPrompt = "Hello Copilot! This is a test from the Perplexity space integration demo. Please provide a brief, helpful response.";
    
    await sendToCopilotwithLogContext(testPrompt, {
      user: 'demo-user',
      sessionId: 'demo-session-001',
      testMode: true
    });
    
    console.log(`\n✅ Demo completed successfully!`);
    console.log(`\n💡 Next steps:`);
    console.log(`   1. Integrate this pattern into your Perplexity space`);
    console.log(`   2. Set up proper log directory mounting`);
    console.log(`   3. Configure monitoring dashboards`);
    console.log(`   4. Add error alerting rules`);
    
  } catch (error) {
    console.error(`\n❌ Demo failed:`, error.message);
    console.log(`\n🔧 Troubleshooting:`);
    console.log(`   1. Ensure Copilot agent is running: node copilot/server.js`);
    console.log(`   2. Check log directory exists: ${LOG_PATH}`);
    console.log(`   3. Verify network connectivity to ${COPILOT_URL}`);
    process.exit(1);
  }
}

// Run demo if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  runDemo();
}

export { sendToCopilotwithLogContext, checkCopilothealth, analyzeLogs };