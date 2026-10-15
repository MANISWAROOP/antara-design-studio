#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# ANTARA STUDIOS — Interior Design POC  •  Deployment Helper
# ─────────────────────────────────────────────────────────────────────────────
# Run this script from the antara-design-studio/ directory:
#   cd antara-design-studio && bash deploy.sh
#
# Choose ONE of the three methods below.
# ─────────────────────────────────────────────────────────────────────────────

set -e
BOLD='\033[1m'; GREEN='\033[0;32m'; GOLD='\033[0;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   ANTARA STUDIOS — Interior Design POC Deployer     ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Choose a deployment target:${NC}"
echo ""
echo -e "  ${GOLD}[1]${NC} GitHub Pages  — Free forever · yourname.github.io/antara-design-studio"
echo -e "  ${BLUE}[2]${NC} Vercel        — Free forever · antara-design-studio.vercel.app"
echo -e "  ${GREEN}[3]${NC} Surge.sh      — Free forever · antara-studios-poc.surge.sh"
echo ""
read -p "Enter choice [1/2/3]: " CHOICE

# ── PRE-CHECKS ───────────────────────────────────────────────────────────────
check_tool() {
  if ! command -v "$1" &>/dev/null; then
    echo -e "${RED}✗ '$1' not found. Installing...${NC}"
    npm install -g "$1"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# METHOD 1: GITHUB PAGES
# ─────────────────────────────────────────────────────────────────────────────
deploy_github_pages() {
  echo ""
  echo -e "${BOLD}━━━  GitHub Pages Deployment  ━━━${NC}"
  echo ""

  if ! command -v gh &>/dev/null; then
    echo "Installing GitHub CLI..."
    brew install gh
  fi

  # Check auth
  if ! gh auth status &>/dev/null; then
    echo -e "${GOLD}→ You need to log into GitHub. A browser window will open.${NC}"
    gh auth login --web
  fi

  # Get GitHub username
  GH_USER=$(gh api user --jq .login)
  REPO_NAME="antara-design-studio"
  echo -e "${GREEN}✓ Logged in as: ${BOLD}$GH_USER${NC}"
  echo ""

  # Create repo if it doesn't exist
  if gh repo view "$GH_USER/$REPO_NAME" &>/dev/null; then
    echo -e "${GREEN}✓ Repository already exists${NC}"
  else
    echo "Creating GitHub repository: $REPO_NAME..."
    gh repo create "$REPO_NAME" \
      --public \
      --description "Antara Studios — Interactive Interior Design POC" \
      --source=. \
      --remote=origin \
      --push
  fi

  # Set remote and push
  if ! git remote get-url origin &>/dev/null; then
    git remote add origin "https://github.com/$GH_USER/$REPO_NAME.git"
  fi

  echo "Pushing to GitHub..."
  git push -u origin main 2>/dev/null || git push -u origin master

  # Enable GitHub Pages via API
  echo "Enabling GitHub Pages..."
  gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    "/repos/$GH_USER/$REPO_NAME/pages" \
    -f source[branch]="main" \
    -f source[path]="/" 2>/dev/null || true

  # Also try PUT for repos that already have Pages
  gh api \
    --method PUT \
    -H "Accept: application/vnd.github+json" \
    "/repos/$GH_USER/$REPO_NAME/pages" \
    -f source[branch]="main" \
    -f source[path]="/" 2>/dev/null || true

  echo ""
  echo -e "${GREEN}${BOLD}✓ DEPLOYED!${NC}"
  echo ""
  echo -e "  🌐 Live URL (active in ~60 seconds):"
  echo -e "     ${BOLD}https://$GH_USER.github.io/$REPO_NAME/${NC}"
  echo ""
  echo -e "  🎛️  Control Panel:"
  echo -e "     ${BOLD}https://github.com/$GH_USER/$REPO_NAME/settings/pages${NC}"
  echo ""
  echo -e "  📝 To update the site later:"
  echo -e "     ${BOLD}git add . && git commit -m 'update' && git push${NC}"
  echo ""
  echo -e "  🔗 Share this link with Antara Studios:"
  echo -e "     ${BOLD}https://$GH_USER.github.io/$REPO_NAME/${NC}"
}

# ─────────────────────────────────────────────────────────────────────────────
# METHOD 2: VERCEL
# ─────────────────────────────────────────────────────────────────────────────
deploy_vercel() {
  echo ""
  echo -e "${BOLD}━━━  Vercel Deployment  ━━━${NC}"
  echo ""

  check_tool vercel

  if ! vercel whoami &>/dev/null; then
    echo -e "${GOLD}→ You need to log into Vercel. Choose GitHub/Google/Email.${NC}"
    vercel login
  fi

  VCL_USER=$(vercel whoami 2>/dev/null || echo "user")
  echo -e "${GREEN}✓ Logged in as: ${BOLD}$VCL_USER${NC}"
  echo ""

  # Deploy to production
  DEPLOY_URL=$(vercel --yes --prod 2>&1 | grep -E "^https://" | tail -1)

  echo ""
  echo -e "${GREEN}${BOLD}✓ DEPLOYED!${NC}"
  echo ""
  echo -e "  🌐 Live URL:  ${BOLD}$DEPLOY_URL${NC}"
  echo ""
  echo -e "  🎛️  Control Panel:  ${BOLD}https://vercel.com/dashboard${NC}"
  echo ""
  echo -e "  📝 To update the site later:"
  echo -e "     ${BOLD}vercel --prod${NC}"
  echo ""
  echo -e "  🌍 To add a custom domain (e.g. design.antarastudios.com):"
  echo -e "     ${BOLD}vercel domains add design.antarastudios.com${NC}"
}

# ─────────────────────────────────────────────────────────────────────────────
# METHOD 3: SURGE.SH
# ─────────────────────────────────────────────────────────────────────────────
deploy_surge() {
  echo ""
  echo -e "${BOLD}━━━  Surge.sh Deployment  ━━━${NC}"
  echo ""

  check_tool surge

  # Suggest a domain
  DEFAULT_DOMAIN="antara-design-studio.surge.sh"
  echo -e "Suggested domain: ${BOLD}$DEFAULT_DOMAIN${NC}"
  read -p "Use this domain? (press Enter to accept, or type a custom one): " SURGE_DOMAIN
  SURGE_DOMAIN="${SURGE_DOMAIN:-$DEFAULT_DOMAIN}"

  echo ""
  echo -e "${GOLD}→ You'll be asked to create/login to a free Surge account.${NC}"
  echo ""

  surge publish . "$SURGE_DOMAIN"

  echo ""
  echo -e "${GREEN}${BOLD}✓ DEPLOYED!${NC}"
  echo ""
  echo -e "  🌐 Live URL:  ${BOLD}https://$SURGE_DOMAIN${NC}"
  echo ""
  echo -e "  📝 To update the site later:"
  echo -e "     ${BOLD}surge publish . $SURGE_DOMAIN${NC}"
  echo ""
  echo -e "  🗑️  To take down the site:"
  echo -e "     ${BOLD}surge teardown $SURGE_DOMAIN${NC}"
}

# ─────────────────────────────────────────────────────────────────────────────
# DISPATCH
# ─────────────────────────────────────────────────────────────────────────────
case "$CHOICE" in
  1) deploy_github_pages ;;
  2) deploy_vercel ;;
  3) deploy_surge ;;
  *)
    echo -e "${RED}Invalid choice. Run the script again and enter 1, 2, or 3.${NC}"
    exit 1 ;;
esac
