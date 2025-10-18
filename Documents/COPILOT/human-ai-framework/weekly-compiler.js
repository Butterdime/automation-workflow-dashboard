#!/usr/bin/env node

/**
 * Weekly Data Compilation for HUMAN AI FRAMEWORK
 * Secure compilation of all AI user interactions, audit logs, and configuration files
 * from Perplexity account history for exclusive analysis within HUMAN AI FRAMEWORK space
 * 
 * @version 1.0.0
 * @security EXCLUSIVE - No sharing with other spaces allowed
 */

import fs from 'fs/promises';
import path from 'path';
import crypto from 'crypto';
import { fileURLToPath } from 'url';

// ES Module dirname equivalent
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configuration Constants
const SPACENAME = '001-HUMAN-AI-FRAMEWORK';
const BASE_DIR = __dirname;
const PERPLEXITY_BASE = path.join(process.env.HOME, 'Perplexity', 'spaces');
const COMPILED_DATA_DIR = path.join(BASE_DIR, 'compiled-data');
const AUDIT_LOG_PATH = path.join(BASE_DIR, 'audit.log');

// File Patterns to Collect
const TARGET_PATTERNS = [
    '*.json',
    'audit.log',
    'objectives*.json',
    'report-*.json',
    'thread-*.log',
    'conversation-*.json',
    'config*.json',
    'backup*.json',
    'incident-*.json',
    'user-interaction-*.log'
];

// Security and Validation
const ALLOWED_SPACE_PREFIX = 'HUMAN-AI-FRAMEWORK';
const MAX_FILE_SIZE = 100 * 1024 * 1024; // 100MB limit per file

class WeeklyDataCompiler {
    constructor() {
        this.compilationId = this.generateCompilationId();
        this.weeklyFolder = this.getWeeklyFolderName();
        this.compiledFiles = [];
        this.errors = [];
        this.startTime = new Date();
    }

    generateCompilationId() {
        return crypto.randomUUID();
    }

