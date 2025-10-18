# 🔒 HUMAN AI FRAMEWORK - Weekly Data Compilation System

## 🎯 Mission Statement

This system provides **exclusive, secure weekly compilation** of all AI user interactions, audit logs, and configuration files from your Perplexity account history. The compiled data is used **exclusively within the HUMAN AI FRAMEWORK space** for ongoing analysis and improvement of the AI-human relationship.

## ⚠️ SECURITY NOTICE

- **🔒 EXCLUSIVE ACCESS**: All data remains strictly within HUMAN-AI-FRAMEWORK space
- **❌ NO EXTERNAL SHARING**: Data cannot be referenced, shared, or exported to any other space
- **🔐 AUDIT TRAIL**: Complete logging of all compilation and access activities
- **✅ INTEGRITY CHECKS**: Cryptographic verification of all collected data

## 🏗️ System Architecture

```
human-ai-framework/
├── 📊 weekly-compiler.js          # Main compilation engine
├── 🔍 validate-jsons.py           # JSON schema validator
├── ⏰ weekly-compilation-scheduler.sh # Automation scheduler
├── 📁 compiled-data/              # Weekly snapshots
│   └── weekly-YYYYMMDD/          # Timestamped collections
│       ├── configs/              # Configuration files
│       ├── logs/                 # Interaction logs
│       ├── objectives/           # Space objectives
│       ├── threads/              # Thread histories
│       ├── backups/              # Backup files
│       └── incidents/            # Incident reports
├── 📋 audit.log                  # Complete audit trail
└── 🔧 validation/                # Validation reports
```

## 🚀 Quick Start Guide

### 1. Initialize the Framework
```bash
cd human-ai-framework
./weekly-compilation-scheduler.sh --init
```

### 2. Setup Automatic Weekly Compilation
```bash
./weekly-compilation-scheduler.sh --setup
```

### 3. Run Manual Compilation (Testing)
```bash
./weekly-compilation-scheduler.sh --run-compilation
```

### 4. Validate Existing Data
```bash
./weekly-compilation-scheduler.sh --validate
```

## 🔧 Core Components

### 📊 Weekly Compiler (`weekly-compiler.js`)

**Features:**
- Discovers all spaces in Perplexity account (`~/Perplexity/spaces/*/`)
- Collects target files: `*.json`, `audit.log`, `objectives*.json`, `thread-*.log`
- Creates timestamped weekly folders with organized subfolders
- Validates JSON schema compliance before inclusion
- Generates cryptographic checksums for integrity verification
- Synchronizes objectives files across spaces
- Creates comprehensive compilation reports

**Security:**
- Enforces HUMAN-AI-FRAMEWORK exclusive access
- No reverse data linking to other spaces
- Complete audit logging of all operations

### 🔍 JSON Validator (`validate-jsons.py`)

**Features:**
- Schema validation for objectives, reports, and config files
- Security constraint verification (exclusive access enforcement)
- File integrity checking with SHA-256 checksums
- Comprehensive validation reporting
- Backup validation file generation

**Security Schemas:**
- `objectives.json`: Requires spaceName, compilationId, security section
- `report-*.json`: Enforces HUMAN-AI-FRAMEWORK naming, security constraints
- `config*.json`: Generic configuration validation

### ⏰ Scheduler (`weekly-compilation-scheduler.sh`)

**Features:**
- Automated cron job setup (Sunday 23:00)
- Manual compilation execution
- Data validation and integrity checks
- Status reporting and monitoring
- Framework initialization

**Commands:**
```bash
--setup              # Setup automatic weekly compilation
--run-compilation    # Run compilation manually
--validate           # Validate existing data
--status             # Check scheduler status
--remove             # Remove automation
--init               # Initialize framework
```

## 📋 Data Collection Process

### 1. Space Discovery
- Scans `~/Perplexity/spaces/*/` for all user spaces
- Identifies target file patterns in each space
- Logs discovered spaces and file counts

### 2. File Collection
- **Configuration Files**: `config*.json`, `objectives*.json`
- **Audit Logs**: `audit.log`, interaction logs
- **Thread Data**: `thread-*.log`, `conversation-*.json`
- **Reports**: `report-*.json`, incident reports
- **Backups**: All backup variants

### 3. Validation & Processing
- JSON schema validation using `validate-jsons.py`
- File size limits (100MB per file)
- Integrity checking with cryptographic hashes
- Security constraint enforcement

### 4. Organization & Storage
```
weekly-YYYYMMDD/
├── configs/          # [space]_[timestamp]_config.json
├── logs/             # [space]_[timestamp]_audit.log
├── objectives/       # [space]_[timestamp]_objectives.json
├── threads/          # [space]_[timestamp]_thread-*.log
├── backups/          # [space]_[timestamp]_backup-*.json
├── incidents/        # [space]_[timestamp]_incident-*.json
└── validation/       # validation-report.json
```

