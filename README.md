# WayPdf
This is a reconnaissance tool useful in bug bounty / pentesting, to find leaked sensitive documents in archived snapshots of a target domain.




<img width="585" height="137" alt="image" src="https://github.com/user-attachments/assets/1f3f82b6-c64c-4991-84a8-6e5b82d88cff" />



🔍 1. wayback_pdf_scan.sh

This is a recon / sensitive data discovery script that:

Fetches archived URLs for a given domain using the Wayback Machine (CDX API).

Example: if you run ./wayback_pdf_scan.sh -u example.com, it queries *.example.com/* from Wayback.

Filters URLs by interesting file extensions (pdf, sql, docx, json, xls, zip, etc.).

Keeps only URLs that might contain sensitive data.

Isolates PDF files from the results.

Scans PDFs for sensitive keywords by:

Downloading each PDF with curl.

Converting it to text using pdftotext.

Searching for sensitive terms like “confidential”, “password”, “PII”, “contract”, “salary”.

Outputs matches into matched_pdfs.txt.

👉 Essentially, this script automates hunting for sensitive documents in old snapshots of a target domain.

⚙️ 2. install.sh

This is a helper script that installs all required dependencies for the scanner.

Detects package manager (apt-get or dnf).

Updates repositories.

Installs core tools:
curl, grep, xargs, coreutils, gawk, sed, poppler-utils (provides pdftotext).

Installs uro (URL deduplicator/normalizer) via:

cargo install uro (if Rust is available).

Or downloads the latest binary from GitHub.

👉 In short, this ensures your environment has all tools needed before running the scanner.

⚡ Workflow in Practice

Run install.sh once to set up dependencies.

Run:

./wayback_pdf_scan.sh -u target.com -t 30


-u → domain

-t → number of threads for parallel PDF scanning

Results:

all_urls.txt → all Wayback URLs

uniq_urls.txt → deduplicated URLs

filtered_urls.txt → only “interesting” extensions

pdf_urls.txt → only PDFs

matched_pdfs.txt → PDFs that contain sensitive keywords
