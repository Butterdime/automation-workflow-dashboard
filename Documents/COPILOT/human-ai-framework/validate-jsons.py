#!/usr/bin/env python3
"""
JSON Schema Validator for HUMAN AI FRAMEWORK Weekly Compilation
Validates all collected JSON files against expected schemas
Security Level: EXCLUSIVE - HUMAN-AI-FRAMEWORK ONLY
"""

import json
import jsonschema
import os
import sys
import hashlib
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple, Any

# Schema definitions for different file types
SCHEMAS = {
    "objectives": {
        "type": "object",
        "required": ["spaceName", "compilationId", "lastUpdated"],
        "properties": {
            "spaceName": {"type": "string"},
            "compilationId": {"type": "string"},
            "lastUpdated": {"type": "string", "format": "date-time"},
            "sources": {
                "type": "array",
                "items": {
                    "type": "object",
                    "required": ["space", "file", "checksum"],
                    "properties": {
                        "space": {"type": "string"},
                        "file": {"type": "string"},
                        "checksum": {"type": "string"}
                    }
                }
            },
            "objectives": {"type": "object"}
        }
    },
    "report": {
        "type": "object",
        "required": ["compilationId", "spaceName", "weeklyFolder", "summary"],
        "properties": {
            "compilationId": {"type": "string"},
            "spaceName": {"type": "string", "enum": ["001-HUMAN-AI-FRAMEWORK"]},
            "weeklyFolder": {"type": "string"},
            "startTime": {"type": "string", "format": "date-time"},
            "endTime": {"type": "string", "format": "date-time"},
            "summary": {
                "type": "object",
                "required": ["totalFilesCompiled", "totalErrors"],
                "properties": {
                    "totalFilesCompiled": {"type": "integer", "minimum": 0},
                    "totalErrors": {"type": "integer", "minimum": 0},
                    "spacesCovered": {"type": "array", "items": {"type": "string"}},
                    "fileTypes": {"type": "object"}
                }
            },
            "security": {
                "type": "object",
                "required": ["exclusiveAccess", "dataSharing", "accessLevel"],
                "properties": {
                    "exclusiveAccess": {"type": "boolean", "enum": [True]},
                    "dataSharing": {"type": "string", "enum": ["PROHIBITED"]},
                    "accessLevel": {"type": "string", "enum": ["HUMAN-AI-FRAMEWORK-ONLY"]}
                }
            }
        }
    },
    "config": {
        "type": "object",
        "properties": {
            "space": {"type": "string"},
            "version": {"type": "string"},
            "lastModified": {"type": "string"}
        }
    }
}