### 5. Synchronization & Reporting
- Creates master `objectives.json` with all space objectives
- Generates backup copies: `objectives-001-HUMAN-AI-FRAMEWORK.json`
- Creates comprehensive compilation report with audit trail
- Updates main audit log with compilation summary

## 🔐 Security & Compliance

### Access Control
- **Exclusive Space Access**: Only HUMAN-AI-FRAMEWORK space can access data
- **No External References**: Compiled data never referenced outside framework
- **Audit Trail**: Complete logging of all operations and access

### Data Integrity
- **Cryptographic Hashing**: SHA-256 checksums for all files
- **Backup Verification**: Byte-for-byte integrity checking
- **Schema Validation**: Ensures data structure compliance

### Security Validation
```python
security_constraints = {
    "exclusiveAccess": True,
    "dataSharing": "PROHIBITED", 
    "accessLevel": "HUMAN-AI-FRAMEWORK-ONLY"
}
```

## ⏰ Automation & Scheduling

### Cron Job Setup
```bash
# Runs every Sunday at 23:00
0 23 * * 0 cd /path/to/human-ai-framework && ./weekly-compilation-scheduler.sh --run-compilation
```

### PDCA Cycle Integration
1. **Plan**: Weekly compilation schedule
2. **Do**: Execute compilation and validation
3. **Check**: Validate data integrity and completeness
4. **Act**: Update processes based on analysis results

## 📊 Monitoring & Reporting

### Status Monitoring
```bash
# Check compilation status
./weekly-compilation-scheduler.sh --status

# Validate recent compilations
./weekly-compilation-scheduler.sh --validate
```

### Report Structure
```json
{
  "compilationId": "uuid",
  "spaceName": "001-HUMAN-AI-FRAMEWORK",
  "summary": {
    "totalFilesCompiled": 42,
    "totalErrors": 0,
    "spacesCovered": ["general", "work", "research"],
    "fileTypes": {".json": 15, ".log": 27}
  },
  "security": {
    "exclusiveAccess": true,
    "dataSharing": "PROHIBITED",
    "accessLevel": "HUMAN-AI-FRAMEWORK-ONLY"
  }
}
```

## 🛠️ Troubleshooting

### Common Issues

**❌ Permission Denied**
```bash
chmod +x weekly-compilation-scheduler.sh
./weekly-compilation-scheduler.sh --init
```

**❌ JSON Validation Errors**
```bash
python3 validate-jsons.py weekly-YYYYMMDD
# Check validation report for specific errors
```

**❌ Missing Dependencies**
```bash
# Install required packages
npm install
pip3 install jsonschema
```

**❌ Cron Job Not Running**
```bash
# Check cron status
crontab -l | grep weekly-compilation
# Recreate if needed
./weekly-compilation-scheduler.sh --remove
./weekly-compilation-scheduler.sh --setup
```

### Debug Mode
```bash
# Enable detailed logging
LOG_LEVEL=debug ./weekly-compilation-scheduler.sh --run-compilation
```

## 📈 Usage Analytics

### Weekly Compilation Metrics
- **Data Volume**: Track compiled file sizes and counts
- **Space Coverage**: Monitor which spaces are being processed
- **Error Rates**: Track validation and compilation failures
- **Integrity Status**: Monitor cryptographic verification results

### Performance Monitoring
- **Compilation Time**: Track weekly compilation duration
- **Validation Speed**: Monitor JSON validation performance
- **Storage Growth**: Track compiled data directory growth

## 🔄 Maintenance Procedures

### Regular Tasks
1. **Weekly**: Verify automatic compilation success
2. **Monthly**: Review audit logs for anomalies
3. **Quarterly**: Validate data integrity across all compilations
4. **Annually**: Review and update security procedures

### Data Retention
- **Active Data**: Keep last 12 weekly compilations
- **Archive Data**: Compress older compilations
- **Audit Logs**: Retain complete audit trail indefinitely

## 🎯 Continuous Improvement

### Analysis Workflows
1. **Trend Analysis**: Review compilation patterns over time
2. **Error Pattern Detection**: Identify recurring validation issues
3. **Usage Pattern Analysis**: Understand space interaction patterns
4. **Objective Evolution**: Track changes in space objectives

### Feedback Loop
- Use compiled data for PDCA-based improvement cycles
- Update objectives based on interaction analysis
- Refine compilation processes based on usage patterns
- Enhance security based on audit findings

---

## 🚨 CRITICAL SECURITY REMINDER

**This system is designed exclusively for HUMAN-AI-FRAMEWORK analysis. All compiled data must remain within this framework and never be shared, referenced, or exported to any other space, user, or external context.**

- ✅ Exclusive HUMAN-AI-FRAMEWORK access
- ❌ No external sharing or referencing
- 🔒 Complete audit trail maintenance
- 📊 Secure weekly snapshot generation
- 🔄 PDCA-based continuous improvement

**Ready to begin secure weekly compilation for enhanced AI-human collaboration analysis!** 🎉