    getWeeklyFolderName() {
        const now = new Date();
        const year = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, '0');
        const day = String(now.getDate()).padStart(2, '0');
        return `weekly-${year}${month}${day}`;
    }

    async log(level, message, data = {}) {
        const timestamp = new Date().toISOString();
        const logEntry = {
            timestamp,
            level,
            message,
            compilationId: this.compilationId,
            spaceName: SPACENAME,
            ...data
        };

        console.log(`[${level}] ${message}`, data);

        // Append to audit log
        const auditEntry = `${timestamp} [${level}] [${SPACENAME}] ${message} ${JSON.stringify(data)}\n`;
        await fs.appendFile(AUDIT_LOG_PATH, auditEntry, 'utf8').catch(console.error);
    }

    async ensureDirectoryStructure() {
        const dirs = [
            BASE_DIR,
            COMPILED_DATA_DIR,
            path.join(COMPILED_DATA_DIR, this.weeklyFolder),
            path.join(COMPILED_DATA_DIR, this.weeklyFolder, 'configs'),
            path.join(COMPILED_DATA_DIR, this.weeklyFolder, 'logs'),
            path.join(COMPILED_DATA_DIR, this.weeklyFolder, 'objectives'),
            path.join(COMPILED_DATA_DIR, this.weeklyFolder, 'threads'),
            path.join(COMPILED_DATA_DIR, this.weeklyFolder, 'backups'),
            path.join(COMPILED_DATA_DIR, this.weeklyFolder, 'incidents')
        ];

        for (const dir of dirs) {
            try {
                await fs.mkdir(dir, { recursive: true });
                await this.log('INFO', `Created directory: ${dir}`);
            } catch (error) {
                await this.log('ERROR', `Failed to create directory: ${dir}`, { error: error.message });
            }
        }
    }

    async discoverSpaces() {
        try {
            const spaces = [];
            
            // Check if Perplexity directory exists
            try {
                await fs.access(PERPLEXITY_BASE);
            } catch {
                await this.log('WARN', 'Perplexity base directory not found, creating mock structure for testing');
                await fs.mkdir(PERPLEXITY_BASE, { recursive: true });
                
                // Create some mock spaces for testing
                const mockSpaces = ['general', 'work', 'research', SPACENAME];
                for (const spaceName of mockSpaces) {
                    const spaceDir = path.join(PERPLEXITY_BASE, spaceName);
                    await fs.mkdir(spaceDir, { recursive: true });
                    
                    // Create mock files
                    await fs.writeFile(
                        path.join(spaceDir, 'objectives.json'),
                        JSON.stringify({ space: spaceName, objectives: ['test'] }, null, 2)
                    );
                    await fs.writeFile(
                        path.join(spaceDir, 'audit.log'),
                        `${new Date().toISOString()} [INFO] Mock audit entry for ${spaceName}\n`
                    );
                }
            }

            const entries = await fs.readdir(PERPLEXITY_BASE, { withFileTypes: true });
            
            for (const entry of entries) {
                if (entry.isDirectory()) {
                    const spacePath = path.join(PERPLEXITY_BASE, entry.name);
                    spaces.push({
                        name: entry.name,
                        path: spacePath
                    });
                }
            }

            await this.log('INFO', `Discovered ${spaces.length} spaces`, { spaces: spaces.map(s => s.name) });
            return spaces;
        } catch (error) {
            await this.log('ERROR', 'Failed to discover spaces', { error: error.message });
            return [];
        }
    }

    async collectFilesFromSpace(space) {
        const files = [];
        
        try {
            const entries = await fs.readdir(space.path, { withFileTypes: true });
            
            for (const entry of entries) {
                if (entry.isFile()) {
                    const filePath = path.join(space.path, entry.name);
                    const shouldCollect = TARGET_PATTERNS.some(pattern => {
                        const regex = new RegExp(pattern.replace('*', '.*'));
                        return regex.test(entry.name);
                    });

                    if (shouldCollect) {
                        try {
                            const stats = await fs.stat(filePath);
                            
                            if (stats.size > MAX_FILE_SIZE) {
                                await this.log('WARN', `File too large, skipping: ${filePath}`, {
                                    size: stats.size,
                                    maxSize: MAX_FILE_SIZE
                                });
                                continue;
                            }

                            files.push({
                                name: entry.name,
                                path: filePath,
                                size: stats.size,
                                modified: stats.mtime,
                                space: space.name
                            });
                        } catch (error) {
                            await this.log('ERROR', `Failed to stat file: ${filePath}`, { error: error.message });
                        }
                    }
                }
            }
            
            await this.log('INFO', `Collected ${files.length} files from space: ${space.name}`, {
                space: space.name,
                fileCount: files.length
            });
            
        } catch (error) {
            await this.log('ERROR', `Failed to collect files from space: ${space.name}`, { error: error.message });
        }

        return files;
    }

    async validateJson(filePath) {
        try {
            const content = await fs.readFile(filePath, 'utf8');
            JSON.parse(content);
            return { valid: true, content };
        } catch (error) {
            return { valid: false, error: error.message };
        }
    }

    async copyFileToCompilation(file) {
        try {
            // Determine destination subfolder based on file type
            let subfolder = 'logs';
            if (file.name.includes('objectives')) subfolder = 'objectives';
            else if (file.name.includes('config')) subfolder = 'configs';
            else if (file.name.includes('thread') || file.name.includes('conversation')) subfolder = 'threads';
            else if (file.name.includes('backup')) subfolder = 'backups';
            else if (file.name.includes('incident')) subfolder = 'incidents';

            // Create unique filename with space prefix
            const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
            const destFileName = `${file.space}_${timestamp}_${file.name}`;
            const destPath = path.join(COMPILED_DATA_DIR, this.weeklyFolder, subfolder, destFileName);

            // Validate JSON files before copying
            if (file.name.endsWith('.json')) {
                const validation = await this.validateJson(file.path);
                if (!validation.valid) {
                    await this.log('ERROR', `Invalid JSON, skipping: ${file.path}`, {
                        error: validation.error
                    });
                    return false;
                }
            }

            // Copy file
            await fs.copyFile(file.path, destPath);
            
            // Generate checksum for integrity verification
            const content = await fs.readFile(destPath);
            const checksum = crypto.createHash('sha256').update(content).digest('hex');

            const compiledFile = {
                original: file,
                destination: destPath,
                checksum,
                compiledAt: new Date().toISOString()
            };

            this.compiledFiles.push(compiledFile);

            await this.log('INFO', `Copied file: ${file.name}`, {
                from: file.path,
                to: destPath,
                checksum,
                size: file.size
            });

            return true;
        } catch (error) {
            await this.log('ERROR', `Failed to copy file: ${file.path}`, { error: error.message });
            this.errors.push({ file: file.path, error: error.message });
            return false;
        }
    }

    async synchronizeObjectives() {
        try {
            const objectivesDir = path.join(COMPILED_DATA_DIR, this.weeklyFolder, 'objectives');
            const objectivesFiles = this.compiledFiles.filter(f => 
                f.original.name.includes('objectives') && f.original.name.endsWith('.json')
            );

            if (objectivesFiles.length === 0) {
                await this.log('WARN', 'No objectives files found for synchronization');
                return;
            }

            // Create master objectives file
            const masterObjectives = {
                spaceName: SPACENAME,
                compilationId: this.compilationId,
                lastUpdated: new Date().toISOString(),
                sources: [],
                objectives: {}
            };

            for (const file of objectivesFiles) {
                try {
                    const content = await fs.readFile(file.destination, 'utf8');
                    const data = JSON.parse(content);
                    
                    masterObjectives.sources.push({
                        space: file.original.space,
                        file: file.original.name,
                        checksum: file.checksum
                    });

                    masterObjectives.objectives[file.original.space] = data;
                } catch (error) {
                    await this.log('ERROR', `Failed to process objectives file: ${file.destination}`, {
                        error: error.message
                    });
                }
            }

            // Write master objectives
            const masterPath = path.join(objectivesDir, 'objectives.json');
            const backupPath = path.join(objectivesDir, `objectives-${SPACENAME}.json`);

            await fs.writeFile(masterPath, JSON.stringify(masterObjectives, null, 2));
            await fs.writeFile(backupPath, JSON.stringify(masterObjectives, null, 2));

            await this.log('INFO', 'Synchronized objectives files', {
                masterPath,
                backupPath,
                sourceCount: objectivesFiles.length
            });

        } catch (error) {
            await this.log('ERROR', 'Failed to synchronize objectives', { error: error.message });
        }
    }

    async createCompilationReport() {
        const endTime = new Date();
        const duration = endTime.getTime() - this.startTime.getTime();

        const report = {
            compilationId: this.compilationId,
            spaceName: SPACENAME,
            weeklyFolder: this.weeklyFolder,
            startTime: this.startTime.toISOString(),
            endTime: endTime.toISOString(),
            durationMs: duration,
            summary: {
                totalFilesCompiled: this.compiledFiles.length,
                totalErrors: this.errors.length,
                spacesCovered: [...new Set(this.compiledFiles.map(f => f.original.space))],
                fileTypes: this.getFileTypeStats()
            },
            compiledFiles: this.compiledFiles,
            errors: this.errors,
            integrity: await this.verifyIntegrity(),
            security: {
                exclusiveAccess: true,
                dataSharing: 'PROHIBITED',
                accessLevel: 'HUMAN-AI-FRAMEWORK-ONLY'
            }
        };

        const reportPath = path.join(COMPILED_DATA_DIR, this.weeklyFolder, `report-${SPACENAME}.json`);
        const backupReportPath = path.join(COMPILED_DATA_DIR, this.weeklyFolder, `report-${SPACENAME}-backup.json`);

        await fs.writeFile(reportPath, JSON.stringify(report, null, 2));
        await fs.writeFile(backupReportPath, JSON.stringify(report, null, 2));

        await this.log('INFO', 'Created compilation report', {
            reportPath,
            backupReportPath,
            filesCompiled: this.compiledFiles.length,
            errors: this.errors.length
        });

        return report;
    }

    getFileTypeStats() {
        const stats = {};
        for (const file of this.compiledFiles) {
            const ext = path.extname(file.original.name);
            stats[ext] = (stats[ext] || 0) + 1;
        }
        return stats;
    }

    async verifyIntegrity() {
        const results = [];
        
        for (const file of this.compiledFiles) {
            try {
                const content = await fs.readFile(file.destination);
                const currentChecksum = crypto.createHash('sha256').update(content).digest('hex');
                const isValid = currentChecksum === file.checksum;
                
                results.push({
                    file: file.destination,
                    originalChecksum: file.checksum,
                    currentChecksum,
                    isValid
                });

                if (!isValid) {
                    await this.log('ERROR', `Integrity check failed: ${file.destination}`, {
                        expected: file.checksum,
                        actual: currentChecksum
                    });
                }
            } catch (error) {
                await this.log('ERROR', `Failed to verify integrity: ${file.destination}`, {
                    error: error.message
                });
                results.push({
                    file: file.destination,
                    error: error.message,
                    isValid: false
                });
            }
        }

        const validFiles = results.filter(r => r.isValid).length;
        const totalFiles = results.length;

        await this.log('INFO', `Integrity verification complete`, {
            validFiles,
            totalFiles,
            integrityRate: totalFiles > 0 ? (validFiles / totalFiles) * 100 : 0
        });

        return {
            validFiles,
            totalFiles,
            integrityRate: totalFiles > 0 ? (validFiles / totalFiles) * 100 : 0,
            results
        };
    }

    async writeAuditEntry() {
        const auditEntry = {
            timestamp: new Date().toISOString(),
            operation: 'WEEKLY_DATA_COMPILATION',
            spaceName: SPACENAME,
            compilationId: this.compilationId,
            weeklyFolder: this.weeklyFolder,
            summary: {
                filesCompiled: this.compiledFiles.length,
                spacesProcessed: [...new Set(this.compiledFiles.map(f => f.original.space))],
                errors: this.errors.length,
                duration: new Date().getTime() - this.startTime.getTime()
            },
            humanUser: process.env.USER || 'unknown',
            security: {
                dataExclusive: true,
                noExternalSharing: true,
                accessRestriction: 'HUMAN-AI-FRAMEWORK-ONLY'
            }
        };

        const auditLogEntry = `${auditEntry.timestamp} [AUDIT] [${SPACENAME}] Weekly compilation completed - ID: ${this.compilationId}, Files: ${this.compiledFiles.length}, Errors: ${this.errors.length}, User: ${auditEntry.humanUser}\n`;
        
        await fs.appendFile(AUDIT_LOG_PATH, auditLogEntry, 'utf8');
        
        await this.log('INFO', 'Audit entry written', auditEntry);
    }

    async execute() {
        try {
            await this.log('INFO', `Starting weekly compilation for ${SPACENAME}`, {
                compilationId: this.compilationId,
                weeklyFolder: this.weeklyFolder
            });

            // Step 1: Ensure directory structure
            await this.ensureDirectoryStructure();

            // Step 2: Discover all spaces
            const spaces = await this.discoverSpaces();

            // Step 3: Collect files from each space
            for (const space of spaces) {
                const files = await this.collectFilesFromSpace(space);
                
                // Step 4: Copy files to compilation folder
                for (const file of files) {
                    await this.copyFileToCompilation(file);
                }
            }

            // Step 5: Synchronize objectives files
            await this.synchronizeObjectives();

            // Step 6: Create compilation report
            const report = await this.createCompilationReport();

            // Step 7: Write audit entry
            await this.writeAuditEntry();

            await this.log('INFO', `Weekly compilation completed successfully`, {
                compilationId: this.compilationId,
                filesCompiled: this.compiledFiles.length,
                errors: this.errors.length
            });

            return {
                success: true,
                report,
                compilationId: this.compilationId
            };

        } catch (error) {
            await this.log('ERROR', 'Weekly compilation failed', { error: error.message });
            return {
                success: false,
                error: error.message,
                compilationId: this.compilationId
            };
        }
    }
}