class HumanAIFrameworkValidator:
    """
    Exclusive validator for HUMAN AI FRAMEWORK weekly compilation data
    NO EXTERNAL ACCESS - INTERNAL USE ONLY
    """
    
    def __init__(self, base_dir: str = None):
        self.base_dir = Path(base_dir) if base_dir else Path(__file__).parent
        self.validation_results = []
        self.error_count = 0
        self.valid_count = 0
        
    def log_validation(self, level: str, message: str, details: Dict = None):
        """Log validation events with security context"""
        timestamp = datetime.now().isoformat()
        log_entry = {
            "timestamp": timestamp,
            "level": level,
            "message": message,
            "security_context": "HUMAN-AI-FRAMEWORK-EXCLUSIVE",
            "details": details or {}
        }
        
        print(f"[{level}] {message}")
        if details:
            print(f"    Details: {details}")
            
        self.validation_results.append(log_entry)
        
    def calculate_file_checksum(self, file_path: Path) -> str:
        """Calculate SHA-256 checksum for file integrity"""
        sha256_hash = hashlib.sha256()
        try:
            with open(file_path, "rb") as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    sha256_hash.update(chunk)
            return sha256_hash.hexdigest()
        except Exception as e:
            self.log_validation("ERROR", f"Failed to calculate checksum for {file_path}", {"error": str(e)})
            return ""
    
    def get_schema_for_file(self, file_path: Path) -> Dict:
        """Determine appropriate schema based on file name/path"""
        file_name = file_path.name.lower()
        
        if "objectives" in file_name:
            return SCHEMAS["objectives"]
        elif "report" in file_name:
            return SCHEMAS["report"]
        elif "config" in file_name:
            return SCHEMAS["config"]
        else:
            # Generic JSON schema
            return {"type": "object"}
    
    def validate_json_file(self, file_path: Path) -> Tuple[bool, Dict]:
        """Validate a single JSON file against appropriate schema"""
        try:
            # Read and parse JSON
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Get appropriate schema
            schema = self.get_schema_for_file(file_path)
            
            # Validate against schema
            jsonschema.validate(data, schema)
            
            # Calculate checksum for integrity
            checksum = self.calculate_file_checksum(file_path)
            
            result = {
                "file": str(file_path),
                "valid": True,
                "schema_type": self.get_schema_type(file_path),
                "checksum": checksum,
                "size_bytes": file_path.stat().st_size,
                "data_preview": self.get_safe_preview(data)
            }
            
            self.valid_count += 1
            self.log_validation("INFO", f"Valid JSON: {file_path.name}", {
                "schema": result["schema_type"],
                "size": result["size_bytes"]
            })
            
            return True, result
            
        except json.JSONDecodeError as e:
            self.error_count += 1
            result = {
                "file": str(file_path),
                "valid": False,
                "error_type": "JSON_DECODE_ERROR",
                "error": str(e),
                "line": getattr(e, 'lineno', None),
                "column": getattr(e, 'colno', None)
            }
            
            self.log_validation("ERROR", f"JSON decode error in {file_path.name}", {
                "error": str(e),
                "line": result.get("line"),
                "column": result.get("column")
            })
            
            return False, result
            
        except jsonschema.ValidationError as e:
            self.error_count += 1
            result = {
                "file": str(file_path),
                "valid": False,
                "error_type": "SCHEMA_VALIDATION_ERROR",
                "error": str(e.message),
                "schema_path": list(e.absolute_path),
                "failed_value": e.instance
            }
            
            self.log_validation("ERROR", f"Schema validation error in {file_path.name}", {
                "error": str(e.message),
                "path": result["schema_path"]
            })
            
            return False, result
            
        except Exception as e:
            self.error_count += 1
            result = {
                "file": str(file_path),
                "valid": False,
                "error_type": "UNEXPECTED_ERROR",
                "error": str(e)
            }
            
            self.log_validation("ERROR", f"Unexpected error validating {file_path.name}", {
                "error": str(e)
            })
            
            return False, result
    
    def get_schema_type(self, file_path: Path) -> str:
        """Determine schema type from file path"""
        file_name = file_path.name.lower()
        if "objectives" in file_name:
            return "objectives"
        elif "report" in file_name:
            return "report"
        elif "config" in file_name:
            return "config"
        else:
            return "generic"
    
    def get_safe_preview(self, data: Any, max_length: int = 200) -> str:
        """Get safe preview of data for logging (no sensitive info exposure)"""
        try:
            preview = json.dumps(data, indent=2)
            if len(preview) > max_length:
                preview = preview[:max_length] + "..."
            return preview
        except:
            return str(type(data))
    
    def validate_security_constraints(self, data: Dict, file_path: Path) -> bool:
        """Validate that data meets HUMAN-AI-FRAMEWORK security requirements"""
        security_violations = []
        
        # Check for space name restrictions
        if "spaceName" in data:
            if not data["spaceName"].startswith("001-HUMAN-AI-FRAMEWORK"):
                security_violations.append("Invalid spaceName - must be HUMAN-AI-FRAMEWORK variant")
        
        # Check security section if present
        if "security" in data:
            security = data["security"]
            if security.get("dataSharing") != "PROHIBITED":
                security_violations.append("dataSharing must be PROHIBITED")
            if security.get("accessLevel") != "HUMAN-AI-FRAMEWORK-ONLY":
                security_violations.append("accessLevel must be HUMAN-AI-FRAMEWORK-ONLY")
            if security.get("exclusiveAccess") is not True:
                security_violations.append("exclusiveAccess must be true")
        
        if security_violations:
            self.log_validation("ERROR", f"Security violations in {file_path.name}", {
                "violations": security_violations
            })
            return False
        
        return True
    
    def discover_json_files(self, directory: Path) -> List[Path]:
        """Discover all JSON files in directory tree"""
        json_files = []
        
        try:
            for file_path in directory.rglob("*.json"):
                if file_path.is_file():
                    json_files.append(file_path)
            
            self.log_validation("INFO", f"Discovered {len(json_files)} JSON files", {
                "directory": str(directory),
                "files": [f.name for f in json_files[:10]]  # Show first 10
            })
            
        except Exception as e:
            self.log_validation("ERROR", f"Failed to discover files in {directory}", {
                "error": str(e)
            })
        
        return json_files
    
    def validate_weekly_compilation(self, weekly_folder: str = None) -> Dict:
        """Validate all JSON files in a weekly compilation"""
        if weekly_folder:
            target_dir = self.base_dir / "compiled-data" / weekly_folder
        else:
            # Find most recent weekly folder
            compiled_data_dir = self.base_dir / "compiled-data"
            if not compiled_data_dir.exists():
                self.log_validation("ERROR", "No compiled-data directory found")
                return self.generate_validation_report()
            
            weekly_folders = [d for d in compiled_data_dir.iterdir() 
                            if d.is_dir() and d.name.startswith("weekly-")]
            
            if not weekly_folders:
                self.log_validation("ERROR", "No weekly compilation folders found")
                return self.generate_validation_report()
            
            target_dir = max(weekly_folders, key=lambda d: d.stat().st_mtime)
        
        if not target_dir.exists():
            self.log_validation("ERROR", f"Target directory does not exist: {target_dir}")
            return self.generate_validation_report()
        
        self.log_validation("INFO", f"Validating weekly compilation: {target_dir.name}")
        
        # Discover and validate all JSON files
        json_files = self.discover_json_files(target_dir)
        validation_results = []
        
        for json_file in json_files:
            is_valid, result = self.validate_json_file(json_file)
            validation_results.append(result)
            
            # Additional security validation for valid files
            if is_valid and json_file.suffix == '.json':
                try:
                    with open(json_file, 'r') as f:
                        data = json.load(f)
                    self.validate_security_constraints(data, json_file)
                except Exception as e:
                    self.log_validation("WARN", f"Could not perform security validation on {json_file.name}", {
                        "error": str(e)
                    })
        
        return self.generate_validation_report(validation_results)
    
    def generate_validation_report(self, file_results: List[Dict] = None) -> Dict:
        """Generate comprehensive validation report"""
        report = {
            "timestamp": datetime.now().isoformat(),
            "security_context": "HUMAN-AI-FRAMEWORK-EXCLUSIVE",
            "validation_summary": {
                "total_files": len(file_results) if file_results else 0,
                "valid_files": self.valid_count,
                "invalid_files": self.error_count,
                "success_rate": (self.valid_count / max(1, self.valid_count + self.error_count)) * 100
            },
            "file_results": file_results or [],
            "validation_log": self.validation_results,
            "security_compliance": {
                "data_exclusive": True,
                "no_external_sharing": True,
                "access_restriction": "HUMAN-AI-FRAMEWORK-ONLY"
            }
        }
        
        return report
    
    def create_backup_validation(self, weekly_folder: str):
        """Create backup of validation results with integrity checks"""
        try:
            report = self.generate_validation_report()
            
            # Write validation report
            validation_dir = self.base_dir / "compiled-data" / weekly_folder / "validation"
            validation_dir.mkdir(exist_ok=True)
            
            report_path = validation_dir / "validation-report.json"
            backup_path = validation_dir / "validation-report-backup.json"
            
            # Write primary and backup
            with open(report_path, 'w') as f:
                json.dump(report, f, indent=2)
            
            with open(backup_path, 'w') as f:
                json.dump(report, f, indent=2)
            
            # Generate checksums
            primary_checksum = self.calculate_file_checksum(report_path)
            backup_checksum = self.calculate_file_checksum(backup_path)
            
            self.log_validation("INFO", "Validation report created", {
                "report_path": str(report_path),
                "backup_path": str(backup_path),
                "primary_checksum": primary_checksum,
                "backup_checksum": backup_checksum,
                "integrity_match": primary_checksum == backup_checksum
            })
            
        except Exception as e:
            self.log_validation("ERROR", "Failed to create validation backup", {
                "error": str(e)
            })

