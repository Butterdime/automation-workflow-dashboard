#!/usr/bin/env node

/**
 * Perplexity Space Integration Template
 * 
 * This template provides a complete integration pattern for Perplexity spaces
 * to access and use Copilot logs for context-aware AI interactions.
 * 
 * Copy this template to your Perplexity space project and customize as needed.
 */

import { execSync } from 'child_process';
import axios from 'axios';
import fs from 'fs';
import path from 'path';

// Configuration - customize these for your space
const CONFIG = {
  spaceName: process.env.SPACE_NAME || 'your-perplexity-space',
  copilotUrl: process.env.COPILOT_URL || 'http://copilot-agent:4000',
  webhookUrl: process.env.WEBHOOK_URL || 'http://webhook-multiplexer:3000',
  sharedLogsPath: process.env.SHARED_COPILOT_LOGS || '/shared/copilot-logs',
  logRetention: parseInt(process.env.LOG_RETENTION_LINES) || 50,
  errorThreshold: parseInt(process.env.ERROR_THRESHOLD) || 5,
  requestTimeout: parseInt(process.env.REQUEST_TIMEOUT) || 30000
};

/**
 * Step 1: Read recent logs from shared location
 */
function getRecentCopilotLogs(lines = 20) {
  try {
    const date = new Date().toISOString().slice(0, 10);
    const logFile = path.join(CONFIG.sharedLogsPath, `${date}.log`);
    
    if (!fs.existsSync(logFile)) {
      console.log(`⚠️  No Copilot log file found at ${logFile}`);
      return {
        logs: [],
        analysis: { totalEntries: 0, errorCount: 0, available: false }
      };
    }
    
    // Read logs efficiently
    const logContent = fs.readFileSync(logFile, 'utf-8');
    const allLines = logContent.trim().split('\n').filter(line => line.trim());
    const recentLogs = allLines.slice(-lines);
    
    return {
      logs: recentLogs,
      analysis: analyzeLogContent(recentLogs),
      totalLogSize: allLines.length
    };
    
  } catch (error) {
    console.error(`❌ Failed to read Copilot logs: ${error.message}`);
    return {
      logs: [],
      analysis: { totalEntries: 0, errorCount: 0, available: false, error: error.message }
    };
  }
}

/**
 * Step 2: Analyze log content for patterns and health
 */
function analyzeLogContent(logs) {
  const analysis = {
    totalEntries: logs.length,
    errorCount: 0,
    healthChecks: 0,
    threadStarts: 0,
    logChecks: 0,
    recentRequests: 0,
    lastActivity: null,
    systemHealth: 'unknown',
    patterns: {
      errors: [],
      warnings: [],
      frequentOperations: {}
    }
  };
  
  const now = Date.now();
  const oneHourAgo = now - (60 * 60 * 1000);
  
  logs.forEach(line => {
    // Extract timestamp
    const timestampMatch = line.match(/^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z)/);
    const timestamp = timestampMatch ? new Date(timestampMatch[1]).getTime() : null;
    
    // Count different types of entries
    if (line.includes('ERROR')) {
      analysis.errorCount++;
      analysis.patterns.errors.push(line.substring(0, 100));
    }
    if (line.includes('HEALTH_CHECK')) analysis.healthChecks++;
    if (line.includes('THREAD_START')) analysis.threadStarts++;
    if (line.includes('LOG_CHECK')) analysis.logChecks++;
    if (line.includes('REQ')) analysis.recentRequests++;
    
    // Track recent activity (within last hour)
    if (timestamp && timestamp > oneHourAgo) {
      analysis.lastActivity = timestampMatch[1];
    }
  });
  
  // Determine system health
  if (analysis.errorCount === 0) {
    analysis.systemHealth = 'healthy';
  } else if (analysis.errorCount <= CONFIG.errorThreshold) {
    analysis.systemHealth = 'degraded';
  } else {
    analysis.systemHealth = 'unhealthy';
  }
  
  analysis.available = true;
  return analysis;
}

/**
 * Step 3: Enhanced health check with log context
 */
