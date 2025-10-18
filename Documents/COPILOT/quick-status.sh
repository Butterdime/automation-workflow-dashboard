#!/bin/bash

# Quick Infrastructure Summary
# Usage: ./quick-status.sh

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'  
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}🚀 Copilot Log Sharing Infrastructure - Quick Status${NC}\n"

# Core files check
CORE_FILES=(
    "package.json"
    "webhook-multiplexer.js"
    "copilot/server.js"
    "docker-compose.yml"
    "setup-log-sharing.sh"
    "deployment-status.sh"
)

OPTIONAL_FILES=(
    "k8s/copilot-deployment.yaml"
    "TEAM_DOCUMENTATION.md"
    "ENVIRONMENT_CONFIGURATION.md"
    "perplexity-space-template.js"
)

echo -e "${BLUE}📋 Core Infrastructure:${NC}"
core_count=0
for file in "${CORE_FILES[@]}"; do
    if [[ -f "$PROJECT_ROOT/$file" ]]; then
        echo -e "  ✅ $file"
        ((core_count++))
    else
        echo -e "  ❌ $file"
    fi
done

echo -e "\n${BLUE}📚 Documentation & Templates:${NC}"
optional_count=0
for file in "${OPTIONAL_FILES[@]}"; do
    if [[ -f "$PROJECT_ROOT/$file" ]]; then
        echo -e "  ✅ $file"
        ((optional_count++))
    else
        echo -e "  ❌ $file"
    fi
done

echo -e "\n${BLUE}📊 Summary:${NC}"
echo -e "  Core Files: ${GREEN}$core_count/${#CORE_FILES[@]}${NC}"
echo -e "  Documentation: ${GREEN}$optional_count/${#OPTIONAL_FILES[@]}${NC}"

total_files=$((${#CORE_FILES[@]} + ${#OPTIONAL_FILES[@]}))
total_found=$((core_count + optional_count))
completion_rate=$((total_found * 100 / total_files))

echo -e "  Completion: ${GREEN}$completion_rate%${NC}"

if [[ $core_count -eq ${#CORE_FILES[@]} ]]; then
    echo -e "\n${GREEN}🎉 Ready to deploy!${NC}"
    echo -e "\nQuick commands:"
    echo -e "  • Full status: ${CYAN}./deployment-status.sh development${NC}"
    echo -e "  • Setup logs: ${CYAN}./setup-log-sharing.sh${NC}"
    echo -e "  • Start dev: ${CYAN}npm run dev${NC}"
    echo -e "  • Docker: ${CYAN}docker-compose up -d${NC}"
else
    echo -e "\n${BLUE}Missing core files. Run full check:${NC}"
    echo -e "  ${CYAN}./deployment-status.sh development${NC}"
fi