def main():
    """Main CLI interface"""
    print("🔒 HUMAN AI FRAMEWORK - JSON Validator")
    print("⚠️  SECURITY: Validation is exclusively for HUMAN-AI-FRAMEWORK")
    print("❌ NO EXTERNAL ACCESS PERMITTED\n")
    
    # Get target directory from command line or use current
    if len(sys.argv) > 1:
        weekly_folder = sys.argv[1]
    else:
        weekly_folder = None
    
    # Initialize validator
    validator = HumanAIFrameworkValidator()
    
    # Run validation
    report = validator.validate_weekly_compilation(weekly_folder)
    
    # Print summary
    summary = report["validation_summary"]
    print(f"\n📊 Validation Summary:")
    print(f"   Total files: {summary['total_files']}")
    print(f"   Valid files: {summary['valid_files']}")
    print(f"   Invalid files: {summary['invalid_files']}")
    print(f"   Success rate: {summary['success_rate']:.1f}%")
    
    # Print errors if any
    if summary['invalid_files'] > 0:
        print(f"\n❌ Validation Errors:")
        for result in report["file_results"]:
            if not result.get("valid", True):
                print(f"   • {result['file']}: {result.get('error', 'Unknown error')}")
    
    # Create backup if validation successful
    if summary['success_rate'] >= 80:  # 80% success threshold
        print(f"\n✅ Validation completed successfully!")
        # Extract weekly folder from successful validation
        if report["file_results"]:
            # Try to determine weekly folder from file paths
            sample_path = Path(report["file_results"][0]["file"])
            for parent in sample_path.parents:
                if parent.name.startswith("weekly-"):
                    validator.create_backup_validation(parent.name)
                    break
    else:
        print(f"\n⚠️  Validation completed with warnings")
    
    # Exit with appropriate code
    sys.exit(0 if summary['invalid_files'] == 0 else 1)

if __name__ == "__main__":
    main()