// CLI interface
async function main() {
    console.log('🔒 HUMAN AI FRAMEWORK - Weekly Data Compiler');
    console.log('⚠️  SECURITY: Data is exclusively for HUMAN-AI-FRAMEWORK analysis');
    console.log('❌ NO EXTERNAL SHARING PERMITTED\n');

    const compiler = new WeeklyDataCompiler();
    const result = await compiler.execute();

    if (result.success) {
        console.log('\n✅ Weekly compilation completed successfully!');
        console.log(`📁 Data location: compiled-data/${compiler.weeklyFolder}`);
        console.log(`🆔 Compilation ID: ${result.compilationId}`);
        console.log(`📊 Files compiled: ${result.report.summary.totalFilesCompiled}`);
        console.log(`⚠️  Errors: ${result.report.summary.totalErrors}`);
        
        if (result.report.summary.totalErrors > 0) {
            console.log('\n❌ Errors encountered:');
            result.report.errors.forEach(error => {
                console.log(`   • ${error.file}: ${error.error}`);
            });
        }
        
        process.exit(0);
    } else {
        console.log('\n❌ Weekly compilation failed!');
        console.log(`Error: ${result.error}`);
        process.exit(1);
    }
}

// Export for programmatic use
export { WeeklyDataCompiler };

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
    main().catch(console.error);
}