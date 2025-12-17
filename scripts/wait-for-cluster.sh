#!/bin/bash
###############################################################################
# wait-for-cluster.sh
# Waits for ROSA HCP cluster to be in 'ready' state
###############################################################################

set -euo pipefail

# Configuration
MAX_ATTEMPTS=${MAX_ATTEMPTS:-60}
SLEEP_INTERVAL=${SLEEP_INTERVAL:-60}
CLUSTER_NAME=${CLUSTER_NAME:-""}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get cluster name from Terraform output if not provided
if [ -z "$CLUSTER_NAME" ]; then
    if command -v terraform &> /dev/null; then
        CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "")
    fi
fi

if [ -z "$CLUSTER_NAME" ]; then
    log_error "CLUSTER_NAME is not set. Please set it or run from Terraform directory."
    exit 1
fi

log_info "Waiting for ROSA HCP cluster '$CLUSTER_NAME' to be ready..."
log_info "Max attempts: $MAX_ATTEMPTS, Sleep interval: ${SLEEP_INTERVAL}s"

attempt=1
while [ $attempt -le $MAX_ATTEMPTS ]; do
    log_info "Attempt $attempt/$MAX_ATTEMPTS: Checking cluster status..."

    # Get cluster state using ROSA CLI or AWS CLI
    if command -v rosa &> /dev/null; then
        CLUSTER_STATE=$(rosa describe cluster -c "$CLUSTER_NAME" -o json 2>/dev/null | jq -r '.state' || echo "unknown")
    else
        # Fallback to Terraform state check
        CLUSTER_STATE=$(terraform output -raw cluster_state 2>/dev/null || echo "unknown")
    fi

    log_info "Current cluster state: $CLUSTER_STATE"

    case $CLUSTER_STATE in
        "ready")
            log_info "Cluster '$CLUSTER_NAME' is ready!"

            # Get cluster details
            if command -v rosa &> /dev/null; then
                API_URL=$(rosa describe cluster -c "$CLUSTER_NAME" -o json | jq -r '.api.url')
                CONSOLE_URL=$(rosa describe cluster -c "$CLUSTER_NAME" -o json | jq -r '.console.url')

                log_info "API URL: $API_URL"
                log_info "Console URL: $CONSOLE_URL"
            fi

            exit 0
            ;;
        "error"|"uninstalling")
            log_error "Cluster is in '$CLUSTER_STATE' state. Aborting."
            exit 1
            ;;
        "installing"|"pending"|"waiting")
            log_info "Cluster is still provisioning ($CLUSTER_STATE). Waiting..."
            ;;
        *)
            log_warn "Unknown cluster state: $CLUSTER_STATE"
            ;;
    esac

    sleep $SLEEP_INTERVAL
    ((attempt++))
done

log_error "Timeout: Cluster did not become ready within $((MAX_ATTEMPTS * SLEEP_INTERVAL)) seconds"
exit 1
