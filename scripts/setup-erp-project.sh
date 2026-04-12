#!/usr/bin/env bash
# setup-erp-project.sh
# Creates the "ERP Core" GitHub Project v2 with custom fields and Sprint 1 issues.
#
# Prerequisites:
#   - gh CLI authenticated (run `gh auth login` first)
#   - Repo issues enabled (Settings > General > Features > Issues)
#
# Usage:
#   chmod +x scripts/setup-erp-project.sh
#   ./scripts/setup-erp-project.sh

set -euo pipefail

OWNER="Jlexalex"
REPO="ai_job"

echo "=== ERP Core Project Setup ==="
echo ""

# ── 1. Create labels ─────────────────────────────────────────────────────────
echo "Creating labels..."
gh label create "sprint-1" --repo "$OWNER/$REPO" --color "1d76db" --description "Sprint 1" --force 2>/dev/null || true
gh label create "erp-core" --repo "$OWNER/$REPO" --color "0e8a16" --description "ERP Core module" --force 2>/dev/null || true
echo "  Labels created."

# ── 2. Create GitHub Project v2 ──────────────────────────────────────────────
echo ""
echo "Creating GitHub Project v2 'ERP Core'..."

PROJECT_ID=$(gh project create --owner "$OWNER" --title "ERP Core" --format json | jq -r '.id')

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "null" ]; then
  echo "ERROR: Failed to create project. Check your gh auth scopes (need 'project' scope)."
  echo "Run: gh auth refresh -s project"
  exit 1
fi
echo "  Project created (ID: $PROJECT_ID)"

# ── 3. Add custom fields ─────────────────────────────────────────────────────
echo ""
echo "Adding custom fields..."

# Priority (single select: High, Medium, Low)
gh project field-create "$PROJECT_ID" \
  --owner "$OWNER" \
  --name "Priority" \
  --data-type "SINGLE_SELECT" \
  --single-select-options "High,Medium,Low"
echo "  Priority field added."

# Estimate (number)
gh project field-create "$PROJECT_ID" \
  --owner "$OWNER" \
  --name "Estimate" \
  --data-type "NUMBER"
echo "  Estimate field added."

# Sprint (iteration, 2-week duration)
gh project field-create "$PROJECT_ID" \
  --owner "$OWNER" \
  --name "Sprint" \
  --data-type "ITERATION" \
  --iteration-duration 14
echo "  Sprint field added (2-week iterations)."

# ── 4. Create Sprint 1 issues ────────────────────────────────────────────────
echo ""
echo "Creating Sprint 1 issues..."

declare -a ISSUE_TITLES=(
  "Document base model"
  "State machine engine"
  "PostgreSQL schema design"
  "REST API skeleton (FastAPI)"
  "Basic auth (OAuth2)"
  "AP Invoice document type"
  "State transitions: Draft→Approved→Posted→Paid"
)

declare -a ISSUE_BODIES=(
  "## Sprint 1 — ERP Core\n\nDefine and document the base model abstraction that all ERP document types will inherit from.\n\n### Acceptance Criteria\n- Base model class/schema defined with common fields (id, created_at, updated_at, status, etc.)\n- Documentation covers field descriptions, types, and constraints\n- Serves as the foundation for all ERP document types (invoices, purchase orders, etc.)"
  "## Sprint 1 — ERP Core\n\nImplement a generic state machine engine that drives document lifecycle transitions.\n\n### Acceptance Criteria\n- State machine class that accepts state definitions and valid transitions\n- Validation logic to prevent invalid transitions\n- Hook/callback support for pre/post transition actions\n- Unit tests covering valid and invalid transitions"
  "## Sprint 1 — ERP Core\n\nDesign the PostgreSQL database schema for the ERP core entities.\n\n### Acceptance Criteria\n- Schema covers base document table, state history/audit log\n- Migration scripts (Alembic or equivalent)\n- Indexes for common query patterns (status, date ranges, document type)\n- Foreign key relationships and constraints defined"
  "## Sprint 1 — ERP Core\n\nSet up the FastAPI project structure with routing, dependency injection, and base CRUD endpoints.\n\n### Acceptance Criteria\n- FastAPI project scaffolding with proper folder structure\n- Base router with health check endpoint\n- CRUD endpoint patterns for base document model\n- OpenAPI/Swagger docs auto-generated\n- Request/response Pydantic models"
  "## Sprint 1 — ERP Core\n\nImplement OAuth2 authentication and authorization for the API.\n\n### Acceptance Criteria\n- OAuth2 password flow or JWT-based auth\n- Token generation and validation\n- Protected endpoint decorator/dependency\n- User model with roles (admin, user, viewer)\n- Login and token refresh endpoints"
  "## Sprint 1 — ERP Core\n\nImplement the Accounts Payable Invoice as the first concrete document type extending the base model.\n\n### Acceptance Criteria\n- AP Invoice model extending the base document model\n- Fields: vendor, invoice_number, amount, currency, due_date, line_items\n- CRUD endpoints specific to AP Invoice\n- Validation rules for invoice data\n- Database migration for the AP Invoice table"
  "## Sprint 1 — ERP Core\n\nWire up the AP Invoice state machine with the concrete lifecycle: Draft → Approved → Posted → Paid.\n\n### Acceptance Criteria\n- State definitions for Draft, Approved, Posted, Paid\n- Valid transitions: Draft→Approved, Approved→Posted, Posted→Paid\n- Rejection/reversal paths where appropriate (e.g., Approved→Draft)\n- API endpoints to trigger transitions\n- State change audit logging\n- Unit and integration tests for the full lifecycle"
)

ISSUE_NUMBERS=()

for i in "${!ISSUE_TITLES[@]}"; do
  TITLE="${ISSUE_TITLES[$i]}"
  BODY="${ISSUE_BODIES[$i]}"

  ISSUE_URL=$(gh issue create \
    --repo "$OWNER/$REPO" \
    --title "$TITLE" \
    --body "$(echo -e "$BODY")" \
    --label "sprint-1,erp-core")

  ISSUE_NUM=$(echo "$ISSUE_URL" | grep -oP '\d+$')
  ISSUE_NUMBERS+=("$ISSUE_NUM")
  echo "  #$ISSUE_NUM: $TITLE"
done

# ── 5. Add issues to the project ─────────────────────────────────────────────
echo ""
echo "Adding issues to the project..."

for ISSUE_NUM in "${ISSUE_NUMBERS[@]}"; do
  ITEM_ID=$(gh project item-add "$PROJECT_ID" \
    --owner "$OWNER" \
    --url "https://github.com/$OWNER/$REPO/issues/$ISSUE_NUM" \
    --format json | jq -r '.id')
  echo "  Issue #$ISSUE_NUM added to project (item: $ITEM_ID)"
done

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "=== Setup Complete ==="
echo ""
echo "Project URL: https://github.com/users/$OWNER/projects/"
echo "Issues:      https://github.com/$OWNER/$REPO/issues"
echo ""
echo "Next steps:"
echo "  1. Open the project board and verify custom fields"
echo "  2. Set Priority and Estimate values for each issue"
echo "  3. Assign issues to Sprint 1 iteration"