async function checkCopilotHealthWithLogs() {
  try {
    console.log(`🩺 Checking Copilot health...`);
    
    // Get server health
    const healthResponse = await axios.get(`${CONFIG.copilotUrl}/health`, {
      timeout: 5000
    });
    
    // Get log analysis
    const { logs, analysis } = getRecentCopilotLogs(30);
    
    const healthReport = {
      serverHealth: healthResponse.data,
      logAnalysis: analysis,
      overallStatus: determineOverallHealth(healthResponse.data, analysis),
      timestamp: new Date().toISOString(),
      spaceName: CONFIG.spaceName
    };
    
    logHealthReport(healthReport);
    return healthReport;
    
  } catch (error) {
    console.error(`❌ Health check failed: ${error.message}`);
    throw new Error(`Copilot health check failed: ${error.message}`);
  }
}

/**
 * Step 4: Send context-aware request to Copilot
 */
async function sendContextAwareRequest(prompt, userContext = {}, options = {}) {
  try {
    console.log(`🔍 Preparing context-aware request for Copilot...`);
    
    // Get recent logs and analysis
    const { logs, analysis, totalLogSize } = getRecentCopilotLogs(options.logLines || 20);
    
    // Check if system is healthy enough for requests
    if (analysis.errorCount > CONFIG.errorThreshold) {
      console.log(`⚠️  High error count detected (${analysis.errorCount}), proceeding with caution`);
    }
    
    // Prepare enhanced context
    const enhancedContext = {
      ...userContext,
      space: {
        name: CONFIG.spaceName,
        requestId: `${CONFIG.spaceName}-${Date.now()}`,
        timestamp: new Date().toISOString()
      },
      logContext: {
        analysis: analysis,
        recentLogsSample: logs.slice(-5), // Last 5 log entries
        totalSystemLogs: totalLogSize
      },
      systemState: {
        health: analysis.systemHealth,
        lastActivity: analysis.lastActivity,
        errorCount: analysis.errorCount
      }
    };
    
    // Prepare request payload
    const requestPayload = {
      prompt,
      context: enhancedContext,
      recentLogs: logs.slice(-10), // Send last 10 full log entries
      metadata: {
        spaceName: CONFIG.spaceName,
        logAnalysisVersion: '1.0',
        requestOptions: options
      }
    };
    
    console.log(`📊 Request context: ${analysis.totalEntries} logs, ${analysis.errorCount} errors, system: ${analysis.systemHealth}`);
    
    // Send request to Copilot
    const response = await axios.post(`${CONFIG.copilotUrl}/process`, requestPayload, {
      headers: { 'Content-Type': 'application/json' },
      timeout: CONFIG.requestTimeout
    });
    
    const result = response.data;
    
    // Log the interaction for audit
    console.log(`✅ Copilot response received`, {
      replyLength: result.reply?.length || 0,
      serverMetrics: result.logMetrics,
      contextUsed: result.contextUsed,
      responseTime: `${Date.now() - new Date(enhancedContext.space.timestamp).getTime()}ms`
    });
    
    // Store interaction history
    await logInteraction(requestPayload, result, analysis);
    
    return {
      reply: result.reply,
      serverMetrics: result.logMetrics,
      clientAnalysis: analysis,
      contextUsed: result.contextUsed,
      requestId: enhancedContext.space.requestId
    };
    
  } catch (error) {
    console.error(`❌ Context-aware request failed: ${error.message}`);
    
    // Provide helpful error context
    if (error.code === 'ECONNREFUSED') {
      throw new Error(`Copilot agent is not accessible at ${CONFIG.copilotUrl}`);
    } else if (error.code === 'ETIMEDOUT') {
      throw new Error(`Request timed out after ${CONFIG.requestTimeout}ms`);
    } else {
      throw new Error(`Copilot request failed: ${error.message}`);
    }
  }
}

/**
 * Step 5: Batch processing with log awareness
 */
