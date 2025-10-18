#!/usr/bin/env python3

"""
Weekly Compilation System - HUMAN AI FRAMEWORK Exclusive
Automated weekly data collection and compilation for exclusive content only
Maintains security isolation and prevents cross-space content sharing
"""

import os
import sys
import json
import shutil
import logging
import sqlite3
import hashlib
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Any, Optional
import subprocess

# Configuration
FRAMEWORK_SPACE = "HUMAN-AI-FRAMEWORK"
COMPILATION_DIR = Path.cwd() / "human-ai-framework"
WEEKS_TO_RETAIN = 12
LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')

# Logging setup
logging.basicConfig(
    level=getattr(logging, LOG_LEVEL),
    format='%(asctime)s [%(levelname)s] [FRAMEWORK] %(message)s',
    handlers=[
        logging.FileHandler('weekly-compilation.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class SecurityManager:
    """Manages security and access control for HUMAN AI FRAMEWORK"""
    
    def __init__(self):
        self.framework_hash = self._calculate_framework_hash()
        self.audit_log = []
    
    def _calculate_framework_hash(self) -> str:
        """Calculate unique hash for HUMAN AI FRAMEWORK space"""
        identifier = f"{FRAMEWORK_SPACE}-{datetime.now().strftime('%Y-%m')}"
        return hashlib.sha256(identifier.encode()).hexdigest()[:16]
    
    def validate_framework_access(self, space_name: str) -> bool:
        """Validate that current space is HUMAN AI FRAMEWORK"""
        is_valid = space_name == FRAMEWORK_SPACE
        self.audit_log.append({
            'timestamp': datetime.now().isoformat(),
            'action': 'access_validation',
            'space': space_name,
            'result': 'granted' if is_valid else 'denied',
            'hash': self.framework_hash
        })
        
        if not is_valid:
            logger.warning(f"Access denied: Invalid space '{space_name}' for FRAMEWORK operations")
        
        return is_valid
    
    def log_compilation_access(self, operation: str, files_count: int) -> None:
        """Log compilation operations for audit trail"""
        self.audit_log.append({
            'timestamp': datetime.now().isoformat(),
            'action': 'compilation_operation',
            'operation': operation,
            'files_processed': files_count,
            'hash': self.framework_hash
        })
        
        logger.info(f"Audit: {operation} - {files_count} files processed")
    
    def save_audit_log(self, compilation_dir: Path) -> None:
        """Save audit log for compliance"""
        audit_file = compilation_dir / f"audit-{datetime.now().strftime('%Y%m%d')}.json"
        
        audit_data = {
            'framework_hash': self.framework_hash,
            'compilation_date': datetime.now().isoformat(),
            'space_verified': FRAMEWORK_SPACE,
            'operations': self.audit_log,
            'retention_policy': f"{WEEKS_TO_RETAIN} weeks"
        }
        
        with open(audit_file, 'w') as f:
            json.dump(audit_data, f, indent=2)
        
        logger.info(f"Audit log saved: {audit_file}")

class WeeklyCompiler:
    """Handles weekly compilation of HUMAN AI FRAMEWORK exclusive content"""
    
    def __init__(self, space_name: str):
        self.space_name = space_name
        self.security_manager = SecurityManager()
        self.compilation_date = datetime.now()
        self.week_id = self.compilation_date.strftime('%Y-W%U')
        self.db_path = COMPILATION_DIR / "compilations.db"
        
        # Validate exclusive access
        if not self.security_manager.validate_framework_access(space_name):
            raise PermissionError(f"Weekly compilation restricted to {FRAMEWORK_SPACE} only")
    
    def init_database(self) -> None:
        """Initialize compilation tracking database"""
        COMPILATION_DIR.mkdir(exist_ok=True)
        
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS compilations (
                    week_id TEXT PRIMARY KEY,
                    compilation_date TEXT NOT NULL,
                    files_processed INTEGER NOT NULL,
                    total_size_bytes INTEGER NOT NULL,
                    checksum TEXT NOT NULL,
                    metadata TEXT NOT NULL
                )
            """)
            
            conn.execute("""
                CREATE TABLE IF NOT EXISTS files_tracked (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    week_id TEXT NOT NULL,
                    file_path TEXT NOT NULL,
                    file_hash TEXT NOT NULL,
                    size_bytes INTEGER NOT NULL,
                    last_modified TEXT NOT NULL,
                    FOREIGN KEY (week_id) REFERENCES compilations (week_id)
                )
            """)
        
        logger.info("Compilation database initialized")
    
    def collect_framework_data(self) -> Dict[str, Any]:
        """Collect data specific to HUMAN AI FRAMEWORK"""
        
        data_sources = {
            'copilot_logs': self._collect_copilot_logs(),
            'conversation_data': self._collect_conversation_data(),
            'framework_configs': self._collect_framework_configs(),
            'weekly_metrics': self._collect_weekly_metrics(),
            'exclusive_content': self._collect_exclusive_content()
        }
        
        # Security validation - ensure no cross-space contamination
        for source_name, source_data in data_sources.items():
            if source_data and not self._validate_data_exclusivity(source_data):
                logger.warning(f"Data source {source_name} failed exclusivity validation")
                data_sources[source_name] = {'error': 'exclusivity_validation_failed'}
        
        total_files = sum(len(data.get('files', [])) for data in data_sources.values() if isinstance(data, dict))
        self.security_manager.log_compilation_access('data_collection', total_files)
        
        return data_sources
    
    def _collect_copilot_logs(self) -> Dict[str, Any]:
        """Collect Copilot logs for HUMAN AI FRAMEWORK only"""
        logs_dir = Path.cwd() / "logs"
        
        if not logs_dir.exists():
            return {'files': [], 'total_size': 0, 'note': 'logs_directory_not_found'}
        
        # Get logs from the past week
        week_ago = self.compilation_date - timedelta(days=7)
        log_files = []
        total_size = 0
        
        for log_file in logs_dir.glob("*.log"):
            stat_info = log_file.stat()
            modified_time = datetime.fromtimestamp(stat_info.st_mtime)
            
            if modified_time >= week_ago:
                # Validate log content is FRAMEWORK-specific
                if self._validate_log_framework_content(log_file):
                    log_files.append({
                        'path': str(log_file),
                        'size': stat_info.st_size,
                        'modified': modified_time.isoformat(),
                        'hash': self._calculate_file_hash(log_file)
                    })
                    total_size += stat_info.st_size
        
        return {
            'files': log_files,
            'total_size': total_size,
            'collection_date': self.compilation_date.isoformat(),
            'week_range': f"{week_ago.isoformat()} to {self.compilation_date.isoformat()}"
        }
    
    def _collect_conversation_data(self) -> Dict[str, Any]:
        """Collect conversation data exclusive to HUMAN AI FRAMEWORK"""
        conversation_files = []
        
        # Look for conversation exports, chat histories, etc.
        patterns = ['conversation-*.json', 'chat-history-*.json', 'session-*.json']
        
        for pattern in patterns:
            for file_path in Path.cwd().glob(pattern):
                if self._validate_file_framework_content(file_path):
                    stat_info = file_path.stat()
                    conversation_files.append({
                        'path': str(file_path),
                        'size': stat_info.st_size,
                        'modified': datetime.fromtimestamp(stat_info.st_mtime).isoformat(),
                        'hash': self._calculate_file_hash(file_path)
                    })
        
        return {
            'files': conversation_files,
            'patterns_searched': patterns,
            'collection_date': self.compilation_date.isoformat()
        }
    
    def _collect_framework_configs(self) -> Dict[str, Any]:
        """Collect configuration files specific to FRAMEWORK"""
        config_files = []
        
        # FRAMEWORK-specific configuration files
        framework_configs = [
            'copilot/config.json',
            'config/copilot-schema.json',
            'human-ai-framework/*.json',
            '.env.framework'
        ]
        
        for pattern in framework_configs:
            for file_path in Path.cwd().glob(pattern):
                if file_path.exists():
                    stat_info = file_path.stat()
                    config_files.append({
                        'path': str(file_path),
                        'size': stat_info.st_size,
                        'modified': datetime.fromtimestamp(stat_info.st_mtime).isoformat(),
                        'hash': self._calculate_file_hash(file_path),
                        'type': 'framework_config'
                    })
        
        return {
            'files': config_files,
            'collection_date': self.compilation_date.isoformat()
        }
    
    def _collect_weekly_metrics(self) -> Dict[str, Any]:
        """Collect performance and usage metrics for the week"""
        
        metrics = {
            'compilation_week': self.week_id,
            'framework_space': FRAMEWORK_SPACE,
            'system_info': {
                'python_version': sys.version,
                'platform': sys.platform,
                'cwd': str(Path.cwd())
            },
            'collection_timestamp': self.compilation_date.isoformat()
        }
        
        # Try to collect system metrics if available
        try:
            import psutil
            metrics['system_metrics'] = {
                'cpu_percent': psutil.cpu_percent(),
                'memory_percent': psutil.virtual_memory().percent,
                'disk_usage': psutil.disk_usage('.').percent
            }
        except ImportError:
            metrics['system_metrics'] = {'note': 'psutil_not_available'}
        
        return metrics
    
    def _collect_exclusive_content(self) -> Dict[str, Any]:
        """Collect content exclusive to HUMAN AI FRAMEWORK"""
        
        exclusive_dirs = ['human-ai-framework', 'framework-exclusive']
        exclusive_files = []
        
        for dir_name in exclusive_dirs:
            dir_path = Path.cwd() / dir_name
            if dir_path.exists():
                for file_path in dir_path.rglob('*'):
                    if file_path.is_file():
                        stat_info = file_path.stat()
                        exclusive_files.append({
                            'path': str(file_path.relative_to(Path.cwd())),
                            'size': stat_info.st_size,
                            'modified': datetime.fromtimestamp(stat_info.st_mtime).isoformat(),
                            'hash': self._calculate_file_hash(file_path)
                        })
        
        return {
            'files': exclusive_files,
            'directories_scanned': exclusive_dirs,
            'collection_date': self.compilation_date.isoformat()
        }
    
    def _validate_data_exclusivity(self, data: Any) -> bool:
        """Validate that collected data is exclusive to HUMAN AI FRAMEWORK"""
        if not isinstance(data, dict):
            return True
        
        # Check for any references to other spaces
        prohibited_spaces = [
            'general-space', 'shared-space', 'public-space', 
            'common-infrastructure', 'cross-space'
        ]
        
        data_str = json.dumps(data).lower()
        
        for prohibited in prohibited_spaces:
            if prohibited in data_str:
                logger.warning(f"Found prohibited space reference: {prohibited}")
                return False
        
        return True
    
    def _validate_log_framework_content(self, log_file: Path) -> bool:
        """Validate that log file contains FRAMEWORK-specific content"""
        try:
            with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read(4096)  # Sample first 4KB
            
            # Must contain FRAMEWORK indicators
            framework_indicators = [FRAMEWORK_SPACE.lower(), '[framework]', 'human-ai-framework']
            
            content_lower = content.lower()
            return any(indicator in content_lower for indicator in framework_indicators)
            
        except Exception as e:
            logger.warning(f"Could not validate log file {log_file}: {e}")
            return False
    
    def _validate_file_framework_content(self, file_path: Path) -> bool:
        """Validate that file contains FRAMEWORK-specific content"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read(2048)  # Sample first 2KB
            
            # Check for FRAMEWORK-specific content
            framework_content = content.lower()
            return FRAMEWORK_SPACE.lower() in framework_content
            
        except Exception as e:
            logger.debug(f"Could not validate file {file_path}: {e}")
            return True  # Default to include if validation fails
    
    def _calculate_file_hash(self, file_path: Path) -> str:
        """Calculate SHA256 hash of file"""
        hash_sha256 = hashlib.sha256()
        
        try:
            with open(file_path, 'rb') as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    hash_sha256.update(chunk)
            return hash_sha256.hexdigest()[:16]  # Truncate for storage
        except Exception as e:
            logger.warning(f"Could not hash file {file_path}: {e}")
            return "hash_failed"
    
    def create_compilation(self, data_sources: Dict[str, Any]) -> Path:
        """Create weekly compilation package"""
        
        compilation_dir = COMPILATION_DIR / f"week-{self.week_id}"
        compilation_dir.mkdir(parents=True, exist_ok=True)
        
        # Create compilation manifest
        manifest = {
            'week_id': self.week_id,
            'compilation_date': self.compilation_date.isoformat(),
            'framework_space': FRAMEWORK_SPACE,
            'security_hash': self.security_manager.framework_hash,
            'data_sources': {},
            'exclusivity_verified': True
        }
        
        total_files = 0
        total_size = 0
        
        # Process each data source
        for source_name, source_data in data_sources.items():
            if isinstance(source_data, dict) and 'files' in source_data:
                source_dir = compilation_dir / source_name
                source_dir.mkdir(exist_ok=True)
                
                copied_files = []
                
                for file_info in source_data['files']:
                    src_path = Path(file_info['path'])
                    
                    if src_path.exists():
                        # Copy file to compilation directory
                        dst_path = source_dir / src_path.name
                        shutil.copy2(src_path, dst_path)
                        
                        copied_files.append({
                            'original_path': str(src_path),
                            'compiled_path': str(dst_path.relative_to(compilation_dir)),
                            'size': file_info['size'],
                            'hash': file_info['hash']
                        })
                        
                        total_files += 1
                        total_size += file_info['size']
                
                manifest['data_sources'][source_name] = {
                    'files_count': len(copied_files),
                    'total_size': sum(f['size'] for f in copied_files),
                    'files': copied_files
                }
        
        # Save manifest
        manifest_path = compilation_dir / 'manifest.json'
        with open(manifest_path, 'w') as f:
            json.dump(manifest, f, indent=2)
        
        # Create compilation checksum
        compilation_checksum = self._calculate_compilation_checksum(compilation_dir)
        
        # Update database
        self._update_compilation_database(
            self.week_id, total_files, total_size, compilation_checksum, manifest
        )
        
        # Save audit log
        self.security_manager.save_audit_log(compilation_dir)
        
        logger.info(f"Weekly compilation created: {compilation_dir}")
        logger.info(f"Files processed: {total_files}, Total size: {total_size} bytes")
        
        return compilation_dir
    
    def _calculate_compilation_checksum(self, compilation_dir: Path) -> str:
        """Calculate checksum for entire compilation"""
        hash_sha256 = hashlib.sha256()
        
        for file_path in sorted(compilation_dir.rglob('*')):
            if file_path.is_file():
                hash_sha256.update(str(file_path.relative_to(compilation_dir)).encode())
                
                with open(file_path, 'rb') as f:
                    for chunk in iter(lambda: f.read(4096), b""):
                        hash_sha256.update(chunk)
        
        return hash_sha256.hexdigest()
    
    def _update_compilation_database(self, week_id: str, files_count: int, 
                                   total_size: int, checksum: str, manifest: Dict) -> None:
        """Update compilation tracking database"""
        
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT OR REPLACE INTO compilations 
                (week_id, compilation_date, files_processed, total_size_bytes, checksum, metadata)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                week_id,
                self.compilation_date.isoformat(),
                files_count,
                total_size,
                checksum,
                json.dumps(manifest)
            ))
    
    def cleanup_old_compilations(self) -> None:
        """Remove compilations older than retention policy"""
        
        cutoff_date = self.compilation_date - timedelta(weeks=WEEKS_TO_RETAIN)
        
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute("""
                SELECT week_id FROM compilations 
                WHERE compilation_date < ?
            """, (cutoff_date.isoformat(),))
            
            old_compilations = [row[0] for row in cursor.fetchall()]
        
        for week_id in old_compilations:
            # Remove directory
            old_dir = COMPILATION_DIR / f"week-{week_id}"
            if old_dir.exists():
                shutil.rmtree(old_dir)
                logger.info(f"Removed old compilation: {old_dir}")
            
            # Remove from database
            with sqlite3.connect(self.db_path) as conn:
                conn.execute("DELETE FROM files_tracked WHERE week_id = ?", (week_id,))
                conn.execute("DELETE FROM compilations WHERE week_id = ?", (week_id,))
        
        if old_compilations:
            logger.info(f"Cleaned up {len(old_compilations)} old compilations")

def main():
    """Main execution function"""
    
    # Get space name from environment
    space_name = os.getenv('SPACE_NAME', 'unknown')
    
    try:
        logger.info(f"Starting weekly compilation for space: {space_name}")
        
        # Initialize compiler with security validation
        compiler = WeeklyCompiler(space_name)
        compiler.init_database()
        
        # Collect FRAMEWORK-exclusive data
        logger.info("Collecting HUMAN AI FRAMEWORK exclusive data...")
        data_sources = compiler.collect_framework_data()
        
        # Create compilation
        logger.info("Creating weekly compilation package...")
        compilation_dir = compiler.create_compilation(data_sources)
        
        # Cleanup old compilations
        logger.info("Cleaning up old compilations...")
        compiler.cleanup_old_compilations()
        
        logger.info(f"✅ Weekly compilation completed successfully: {compilation_dir}")
        
        # Output summary for CI/CD
        summary = {
            'status': 'success',
            'week_id': compiler.week_id,
            'compilation_dir': str(compilation_dir),
            'space_verified': FRAMEWORK_SPACE,
            'files_processed': sum(
                len(data.get('files', [])) 
                for data in data_sources.values() 
                if isinstance(data, dict)
            )
        }
        
        print(json.dumps(summary, indent=2))
        
    except PermissionError as e:
        logger.error(f"❌ Access denied: {e}")
        sys.exit(1)
        
    except Exception as e:
        logger.error(f"💥 Weekly compilation failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()