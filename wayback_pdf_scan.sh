#!/usr/bin/env bash
#
# wayback_pdf_scan.sh
# -------------------
# 1. Pull URLs from Wayback CDX for a given domain.
# 2. Filter by interesting extensions.
# 3. Deep‑scan PDFs for sensitive text (via pdftotext + grep).
#
# Requires: curl, grep, xargs, tr, awk, sed, pdftotext  (uro optional).
#

set -euo pipefail


banner() {
cat <<'EOF'
 ___       __   ________      ___    ___ ________  ________  ________ 
|\  \     |\  \|\   __  \    |\  \  /  /|\   __  \|\   ___ \|\  _____\
\ \  \    \ \  \ \  \|\  \   \ \  \/  / | \  \|\  \ \  \_|\ \ \  \__/ 
 \ \  \  __\ \  \ \   __  \   \ \    / / \ \   ____\ \  \ \\ \ \   __\
  \ \  \|\__\_\  \ \  \ \  \   \/  /  /   \ \  \___|\ \  \_\\ \ \  \_|
   \ \____________\ \__\ \__\__/  / /      \ \__\    \ \_______\ \__\ 
    \|____________|\|__|\|__|\___/ /        \|__|     \|_______|\|__| 
                            \|___|/                                   

#This is Demo Test Of the Project 
EOF
}
banner

###############################################################################
# CLI options
###############################################################################
THREADS=20
TARGET_DOMAIN=""

usage() {
  echo "Usage: $0 -u <domain> [-t <threads>]" >&2
  exit "${1:-1}"
}

while getopts ":u:t:h" opt; do
  case $opt in
    u) TARGET_DOMAIN="$OPTARG" ;;
    t) THREADS="$OPTARG" ;;
    h|\?) usage 0 ;;
  esac
done
[[ -z $TARGET_DOMAIN ]] && usage 1

###############################################################################
# Dependency checks
###############################################################################
for cmd in curl grep xargs tr awk sed pdftotext; do
  command -v "$cmd" &>/dev/null || { echo "[-] '$cmd' not found in PATH"; exit 1; }
done

###############################################################################
# Config
###############################################################################
EXTENSIONS='xls|xml|xlsx|json|pdf|sql|docx?|pptx?|txt|zip|tar\.gz|tgz|bak|7z|rar|log|cache|secret|db|backup|ya?ml|gz|config|csv|yaml|md|md5|exe|dll|bin|ini|bat|sh|deb|git|env|rpm|iso|img|apk|msi|dmg|tmp|crt|pem|key|pub|asc'

# One‑line PDF keyword regex (portable: uses [[:space:]] for \s)
PDF_KEYWORDS='(internal[[:space:]]+use[[:space:]]+only|confidential|strictly[[:space:]]+private|personal[[:space:]]*&[[:space:]]+confidential|private|restricted|internal|not[[:space:]]+for[[:space:]]+distribution|do[[:space:]]+not[[:space:]]+share|proprietary|trade[[:space:]]+secret|classified|sensitive|confidential[[:space:]]+information|bank[[:space:]]+statement|invoice|salary|contract|agreement|non[[:space:]]+disclosure[[:space:]]+agreement|nda|passport|social[[:space:]]+security[[:space:]]+number|ssn|date[[:space:]]+of[[:space:]]+birth|dob|credit[[:space:]]+card|identity[[:space:]]+number|id[[:space:]]+number|company[[:space:]]+confidential|staff[[:space:]]+only|management[[:space:]]+only|internal[[:space:]]+only|personal[[:space:]]+identifiable[[:space:]]+information|pii|email[[:space:]]+address|phone[[:space:]]+number|contact[[:space:]]+details|employee[[:space:]]+number|account[[:space:]]+number|login[[:space:]]+credentials|username|password|bank[[:space:]]+account|tax[[:space:]]+identification[[:space:]]+number|tin|bank[[:space:]]+routing[[:space:]]+number|iban|security[[:space:]]+question|access[[:space:]]+token|authentication[[:space:]]+key|encryption[[:space:]]+key|user[[:space:]]+id|financial[[:space:]]+statement|tax[[:space:]]+report|financial[[:space:]]+data|payroll[[:space:]]+data|asset[[:space:]]+report|investment[[:space:]]+portfolio|balance[[:space:]]+sheet|profit[[:space:]]+and[[:space:]]+loss|annual[[:space:]]+report|business[[:space:]]+plan|audit[[:space:]]+report|health[[:space:]]+record|medical[[:space:]]+history|patient[[:space:]]+data|legal[[:space:]]+document|court[[:space:]]+order|lawsuit[[:space:]]+details|salary[[:space:]]+statement|employment[[:space:]]+contract|job[[:space:]]+offer|termination[[:space:]]+letter|promotion[[:space:]]+letter|employee[[:space:]]+evaluation|compensation[[:space:]]+package|bonus[[:space:]]+information|confidential[[:space:]]+report|internal[[:space:]]+memo|board[[:space:]]+meeting[[:space:]]+notes|strategy[[:space:]]+document|project[[:space:]]+plan)'

###############################################################################
# Workflow
###############################################################################
echo "[*] Domain        : $TARGET_DOMAIN"
echo "[*] Wayback query : grabbing URLs …"
curl -s -G 'https://web.archive.org/cdx/search/cdx' \
  --data-urlencode "url=*.$TARGET_DOMAIN/*" \
  --data-urlencode collapse=urlkey \
  --data-urlencode output=text \
  --data-urlencode fl=original > all_urls.txt
echo "    → $(wc -l < all_urls.txt) raw URLs"

# Optional normalisation via uro
if command -v uro &>/dev/null; then
  uro all_urls.txt > uniq_urls.txt
else
  sort -u all_urls.txt > uniq_urls.txt
fi

grep -E "\.($EXTENSIONS)(\?.*)?$" uniq_urls.txt > filtered_urls.txt
echo "[*] URLs after extension filter : $(wc -l < filtered_urls.txt)"

grep -Ei '\.pdf(\?.*)?$' filtered_urls.txt > pdf_urls.txt
echo "[*] PDF URLs to scan           : $(wc -l < pdf_urls.txt)"

echo "[*] Scanning PDFs for sensitive text (threads: $THREADS)…"
: > matched_pdfs.txt

export PDF_KEYWORDS     # for subshells
scan_pdf() {
  url="$1"
  # fetch & convert -> pdf text -> grep
  if curl -s --max-time 30 "$url" | pdftotext - - 2>/dev/null | \
     grep -Eaiq "$PDF_KEYWORDS"; then
    echo "$url"
  fi
}
export -f scan_pdf

# Parallel scan
tr '\n' '\0' < pdf_urls.txt |
xargs -0  -P "$THREADS" -I{} bash -c 'scan_pdf "$@"' _ {} \
  >> matched_pdfs.txt

echo "[✓] Done. Sensitive PDFs found : $(wc -l < matched_pdfs.txt)"
[[ -s matched_pdfs.txt ]] && cat matched_pdfs.txt