async function processBatchRequests(requests, options = {}) {
  console.log(`📦 Processing batch of ${requests.length} requests with log context...`);
  
  const results = [];
  const batchStartTime = Date.now();
  
  // Get initial log state
  const initialLogState = getRecentCopilotLogs(10);
  console.log(`📋 Batch starting with ${initialLogState.analysis.errorCount} recent errors`);
  
  for (let i = 0; i < requests.length; i++) {
    const request = requests[i];
    
    try {
      // Add batch context
      const batchContext = {
        ...request.context,
        batch: {
          index: i,
          total: requests.length,
          batchId: `batch-${batchStartTime}`,
          initialLogState: initialLogState.analysis
        }
      };
      
      const result = await sendContextAwareRequest(
        request.prompt,
        batchContext,
        { ...options, logLines: 15 }
      );
      
      results.push({ success: true, result, request: request });
      
      // Add delay between requests if specified
      if (options.delayMs && i < requests.length - 1) {
        await new Promise(resolve => setTimeout(resolve, options.delayMs));
      }
      
    } catch (error) {
      console.error(`❌ Batch request ${i + 1} failed: ${error.message}`);
      results.push({ success: false, error: error.message, request: request });
      
      // Stop batch on critical errors if configured
      if (options.stopOnError) {
        console.log(`🛑 Stopping batch processing due to error`);
        break;
      }
    }
  }
  
  const batchDuration = Date.now() - batchStartTime;
  console.log(`📊 Batch completed: ${results.filter(r => r.success).length}/${requests.length} successful in ${batchDuration}ms`);
  
  return {
    results,
    summary: {
      total: requests.length,
      successful: results.filter(r => r.success).length,
      failed: results.filter(r => !r.success).length,
      duration: batchDuration,
      avgRequestTime: batchDuration / requests.length
    }
  };
}

/**
 * Utility Functions
 */
function determineOverallHealth(serverHealth, logAnalysis) {
  if (!logAnalysis.available) return 'unknown';
  if (serverHealth.status === 'degraded' || logAnalysis.systemHealth === 'unhealthy') return 'degraded';
  if (logAnalysis.errorCount > 0) return 'warning';
  return 'healthy';
}

function logHealthReport(report) {
  console.log(`📊 Health Report for ${report.spaceName}:`, {
    serverStatus: report.serverHealth.status,
    logHealth: report.logAnalysis.systemHealth,
    recentErrors: report.logAnalysis.errorCount,
    lastActivity: report.logAnalysis.lastActivity,
    overallStatus: report.overallStatus
  });
}

async function logInteraction(request, response, logAnalysis) {
  const interaction = {
    timestamp: new Date().toISOString(),
    spaceName: CONFIG.spaceName,
    requestId: request.metadata?.requestId || 'unknown',
    promptLength: request.prompt?.length || 0,
    replyLength: response.reply?.length || 0,
    logAnalysis: {
      errorCount: logAnalysis.errorCount,
      systemHealth: logAnalysis.systemHealth,
      logsAnalyzed: logAnalysis.totalEntries
    },
    serverMetrics: response.logMetrics
  };
  
  // In a real implementation, you might store this in a database or log file
  console.log(`📝 Interaction logged:`, interaction);
}

/**
 * Example Usage and Testing
 */
async function runExample() {
  console.log(`\n🚀 Perplexity Space Integration Example`);
  console.log(`Space: ${CONFIG.spaceName}`);
  console.log(`===================================\n`);
  
  try {
    // Example 1: Health Check
    const health = await checkCopilotHealthWithLogs();
    console.log(`Health Status: ${health.overallStatus}\n`);
    
    // Example 2: Simple Request
    const response1 = await sendContextAwareRequest(
      "Hello Copilot! Can you help me understand the current system status based on recent logs?",
      { user: 'example-user', session: 'demo' }
    );
    console.log(`Response 1: ${response1.reply.substring(0, 100)}...\n`);
    
    // Example 3: Batch Processing
    const batchRequests = [
      { prompt: "What's the current error rate?", context: { type: 'monitoring' } },
      { prompt: "Are there any system warnings?", context: { type: 'diagnostics' } },
      { prompt: "How is the system performing today?", context: { type: 'performance' } }
    ];
    
    const batchResults = await processBatchRequests(batchRequests, {
      delayMs: 1000,
      stopOnError: false
    });
    
    console.log(`✅ Example completed successfully!`);
    console.log(`Batch summary:`, batchResults.summary);
    
  } catch (error) {
    console.error(`❌ Example failed:`, error.message);
  }
}

// Export for use in other modules
export {
  getRecentCopilotLogs,
  analyzeLogContent,
  checkCopilotHealthWithLogs,
  sendContextAwareRequest,
  processBatchRequests,
  CONFIG
};

// Run example if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  runExample();
}